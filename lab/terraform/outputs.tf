output "backend_lb_ip" {
  description = "WEKA cluster LB IP — this is the CSI Secret 'endpoints' host"
  value       = module.weka_cluster.backend_lb_ip
}

output "weka_password_secret_id" {
  description = "Secret Manager secret ID holding the WEKA admin password"
  value       = module.weka_cluster.weka_cluster_admin_password_secret_id
}

output "terminate_cluster_uri" {
  description = "Cloud Run URL to call BEFORE terraform destroy"
  value       = module.weka_cluster.terminate_cluster_uri
}

output "helper_commands" {
  description = "Pre-formatted WEKA module helper commands (get_password, get_status, ...)"
  value       = module.weka_cluster.cluster_helper_commands
}

output "tenant_public_ip" {
  value = google_compute_instance.tenant.network_interface[0].access_config[0].nat_ip
}

output "tenant_internal_ip" {
  value = google_compute_instance.tenant.network_interface[0].network_ip
}

output "cluster_name" {
  value = var.cluster_name
}

output "ssh_username" {
  value = "weka"
}
