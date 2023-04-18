
terraform {
  required_version = ">= 0.14"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }

    ignition = {
      source  = "community-terraform-providers/ignition"
      version = "2.1.3"
    }
  }
}
