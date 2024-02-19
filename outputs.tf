# -----------------------------------------------------
# VPC outputs
# -----------------------------------------------------
output "vpc" {
  value = {
    name      = google_compute_network.vpc.name,
    self_link = google_compute_network.vpc.self_link
  }
  description = "The VPC created by this module"
}

# -----------------------------------------------------
# Subnets outputs
# -----------------------------------------------------
output "subnets" {
  value = [for subnet in google_compute_subnetwork.subnets : {
    name      = subnet.name,
    self_link = subnet.self_link
  }]
  description = "List of subnets created for the VPC"
}

# -----------------------------------------------------
# Routes outputs
# -----------------------------------------------------
output "routes" {
  value = [for route in google_compute_route.routes : {
    name      = route.name
    self_link = route.self_link
  }]
  description = "List of routes created for the VPC"
}

# -----------------------------------------------------
# Firewall rules outputs
# -----------------------------------------------------
output "firewall_rules" {
  value = [for rule in google_compute_firewall.firewall_rules : {
    name      = rule.name
    self_link = rule.self_link
  }]
  description = "List of firewall rules created for the VPC"
}

# -----------------------------------------------------
# Web Server Compute Instance outputs
# -----------------------------------------------------
output "web_server" {
  value = [for instance in google_compute_instance.web_server : {
    name          = instance.name
    self_link     = instance.self_link
    access_config = flatten([for interfaces in instance.network_interface : interfaces.access_config])
  }]
  description = "The web server compute instance created by this module"
}
