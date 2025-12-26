{ config, lib, pkgs, ... }:

let
  # Spine role configuration using standard NixOS options
  cfg = config;  # Use standard config directly

  # Default spine networking
  defaultSpineNetworking = {
    networking = {
      hostName = "spine-node";
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
          ips = [ "10.255.0.1/24" "fd42:1337:255::1/64" ];
          privateKeyFile = "/etc/wireguard/private.key";
        };
      };
    };
  };

in {
  options = {
    network-fabric = {
      roles = {
        spine = lib.mkOption {
          type = lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "Enable spine role";
              roleId = lib.mkOption {
                type = lib.types.str;
                default = "spine1";
                description = "Spine node identifier";
              };
              networking = lib.mkOption {
                type = lib.types.attrs;
                default = {};
                description = "Spine networking configuration";
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

  config = lib.mkIf cfg.network-fabric.roles.spine.enable {
    # Apply spine role configuration
    networking = defaultSpineNetworking.networking // cfg.network-fabric.roles.spine.networking;
    services.frr = defaultSpineNetworking.services.frr // cfg.network-fabric.roles.spine.frr;
    services.wireguard = defaultSpineNetworking.services.wireguard // cfg.network-fabric.roles.spine.wireguard;
  };
}