terraform {
  required_version = ">= 0.13"

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }

  backend "s3" {
    # Значения задаются через -backend-config или .tfbackend файлы:
    #   bucket, key, region, endpoints, access_key, secret_key
    #
    # Это позволяет:
    # - не хранить секреты в коде
    # - использовать разные ключи (key) для разных окружений
    # - переключаться между MinIO / Yandex Object Storage / AWS S3

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
    use_path_style              = true # обязательно для MinIO
  }
}

provider "yandex" {
  zone = var.zone
}
