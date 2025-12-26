{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.roles.spine || {};
  
  # Default spine role configuration
  defaultSpineConfig = {
    # Networking defaults for spine
    networking = {
      loopback = {
        enable = true;
        ipv4 = [ { address = "10.254.0.1"; prefixLength = 32; } ];
        ipv6 = [ { address = "fd42:1337:254::1"; prefixLength = 128; } ];
      };
    };
    
    # WireGuard defaults for spine
    wireguard = {
      enable = true;
      interfaceName = "wgtransport";
      listenPort = 51820;
      ips = [
        "10.255.0.1/24"
        "fd42:1337:255::1/64"
      ];
    };
    
    # FRR defaults for spine (OSPF + BGP)
    frr = {
      enable = true;
      
      ospf = {
        enable = true;
        area = 0;
        networks = [
          "10.254.0.1/32"
          "10.255.0.0/24"
        ];
        passiveInterfaces = [ "default" "wgtransport" ];
      };
      
      bgp = {
        enable = true;
        as = 65000;
        routerId = "10.254.0.1";
        addressFamilies = [ "ipv4 unicast" ];
      };
    };
    
    # Security defaults for spine
    security = {
      enable = true;
      fail2ban = {
        enable = true;
        jails = {
          sshd = {
            enabled = true;
            maxretry = 5;
            findtime = "10m";
            bantime = "1h";
          };
        };
      };
      hardening = {
        enable = true;
      };
    };
  };

in {
  options.network-fabric.roles.spine = {
    enable = lib.mkDefault false;
    
    # Spine-specific configuration
    roleId = lib.mkDefault "spine1";
    
    # Networking overrides
    networking = lib.mkOption {
      type = lib.types.submodule {
        options = {
          loopback = lib.mkOption {
            type = lib.types.submodule {
              options = {
                ipv4 = lib.mkDefault [ { address = "10.254.0.1"; prefixLength = 32; } ];
                ipv6 = lib.mkDefault [ { address = "fd42:1337:254::1"; prefixLength = 128; } ];
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
          ips = lib.mkDefault [ "10.255.0.1/24" "fd42:1337:255::1/64" ];
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
                routerId = lib.mkDefault "10.254.0.1";
                neighbors = lib.mkDefault {};
                networks = lib.mkDefault [ "10.254.0.1/32" ];
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
                enable = lib.mkDefault true;
              };
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Apply spine role configuration
    network-fabric = {
      networking = lib.mkMerge [ defaultSpineConfig.networking (cfg.networking or {}) ];
      wireguard = lib.mkMerge [ defaultSpineConfig.wireguard (cfg.wireguard or {}) ];
      frr = lib.mkMerge [ defaultSpineConfig.frr (cfg.frr or {}) ];
      security = lib.mkMerge [ defaultSpineConfig.security (cfg.security or {}) ];
    };
    
    # Spine-specific system tweaks
    boot.kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.yama.ptrace_scope" = 2;
    };
    
    # Spine-specific services
    services.journald.extraConfig = ''
      Storage=persistent
      Compress=yes
      SystemMaxUse=512M
      RuntimeMaxUse=128M
      SystemMaxFileSize=64M
      RateLimitIntervalSec=30s
      RateLimitBurst=1000
    '';
    
    security.apparmor.enable = true;
    security.auditd.enable = true;
    security.audit.enable = true;
  };
}