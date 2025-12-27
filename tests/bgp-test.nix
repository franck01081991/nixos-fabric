{ pkgs, ... }:

let
  testBGPSession = import ./bgp-session-test.nix;
  testBGPRoutes = import ./bgp-routes-test.nix;
  testBGPEVPN = import ./bgp-evpn-test.nix;
  
in {
  session = testBGPSession;
  routes = testBGPRoutes;
  evpn = testBGPEVPN;
}
