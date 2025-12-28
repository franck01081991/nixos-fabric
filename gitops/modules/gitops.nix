{ config, pkgs, lib, ... }:

# GitOps module for NixOS Fabric
# This module provides GitOps capabilities for continuous deployment

let
  inherit (lib) mkIf mkEnableOption mkOption mkDefault mkForce mkAfter mkBefore concatStringsSep mapAttrsToList attrNames;
  inherit (lib.types) submodule str bool listOf attrs attrsOf;
in
{
  options.network-fabric.gitops = {
    enable = mkEnableOption "Enable GitOps for NixOS Fabric";
    
    repository = mkOption {
      type = lib.types.str;
      default = "";
      description = "Git repository URL for configuration";
    };
    
    branch = mkOption {
      type = lib.types.str;
      default = "master";
      description = "Git branch to track";
    };
    
    interval = mkOption {
      type = lib.types.str;
      default = "15m";
      description = "Update check interval (systemd timer format)";
    };
    
    logFile = mkOption {
      type = lib.types.str;
      default = "/var/log/nixos-fabric/gitops.log";
      description = "Log file for GitOps operations";
    };
    
    # External machines configuration
    machines = mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          enable = mkEnableOption "Enable GitOps for this machine";
          configPath = mkOption {
            type = lib.types.str;
            default = "";
            description = "Path to machine configuration file";
          };
          description = mkOption {
            type = lib.types.str;
            default = "";
            description = "Machine description";
          };
        };
      });
      default = {};
      description = "External machines GitOps configuration";
    };
  };

  config = mkIf config.network-fabric.gitops.enable {
    # GitOps service configuration
    systemd.services.nixos-fabric-gitops = {
      description = "NixOS Fabric GitOps Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c 'nixos-rebuild switch --flake ${config.network-fabric.gitops.repository}#${config.network-fabric.gitops.branch}';";
        Restart = "always";
        RestartSec = "60s";
        Environment = "FABRIC_GITOPS=true";
      };
      path = [ pkgs.bash/bin ];
    };

    # GitOps timer configuration
    systemd.timers.nixos-fabric-gitops = {
      description = "NixOS Fabric GitOps Update Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = config.network-fabric.gitops.interval;
        Persistent = true;
        AccuracySec = "1min";
      };
    };

    # GitOps activation scripts
    system.activationScripts.gitops-init = mkAfter ''
      # Create gitops directory structure
      mkdir -p /etc/nixos-fabric/gitops
      mkdir -p /var/lib/nixos-fabric/gitops
      mkdir -p /var/log/nixos-fabric
      
      # Create gitops configuration file
      cat > /etc/nixos-fabric/gitops/config <<EOF
# NixOS Fabric GitOps Configuration
GITOPS_REPOSITORY="${config.network-fabric.gitops.repository}"
GITOPS_BRANCH="${config.network-fabric.gitops.branch}"
GITOPS_INTERVAL="${config.network-fabric.gitops.interval}"
GITOPS_LOG="${config.network-fabric.gitops.logFile}"
EOF
      
      # Set permissions
      chown -R root:root /etc/nixos-fabric/gitops
      chmod -R 750 /etc/nixos-fabric/gitops
      chmod 640 /etc/nixos-fabric/gitops/config
      
      echo "GitOps initialization completed"
    '';

    # GitOps environment variables
    environment.sessionVariables = {
      FABRIC_GITOPS = "true";
      FABRIC_PHASE = "day-2";
      GITOPS_REPOSITORY = config.network-fabric.gitops.repository;
      GITOPS_BRANCH = config.network-fabric.gitops.branch;
    };

    # GitOps packages
    environment.systemPackages = with pkgs; [
      git
      openssh
      curl
      jq
    ];

    # External machines GitOps configuration
    system.activationScripts.gitops-external-machines = mkAfter ''
      # Create machines directory
      mkdir -p /etc/nixos-fabric/gitops/machines
      
      # Generate configuration for each external machine
      ${concatStringsSep "\n" (mapAttrsToList (machineName: machineConfig: 
        if machineConfig.enable then 
          ''
            cat > /etc/nixos-fabric/gitops/machines/${machineName} <<EOF
# ${machineName} GitOps Configuration
MACHINE_NAME="${machineName}"
CONFIG_PATH="${machineConfig.configPath}"
GITOPS_INTERVAL="${config.network-fabric.gitops.interval}"
EOF
          ''
        else 
          ""
      ) config.network-fabric.gitops.machines)}
      
      # Set permissions
      chown -R root:root /etc/nixos-fabric/gitops/machines
      chmod -R 750 /etc/nixos-fabric/gitops/machines
      chmod 640 /etc/nixos-fabric/gitops/machines/*
      
      echo "GitOps external machines configuration completed"
    '';

    # External machines GitOps service
    systemd.services.nixos-fabric-gitops-external = {
      description = "NixOS Fabric GitOps for External Machines";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.nixos-fabric-gitops}/bin/gitops-external-service';";
        Restart = "always";
        RestartSec = "60s";
        Environment = "FABRIC_GITOPS_EXTERNAL=true";
      };
      path = [ pkgs.bash/bin ];
    };

    # External machines GitOps timer
    systemd.timers.nixos-fabric-gitops-external = {
      description = "NixOS Fabric GitOps Timer for External Machines";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = config.network-fabric.gitops.interval;
        Persistent = true;
        AccuracySec = "1min";
      };
    };

    # External machines environment variables
    environment.sessionVariables.FABRIC_GITOPS_EXTERNAL = "true";
    environment.sessionVariables.EXTERNAL_MACHINES = concatStringsSep " " (attrNames config.network-fabric.gitops.machines);
  };
}