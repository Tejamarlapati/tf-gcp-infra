variable "network" {
  type        = string
  description = "The VPC to use for the load balancer"
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
