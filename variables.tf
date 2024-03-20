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
    purpose                  = optional(string)
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

  default = null
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

variable "firewall_rules" {
  type = list(object({
    name               = string
    description        = optional(string)
    direction          = string
    priority           = optional(number)
    source_ranges      = optional(list(string))
    destination_ranges = optional(list(string))
    source_tags        = optional(list(string))
    target_tags        = optional(list(string))
    allowed = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
    denied = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
  }))

  description = <<-_EOT
  [{
    name               = "(Required) The name of the firewall rule"
    description        = "(Optional) The description of the firewall rule. Defaults to 'Firewall rule {name} under {var.vpc_name} VPC'"
    direction          = "(Required) The direction of traffic to which this firewall applies. Valid values are INGRESS or EGRESS"
    priority           = "(Optional) The priority of the firewall rule. Defaults to 1000"
    source_ranges      = "(Optional) A list of source IP ranges to which this firewall applies"
    destination_ranges = "(Optional) A list of destination IP ranges to which this firewall applies. If any value is set to "DATABASE_PRIVATE_IP", the firewall rule applies to the private IP CIDR of the database instance."
    source_tags        = "(Optional) A list of source instance tags to which this firewall applies"
    target_tags        = "(Optional) A list of target instance tags to which this firewall applies"

    allowed = "(Optional) A list of allowed protocols and ports. Each allowed block supports fields protocol and ports"
    denied  = "(Optional) A list of denied protocols and ports. Each denied block supports fields protocol and ports"
  }]
  _EOT

  default = []

  validation {
    condition = (alltrue([
      for rule in var.firewall_rules : (rule.allowed != null) || (rule.denied != null)
    ]))
    error_message = "At least 1 allowed or denied rule must be defined"
  }

  validation {
    condition = (alltrue([
      for rule in var.firewall_rules :
      (rule.allowed != null ? length(rule.allowed) > 0 : true) || (rule.denied != null ? length(rule.denied) > 0 : true)
    ]))
    error_message = "At least 1 allowed or denied rule must be defined"
  }
}

variable "webapp_compute_instance" {
  type = object({
    name         = string
    machine_type = string
    zone         = string
    tags         = list(string)
    image        = string
    disk_size    = number
    disk_type    = string
    subnet_name  = string
  })

  description = <<-_EOT
  {
    name         = "(Required) The name of the instance"
    machine_type = "(Required) The machine type of the instance"
    zone         = "(Required) The zone in which the instance is created"
    tags         = "(Optional) A list of instance tags"
    image        = "(Required) The image of the instance"
    disk_size    = "(Required) The size of the boot disk"
    disk_type    = "(Required) The type of the boot disk"
    subnet_name  = "(Optional) The name of the subnet to bind this instance to. If not provided, the instance is created in the default network"
  }
  _EOT

  default = null

  validation {
    condition     = (var.webapp_compute_instance != null ? var.webapp_compute_instance.subnet_name != null : true)
    error_message = "Subnet name must be provided if webapp_compute_instance is defined"
  }
}

variable "database_sql_instance" {
  type = object({
    name                = string
    region              = string
    tier                = string
    database_name       = string
    database_username   = string
    database_version    = optional(string, "POSTGRES_15")
    disk_type           = optional(string, "pd-ssd")
    disk_size           = optional(number, 100)
    availability_type   = optional(string, "REGIONAL")
    deletion_protection = optional(bool, true)

    ip_configuration = optional(object({
      ipv4_enabled                                  = optional(bool, false)
      require_ssl                                   = optional(bool, true)
      ssl_mode                                      = optional(string)
      enable_private_path_for_google_cloud_services = optional(bool, true)
    }))

    private_access_config = optional(object({
      name          = optional(string)
      purpose       = optional(string, "VPC_PEERING")
      address_type  = optional(string, "INTERNAL")
      address       = optional(string, null)
      prefix_length = optional(number, 24)
    }))
  })

  description = <<-_EOT
  {
    name                = "(Required) The name of the instance"
    region              = "(Required) The region in which the instance is created"
    tier                = "(Required) The tier of the instance"
    database_name       = "(Required) The name of the database"
    database_username   = "(Required) The username of the database"
    database_version    = "(Optional) The version of the database. Defaults to POSTGRES_15"
    disk_type           = "(Optional) The type of the disk. Defaults to pd-ssd"
    disk_size           = "(Optional) The size of the disk. Defaults to 100"
    availability_type   = "(Optional) The availability type of the instance. Defaults to REGIONAL"
    deletion_protection = "(Optional) Whether the instance is deletion protected. Defaults to true"

    ip_configuration = "(Optional) The IP configuration of the instance"
    private_access_config = "(Optional) The private access configuration of the instance"
  }
  _EOT

  default = null
}

variable "service_account_id" {
  description = "The ID of the service account to use for the resources"
  type        = string
}

variable "service_account_iam_bindings" {
  type        = list(string)
  description = "The list of IAM roles to grant to the service account. Defaults to roles/logging.logWriter and roles/monitoring.metricWriter"
  default     = ["roles/logging.admin", "roles/monitoring.metricWriter"]
}

variable "service_account_vm_scopes" {
  description = "The list of scopes to grant to the service account. Defaults to logging.write and monitoring.write"
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write"]
}

variable "webapp_dns_record_set" {
  type = object({
    name         = string,
    type         = string,
    ttl          = number,
    managed_zone = string
  })

  description = <<-_EOT
  {
    name      = "(Required) The name of the DNS record set"
    type      = "(Required) The type of the DNS record set"
    ttl       = "(Required) The TTL of the DNS record set"
    managed_zone = "(Required) The name of the DNS zone"
  }
  _EOT
}

variable "webapp_log_level" {
  description = "The log level of the webapp. Defaults to info"
  type        = string
  default     = "info"

  validation {
    condition     = (var.webapp_log_level != null ? contains(["info", "warning", "error"], var.webapp_log_level) : false)
    error_message = "Log level must be one of info, warning or error"
  }
}
