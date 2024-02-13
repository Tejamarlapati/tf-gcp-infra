variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The default region in which to create the resources"
  type        = string
  default     = "us-east1"
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
  }))

  description = <<-_EOT
  {
    name                            = "(Required) The name of the VPC"
    description                     = "(Optional) The description of the VPC. Defaults to '{vpc.name} Virtual Private Cloud'"
    routing_mode                    = "(Optional) The network routing mode. Defaults to 'REGIONAL'"
    auto_create_subnets             = "(Optional) Whether to create subnets automatically. Defaults to 'false'"
    delete_default_routes_on_create = "(Optional) Whether to delete the default route on create. Defaults to 'true'"
    subnets                         =  {
      name                     = "(Required) The name of the subnet"
      ip_cidr_range            = "(Required) The IP CIDR range of the subnet"
      description              = "(Optional) The description of the subnet. Defaults to '{subnet.name} subnet for {vpc.name} VPC'"
      region                   = "(Optional) The region in which the subnet will be created. Defaults to the default region of provider"
      private_ip_google_access = "(Optional) Whether to enable private IP Google access. Defaults to 'true'"
<<<<<<< Updated upstream
    }
=======
    }]
    routes = [{
      name             = "(Required) The name of the route"
      dest_range       = "(Required) The destination range of the route"
      tags             = "(Optional) The tags of the route. Default is empty list"
      
      ** One of the next_hop_gateway, next_hop_ip or next_hop_ilb must be defined
      next_hop_gateway = "(Optional) The next hop gateway of the route"
      next_hop_ip      = "(Optional) The next hop IP of the route"
      next_hop_ilb     = "(Optional) The next hop ILB of the route"
    }]
>>>>>>> Stashed changes
  }
  _EOT
}
