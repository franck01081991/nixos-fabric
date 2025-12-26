{ config, lib, pkgs, ... }:

let
  # Leaf role configuration using standard NixOS options
  cfg = config;  # Use standard config directly

  # Default leaf networking
  defaultLeafNetworking = {
    networking = {
      hostName = "leaf-node";
      domain = "fabric.local";
      nameservers = [ "1.1.1.1" "8.8.8.8" ];
    };
    
    # BGP configuration (using FRR)
    services.frr = {
      enable = true;
      zebra = { enable = true; };
      bgpd = { enable = true; };
    };
    
    # WireGuard configuration
    services.wireguard = {
      enable = true;
      interfaces = {
        wg0 = {
          ips = [ "10.255.0.2/24" "fd42:1337:255::2/64" ];
          privateKeyFile = "/etc/wireguard/private.key";
        };
      };
    };
  };

in {
  options = {
    network-fabric = {
      roles = {
        leaf = lib.mkOption {
          type = lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "Enable leaf role";
              roleId = lib.mkOption {
                type = lib.types.str;
                default = "leaf1";
                description = "Leaf node identifier";
              };
              networking = lib.mkOption {
                type = lib.types.attrs;
                default = {};
                description = "Leaf networking configuration";
              };
              frr = lib.mkOption {
                type = lib.types.attrs;
                default = {};
                description = "FRR/BGP configuration";
              };
              wireguard = lib.mkOption {
                type = lib.types.attrs;
                default = {};
                description = "WireGuard configuration";
              };
            };
          };
        };
      };
    };
  };

  config = lib.mkIf (cfg.network-fabric.roles.leaf or {}).enable {
    # Apply leaf role configuration
    networking = defaultLeafNetworking.networking // (cfg.network-fabric.roles.leaf or {}).networking;
    services.frr = defaultLeafNetworking.services.frr // (cfg.network-fabric.roles.leaf or {}).frr;
    services.wireguard = defaultLeafNetworking.services.wireguard // (cfg.network-fabric.roles.leaf or {}).wireguard;
  };
}