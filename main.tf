provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc_csye6225" {
  name                    = var.vpc_name
  description             = var.vpc_description
  routing_mode            = var.vpc_routing_mode
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name                     = var.subnet_db_name
  region                   = var.region
  network                  = google_compute_network.vpc_csye6225.self_link
  ip_cidr_range            = var.subnet_webapp_cidr
  private_ip_google_access = var.subnet_private_ip_google_access
}

resource "google_compute_subnetwork" "db_subnet" {
  name                     = var.subnet_db_name
  region                   = var.region
  network                  = google_compute_network.vpc_csye6225.self_link
  ip_cidr_range            = var.subnet_db_cidr
  private_ip_google_access = var.subnet_private_ip_google_access
}
