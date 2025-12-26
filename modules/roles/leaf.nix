{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.roles.leaf || {};
  
  # Default leaf role configuration
  defaultLeafConfig = {
    # Networking defaults for leaf
    networking = {
      loopback = {
        enable = true;
        ipv4 = [ { address = "10.254.0.11"; prefixLength = 32; } ];
      };
    };
    
    # WireGuard defaults for leaf
    wireguard = {
      enable = true;
      interfaceName = "wgtransport";
      listenPort = 51820;
      ips = [ "10.255.0.11/24" ];
    };
    
    # FRR defaults for leaf (BGP + EVPN)
    frr = {
      enable = true;
      
      bgp = {
        enable = true;
        as = 65000;
        routerId = "10.254.0.11";
        clusterId = "10.254.0.11";
        addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
      };
      
      evpn = {
        enable = true;
        neighbors = [];
      };
    };
    
    # Security defaults for leaf
    security = {
      enable = true;
      fail2ban = {
        enable = false;  # Typically not needed on leaf nodes
      };
      hardening = {
        enable = true;
      };
    };
  };

in {
  options.network-fabric.roles.leaf = {
    enable = lib.mkDefault false;
    
    # Leaf-specific configuration
    roleId = lib.mkDefault "leaf1";
    
    # Networking overrides
    networking = lib.mkOption {
      type = lib.types.submodule {
        options = {
          loopback = lib.mkOption {
            type = lib.types.submodule {
              options = {
                ipv4 = lib.mkDefault [ { address = "10.254.0.11"; prefixLength = 32; } ];
              };
            };
          };
        };
      };
    };
    
    # WireGuard overrides
    wireguard = lib.mkOption {
      type = lib.types.submodule {
        options = {
          ips = lib.mkDefault [ "10.255.0.11/24" ];
        };
      };
    };
    
    # FRR overrides
    frr = lib.mkOption {
      type = lib.types.submodule {
        options = {
          bgp = lib.mkOption {
            type = lib.types.submodule {
              options = {
                routerId = lib.mkDefault "10.254.0.11";
                clusterId = lib.mkDefault "10.254.0.11";
                neighbors = lib.mkDefault {};
                networks = lib.mkDefault [ "10.254.0.11/32" ];
                addressFamilies = lib.mkDefault [ "ipv4 unicast" "l2vpn evpn" ];
              };
            };
          };
          evpn = lib.mkOption {
            type = lib.types.submodule {
              options = {
                enable = lib.mkDefault true;
                neighbors = lib.mkDefault [];
              };
            };
          };
        };
      };
    };
    
    # Security overrides
    security = lib.mkOption {
      type = lib.types.submodule {
        options = {
          fail2ban = lib.mkOption {
            type = lib.types.submodule {
              options = {
                enable = lib.mkDefault false;
              };
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Apply leaf role configuration
    network-fabric = {
      networking = lib.mkMerge [ defaultLeafConfig.networking (cfg.networking or {}) ];
      wireguard = lib.mkMerge [ defaultLeafConfig.wireguard (cfg.wireguard or {}) ];
      frr = lib.mkMerge [ defaultLeafConfig.frr (cfg.frr or {}) ];
      security = lib.mkMerge [ defaultLeafConfig.security (cfg.security or {}) ];
    };
    
    # Leaf-specific system tweaks
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    
    # Leaf-specific packages
    environment.systemPackages = with pkgs; [
      vim git tcpdump frr wireguard-tools iproute2
    ];
  };
}