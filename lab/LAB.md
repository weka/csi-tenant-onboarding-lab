# Lab runbook — traditional WEKA cluster + tenant k8s + CSI

End-to-end lab that stands up a **traditional (non-operator) WEKA cluster** on GCP
and a separate **tenant** node running its own single-node k8s (k3s) that consumes
the cluster over the WEKA CSI plugin with **tenant-scoped credentials**.

- GCP project: `your-gcp-project` (auth: `<your-gcloud-user>` ADC)
- WEKA: 4.4.10.171, 6× c2-standard-16 backends, UDP mode, dedicated VPC
- Tenant: 1× n2-standard-4, Ubuntu 22.04 (kernel < 6.17 so wekafs compiles), k3s
- Terraform: `lab/terraform/` (reuses the official `weka/weka/gcp` module)

> **Recommended: run in a disposable project with SA impersonation** so a stray
> command can never touch shared resources and your login needs near-zero standing
> access. One-time: `scripts/provider/bootstrap-project.sh <project> <billing>`.
> Full rationale + steps: [../docs/lab-isolation.md](../docs/lab-isolation.md).

## 1. Bring up the infrastructure

Using the isolated flow (set `TF_VAR_project` + `TF_VAR_impersonate_service_account`
per [../docs/lab-isolation.md](../docs/lab-isolation.md)); or directly against a
project you own:

```bash
cd lab/terraform
export CLOUDSDK_ACTIVE_CONFIG_NAME=default   # <your-gcloud-user> / your-gcp-project
export TF_VAR_get_weka_io_token=$(gcloud secrets versions access latest \
  --secret=get-weka-io-<your-user> --project your-gcp-project)

terraform init
terraform apply           # ~15 min: WEKA cluster formation + tenant VM

terraform output          # backend_lb_ip, tenant_public_ip, helper_commands, ...
```

Get the WEKA admin password:
```bash
gcloud secrets versions access latest \
  --secret=csi-tenant-csi-tenant-password --project your-gcp-project \
  --format='get(payload.data)' | base64 -d
```

## 2. WEKA-side tenant provisioning

SSH to a backend (`weka` user), `weka user login admin <pw>`, then create the
org/fs/users. Verified CLI in
[../examples/01-org-tenant/provider-setup.md](../examples/01-org-tenant/provider-setup.md)
and [../examples/02-root-org-tenant/provider-setup.md](../examples/02-root-org-tenant/provider-setup.md).
Use the dedicated **`csi`** role for the tenant users (least privilege).

## 3. Tenant node: install the WEKA client, then CSI

⚠️ **The CSI plugin's wekafs transport requires a running WEKA client on the host.**
It is not fully self-contained — `tenant-startup.sh` only lays down k3s + gcc-12.
After the cluster is up, install the client on the tenant (`weka@<tenant_public_ip>`):

```bash
BACKEND=10.0.0.3        # any backend mgmt IP / the LB IP

# a. install the WEKA agent + CLI from the cluster
curl -s http://$BACKEND:14000/dist/v1/install | sudo sh

# b. download the matching WEKA version (builds client bits; needs gcc-12)
sudo weka version get 4.4.10.171

# c. create a stateless UDP client container joined to the backends.
#    --net udp (backends are UDP, GCP has no DPDK); --core-ids required because
#    cgroups are disabled on this image (auto core allocation fails otherwise).
sudo weka local setup container --name client --client --net udp --core-ids 1 \
  --join-ips 10.0.0.4,10.0.0.5,10.0.0.6,10.0.0.7,10.0.0.8,10.0.0.9
weka local ps          # STATE=Running, STATUS=Ready
```

Then install the CSI plugin. **Set `allowInsecureHttps=true`** — the WEKA API on
:14000 uses a self-signed cert; without this the controller crash-loops on failed
health probes. (In production, provide `caCertificate` in the Secret instead.)

```bash
export KUBECONFIG=/home/weka/.kube/config
helm repo add csi-wekafs https://weka.github.io/csi-wekafs && helm repo update
helm upgrade --install csi-wekafs csi-wekafs/csi-wekafsplugin \
  --version 2.8.1 \                     # pin to match the customer's CSI version
  --namespace csi-wekafs --create-namespace \
  --set pluginConfig.allowInsecureHttps=true
kubectl -n csi-wekafs get pods        # controller 5/5, node 3/3, no restarts
```

Then apply the tenant-scoped Secret + `dir/v1` StorageClass + PVC/pod (set
`endpoints` = `<backend_lb_ip>:14000`, `scheme: https`, real password). Captured
results in each example's `verify.md`.

## 4. Teardown  ⚠️ order matters

The WEKA module needs its terminate hook called **before** destroy, or backends
leak / destroy hangs:

```bash
# 1. call the terminate hook (helper_commands.pre_terraform_destroy)
terraform output -raw terminate_cluster_uri   # then curl it per module docs
# 2. then destroy
terraform destroy
```

## Known gotchas

- **Kernel:** Weka 4.4.10 client gateway module fails to compile on kernel ≥ 6.17
  (Ubuntu 24.04). Tenant is pinned to Ubuntu 22.04 for this reason.
- **Compiler:** the client gateway build needs **gcc-12**; Ubuntu 22.04 defaults to
  gcc-11. `tenant-startup.sh` installs gcc-12 and sets it as the default `gcc`.
- **DPDK:** GCP c2-standard-16 can't do DPDK setup → UDP mode (`install_cluster_dpdk=false`).
- **Firewall:** a `protocol=all` rule scoped to the lab VPC's own subnet CIDR gives
  the tenant full L4 reachability to backends (UDP-mode WEKA uses a wide port range).
- **Client required:** CSI wekafs transport needs a running WEKA client on the host
  (agent install + `weka version get` + `weka local setup container --client`). It
  is *not* fully agentless. The probe fails with "Weka driver not running on host"
  until the client container is `Running`.
- **Self-signed API:** set `pluginConfig.allowInsecureHttps=true` (lab) or supply
  `caCertificate` (prod) — otherwise the controller crash-loops on health probes.
- **cgroups disabled:** on this image `weka local setup container` needs explicit
  `--core-ids` (auto core allocation errors out).
- **`weka fs add`** (not `fs create`); **`weka org add <name> <user> <pw>`** creates
  org + org-admin together; tenant user role = **`csi`**.
