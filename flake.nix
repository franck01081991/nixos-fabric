{
  description = "Spine/leaf fabric (rtr-sapinet + rtr-noisy)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      mkHost = { system, hostname }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./modules/lib.nix
            ./modules/base.nix
            ./modules/ssh.nix
            ./modules/nftables.nix
            ./modules/ansible.nix
            ./modules/roles/spine.nix
            ./modules/roles/leaf.nix

            ./hosts/${hostname}/hardware-configuration.nix
            ./hosts/${hostname}/default.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        "rtr-sapinet" = mkHost { system = "x86_64-linux"; hostname = "rtr-sapinet"; };
        "rtr-noisy" = mkHost { system = "x86_64-linux"; hostname = "rtr-noisy"; };
      };
    };
}
