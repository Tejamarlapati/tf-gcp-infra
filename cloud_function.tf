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

    ingress_settings = coalesce(var.cloud_function.ingress_settings, "ALLOW_INTERNAL_ONLY")
  }

  create_bucket = var.cloud_function.storage.bucket_name == null ? true : false
  bucket_name   = local.create_bucket == true ? google_storage_bucket.bucket[0].name : var.cloud_function.storage.bucket_name
  object_name   = local.create_bucket == true ? google_storage_bucket_object.object[0].name : var.cloud_function.storage.object_name
  should_clone  = var.cloud_function.storage.clone_url != null ? true : false
}

# -----------------------------------------------------
# Adding CMEK roles to the service agent
# -----------------------------------------------------

resource "google_kms_crypto_key_iam_binding" "storage_encrypter_decrypter" {
  crypto_key_id = local.google_kms_crypto_key_storage
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:service-${data.google_project.default.number}@gs-project-accounts.iam.gserviceaccount.com"]
}

# -----------------------------------------------------
# Create Cloud Function Storage Data
# -----------------------------------------------------
resource "null_resource" "git_clone" {
  count = local.should_clone == true ? 1 : 0
  provisioner "local-exec" {
    command = "rm -rf ./tmp/source && mkdir -p ./tmp/source && git clone ${var.cloud_function.storage.clone_url} ./tmp/source && zip -r ./tmp/serverless-main.zip ./tmp/source"
  }
}

resource "null_resource" "zip_code" {
  count = local.should_clone == false ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
      rm -rf ./tmp;
      mkdir -p ./tmp;
      current_path=$(pwd);
      cd ${var.cloud_function.storage.local_path};
      zip -r $current_path/tmp/serverless-main.zip .
    EOT
  }
}

resource "random_id" "bucket_id" {
  count       = local.create_bucket == true ? 1 : 0
  byte_length = 8
}

resource "google_storage_bucket" "bucket" {
  count                       = local.create_bucket == true ? 1 : 0
  name                        = "cloud-function-source-${data.google_project.default.number}-${random_id.bucket_id.0.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  encryption {
    default_kms_key_name = local.google_kms_crypto_key_storage
  }
  depends_on = [google_kms_crypto_key_iam_binding.storage_encrypter_decrypter]
}

resource "google_storage_bucket_object" "object" {
  count      = local.create_bucket == true ? 1 : 0
  name       = "serverless-main.zip"
  bucket     = google_storage_bucket.bucket.0.name
  source     = "./tmp/serverless-main.zip"
  depends_on = [null_resource.git_clone, null_resource.zip_code]
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
        bucket = local.bucket_name
        object = local.object_name
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

  depends_on = [google_storage_bucket.bucket, google_storage_bucket_object.object, google_service_account.cloud_function_service_account]
}
