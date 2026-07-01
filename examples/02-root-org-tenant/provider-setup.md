# Provider setup — Model B (root org, dedicated filesystem)

Run on the WEKA cluster as ClusterAdmin. **Confirm CLI syntax/role names against
the WEKA version on the cluster** (see OPEN-QUESTIONS #4).

```bash
# 1. Pre-create a dedicated filesystem for the tenant, with a capacity quota.
#    This FS + the StorageClass pin are the ONLY isolation fence in this model.
weka fs create tenant-a-fs <fs-group-name> <capacity>

# 2. Add a SCOPED user for CSI — a 'regular' (non-admin) user, NOT ClusterAdmin.
weka user add tenant-a-csi <password> --role regular
```

Hand to the tenant (goes into `csi-secret.yaml`):

| Item | Value |
|---|---|
| `username` | `tenant-a-csi` |
| `password` | (set above) |
| `organization` | `Root` |
| `endpoints` | ≥2 mgmt IPs, e.g. `10.0.0.11:14000,10.0.0.12:14000` |
| `scheme` | `https` |

**Isolation caveat:** a `regular` user in the root org can **view all filesystems
cluster-wide** — there is no org boundary. The tenant is fenced only by the
StorageClass `filesystemName` pin and the FS capacity quota. Use Model B only for
single-tenant/trusted setups; prefer [Model A](../01-org-tenant/) for real
multi-tenancy.
