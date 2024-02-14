# -----------------------------------------------------
# VPC outputs
# -----------------------------------------------------
output "vpc_networks" {
  description = "List of VPCs with name, self_link and subnets"
  value = [
    for vpc_index, vpc in module.vpc : {
      name      = vpc.network.name
      self_link = vpc.network.self_link
      subnets = [
        for subnet in vpc.subnets : {
          name      = subnet.name
          region    = subnet.region
          self_link = subnet.self_link
        }
      ]
      routes = [
        for route in vpc.routes : {
          name      = route.name
          self_link = route.self_link
        }
      ]
    }
  ]
}
