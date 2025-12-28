{ inputs, ... }:
{
  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      mkHost = { hostname }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./modules/network-fabric.nix
            ./modules/networking/networking.nix
            ({ config, lib, pkgs, ... }:
            {
              network-fabric.network = {
                enable = true;
                hostName = hostname;
                domain = "test.local";
                dnsServers = [ "8.8.8.8" ];
                useDHCP = false;
                useNetworkd = false;
                nameservers = [ "8.8.8.8" ];
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
};