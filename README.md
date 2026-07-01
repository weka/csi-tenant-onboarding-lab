# csi-tenant-onboarding-lab

How to onboard a **tenant** who runs their own single-node Kubernetes cluster on a
baremetal host and consumes storage from a shared **WEKA** cluster via the
[WEKA CSI plugin](https://github.com/weka/csi-wekafs) — using **limited,
tenant-scoped credentials instead of cluster-admin credentials**.

> Origin: WEKA/Coupang weekly status call, 2026-06-30. Action item — provide the
> Coupang team guidance on configuring CSI to use limited tenant- or
> filesystem-specific credentials instead of admin credentials. This repo is that
> guidance, in runnable form.

## The problem this addresses

The path-of-least-resistance CSI install drops **cluster-admin** WEKA credentials
into a Kubernetes Secret. Any tenant who can read that Secret (or the CSI
controller acting on their behalf) then has cluster-wide reach on the WEKA side.
For a multi-tenant platform that is the wrong blast radius. This lab shows the
least-privilege alternatives.

## Two isolation models, side by side

| | `examples/01-org-tenant/` | `examples/02-root-org-tenant/` |
|---|---|---|
| WEKA isolation | Dedicated WEKA **Organization** | Root org, **dedicated filesystem** |
| Secret `organization` | tenant org name | `Root` |
| Handed-over user | **OrgAdmin scoped to that org** | non-admin user, fenced by filesystem + quota |
| Tenant can see | only their org's filesystems/objects | (relies on StorageClass + role to fence) |
| Isolation strength | strong, native to WEKA | weaker — mitigations documented |

Both examples use:
- **Directory-backed (`dir/v1`) volumes** — folder-based PVCs, matching Coupang's usage.
- **Stateless, CSI-managed client** — no manual `weka agent install` on the tenant host.
- The tenant runs a **single-node k8s** cluster on their baremetal host.

Manifests are derived from the official
[csi-wekafs `dynamic_directory` example](https://github.com/weka/csi-wekafs/tree/master/examples/dynamic_directory)
and the WEKA role model — see [docs/REFERENCES.md](docs/REFERENCES.md).

## Layout

```
docs/
  secrets-and-access.md   # ← core deliverable: exact creds + role scope per model
  REFERENCES.md           # official csi-wekafs examples + Sergey's design pages + role model
  architecture.md         # WEKA cluster ⇄ tenant k8s host; where the trust boundary sits
  provider-runbook.md     # what the WEKA cluster operator does to onboard a tenant
  tenant-runbook.md       # what the tenant does on their host (k8s + CSI install)
  OPEN-QUESTIONS.md       # remaining decisions (snapshots, MT 2.0, exact min role)
examples/
  01-org-tenant/          # dir/v1 via a dedicated WEKA Organization (recommended)
  02-root-org-tenant/     # dir/v1 on root org + dedicated filesystem
scripts/
  tenant/install-csi.sh   # helm install of the CSI plugin
```

## Status

✅ **Validated end-to-end on a live lab** (2026-07-01): traditional WEKA cluster
4.4.10.171 on GCP + a single-node k3s tenant, both models provisioning `dir/v1`
volumes with scoped **`csi`-role** credentials. Evidence in each example's
`verify.md`; full runbook in [lab/LAB.md](lab/LAB.md). Key finding: WEKA has a
dedicated **`csi`** role — the least-privilege answer to "not admin credentials."

Remaining (see [docs/OPEN-QUESTIONS.md](docs/OPEN-QUESTIONS.md)): snapshots demo and
Multi-tenancy 2.0.
