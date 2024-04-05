resource "google_kms_key_ring" "key_ring" {
  count    = var.key_ring == null ? 1 : 0
  name     = "${var.key_prefix}_crypto_key_ring"
  location = var.region
}

locals {
  key_ring                      = var.key_ring == null ? google_kms_key_ring.key_ring[0].id : var.key_ring.id
  google_kms_crypto_key_vm      = var.key_ring == null ? google_kms_crypto_key.vm[0].id : var.key_ring.vm_key
  google_kms_crypto_key_sql     = var.key_ring == null ? google_kms_crypto_key.sql[0].id : var.key_ring.sql_key
  google_kms_crypto_key_storage = var.key_ring == null ? google_kms_crypto_key.storage[0].id : var.key_ring.storage_key
}

resource "google_kms_crypto_key" "vm" {
  count           = var.key_ring == null ? 1 : 0
  name            = "${var.key_prefix}_crypto_key_vm"
  key_ring        = local.key_ring
  rotation_period = "2592000s"
  depends_on      = [google_kms_key_ring.key_ring]
}

resource "google_kms_crypto_key" "sql" {
  count           = var.key_ring == null ? 1 : 0
  name            = "${var.key_prefix}_crypto_key_sql"
  key_ring        = local.key_ring
  rotation_period = "2592000s"
  depends_on      = [google_kms_key_ring.key_ring]
}

resource "google_kms_crypto_key" "storage" {
  count           = var.key_ring == null ? 1 : 0
  name            = "${var.key_prefix}_crypto_key_storage"
  key_ring        = local.key_ring
  rotation_period = "2592000s"
  depends_on      = [google_kms_key_ring.key_ring]
}
