{
  description = "Test minimal flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        nixosConfigurations = {
          test = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              ./hosts/production/rtr-prod-01.nix
            ];
          };
        };
      }
    );
}