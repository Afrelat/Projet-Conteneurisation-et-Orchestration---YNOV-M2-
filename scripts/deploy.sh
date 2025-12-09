#!/bin/bash

# M2Cloud Deployment Script
set -e

NAMESPACE="m2cloud"
HELM_RELEASE="m2cloud"

echo "🚀 M2Cloud Kubernetes Deployment"
echo "================================="

# Check prerequisites
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed."; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ helm is required but not installed."; exit 1; }

# Create namespace if not exists
echo "📦 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply monitoring stack
echo "📊 Deploying monitoring stack..."
kubectl apply -f k8s/monitoring/prometheus-namespace.yaml
kubectl apply -f k8s/monitoring/

# Apply logging stack
echo "📝 Deploying logging stack..."
kubectl apply -f k8s/logging/

# Deploy with Helm
echo "🎯 Deploying M2Cloud application..."
helm upgrade --install $HELM_RELEASE ./helm/m2cloud \
  --namespace $NAMESPACE \
  --wait \
  --timeout 10m

# Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=web -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=applicants-api -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=jobs-api -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=identity-api -n $NAMESPACE --timeout=300s

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Pod Status:"
kubectl get pods -n $NAMESPACE
echo ""
echo "🌐 Services:"
kubectl get svc -n $NAMESPACE
echo ""
echo "📈 HPA Status:"
kubectl get hpa -n $NAMESPACE
