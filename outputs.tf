# -----------------------------------------------------
# VPC outputs
# -----------------------------------------------------
output "vpc" {
  value       = google_compute_network.vpc
  description = "The VPC created by this module"
}

# -----------------------------------------------------
# Subnets outputs
# -----------------------------------------------------
output "subnets" {
  value       = [for subnet in google_compute_subnetwork.subnets : subnet]
  description = "List of subnets created for the VPC"
}

# -----------------------------------------------------
# Routes outputs
# -----------------------------------------------------
output "routes" {
  value       = [for route in google_compute_route.routes : route]
  description = "List of routes created for the VPC"
}

