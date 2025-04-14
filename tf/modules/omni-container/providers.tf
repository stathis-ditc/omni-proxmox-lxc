terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.75.0"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://${var.proxmox_ip}:8006"
  api_token = var.proxmox_api_token
  username  = "root"
  insecure  = true
  ssh {
    agent    = true
    username = "root"
  }
}