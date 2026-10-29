terraform {
  required_version = ">= 1.9"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.118.1" # look up the latest on registry.terraform.io/providers/bpg/proxmox
    }
  }
}