variable "hcloud_token" {}

provider "hcloud" {
  version = "1.15"
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name = "default"
  public_key = file("~/.ssh/id_rsa.pub")
}
