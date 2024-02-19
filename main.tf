locals {
  subnets_with_defaults = var.subnets == null ? [] : [
    for subnet in var.subnets : {
      name                     = subnet.name
      ip_cidr_range            = subnet.ip_cidr_range
      description              = coalesce(subnet.description, "Subnet ${subnet.name} under ${var.vpc_name} VPC")
      region                   = coalesce(subnet.region, var.region)
      private_ip_google_access = coalesce(subnet.private_ip_google_access, true)
    }
  ]

  routes_with_defaults = var.routes == null ? [] : [
    for route in var.routes : {
      name                   = "vpc-${var.vpc_name}-route-${route.name}"
      dest_range             = route.dest_range
      next_hop_gateway       = route.next_hop_gateway
      next_hop_ip            = route.next_hop_ip
      next_hop_ilb           = route.next_hop_ilb
      next_hop_instance      = route.next_hop_instance
      next_hop_instance_zone = route.next_hop_instance_zone
      description            = coalesce(route.description, "Route ${route.name} under ${var.vpc_name} VPC")
      tags                   = coalesce(route.tags, [])
    }
  ]
}

# -----------------------------------------------------
# Create a VPC with subnets 
# -----------------------------------------------------

resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  description                     = coalesce(var.vpc_description, "${var.vpc_name} - Virtual Private Cloud")
  routing_mode                    = var.vpc_routing_mode
  auto_create_subnetworks         = var.vpc_auto_create_subnets
  delete_default_routes_on_create = var.vpc_delete_default_routes_on_create
}

# -----------------------------------------------------
# Create custom subnets (if auto_create_subnets is false)
# -----------------------------------------------------
resource "google_compute_subnetwork" "subnets" {
  count                    = var.vpc_auto_create_subnets == false ? length(local.subnets_with_defaults) : 0
  name                     = local.subnets_with_defaults[count.index].name
  description              = local.subnets_with_defaults[count.index].description
  region                   = local.subnets_with_defaults[count.index].region
  ip_cidr_range            = local.subnets_with_defaults[count.index].ip_cidr_range
  private_ip_google_access = local.subnets_with_defaults[count.index].private_ip_google_access
  network                  = google_compute_network.vpc.self_link
  depends_on               = [google_compute_network.vpc]
}

# -----------------------------------------------------
# Create routes for VPC
# -----------------------------------------------------
resource "google_compute_route" "routes" {
  count                  = length(local.routes_with_defaults)
  name                   = local.routes_with_defaults[count.index].name
  dest_range             = local.routes_with_defaults[count.index].dest_range
  next_hop_gateway       = local.routes_with_defaults[count.index].next_hop_gateway
  next_hop_ip            = local.routes_with_defaults[count.index].next_hop_ip
  next_hop_ilb           = local.routes_with_defaults[count.index].next_hop_ilb
  next_hop_instance      = local.routes_with_defaults[count.index].next_hop_instance
  next_hop_instance_zone = local.routes_with_defaults[count.index].next_hop_instance_zone
  description            = local.routes_with_defaults[count.index].description
  tags                   = local.routes_with_defaults[count.index].tags
  network                = google_compute_network.vpc.self_link
  depends_on             = [google_compute_network.vpc]
}
