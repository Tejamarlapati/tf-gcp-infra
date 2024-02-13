provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  vpc_with_defaults = [
    for vpc_index, vpc in var.vpcs : {
      name                            = vpc.name
      description                     = coalesce(vpc.description, format("%s Virtual Private Cloud", vpc.name))
      routing_mode                    = coalesce(vpc.routing_mode, "REGIONAL")
      auto_create_subnets             = coalesce(vpc.auto_create_subnets, false)
      delete_default_routes_on_create = coalesce(vpc.delete_default_routes_on_create, true)
      subnets = [
        for subnet in vpc.subnets : {
          name                     = subnet.name
          description              = coalesce(subnet.description, format("%s subnet for %s VPC", subnet.name, vpc.name))
          region                   = coalesce(subnet.region, var.region)
          ip_cidr_range            = subnet.ip_cidr_range
          private_ip_google_access = coalesce(subnet.private_ip_google_access, true)
          vpc_index                = vpc_index
        }
      ]
    }
  ]

  subnets_with_defaults = flatten([for vpc in local.vpc_with_defaults : vpc.subnets])
}

# -----------------------------------------------------
# Create VPCs merged with defaults
# -----------------------------------------------------

resource "google_compute_network" "vpc" {
  count                           = length(local.vpc_with_defaults)
  name                            = local.vpc_with_defaults[count.index].name
  description                     = local.vpc_with_defaults[count.index].description
  routing_mode                    = local.vpc_with_defaults[count.index].routing_mode
  auto_create_subnetworks         = local.vpc_with_defaults[count.index].auto_create_subnets
  delete_default_routes_on_create = local.vpc_with_defaults[count.index].delete_default_routes_on_create
}

# -----------------------------------------------------
# Create subnets for each VPC merged with defaults
# -----------------------------------------------------
resource "google_compute_subnetwork" "subnet" {
  count                    = length(local.subnets_with_defaults)
  name                     = local.subnets_with_defaults[count.index].name
  description              = local.subnets_with_defaults[count.index].description
  region                   = local.subnets_with_defaults[count.index].region
  ip_cidr_range            = local.subnets_with_defaults[count.index].ip_cidr_range
  private_ip_google_access = local.subnets_with_defaults[count.index].private_ip_google_access
  network                  = google_compute_network.vpc[local.subnets_with_defaults[count.index].vpc_index].self_link
}
