locals {
  instance_tags = concat(["load-balanced-backend"], coalesce(var.instance_tags, []))
  create_ip     = coalesce(var.ip_settings.create_ip, false)
  ip_address    = local.create_ip ? "${google_compute_address.load_balancer.0.address}" : var.ip_settings.ip_address
}

# -----------------------------------------------------
# Setup Global External IP for Load Balancer
# -----------------------------------------------------
resource "google_compute_address" "load_balancer" {
  count        = local.create_ip ? 1 : 0
  name         = "${var.name}-ip"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

# -----------------------------------------------------
# Load Balancer Basic Health Check
# -----------------------------------------------------
resource "google_compute_region_health_check" "load_balancer" {
  name = "${var.name}-health-check"

  timeout_sec         = coalesce(var.health_check.timeout_sec, 5)
  check_interval_sec  = coalesce(var.health_check.check_interval_sec, 5)
  healthy_threshold   = coalesce(var.health_check.healthy_threshold, 3)
  unhealthy_threshold = coalesce(var.health_check.unhealthy_threshold, 3)

  http_health_check {
    port_specification = "USE_SERVING_PORT"
    request_path       = coalesce(var.health_check.request_path, "/healthz")
  }
}

# -----------------------------------------------------
# Load Balancer Backend Service
# -----------------------------------------------------
resource "google_compute_region_backend_service" "load_balancer" {
  name        = "${var.name}-backend"
  description = "Backend for ${var.name} Load Balancer"
  region      = var.region

  load_balancing_scheme = "EXTERNAL_MANAGED"

  protocol    = "HTTP"
  port_name   = var.named_port
  timeout_sec = 30

  backend {
    group           = var.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_region_health_check.load_balancer.id]

  locality_lb_policy              = "ROUND_ROBIN"
  session_affinity                = "NONE"
  connection_draining_timeout_sec = 120
}

# -----------------------------------------------------
# Load Balancer URL Map
# -----------------------------------------------------
resource "google_compute_region_url_map" "load_balancer" {
  name            = var.name
  default_service = google_compute_region_backend_service.load_balancer.id
}

# -----------------------------------------------------
# Load Balancer Target HTTPS Proxy
# -----------------------------------------------------
resource "google_compute_region_target_https_proxy" "load_balancer" {
  name             = "${var.name}-proxy"
  url_map          = google_compute_region_url_map.load_balancer.id
  ssl_certificates = var.ssl_certificates

  lifecycle {
    precondition {
      condition     = var.ssl_certificates != null
      error_message = "SSL certificates are required to create a external regional HTTPS load balancer."
    }
  }
}

# -----------------------------------------------------
# Load Balancer Proxy Subnet
# -----------------------------------------------------
resource "google_compute_subnetwork" "load_balancer_proxy_subnet" {
  name          = "${var.name}-proxy-subnet"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  ip_cidr_range = coalesce(var.proxy_subnet_cidr, "10.0.10.0/24")
  network       = var.network
}

# -----------------------------------------------------
# Load Balancer Forwarding Rule
# -----------------------------------------------------
resource "google_compute_forwarding_rule" "load_balancer" {
  name                  = "${var.name}-https-forwarding-rule"
  target                = google_compute_region_target_https_proxy.load_balancer.id
  ip_address            = local.ip_address
  ip_protocol           = "TCP"
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network               = var.network
  depends_on            = [google_compute_subnetwork.load_balancer_proxy_subnet]
}

# -----------------------------------------------------
# Load Balancer Firewall Rule
# -----------------------------------------------------
resource "google_compute_firewall" "default" {
  name = "${var.name}-allow-health-check"
  allow {
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = var.network
  priority      = 1000
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = local.instance_tags
}

resource "google_compute_firewall" "allow_proxy" {
  name = "${var.name}-allow-proxies"
  allow {
    ports    = ["80", "443"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  network       = var.network
  priority      = 1000
  source_ranges = [google_compute_subnetwork.load_balancer_proxy_subnet.ip_cidr_range]
  target_tags   = local.instance_tags
}
