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
    # Generate dynamic configuration file with custom config support
    system.activationScripts.dynamicConfig = lib.mkBefore ''
      # Create config directory
      mkdir -p /etc/nixos-fabric
      
      # Check for custom configuration
      if [ -f /etc/nixos-fabric/custom-config.env ]; then
        echo "Using custom configuration from /etc/nixos-fabric/custom-config.env"
        source /etc/nixos-fabric/custom-config.env
      else
        echo "Using default configuration"
        export NIXOS_FABRIC_CONFIG_DIR="/etc/nixos-fabric"
        export NIXOS_FABRIC_ANSIBLE_DIR="$NIXOS_FABRIC_CONFIG_DIR/ansible"
      fi
      
      # Always generate the dynamic config file
      cat > /etc/nixos-fabric/dynamic.env <<EOF
        export NIXOS_FABRIC_CONFIG_DIR="/etc/nixos-fabric"
        export NIXOS_FABRIC_ANSIBLE_DIR="\$NIXOS_FABRIC_CONFIG_DIR/ansible"
        export NIXOS_FABRIC_PLAYBOOKS_DIR="\$NIXOS_FABRIC_ANSIBLE_DIR/playbooks"
        export NIXOS_FABRIC_ROLES_DIR="\$NIXOS_FABRIC_ANSIBLE_DIR/roles"
        export NIXOS_FABRIC_LOGS_DIR="\$NIXOS_FABRIC_CONFIG_DIR/logs"
        export NIXOS_FABRIC_BACKUP_DIR="\$NIXOS_FABRIC_CONFIG_DIR/backups"
      EOF
      
      # Create additional directories
      mkdir -p "$NIXOS_FABRIC_PLAYBOOKS_DIR" "$NIXOS_FABRIC_ROLES_DIR" "$NIXOS_FABRIC_LOGS_DIR" "$NIXOS_FABRIC_BACKUP_DIR"
      
      # Source the environment variables
      echo "source /etc/nixos-fabric/dynamic.env" >> /etc/profile.d/nixos-fabric-dynamic.sh
      
      # Create a symlink for easy access
      ln -sf "$NIXOS_FABRIC_CONFIG_DIR" /var/lib/nixos-fabric
    '';
    
    # Make generated configuration available as session variables
    environment.sessionVariables = {
      NIXOS_FABRIC_CONFIG_DIR = "/etc/nixos-fabric";
      NIXOS_FABRIC_ANSIBLE_DIR = "/etc/nixos-fabric/ansible";
    };
    
    # Create systemd service for dynamic config management
    systemd.services.nixos-fabric-dynamic = {
      description = "NixOS Fabric Dynamic Configuration Manager";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'source /etc/profile.d/nixos-fabric-dynamic.sh && echo Dynamic config loaded'";
      };
    };
  };
}