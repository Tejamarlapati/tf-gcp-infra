variable "vpc" {
  type = object({
    name                            = string
    description                     = string
    routing_mode                    = string
    auto_create_subnets             = bool
    delete_default_routes_on_create = bool
    subnets = list(object({
      name                     = string
      ip_cidr_range            = string
      description              = string
      region                   = string
      private_ip_google_access = bool
    }))
    routes = list(object({
      name             = string
      dest_range       = string
      next_hop_gateway = optional(string)
      next_hop_ip      = optional(string)
      next_hop_ilb     = optional(string)
      tags             = optional(list(string))
    }))
  })

  description = "VPC configuration"
}
