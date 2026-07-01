# Provider setup — Model B (root org, dedicated filesystem)

Run on the WEKA cluster as ClusterAdmin (in the root org). Verified against WEKA 4.4.10.

```bash
# 1. Pre-create a dedicated filesystem for the tenant.
#    This FS + the StorageClass pin are the ONLY isolation fence in this model.
weka fs add tenant-b-fs default 100GB

# 2. Add the SCOPED CSI user — the dedicated 'csi' role (least privilege), NOT admin.
weka user add tenant-b-csi csi <csi-pw>
```

Hand to the tenant (goes into `csi-secret.yaml`):

| Item | Value |
|---|---|
| `username` | `tenant-a-csi` |
| `password` | (set above) |
| `organization` | `Root` |
| `endpoints` | ≥2 mgmt IPs, e.g. `10.0.0.11:14000,10.0.0.12:14000` |
| `scheme` | `https` |

**Isolation caveat:** a root-org user has **no org boundary** to contain it. The
`csi` role limits *what* it can do, but the tenant is fenced only by the StorageClass
`filesystemName` pin and the FS capacity quota. Use Model B only for
single-tenant/trusted setups; prefer [Model A](../01-org-tenant/) for real
multi-tenancy.
