# The official weka module has sub-resources (network submodule, pubsub, project
# services) that read the provider-default project/region rather than taking
# project_id explicitly, so configure the providers here. Auth is ADC.
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
