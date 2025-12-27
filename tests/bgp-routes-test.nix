{ pkgs, ... }:

let
  # Test BGP routes configuration
  bgpRoutesConfig = {
    bgp_networks = [ "10.254.0.1/32" "10.255.0.0/24" ];
    bgp_neighbors = [
      {
        ip = "10.254.0.11";
        as = 65001;
        ebgp_multihop = 5;
      }
    ];
  };
in
{
  bgpRoutesConfig = bgpRoutesConfig;
  isValid = bgpRoutesConfig.bgp_networks != null && bgpRoutesConfig.bgp_neighbors != null;
}