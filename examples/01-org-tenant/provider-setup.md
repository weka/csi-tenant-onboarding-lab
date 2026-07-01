# Provider setup — Model A (dedicated WEKA Organization)

Run on the WEKA cluster as ClusterAdmin. Verified against WEKA 4.4.10.

```bash
# 1. Create the tenant's organization + its org-admin (one command).
#    This is a hard multi-tenancy boundary — even ClusterAdmin can't see inside.
weka org add tenant-a tenant-a-admin <admin-pw> \
  --ssd-quota 300GB --total-quota 300GB

# 2. Switch into the org and pre-create the filesystem the tenant's PVCs will
#    carve directories from. fs-groups are cluster-level, so use the existing
#    'default' group; the filesystem itself lives in the org. dir/v1 needs the FS
#    to already exist.
weka user login tenant-a-admin <admin-pw> --org tenant-a
weka fs add tenant-a-fs default 100GB

# 3. Add the SCOPED CSI user — the dedicated 'csi' role (least privilege), NOT admin.
weka user add tenant-a-csi csi <csi-pw>
```

> On this SSD-only cluster the module's `default` fs is thick-provisioned to nearly
> all SSD; free some first with `weka fs update default --total-capacity 200GB`
> (non-tiered fs: pass only `--total-capacity`, not `--ssd-capacity`).

Hand to the tenant (goes into `csi-secret.yaml`):

| Item | Value |
|---|---|
| `username` | `tenant-a-csi` |
| `password` | (set above) |
| `organization` | `tenant-a` |
| `endpoints` | ≥2 mgmt IPs, e.g. `10.0.0.11:14000,10.0.0.12:14000` |
| `scheme` | `https` |
| `caCertificate` | base64 PEM if using a private CA |

**Isolation:** the tenant's CSI can only see/act within `tenant-a`, up to
the org's capacity. Other tenants' filesystems are invisible.
