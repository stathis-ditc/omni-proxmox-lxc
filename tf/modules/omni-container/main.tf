locals {
  certs_path             = "${path.module}/certs"
  cert_files             = fileset(local.certs_path, "*")
  generate_etcd_gpg_path = "${path.module}/scripts/generate-etcd-gpg.sh"
  update_pm_script_path  = "${path.module}/scripts/update_pm_container_config.sh"
  launch_omni_script     = "${path.module}/scripts/launch-omni.sh"
}
resource "proxmox_virtual_environment_container" "omni_container" {
  node_name = "proxmox"
  vm_id     = 100

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.ubuntu_24_10_lxc_img.id
    type             = "ubuntu"
  }

  initialization {
    hostname = "omni-container"
    ip_config {
      ipv4 {
        address = var.ipv4_cidr
        gateway = var.ipv4_gateway
      }
    }
    user_account {
      keys = [
        trimspace(tls_private_key.ubuntu_container_key.public_key_openssh)
      ]
      password = random_password.ubuntu_container_password.result
    }
  }

  disk {
    datastore_id = var.disk_config.datastore_id
    size         = var.disk_config.size
  }

  network_interface {
    name     = "eth0"
    bridge   = "vmbr0"
    enabled  = true
    firewall = true
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu_24_10_lxc_img" {
  content_type       = "vztmpl"
  datastore_id       = "local"
  node_name          = "proxmox"
  url                = "https://cloud-images.ubuntu.com/releases/oracular/release-20250305/ubuntu-24.10-server-cloudimg-amd64-root.tar.xz"
  checksum           = "eae36ea406a780d8bd228fa6337736a0a1e70a2a9c726ccbfde609541d06123f"
  checksum_algorithm = "sha256"
}

resource "null_resource" "create_cert_dir" {
  provisioner "remote-exec" {
    inline = ["mkdir -p /root/certs"]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.ubuntu_container_key.private_key_pem
      host        = split("/", proxmox_virtual_environment_container.omni_container.initialization[0].ip_config[0].ipv4[0].address)[0]
    }
  }

  depends_on = [proxmox_virtual_environment_container.omni_container]
}

resource "null_resource" "upload_certs" {
  for_each = { for file in local.cert_files : file => file }

  provisioner "file" {
    source      = "${local.certs_path}/${each.value}"
    destination = "/root/certs/${each.value}"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.ubuntu_container_key.private_key_pem
      host        = split("/", proxmox_virtual_environment_container.omni_container.initialization[0].ip_config[0].ipv4[0].address)[0]
    }
  }

  depends_on = [null_resource.create_cert_dir]
}

resource "null_resource" "etcd_encryption_key_generate" {
  triggers = {
    script = filesha256(local.generate_etcd_gpg_path)
  }

  provisioner "remote-exec" {
    script = local.generate_etcd_gpg_path

    connection {
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.ubuntu_container_key.private_key_pem
      host        = split("/", proxmox_virtual_environment_container.omni_container.initialization[0].ip_config[0].ipv4[0].address)[0]
    }
  }

  depends_on = [proxmox_virtual_environment_container.omni_container]
}

resource "null_resource" "update_proxmox_container_config" {
  triggers = {
    script = filesha256(local.update_pm_script_path)
  }

  provisioner "remote-exec" {
    script = local.update_pm_script_path

    connection {
      type = "ssh"
      user = "root"
      host = var.proxmox_ip
    }
  }

  depends_on = [proxmox_virtual_environment_container.omni_container]
}

resource "null_resource" "launch_omni" {
  triggers = {
    script = filesha256(local.launch_omni_script)
    omni_version = var.omni_config.version
  }

  provisioner "file" {
    source      = local.launch_omni_script
    destination = "/root/launch-omni.sh"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.ubuntu_container_key.private_key_pem
      host        = split("/", proxmox_virtual_environment_container.omni_container.initialization[0].ip_config[0].ipv4[0].address)[0]
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/launch-omni.sh",
      "export OMNI_VERSION=${self.triggers.omni_version}",
      "export OMNI_TARGET_PLATFORM=${var.omni_config.target_platform}",
      "export OMNI_ARCH=${var.omni_config.arch}",
      "export OMNI_NAME=${var.omni_config.name}",
      "export OMNI_API_URL=${var.omni_config.api_url}",
      "export OMNI_WG_ADDR=${split("/", proxmox_virtual_environment_container.omni_container.initialization[0].ip_config[0].ipv4[0].address)[0]}",
      "export OMNI_AUTH0_DOMAIN=${var.omni_config.auth0_domain}",
      "export OMNI_AUTH0_CLIENT_ID=${var.omni_config.auth0_client_id}",
      "export OMNI_INITIAL_USERS=${var.omni_config.initial_users}",
      "/root/launch-omni.sh"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.ubuntu_container_key.private_key_pem
      host        = split("/", proxmox_virtual_environment_container.omni_container.initialization[0].ip_config[0].ipv4[0].address)[0]
    }
  }

  depends_on = [proxmox_virtual_environment_container.omni_container]
}


resource "random_password" "ubuntu_container_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_container_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
