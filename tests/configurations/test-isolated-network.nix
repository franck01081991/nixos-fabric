{ config, lib, pkgs, ... }:

let
  defaultFabricConfig = {
    network = {
      domain = "fabric.local";
      dnsServers = [ "1.1.1.1" "8.8.8.8" ];
      ipv4 = {
        prefix = "10.254.0.0/16";
        gateway = "10.254.0.1";
      };
      ipv6 = {
        prefix = "fd42:1337:254::/64";
        gateway = "fd42:1337:254::1";
      };
    };
  };

  cfg = if config.network-fabric ? network then config.network-fabric.network else {};

in {
  options.network-fabric = {
    enable = lib.mkEnableOption "Enable NixOS Fabric configuration";
    
    network = lib.mkOption {
      type = lib.types.submodule {
        options = {
          domain = lib.mkDefault defaultFabricConfig.network.domain;
          dnsServers = lib.mkDefault defaultFabricConfig.network.dnsServers;
        };
      };
      default = defaultFabricConfig.network;
      description = "Network configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    testOutput = "Network module loaded successfully";
  };
}