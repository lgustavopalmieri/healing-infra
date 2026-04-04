# Observability Layer — Action Plan

## Overview

Implementation of the initial observability layer for the healing platform using OpenTelemetry, Prometheus, and Grafana. All components run inside the EKS cluster in a dedicated `observability` namespace, accessible via an ALB Ingress endpoint.

Each environment (dev, staging, production) has its own isolated stack — same manifests, different clusters.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        EKS Cluster (per env)                        │
│                                                                     │
│  ┌─────────────┐    scrape     ┌──────────────┐    datasource      │
│  │  Prometheus  │◄────────────►│   Grafana     │◄──── ALB Ingress  │
│  │  (metrics    │              │  (dashboards) │     /grafana       │
│  │   storage)   │              └──────────────┘                     │
│  └──────┬───────┘                                                   │
│         │ scrape                                                    │
│         ▼                                                           │
│  ┌──────────────────┐         ┌──────────────────┐                  │
│  │  OTel Collector   │◄──otlp──│  Applications    │                  │
│  │  (receives app    │         │  (healing-        │                  │
│  │   metrics, exposes│         │   specialist,     │                  │
│  │   to prometheus)  │         │   future apps)    │                  │
│  └──────────────────┘         └──────────────────┘                  │
│         ▲                                                           │
│  Prometheus also scrapes:                                           │
│  - kube-state-metrics (pod count, status, etc.)                     │
│  - kubelet/cAdvisor (CPU, memory per pod)                           │
│  - OTel Collector /metrics (app metrics)                            │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Flow

1. **Application metrics** → Apps send OTLP metrics to OTel Collector (HTTP :4318)
2. **OTel Collector** → Receives OTLP, exports as Prometheus format on :8889
3. **Prometheus** → Scrapes OTel Collector :8889, kube-state-metrics :8080, kubelet cAdvisor
4. **Grafana** → Queries Prometheus as datasource, renders dashboards
5. **User** → Accesses Grafana via ALB Ingress at `/grafana`

---

## Components to Deploy

### 1. Namespace — `observability`

Simple namespace with standard labels.

| Item | Detail |
|------|--------|
| Manifest | `k8s/observability/namespace.yaml` |
| Complexity | Minimal |

### 2. kube-state-metrics

Generates metrics about Kubernetes object states (pod count, deployment status, etc.). This is how we get "number of pods per application running in the cluster".

| Item | Detail |
|------|--------|
| Manifest | `k8s/observability/kube-state-metrics.yaml` |
| Image | `registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.15.0` |
| Resources | ServiceAccount + ClusterRole + ClusterRoleBinding + Deployment + Service |
| Port | 8080 (metrics), 8081 (telemetry) |

### 3. OpenTelemetry Collector

Receives application metrics via OTLP protocol and exports them in Prometheus format. Single deployment (1 replica to avoid duplicate metrics).

| Item | Detail |
|------|--------|
| Manifest | `k8s/observability/otel-collector.yaml` |
| Image | `otel/opentelemetry-collector-contrib:0.128.0` |
| Resources | ConfigMap + Deployment (1 replica) + Service |
| Ports | 4317 (gRPC), 4318 (HTTP), 8889 (Prometheus exporter) |
| Pipeline | receivers: [otlp] → processors: [batch] → exporters: [prometheus] |

### 4. Prometheus

Scrapes metrics from kube-state-metrics, kubelet/cAdvisor, and OTel Collector. Stores time-series data.

| Item | Detail |
|------|--------|
| Manifest | `k8s/observability/prometheus.yaml` |
| Image | `prom/prometheus:v3.4.0` |
| Resources | ServiceAccount + ClusterRole + ClusterRoleBinding + ConfigMap + Deployment + Service |
| Port | 9090 |
| Storage | emptyDir (initial phase — upgrade to PVC when needed) |
| Scrape targets | kube-state-metrics, kubelet cAdvisor, OTel Collector |

### 5. Grafana

Visualization layer with pre-configured datasource (Prometheus) and two dashboards.

| Item | Detail |
|------|--------|
| Manifest | `k8s/observability/grafana.yaml` |
| Image | `grafana/grafana:11.6.0` |
| Resources | ConfigMap (datasources + dashboards) + Deployment + Service |
| Port | 3000 |
| Auth | Basic auth (admin / configurable via Secret) |
| Root URL | `/grafana` (behind ALB Ingress sub-path) |

### 6. Ingress

ALB Ingress exposing Grafana on `/grafana`. Uses a dedicated ALB group separate from application traffic.

| Item | Detail |
|------|--------|
| Manifest | `k8s/observability/ingress.yaml` |
| ALB Group | `healing-observability` (separate from `healing-qa`) |
| Path | `/grafana` → Grafana service :3000 |

### 7. Grafana Dashboards

Dashboards are standalone `.json` files in `k8s/observability/dashboards/`. The `apply.sh` script creates a single ConfigMap from the entire folder. To add a new dashboard, just add a `.json` file — no YAML editing needed.

| Dashboard | File | Metrics |
|-----------|------|---------|
| **Kubernetes Cluster** | `dashboards/kubernetes-cluster.json` | Pod count per deployment, CPU usage per pod, Memory usage per pod |
| **Applications** | `dashboards/applications.json` | Requests per second (per app), Request count per endpoint (per app), Response time p95 |

---

## File Structure

```
k8s/
└── observability/
    ├── dashboards/                 # Pure JSON dashboard files (one per dashboard)
    │   ├── kubernetes-cluster.json # K8s cluster metrics dashboard
    │   └── applications.json       # Application metrics dashboard
    ├── namespace.yaml              # Namespace definition
    ├── kube-state-metrics.yaml     # Pod/deployment state metrics
    ├── otel-collector.yaml         # OTel Collector (OTLP → Prometheus)
    ├── prometheus.yaml             # Prometheus server + scrape config
    ├── grafana.yaml                # Grafana + datasource provisioning
    ├── ingress.yaml                # ALB Ingress for Grafana
    ├── apply.sh                    # Deploy all observability components
    └── destroy.sh                  # Tear down all observability components
```

> Dashboards are standalone `.json` files in the `dashboards/` folder. To add a new dashboard, drop a `.json` file there and re-run `apply.sh`. The script creates a ConfigMap from the entire folder via `kubectl create configmap --from-file`.

---

## Metrics Collected

### Kubernetes Cluster Metrics (via kube-state-metrics + cAdvisor)

| Metric | Source | Description |
|--------|--------|-------------|
| `kube_deployment_status_replicas` | kube-state-metrics | Number of pods running per deployment |
| `kube_deployment_spec_replicas` | kube-state-metrics | Desired number of pods per deployment |
| `container_cpu_usage_seconds_total` | kubelet/cAdvisor | CPU usage per container |
| `container_memory_working_set_bytes` | kubelet/cAdvisor | Memory usage per container |

### Application Metrics (via OTel Collector)

| Metric | Source | Description |
|--------|--------|-------------|
| `app_requests_total` | Application OTel SDK | Total requests (counter), labeled by `app` and `endpoint` |
| `app_response_time_seconds` | Application OTel SDK | Response time histogram per endpoint |

> Applications must send these metrics via OTLP to the OTel Collector. See `docs/app-otel-config.md` for configuration details.

---

## Implementation Order

1. **Namespace** — Create `observability` namespace
2. **kube-state-metrics** — Deploy with RBAC (cluster-wide read access)
3. **OTel Collector** — Deploy with OTLP receiver + Prometheus exporter
4. **Prometheus** — Deploy with scrape config targeting all sources
5. **Grafana** — Deploy with Prometheus datasource + dashboards
6. **Ingress** — Expose Grafana via ALB
7. **Validation** — Access Grafana, verify dashboards show data

---

## Scaling Considerations

- **New applications**: Just configure the app to send OTLP metrics to `otel-collector.observability.svc.cluster.local:4318`. Metrics appear automatically in the Applications dashboard.
- **New infrastructure targets** (OpenSearch, RDS, SQS): Add Prometheus scrape targets or CloudWatch exporters in a future iteration.
- **New environments**: Same manifests, different cluster. `kubectl apply` and done.
- **Persistent storage**: When needed, replace Prometheus `emptyDir` with a PVC.
- **High availability**: Scale Prometheus with Thanos or VictoriaMetrics when traffic justifies it.

---

## What Is NOT Included (by design)

- Tracing (Jaeger, Tempo)
- Log aggregation (Loki)
- Alerting rules (future iteration)
- CloudWatch integration
- OpenSearch/RDS/SQS monitoring (future iteration)
