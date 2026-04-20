provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token =  var.proxmox_credentials
  insecure  = true
}