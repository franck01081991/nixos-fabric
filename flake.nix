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
            ./modules/network-fabric.nix  # Central fabric module with integrated security
            ./modules/lib.nix
            ./modules/dynamic.nix
            ./modules/base.nix
            ./modules/security/init.nix  # Comprehensive security module
            ./modules/network-security.nix  # Unified network security
            ./modules/frr.nix            # FRR routing with security
            ./modules/wireguard.nix      # WireGuard VPN with security
            ./modules/networking.nix     # Networking configuration
            ./modules/roles/generic.nix    # Generic role functionality
            ./modules/roles/spine-improved.nix  # Improved spine role
            ./modules/roles/leaf-improved.nix   # Improved leaf role

            ./hosts/${hostname}/hardware-configuration.nix
            ./hosts/${hostname}/default.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        "rtr-sapinet" = mkHost { system = "x86_64-linux"; hostname = "rtr-sapinet"; };
        "rtr-noisy" = mkHost { system = "x86_64-linux"; hostname = "rtr-noisy"; };
        "test-vm" = mkHost { system = "x86_64-linux"; hostname = "test-vm"; };
      };
    };
}
