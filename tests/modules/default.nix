{ pkgs, testUtils, ... }:

# Fabric Module Tests

let
  # Test the network-fabric module
  testFabricModule = testUtils.runTest "fabric-module-validation" ((): 
    let
      testConfig = {
        network-fabric = {
          enable = true;
          name = "test-fabric";
          environment = "testing";
          configDir = "/etc/nixos-fabric";
          ansibleDir = "/etc/nixos-fabric/ansible";
          roles = {
            spine = {
              enable = true;
              roleId = "spine1";
              description = "Test spine";
              priority = 100;
            };
            leaf = {
              enable = false;
              roleId = "leaf1";
              description = "Test leaf";
              priority = 50;
            };
          };
          network = {
            domain = "test.local";
            dnsServers = [ "8.8.8.8" ];
            ipv4 = {
              prefix = "10.0.0.0/16";
              gateway = "10.0.0.1";
            };
            ipv6 = {
              prefix = "fd00::/64";
              gateway = "fd00::1";
            };
          };
          security = {
            sshPort = 22;
            fail2banEnable = true;
            firewallEnable = true;
          };
        };
      };
      
      result = testUtils.testFabricConfig testConfig;
    in 
    if result.overallSuccess then
      testUtils.makeTestResult {
        success = true;
        message = "Fabric module configuration is valid";
        details = "All required fields are present and have correct types";
      }
    else
      testUtils.makeTestResult {
        success = false;
        message = "Fabric module configuration is invalid";
        details = "Some fields are missing or have incorrect types";
      }
  );
  
  # Test network configuration
  testNetworkConfig = testUtils.runTest "network-configuration" ((): 
    let
      networkConfig = {
        domain = "fabric.local";
        dnsServers = [ "1.1.1.1" "8.8.8.8" ];
        ipv4 = {
          prefix = "10.254.0.0/16";
          gateway = "10.254.0.1";
        };
        ipv6 = {
          prefix = "fd42:1337:254::/64";
          gateway = "fd42:1337:254::1";
        };
      };
      
      # Validate IP addresses
      ipv4Valid = builtins.match "^\d+\.\d+\.\d+\.\d+/\d+$" networkConfig.ipv4.prefix != null;
      ipv6Valid = builtins.match "^[a-fA-F0-9:]+::[a-fA-F0-9:]+/\d+$" networkConfig.ipv6.prefix != null;
      
      result = testUtils.assertTrue (ipv4Valid && ipv6Valid);
    in 
    result
  );
  
  # Test role configuration
  testRoleConfig = testUtils.runTest "role-configuration" ((): 
    let
      roleConfig = {
        enable = true;
        roleId = "test-role";
        description = "Test role";
        priority = 100;
      };
      
      result = testUtils.testRoleConfig roleConfig;
    in 
    if result.overallSuccess then
      testUtils.makeTestResult {
        success = true;
        message = "Role configuration is valid";
        details = "All role fields are present and have correct types";
      }
    else
      testUtils.makeTestResult {
        success = false;
        message = "Role configuration is invalid";
        details = "Some role fields are missing or have incorrect types";
      }
  );
  
  # Test security configuration
  testSecurityConfig = testUtils.runTest "security-configuration" ((): 
    let
      securityConfig = {
        sshPort = 22;
        fail2banEnable = true;
        firewallEnable = true;
      };
      
      # Validate SSH port
      sshPortValid = securityConfig.sshPort > 0 && securityConfig.sshPort < 65536;
      
      result = testUtils.assertTrue sshPortValid;
    in 
    if result.success then
      testUtils.makeTestResult {
        success = true;
        message = "Security configuration is valid";
        details = "SSH port is within valid range";
      }
    else
      result
  );

in {
  name = "fabric-modules";
  tests = [
    testFabricModule
    testNetworkConfig
    testRoleConfig
    testSecurityConfig
  ];
}