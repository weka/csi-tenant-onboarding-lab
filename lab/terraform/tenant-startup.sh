#!/usr/bin/env bash
# Tenant node bootstrap: single-node k3s + helm + build deps the WEKA CSI client
# needs to compile the wekafs gateway module against the host kernel.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
# WEKA 4.4.x client gateway module needs gcc-12 to compile (Ubuntu 22.04 defaults
# to gcc-11, which fails the build). Install gcc-12 and make it the default gcc.
apt-get install -y curl ca-certificates make gcc gcc-12 "linux-headers-$(uname -r)"
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
update-alternatives --set gcc /usr/bin/gcc-12

# Single-node k3s (world-readable kubeconfig so the 'weka' user can use it).
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -

# Helm 3.
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# kubeconfig for the weka user.
install -d -o weka -g weka /home/weka/.kube
cp /etc/rancher/k3s/k3s.yaml /home/weka/.kube/config
chown weka:weka /home/weka/.kube/config
echo 'export KUBECONFIG=/home/weka/.kube/config' >> /home/weka/.bashrc

touch /home/weka/.tenant-bootstrap-done
