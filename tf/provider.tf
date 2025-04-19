provider "nomad" {
  address = "http://ntoulapa.lgian.com:4646"
}

provider "consul" {
  address    = "http://ntoulapa.lgian.com:8500"
}

terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = ">= 0.7.1"
    }
  }
}
