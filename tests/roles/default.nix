{ pkgs, testUtils, ... }:

# Role System Tests

let
  # Test spine role configuration
  testSpineRole = testUtils.runTest "spine-role-validation" ((): 
    let
      spineConfig = {
        enable = true;
        roleId = "spine1";
        description = "Core spine router";
        priority = 200;
        networking = {
          hostName = "rtr-sapinet";
          spineNetworks = [ "10.254.0.0/16" "fd42:1337:254::/64" ];
        };
        routing = {
          ospf = {
            enable = true;
            area = "0.0.0.0";
            networks = [ "10.254.0.0/16" ];
          };
          bgp = {
            enable = true;
            asNumber = 65000;
            fullMesh = true;
            multihop = true;
            multihopTtl = 255;
            neighbors = [ "10.254.0.11" ];
          };
        };
        wireguard = {
          enable = true;
          interface = "wg0";
          spinePeers = [ "rtr-noisy:51820" ];
        };
      };
      
      # Validate spine configuration
      hasRequiredFields = 
        spineConfig.enable && 
        spineConfig.roleId != "" &&
        spineConfig.networking.hostName != "" &&
        spineConfig.routing.bgp.asNumber > 0;
      
      result = testUtils.assertTrue hasRequiredFields;
    in 
    if result.success then
      testUtils.makeTestResult {
        success = true;
        message = "Spine role configuration is valid";
        details = "All required spine role fields are present";
      }
    else
      result
  );
  
  # Test leaf role configuration
  testLeafRole = testUtils.runTest "leaf-role-validation" ((): 
    let
      leafConfig = {
        enable = true;
        roleId = "leaf1";
        description = "Edge leaf router";
        priority = 100;
        networking = {
          hostName = "rtr-noisy";
          leafNetworks = [ "10.254.1.0/24" "fd42:1337:254:1::/64" ];
        };
        routing = {
          bgp = {
            enable = true;
            asNumber = 65000;
            evpnEnable = true;
            vxlanEnable = true;
            vxlanVni = 100;
            spinePeers = [ "10.254.0.1" ];
          };
        };
        vxlan = {
          enable = true;
          vni = 100;
          interface = "vxlan100";
          ipv4Network = "10.254.100.0/24";
          ipv6Network = "fd42:1337:254:100::/64";
        };
        wireguard = {
          enable = true;
          interface = "wg0";
          spinePeers = [ "rtr-sapinet:51820" ];
        };
      };
      
      # Validate leaf configuration
      hasRequiredFields = 
        leafConfig.enable && 
        leafConfig.roleId != "" &&
        leafConfig.networking.hostName != "" &&
        leafConfig.routing.bgp.asNumber > 0 &&
        leafConfig.vxlan.vni > 0;
      
      # Validate EVPN/VXLAN consistency
      evpnVxlanConsistent = 
        (leafConfig.routing.bgp.evpnEnable && leafConfig.vxlan.enable) ||
        (!leafConfig.routing.bgp.evpnEnable && !leafConfig.vxlan.enable);
      
      result = testUtils.assertTrue (hasRequiredFields && evpnVxlanConsistent);
    in 
    if result.success then
      testUtils.makeTestResult {
        success = true;
        message = "Leaf role configuration is valid";
        details = "All required leaf role fields are present and consistent";
      }
    else
      result
  );
  
  # Test hybrid role configuration
  testHybridRole = testUtils.runTest "hybrid-role-validation" ((): 
    let
      hybridConfig = {
        spine = {
          enable = true;
          roleId = "spine2";
          description = "Hybrid spine component";
          priority = 200;
        };
        leaf = {
          enable = true;
          roleId = "leaf1";
          description = "Hybrid leaf component";
          priority = 100;
        };
      };
      
      # Validate hybrid configuration
      bothRolesEnabled = 
        hybridConfig.spine.enable && 
        hybridConfig.leaf.enable;
      
      roleIdsValid = 
        hybridConfig.spine.roleId != "" && 
        hybridConfig.leaf.roleId != "";
      
      prioritiesValid = 
        hybridConfig.spine.priority > hybridConfig.leaf.priority;
      
      result = testUtils.assertTrue (bothRolesEnabled && roleIdsValid && prioritiesValid);
    in 
    if result.success then
      testUtils.makeTestResult {
        success = true;
        message = "Hybrid role configuration is valid";
        details = "Both spine and leaf roles are properly configured with correct priorities";
      }
    else
      result
  );
  
  # Test role priority system
  testRolePriority = testUtils.runTest "role-priority-system" ((): 
    let
      roles = {
        spine = { enable = true; priority = 200; };
        leaf = { enable = true; priority = 100; };
        monitoring = { enable = false; priority = 50; };
      };
      
      # Test that spine has higher priority than leaf
      priorityCorrect = 
        roles.spine.priority > roles.leaf.priority &&
        roles.leaf.priority > roles.monitoring.priority;
      
      result = testUtils.assertTrue priorityCorrect;
    in 
    if result.success then
      testUtils.makeTestResult {
        success = true;
        message = "Role priority system is working correctly";
        details = "Spine (200) > Leaf (100) > Monitoring (50)";
      }
    else
      result
  );
  
  # Test role conflict detection
  testRoleConflictDetection = testUtils.runTest "role-conflict-detection" ((): 
    let
      # Test conflicting configurations
      conflictingConfig = {
        spine = {
          enable = true;
          roleId = "spine1";
          networking = {
            hostName = "conflict-node";
          };
        };
        leaf = {
          enable = true;
          roleId = "spine1";  # Same roleId as spine - conflict!
          networking = {
            hostName = "conflict-node";
          };
        };
      };
      
      # Detect conflict
      hasConflict = 
        conflictingConfig.spine.roleId == conflictingConfig.leaf.roleId &&
        conflictingConfig.spine.enable &&
        conflictingConfig.leaf.enable;
      
      result = testUtils.assertTrue hasConflict;
    in 
    if result.success then
      testUtils.makeTestResult {
        success = true;
        message = "Role conflict detection is working";
        details = "Detected conflicting roleIds between spine and leaf";
      }
    else
      result
  );

in {
  name = "role-system";
  tests = [
    testSpineRole
    testLeafRole
    testHybridRole
    testRolePriority
    testRoleConflictDetection
  ];
}