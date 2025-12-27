{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.auto-updates || {};
  
in {
  options.network-fabric.auto-updates = {
    enable = lib.mkDefault false;
    
    system = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          allowReboot = lib.mkDefault true;
          dates = lib.mkDefault "*/7 * * *";  # Tous les 7 jours
          flags = lib.mkDefault [ "--option substituters https://cache.nixos.org" ];
        };
      };
    };
    
    security = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          checkInterval = lib.mkDefault "daily";
          emailNotifications = lib.mkDefault false;
          emailTo = lib.mkDefault "";
        };
      };
    };
    
    packages = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          updateInterval = lib.mkDefault "weekly";
          packages = lib.mkDefault [ 
            "wireguard-tools"
            "frr"
            "prometheus"
            "node-exporter"
            "grafana"
            "sops"
            "age"
          ];
        };
      };
    };
  };
  
  config = lib.mkIf cfg.enable {
    # System auto-updates
    system.autoUpgrade = lib.mkIf cfg.system.enable {
      enable = true;
      allowReboot = cfg.system.allowReboot;
      dates = cfg.system.dates;
      flags = cfg.system.flags;
      
      # Notifications
      notificationEmail = lib.mkIf cfg.security.emailNotifications cfg.security.emailTo;
    };
    
    # Security updates checker
    services.cron = lib.mkIf cfg.security.enable {
      enable = true;
      systemJobs = [
        {
          name = "security-updates-check";
          command = "${pkgs.nix}/bin/nix-env -u '*' --attr nixpkgs.nixosTests.security-updates 2>&1 | logger -t security-updates";
          special = cfg.security.checkInterval;
          user = "root";
        }
      ];
    };
    
    # Package updates
    environment.systemPackages = lib.mkIf cfg.packages.enable (
      pkgs.lib.attrValues (builtins.listToAttrs (lib.mapAttrs (name: pkg: 
        { 
          name = "${pkg}-latest";
          value = pkgs.${pkg};
        }
      ) (builtins.listToAttrs cfg.packages.packages)))
    );
    
    # Update packages regularly
    systemd.services.package-updates = lib.mkIf cfg.packages.enable {
      description = "Update packages regularly";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'nix-env -u \"*\" --attr nixpkgs.${toString cfg.packages.packages} 2>&1 | logger -t package-updates'";
      };
      timerConfig = {
        OnCalendar = cfg.packages.updateInterval;
        Persistent = true;
      };
    };
    
    # Security hardening for auto-updates
    security = lib.mkIf cfg.enable {
      autoUpgrade = {
        enable = true;
        allowReboot = true;
        dates = "*/7 * * *";
      };
      
      # Ensure only signed packages are installed
      nix = {
        requireSigned = true;
        trustedUsers = [ "root" ];
      };
    };
  };
}
