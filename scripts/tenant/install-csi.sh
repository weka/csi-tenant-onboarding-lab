#!/usr/bin/env bash
# Install the WEKA CSI plugin on the tenant's single-node k8s cluster.
# Stateless / CSI-managed client (no manual `weka agent install` on the host).
set -euo pipefail

NS=csi-wekafs

helm repo add csi-wekafs https://weka.github.io/csi-wekafs
helm repo update

# Default install runs the CSI-managed client. Verify client-mode + any needed
# values against the chart version you deploy:
#   helm show values csi-wekafs/csi-wekafsplugin
helm upgrade --install csi-wekafs csi-wekafs/csi-wekafsplugin \
  --namespace "$NS" --create-namespace

echo
echo "CSI plugin installed. Next (from an examples/*/ dir):"
echo "  cp csi-secret.example.yaml csi-secret.yaml   # fill real, tenant-scoped values"
echo "  kubectl apply -f csi-secret.yaml"
echo "  kubectl apply -f storageclass.yaml"
echo "  kubectl apply -f pvc-and-pod.yaml"
