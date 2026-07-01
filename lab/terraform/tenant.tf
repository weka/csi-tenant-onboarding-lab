# The tenant's baremetal-host stand-in: one Ubuntu 22.04 VM running single-node
# k3s + the WEKA CSI plugin. Ubuntu 22.04 (NOT 24.04) on purpose: WEKA 4.4.10's
# client gateway kernel module fails to compile on kernel >= 6.17, which 24.04
# ships. 22.04's kernel is old enough for wekafs to build.
data "google_compute_subnetwork" "weka_subnet" {
  name       = "${var.cluster_name}-subnet-0"
  region     = var.region
  project    = var.project
  depends_on = [module.weka_cluster]
}

data "google_compute_image" "ubuntu2204" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

# SSH to the tenant from the operator workstation.
resource "google_compute_firewall" "tenant_ssh" {
  name    = "${var.cluster_name}-tenant-ssh"
  network = data.google_compute_subnetwork.weka_subnet.network
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allow_ssh_cidrs
  target_tags   = ["weka-tenant"]
}

# Full L4 reachability within the management subnet so the tenant (UDP-mode WEKA
# client via CSI) can reach every backend. Broad, but this is an isolated lab VPC.
resource "google_compute_firewall" "intra_subnet" {
  name    = "${var.cluster_name}-intra-subnet"
  network = data.google_compute_subnetwork.weka_subnet.network
  project = var.project

  allow { protocol = "all" }

  source_ranges = [data.google_compute_subnetwork.weka_subnet.ip_cidr_range]
  depends_on    = [module.weka_cluster]
}

resource "google_compute_instance" "tenant" {
  name                      = "${var.cluster_name}-tenant"
  machine_type              = var.tenant_instance_type
  zone                      = var.zone
  project                   = var.project
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu2204.self_link
      size  = 60
      type  = "pd-ssd"
    }
  }

  # Single NIC in the WEKA management subnet (SSH + WEKA UDP data path).
  network_interface {
    subnetwork = data.google_compute_subnetwork.weka_subnet.self_link
    access_config {}
  }

  metadata = {
    ssh-keys       = "weka:${file(pathexpand(var.ssh_public_key_path))}"
    startup-script = file("${path.module}/tenant-startup.sh")
  }

  tags = ["weka-tenant"]

  labels = {
    owner = var.owner
    role  = "csi-tenant"
  }

  depends_on = [module.weka_cluster]
}
