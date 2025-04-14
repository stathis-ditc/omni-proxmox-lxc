#!/bin/bash

set -e

gpg --batch --passphrase '' --quick-generate-key "Omni (Used for etcd data encryption) <how-to-guide@siderolabs.com>" rsa4096 cert never

FINGERPRINT=$(gpg --list-secret-keys --with-colons "how-to-guide@siderolabs.com" | awk -F: '/^fpr:/ { print $10 }' | head -n1)

gpg --batch --passphrase '' --quick-add-key "$FINGERPRINT" rsa4096 encr never

gpg --export-secret-key --armor "how-to-guide@siderolabs.com" > /root/omni.asc