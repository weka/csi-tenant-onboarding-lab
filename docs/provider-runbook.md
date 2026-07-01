# Provider runbook — onboarding a tenant (WEKA cluster operator)

What the WEKA cluster operator does to onboard a tenant. Verified against WEKA
4.4.10. Run these as ClusterAdmin (`weka user login admin <pw>`). Pick **one**
isolation model — see [secrets-and-access.md](secrets-and-access.md).

## Model A — dedicated Organization (recommended)

```bash
# 1. Create the tenant's organization + its org-admin, with a capacity quota.
#    This is a hard boundary: even ClusterAdmin can't see inside it afterward.
weka org add <tenant-org> <tenant-admin> <admin-pw> \
  --ssd-quota <quota> --total-quota <quota>

# 2. Switch into the org and pre-create the filesystem the tenant's PVCs will
#    carve directories from. fs-groups are cluster-level, so use the existing
#    'default' group; the filesystem itself lives in the org.
weka user login <tenant-admin> <admin-pw> --org <tenant-org>
weka fs add <tenant-fs> default <capacity>

# 3. Create the scoped CSI credential — the dedicated 'csi' role, NOT admin.
weka user add <tenant-csi-user> csi <csi-pw>
```

## Model B — root org, dedicated filesystem

```bash
weka fs add <tenant-fs> default <capacity>      # dedicated FS in the root org
weka user add <tenant-csi-user> csi <csi-pw>    # scoped 'csi' role, NOT admin
```

## Hand off to the tenant

Provide (these go into the tenant's CSI Secret):

| Item | Value |
|---|---|
| `username` | `<tenant-csi-user>` |
| `password` | (from above) |
| `organization` | `<tenant-org>` (Model A) or `Root` (Model B) |
| `endpoints` | ≥2 backend mgmt IPs, e.g. `10.0.0.11:14000,10.0.0.12:14000` |
| `scheme` | `https` (mandatory on WEKA 4.3+) |
| `caCertificate` | base64 PEM if the API uses a private/self-signed cert |

Also confirm: the tenant host has **network reachability** to the WEKA management
endpoints and data path, and (for the wekafs transport) will install the WEKA
client — see [tenant-runbook.md](tenant-runbook.md).

## Notes / gotchas

- **Capacity**: on an SSD-only lab cluster the module's `default` filesystem may be
  thick-provisioned to nearly all SSD. Free some first:
  `weka fs update default --total-capacity <smaller>` (non-tiered fs → pass only
  `--total-capacity`, not `--ssd-capacity`).
- **fs-groups are cluster-level**: an OrgAdmin can create filesystems in the org but
  cannot manage fs-groups; reuse the cluster `default` group.
- **Verify the credential is scoped**: `weka user` inside the org should show the
  `csi` user with role `CSI`; a `weka fs` listing in Root must NOT show the org's
  filesystem (proves isolation).
