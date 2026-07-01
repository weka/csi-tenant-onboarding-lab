# Provider setup — Model A (dedicated WEKA Organization)

Run on the WEKA cluster as ClusterAdmin. **Confirm CLI syntax/role names against
the WEKA version on the cluster** — the `weka org` / `weka user` interface has
evolved across versions (see OPEN-QUESTIONS #4).

```bash
# 1. Create the tenant's organization (hard multi-tenancy boundary).
#    Even ClusterAdmin cannot see inside it afterward.
weka org create coupang-tenant-a

# 2. Pre-create the filesystem the tenant's PVCs will carve directories from.
#    fs-groups are cluster-level (ClusterAdmin owns them); the filesystem itself
#    lives in the tenant's org. dir/v1 needs the FS to already exist.
weka fs create tenant-a-fs <fs-group-name> <capacity> --org coupang-tenant-a

# 3. Add a SCOPED user for CSI — OrganizationAdmin within the org, NOT ClusterAdmin.
#    (A 'regular' org user may also suffice for dir/v1 — verify.)
weka user add tenant-a-csi <password> --org coupang-tenant-a --role org-admin
```

Hand to the tenant (goes into `csi-secret.yaml`):

| Item | Value |
|---|---|
| `username` | `tenant-a-csi` |
| `password` | (set above) |
| `organization` | `coupang-tenant-a` |
| `endpoints` | ≥2 mgmt IPs, e.g. `10.0.0.11:14000,10.0.0.12:14000` |
| `scheme` | `https` |
| `caCertificate` | base64 PEM if using a private CA |

**Isolation:** the tenant's CSI can only see/act within `coupang-tenant-a`, up to
the org's capacity. Other tenants' filesystems are invisible.
