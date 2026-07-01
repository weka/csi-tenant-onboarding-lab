variable "project" {
  description = "GCP project ID"
  default     = "your-gcp-project"
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "cluster_name" {
  description = "Cluster name prefix — max 37 chars, used in resource names"
  type        = string
  default     = "csi-tenant"
}

variable "weka_version" {
  description = "WEKA version to install"
  default     = "4.4.10.171"
}

variable "get_weka_io_token" {
  description = "get.weka.io download token. Pass via TF_VAR_get_weka_io_token (fetched from Secret Manager get-weka-io-<your-user>)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "backend_count" {
  description = "Number of WEKA backend instances (module minimum 6)"
  default     = 6
}

variable "backend_instance_type" {
  default = "c2-standard-16"
}

# The tenant's baremetal-host stand-in (runs its own single-node k3s + WEKA CSI).
variable "tenant_instance_type" {
  default = "n2-standard-4"
}

variable "ssh_public_key_path" {
  default = "~/.ssh/id_ed25519.pub"
}

variable "allow_ssh_cidrs" {
  description = "CIDRs allowed SSH access to the tenant VM"
  type        = list(string)
  default     = []
}

variable "owner" {
  default = "weka-lab"
}
