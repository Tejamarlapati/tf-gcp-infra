variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The default region in which to create the resources"
  type        = string
}

variable "vpcs" {
  type = list(object({
    name                            = string
    description                     = optional(string)
    routing_mode                    = optional(string, "REGIONAL")
    auto_create_subnets             = optional(bool, false)
    delete_default_routes_on_create = optional(bool, true)
    subnets = list(object({
      name                     = string
      ip_cidr_range            = string
      description              = optional(string)
      region                   = optional(string)
      private_ip_google_access = optional(bool, true)
    }))
    routes = optional(list(object({
      name             = string
      dest_range       = string
      next_hop_gateway = optional(string)
      next_hop_ip      = optional(string)
      next_hop_ilb     = optional(string)
      tags             = optional(list(string))
    })))
  }))


  validation {
    condition     = (length(var.vpcs) > 0)
    error_message = "At least one VPC must be defined"
  }

  validation {
    condition     = alltrue([for vpc in var.vpcs : length(vpc.subnets) > 0])
    error_message = "At least one subnet must be defined for each VPC"
  }

  validation {
    // Condition to check if there are routes then if one of next_hop_gateway, next_hop_ip or next_hop_ilb is defined
    condition = alltrue([for vpc in var.vpcs :
      alltrue([
        for route in vpc.routes : length(route) > 0
        ? (route.next_hop_gateway != null || route.next_hop_ip != null || route.next_hop_ilb != null)
        : true
      ])
    ])
    error_message = "If routes are defined, then one of next_hop_gateway, next_hop_ip or next_hop_ilb must be defined"
  }

  description = <<-_EOT
  {
    name                            = "(Required) The name of the VPC"
    description                     = "(Optional) The description of the VPC. Defaults to '{vpc.name} Virtual Private Cloud'"
    routing_mode                    = "(Optional) The network routing mode. Defaults to 'REGIONAL'"
    auto_create_subnets             = "(Optional) Whether to create subnets automatically. Defaults to 'false'"
    delete_default_routes_on_create = "(Optional) Whether to delete the default route on create. Defaults to 'true'"
    subnets                         =  [{
      name                     = "(Required) The name of the subnet"
      ip_cidr_range            = "(Required) The IP CIDR range of the subnet"
      description              = "(Optional) The description of the subnet. Defaults to '{subnet.name} subnet for {vpc.name} VPC'"
      region                   = "(Optional) The region in which the subnet will be created. Defaults to the default region of provider"
      private_ip_google_access = "(Optional) Whether to enable private IP Google access. Defaults to 'true'"
    }]
    routes = [{
      name             = "(Required) The name of the route"
      dest_range       = "(Required) The destination range of the route"
      tags             = "(Optional) The tags of the route"
      
      ** One of the next_hop_gateway, next_hop_ip or next_hop_ilb must be defined
      next_hop_gateway = "(Optional) The next hop gateway of the route"
      next_hop_ip      = "(Optional) The next hop IP of the route"
      next_hop_ilb     = "(Optional) The next hop ILB of the route"
    }]
  }
  _EOT
}

variable "public_route_tags" {
  type        = list(string)
  description = "Tag to identify public route. Defaults to ['public']"
  default     = ["public"]
}

variable "private_route_tags" {
  type        = list(string)
  description = "Tag to identify private route. Defaults to ['private']"
  default     = ["private"]
}
