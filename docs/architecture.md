# Architecture & trust boundary

How a tenant's Kubernetes cluster consumes a shared WEKA cluster over the CSI
plugin, and — the whole point — **where the trust boundary sits and what crosses
it.**

## The two sides

```
        PROVIDER (WEKA cluster operator)            │        TENANT
                                                     │
  ┌───────────────────────────────────────┐         │   ┌──────────────────────────────┐
  │  WEKA cluster  (traditional / backends)│         │   │  Baremetal host               │
  │                                        │         │   │  ┌────────────────────────┐   │
  │   Organizations ── filesystems         │         │   │  │ single-node Kubernetes │   │
  │   users/roles   ── fs-groups (cluster) │         │   │  │                        │   │
  │                                        │         │   │  │  WEKA CSI plugin        │   │
  │   Mgmt API :14000 (https) ─────────────┼─────────┼───┼─▶│   controller + node    │   │
  │   Data path (UDP / DPDK) ──────────────┼─────────┼───┼─▶│  StorageClass (dir/v1) │   │
  │                                        │         │   │  │  Secret: <csi-user>     │   │
  └───────────────────────────────────────┘         │   │  │  PVC ─▶ PV ─▶ Pod       │   │
                                                     │   │  │  WEKA client (wekafs)   │   │
                                                     │   │  └────────────────────────┘   │
                                                     │   └──────────────────────────────┘
                                          TRUST BOUNDARY
                                   (a scoped WEKA API credential)
```

- **Provider** owns the WEKA cluster: backends, the management API, filesystems,
  Organizations, users/roles, and capacity quotas. It also retains cluster-admin.
- **Tenant** owns its own baremetal host and Kubernetes cluster. It installs the
  WEKA CSI plugin and consumes storage. It never gets cluster-admin.

## The trust boundary

The boundary is a **single WEKA API credential** placed in a Kubernetes Secret in
the tenant's cluster. Everything the tenant's CSI can do on WEKA is bounded by that
user's **role + organization + quota**:

- **Role** = the dedicated **`csi`** role — exactly the operations the provisioner
  needs (create/delete directories, quotas, snapshots), nothing more. Never `admin`.
- **Organization** = the tenant's WEKA Organization (Model A) or `Root` (Model B).
  An org is a hard boundary: the credential cannot see other orgs' filesystems.
- **Quota** = org capacity (Model A) or per-filesystem capacity (Model B), so a
  tenant cannot exhaust the cluster.

The provider hands over that credential (+ the API endpoints and, in production, a
CA cert). Nothing else crosses the boundary.

## Components

| Side | Component | Role |
|---|---|---|
| Provider | WEKA backends + mgmt API (`:14000`, https) | storage + control plane |
| Provider | Organization / filesystem / `csi` user | the tenant's scoped slice |
| Tenant | Kubernetes (single-node k3s here) | the tenant's workload plane |
| Tenant | WEKA client (agent + wekafs driver) | mounts filesystems on the host |
| Tenant | CSI controller (Deployment) | calls the WEKA API to provision volumes |
| Tenant | CSI node (DaemonSet) | stages/publishes the wekafs mount into pods |
| Tenant | Secret + StorageClass + PVC | the tenant-scoped configuration |

## Connectivity

- **Management**: the CSI controller connects to the WEKA API `endpoints`
  (`<backend>:14000`, HTTPS — mandatory on WEKA 4.3+) using the Secret credential.
- **Data path**: the WEKA client on the host reaches the backends over the storage
  network. In this lab that is **UDP** mode (GCP c2 instances can't run DPDK);
  on suitable hardware it would be DPDK.
- The tenant host therefore needs L4 reachability to the WEKA backends on the
  management + data ports.

## Control flow (provisioning a volume)

1. Tenant creates a **PVC** referencing the `dir/v1` **StorageClass**.
2. The CSI **controller** reads the **Secret**, logs into the WEKA API as the
   scoped `csi` user, and creates a **directory + quota** inside the tenant's
   filesystem (`dir/v1/<fs>/csi-volumes/<pv-id>`).
3. The PVC binds to the resulting **PV**.
4. When a pod is scheduled, the CSI **node** plugin mounts that directory via the
   host's WEKA client (`type wekafs`) into the pod at its `mountPath`.

Because provisioning is directory-backed, the provider **pre-creates the
filesystem**; the tenant's credential only ever manipulates directories and quotas
inside it — the lowest-privilege footprint.

## The two isolation models on this architecture

- **Model A — dedicated Organization**: the `csi` user lives in the tenant's own
  WEKA Organization. The trust boundary is reinforced by WEKA's native org
  isolation — the credential cannot even see other orgs' filesystems. Recommended
  for multi-tenant platforms.
- **Model B — root org + dedicated filesystem**: the `csi` user is in `Root` and is
  fenced only by the StorageClass `filesystemName` pin + a quota. Simpler, weaker;
  reserve for single-tenant/trusted setups.

See [secrets-and-access.md](secrets-and-access.md) for the credential detail and
[lab-evidence.md](lab-evidence.md) for the validated command transcript.
