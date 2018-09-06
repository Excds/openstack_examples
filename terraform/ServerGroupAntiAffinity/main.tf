provider "openstack" {
  version = "~> 1.8"
  cloud   = "optimist_training"
}

# Network

resource "openstack_networking_network_v2" "net-example-servergrp1" {
  name           = "net-example-servergrp1"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet-example-servergrp1-v4" {
  name       = "net-example-servergrp1-subnet01"
  network_id = "${openstack_networking_network_v2.net-example-servergrp1.id}"
  cidr       = "10.0.8.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8","8.8.4.4"]
}

resource "openstack_networking_subnet_v2" "subnet-example-servergrp1-v6" {
  name       = "net-example-servergrp1-subnet02"
  network_id = "${openstack_networking_network_v2.net-example-servergrp1.id}"
  ip_version = 6
  ipv6_address_mode = "dhcpv6-stateful"
  ipv6_ra_mode = "dhcpv6-stateful"
  subnetpool_id = "${var.ipv6_subnetpool_id}"
  dns_nameservers = ["2001:4860:4860::8888","2001:4860:4860::8844"]
}

# Router

resource "openstack_networking_router_v2" "router-example-servergrp1" {
  name                = "router-example-servergrp1"
  external_network_id = "${var.provider_network_id}"
}

resource "openstack_networking_router_interface_v2" "router_interface_v4" {
  router_id = "${openstack_networking_router_v2.router-example-servergrp1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet-example-servergrp1-v4.id}"
}

resource "openstack_networking_router_interface_v2" "router_interface_v6" {
  router_id = "${openstack_networking_router_v2.router-example-servergrp1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet-example-servergrp1-v6.id}"
}

# Security Groups

resource "openstack_networking_secgroup_v2" "example-servergrp1-allow_ssh_icmp" {
  name        = "allow_ssh_icmp"
  description = " allow incoming ssh and icmp traffic from anywhere."
}

resource "openstack_networking_secgroup_rule_v2" "example-servergrp1-secgrp-ssh-v4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.example-servergrp1-allow_ssh_icmp.id}"
}

resource "openstack_networking_secgroup_rule_v2" "example-servergrp1-secgrp-icmp-v4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.example-servergrp1-allow_ssh_icmp.id}"
}

resource "openstack_networking_secgroup_rule_v2" "example-servergrp1-secgrp-ssh-v6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "::/0"
  security_group_id = "${openstack_networking_secgroup_v2.example-servergrp1-allow_ssh_icmp.id}"
}

resource "openstack_networking_secgroup_rule_v2" "example-servergrp1-secgrp-icmp-v6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "ipv6-icmp"
  remote_ip_prefix  = "::/0"
  security_group_id = "${openstack_networking_secgroup_v2.example-servergrp1-allow_ssh_icmp.id}"
}

# Compute

resource "openstack_compute_servergroup_v2" "anti-affinity-servergrp" {
  name     = "anti-affinity-servergrp"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "vm-example-servergrp1-1" {
  name            = "vm-example-servergrp1-1"
  image_name      = "${var.server_image}"
  flavor_name     = "m1.micro"
  key_pair        = "${var.ssh_key}"
  availability_zone = "es1"
  security_groups = ["default","${openstack_networking_secgroup_v2.example-servergrp1-allow_ssh_icmp.name}"]

  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.anti-affinity-servergrp.id}"
  }

  network {
    name = "${openstack_networking_network_v2.net-example-servergrp1.name}"
  }
}

resource "openstack_compute_instance_v2" "vm-example-servergrp1-2" {
  name            = "vm-example-servergrp1-2"
  image_name      = "${var.server_image}"
  flavor_name     = "m1.micro"
  key_pair        = "${var.ssh_key}"
  availability_zone = "es1"
  security_groups = ["default","${openstack_networking_secgroup_v2.example-servergrp1-allow_ssh_icmp.name}"]

  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.anti-affinity-servergrp.id}"
  }

  network {
    name = "${openstack_networking_network_v2.net-example-servergrp1.name}"
  }
}

resource "openstack_compute_instance_v2" "vm-example-servergrp1-3" {
  name            = "vm-example-servergrp1-3"
  image_name      = "${var.server_image}"
  flavor_name     = "m1.micro"
  key_pair        = "${var.ssh_key}"
  availability_zone = "ix1"
  security_groups = ["default","${openstack_networking_secgroup_v2.example-servergrp1-allow_ssh_icmp.name}"]

  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.anti-affinity-servergrp.id}"
  }

  network {
    name = "${openstack_networking_network_v2.net-example-servergrp1.name}"
  }
}

resource "openstack_compute_instance_v2" "vm-example-servergrp1-4" {
  name            = "vm-example-servergrp1-4"
  image_name      = "${var.server_image}"
  flavor_name     = "m1.micro"
  key_pair        = "${var.ssh_key}"
  availability_zone = "ix1"
  security_groups = ["default","${openstack_networking_secgroup_v2.example-servergrp1-allow_ssh_icmp.name}"]

  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.anti-affinity-servergrp.id}"
  }

  network {
    name = "${openstack_networking_network_v2.net-example-servergrp1.name}"
  }
}
