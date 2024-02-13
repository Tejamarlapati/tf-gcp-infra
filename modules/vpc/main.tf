# ---------------------------------------------------------------------------------------------------------------------
# VPC Module
# ---------------------------------------------------------------------------------------------------------------------

locals {
  vpc = var.vpc
}

# ---------------------------------------------------------------------------------------------------------------------
# Create VPC
# ---------------------------------------------------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                            = local.vpc.name
  description                     = local.vpc.description
  routing_mode                    = local.vpc.routing_mode
  auto_create_subnetworks         = local.vpc.auto_create_subnets
  delete_default_routes_on_create = local.vpc.delete_default_routes_on_create
}

# -----------------------------------------------------
# Create subnets for each VPC
# -----------------------------------------------------
resource "google_compute_subnetwork" "subnet" {
  count                    = length(local.vpc.subnets)
  name                     = local.vpc.subnets[count.index].name
  description              = local.vpc.subnets[count.index].description
  region                   = local.vpc.subnets[count.index].region
  ip_cidr_range            = local.vpc.subnets[count.index].ip_cidr_range
  private_ip_google_access = local.vpc.subnets[count.index].private_ip_google_access
  network                  = google_compute_network.vpc.self_link
}

# -----------------------------------------------------
# Setup Public Route
# -----------------------------------------------------
resource "google_compute_route" "route" {
  count            = length(local.vpc.routes)
  name             = "vpc-${local.vpc.name}-route-${local.vpc.routes[count.index].name}"
  dest_range       = local.vpc.routes[count.index].dest_range
  next_hop_gateway = local.vpc.routes[count.index].next_hop_gateway
  next_hop_ilb     = local.vpc.routes[count.index].next_hop_ilb
  next_hop_ip      = local.vpc.routes[count.index].next_hop_ip
  tags             = local.vpc.routes[count.index].tags
  network          = google_compute_network.vpc.self_link
}
