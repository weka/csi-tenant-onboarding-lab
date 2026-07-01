terraform {
  required_version = ">= 1.5"
  required_providers {
    google = { source = "hashicorp/google" }
  }
}
# No provider block: auth via ADC (rodney.peck@weka.io), project set per-resource.
# Matches the proven virtiofs-bench module invocation.
