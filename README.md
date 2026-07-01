# csi-tenant-onboarding-lab

How to onboard a **tenant** who runs their own single-node Kubernetes cluster on a
baremetal host and consumes storage from a shared **WEKA** cluster via the
[WEKA CSI plugin](https://github.com/weka/csi-wekafs) — using **limited,
tenant-scoped credentials instead of cluster-admin credentials**.

> Purpose: guidance plus a validated lab for configuring the WEKA CSI plugin to use
> limited tenant- or filesystem-specific credentials instead of admin credentials —
> in runnable form.

**Start here:** [`docs/csi-howto.md`](docs/csi-howto.md) — the full how-to walkthrough
(also as a [PDF](docs/csi-howto.pdf)). Short version: [`docs/csi-guidance.md`](docs/csi-guidance.md).

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
| Handed-over user | **`csi`-role user** scoped to that org | **`csi`-role user** in root org, fenced by filesystem + quota |
| Tenant can see | only their org's filesystems/objects | (relies on StorageClass + role to fence) |
| Isolation strength | strong, native to WEKA | weaker — mitigations documented |

Both examples use:
- The dedicated **`csi`** role for the tenant credential — least-privilege, never admin.
- **Directory-backed (`dir/v1`) volumes** — folder-based PVCs (the common tenant pattern).
- The tenant runs a **single-node k8s** cluster on their baremetal host, with the
  **WEKA client installed on the node** (the CSI wekafs transport is not agentless).

Manifests are derived from the official
[csi-wekafs `dynamic_directory` example](https://github.com/weka/csi-wekafs/tree/master/examples/dynamic_directory)
and the WEKA role model — see [docs/REFERENCES.md](docs/REFERENCES.md).

## Layout

```
docs/
  csi-howto.md            # ← full how-to walkthrough (source for the PDF)
  csi-howto.pdf           # send-ready PDF
  csi-guidance.md         # short quick-reference guidance
  secrets-and-access.md   # exact creds + role scope per model
  architecture.md         # WEKA cluster ⇄ tenant k8s host; where the trust boundary sits
  provider-runbook.md     # what the WEKA cluster operator does to onboard a tenant
  tenant-runbook.md       # what the tenant does on their host (client + CSI install)
  lab-evidence.md         # captured command transcript from the lab run
  REFERENCES.md           # official csi-wekafs examples + WEKA role model
  OPEN-QUESTIONS.md       # notes: snapshots caveat, Multi-tenancy 2.0
examples/
  01-org-tenant/          # dir/v1 via a dedicated WEKA Organization (recommended)
  02-root-org-tenant/     # dir/v1 on root org + dedicated filesystem
scripts/
  tenant/install-csi.sh   # helm install of the CSI plugin
```

## Status

✅ **Validated end-to-end on a live lab** (2026-07-01): traditional WEKA cluster
4.4.10.171 on GCP + a single-node k3s tenant, both models provisioning `dir/v1`
volumes with scoped **`csi`-role** credentials. Full command transcript in
[docs/lab-evidence.md](docs/lab-evidence.md); per-model evidence in each example's
`verify.md`; runbook in [lab/LAB.md](lab/LAB.md). Key finding: WEKA has a
dedicated **`csi`** role — the least-privilege answer to "not admin credentials."

Remaining (see [docs/OPEN-QUESTIONS.md](docs/OPEN-QUESTIONS.md)): snapshots demo and
Multi-tenancy 2.0.
