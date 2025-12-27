{ pkgs, ... }:

let
  # Test VLAN ports configuration
  vlanPortsConfig = {
    vlan_id = 100;
    ports = [ "eth0" "eth1" ];
    tagged = [ "eth0" ];
    untagged = [ "eth1" ];
  };
in
{
  vlanPortsConfig = vlanPortsConfig;
  isValid = vlanPortsConfig.vlan_id != null && vlanPortsConfig.ports != null;
}