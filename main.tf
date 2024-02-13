
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
    }
  ]
}

# -----------------------------------------------------
# Create GCP VPCs with subnets (merged with default values)
# -----------------------------------------------------

module "vpc" {
  source = "./modules/vpc"
  count  = length(local.vpc_with_defaults)
  vpc    = local.vpc_with_defaults[count.index]
}
