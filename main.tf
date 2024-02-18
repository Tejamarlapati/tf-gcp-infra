locals {
  subnets_with_defaults = var.subnets == null ? [] : [
    for subnet in var.subnets : {
      name                     = subnet.name
      ip_cidr_range            = subnet.ip_cidr_range
      description              = coalesce(subnet.description, "Subnet ${subnet.name} under ${var.vpc_name} VPC")
      region                   = coalesce(subnet.region, var.region)
      private_ip_google_access = coalesce(subnet.private_ip_google_access, true)
    }
  ]

  routes_with_defaults = var.routes == null ? [] : [
    for route in var.routes : {
      name                   = "vpc-${var.vpc_name}-route-${route.name}"
      dest_range             = route.dest_range
      next_hop_gateway       = route.next_hop_gateway
      next_hop_ip            = route.next_hop_ip
      next_hop_ilb           = route.next_hop_ilb
      next_hop_instance      = route.next_hop_instance
      next_hop_instance_zone = route.next_hop_instance_zone
      description            = coalesce(route.description, "Route ${route.name} under ${var.vpc_name} VPC")
      tags                   = coalesce(route.tags, [])
    }
  ]

  firewall_rules_with_defaults = var.firewall_rules == null ? [] : [
    for rule in var.firewall_rules : {
      name               = rule.name
      description        = coalesce(rule.description, "Firewall rule ${rule.name} under ${var.vpc_name} VPC")
      direction          = rule.direction
      source_ranges      = coalesce(rule.source_ranges, [])
      destination_ranges = coalesce(rule.destination_ranges, [])

      source_tags = rule.source_tags
      target_tags = rule.target_tags

      allowed = rule.allowed == null ? [] : [
        for a in rule.allowed : {
          protocol = a.protocol
          ports    = a.ports
        }
      ]
      denied = rule.denied == null ? [] : [
        for d in rule.denied : {
          protocol = d.protocol
          ports    = d.ports
        }
      ]
    }
  ]
}

# -----------------------------------------------------
# Create a VPC with subnets 
# -----------------------------------------------------

resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  description                     = coalesce(var.vpc_description, "${var.vpc_name} - Virtual Private Cloud")
  routing_mode                    = var.vpc_routing_mode
  auto_create_subnetworks         = var.vpc_auto_create_subnets
  delete_default_routes_on_create = var.vpc_delete_default_routes_on_create
}

# -----------------------------------------------------
# Create custom subnets (if auto_create_subnets is false)
# -----------------------------------------------------
resource "google_compute_subnetwork" "subnets" {
  count                    = var.vpc_auto_create_subnets == false ? length(local.subnets_with_defaults) : 0
  name                     = local.subnets_with_defaults[count.index].name
  description              = local.subnets_with_defaults[count.index].description
  region                   = local.subnets_with_defaults[count.index].region
  ip_cidr_range            = local.subnets_with_defaults[count.index].ip_cidr_range
  private_ip_google_access = local.subnets_with_defaults[count.index].private_ip_google_access
  network                  = google_compute_network.vpc.self_link
  depends_on               = [google_compute_network.vpc]
}

# -----------------------------------------------------
# Create routes for VPC
# -----------------------------------------------------
resource "google_compute_route" "routes" {
  count                  = length(local.routes_with_defaults)
  name                   = local.routes_with_defaults[count.index].name
  dest_range             = local.routes_with_defaults[count.index].dest_range
  next_hop_gateway       = local.routes_with_defaults[count.index].next_hop_gateway
  next_hop_ip            = local.routes_with_defaults[count.index].next_hop_ip
  next_hop_ilb           = local.routes_with_defaults[count.index].next_hop_ilb
  next_hop_instance      = local.routes_with_defaults[count.index].next_hop_instance
  next_hop_instance_zone = local.routes_with_defaults[count.index].next_hop_instance_zone
  description            = local.routes_with_defaults[count.index].description
  tags                   = local.routes_with_defaults[count.index].tags
  network                = google_compute_network.vpc.self_link
  depends_on             = [google_compute_network.vpc]
}

# -----------------------------------------------------
# Setup firewall rules
# -----------------------------------------------------
resource "google_compute_firewall" "firewall_rules" {
  count       = local.firewall_rules_with_defaults == null ? 0 : length(local.firewall_rules_with_defaults)
  name        = local.firewall_rules_with_defaults[count.index].name
  description = local.firewall_rules_with_defaults[count.index].description
  direction   = local.firewall_rules_with_defaults[count.index].direction

  source_ranges      = local.firewall_rules_with_defaults[count.index].source_ranges
  destination_ranges = local.firewall_rules_with_defaults[count.index].destination_ranges

  source_tags = local.firewall_rules_with_defaults[count.index].source_tags
  target_tags = local.firewall_rules_with_defaults[count.index].target_tags

  dynamic "allow" {
    for_each = local.firewall_rules_with_defaults[count.index].allowed
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = local.firewall_rules_with_defaults[count.index].denied
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }

  network    = google_compute_network.vpc.self_link
  depends_on = [google_compute_network.vpc]
}

# -----------------------------------------------------
# Setup Web Server Compute Instance
# -----------------------------------------------------

resource "google_compute_instance" "web_server" {
  count        = var.webapp_compute_instance == null ? 0 : 1
  name         = var.webapp_compute_instance.name
  machine_type = var.webapp_compute_instance.machine_type
  zone         = var.webapp_compute_instance.zone
  tags         = var.webapp_compute_instance.tags
  boot_disk {
    initialize_params {
      image = var.webapp_compute_instance.image
      size  = var.webapp_compute_instance.disk_size
      type  = var.webapp_compute_instance.disk_type
    }
  }
  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.subnets[index(google_compute_subnetwork.subnets.*.name, var.webapp_compute_instance.subnet_name)].self_link

    // Ephemeral IP
    access_config {
    }
  }
  depends_on = [google_compute_network.vpc, google_compute_firewall.firewall_rules, google_compute_subnetwork.subnets]
}
