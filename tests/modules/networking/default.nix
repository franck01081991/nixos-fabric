{ lib, config, utils, ... }:

let
  # Import test utilities
  inherit (utils) assertHasAttr assertEqual assertNotNull;

  # Networking configuration
  networkingConfig = config.networking or {};

in {
  # Test that networking configuration exists
  exists = assertNotNull networkingConfig "Networking configuration should exist";

  # Test that hostName is defined
  hasHostName = assertHasAttr networkingConfig "hostName" "Networking should have hostName";

  # Test that interfaces are defined
  hasInterfaces = assertHasAttr networkingConfig "interfaces" "Networking should have interfaces";

  # Test that default gateway is defined (if not DHCP)
  hasDefaultGateway = if networkingConfig.useDHCP == false then
    assertHasAttr networkingConfig "defaultGateway" "Non-DHCP networking should have defaultGateway"
  else
    utils.makeTestResult true "DHCP networking doesn't require defaultGateway" {};

  # Test that DNS is configured
  hasNameServers = assertHasAttr networkingConfig "nameservers" "Networking should have nameservers";

  # Test specific interface configurations
  testInterface = interfaceName: 
    let
      iface = builtins.getAttr interfaceName networkingConfig.interfaces;
    in
    if iface != null then
      {
        hasIPv4 = assertHasAttr iface "ipv4" "Interface should have IPv4 configuration";
        hasIPv6 = assertHasAttr iface "ipv6" "Interface should have IPv6 configuration";
      }
    else
      utils.makeTestResult false "Interface not found" {};

  # Test loopback interface
  loopbackTest = testInterface "lo";

  # Test that we have at least one non-loopback interface
  hasNonLoopback = let
    interfaces = builtins.attrNames networkingConfig.interfaces;
    nonLoopback = builtins.filter (name: name != "lo") interfaces;
  in
  if nonLoopback != [] then
    utils.makeTestResult true "Has non-loopback interfaces" { interfaces = nonLoopback; }
  else
    utils.makeTestResult false "No non-loopback interfaces found" {};
}