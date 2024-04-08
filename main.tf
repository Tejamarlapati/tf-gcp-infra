# -----------------------------------------------------
# Project Data
# -----------------------------------------------------
data "google_project" "default" {
}

# -----------------------------------------------------
# Create database instance and setup database
# -----------------------------------------------------
module "database" {
  source                 = "./modules/database"
  network                = google_compute_network.vpc.self_link
  database_sql_instance  = var.database_sql_instance
  disk_encryption_key_id = local.google_kms_crypto_key_sql
}

# -----------------------------------------------------
# Setup Load Balancer
# -----------------------------------------------------
module "external-lb" {
  # source = "./modules/external-regional-https-lb"
  source = "./modules/external-global-https-lb"

  project_id = var.project_id
  region     = var.region

  name                    = var.webapp_load_balancer.name
  ssl_certificates        = var.webapp_load_balancer.ssl_certificates
  ssl_certificate_domains = [var.webapp_dns_record_set.name]

  health_check = var.http_basic_health_check

  network        = google_compute_network.vpc.self_link
  instance_group = google_compute_region_instance_group_manager.webapp.instance_group
  instance_tags  = google_compute_region_instance_template.webapp.tags

  ip_settings = {
    create_ip  = coalesce(var.webapp_load_balancer.ip_address, "DEFAULT") == "DEFAULT" ? true : false
    ip_address = var.webapp_load_balancer.ip_address
  }
}

# -----------------------------------------------------
# Setup DNS for the Load Balancer
# -----------------------------------------------------
resource "google_dns_record_set" "load_balancer" {
  name         = var.webapp_dns_record_set.name
  type         = var.webapp_dns_record_set.type
  ttl          = var.webapp_dns_record_set.ttl
  managed_zone = var.webapp_dns_record_set.managed_zone
  rrdatas      = [module.external-lb.load_balancer.ip_address]
  depends_on   = [module.external-lb.load_balancer]
}
