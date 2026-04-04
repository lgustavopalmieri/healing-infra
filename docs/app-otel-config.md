# Application OpenTelemetry Configuration Guide

## Overview

This document describes the infrastructure-side configuration required for applications to send metrics to the observability stack. It covers environment variables, Kubernetes manifest changes, and connectivity details — not SDK implementation code.

---

## How It Works

```
┌──────────────┐    OTLP/HTTP     ┌──────────────────┐    Prometheus     ┌────────────┐
│  Application │───── :4318 ─────►│  OTel Collector   │──── :8889 ──────►│ Prometheus  │
│  (any lang)  │                  │  (observability   │                  │            │
│              │    OTLP/gRPC     │   namespace)      │                  └────────────┘
│              │───── :4317 ─────►│                    │
└──────────────┘                  └──────────────────┘
```

Applications send metrics using the OTLP protocol (HTTP or gRPC) to the OTel Collector running in the `observability` namespace. The Collector converts and exposes them in Prometheus format.

---

## Required Environment Variables

Add these to your application's ConfigMap or Deployment env:

| Variable | Value | Description |
|----------|-------|-------------|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://otel-collector.observability.svc.cluster.local:4318` | OTel Collector OTLP HTTP endpoint (cluster-internal DNS) |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/protobuf` | Protocol for OTLP export (use `grpc` if using port 4317) |
| `OTEL_SERVICE_NAME` | `<your-service-name>` | Identifies the application in metrics (e.g. `healing-specialist`) |
| `OTEL_RESOURCE_ATTRIBUTES` | `deployment.environment=<env>` | Additional resource attributes (environment, version, etc.) |

### Example: ConfigMap addition for healing-specialist

These env vars are already configured in `k8s/specialist/healing-specialist.yaml` and `k8s.example/specialist/healing-specialist.yaml`:

```yaml
# In k8s/specialist/healing-specialist.yaml — ConfigMap section
data:
  # ... existing config ...
  OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector.observability.svc.cluster.local:4318"
  OTEL_EXPORTER_OTLP_PROTOCOL: "http/protobuf"
  OTEL_SERVICE_NAME: "healing-specialist"
  OTEL_RESOURCE_ATTRIBUTES: "deployment.environment=production"
```

> The endpoint uses Kubernetes internal DNS. It resolves to the OTel Collector Service in the `observability` namespace from any namespace in the cluster.

---

## Adding a New Grafana Dashboard

Dashboards are standalone `.json` files in `k8s/observability/dashboards/`. No YAML editing needed.

1. Create your dashboard JSON file (export from Grafana UI or write manually)
2. Save it to `k8s/observability/dashboards/<dashboard-name>.json`
3. Run `bash k8s/observability/apply.sh` — the script recreates the ConfigMap from the entire folder

The `apply.sh` script uses `kubectl create configmap --from-file=dashboards/ --dry-run=client | kubectl apply` to keep the ConfigMap in sync with the folder contents.

---

## Required Application Metrics

For the Applications dashboard in Grafana to work, your application must emit the following metrics via OTLP:

| Metric Name | Type | Labels/Attributes | Description |
|-------------|------|-------------------|-------------|
| `app_requests_total` | Counter | `app`, `endpoint` | Total number of requests processed. Increment on every request. |
| `app_response_time_seconds` | Histogram | `app`, `endpoint` | Response time per request in seconds. |

### Label Conventions

| Label | Example | Description |
|-------|---------|-------------|
| `app` | `healing-specialist` | Application name (should match `OTEL_SERVICE_NAME`) |
| `endpoint` | `/api/v1/specialists`, `/health` | The HTTP route/path of the request |

---

## Connectivity Details

| Protocol | Host | Port | Use Case |
|----------|------|------|----------|
| OTLP HTTP | `otel-collector.observability.svc.cluster.local` | 4318 | Recommended for most languages |
| OTLP gRPC | `otel-collector.observability.svc.cluster.local` | 4317 | Alternative for gRPC-native apps |

Both ports are available. HTTP is recommended as it's simpler to debug and works through more proxies.

---

## Onboarding a New Application (Checklist)

1. **Add OTel SDK** to your application dependencies (language-specific)
2. **Instrument metrics**: Create `app_requests_total` counter and `app_response_time_seconds` histogram
3. **Set environment variables**: Add the 4 env vars above to your ConfigMap/Deployment
4. **Deploy**: The OTel Collector automatically receives and exports your metrics
5. **Verify**: Check the Grafana Applications dashboard — your app should appear automatically

No changes to the observability stack are needed when onboarding new applications.

---

## Language-Specific SDK References

| Language | SDK Package | Docs |
|----------|-------------|------|
| Go | `go.opentelemetry.io/otel` | https://opentelemetry.io/docs/languages/go/ |
| Python | `opentelemetry-sdk`, `opentelemetry-exporter-otlp` | https://opentelemetry.io/docs/languages/python/ |
| Java | `io.opentelemetry:opentelemetry-sdk` | https://opentelemetry.io/docs/languages/java/ |
| Node.js | `@opentelemetry/sdk-node` | https://opentelemetry.io/docs/languages/js/ |
| .NET | `OpenTelemetry.Extensions.Hosting` | https://opentelemetry.io/docs/languages/net/ |

> This guide intentionally does not include SDK implementation code. Refer to the official docs above for language-specific instrumentation details.

---

## Testing Locally (Optional)

If you want to test OTel metric export locally before deploying to the cluster, you can point your application to a local OTel Collector using Docker:

```bash
# Run a local OTel Collector
docker run -p 4317:4317 -p 4318:4318 -p 8889:8889 \
  -v $(pwd)/collector-config.yaml:/etc/otelcol-contrib/config.yaml \
  otel/opentelemetry-collector-contrib:0.128.0

# Set env var to point to local collector
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```
