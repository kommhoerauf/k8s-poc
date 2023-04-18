# k8s-poc
Repository set up for kubecon2023 in Amsterdam, playground

Our goal is to bootstrap a (feature rich) functional highly available k0s cluster from scratch.

* https://github.com/k0sproject/k0sctl (very promising candidate as we do not have the hassel with tokens, all we need is a working ssh connection)
* https://docs.k0sproject.io (very similiar to k3s, new nodes can spawning via tokens, e.g. for bootstrapping)
* https://metallb.universe.tf/installation/clouds/#metallb-on-openstack
* https://docs.k0sproject.io/v1.23.6+k0s.2/examples/metallb-loadbalancer/

Contains terraform modules for setting up masters, workers
We choose ~~Flatcar~~ Ubuntu as operating system and will use ~~Ignition (the Flatcar version of cloudinit)~~ cloudinit to roll out necessary SSH Keys and install k0sctl directly and not rely on the native openstack integration.

~~https://registry.terraform.io/providers/community-terraform-providers/ignition/latest/docs~~

It would be perfect to generate the necessary k0sctl configuration directly via terraform in our case

We want to use metallb (to not generate a dependency to octavia-lbaas) for configuration of a loadbalancer in front of our control plan/master nodes.