provider "nomad" {
  address = "http://localhost:4646"
}

provider "consul" {
  address    = "http://localhost:8500"
}

terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = ">= 0.7.1"
    }
  }
}
