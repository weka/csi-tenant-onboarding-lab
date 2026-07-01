# Configuring the WEKA CSI plugin with limited tenant credentials

How to give a tenant's Kubernetes cluster access to WEKA storage over the CSI plugin
using **limited, tenant-scoped credentials instead of cluster-admin credentials.**

All commands and manifests below were validated end-to-end against WEKA 4.4.10 with
CSI plugin v2.8.8 and directory-backed (`dir/v1`) volumes.

---

## TL;DR

1. Never put `admin`/ClusterAdmin credentials in the CSI Secret.
2. Create a dedicated WEKA user per tenant with the purpose-built **`csi` role** —
   it grants exactly the operations the provisioner needs and nothing else.
3. Choose an isolation model:
   - **Model A — dedicated Organization** (recommended for multi-tenant): the
     tenant's `csi` user lives in its own WEKA Organization and can only see that
     org's filesystems.
   - **Model B — root org + dedicated filesystem**: simpler, but the user has no org
     boundary; it is fenced only by the StorageClass + a capacity quota.

## The `csi` role

WEKA provides a dedicated role for exactly this purpose:

```bash
weka user add <username> csi <password>
```

Use it for the tenant's CSI credentials in both models. It is the least-privilege
answer — no ClusterAdmin, no OrgAdmin required.

## The CSI Secret (what the tenant receives)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: csi-wekafs-api-secret
  namespace: csi-wekafs
type: Opaque
stringData:
  username: <tenant-csi-user>
  password: <password>
  organization: <org-name-or-Root>      # tenant org (Model A) or Root (Model B)
  scheme: https                          # HTTPS is mandatory on WEKA 4.3+
  endpoints: "<backend-ip>:14000,<backend-ip>:14000"
  # For a private/self-signed API cert, provide the CA (recommended for prod):
  caCertificate: ""                      # base64-encoded PEM
```

The StorageClass wires this Secret into all five external-provisioner secret slots
and pins the filesystem:

```yaml
parameters:
  volumeType: dir/v1
  filesystemName: <tenant-fs>
  capacityEnforcement: HARD
  csi.storage.k8s.io/provisioner-secret-name: csi-wekafs-api-secret
  csi.storage.k8s.io/provisioner-secret-namespace: csi-wekafs
  # (…controller-publish / controller-expand / node-stage / node-publish: same)
```

---

## Model A — dedicated Organization (recommended)

Provider (WEKA cluster admin):
```bash
weka org add <tenant-org> <tenant-admin> <admin-pw> --ssd-quota 300GB --total-quota 300GB
weka user login <tenant-admin> <admin-pw> --org <tenant-org>
weka fs add <tenant-fs> default 100GB          # filesystem lives inside the org
weka user add <tenant-csi-user> csi <csi-pw>   # scoped CSI credential
```

The CSI Secret uses `organization: <tenant-org>`. The tenant's CSI user cannot see
or touch any other org's filesystems — verified: a filesystem created in the org is
not even visible to a cluster admin listing the root org.

## Model B — root org, dedicated filesystem

Provider:
```bash
weka fs add <tenant-fs> default 100GB
weka user add <tenant-csi-user> csi <csi-pw>
```

The CSI Secret uses `organization: Root`. Isolation relies on the `csi` role + the
StorageClass `filesystemName` pin + a capacity quota — there is no hard org
boundary. Prefer Model A for real multi-tenancy.

---

## Node prerequisite

The CSI plugin's wekafs transport requires the **WEKA client running on each k8s
node**. On each node:

```bash
curl -s http://<backend-ip>:14000/dist/v1/install | sudo sh   # install agent
sudo weka version get <cluster-version>                        # client software
sudo weka local setup container --name client --client \
  --net udp --core-ids <core> --join-ips <backend-ips>         # join the cluster
```

Then install the plugin (Helm chart `csi-wekafs/csi-wekafsplugin`). If the WEKA API
uses a self-signed certificate, either provide `caCertificate` in the Secret
(recommended) or set `pluginConfig.allowInsecureHttps=true`.

---

## Verified

Both models were run end-to-end in a lab: a tenant's single-node Kubernetes cluster
provisioned and mounted `dir/v1` PVCs against WEKA using only its scoped `csi`-role
credentials — PVCs Bound, pods reading/writing, and (Model A) full org isolation
from other tenants. No admin credentials were used anywhere in the tenant's config.

Full command transcript with the actual output: [lab-evidence.md](lab-evidence.md).
