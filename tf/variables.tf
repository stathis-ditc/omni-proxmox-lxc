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
  type        = string
  description = "The IP of the proxmox node where LXC is hosted"
}

variable "proxmox_api_token" {
  type        = string
  description = "The generated api token to access Proxmox "
}

variable "ipv4_cidr" {
  type        = string
  description = "The IPv4 of the container. Must be in CIDR format i.e. ip/subnet"
}

variable "ipv4_gateway" {
  type        = string
  description = "The IP of the gateway"
}

variable "disk_config" {
  type = object({
    datastore_id = string
    size         = number
  })
}