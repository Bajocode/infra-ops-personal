resource "local_file" "output" {
  content = <<EOF
master0_ip=${hcloud_server.master-0.ipv4_address}

worker0_ip=${hcloud_server.worker-0.ipv4_address}

floating_ip=${hcloud_floating_ip.k8s_load_balancer.ip_address}
EOF

  filename = "./outputs"
}
