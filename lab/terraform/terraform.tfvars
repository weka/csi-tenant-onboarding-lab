cluster_name          = "csi-tenant"
owner                 = "rodney-peck"
ssh_public_key_path   = "~/.ssh/id_ed25519.pub"
allow_ssh_cidrs       = ["108.90.205.215/32"]
tenant_instance_type  = "n2-standard-4"
# get_weka_io_token is provided via TF_VAR_get_weka_io_token (Secret Manager).
