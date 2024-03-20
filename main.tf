locals {
  subnets_with_defaults = var.subnets == null ? [] : [
    for subnet in var.subnets : {
      name                     = subnet.name
      ip_cidr_range            = subnet.ip_cidr_range
      purpose                  = subnet.purpose
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
      priority           = coalesce(rule.priority, 1000)
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

  database_sql_instance = var.database_sql_instance == null ? null : {
    name              = var.database_sql_instance.name
    region            = var.database_sql_instance.region
    tier              = var.database_sql_instance.tier
    database_name     = var.database_sql_instance.database_name
    database_username = var.database_sql_instance.database_username

    database_version    = var.database_sql_instance.database_version
    disk_size           = var.database_sql_instance.disk_size
    disk_type           = var.database_sql_instance.disk_type
    availability_type   = var.database_sql_instance.availability_type
    deletion_protection = var.database_sql_instance.deletion_protection

    ip_configuration = merge({
      ipv4_enabled                                  = false
      require_ssl                                   = true
      enable_private_path_for_google_cloud_services = true
    }, var.database_sql_instance.ip_configuration)

    private_access_config = merge({
      name = "vpc-${var.vpc_name}-database-private-access"
    }, var.database_sql_instance.private_access_config)
  }
}

# -----------------------------------------------------
# Create a VPC with subnets 
# -----------------------------------------------------

resource "google_compute_network" "vpc" {
  provider                        = google
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
  provider                 = google
  count                    = var.vpc_auto_create_subnets == false ? length(local.subnets_with_defaults) : 0
  name                     = local.subnets_with_defaults[count.index].name
  description              = local.subnets_with_defaults[count.index].description
  purpose                  = local.subnets_with_defaults[count.index].purpose
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
  provider               = google
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
  provider      = google
  count         = local.firewall_rules_with_defaults == null ? 0 : length(local.firewall_rules_with_defaults)
  name          = local.firewall_rules_with_defaults[count.index].name
  description   = local.firewall_rules_with_defaults[count.index].description
  direction     = local.firewall_rules_with_defaults[count.index].direction
  priority      = local.firewall_rules_with_defaults[count.index].priority
  source_ranges = local.firewall_rules_with_defaults[count.index].source_ranges
  destination_ranges = compact([
    for each_dest_range in local.firewall_rules_with_defaults[count.index].destination_ranges :
    replace(each_dest_range, "DATABASE_PRIVATE_IP",
      local.database_sql_instance == null
      ? ""
      : "${google_compute_global_address.database_private_access_ip.0.address}/${google_compute_global_address.database_private_access_ip.0.prefix_length}"
    )
  ])

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
# Setup Internal IP for Database Server
# -----------------------------------------------------
resource "google_compute_global_address" "database_private_access_ip" {
  provider      = google
  count         = local.database_sql_instance == null ? 0 : 1
  name          = local.database_sql_instance.private_access_config.name
  address_type  = local.database_sql_instance.private_access_config.address_type
  purpose       = local.database_sql_instance.private_access_config.purpose
  address       = local.database_sql_instance.private_access_config.address
  prefix_length = local.database_sql_instance.private_access_config.prefix_length
  network       = google_compute_network.vpc.self_link
  depends_on    = [google_compute_network.vpc]
}

resource "google_service_networking_connection" "database_private_access_networking_connection" {
  provider                = google
  count                   = local.database_sql_instance == null ? 0 : 1
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.database_private_access_ip.0.name]
  deletion_policy         = "ABANDON"
  depends_on              = [google_compute_network.vpc, google_compute_global_address.database_private_access_ip]
}

# -----------------------------------------------------
# Setup Database Cloud SQL Instance
# -----------------------------------------------------
resource "random_id" "database_instance_id" {
  count       = local.database_sql_instance == null ? 0 : 1
  byte_length = 4
}

resource "google_sql_database_instance" "database_instance" {
  provider            = google
  count               = local.database_sql_instance == null ? 0 : 1
  name                = "${local.database_sql_instance.name}-${random_id.database_instance_id.0.hex}"
  region              = local.database_sql_instance.region
  database_version    = local.database_sql_instance.database_version
  deletion_protection = local.database_sql_instance.deletion_protection
  settings {
    tier                        = local.database_sql_instance.tier
    availability_type           = local.database_sql_instance.availability_type
    disk_size                   = local.database_sql_instance.disk_size
    disk_type                   = local.database_sql_instance.disk_type
    disk_autoresize             = false
    deletion_protection_enabled = local.database_sql_instance.deletion_protection
    ip_configuration {
      private_network                               = google_service_networking_connection.database_private_access_networking_connection.0.network
      ipv4_enabled                                  = local.database_sql_instance.ip_configuration.ipv4_enabled
      require_ssl                                   = local.database_sql_instance.ip_configuration.require_ssl
      ssl_mode                                      = local.database_sql_instance.ip_configuration.ssl_mode
      enable_private_path_for_google_cloud_services = local.database_sql_instance.ip_configuration.enable_private_path_for_google_cloud_services
    }
  }
  depends_on = [google_compute_network.vpc, google_compute_subnetwork.subnets]
}

# -----------------------------------------------------
# Setup database, username and password for the database
# -----------------------------------------------------

# generate random password
resource "random_password" "database_password" {
  length           = 16
  special          = true
  upper            = true
  numeric          = true
  lower            = true
  override_special = "_$*@~^{}|"
}

resource "google_sql_database" "database" {
  provider   = google
  count      = local.database_sql_instance == null ? 0 : 1
  name       = local.database_sql_instance.database_name
  instance   = google_sql_database_instance.database_instance.0.name
  depends_on = [google_sql_database_instance.database_instance, google_sql_user.database_user]
}

resource "google_sql_user" "database_user" {
  provider   = google
  count      = local.database_sql_instance == null ? 0 : 1
  instance   = google_sql_database_instance.database_instance.0.name
  name       = local.database_sql_instance.database_username
  password   = random_password.database_password.result
  depends_on = [google_sql_database_instance.database_instance]
}

# -----------------------------------------------------
# Creating service account for Ops Agent with IAM bindings
# -----------------------------------------------------

resource "google_service_account" "service_account" {
  account_id   = var.service_account_id
  display_name = "${var.service_account_id} Service Account"
}


resource "google_project_iam_binding" "service_account_iam_bindings" {
  count   = length(var.service_account_iam_bindings)
  project = var.project_id
  role    = var.service_account_iam_bindings[count.index]
  members = [google_service_account.service_account.member]
}

# -----------------------------------------------------
# Setup Web Server Compute Instance
# -----------------------------------------------------

resource "google_compute_instance" "web_server" {
  provider     = google
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

  metadata_startup_script = templatefile("./startup.sh", {
    name     = length(google_sql_database.database) > 0 ? "${google_sql_database.database.0.name}" : ""
    host     = length(google_sql_database_instance.database_instance) > 0 ? "${google_sql_database_instance.database_instance.0.private_ip_address}" : ""
    username = local.database_sql_instance.database_username
    password = urlencode("${random_password.database_password.result}")
    loglevel = var.webapp_log_level
  })

  service_account {
    email  = google_service_account.service_account.email
    scopes = var.service_account_vm_scopes
  }

  depends_on = [
    google_compute_network.vpc,
    google_compute_firewall.firewall_rules,
    google_compute_subnetwork.subnets,
    google_sql_database_instance.database_instance,
    google_service_account.service_account,
    google_project_iam_binding.service_account_iam_bindings
  ]
}

# -----------------------------------------------------
# Setup DNS for the Web Server
# -----------------------------------------------------
resource "google_dns_record_set" "webapp_dns_record" {
  count        = var.webapp_dns_record_set == null ? 0 : 1
  name         = var.webapp_dns_record_set.name
  type         = var.webapp_dns_record_set.type
  ttl          = var.webapp_dns_record_set.ttl
  managed_zone = var.webapp_dns_record_set.managed_zone
  rrdatas      = [google_compute_instance.web_server[count.index].network_interface[count.index].access_config[count.index].nat_ip]
  depends_on   = [google_compute_instance.web_server]
}
