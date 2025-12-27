{ pkgs, ... }:

let
  testWireGuard = import ./wireguard-test.nix;
  testBGP = import ./bgp-test.nix;
  testVLAN = import ./vlan-test.nix;
  testSecurity = import ./security-test.nix;
  testMonitoring = import ./monitoring-test.nix;
  
in {
  wireguard = testWireGuard;
  bgp = testBGP;
  vlan = testVLAN;
  security = testSecurity;
  monitoring = testMonitoring;
}
