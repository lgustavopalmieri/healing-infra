#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Deploying observability stack ==="

echo "[1/6] Creating namespace..."
kubectl apply -f "$SCRIPT_DIR/namespace.yaml"

echo "[2/6] Deploying kube-state-metrics..."
kubectl apply -f "$SCRIPT_DIR/kube-state-metrics.yaml"

echo "[3/6] Deploying OpenTelemetry Collector..."
kubectl apply -f "$SCRIPT_DIR/otel-collector.yaml"

echo "[4/6] Deploying Prometheus..."
kubectl apply -f "$SCRIPT_DIR/prometheus.yaml"

echo "[5/6] Deploying Grafana (dashboards + datasources)..."
kubectl create configmap grafana-dashboards \
  --from-file="$SCRIPT_DIR/dashboards/" \
  --namespace=observability \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$SCRIPT_DIR/grafana.yaml"

echo "[6/6] Deploying Ingress..."
kubectl apply -f "$SCRIPT_DIR/ingress.yaml"

echo ""
echo "=== Waiting for pods to be ready ==="
kubectl -n observability rollout status deployment/kube-state-metrics --timeout=120s
kubectl -n observability rollout status deployment/otel-collector --timeout=120s
kubectl -n observability rollout status deployment/prometheus --timeout=120s
kubectl -n observability rollout status deployment/grafana --timeout=120s

echo ""
echo "=== Observability stack deployed ==="
kubectl get pods -n observability
echo ""

INGRESS_HOST=$(kubectl get ingress observability -n observability -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "<pending>")
echo "Grafana URL: http://${INGRESS_HOST}/grafana"
echo "Default credentials: admin / (see grafana-admin Secret)"
