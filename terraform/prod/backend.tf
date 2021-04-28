terraform {
  backend "s3" {
    endpoint                    = "storage.yandexcloud.net"
    bucket                      = "terraformobjectstoragekit"
    region                      = "ru-central1"
    key                         = "prod/terraform.tfstate"
    access_key                  = "jM2KZWCKeDxEIM6mp_Av"
    secret_key                  = "yuTfyBQRLn6rt5olC5aI0cnqU_r0o2shaFwEz9gn"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
