{ config, lib, pkgs, ... }:

{
  network-fabric.ansible = {
    enable = true;
    
    # Host-specific variables
    hostVars = {
      "rtr-sapinet" = {
        wireguard_address = "10.255.0.1/24";
        wireguard_endpoint = "45.90.162.251";
        frr_ospf_router_id = "10.254.0.1";
        node_role = "spine";
      };
      
      "rtr-noisy" = {
        wireguard_address = "10.255.0.11/24";
        wireguard_endpoint = "RTR_NOISY_IP";
        frr_ospf_router_id = "10.254.0.11";
        node_role = "hybrid";
      };
    };
    
    # Group variables
    groupVars = {
      "spine" = {
        frr_bgp_as_number = 65000;
        fabric_networks = [
          "10.254.0.0/24"
          "10.255.0.0/24"
          "fd42:1337:254::/64"
        ];
      };
      
      "leaf" = {
        frr_bgp_as_number = 65000;
        fabric_networks = [
          "10.254.0.0/24"
          "10.255.0.0/24"
          "fd42:1337:254::/64"
        ];
      };
    };
  };
}