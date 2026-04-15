resource "proxmox_virtual_environment_vm" "control_plane" {
  name      = "k8s-cp-01"
  node_name = var.proxmox_node
  vm_id     = 200
  on_boot   = true

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu { cores = 2 }
  memory { dedicated = 2048 }

  agent { enabled = true }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = 20
    discard      = "on"
  }

  initialization {
    datastore_id = var.datastore_id
    ip_config {
      ipv4 { address = "dhcp" }
    }
    user_account {
      username = "debian"
      keys     = [var.ssh_public_key]
    }
  }
}

resource "proxmox_virtual_environment_vm" "workers" {
  count     = 2
  name      = "k8s-worker-0${count.index + 1}"
  node_name = var.proxmox_node
  vm_id     = 201 + count.index
  on_boot   = true

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu { cores = 1 }
  memory { dedicated = 1024 }

  agent { enabled = true }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = 20
    discard      = "on"
  }

  initialization {
    ip_config {
      ipv4 { address = "dhcp" }
    }
    user_account {
      username = "debian"
      keys     = [var.ssh_public_key]
    }
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    control_plane_ip = proxmox_virtual_environment_vm.control_plane.ipv4_addresses[1][0]
    worker_ips       = [for vm in proxmox_virtual_environment_vm.workers : vm.ipv4_addresses[1][0]]
  })
  filename = "${path.module}/../ansible/inventory.yml"
}
