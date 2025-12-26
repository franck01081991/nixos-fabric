{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.networking || {};
  
  # Generate interface configurations
  generateInterfaces = interfaces: 
    lib.mapAttrs (name: ifaceConfig: 
      {
        ipv4 = ifaceConfig.ipv4 or null;
        ipv6 = ifaceConfig.ipv6 or null;
        extraConfig = ifaceConfig.extraConfig or "";
      }
    ) interfaces;

in {
  options.network-fabric.networking = {
    enable = lib.mkDefault false;
    
    # Basic network settings
    hostName = lib.mkDefault "";
    timeZone = lib.mkDefault "Europe/Paris";
    useDHCP = lib.mkDefault false;
    useNetworkd = lib.mkDefault true;
    
    # DNS settings
    nameservers = lib.mkDefault [ "1.1.1.1" "9.9.9.9" ];
    
    # Default gateway
    defaultGateway = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault false;
          address = lib.mkDefault "";
          interface = lib.mkDefault "";
        };
      };
    };
    
    # Interfaces configuration
    interfaces = lib.mkDefault {};
    
    # Loopback configuration
    loopback = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          ipv4 = lib.mkDefault [];
          ipv6 = lib.mkDefault [];
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Basic network settings
    networking.hostName = cfg.hostName;
    time.timeZone = cfg.timeZone;
    networking.useDHCP = cfg.useDHCP;
    networking.useNetworkd = cfg.useNetworkd;
    
    # DNS configuration
    networking.nameservers = cfg.nameservers;
    
    # Default gateway
    networking.defaultGateway = lib.mkIf cfg.defaultGateway.enable {
      address = cfg.defaultGateway.address;
      interface = cfg.defaultGateway.interface;
    };
    
    # Loopback interface
    networking.interfaces.lo = lib.mkIf cfg.loopback.enable {
      ipv4.addresses = cfg.loopback.ipv4;
      ipv6.addresses = cfg.loopback.ipv6;
    };
    
    # Additional interfaces
    networking.interfaces = generateInterfaces cfg.interfaces;
    
    # System tweaks for networking
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}