resource "wakamevdc_security_group" "web_security_group" {
  display_name = "WebSecurityGroup"
  description = "Enable SSH access, HTTP access via port 80"
  rules = "tcp:80,80,ip4:0.0.0.0"
}

resource "wakamevdc_security_group" "ap_security_group" {
  display_name = "APSecurityGroup"
  description = "Enable AJP access via / JMX access"
  rules = "tcp:8009,8009,${wakamevdc_security_group.web_security_group.id}\ntcp:12345,12345,ip4:10.0.0.0\ntcp:12346,12346,ip4:10.0.0.0"
}

resource "wakamevdc_security_group" "db_security_group" {
  display_name = "DBSecurityGroup"
  description = "Enable DB access via port 5432"
  rules = "tcp:5432,5432,${wakamevdc_security_group.ap_security_group.id}"
}

resource "wakamevdc_instance" "web_server" {
  display_name = "WebServer"
  cpu_cores = 1
  memory_size = 512
  image_id = "${var.web_image}"
  hypervisor = "kvm"
  ssh_key_id = "${var.ssh_key_id}"

  vif {
    network_id = "${var.private_network}"
    security_groups = [
      "${var.shared_security_group}",
      "${wakamevdc_security_group.web_security_group.id}"
    ]
  }
  vif {
    network_id = "${var.public_network}"
    security_groups = [
      "${var.shared_security_group}",
      "${wakamevdc_security_group.web_security_group.id}"
    ]
  }
}

resource "wakamevdc_instance" "ap_server" {
  display_name = "APServer"
  cpu_cores = 1
  memory_size = 512
  image_id = "${var.ap_image}"
  hypervisor = "kvm"
  ssh_key_id = "${var.ssh_key_id}"

  vif {
    network_id = "${var.private_network}"
    security_groups = [
      "${var.shared_security_group}",
      "${wakamevdc_security_group.ap_security_group.id}"
    ]
  }
}

resource "wakamevdc_instance" "db_server" {
  display_name = "DBServer"
  cpu_cores = 1
  memory_size = 512
  image_id = "${var.db_image}"
  hypervisor = "kvm"
  ssh_key_id = "${var.ssh_key_id}"

  vif {
    network_id = "${var.private_network}"
    security_groups = [
      "${var.shared_security_group}",
      "${wakamevdc_security_group.db_security_group.id}"
    ]
  }
}

output "cluster_addresses" {
  value = "${wakamevdc_instance.web_server.vif.0.ip_address}, ${wakamevdc_instance.ap_server.vif.0.ip_address}, ${wakamevdc_instance.db_server.vif.0.ip_address}"
}

output "frontend_addresses" {
  value = "${wakamevdc_instance.web_server.vif.1.ip_address}"
}
