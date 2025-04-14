#!/bin/bash

## TODO: Pass VM_ID env var through the IaC and don't hardcode here
VM_ID=100
echo "Updating LXC config to /etc/pve/lxc/${VM_ID}.conf..."

cat <<'EOF' >> /etc/pve/lxc/${VM_ID}.conf
lxc.apparmor.profile: unconfined
lxc.cap.drop:
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.auto: proc:rw sys:rw
lxc.mount.entry: /dev/net dev/net none bind,create=dir
EOF

pct reboot ${VM_ID}