{ pkgs, ... }:

let
  # Test VLAN bridge configuration
  vlanBridgeConfig = {
    vlan_id = 100;
    bridge_name = "br100";
    interfaces = [ "eth0" "eth1" ];
  };
in
{
  vlanBridgeConfig = vlanBridgeConfig;
  isValid = vlanBridgeConfig.vlan_id != null && vlanBridgeConfig.bridge_name != null;
}