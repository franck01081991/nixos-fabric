{ pkgs, ... }:

let
  # Import the FRR module
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
  frrConfig = frrConfig;
  isValid = frrConfig.services.frr != null;
}