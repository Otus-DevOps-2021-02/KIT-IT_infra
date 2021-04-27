terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "kit-it"
    region     = "ru-central-1"
    key        = "terraform.tfstate"
    access_key = "bkk4qhdCh"
    secret_key = "PJytYlxWrKFV9XoHX0Oho19"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
