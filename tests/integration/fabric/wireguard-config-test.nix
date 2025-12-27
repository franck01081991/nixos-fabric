{ pkgs, ... }:

let
  # Import the WireGuard module
  wireguardConfig = import ./ansible/templates/wireguard.nix.j2 {
    inventory_hostname = "rtr-sapinet";
    wg_port = 51820;
    wg_mtu = 1420;
    wg_ip_address = "10.255.0.1/24";
    wg_peers = [
      {
        public_key = "test_public_key";
        allowed_ips = [ "10.255.0.11/32" "10.254.0.11/32" ];
        endpoint = "45.90.162.251:51820";
        persistent_keepalive = 25;
      }
    ];
  };
in
{
  wireguardConfig = wireguardConfig;
  isValid = wireguardConfig.networking.wireguard.interfaces.wgtransport != null;
}