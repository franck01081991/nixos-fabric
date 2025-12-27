{ pkgs, ... }:

let
  # Test BGP session configuration
  bgpSessionConfig = {
    bgp_as = 65001;
    bgp_router_id = "10.254.0.1";
    bgp_neighbors = [
      {
        ip = "10.254.0.11";
        as = 65001;
        ebgp_multihop = 5;
      }
    ];
    bgp_networks = [ "10.254.0.1/32" ];
    bgp_evpn_enabled = false;
  };
in
{
  bgpSessionConfig = bgpSessionConfig;
  isValid = bgpSessionConfig.bgp_as != null && bgpSessionConfig.bgp_router_id != null;
}