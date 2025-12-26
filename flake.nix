{
  description = "Spine/leaf fabric (vm-sapinet + rtr-noisy)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      mkHost = { system, hostname }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./modules/ssh.nix
            ./modules/nftables.nix
            # ./modules/roles/spine.nix
            # ./modules/roles/leaf.nix

            ./hosts/${hostname}/hardware-configuration.nix
            ./hosts/${hostname}/default.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        "vm-sapinet" = mkHost { system = "x86_64-linux"; hostname = "vm-sapinet"; };
        "rtr-noisy" = mkHost { system = "x86_64-linux"; hostname = "rtr-noisy"; };
      };
    };
}
