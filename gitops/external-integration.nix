{ config, lib, pkgs, ... }:

# GitOps Integration for External Machines
# This module integrates existing external configurations with GitOps capabilities

{
  # Import external configurations
  imports = [
    # External machine configurations
    (builtins.path { path = [ "external" "rtr-noisy-config" "default.nix" ]; })
    (builtins.path { path = [ "external" "rtr-sapinet-config" "default.nix" ]; })
    
    # Host configurations
    (builtins.path { path = [ "hosts" "default-ansible.nix" ]; })
    
    # GitOps module
    (builtins.path { path = [ "gitops" "modules" "gitops.nix" ]; })
  ];

  # Enable GitOps for external machines
  network-fabric.gitops = {
    enable = true;
    repository = "git@github.com:your-org/nixos-fabric.git";
    branch = "master";
    interval = "15m";
    
    # Machine-specific GitOps settings
    machines = {
      "rtr-noisy" = {
        enable = true;
        configPath = "external/rtr-noisy-config/default.nix";
        description = "Noisy router GitOps";
      };
      
      "rtr-sapinet" = {
        enable = true;
        configPath = "external/rtr-sapinet-config/default.nix";
        description = "Sapinet router GitOps";
      };
    };
  };

  # GitOps activation for external machines
  system.activationScripts.gitops-external = lib.mkAfter ''
    # Create GitOps configuration for each external machine
    mkdir -p /etc/nixos-fabric/gitops/machines
    
    # rtr-noisy GitOps configuration
    cat > /etc/nixos-fabric/gitops/machines/rtr-noisy <<EOF
# rtr-noisy GitOps Configuration
MACHINE_NAME="rtr-noisy"
CONFIG_PATH="external/rtr-noisy-config/default.nix"
GITOPS_INTERVAL="15m"
EOF
    
    # rtr-sapinet GitOps configuration
    cat > /etc/nixos-fabric/gitops/machines/rtr-sapinet <<EOF
# rtr-sapinet GitOps Configuration
MACHINE_NAME="rtr-sapinet"
CONFIG_PATH="external/rtr-sapinet-config/default.nix"
GITOPS_INTERVAL="15m"
EOF
    
    # Set permissions
    chown -R root:root /etc/nixos-fabric/gitops/machines
    chmod -R 750 /etc/nixos-fabric/gitops/machines
    chmod 640 /etc/nixos-fabric/gitops/machines/*
    
    echo "GitOps integration for external machines completed"
  '';

  # GitOps services for external machines
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
    path = [ pkgs.bash bin ];
  };

  # GitOps timer for external machines
  systemd.timers.nixos-fabric-gitops-external = {
    description = "NixOS Fabric GitOps Timer for External Machines";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* *:0/15:00";  # Every 15 minutes
      Persistent = true;
      AccuracySec = "1min";
    };
  };

  # GitOps environment variables for external machines
  environment.sessionVariables = {
    FABRIC_GITOPS_EXTERNAL = "true";
    EXTERNAL_MACHINES = "rtr-noisy rtr-sapinet";
  };

  # GitOps packages for external integration
  environment.systemPackages = with pkgs; [
    git
    openssh
    curl
    jq
    nix
    nixfmt
    nixpkgs-fmt
  ];
}