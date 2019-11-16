#!/bin/bash

# kubectl apply -f /home/gabeduke/repos/civo/civo-iot/kubernetes-marketplace/prometheus-operator/app.yaml

NAMESPACE=monitoring
HELM_CHART_VERSION=6.20.3

# Create the namespace for prometheus-operator
kubectl create namespace ${NAMESPACE}

# Update your local Helm chart repository cache
helm repo update

# Ensure CRDs exist
checkCRDs () {
  kubectl -n ${NAMESPACE} wait --for condition=established --timeout=60s crd/alertmanagers.monitoring.coreos.com
  kubectl -n ${NAMESPACE} wait --for condition=established --timeout=60s crd/podmonitors.monitoring.coreos.com
  kubectl -n ${NAMESPACE} wait --for condition=established --timeout=60s crd/prometheuses.monitoring.coreos.com
  kubectl -n ${NAMESPACE} wait --for condition=established --timeout=60s crd/prometheusrules.monitoring.coreos.com
  kubectl -n ${NAMESPACE} wait --for condition=established --timeout=60s crd/servicemonitors.monitoring.coreos.com
}

BACKOFF=1
until checkCRDs || [ $BACKOFF -eq 10 ]; do
  printf 'Waiting for CRDs to exist...'
  sleep $(( BACKOFF++ ))
done

# Install the prometheus-operator Helm chart
helm install \
  --namespace monitoring \
  --set prometheusOperator.createCustomResource=false \
  --version 8.2.2 \
  prometheus-operator stable/prometheus-operator
