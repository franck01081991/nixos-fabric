{
  description = "Spine/leaf fabric (sapinet + noisy-edge1)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      mkHost = { system, hostname }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./modules/base.nix
            ./modules/ssh.nix
            ./modules/nftables.nix

            ./hosts/${hostname}/hardware-configuration.nix
            ./hosts/${hostname}/default.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        sapinet = mkHost { system = "x86_64-linux"; hostname = "sapinet"; };
        noisy-edge1 = mkHost { system = "x86_64-linux"; hostname = "noisy-edge1"; };
      };
    };
}
