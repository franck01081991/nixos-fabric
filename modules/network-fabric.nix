{ lib, config, pkgs, ... }:

# Central module for NixOS Fabric configuration
# This module provides a unified interface for all fabric-related settings

let
  inherit (lib) mkOption mkDefault mkEnableOption mkIf mkForce;
  inherit (lib.types) submodule str bool listOf attrs attrsOf;

  # Import utility functions
  utils = import ./lib/utils.nix { inherit lib; };

  # Default fabric configuration
  defaultFabricConfig = {
    enable = false;
    
    # Fabric identity
    name = "nixos-fabric";
    environment = "production";
    
    # Directories
    configDir = "/etc/nixos-fabric";
    ansibleDir = "${config.network-fabric.configDir}/ansible";
    
    # Roles configuration
    roles = {
      spine = {
        enable = false;
        roleId = "spine1";
        description = "Core routing role";
      };
      leaf = {
        enable = false;
        roleId = "leaf1";
        description = "Edge routing role";
      };
    };
    
    # Network settings
    network = {
      domain = "fabric.local";
      dnsServers = [ "1.1.1.1" "8.8.8.8" ];
      
      # IP addressing
      ipv4 = {
        prefix = "10.254.0.0/16";
        gateway = "10.254.0.1";
      };
      
      ipv6 = {
        prefix = "fd42:1337:254::/64";
        gateway = "fd42:1337:254::1";
      };
    };
    
    # Security settings
    security = {
      sshPort = 22;
      fail2banEnable = true;
      firewallEnable = true;
    };
  };

in {
  options.network-fabric = {
    enable = mkEnableOption "Enable NixOS Fabric configuration";
    
    # Fabric identity
    name = mkOption {
      type = str;
      default = defaultFabricConfig.name;
      description = "Name of the fabric";
    };
    
    environment = mkOption {
      type = str;
      default = defaultFabricConfig.environment;
      description = "Deployment environment (production, staging, development)";
    };
    
    # Network settings
    network = mkOption {
      type = submodule {
        options = {
          domain = lib.mkDefault defaultFabricConfig.network.domain;
          dnsServers = lib.mkDefault defaultFabricConfig.network.dnsServers;
          
          ipv4 = mkOption {
            type = submodule {
              options = {
                prefix = lib.mkDefault defaultFabricConfig.network.ipv4.prefix;
                gateway = lib.mkDefault defaultFabricConfig.network.ipv4.gateway;
              };
            };
          };
          
          ipv6 = mkOption {
            type = submodule {
              options = {
                prefix = lib.mkDefault defaultFabricConfig.network.ipv6.prefix;
                gateway = lib.mkDefault defaultFabricConfig.network.ipv6.gateway;
              };
            };
          };
        };
      };
      default = defaultFabricConfig.network;
      description = "Network configuration";
    };
    
    # Security settings - integrated network security
    security = mkOption {
      type = submodule {
        options = {
          enable = mkDefault true;
          ssh = mkOption {
            type = submodule {
              options = {
                port = mkDefault defaultFabricConfig.security.sshPort;
                enable = mkDefault true;
                passwordAuthentication = mkDefault false;
                permitRootLogin = mkDefault "prohibit-password";
                allowUsers = mkDefault [ "franck" "nixos" ];
                allowGroups = mkDefault [ "wheel" ];
                maxAuthTries = mkDefault 3;
                loginGraceTime = mkDefault 30;
                banner = mkDefault "/etc/issue";
              };
            };
          };
          firewallEnable = mkDefault true;
          fail2banEnable = mkDefault true;
        };
      };
      default = defaultFabricConfig.security;
      description = "Integrated network security configuration";
    };
  };
  
  config = mkIf config.network-fabric.enable {
    # Create fabric configuration directory
    system.activationScripts.fabricConfig = lib.mkBefore ''
      mkdir -p ${config.network-fabric.configDir}
      mkdir -p ${config.network-fabric.ansibleDir}
      
      # Create environment configuration
      cat > ${config.network-fabric.configDir}/environment <<EOF
# NixOS Fabric Environment Configuration
FABRIC_NAME="${config.network-fabric.name}"
FABRIC_ENVIRONMENT="${config.network-fabric.environment}"
FABRIC_CONFIG_DIR="${config.network-fabric.configDir}"
FABRIC_ANSIBLE_DIR="${config.network-fabric.ansibleDir}"
EOF
      
      # Create network configuration
      cat > ${config.network-fabric.configDir}/network <<EOF
# NixOS Fabric Network Configuration
FABRIC_DOMAIN="${config.network-fabric.network.domain}"
FABRIC_DNS_SERVERS="${lib.concatStringsSep " " config.network-fabric.network.dnsServers}"
FABRIC_IPV4_PREFIX="${config.network-fabric.network.ipv4.prefix}"
FABRIC_IPV4_GATEWAY="${config.network-fabric.network.ipv4.gateway}"
FABRIC_IPV6_PREFIX="${config.network-fabric.network.ipv6.prefix}"
FABRIC_IPV6_GATEWAY="${config.network-fabric.network.ipv6.gateway}"
EOF
      
      # Create roles configuration
      cat > ${config.network-fabric.configDir}/roles <<EOF
# NixOS Fabric Roles Configuration
${lib.concatStringsSep "\n" (lib.mapAttrsToList (roleName: roleConfig: 
  "FABRIC_ROLE_${lib.stringToUpper roleName}_ENABLE=${lib.toString roleConfig.enable}"
) config.network-fabric.roles)}
EOF
    '';
    
    # Set environment variables
    environment.sessionVariables = {
      NIXOS_FABRIC_NAME = config.network-fabric.name;
      NIXOS_FABRIC_ENVIRONMENT = config.network-fabric.environment;
    };
    
    # Import network security module
    imports = [
      ./network-security.nix
    ];
    
    # Create systemd service for fabric management
    systemd.services.nixos-fabric = {
      description = "NixOS Fabric Management Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'source ${config.network-fabric.configDir}/environment && echo Fabric ${config.network-fabric.name} initialized';";
      };
    };
  };
}