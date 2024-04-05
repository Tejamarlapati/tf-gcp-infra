locals {
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
      name = "vpc-database-private-access"
    }, var.database_sql_instance.private_access_config)
  }
}

# -----------------------------------------------------
# Setup Internal IP for Database Server
# -----------------------------------------------------
resource "google_compute_global_address" "database_private_access_ip" {
  name          = local.database_sql_instance.private_access_config.name
  address_type  = local.database_sql_instance.private_access_config.address_type
  purpose       = local.database_sql_instance.private_access_config.purpose
  address       = local.database_sql_instance.private_access_config.address
  prefix_length = local.database_sql_instance.private_access_config.prefix_length
  network       = var.network
}

resource "google_service_networking_connection" "database_private_access_networking_connection" {
  service                 = "servicenetworking.googleapis.com"
  network                 = google_compute_global_address.database_private_access_ip.network
  reserved_peering_ranges = [google_compute_global_address.database_private_access_ip.name]
  deletion_policy         = "ABANDON"
  depends_on              = [google_compute_global_address.database_private_access_ip]
}

# -----------------------------------------------------
# Setup Database Encryption Key
# -----------------------------------------------------

resource "google_kms_crypto_key_iam_binding" "encrypter_decrypter" {
  crypto_key_id = var.disk_encryption_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql.email}"]
}

resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  provider = google-beta
  service  = "sqladmin.googleapis.com"
}


# -----------------------------------------------------
# Setup Database Cloud SQL Instance
# -----------------------------------------------------
resource "random_id" "database_instance_id" {
  byte_length = 4
}

resource "google_sql_database_instance" "database_instance" {
  name                = "${local.database_sql_instance.name}-${random_id.database_instance_id.hex}"
  region              = local.database_sql_instance.region
  database_version    = local.database_sql_instance.database_version
  deletion_protection = local.database_sql_instance.deletion_protection

  encryption_key_name = var.disk_encryption_key_id

  settings {
    tier                        = local.database_sql_instance.tier
    availability_type           = local.database_sql_instance.availability_type
    disk_size                   = local.database_sql_instance.disk_size
    disk_type                   = local.database_sql_instance.disk_type
    disk_autoresize             = false
    deletion_protection_enabled = local.database_sql_instance.deletion_protection

    ip_configuration {
      private_network                               = google_service_networking_connection.database_private_access_networking_connection.network
      ipv4_enabled                                  = local.database_sql_instance.ip_configuration.ipv4_enabled
      require_ssl                                   = local.database_sql_instance.ip_configuration.require_ssl
      ssl_mode                                      = local.database_sql_instance.ip_configuration.ssl_mode
      enable_private_path_for_google_cloud_services = local.database_sql_instance.ip_configuration.enable_private_path_for_google_cloud_services
    }
  }
  depends_on = [google_service_networking_connection.database_private_access_networking_connection]
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
  name       = local.database_sql_instance.database_name
  instance   = google_sql_database_instance.database_instance.name
  depends_on = [google_sql_database_instance.database_instance, google_sql_user.database_user]
}

resource "google_sql_user" "database_user" {
  instance   = google_sql_database_instance.database_instance.name
  name       = local.database_sql_instance.database_username
  password   = random_password.database_password.result
  depends_on = [google_sql_database_instance.database_instance]
}
