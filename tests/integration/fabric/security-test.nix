{ pkgs, ... }:

let
  testSSH = import ./security-ssh-test.nix;
  testFirewall = import ./security-firewall-test.nix;
  testHardening = import ./security-hardening-test.nix;
  
in {
  ssh = testSSH;
  firewall = testFirewall;
  hardening = testHardening;
}
