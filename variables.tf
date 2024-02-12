variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region in which to create the resources"
  type        = string
}

variable "vpc_name" {
  description = "Name of the Virtual Private Cloud (VPC)"
  type        = string
}

variable "vpc_description" {
  description = "Description of the Virtual Private Cloud (VPC)"
  type        = string
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

variable "subnet_region" {
  description = "The region in which to create the subnet. Default is us-east1."
  type        = string
  default     = null
}

variable "subnet_private_ip_google_access" {
  description = "CIDR range for the subnets. Default is true."
  type        = bool
  default     = true
}


variable "subnet_webapp_name" {
  description = "Name of the webapp subnet. Default is webapp-subnet."
  type        = string
  default     = "webapp-subnet"
}


variable "subnet_webapp_cidr" {
  description = "CIDR range for the subnets for webapp"
  type        = string
}

variable "subnet_db_name" {
  description = "Name of the db subnet. Default is db-subnet."
  type        = string
  default     = "db-subnet"
}

variable "subnet_db_cidr" {
  description = "CIDR range for the subnets for db"
  type        = string
}

variable "route_webapp_name" {
  description = "Name of the route for webapp. Default is webapp-route."
  type        = string
  default     = "webapp-route"
}

variable "firewall_public_allow_all_ingress_tags" {
  description = "List of tags to allow all ingress traffic from. Default is [public]."
  type        = list(string)
  default     = ["public"]
}
