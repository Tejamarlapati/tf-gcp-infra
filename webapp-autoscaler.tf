
# -----------------------------------------------------
# Creating service account for Ops Agent with IAM bindings
# -----------------------------------------------------

resource "google_service_account" "webapp_service_account" {
  account_id   = var.service_account_id
  display_name = "Webapp Service Account"
  description  = "${var.service_account_id} Service Account"
}

resource "google_project_iam_binding" "webapp_service_account_iam_bindings" {
  count   = length(var.service_account_iam_bindings)
  project = var.project_id
  role    = var.service_account_iam_bindings[count.index]
  members = [google_service_account.webapp_service_account.member]
}

# -----------------------------------------------------
# Regional Compute Instance Template
# -----------------------------------------------------

resource "google_compute_region_instance_template" "webapp" {
  region = var.region

  name_prefix    = "${var.webapp_compute_instance.name}-template-"
  can_ip_forward = false

  description          = "This template is used to create ${var.webapp_compute_instance.name} instances."
  instance_description = "${var.webapp_compute_instance.name} Instance"

  tags         = var.webapp_compute_instance.tags
  machine_type = var.webapp_compute_instance.machine_type

  disk {
    source_image = var.webapp_compute_instance.image
    auto_delete  = true
    boot         = true
    disk_type    = var.webapp_compute_instance.disk_type
    disk_size_gb = var.webapp_compute_instance.disk_size
  }

  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.subnets[index(google_compute_subnetwork.subnets.*.name, var.webapp_compute_instance.subnet_name)].self_link
    access_config {}
  }

  metadata_startup_script = templatefile("./startup.sh", {
    name      = module.database.database_name
    host      = module.database.ip_address
    username  = module.database.username
    password  = urlencode("${module.database.password}")
    loglevel  = var.webapp_log_level
    topicname = google_pubsub_topic.pubsub_topic.name
  })

  service_account {
    email  = google_service_account.webapp_service_account.email
    scopes = var.service_account_vm_scopes
  }

  lifecycle {
    create_before_destroy = true
    # ignore_changes        = [disk[0]]
  }

  depends_on = [
    google_compute_network.vpc,
    google_compute_firewall.firewall_rules,
    google_compute_subnetwork.subnets,
    module.database,
    google_service_account.webapp_service_account,
    google_project_iam_binding.webapp_service_account_iam_bindings,
    google_pubsub_topic.pubsub_topic
  ]
}

# -----------------------------------------------------
# Webapp Compute instance Health Check
# -----------------------------------------------------
resource "google_compute_health_check" "webapp" {
  name = coalesce(var.http_basic_health_check.name, "webapp-http-health-check")

  timeout_sec         = coalesce(var.http_basic_health_check.timeout_sec, 5)
  check_interval_sec  = coalesce(var.http_basic_health_check.check_interval_sec, 5)
  healthy_threshold   = coalesce(var.http_basic_health_check.healthy_threshold, 3)
  unhealthy_threshold = coalesce(var.http_basic_health_check.unhealthy_threshold, 3)

  http_health_check {
    request_path = coalesce(var.http_basic_health_check.request_path, "/healthz")
    port         = coalesce(var.http_basic_health_check.port, 80)
  }
}

# -----------------------------------------------------
# Regional Webapp Instance Group Manager
# -----------------------------------------------------
resource "google_compute_region_instance_group_manager" "webapp" {
  name        = "${var.webapp_compute_instance.name}-group-manager"
  description = "This instance group manager is used to manage ${var.webapp_compute_instance.name} instances."

  region                    = var.region
  distribution_policy_zones = ["${var.region}-b", "${var.region}-c", "${var.region}-d"]

  version {
    instance_template = google_compute_region_instance_template.webapp.self_link
  }

  auto_healing_policies {
    initial_delay_sec = 240
    health_check      = google_compute_health_check.webapp.self_link
  }

  named_port {
    name = "http"
    port = 80
  }

  base_instance_name = var.webapp_compute_instance.name

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
  }

  update_policy {
    type                           = "PROACTIVE"
    instance_redistribution_type   = "PROACTIVE"
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_percent              = 0
    max_unavailable_fixed          = 3
    replacement_method             = "SUBSTITUTE"
  }
}

# -----------------------------------------------------
# Regional Webapp Instance Auto Scaler
# -----------------------------------------------------
resource "google_compute_region_autoscaler" "webapp" {
  name   = coalesce(var.webapp_auto_scaler.name, "${var.webapp_compute_instance.name}-autoscaler")
  target = google_compute_region_instance_group_manager.webapp.id

  autoscaling_policy {
    mode            = "ON"
    min_replicas    = coalesce(var.webapp_auto_scaler.min_replicas, 3)
    max_replicas    = coalesce(var.webapp_auto_scaler.max_replicas, 6)
    cooldown_period = coalesce(var.webapp_auto_scaler.cooldown_period, 120)

    cpu_utilization {
      target = coalesce(var.webapp_auto_scaler.cpu_utilization_target, 0.05)
    }

    dynamic "scale_in_control" {
      for_each = var.webapp_auto_scaler.scale_in_control == null ? [] : [var.webapp_auto_scaler.scale_in_control]
      content {
        max_scaled_in_replicas {
          fixed = coalesce(scale_in_control.value.max_scaled_in_replicas_fixed, 1)
        }
        time_window_sec = coalesce(scale_in_control.value.time_window_sec, 300)
      }
    }
  }
}
