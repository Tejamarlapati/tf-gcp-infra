resource "random_id" "key_ring_random" {
  byte_length = 8
}

locals {
  key_prefix                           = "${var.key_prefix}-${random_id.key_ring_random.hex}"
  key_ring_crypto_keys_rotation_period = coalesce(var.key_ring_crypto_keys_rotation_period, "2592000s")

  key_ring                      = var.key_ring == null ? google_kms_key_ring.key_ring[0].id : var.key_ring.id
  google_kms_crypto_key_vm      = var.key_ring == null ? google_kms_crypto_key.vm[0].id : var.key_ring.vm_key
  google_kms_crypto_key_sql     = var.key_ring == null ? google_kms_crypto_key.sql[0].id : var.key_ring.sql_key
  google_kms_crypto_key_storage = var.key_ring == null ? google_kms_crypto_key.storage[0].id : var.key_ring.storage_key
}

# -----------------------------------------------------
# Create KMS Key Ring and Crypto Keys
# -----------------------------------------------------

resource "google_kms_key_ring" "key_ring" {
  count    = var.key_ring == null ? 1 : 0
  name     = "${local.key_prefix}_crypto_key_ring"
  location = var.region
}

resource "google_kms_crypto_key" "vm" {
  count           = var.key_ring == null ? 1 : 0
  name            = "${local.key_prefix}_crypto_key_vm"
  key_ring        = local.key_ring
  rotation_period = local.key_ring_crypto_keys_rotation_period
  depends_on      = [google_kms_key_ring.key_ring]
}

resource "google_kms_crypto_key" "sql" {
  count           = var.key_ring == null ? 1 : 0
  name            = "${local.key_prefix}_crypto_key_sql"
  key_ring        = local.key_ring
  rotation_period = local.key_ring_crypto_keys_rotation_period
  depends_on      = [google_kms_key_ring.key_ring]
}

resource "google_kms_crypto_key" "storage" {
  count           = var.key_ring == null ? 1 : 0
  name            = "${local.key_prefix}_crypto_key_storage"
  key_ring        = local.key_ring
  rotation_period = local.key_ring_crypto_keys_rotation_period
  depends_on      = [google_kms_key_ring.key_ring]
}

# -----------------------------------------------------
# Adding CMEK roles to the service agent
# -----------------------------------------------------

resource "google_kms_crypto_key_iam_binding" "vm_encrypter_decrypter" {
  crypto_key_id = local.google_kms_crypto_key_vm
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:service-${data.google_project.default.number}@compute-system.iam.gserviceaccount.com"]
}

resource "google_kms_crypto_key_iam_binding" "storage_encrypter_decrypter" {
  crypto_key_id = local.google_kms_crypto_key_storage
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:service-${data.google_project.default.number}@gs-project-accounts.iam.gserviceaccount.com"]
}

resource "google_kms_crypto_key_iam_binding" "db_encrypter_decrypter" {
  crypto_key_id = local.google_kms_crypto_key_sql
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:service-${data.google_project.default.number}@gcp-sa-cloud-sql.iam.gserviceaccount.com"]
}
