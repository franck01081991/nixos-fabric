{
  description = "NixOS Fabric - Day-2 GitOps Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations = {
        gitops = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, lib, ... }: {
              imports = [
                ../modules/gitops.nix
              ];

              # GitOps configuration
              network-fabric.gitops = {
                enable = true;
                repository = "git@github.com:username/nixos-fabric.git";
                branch = "master";
                interval = "15m";
                logFile = "/var/log/nixos-fabric/gitops.log";
              };

              # GitOps service
              systemd.services.nixos-fabric-gitops = {
                description = "NixOS Fabric GitOps Service";
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "simple";
                  ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.nixos-fabric-gitops}/bin/gitops-service';";
                  Restart = "always";
                  RestartSec = "60s";
                };
                path = [ pkgs.bash/bin ];
              };

              # GitOps timer for periodic updates
              systemd.timers.nixos-fabric-gitops = {
                description = "NixOS Fabric GitOps Update Timer";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                  OnCalendar = config.network-fabric.gitops.interval;
                  Persistent = true;
                  AccuracySec = "1min";
                };
              };

              # GitOps activation script
              system.activationScripts.gitops-setup = lib.mkAfter ''
                # Create gitops directory structure
                mkdir -p /etc/nixos-fabric/gitops
                mkdir -p /var/lib/nixos-fabric/gitops
                mkdir -p /var/log/nixos-fabric
                
                # Create gitops configuration
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
                
                # Initialize git repository
                if [ ! -d /var/lib/nixos-fabric/gitops/repository ]; then
                  git init --bare /var/lib/nixos-fabric/gitops/repository
                fi
                
                echo "GitOps setup completed"
              '';

              # GitOps environment variables
              environment.sessionVariables = {
                FABRIC_GITOPS = "true";
                FABRIC_PHASE = "day-2";
              };

              # GitOps packages
              environment.systemPackages = with pkgs; [
                git
                openssh
                curl
                jq
              ];

              # GitOps security
              security.gitops = {
                enable = true;
                sshKeyPath = "/etc/nixos-fabric/gitops/ssh_key";
                knownHosts = "/etc/nixos-fabric/gitops/known_hosts";
              };
            })
          ];
        };
      };
    };
}