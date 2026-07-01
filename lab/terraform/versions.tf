terraform {
  required_version = ">= 1.5"
  required_providers {
    google = { source = "hashicorp/google" }
  }
}
# No provider block: auth via ADC, project set per-resource.
