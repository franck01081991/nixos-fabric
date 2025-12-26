{ lib, config, utils, ... }:

let
  # Import test utilities
  inherit (utils) assertHasAttr assertEqual assertNotNull assertContains;

  # WireGuard configuration
  wireguardConfig = config.network-fabric.wireguard or {};

in {
  # Test that WireGuard configuration exists
  exists = assertNotNull wireguardConfig "WireGuard configuration should exist";

  # Test that enable flag is boolean
  enableIsBoolean = let
    enable = wireguardConfig.enable;
  in
  if enable == true || enable == false then
    utils.makeTestResult true "WireGuard enable is boolean" { enable = enable; }
  else
    utils.makeTestResult false "WireGuard enable should be boolean" { enable = enable; };

  # Test that listen port is defined when enabled
  hasListenPort = if wireguardConfig.enable == true then
    assertHasAttr wireguardConfig "listenPort" "Enabled WireGuard should have listenPort"
  else
    utils.makeTestResult true "Disabled WireGuard doesn't require listenPort" {};

  # Test that interfaces are defined when enabled
  hasInterfaces = if wireguardConfig.enable == true then
    assertHasAttr wireguardConfig "interfaces" "Enabled WireGuard should have interfaces"
  else
    utils.makeTestResult true "Disabled WireGuard doesn't require interfaces" {};

  # Test specific interface if exists
  testInterface = interfaceName: 
    let
      iface = builtins.getAttr interfaceName (wireguardConfig.interfaces or {});
    in
    if iface != null then
      {
        hasPrivateKey = assertHasAttr iface "privateKeyFile" "WireGuard interface should have privateKeyFile";
        hasPeers = assertHasAttr iface "peers" "WireGuard interface should have peers";
        
        # Test peers if exist
        testPeers = let
          peers = iface.peers or [];
        in
        if peers != [] then
          builtins.mapAttrs (peerName: peerConfig:
            {
              hasPublicKey = assertHasAttr peerConfig "publicKey" "Peer should have publicKey";
              hasAllowedIPs = assertHasAttr peerConfig "allowedIPs" "Peer should have allowedIPs";
              hasEndpoint = assertHasAttr peerConfig "endpoint" "Peer should have endpoint";
            }
          ) peers
        else
          { noPeers = utils.makeTestResult true "No peers to test" {}; };
      }
    else
      utils.makeTestResult false "Interface not found" {};

  # Test wg0 interface (common name)
  wg0Test = if wireguardConfig.enable == true then
    testInterface "wg0"
  else
    { skipped = utils.makeTestResult true "WireGuard disabled, skipping wg0 test" {}; };

  # Test firewall integration
  firewallIntegration = if wireguardConfig.enable == true && wireguardConfig.firewall.enable == true then
    assertHasAttr wireguardConfig.firewall "listenPort" "Firewall-enabled WireGuard should specify listenPort"
  else
    utils.makeTestResult true "Firewall integration not required" {};
}