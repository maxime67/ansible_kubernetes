#######################################
#         PROVIDER INFORMATIONS       #
#                                     #
#######################################

variable "proxmox_endpoint" {
  description = "Proxmox API URL, ex: https://192.168.1.75:8006"
  type        = string
  default     = "https://192.168.1.75:8006"
}

variable "proxmox_credentials" {
  description = "Credentials Proxmox"
  type        = string
}

variable "ssh_public_key" {
  description = "Clé SSH publique injectée dans les VMs via cloud-init"
  type        = string
}

#######################################
#         PROXMOX INFORMATIONS        #
#                                     #
#######################################

variable "template_id" {
  description = "VM ID du template Debian 13 à cloner"
  type        = number
  default     = 9004
}

variable "proxmox_nodes" {
  description = "Liste des nœuds Proxmox (1 VM par nœud)"
  type        = list(string)
  default     = ["pve1", "pve2", "pve3"]
}

variable "template_node" {
  description = "Nœud Proxmox où le template_id est stocké"
  type        = string
  default     = "pve1"
}

variable "datastore_id" {
  description = "Storage Proxmox pour les VMs (doit supporter les images VM)"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Bridge réseau des VMs"
  type        = string
  default     = "vmbr0"
}

############################################
#         CONTROL PLAN INFORMATIONS        #
#                                          #
############################################

variable "control_plan_disk_size" {
  description = "Taille des disques des control plan"
  type        = number
  default     = 20
}

variable "control_plan_memory_size" {
  description = "Volume de RAM pour les control plan"
  type        = number
  default     = 7168
}

variable "control_plan__cpu_number" {
  description = "Nombre de coeur par VM pour les control plan"
  type        = number
  default     = 3
}

############################################
#           WORKER INFORMATIONS            #
#                                          #
############################################

variable "worker_memory_size" {
  description = "Volume de RAM pour les workers"
  type        = number
  default     = 6144
}

variable "worker_disk_size" {
  description = "Taille des disques des workers"
  type        = number
  default     = 20
}

variable "worker_cpu_number" {
  description = "Nombre de coeur par VM pour les worker"
  type        = number
  default     = 2
}
