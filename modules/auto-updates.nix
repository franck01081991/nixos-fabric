{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.auto-updates;
  
in {
  options.network-fabric.auto-updates = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable auto-updates functionality";
    };
    
    system = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable system auto-updates";
          };
          allowReboot = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Allow automatic reboots for system updates";
          };
          dates = lib.mkOption {
            type = lib.types.str;
            default = "*/7 * * *";  # Tous les 7 jours
            description = "Cron schedule for system updates";
          };
          flags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "--option substituters https://cache.nixos.org" ];
            description = "Additional flags for system updates";
          };
        };
      };
    };
    
    security = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable security updates checking";
          };
          checkInterval = lib.mkOption {
            type = lib.types.str;
            default = "daily";
            description = "Interval for security updates checking";
          };
          emailNotifications = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable email notifications for security updates";
          };
          emailTo = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Email address for security update notifications";
          };
        };
      };
    };
    
    packages = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable package auto-updates";
          };
          updateInterval = lib.mkOption {
            type = lib.types.str;
            default = "weekly";
            description = "Interval for package updates";
          };
          packages = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ 
              "wireguard-tools"
              "frr"
              "prometheus"
              "node-exporter"
              "grafana"
              "sops"
              "age"
            ];
            description = "List of packages to keep updated";
          };
        };
      };
    };
  };
  
  config = lib.mkIf (config.network-fabric.auto-updates.enable) {
    # System auto-updates
    system.autoUpgrade = lib.mkIf cfg.system.enable {
      enable = true;
      allowReboot = cfg.system.allowReboot;
      dates = cfg.system.dates;
      flags = cfg.system.flags;
      
      # Notifications would be handled separately if needed
    };
    
    # Security updates checker
    services.cron = lib.mkIf cfg.security.enable {
      enable = true;
      systemCronJobs = [
        "${cfg.security.checkInterval} ${pkgs.nix}/bin/nix-env -u '*' --attr nixpkgs.nixosTests.security-updates 2>&1 | logger -t security-updates"
      ];
    };
    
    # Package updates
    environment.systemPackages = lib.mkIf cfg.packages.enable (
      builtins.map (pkg: builtins.getAttr pkg pkgs) cfg.packages.packages
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
    # Security hardening for auto-updates
    nix = lib.mkIf cfg.enable {
      settings = {
        trusted-users = [ "root" ];
      };
    };
  };
}
