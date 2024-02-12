provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  subnet_region = var.subnet_region != null ? var.subnet_region : var.region
}

# -----------------------------------------------------
# Create a VPC with custom subnets 
# -----------------------------------------------------

resource "google_compute_network" "vpc_csye6225" {
  name                            = var.vpc_name
  description                     = var.vpc_description
  routing_mode                    = var.vpc_routing_mode
  auto_create_subnetworks         = var.vpc_auto_create_subnets
  delete_default_routes_on_create = var.vpc_delete_default_routes_on_create
}

# -----------------------------------------------------
# Create subnets
# 1. Create a subnet for the webapp
# 2. Create a subnet for the database
# -----------------------------------------------------
resource "google_compute_subnetwork" "webapp_subnet" {
  name                     = var.subnet_webapp_name
  description              = "Subnet for the webapp under ${var.vpc_name} VPC"
  region                   = local.subnet_region
  network                  = google_compute_network.vpc_csye6225.self_link
  ip_cidr_range            = var.subnet_webapp_cidr
  private_ip_google_access = var.subnet_private_ip_google_access
  depends_on               = [google_compute_network.vpc_csye6225]
}
resource "google_compute_subnetwork" "db_subnet" {
  name                     = var.subnet_db_name
  description              = "Subnet for the database under ${var.vpc_name} VPC"
  region                   = local.subnet_region
  network                  = google_compute_network.vpc_csye6225.self_link
  ip_cidr_range            = var.subnet_db_cidr
  private_ip_google_access = var.subnet_private_ip_google_access
  depends_on               = [google_compute_network.vpc_csye6225]
}

# -----------------------------------------------------
# Create a default router for the VPC
# -----------------------------------------------------

resource "google_compute_router" "vpc_router" {
  name        = "${var.vpc_name}-router"
  description = "Default router being created for ${var.vpc_name} VPC"
  network     = google_compute_network.vpc_csye6225.self_link
  depends_on  = [google_compute_network.vpc_csye6225]
}

# -----------------------------------------------------
# Create a NAT gateway for the webapp VPC
# -----------------------------------------------------
resource "google_compute_router_nat" "vpc_nat" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.vpc_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.webapp_subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  depends_on = [google_compute_router.vpc_router]
}
