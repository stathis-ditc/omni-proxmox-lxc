# Sidero Labs Omni deployment on Proxmox LXC container with Terrafiorm/OpenTofu

This project automates the deployment of Sidero's Labs Omni on a Proxmox LXC container using Terraform/OpenTofu. It creates and configures an LXC container running Ubuntu 24.10, sets up necessary certificates, and deploys the Omni platform.

## Prerequisites
- Before you start, please watch [How to install Omni on-prem](https://www.youtube.com/watch?v=wd3lI3qf-3w) to get 
  the understabding on how Oni is installed on-prem
- Terraform (tested with version 1.5.0 or later) / OpenTofu (tested with version 1.6.0 or later)
- Proxmox server already installed with API access. Basic Proxmox knowledge is required
- SSH access to the Proxmox server (currently only insecure connection is supported)
- A valid domain name and valid certificates (see the video above on how to generate them if you haven't already)
- Auth0 app pre-configured (see the video above on how to generate them if you haven't already)

## Configuration

The project uses the following variables that can be configured in `tf/variables.tf`:

- `omni_config`: Configuration for the Omni instance including:
  - version
  - target platform
  - architecture
  - name
  - API URL
  - Auth0 configuration
  - Initial users
- `proxmox_ip`: IP address of the Proxmox server
- `proxmox_api_token`: Proxmox's generated API token with the necessary permissions to access the platform
- `ipv4_cidr`: IPv4 address and subnet for the container
- `ipv4_gateway`: Gateway IP address
- `disk_config`: Configure the LXC's volume datastore and 10

## Usage

1. Update the variables in `tf/variables.tf` according to your environment
2. Place your certificates in the `tf/modules/omni-container/certs` directory
3. Initialize Terraform or OpenTofu:
   ```bash
   cd tf
   terraform init
   ```
   ```bash
   cd tf
   tofu init
   ```
4. Apply the configuration:
   ```bash
   terraform apply
   ```
   ```bash
   tofu apply
   ```
5. To access OmniUI, set in your local hosts the IP of the container to resolve on your domain name used during the installation. For ex
```bash
# /etc/hosts
1.2.3.4 omni.example.com
```
6. Generated ssh keys and passwords can be found on the generated terraform.tfstate

## Features

- Creates an LXC container running Ubuntu 24.10
- Configures network settings with static IP
- Sets up SSH access with generated keys
- Deploys and configures the Omni platform
- Generates etcd encryption keys
- Configures Auth0 integration

## Security Considerations

- This project is designed for Proxmox and HomeLabs. Has not been considered for the moment for production systems
- It is tested in a isolated, secured network behind strict firewall rules.  
- For simplicity, The project generates passwords and SSH keys stored in plain text in terraform's state for simplicity
- In the future, API tokens and credentials will be properly secured

## Maintenance

To update the container configuration or redeploy:
1. Make necessary changes to the Terraform configuration
2. Run `terraform plan` to review changes
3. Apply changes with `terraform apply`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](https://github.com/stathis-ditc/omni-proxmox-lxc/blob/main/LICENSE)