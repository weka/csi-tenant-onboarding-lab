# Secrets & access: giving a tenant CSI access without admin credentials

> **Status: first pass — verify against official docs before sending to Coupang.**
> Confirm the Secret key names, the StorageClass secret wiring, and the minimum
> WEKA role names against the
> [csi-wekafs examples](https://github.com/weka/csi-wekafs/tree/master/examples)
> and the internal CSI setup pages (Sergey's series). See
> [OPEN-QUESTIONS.md](OPEN-QUESTIONS.md).

## What the tenant actually receives

To use the WEKA CSI plugin the tenant needs exactly two things from the operator:

1. **Network reachability** to the WEKA cluster management endpoints (and data
   path) from the baremetal host.
2. **A Kubernetes Secret** holding a WEKA API user's credentials + connection
   info. The StorageClass points the CSI controller/node at this Secret.

Everything the "should I hand over admin creds?" question hinges on is **which
WEKA user goes into that Secret, and what that user is allowed to do.**

## Anatomy of the CSI Secret

The CSI plugin reads a Kubernetes Secret (referenced from the StorageClass). Its
fields:

| Key | Meaning | Least-privilege note |
|---|---|---|
| `username` | WEKA API user | **This is the lever.** Use a dedicated tenant user, never `admin`. |
| `password` | that user's password | rotate independently of the operator's admin creds |
| `organization` | WEKA Organization the user belongs to | `Root` for root-org model; tenant org name for the Organization model |
| `scheme` | `http` / `https` | use `https` in production |
| `endpoints` | comma-separated `host:port` of WEKA management IPs | e.g. `10.0.0.11:14000,10.0.0.12:14000` |
| `caCertificate` | (optional) CA cert for `https` | for custom/private CA |
| `localContainerName` | (optional) name of a pre-installed client container | omit for stateless CSI-managed client |

The Secret is namespaced in the tenant's k8s cluster. The StorageClass wires it in
via the standard external-provisioner parameters
(`csi.storage.k8s.io/{provisioner,controller-publish,node-stage,node-publish,controller-expand}-secret-name`
and matching `-secret-namespace`). Keeping the Secret in a namespace only the
tenant platform team can read is part of the isolation story.

## The anti-pattern to replace

```yaml
# DON'T: cluster-admin creds in the tenant's CSI Secret
stringData:
  username: admin            # ClusterAdmin — cluster-wide reach
  organization: Root
  password: <cluster-admin-password>
```

Any principal that can read this Secret, plus the CSI controller acting on PVC
requests, can now operate cluster-wide on WEKA. Replace with one of the two
models below.

---

## Model A — dedicated WEKA Organization (strong isolation)

The operator creates a WEKA **Organization** for the tenant and an **OrgAdmin**
user scoped to it. WEKA Organizations are the native multi-tenancy boundary: the
org's users can only see and act on that org's filesystems, object stores, and
users, up to the org's capacity quota.

**Operator side (provider):**
```
weka org create coupang-tenant-a --total-capacity <quota>
weka user add tenant-a-csi <password> --org coupang-tenant-a --role OrgAdmin
# (role name to confirm — OrgAdmin is required if CSI must create filesystems;
#  a lower role may suffice for directory-backed PVCs — see below)
```

**Secret handed to the tenant:**
```yaml
stringData:
  username: tenant-a-csi
  organization: coupang-tenant-a     # ← the tenant's org, not Root
  password: <tenant-a-password>
  scheme: https
  endpoints: 10.0.0.11:14000,10.0.0.12:14000
```

**Blast radius:** confined to `coupang-tenant-a`. The user cannot enumerate or
touch other tenants' filesystems. Capacity is bounded by the org quota. This is
the recommended model for a real multi-tenant platform.

---

## Model B — root org, dedicated filesystem (simpler, weaker)

No Organization. The tenant gets a **non-admin** user in the root org, and is
fenced to a pre-created filesystem via the StorageClass and a capacity quota.

**Operator side (provider):**
```
weka fs create tenant-a-fs --group <fs-group> --capacity <quota>
weka user add tenant-a-csi <password> --role ReadWrite    # NOT ClusterAdmin
# (role must allow the CSI operations you need; verify minimum — see OPEN-QUESTIONS)
```

**Secret handed to the tenant:**
```yaml
stringData:
  username: tenant-a-csi
  organization: Root
  password: <tenant-a-password>
  scheme: https
  endpoints: 10.0.0.11:14000,10.0.0.12:14000
```

**Blast radius:** the credential lives in the root org, so isolation depends on
(a) the user's role being non-admin, (b) the StorageClass pinning a specific
filesystem, and (c) a capacity quota. There is no hard org boundary — document
this as a known limitation and reserve Model B for single-tenant or trusted
setups.

---

## How provisioning mode changes the minimum privilege

The required role depends on what the CSI plugin has to *do* on the WEKA side:

- **Directory-backed (`dir/v1`)** — the operator pre-creates the filesystem; CSI
  only creates directories and sets quotas inside it. This needs the **lower**
  privilege and is the better least-privilege fit. Coupang referenced this mode
  on the 2026-06-30 call.
- **Filesystem-backed (`fs`)** — CSI creates a **new filesystem per PVC**, which
  requires filesystem-create privilege: **OrgAdmin** within the org (Model A) or a
  cluster-level right (Model B). Higher blast radius.

> **Recommendation:** pair least-privilege with directory-backed provisioning.
> Model A + `dir/v1` gives strong isolation *and* the smallest role. This is
> pending the provisioning-mode decision in
> [OPEN-QUESTIONS.md](OPEN-QUESTIONS.md).

## Operational hygiene (both models)

- One WEKA user **per tenant**, named for the tenant — never shared, never `admin`.
- Rotate the tenant's password independently; rotating it must not touch the
  operator's admin creds.
- Restrict read access to the k8s Secret to the tenant platform team (RBAC).
- Prefer `https` + `caCertificate` for the management connection.
- Set a capacity quota (org total-capacity, or per-filesystem) so a tenant cannot
  exhaust the cluster.
