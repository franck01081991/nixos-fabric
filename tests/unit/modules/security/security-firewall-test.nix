{ pkgs, ... }:

let
  # Test firewall configuration
  firewallConfig = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ 53 123 ];
    allowedICMPTypes = [ "echo-request" "echo-reply" ];
  };
in
{
  firewallConfig = firewallConfig;
  isValid = firewallConfig.enable != null && firewallConfig.allowedTCPPorts != null;
}