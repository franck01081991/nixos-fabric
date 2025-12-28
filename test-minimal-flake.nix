{
  description = "Test minimal flake without flake-utils";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    core.url = "git+ssh://git@github.com/franck01081991/nixos-fabric-core.git";
  };

  outputs = { self, nixpkgs, core, ... }@inputs:
    {
      nixosConfigurations = {
        test = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            core.nixosModules.fabric
            ./hosts/production/rtr-prod-01.nix
          ];
        };
      };
    };
}