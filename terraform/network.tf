resource "hcloud_network" "vpc" {
  name = "kthw"
  ip_range = "10.240.0.0/24"
}
resource "hcloud_network_subnet" "subnet" {
  network_id = hcloud_network.vpc.id
  type = "server"
  network_zone = "eu-central"
  ip_range = "10.240.0.0/24"
}
resource "hcloud_floating_ip" "k8s_load_balancer" {
  name = "k8s_load_balancer"
  type = "ipv4"
  home_location = "nbg1"
}

# add to subnet masters 
resource "hcloud_server_network" "subnet_master-0" {
  server_id = hcloud_server.master-0.id
  network_id = hcloud_network.vpc.id
  ip = "10.240.0.10"
}
/*
resource "hcloud_server_network" "subnet_master-1" {
  server_id = hcloud_server.master-1.id
  network_id = hcloud_network.vpc.id
  ip = "10.240.0.11"
}
resource "hcloud_server_network" "subnet_master-2" {
  server_id = hcloud_server.master-2.id
  network_id = hcloud_network.vpc.id
  ip = "10.240.0.12"
}
*/

# add to subnet workers
resource "hcloud_server_network" "subnet_worker-0" {
  server_id = hcloud_server.worker-0.id
  network_id = hcloud_network.vpc.id
  ip = "10.240.0.20"
}
/*
resource "hcloud_server_network" "subnet_worker-1" {
  server_id = hcloud_server.worker-1.id
  network_id = hcloud_network.vpc.id
  ip = "10.240.0.21"
}
resource "hcloud_server_network" "subnet_worker-2" {
  server_id = hcloud_server.worker-2.id
  network_id = hcloud_network.vpc.id
  ip = "10.240.0.22"
}
*/
