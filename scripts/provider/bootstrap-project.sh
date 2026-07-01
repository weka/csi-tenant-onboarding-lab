#!/usr/bin/env bash
# One-time bootstrap of a DISPOSABLE GCP project for the CSI lab.
#
# Why: the WEKA terraform module needs broad create/delete permissions, and GCP's
# real isolation boundary is the project (IAM can't reliably fence a broad role
# inside a shared project). Running the lab in its own throwaway project means a
# stray command — even `terraform destroy` — can never touch shared resources.
#
# Run this ONCE with your normal gcloud identity (needs project-create + billing
# perms). Afterwards, day-to-day lab runs impersonate the lab SA, so your personal
# identity carries near-zero standing access.
set -euo pipefail

PROJECT="${1:?usage: bootstrap-project.sh <new-project-id> <billing-account-id>}"
BILLING="${2:?usage: bootstrap-project.sh <new-project-id> <billing-account-id>}"
ME="$(gcloud config get-value account 2>/dev/null)"

echo ">> creating disposable project $PROJECT"
gcloud projects create "$PROJECT"
gcloud billing projects link "$PROJECT" --billing-account="$BILLING"

echo ">> enabling base APIs (the WEKA module enables the rest via serviceusage)"
gcloud services enable \
  cloudresourcemanager.googleapis.com serviceusage.googleapis.com \
  compute.googleapis.com iam.googleapis.com --project "$PROJECT"

echo ">> SA the WEKA module attaches to backends/functions (main.tf expects this name)"
gcloud iam service-accounts create weka-deployment --project "$PROJECT"
gcloud projects add-iam-policy-binding "$PROJECT" --quiet \
  --member="serviceAccount:weka-deployment@$PROJECT.iam.gserviceaccount.com" \
  --role="roles/editor"

echo ">> lab SA that Terraform impersonates (owner is fine — the project is disposable)"
gcloud iam service-accounts create csi-lab --project "$PROJECT"
gcloud projects add-iam-policy-binding "$PROJECT" --quiet \
  --member="serviceAccount:csi-lab@$PROJECT.iam.gserviceaccount.com" \
  --role="roles/owner"

echo ">> granting YOU impersonation of the lab SA (the only standing grant on your identity)"
gcloud iam service-accounts add-iam-policy-binding \
  "csi-lab@$PROJECT.iam.gserviceaccount.com" --project "$PROJECT" \
  --member="user:$ME" --role="roles/iam.serviceAccountTokenCreator"

cat <<EOF

Bootstrap complete. Run the lab against the disposable project:

  cd lab/terraform
  export TF_VAR_project=$PROJECT
  export TF_VAR_impersonate_service_account=csi-lab@$PROJECT.iam.gserviceaccount.com
  export TF_VAR_get_weka_io_token=<your get.weka.io token>
  export CSI_VERSION=2.8.1            # match the customer's CSI version
  terraform init && terraform apply

Your ADC (from 'gcloud auth login') needs NO project roles — only the
tokenCreator grant above. Terraform borrows the lab SA's power only for the run.

Teardown — terminate hook + destroy, OR just delete the whole project:
  gcloud projects delete $PROJECT
EOF
