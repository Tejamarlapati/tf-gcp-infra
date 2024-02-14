
locals {
  vpc_with_defaults = [
    for vpc in var.vpcs : {
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
        }
      ]
      routes = vpc.routes == null ? [] : [
        for route in vpc.routes : {
          name             = route.name
          dest_range       = route.dest_range
          next_hop_gateway = route.next_hop_gateway
          next_hop_ip      = route.next_hop_ip
          next_hop_ilb     = route.next_hop_ilb
          tags             = route.tags
        }
      ]
    }
  ]
}

# -----------------------------------------------------
# Create GCP VPCs with subnets & routes (merged with default values if not provided)
# -----------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"
  count  = length(local.vpc_with_defaults)
  vpc    = local.vpc_with_defaults[count.index]
}
