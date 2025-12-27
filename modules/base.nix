{ config, lib, pkgs, ... }:

{
  options.network-fabric.base = {
    enable = lib.mkDefault false;
    
    # Common packages
    packages = lib.mkDefault [
      "git"
      "curl"
      "vim"
      "wireguard-tools"
      "frr"
    ];
    
    # Common users
    users = lib.mkOption {
      type = lib.types.submodule {
        options = {
          franck = lib.mkOption {
            type = lib.types.submodule {
              options = {
                enable = lib.mkDefault true;
                sshKey = lib.mkDefault "";
              };
            };
          };
        };
      };
    };
    
    # Common system settings
    system = lib.mkOption {
      type = lib.types.submodule {
        options = {
          stateVersion = lib.mkDefault "25.11";
          console = lib.mkOption {
            type = lib.types.submodule {
              options = {
                keyMap = lib.mkDefault "fr";
              };
            };
          };
        };
      };
    };
    
    # Configuration directory
    configDir = lib.mkDefault "/etc/nixos-fabric";
  };

  config = lib.mkForce {
    # Common packages
    environment.systemPackages = with pkgs; [
      git
      curl
      vim
      wireguard-tools
      frr
    ];
    
    # Common users
    users.users.franck = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "" ];
    };
    
    security.sudo.wheelNeedsPassword = false;
    
    # Common system settings
    console.keyMap = "fr";
    system.stateVersion = "25.11";
    
    # Create config directory and set environment
    system.activationScripts.configDir = lib.mkBefore ''
      mkdir -p /etc/nixos-fabric
      echo "export NIXOS_FABRIC_CONFIG_DIR='/etc/nixos-fabric'" > /etc/profile.d/nixos-fabric.sh
      echo "export NIXOS_FABRIC_ANSIBLE_DIR='$NIXOS_FABRIC_CONFIG_DIR/ansible'" >> /etc/profile.d/nixos-fabric.sh
    '';
  };
}
