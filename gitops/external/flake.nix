{
  description = "NixOS Fabric - External Machines GitOps Flake";

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
        # rtr-noisy with GitOps
        rtr-noisy-gitops = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              imports = [
                ../external-integration.nix
                ../hosts/default-ansible.nix
              ];

              # Machine-specific GitOps configuration
              network-fabric.gitops.machines."rtr-noisy".enable = true;
              
              # Enable GitOps service
              systemd.services.nixos-fabric-gitops-external.enable = true;
              systemd.timers.nixos-fabric-gitops-external.enable = true;
              
              # Machine identification
              networking.hostName = "rtr-noisy";
              network-fabric.name = "rtr-noisy";
            })
          ];
        };

        # rtr-sapinet with GitOps
        rtr-sapinet-gitops = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              imports = [
                ../external-integration.nix
                ../hosts/default-ansible.nix
              ];

              # Machine-specific GitOps configuration
              network-fabric.gitops.machines."rtr-sapinet".enable = true;
              
              # Enable GitOps service
              systemd.services.nixos-fabric-gitops-external.enable = true;
              systemd.timers.nixos-fabric-gitops-external.enable = true;
              
              # Machine identification
              networking.hostName = "rtr-sapinet";
              network-fabric.name = "rtr-sapinet";
            })
          ];
        };

        # Combined configuration for all external machines
        external-gitops = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              imports = [
                ../external-integration.nix
                ../gitops/modules/gitops.nix
              ];

              # Enable GitOps for all external machines
              network-fabric.gitops = {
                enable = true;
                repository = "git@github.com:your-org/nixos-fabric.git";
                branch = "master";
                interval = "15m";
                
                machines = {
                  "rtr-noisy" = {
                    enable = true;
                    configPath = "external/rtr-noisy-config/default.nix";
                  };
                  "rtr-sapinet" = {
                    enable = true;
                    configPath = "external/rtr-sapinet-config/default.nix";
                  };
                };
              };

              # Enable GitOps services
              systemd.services.nixos-fabric-gitops-external.enable = true;
              systemd.timers.nixos-fabric-gitops-external.enable = true;
              
              # GitOps environment
              environment.sessionVariables = {
                FABRIC_GITOPS_EXTERNAL = "true";
                EXTERNAL_MACHINES = "rtr-noisy rtr-sapinet";
              };
            })
          ];
        };
      };
    };
}