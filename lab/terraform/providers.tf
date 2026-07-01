# Auth via ADC. For an isolated run, set impersonate_service_account to the lab SA
# (see docs/lab-isolation.md): your own login then needs only
# roles/iam.serviceAccountTokenCreator on that SA — no standing project access.
# Empty string = use your ADC directly (no impersonation).
provider "google" {
  project                     = var.project
  region                      = var.region
  zone                        = var.zone
  impersonate_service_account = var.impersonate_service_account
}

provider "google-beta" {
  project                     = var.project
  region                      = var.region
  zone                        = var.zone
  impersonate_service_account = var.impersonate_service_account
}
