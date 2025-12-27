{ pkgs, ... }:

let
  # Test BGP EVPN configuration
  bgpEvpnConfig = {
    bgp_evpn_enabled = true;
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
  bgpEvpnConfig = bgpEvpnConfig;
  isValid = bgpEvpnConfig.bgp_evpn_enabled != null && bgpEvpnConfig.bgp_neighbors != null;
}