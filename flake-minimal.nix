{
  description = "Minimal flake for testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      mkHost = { hostname }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./modules/core/network-fabric.nix
            ./modules/networking/networking.nix
            ({ config, lib, pkgs, ... }:
            {
              network-fabric = {
                enable = true;
                name = "test-fabric";
                network = {
                  enable = true;
                  domain = "test.local";
                  dnsServers = [ "8.8.8.8" ];
                };
              };
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