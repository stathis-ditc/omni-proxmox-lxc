variable "omni_config" {
  type = object({
    version         = string
    target_platform = string
    arch            = string
    name            = string
    api_url         = string
    auth0_domain    = string
    auth0_client_id = string
    initial_users   = string
  })
  description = "Configuration for Omni instance"
}

variable "proxmox_ip" {
}

variable "proxmox_api_token" {
}

variable "ipv4_cidr" {
}

variable "ipv4_gateway" {
}

variable "disk_config" {
  type = object({
    datastore_id = string
    size         = number
  })
}