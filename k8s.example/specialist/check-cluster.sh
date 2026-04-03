#!/bin/bash

echo "========================================="
echo "  1. Setting namespace to 'healing'"
echo "========================================="
kubectl config set-context --current --namespace=healing
echo ""

echo "========================================="
echo "  2. Checking pods"
echo "========================================="
kubectl get pods -o wide
echo ""

echo "========================================="
echo "  3. Ingress address (ALB)"
echo "========================================="
kubectl get ingress healing-specialist
echo ""

echo "========================================="
echo "  4. Swagger URL"
echo "========================================="
INGRESS_HOST=$(kubectl get ingress healing-specialist -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Swagger UI: http://${INGRESS_HOST}/swagger/index.html"
