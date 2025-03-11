provider "nomad" {
  address = "http://localhost:24646"
}

provider "consul" {
  address    = "http://localhost:28500"
}

terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = ">= 0.7.1"
    }
  }
}
