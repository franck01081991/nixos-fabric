{ pkgs, ... }:

let
  # Import the WireGuard wg0.conf template
  wg0Config = builtins.readFile ./ansible/roles/wireguard/templates/wg0.conf.j2;
  # Replace variables with test values
  wg0ConfigTest = builtins.replaceStrings [ "wireguard_address" "wireguard_port" "wireguard_peers" ] [ "10.255.0.1/24" "51820" "[{\"public_key\": \"test_key\", \"allowed_ips\": [\"10.255.0.0/24\"]}]" ] wg0Config;
in
{
  wg0Config = wg0ConfigTest;
  isValid = builtins.length wg0Config > 0;
}