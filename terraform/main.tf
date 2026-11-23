terraform {
  required_version = ">= 1.6"

  required_providers {
    lima = {
      source  = "registry.terraform.io/guidoiaquinti/lima"
      version = "~> 0.1.2"
    }
  }
}

provider "lima" {}

variable "vms" {
  type = map(object({
    cpus   = number
    memory = string
    start  = optional(bool, true)
    portForwards = optional(list(object({
      guestPort = number
      hostPort  = number
      hostIP    = optional(string)
      protocol  = optional(string)
    })), [])
  }))
  default = {
    k3s-vm = {
      cpus   = 4
      memory = "6GiB"
      portForwards = [
        { guestPort = 6443, hostPort = 6443 },
        { guestPort = 80, hostPort = 50080 },
        { guestPort = 443, hostPort = 50443 },
      ]
    }
  }
}

resource "lima_instance" "vm" {
  for_each = var.vms

  name     = each.key
  template = "template:ubuntu-24.04"
  cpus     = each.value.cpus
  memory   = each.value.memory
  start    = each.value.start

  # Port forwards are set here rather than via the provider's port_forwards attribute because
  # plain mode only honours static forwards and the attribute has no way to set `static`.
  config_overrides = yamlencode(merge(
    {
      mounts   = null
      plain    = true
    },
    length(each.value.portForwards) == 0 ? {} : {
      portForwards = [
        for pf in each.value.portForwards : { for k, v in {
          guestPort = pf.guestPort
          hostPort  = pf.hostPort
          hostIP    = pf.hostIP
          proto     = pf.protocol
          static    = true
        } : k => v if v != null }
      ]
    }
  ))

}

output "ssh_config" {
  description = "Per-VM SSH config files, for use with ssh -F or ansible_ssh_common_args"
  value       = { for name, vm in lima_instance.vm : name => vm.ssh_config }
}
