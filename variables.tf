variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The default region in which to create the resources. Defaults to us-east1."
  type        = string
  default     = "us-east1"
}

variable "vpc_name" {
  description = "Name of the Virtual Private Cloud (VPC)"
  type        = string
}

variable "vpc_description" {
  description = "Description of the Virtual Private Cloud (VPC). Defaults to '{var.vpc_name} - Virtual Private Cloud'."
  type        = string
  default     = null
}

variable "vpc_routing_mode" {
  description = "VPC routing mode. Default is REGIONAL. Valid values are REGIONAL or GLOBAL."
  type        = string
  default     = "REGIONAL"
}

variable "vpc_auto_create_subnets" {
  description = "Whether to create subnets in the VPC. Default is false."
  type        = bool
  default     = false
}

variable "vpc_delete_default_routes_on_create" {
  description = "Whether to delete the default route created by the VPC. Default is true."
  type        = bool
  default     = true
}

variable "subnets" {
  type = list(object({
    name                     = string
    ip_cidr_range            = string
    description              = optional(string)
    region                   = optional(string)
    private_ip_google_access = optional(bool)
  }))

  description = <<-_EOT
  [{
    name                            = "(Required) The name of the subnet"
    ip_cidr_range                   = "(Required) The range of internal addresses that are owned by this subnet.
    description                     = "(Optional) The description of the subnet. Defaults to 'Subnet {subnet.name} under {var.vpc_name} VPC'."
    region                          = "(Optional) The region in which the subnet is created. Defaults to {var.region}"
    private_ip_google_access        = "(Optional) Whether VMs can access Google services without external IP addresses. Defaults to true."
  }]
  _EOT

  validation {
    condition = (var.subnets == null ? true
    : alltrue([for subnet in var.subnets : subnet.ip_cidr_range != null && subnet.ip_cidr_range != ""]))
    error_message = "Subnet IP CIDR ranges must not be empty."
  }

  validation {
    condition = (var.subnets == null ? true
    : alltrue([for subnet in var.subnets : subnet.name != null && subnet.name != ""]))
    error_message = "Subnet names must not be empty."
  }
}

variable "routes" {
  type = list(object({
    name                   = string
    dest_range             = string
    description            = optional(string)
    tags                   = optional(list(string))
    next_hop_gateway       = optional(string)
    next_hop_ip            = optional(string)
    next_hop_ilb           = optional(string)
    next_hop_instance      = optional(string)
    next_hop_instance_zone = optional(string)
  }))

  description = <<-_EOT
  [{
    name             = "(Required) The name of the route. Defaults the route name to 'vpc-{vpc.name}-route-{name}'"
    dest_range       = "(Required) The destination range of outgoing packets that this route applies to"
    description      = "(Optional) The description of the route. Defaults to 'Route {name} under {var.vpc_name} VPC'"
    tags             = "(Optional) A list of instance tags to which this route applies"

    ** One of the next_hop_gateway, next_hop_ip, next_hop_ilb, next_hop_instance (and next_hop_instance_zone) must be defined
      next_hop_gateway       = "(Optional) The next hop gateway of the route"
      next_hop_ip            = "(Optional) The next hop IP of the route"
      next_hop_ilb           = "(Optional) The next hop ILB of the route"
      next_hop_instance      = "(Optional) The next hop instance of the route"
      next_hop_instance_zone = "(Optional) The next hop instance zone of the route"
  }]
  _EOT

  validation {
    condition = (var.routes != null ?
      alltrue([for route in var.routes : route.next_hop_gateway != null || route.next_hop_ip != null || route.next_hop_ilb != null || route.next_hop_instance != null])
    : true)
    error_message = "If routes are defined, then one of next_hop_gateway, next_hop_ip or next_hop_ilb must be defined"
  }

  default = []
}
