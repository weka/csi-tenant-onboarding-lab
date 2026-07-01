#!/usr/bin/env bash
# Install the WEKA CSI plugin on the tenant's single-node k8s cluster.
# Stateless / CSI-managed client (no manual `weka agent install` on the host).
set -euo pipefail

NS=csi-wekafs

helm repo add csi-wekafs https://weka.github.io/csi-wekafs
helm repo update

# NOTE: the wekafs transport needs a running WEKA client on the host first
# (agent install + `weka version get` + `weka local setup container --client`).
# See lab/LAB.md §3. allowInsecureHttps=true is for a self-signed WEKA API cert
# (lab); in production omit it and put a caCertificate in the Secret instead.
helm upgrade --install csi-wekafs csi-wekafs/csi-wekafsplugin \
  --namespace "$NS" --create-namespace \
  --set pluginConfig.allowInsecureHttps=true

echo
echo "CSI plugin installed. Next (from an examples/*/ dir):"
echo "  cp csi-secret.example.yaml csi-secret.yaml   # fill real, tenant-scoped values"
echo "  kubectl apply -f csi-secret.yaml"
echo "  kubectl apply -f storageclass.yaml"
echo "  kubectl apply -f pvc-and-pod.yaml"
