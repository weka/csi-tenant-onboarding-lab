cluster_name         = "csi-tenant"
owner                = "weka-lab"
ssh_public_key_path  = "~/.ssh/id_ed25519.pub"
allow_ssh_cidrs      = ["<YOUR_ADMIN_IP>/32"]
tenant_instance_type = "n2-standard-4"
# get_weka_io_token is provided via TF_VAR_get_weka_io_token.
#
# Isolated run (recommended — see docs/lab-isolation.md + scripts/provider/bootstrap-project.sh):
#   project                     = "weka-csi-lab-<id>"
#   impersonate_service_account = "csi-lab@weka-csi-lab-<id>.iam.gserviceaccount.com"
