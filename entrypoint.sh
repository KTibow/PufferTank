#!/bin/bash
set -e

# print CUDA version
echo "PufferTank 4.0 (CUDA $(nvcc --version | grep "release" | awk '{print $6}'))"

# check if NVIDIA driver is loaded
if ! nvidia-smi > /dev/null 2>&1; then
    echo "WARNING: The NVIDIA Driver was not detected. GPU functionality will not be available."
fi

# Add SSH public key from env vars.
# Set PUBLIC_KEY in Vast Entrypoint mode to your ~/.ssh/id_ed25519.pub or similar.
mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

for key_var in PUBLIC_KEY SSH_PUBLIC_KEY VAST_SSH_KEY; do
    key="${!key_var:-}"
    if [ -n "$key" ]; then
        echo "$key" >> /root/.ssh/authorized_keys
    fi
done

if [ ! -s /root/.ssh/authorized_keys ]; then
    echo "WARNING: No SSH public key found."
    echo "Set PUBLIC_KEY, SSH_PUBLIC_KEY, or VAST_SSH_KEY in the Vast environment variables."
fi

# Ensure SSH host keys exist
ssh-keygen -A

# Start SSH daemon
mkdir -p /run/sshd
/usr/sbin/sshd

# Optional live update
cd /puffer && git pull 2>/dev/null || true

# keep container running / run provided command
exec "$@"
