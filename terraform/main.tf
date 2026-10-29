# One cloud-init file per node, uploaded to Proxmox as a snippet
resource "proxmox_virtual_environment_file" "user_data" {
  for_each     = var.nodes
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    file_name = "${each.key}-user-data.yaml"
    data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
      hostname = each.key
      ssh_key  = trimspace(file(pathexpand(var.ssh_public_key_path)))
    })
  }
}

resource "proxmox_virtual_environment_vm" "node" {
  for_each  = var.nodes
  name      = each.key
  node_name = "pve"
  vm_id     = each.value.vmid

  clone {
    vm_id = var.template_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = each.value.disk
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id      = "local-lvm"
    user_data_file_id = proxmox_virtual_environment_file.user_data[each.key].id

    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.gateway]
    }
  }
}