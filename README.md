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
- **Stateless, CSI-managed client** — no manual `weka agent install` on the tenant host.
- The tenant runs a **single-node k8s** cluster on their baremetal host.

> **Provisioning mode is still open** — see [docs/OPEN-QUESTIONS.md](docs/OPEN-QUESTIONS.md).
> The 2026-06-30 call referenced **folder-based (directory) PVCs**; the initial lab
> scoping picked **filesystem-backed** PVCs. These have different credential
> requirements, so we resolve this before writing the example manifests.

## Layout

```
docs/
  secrets-and-access.md   # ← core deliverable: exact creds + role scope per model
  architecture.md         # WEKA cluster ⇄ tenant k8s host; where the trust boundary sits
  provider-runbook.md     # what the WEKA cluster operator does to onboard a tenant
  tenant-runbook.md       # what the tenant does on their host (k8s + CSI install)
  OPEN-QUESTIONS.md       # decisions still to confirm before manifests are authoritative
examples/
  01-org-tenant/          # multi-tenant via a WEKA Organization
  02-root-org-tenant/     # shared cluster, root org + dedicated filesystem
scripts/
  provider/               # operator-side onboarding helpers
  tenant/                 # tenant-side install + smoke test
```

## Status

Scaffolding stage. `docs/secrets-and-access.md` is a first pass pending review of
the official [csi-wekafs examples](https://github.com/weka/csi-wekafs/tree/master/examples)
and the internal CSI setup pages. Example manifests are held until the provisioning
mode is confirmed. Nothing here has been run end-to-end yet.
