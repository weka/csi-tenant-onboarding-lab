# Tenant runbook — consuming WEKA storage from your k8s cluster

What the tenant does on their host to consume WEKA storage over CSI. Verified with
single-node k3s on Ubuntu 22.04, WEKA 4.4.10, CSI plugin v2.8.8.

## Prerequisites from the provider

- The scoped CSI credential + connection info (see the
  [provider runbook](provider-runbook.md) hand-off table).
- Network reachability from this host to the WEKA management endpoints (`:14000`)
  and the data path.
- **OS**: use a kernel the WEKA client supports — WEKA 4.4.10's driver fails to
  build on kernel ≥ 6.17 (Ubuntu 24.04). Ubuntu 22.04 is safe.

## 1. Kubernetes

Stand up your cluster (any conformant k8s; this lab used single-node k3s):
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml   # or ~/.kube/config
kubectl get nodes        # Ready
```

## 2. Install the WEKA client on the node

The CSI wekafs transport requires a running WEKA client on each node. Install deps
first (**gcc-12** is required to build the wekafs driver on Ubuntu 22.04):
```bash
sudo apt-get install -y gcc-12 make "linux-headers-$(uname -r)"
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
sudo update-alternatives --set gcc /usr/bin/gcc-12

# agent + CLI, then the matching WEKA version, then a client container
curl -s http://<backend-ip>:14000/dist/v1/install | sudo sh
sudo weka version get <cluster-version>
sudo weka local setup container --name client --client \
  --net udp --core-ids <core> --join-ips <backend-ips>
weka local ps        # STATE=Running, STATUS=Ready
```
> `--net udp` for UDP-mode clusters (no DPDK). `--core-ids` is required when cgroups
> are disabled (auto core allocation fails otherwise).

## 3. Install the WEKA CSI plugin

```bash
helm repo add csi-wekafs https://weka.github.io/csi-wekafs && helm repo update
helm upgrade --install csi-wekafs csi-wekafs/csi-wekafsplugin \
  --version 2.8.1 \                               # pin to match the customer's CSI version
  --namespace csi-wekafs --create-namespace \
  --set pluginConfig.allowInsecureHttps=true      # lab self-signed API; prod: use caCertificate
kubectl -n csi-wekafs get pods     # controller 5/5, node 3/3
```

## 4. Create the Secret, StorageClass, and a workload

Use the manifests in [`examples/01-org-tenant/`](../examples/01-org-tenant/) (org
model) or [`examples/02-root-org-tenant/`](../examples/02-root-org-tenant/) (root
model):
```bash
cp csi-secret.example.yaml csi-secret.yaml   # fill in the provider-supplied values
kubectl apply -f csi-secret.yaml
kubectl apply -f storageclass.yaml
kubectl apply -f pvc-and-pod.yaml
```

## 5. Verify

```bash
kubectl get pvc          # STATUS=Bound
kubectl get pod          # Running
kubectl exec <pod> -- sh -c 'mount | grep /data; cat /data/temp.txt'
#   /data is a `type wekafs` mount; the file is readable/writable
```

See [lab-evidence.md](lab-evidence.md) for a full captured transcript, and each
example's `verify.md` for per-model results.

## Troubleshooting

- **CSI controller crash-loops / healthz fails** → the API cert isn't trusted; set
  `pluginConfig.allowInsecureHttps=true` (lab) or provide `caCertificate` (prod).
- **`CSI Probe FAILED: Weka driver not running on host`** → the WEKA client isn't
  running; complete step 2 (`weka local ps` must show the container `Running`).
- **PVC stuck `Pending`** → check the controller logs
  (`kubectl -n csi-wekafs logs deploy/csi-wekafs-controller -c wekafs`); usually the
  API connection (endpoint/scheme/creds) or a not-ready driver.
