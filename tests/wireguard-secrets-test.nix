{ pkgs, ... }:

let
  # Import the WireGuard secrets template
  secretsConfig = builtins.readFile ./ansible/roles/wireguard/templates/wireguard-secrets.j2;
  # Replace variables with test values
  secretsConfigTest = builtins.replaceStrings [ "wg_public_key.stdout" "wireguard_endpoint" "wireguard_peers" ] [ "test_public_key" "test_endpoint" "[{\"name\": \"test_peer\", \"public_key\": \"test_peer_key\", \"endpoint\": \"test_peer_endpoint\"}]" ] secretsConfig;
in
{
  secretsConfig = secretsConfigTest;
  isValid = builtins.length secretsConfig > 0;
}