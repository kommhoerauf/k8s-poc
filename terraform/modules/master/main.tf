################################################################################
# Input variables
################################################################################

variable "num" {
  type    = string
  default = "3"
}

variable "net" {
  type = string
}

variable "image" {
  type = string
}

variable "ssh_keys" {
  type = list(any)
}

variable "flavor" {
  type = string
}

variable "metadata" {
  type = map(any)
}

################################################################################
# Ignition - in case we work with Flatcar images
################################################################################

#data "ignition_user" "ignition_data" {
#  name                = "core"
#  home_dir            = "/home/core/"
#  shell               = "/bin/bash"
#  ssh_authorized_keys = var.ssh_keys
#}

#data "ignition_systemd_unit" "k0sctl_install" {
#    name = "k0sctl-setup.service"
#    content = "[Unit]\nDescription=Download and setup k0sctl\nAfter=network-online.target\nWants=network-online.target\nConditionFirstBoot=yes\n\n[Service]\nType=oneshot\nExecStartPre=-/usr/bin/mkdir -p /opt/bin\nExecStartPre=-/usr/bin/rm -f /opt/bin/k0sctl\nExecStartPre=/usr/bin/curl -L -o /opt/bin/k0sctl https://github.com/k0sproject/k0sctl/releases/download/v0.15.0/k0sctl-linux-x64\nExecStart=/usr/bin/chmod +x /opt/bin/k0sctl\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target"
#}

#data "ignition_config" "user_data" {
#  users = [
#    data.ignition_user.ignition_data.rendered
#  ]
#  systemd = [
#    data.ignition_systemd_unit.k0sctl_install.rendered
#  ]
#}

################################################################################
# Instances
################################################################################

resource "openstack_compute_instance_v2" "masters" {
  count       = var.num
  name        = "master-${count.index}"
  image_id    = var.image
  flavor_name = var.flavor
  metadata    = var.metadata
  # Ignition is only needed when using a Flatcar image
  #user_data   = data.ignition_config.user_data.rendered
  user_data = templatefile("${path.module}/cloud.cfg", {
    ssh_keys          = indent(8, "\n- ${join("\n- ", var.ssh_keys)}"),
    install_master_sh = base64encode(file("${path.module}/scripts/install_master.sh")),
  })

  network {
    uuid = var.net
  }

  lifecycle {
    ignore_changes = [
      image_id,
    ]
  }
}

################################################################################
# Output
################################################################################

output "host_entries" {
  value = [
    for ip in openstack_compute_instance_v2.masters.*.access_ip_v4 :
    {
      address = ip
      user    = "master"
      port    = 22
      keyPath = null
    }
  ]
}
output "master_ips" {
  value = openstack_compute_instance_v2.masters.*.access_ip_v4
}