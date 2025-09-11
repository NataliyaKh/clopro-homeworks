variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
}

variable "yc_cloud_id" {
  description = "Yandex Cloud cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "public_key" {
  description = "SSH public key"
  type        = string
}

variable "access_key" {
  description = "Access key for Yandex Object Storage"
  type        = string
}

variable "secret_key" {
  description = "Secret key for Yandex Object Storage"
  type        = string
}

variable "yc_instance_service_account_id" {
  description = "Service account ID"
  type        = string
}
