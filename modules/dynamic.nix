{ config, lib, pkgs, ... }:

{
  options.network-fabric.dynamic = {
    enable = lib.mkDefault false;
    
    # Dynamic configuration options
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos-fabric";
      description = "Base configuration directory for fabric";
    };
    
    ansibleDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.network-fabric.dynamic.configDir}/ansible";
      description = "Ansible configuration directory";
    };
    
    # Generated configuration
    generated = lib.mkOption {
      type = lib.types.attrs;
      default = {
        CONFIG_DIR = "${config.network-fabric.dynamic.configDir}";
        ANSIBLE_DIR = "${config.network-fabric.dynamic.ansibleDir}";
        PLAYBOOKS_DIR = "${config.network-fabric.dynamic.ansibleDir}/playbooks";
        ROLES_DIR = "${config.network-fabric.dynamic.ansibleDir}/roles";
      };
      description = "Generated configuration paths";
    };
  };
  
  config = lib.mkForce {
    # Generate dynamic configuration file using default values
    system.activationScripts.dynamicConfig = lib.mkBefore ''
      mkdir -p /etc/nixos-fabric
      cat > /etc/nixos-fabric/dynamic.env <<EOF
        export NIXOS_FABRIC_CONFIG_DIR="/etc/nixos-fabric"
        export NIXOS_FABRIC_ANSIBLE_DIR="$NIXOS_FABRIC_CONFIG_DIR/ansible"
        export NIXOS_FABRIC_PLAYBOOKS_DIR="$NIXOS_FABRIC_ANSIBLE_DIR/playbooks"
        export NIXOS_FABRIC_ROLES_DIR="$NIXOS_FABRIC_ANSIBLE_DIR/roles"
      EOF
      
      # Source the environment variables
      echo "source /etc/nixos-fabric/dynamic.env" >> /etc/profile.d/nixos-fabric-dynamic.sh
    '';
    
    # Make generated configuration available
    environment.sessionVariables = {
      NIXOS_FABRIC_CONFIG_DIR = "/etc/nixos-fabric";
      NIXOS_FABRIC_ANSIBLE_DIR = "/etc/nixos-fabric/ansible";
    };
  };
}