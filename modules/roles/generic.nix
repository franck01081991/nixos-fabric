{ lib, config, pkgs, ... }:

# Generic role module that provides common functionality for all roles

let
  inherit (lib) mkOption mkDefault mkEnableOption mkIf mkForce;
  inherit (lib.types) submodule str bool attrs;

  # Common role options
  commonRoleOptions = {
    enable = mkEnableOption "Enable this role";
    roleId = mkOption {
      type = str;
      default = "role1";
      description = "Role identifier";
    };
    description = mkOption {
      type = str;
      default = "Generic fabric role";
      description = "Role description";
    };
    priority = mkOption {
      type = mkDefault 100;
      description = "Role priority (higher = more important)";
    };
  };

  # Role validation function
  validateRole = roleConfig: 
    if roleConfig.enable && roleConfig.roleId == "" 
    then lib.mkForce "Role ID must be specified when role is enabled"
    else roleConfig;

  # Role activation script
  roleActivationScript = roleName: roleConfig: ''
    echo "Activating ${roleName} role (${roleConfig.roleId})"
    echo "Role description: ${roleConfig.description}"
    echo "Role priority: ${lib.toString roleConfig.priority}"
    
    # Create role marker file
    mkdir -p /etc/nixos-fabric/roles
    cat > /etc/nixos-fabric/roles/${roleName} <<EOF
ROLE_NAME="${roleName}"
ROLE_ID="${roleConfig.roleId}"
ROLE_DESCRIPTION="${roleConfig.description}"
ROLE_PRIORITY="${lib.toString roleConfig.priority}"
ROLE_ENABLED="true"
EOF
  '';

  # Role environment variables
  roleEnvironmentVars = roleName: roleConfig: {
    "NIXOS_FABRIC_ROLE_${lib.stringToUpper roleName}_ENABLED" = "true";
    "NIXOS_FABRIC_ROLE_${lib.stringToUpper roleName}_ID" = roleConfig.roleId;
    "NIXOS_FABRIC_ROLE_${lib.stringToUpper roleName}_DESCRIPTION" = roleConfig.description;
    "NIXOS_FABRIC_ROLE_${lib.stringToUpper roleName}_PRIORITY" = lib.toString roleConfig.priority;
  };

in {
  options = {
    network-fabric = {
      roles = lib.mkOption {
        type = attrsOf (submodule commonRoleOptions);
        default = { };
        description = "Fabric roles configuration";
      };
    };
  };
  
  config = lib.mkIf config.network-fabric.enable {
    # Process all roles
    environment.sessionVariables = lib.concatLists (
      lib.mapAttrsToList (roleName: roleConfig: 
        if roleConfig.enable 
        then [roleEnvironmentVars roleName roleConfig]
        else [ ]
      ) config.network-fabric.roles
    );
    
    # Create role activation scripts
    system.activationScripts.fabricRoles = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (roleName: roleConfig: 
        if roleConfig.enable 
        then roleActivationScript roleName roleConfig
        else ""
      ) config.network-fabric.roles
    );
    
    # Validate all roles
    lib.mkAssert (
      lib.all (roleConfig: 
        if roleConfig.enable 
        then roleConfig.roleId != "" 
        else true
      ) (lib.attrValues config.network-fabric.roles)
    ) "All enabled roles must have a roleId specified";
  };
}