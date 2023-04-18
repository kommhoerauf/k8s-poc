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
# Instances
################################################################################


resource "openstack_compute_instance_v2" "workers" {
  count       = var.num
  name        = "worker-${count.index}"
  image_id    = var.image
  flavor_name = var.flavor
  metadata    = var.metadata
  user_data = templatefile("${path.module}/cloud.cfg", {
    ssh_keys = indent(8, "\n- ${join("\n- ", var.ssh_keys)}")
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
    for ip in openstack_compute_instance_v2.workers.*.access_ip_v4 :
    {
      address = ip
      user    = "worker"
      port    = 22
      keyPath = null
    }
  ]
}
output "worker_ip" {
  value = openstack_compute_instance_v2.workers.*.access_ip_v4
}
