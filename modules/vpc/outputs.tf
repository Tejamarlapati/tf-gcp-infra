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
  description = "A map of subnetworks. Key is the name of the subnetwork, value is reference to the subnetwork."
  value       = { for subnet in google_compute_subnetwork.subnet : subnet.name => subnet }
}

# -----------------------------------------------------
# Route outputs
# -----------------------------------------------------
output "routes" {
  description = "A map of routes. Key is the name of the route, value is reference to the route."
  value       = { for route in google_compute_route.route : route.name => route }
}
