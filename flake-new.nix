{
  description = "NixOS Fabric - New Clean Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      
      # Simple network module
      networkModule = { config, lib, pkgs, ... }:
        let
          cfg = config.network-fabric.network or {};
        in {
          options.network-fabric = {
            enable = lib.mkEnableOption "Enable NixOS Fabric";
            
            network = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  enable = lib.mkDefault false;
                  hostName = lib.mkDefault "nixos-fabric";
                  domain = lib.mkDefault "fabric.local";
                  dnsServers = lib.mkDefault [ "1.1.1.1" "8.8.8.8" ];
                };
              };
              default = {};
              description = "Network configuration";
            };
          };
          
          config = lib.mkIf cfg.enable {
            networking.hostName = cfg.hostName;
          };
        };
      
      mkHost = { hostname }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            networkModule
            ({ config, lib, pkgs, ... }:
            {
              network-fabric.network.enable = true;
              network-fabric.network.hostName = hostname;
            })
          ];
        };
    in
    {
      nixosConfigurations = {
        "test" = mkHost { hostname = "test"; };
      };
    };
}