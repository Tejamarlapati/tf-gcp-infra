# -----------------------------------------------------
# VPC outputs
# -----------------------------------------------------
output "network" {
  description = "A reference to the VPC network"
  value       = google_compute_network.vpc
}

# -----------------------------------------------------
# Subnet outputs
# -----------------------------------------------------
output "subnets" {
  description = "A list of subnets. Each element contains a reference to the subnet."
  value       = [for subnet in google_compute_subnetwork.subnet : subnet]
}


# -----------------------------------------------------
# Route outputs
# -----------------------------------------------------
output "routes" {
  description = "A list of routes. Each element contains a reference to the route."
  value       = [for route in google_compute_route.route : route]
}
