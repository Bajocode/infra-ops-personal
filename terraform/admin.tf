variable "hcloud_token" {}

terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name = "default"
  public_key = file("~/.ssh/id_rsa.pub")
}
