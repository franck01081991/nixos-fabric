#!/usr/bin/env bash
set -euo pipefail

# WireGuard Deployment Script for NixOS Fabric
# Usage: ./scripts/deploy-wireguard.sh <host> <public_ip_or_domain>

HOST="$1"
PUBLIC_ENDPOINT="$2"
SECRETS_DIR="/etc/nixos/secrets"
WG_DIR="/etc/wireguard"

# Create directories
sudo mkdir -p "$SECRETS_DIR" "$WG_DIR"

# Generate private key
PRIV_KEY_FILE="$WG_DIR/$HOST.key"
if [ ! -f "$PRIV_KEY_FILE" ]; then
    echo "Generating WireGuard private key for $HOST..."
    wg genkey | sudo tee "$PRIV_KEY_FILE"
    sudo chmod 600 "$PRIV_KEY_FILE"
else
    echo "Using existing private key for $HOST"
fi

# Extract public key
PUB_KEY=$(sudo cat "$PRIV_KEY_FILE" | wg pubkey)
echo "Public key for $HOST: $PUB_KEY"

# Create secrets file
SECRETS_FILE="$SECRETS_DIR/wireguard.nix"
if [ ! -f "$SECRETS_FILE" ]; then
    echo "Creating secrets file..."
    sudo tee "$SECRETS_FILE" > /dev/null <<EOF
{ 
  # WireGuard configuration
  ${HOST}Pub = "$PUB_KEY";
  ${HOST}Endpoint = "$PUBLIC_ENDPOINT";
  
  # Add other peers as needed
  # noisyPub = "BASE64_PUBLIC_KEY";
  # noisyEndpoint = "IP_OR_DOMAIN";
}
EOF
    sudo chmod 600 "$SECRETS_FILE"
else
    echo "Updating secrets file..."
    # This is a simple approach - in production you might want to merge more carefully
    sudo tee "$SECRETS_FILE" > /dev/null <<EOF
{ 
  # WireGuard configuration
  ${HOST}Pub = "$PUB_KEY";
  ${HOST}Endpoint = "$PUBLIC_ENDPOINT";
  
  # Add other peers as needed
  # noisyPub = "BASE64_PUBLIC_KEY";
  # noisyEndpoint = "IP_OR_DOMAIN";
}
EOF
fi

echo "WireGuard setup complete for $HOST"
echo "Private key: $PRIV_KEY_FILE"
echo "Public key: $PUB_KEY"
echo "Secrets file: $SECRETS_FILE"
echo "Endpoint: $PUBLIC_ENDPOINT"
