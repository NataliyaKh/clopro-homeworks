resource "yandex_storage_bucket" "image_bucket" {
  bucket     = "nkh-2025-09-09"
  access_key = var.access_key
  secret_key = var.secret_key

  anonymous_access_flags {
    read = true
    list = false
  }
}

resource "yandex_storage_object" "image" {
  bucket       = yandex_storage_bucket.image_bucket.bucket
  key          = "trees.jpg"
  source       = "trees.jpg"
  access_key   = var.access_key
  secret_key   = var.secret_key
  content_type = "image/jpeg"
}
