#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Destroying observability stack ==="

echo "Deleting Ingress..."
kubectl delete -f "$SCRIPT_DIR/ingress.yaml" --ignore-not-found

echo "Deleting Grafana..."
kubectl delete -f "$SCRIPT_DIR/grafana.yaml" --ignore-not-found
kubectl delete configmap grafana-dashboards -n observability --ignore-not-found

echo "Deleting Prometheus..."
kubectl delete -f "$SCRIPT_DIR/prometheus.yaml" --ignore-not-found

echo "Deleting OpenTelemetry Collector..."
kubectl delete -f "$SCRIPT_DIR/otel-collector.yaml" --ignore-not-found

echo "Deleting kube-state-metrics..."
kubectl delete -f "$SCRIPT_DIR/kube-state-metrics.yaml" --ignore-not-found

echo "Deleting namespace..."
kubectl delete -f "$SCRIPT_DIR/namespace.yaml" --ignore-not-found

echo ""
echo "=== Observability stack destroyed ==="
