# Provider runbook — onboarding a tenant (WEKA cluster operator)

_TODO — fill with validated CLI once provisioning mode is confirmed._

Outline:

1. Decide isolation model (Organization vs root-org + dedicated FS) — see
   [secrets-and-access.md](secrets-and-access.md).
2. **Model A:** `weka org create` + capacity quota; add OrgAdmin user scoped to org.
   **Model B:** `weka fs create` in a filesystem group with a quota; add a
   non-admin user.
3. Create the scoped WEKA API user (never hand over `admin`).
4. Provide the tenant: management `endpoints`, `scheme`, CA cert (if `https`),
   the username/password, and the org name.
5. Confirm network reachability from the tenant host to WEKA management + data path.
6. Hand off to the [tenant runbook](tenant-runbook.md).
