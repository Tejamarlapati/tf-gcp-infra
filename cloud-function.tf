locals {
  cloud_function = {
    name        = var.cloud_function.name
    location    = coalesce(var.cloud_function.location, var.region)
    runtime     = var.cloud_function.runtime
    entry_point = var.cloud_function.entry_point

    service_config = merge({
      max_instance_count    = 1
      min_instance_count    = 1
      available_memory      = "256M"
      timeout_seconds       = 60
      environment_variables = {}
    }, var.cloud_function.service_config)


    trigger = merge({
      trigger_region = var.region,
      event_type     = "google.cloud.pubsub.topic.v1.messagePublished",
      retry_policy   = "RETRY_POLICY_RETRY"
    }, var.cloud_function.trigger)

    storage          = var.cloud_function.storage
    ingress_settings = coalesce(var.cloud_function.ingress_settings, "ALLOW_INTERNAL_ONLY")
  }
}

# -----------------------------------------------------
# Setup cloud function service account with IAM restrictions
# -----------------------------------------------------

resource "google_service_account" "cloud_function_service_account" {
  account_id   = var.cloud_function_service_account_id
  display_name = "Cloud Function Service Account"
  description  = "${var.cloud_function_service_account_id} Service Account"
}

resource "google_cloud_run_v2_service_iam_binding" "cloud_function" {
  name    = google_cloudfunctions2_function.cloud_function.name
  role    = "roles/run.invoker"
  members = [google_service_account.cloud_function_service_account.member]
}

# -----------------------------------------------------
# Setup Google v2 Cloud Function
# -----------------------------------------------------
resource "google_vpc_access_connector" "cloud_function_db_connector" {
  name          = "cf-db-connector"
  ip_cidr_range = "10.20.0.0/28"
  network       = google_compute_network.vpc.self_link
}

resource "google_cloudfunctions2_function" "cloud_function" {
  project     = var.project_id
  name        = local.cloud_function.name
  location    = local.cloud_function.location
  description = "${local.cloud_function.name} Cloud Function"

  build_config {
    runtime     = local.cloud_function.runtime
    entry_point = local.cloud_function.entry_point
    environment_variables = {
    }
    source {
      storage_source {
        bucket = local.cloud_function.storage.bucket_name
        object = local.cloud_function.storage.object_name
      }
    }
  }

  service_config {
    max_instance_count = local.cloud_function.service_config.max_instance_count
    min_instance_count = local.cloud_function.service_config.min_instance_count
    available_memory   = local.cloud_function.service_config.available_memory
    timeout_seconds    = local.cloud_function.service_config.timeout_seconds

    environment_variables = merge({
      "DB_NAME"     = "${module.database.database_name}"
      "DB_USER"     = "${module.database.username}"
      "DB_PASSWORD" = urlencode("${module.database.password}")
      "DB_HOST"     = "${module.database.ip_address}"
      "DB_PORT"     = "5432"
      "DB_TIMEOUT"  = 10000
      "SSL"         = true
    }, local.cloud_function.service_config.environment_variables)

    ingress_settings               = local.cloud_function.ingress_settings
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.cloud_function_service_account.email
    vpc_connector                  = google_vpc_access_connector.cloud_function_db_connector.self_link
    vpc_connector_egress_settings  = "PRIVATE_RANGES_ONLY"
  }

  event_trigger {
    service_account_email = google_service_account.cloud_function_service_account.email
    trigger_region        = local.cloud_function.trigger.trigger_region
    event_type            = local.cloud_function.trigger.event_type
    pubsub_topic          = google_pubsub_topic.pubsub_topic.id
    retry_policy          = local.cloud_function.trigger.retry_policy
  }
}
