{
  description = "NixOS Fabric - New Clean Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";

      networkModule = { config, lib, pkgs, ... }:
        let
          cfg = config.network-fabric.network;
        in
        {
          options.network-fabric = {
            enable = lib.mkEnableOption "Enable NixOS Fabric";

            network = lib.mkOption {
              type = lib.types.submodule ({ ... }: {
                options = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = "Enable network settings for this host.";
                  };

                  hostName = lib.mkOption {
                    type = lib.types.str;
                    default = "nixos-fabric";
                    description = "Hostname for this host.";
                  };

                  domain = lib.mkOption {
                    type = lib.types.str;
                    default = "fabric.local";
                    description = "Domain name.";
                  };

                  dnsServers = lib.mkOption {
                    type = with lib.types; listOf str;
                    default = [ "1.1.1.1" "8.8.8.8" ];
                    description = "DNS servers used by network-fabric.";
                  };
                };
              });
              default = {};
              description = "Network configuration";
            };
          };

          # Configuration conditionnelle
          config = lib.mkIf (cfg.enable) {
            networking.hostName = cfg.hostName;
            networking.nameservers = cfg.dnsServers;
          };
        };

      mkHost = { hostname, ciMode ? false }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            networkModule
            ({ ... }: {
              network-fabric.enable = true;

              network-fabric.network.enable = true;
              network-fabric.network.hostName = hostname;
              # network-fabric.network.dnsServers = [ "10.0.0.53" "fd00::53" ];
            })
          ] ++ (if ciMode then [ ./modules/ci-bootless.nix ] else []);
        };

      # Import real router configurations if they exist
      importRtrConfig = name: hostConfig:
        if builtins.pathExists (./hosts/${name}/default.nix) then
          (import ./hosts/${name}/default.nix).nixosConfigurations.${name}
        else
          null;
    in
    {
      nixosConfigurations = {
        test = mkHost { hostname = "test"; };
        test-ci = mkHost { hostname = "test-ci"; ciMode = true; };
      } // builtins.listToAttrs (
        map
          (name: { name = name; value = importRtrConfig name {}; })
          [ "rtr-sapinet" "rtr-noisy" ]
      );
    };
}
