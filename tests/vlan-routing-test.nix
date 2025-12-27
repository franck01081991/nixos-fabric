{ pkgs, ... }:

let
  # Test VLAN routing configuration
  vlanRoutingConfig = {
    vlan_id = 100;
    network = "192.168.100.0/24";
    gateway = "192.168.100.1";
  };
in
{
  vlanRoutingConfig = vlanRoutingConfig;
  isValid = vlanRoutingConfig.vlan_id != null && vlanRoutingConfig.network != null;
}