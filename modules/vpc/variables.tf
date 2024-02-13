
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
  })

  description = "VPC configuration"
}
