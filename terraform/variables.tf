variable "proxmox_endpoint" {
  description = "Proxmox API URL, ex: https://192.168.1.12:8006"
  type        = string
  default     = "https://192.168.1.12:8006"
}

variable "proxmox_username" {
  description = "Utilisateur Proxmox, ex: root@pam"
  type        = string
}

variable "proxmox_password" {
  description = "Mot de passe de l'utilisateur Proxmox"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Clé SSH publique injectée dans les VMs via cloud-init"
  type        = string
}

variable "template_id" {
  description = "VM ID du template Debian 13 à cloner"
  type        = number
  default     = 8999
}

variable "proxmox_node" {
  description = "Nom du nœud Proxmox"
  type        = string
  default     = "pve"
}

variable "datastore_id" {
  description = "Storage Proxmox pour les VMs"
  type        = string
  default     = "local"
}

variable "network_bridge" {
  description = "Bridge réseau des VMs"
  type        = string
  default     = "vmbr0"
}
