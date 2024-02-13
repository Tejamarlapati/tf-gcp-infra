# ---------------------------------------------------------------------------------------------------------------------
# VPC Module
# ---------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------------------------
# Create VPC
# ---------------------------------------------------------------------------------------------------------------------

resource "google_compute_network" "vpc" {
  name                            = var.vpc.name
  description                     = var.vpc.description
  routing_mode                    = var.vpc.routing_mode
  auto_create_subnetworks         = var.vpc.auto_create_subnets
  delete_default_routes_on_create = var.vpc.delete_default_routes_on_create
}

# -----------------------------------------------------
# Create subnets for each VPC
# -----------------------------------------------------
resource "google_compute_subnetwork" "subnet" {
  count                    = length(var.vpc.subnets)
  name                     = var.vpc.subnets[count.index].name
  description              = var.vpc.subnets[count.index].description
  region                   = var.vpc.subnets[count.index].region
  ip_cidr_range            = var.vpc.subnets[count.index].ip_cidr_range
  private_ip_google_access = var.vpc.subnets[count.index].private_ip_google_access
  network                  = google_compute_network.vpc.self_link
}
