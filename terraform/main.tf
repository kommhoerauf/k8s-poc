################################################################################
# Input variables
################################################################################


variable "public_network" {
  type    = string
  default = "ext-net"
}

variable "number_master" {
  type    = string
  default = "3"
}

variable "number_worker" {
  type    = string
  default = "3"
}

variable "flavor_master" {
  type    = string
  default = "m1.tiny"
}

variable "flavor_worker" {
  type    = string
  default = "m1.tiny"
}

variable "ssh_keys" {
  type = list(string)
}

################################################################################
# Data we get from OpenStack
################################################################################

data "openstack_networking_network_v2" "public_network" {
  name = var.public_network
}

data "openstack_images_image_v2" "image" {
  most_recent = true

  visibility = "public"
  properties = {
    #os_distro  = "flatcar"
    #os_version = "stable"
    os_distro  = "ubuntu"
    os_version = "22.04"
  }
}

################################################################################
# Base network configuration
################################################################################

resource "openstack_networking_network_v2" "kubernetes_net" {
  name           = "kubernetes_net"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "kubernetes_subnet" {
  name            = "kubernetes_subnet"
  network_id      = openstack_networking_network_v2.kubernetes_net.id
  cidr            = "192.168.0.0/24"
  dns_nameservers = ["8.8.8.8", "2.2.2.2"]
  ip_version      = 4

  allocation_pool {
    start = "192.168.0.10"
    end   = "192.168.0.250"
  }
}

resource "openstack_networking_router_v2" "kubernetes_router" {
  name                = "kubernetes_router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.public_network.id
}

resource "openstack_networking_router_interface_v2" "router_subnet_connect" {
  router_id = openstack_networking_router_v2.kubernetes_router.id
  subnet_id = openstack_networking_subnet_v2.kubernetes_subnet.id
}

module "master" {
  num      = var.number_master
  source   = "./modules/master"
  metadata = {}
  flavor   = var.flavor_master
  image    = data.openstack_images_image_v2.image.id
  net      = openstack_networking_network_v2.kubernetes_net.id
  #public_network = var.public_network
  ssh_keys = var.ssh_keys
}

module "worker" {
  num      = var.number_worker
  source   = "./modules/worker"
  metadata = {}
  flavor   = var.flavor_worker
  image    = data.openstack_images_image_v2.image.id
  net      = openstack_networking_network_v2.kubernetes_net.id
  #public_network = var.public_network
  ssh_keys = var.ssh_keys
}

locals {
  master_config_yaml = yamlencode(
    [for entry in module.master.host_entries :
      {
        ssh : entry
        role : "master"
      }
  ])
  worker_config_yaml = yamlencode(
    [for entry in module.worker.host_entries :
      {
        ssh : entry
        role : "worker"
      }
  ])
}

#locals {
#  master_config_yaml = replace(yamlencode(
#    [for entry in module.master.host_entries :
#      {
#        ssh : entry
#        role : "master"
#      }
#    ]),
#  "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
#}

#locals {
#  master_config_yaml = replace(yamlencode(
#    [
#      for entry in module.master.host_entries :
#      {
#        ssh : entry
#        role : "master"
#      }
#    ]),
#  "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
#}


#output "test2" {
#  value = local.master_config_yaml
#}

#output "test3" {
#  value = replace(yamlencode({
#    apiVersion : "k0sctl.k0sproject.io / v1beta1"
#    kind : "Cluster"
#    metadata : {
#      name : "k0s-cluster"
#    }
#    spec : {
#      hosts : local.master_config_yaml
#    }
#    k0s : {
#      version : "1.26.3+k0s.0"
#      dynamicConfig : false
#    }
#    })
#  , "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
#}

#test = yamlencode(module.master.*.master_ip)


#resource "local_file" "k0sctlconfig" {
#  content = replace(yamlencode({
#    apiVersion : "k0sctl.k0sproject.io/v1beta1"
#    kind : "Cluster"
#    metadata : {
#      name : "k0s-cluster"
#    }
#    spec : {
#      hosts : local.master_config_yaml
#    }
#    k0s : {
#      version : "1.26.3+k0s.0"
#      dynamicConfig : false
#    }
#    })
#  , "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
#  filename = "k0sctl.yaml"
#}
resource "local_file" "k0sctlconfig" {
  content = replace(yamlencode({
    apiVersion : "k0sctl.k0sproject.io/v1beta1"
    kind : "Cluster"
    metadata : {
      name : "k0s-cluster"
    }
    spec : {
      hosts : flatten([local.master_config_yaml, local.worker_config_yaml])
    }
    k0s : {
      version : "1.26.3+k0s.0"
      dynamicConfig : false
    }
    })
  , "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
  filename = "k0sctl.yaml"
}