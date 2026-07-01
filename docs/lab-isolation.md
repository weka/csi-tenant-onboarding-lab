# Running the lab safely: isolation & minimal access

Goal: run this lab so that **a stray command can never affect other users**, and so
the person running it needs **near-zero standing GCP access**.

## The key fact: the project is the isolation boundary

The official `weka/weka/gcp` module needs broad create/delete across compute,
networking, serverless, storage, secret manager, DNS, VPC-access, and API
enablement. There is no narrow role that runs it, and IAM *within* a shared project
cannot reliably stop a broadly-permissioned run (or a mistaken `terraform destroy`)
from touching other people's resources.

**So the lab runs in its own disposable GCP project.** Your credentials then have
power *only* there; shared projects are untouchable by construction.

## Minimal standing access via SA impersonation

You never attach broad roles to your own identity. Instead:

- A **lab service account** (`csi-lab@<project>`) holds the provisioning roles, and
  it exists only in the disposable project.
- Your login (`gcloud auth login`) is granted just
  **`roles/iam.serviceAccountTokenCreator`** on that SA — nothing else.
- Terraform **impersonates** the lab SA for the run (`impersonate_service_account`),
  borrowing its power only while applying.

Result: your personal identity can't modify anything in any shared project, because
the only credential Terraform uses (the lab SA) has no access there.

## One-time setup

Run with your normal gcloud identity (needs project-create + billing perms):

```bash
scripts/provider/bootstrap-project.sh weka-csi-lab-<id> <BILLING_ACCOUNT_ID>
```

This creates the project, links billing, enables base APIs, creates the
`weka-deployment` SA (attached to the WEKA VMs/functions) and the `csi-lab` SA
(Terraform impersonates it), and grants **you** token-creator on `csi-lab`.

## Running the lab

```bash
cd lab/terraform
export TF_VAR_project=weka-csi-lab-<id>
export TF_VAR_impersonate_service_account=csi-lab@weka-csi-lab-<id>.iam.gserviceaccount.com
export TF_VAR_get_weka_io_token=<your get.weka.io token>
export CSI_VERSION=2.8.1            # match the customer's CSI version
terraform init && terraform apply
```

Everything Terraform does is confined to `weka-csi-lab-<id>`.

## Teardown

Either the normal path (terminate hook → `terraform destroy`, see
[../lab/LAB.md](../lab/LAB.md#4-teardown-order-matters)), or — because the project
is disposable — just delete the whole thing:

```bash
gcloud projects delete weka-csi-lab-<id>
```

## Matching a customer's CSI version

Set `CSI_VERSION` (default `2.8.1`) so the lab installs the same CSI plugin chart
the customer runs, and behaviour matches theirs. Chart version == plugin app
version (e.g. `2.8.1` → plugin `v2.8.1`).

## Fallback: shared project (not recommended)

If you cannot create a project, you can point `TF_VAR_project` at a shared project
and impersonate a scoped `csi-lab` SA there, with all resources prefixed
`csi-tenant-*` and a separate Terraform state. This reduces but **does not
eliminate** cross-user risk — the SA still needs broad roles in the shared project.
Prefer the disposable-project path above.
