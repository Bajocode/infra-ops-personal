# masters
resource "hcloud_server" "master-0" {
  name = "master-0"
  image = "ubuntu-18.04"
  server_type = "cx11"
	location = "nbg1"
	ssh_keys = [hcloud_ssh_key.default.id]
}
/*
resource "hcloud_server" "master-1" {
  name = "master-1"
  image = "ubuntu-18.04"
  server_type = "cx11"
	location = "nbg1"
	ssh_keys = [hcloud_ssh_key.default.id]
}
resource "hcloud_server" "master-2" {
  name = "master-2"
  image = "ubuntu-18.04"
  server_type = "cx11"
	location = "nbg1"
	ssh_keys = [hcloud_ssh_key.default.id]
}
*/

# workers
resource "hcloud_server" "worker-0" {
  name = "worker-0"
  image = "ubuntu-18.04"
  server_type = "cx21"
	location = "nbg1"
  labels = {pod_cidr="10.200.0.0-24"}
	ssh_keys = [hcloud_ssh_key.default.id]
}
/*
resource "hcloud_server" "worker-1" {
  name = "worker-1"
  image = "ubuntu-18.04"
  server_type = "cx21"
	location = "nbg1"
  labels = {pod_cidr="10.200.1.0-24"}
	ssh_keys = [hcloud_ssh_key.default.id]
}
resource "hcloud_server" "worker-2" {
  name = "worker-2"
  image = "ubuntu-18.04"
  server_type = "cx21"
	location = "nbg1"
  labels = {pod_cidr="10.200.2.0-24"}
	ssh_keys = [hcloud_ssh_key.default.id]
}
*/
