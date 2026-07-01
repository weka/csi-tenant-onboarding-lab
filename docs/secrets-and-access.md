# Secrets & access: giving a tenant CSI access without admin credentials

This document covers configuring the WEKA CSI plugin to use **limited
tenant-/filesystem-specific credentials instead of admin credentials**. `examples/01`
and `examples/02` are the runnable manifests.

Verified against the official
[csi-wekafs examples](https://github.com/weka/csi-wekafs/tree/master/examples) and
the WEKA multi-tenancy role model. See [REFERENCES.md](REFERENCES.md).

## What the tenant receives

To use the WEKA CSI plugin the tenant needs exactly two things from the operator:

1. **Network reachability** from the baremetal host to the WEKA management
   endpoints (and the data path).
2. **A Kubernetes Secret** holding a WEKA API user's credentials + connection info.
   The StorageClass points the CSI controller/node at this Secret.

The entire "should I hand over admin creds?" question reduces to **which WEKA user
goes in that Secret, and what that user is allowed to do.** Answer: a dedicated,
tenant-scoped user — never `admin`/ClusterAdmin.

## Anatomy of the CSI Secret

Keys (from the official `examples/common/csi-wekafs-api-secret.yaml`):

| Key | Meaning | Least-privilege note |
|---|---|---|
| `username` | WEKA API user | **The lever.** A dedicated per-tenant user, never `admin`. |
| `password` | that user's password | rotate independently of the operator's admin creds |
| `organization` | WEKA Organization of the user | `Root` for root-org model; tenant org name for the Organization model |
| `scheme` | `http` / `https` | **HTTPS is mandatory since Weka 4.3.0** — use `https` |
| `endpoints` | comma-separated `host:port` of mgmt IPs | ≥2 backends, or a load balancer |
| `autoUpdateEndpoints` | auto-refresh endpoints on login | `true` only for autoscaling backends *without* an LB; else `false` |
| `localContainerName` | pin the client container | set only on multi-cluster hosts; else `""` |
| `nfsTargetIps` | NFS transport targets | only when using NFS without NFS-group IPs |
| `caCertificate` | base64 PEM CA | for `https` with a private/self-signed CA |

The Secret lives in a namespace in the **tenant's** k8s cluster (default
`csi-wekafs`). The StorageClass wires it into all five external-provisioner secret
slots (provisioner / controller-publish / controller-expand / node-stage /
node-publish). Restrict read access to that Secret via k8s RBAC — that is part of
the isolation story.

> The official template uses `data:` (base64-encoded values). The examples here use
> `stringData:` (plaintext) so they read as templates; Kubernetes base64-encodes on
> write, so the two are equivalent.

## The anti-pattern to replace

```yaml
# DON'T: cluster-admin creds in the tenant's CSI Secret (this is the official
# example's default — fine for a single-tenant demo, wrong for a real tenant)
stringData:
  username: admin            # ClusterAdmin — cluster-wide reach
  organization: Root
  password: <cluster-admin-password>
```

Anyone who can read this Secret — plus the CSI controller acting on PVC requests —
can operate cluster-wide on WEKA. Replace with one of the two models below.

## The WEKA role model (why the two models differ)

From WEKA's multi-tenancy design (roles confirmed on 4.4.10, `weka user add <name> <role>`):

- **ClusterAdmin** — org-admin of the global org; manages organizations, HW, and
  **fs-groups**; **cannot** view/manage filesystems or users inside other orgs.
- **OrganizationAdmin** (`orgadmin`) — full admin *within one organization*. Cannot
  see other orgs. **Cannot manage fs-groups** (those stay cluster-level).
- **regular** — within its org: view, and create/delete/update filesystems.
- **readonly** — view only, within its org.
- **`csi`** — ⭐ **a dedicated, purpose-built role for the CSI plugin.** This is the
  right least-privilege choice for the tenant's CSI credentials — it grants exactly
  the operations the provisioner needs (create/delete directories, quotas,
  snapshots on filesystems) and nothing else. Use it in **both** models.
- **`s3`** — for S3 access (not relevant here).

Organizations are WEKA's hard multi-tenancy boundary: even a ClusterAdmin cannot
see inside another org's filesystems/users. That is what Model A buys — combined
with the `csi` role, the tenant gets least-privilege *and* org isolation.

---

## Model A — dedicated WEKA Organization (strong isolation) — recommended

Operator creates an **Organization** for the tenant + an **OrganizationAdmin** user
scoped to it. For **directory-backed** volumes, the operator also
pre-creates the filesystem the tenant's PVCs carve directories from (fs-groups are
cluster-level, so the FS is created inside the org by the operator).

**Secret handed to the tenant** (`examples/01-org-tenant/`):
```yaml
stringData:
  username: tenant-a-csi
  organization: tenant-a     # ← the tenant's org, not Root
  password: <tenant-a-password>
  scheme: https
  endpoints: 10.0.0.11:14000,10.0.0.12:14000
```

**Blast radius:** confined to `tenant-a`. The user cannot enumerate or touch
other tenants' filesystems; capacity is bounded by the org. For `dir/v1` an
OrganizationAdmin is a clean scoped choice (a `regular` org user may also suffice —
see OPEN-QUESTIONS #4). Recommended for a real multi-tenant platform.

---

## Model B — root org, dedicated filesystem (simpler, weaker)

No Organization. The tenant gets a **non-admin** (`regular`) user in the root org,
fenced to a pre-created filesystem via the StorageClass + a capacity quota.

**Secret handed to the tenant** (`examples/02-root-org-tenant/`):
```yaml
stringData:
  username: tenant-a-csi
  organization: Root
  password: <tenant-a-password>
  scheme: https
  endpoints: 10.0.0.11:14000,10.0.0.12:14000
```

**Blast radius:** a `regular` user in the root org can **view all filesystems
cluster-wide** — there is no org boundary. Isolation relies entirely on (a) the
non-admin role, (b) the StorageClass pinning `filesystemName`, and (c) a capacity
quota. Reserve Model B for single-tenant or trusted setups; document the gap.

---

## How provisioning mode changes the minimum privilege

- **Directory-backed (`dir/v1`)** — operator pre-creates the filesystem; CSI only
  creates directories + quotas inside it. **Lowest privilege.** This is the
  primary example.
- **Filesystem-backed (`fs`)** — CSI creates a **new filesystem per PVC**, requiring
  filesystem-create privilege: OrganizationAdmin within the org (Model A) or a
  cluster-level right (Model B). Higher blast radius. Documented alternative only.

## Operational hygiene (both models)

- One WEKA user **per tenant**, named for the tenant — never shared, never `admin`.
- Rotate the tenant's password independently of the operator's admin creds.
- Restrict read access to the k8s Secret via RBAC to the tenant platform team.
- Use `https` (+ `caCertificate` for a private CA) — mandatory since Weka 4.3.0.
- Set a capacity quota (org capacity, or per-filesystem) so a tenant cannot exhaust
  the cluster.
