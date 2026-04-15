output "vm_ids" {
  description = "IDs des VMs créées"
  value = {
    control_plane = proxmox_virtual_environment_vm.control_plane.vm_id
    workers       = proxmox_virtual_environment_vm.workers[*].vm_id
  }
}
