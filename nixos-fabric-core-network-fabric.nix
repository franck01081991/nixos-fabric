{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.network-fabric;
  mkOption = lib.mkOption;
  mkEnableOption = lib.mkEnableOption;
  mkOptionType = lib.types;

in {
  options.network-fabric = {
    enable = mkEnableOption "Enable NixOS Fabric";
    
    network = mkOption {
      type = mkOptionType.submodule ({
        options = {
          enable = mkOption {
            type = mkOptionType.bool;
            default = false;
            description = "Enable network settings for this host.";
          };
          
          hostName = mkOption {
            type = mkOptionType.str;
            default = "nixos-fabric";
            description = "Hostname for this host.";
          };
          
          domain = mkOption {
            type = mkOptionType.str;
            default = "fabric.local";
            description = "Domain name.";
          };
          
          dnsServers = mkOption {
            type = mkOptionType.listOf mkOptionType.str;
            default = [ "1.1.1.1" "8.8.8.8" ];
            description = "DNS servers used by network-fabric.";
          };
        };
      });
      default = {};
      description = "Network configuration";
    };
  };
  
  config = mkIf (cfg.enable) {
    networking.hostName = cfg.network.hostName;
    networking.nameservers = cfg.network.dnsServers;
  };
}