{ pkgs, ... }:

let
  testWireGuardInterface = import ./wireguard-interface-test.nix;
  testWireGuardPeers = import ./wireguard-peers-test.nix;
  testWireGuardMTU = import ./wireguard-mtu-test.nix;
  
in {
  interface = testWireGuardInterface;
  peers = testWireGuardPeers;
  mtu = testWireGuardMTU;
}
