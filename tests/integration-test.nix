{ pkgs, ... }:

let
  # Test integration between WireGuard and FRR
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
  
  frrConfig = import ./ansible/templates/frr.nix.j2 {
    inventory_hostname = "rtr-sapinet";
    bgp_as = 65001;
    bgp_router_id = "10.254.0.1";
    bgp_cluster_id = "10.254.0.11";
    bgp_neighbors = [
      {
        ip = "10.254.0.11";
        as = 65001;
        ebgp_multihop = 5;
      }
    ];
    bgp_networks = [ "10.254.0.1/32" ];
    bgp_evpn_enabled = false;
    ospf_router_id = "10.254.0.1";
    ospf_networks = [ "10.254.0.1/32" "10.255.0.0/24" ];
    ospf_area = 0;
    ospf_passive_interfaces = [ "wgtransport" ];
  };
in
{
  wireguardConfig = wireguardConfig;
  frrConfig = frrConfig;
  isValid = wireguardConfig.networking.wireguard.interfaces.wgtransport != null && frrConfig.services.frr != null;
}