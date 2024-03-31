variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The default region in which to create the resources. Defaults to us-east1."
  type        = string
  default     = "us-east1"
}

variable "name" {
  type        = string
  description = "The name of the load balancer"
}

variable "network" {
  type        = string
  description = "The VPC to use for the load balancer"
}

variable "proxy_subnet_cidr" {
  type        = string
  description = "The CIDR range for the subnet to use for the load balancer proxy. Defaults to Defaults to '10.0.10.0/24'"
  default     = "10.0.10.0/24"
}

variable "instance_group" {
  type        = string
  description = "The instance group to use as the backend for the load balancer"
}

variable "instance_tags" {
  type        = list(string)
  description = "The list of tags to use for the instance group. Defaults to an ['load-balanced-backend', 'webapp']."
  default     = ["load-balanced-backend", "webapp"]
}

variable "named_port" {
  type        = string
  description = "The name of the port to use for the instance group. Defaults to 'http'."
  default     = "http"
}

variable "ssl_certificates" {
  type        = list(string)
  description = "The list of SSL certificates to use for the load balancer"
}

variable "ssl_certificate_domains" {
  type        = list(string)
  description = "Create a managed SSL certificate for the load balancer with the specified domains"
  default     = null
  nullable    = true
}

variable "health_check" {
  type = object({
    timeout_sec         = optional(number, 5)
    check_interval_sec  = optional(number, 5)
    healthy_threshold   = optional(number, 3)
    unhealthy_threshold = optional(number, 3)
    request_path        = optional(string, "/healthz")
    port                = optional(number, 80)
  })

  description = <<-_EOT
  {
    name                = "(Optional) The name of the health check. Defaults to 'load-balancer-health-check'"
    timeout_sec         = "(Optional) The timeout of the health check. Defaults to 5"
    check_interval_sec  = "(Optional) The check interval of the health check. Defaults to 5"
    healthy_threshold   = "(Optional) The healthy threshold of the health check. Defaults to 3"
    unhealthy_threshold = "(Optional) The unhealthy threshold of the health check. Defaults to 3"
    request_path        = "(Optional) The request path of the health check. Defaults to '/healthz'"
    port                = "(Optional) The port of the health check. Defaults to 80"
  }
  _EOT

  default = {
    name                = "load-balancer-health-check"
    timeout_sec         = 5
    check_interval_sec  = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    request_path        = "/healthz"
    port                = 80
  }
}

variable "ip_settings" {
  type = object({
    create_ip  = optional(bool, false)
    ip_address = optional(string, "")
  })
  description = "The IP settings for the load balancer"
  default = {
    create_ip  = false
    ip_address = ""
  }

  validation {
    condition     = var.ip_settings.create_ip == true || (var.ip_settings.create_ip == false && var.ip_settings.ip_address != "")
    error_message = "The load balancer ip_address cannot be an empty string when create_ip is false"
  }
}
