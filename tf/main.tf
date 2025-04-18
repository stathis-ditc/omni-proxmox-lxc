module "omni-container" {
  source                = "./modules/omni-container"
  omni_config           = var.omni_config
  ipv4_cidr             = var.ipv4_cidr
  ipv4_gateway          = var.ipv4_gateway
  proxmox_ip            = var.proxmox_ip
  proxmox_api_token     = var.proxmox_api_token
  disk_config           = var.disk_config
  proxmox_root_password = var.proxmox_root_password
}