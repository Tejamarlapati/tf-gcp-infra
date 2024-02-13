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
    description                     = optional(string, "%s VPC")
    routing_mode                    = optional(string, "REGIONAL")
    region                          = optional(string)
    auto_create_subnets             = optional(bool, false)
    delete_default_routes_on_create = optional(bool, true)
    subnets = list(object({
      name                     = string
      description              = optional(string, "%s subnet for %s VPC")
      region                   = optional(string)
      ip_cidr_range            = string
      private_ip_google_access = optional(bool, true)
    }))
  }))

  description = <<-_EOT
  {
    name                            = "The name of the VPC"
    description                     = "The description of the VPC"
    routing_mode                    = "The network routing mode"
    region                          = "The region in which the VPC will be created"
    auto_create_subnets             = "Whether to create subnets automatically"
    delete_default_routes_on_create = "Whether to delete the default route on create"
    subnets                         =  {
      name                     = "The name of the subnet"
      description              = "The description of the subnet"
      region                   = "The region in which the subnet will be created"
      ip_cidr_range            = "The IP CIDR range of the subnet"
      private_ip_google_access = "Whether to enable private IP Google access"
    }
  }
  _EOT
}
