# Traditional (non-operator) WEKA cluster via the official weka/weka/gcp module.
# This is the "provider" WEKA cluster the tenant consumes over CSI.
# Invocation mirrors the proven virtiofs-bench module (UDP mode, no DPDK,
# reuse the shared weka-deployment SA, no auto-created clients).
module "weka_cluster" {
  source  = "weka/weka/gcp"
  version = "~> 4.0"

  cluster_name      = var.cluster_name
  prefix            = var.cluster_name
  project_id        = var.project
  region            = var.region
  zone              = var.zone
  cluster_size      = var.backend_count
  machine_type      = var.backend_instance_type
  get_weka_io_token = var.get_weka_io_token
  weka_version      = var.weka_version

  # No auto-created clients — the tenant node (tenant.tf) is our client.
  clients_number = 0

  # GCP c2-standard-16 can't do DPDK driver setup; UDP mode.
  nic_number           = 1
  install_cluster_dpdk = false

  # Reuse the shared SA that already exists in team-cst.
  sa_email = "weka-deployment@${var.project}.iam.gserviceaccount.com"

  allow_ssh_cidrs = var.allow_ssh_cidrs

  labels_map = {
    owner             = var.owner
    weka_cluster_name = var.cluster_name
  }
}
