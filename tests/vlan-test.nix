{ pkgs, ... }:

let
  testVLANBridge = import ./vlan-bridge-test.nix;
  testVLANPorts = import ./vlan-ports-test.nix;
  testVLANRouting = import ./vlan-routing-test.nix;
  
in {
  bridge = testVLANBridge;
  ports = testVLANPorts;
  routing = testVLANRouting;
}
