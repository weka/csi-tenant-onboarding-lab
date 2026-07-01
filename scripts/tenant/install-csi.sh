#!/usr/bin/env bash
# Install the WEKA CSI plugin on the tenant's single-node k8s cluster.
# Prereq: the WEKA client must already be installed + running on the node (see below).
set -euo pipefail

NS=csi-wekafs
# Pin the CSI plugin chart version to match the customer's deployed version, so the
# lab behaves the same as their environment. Override with: CSI_VERSION=x.y.z ./install-csi.sh
CSI_VERSION="${CSI_VERSION:-2.8.1}"

helm repo add csi-wekafs https://weka.github.io/csi-wekafs
helm repo update

echo "Installing WEKA CSI plugin chart version ${CSI_VERSION}"
# NOTE: the wekafs transport needs a running WEKA client on the host first
# (agent install + `weka version get` + `weka local setup container --client`).
# See lab/LAB.md §3. allowInsecureHttps=true is for a self-signed WEKA API cert
# (lab); in production omit it and put a caCertificate in the Secret instead.
helm upgrade --install csi-wekafs csi-wekafs/csi-wekafsplugin \
  --version "$CSI_VERSION" \
  --namespace "$NS" --create-namespace \
  --set pluginConfig.allowInsecureHttps=true

echo
echo "CSI plugin installed. Next (from an examples/*/ dir):"
echo "  cp csi-secret.example.yaml csi-secret.yaml   # fill real, tenant-scoped values"
echo "  kubectl apply -f csi-secret.yaml"
echo "  kubectl apply -f storageclass.yaml"
echo "  kubectl apply -f pvc-and-pod.yaml"
