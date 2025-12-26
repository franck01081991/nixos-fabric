{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.base || {};

in {
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
  };

  config = lib.mkIf cfg.enable {
    # Common packages
    environment.systemPackages = with pkgs; cfg.packages;
    
    # Common users
    users.users.franck = lib.mkIf cfg.users.franck.enable {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ cfg.users.franck.sshKey ];
    };
    
    security.sudo.wheelNeedsPassword = false;
    
    # Common system settings
    console.keyMap = cfg.system.console.keyMap;
    system.stateVersion = cfg.system.stateVersion;
  };
}
