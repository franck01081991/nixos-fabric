{ config, pkgs, ... }:

# Example NixOS Fabric Configuration with Integrated Network Security
# This example demonstrates how to configure a secure network fabric
# with FRR, WireGuard, and comprehensive security policies

{
  imports = [
    ../modules/core/network-fabric.nix
    ../modules/networking/frr.nix
    ../modules/networking/wireguard.nix
    ../modules/security/init.nix
  ];

  network-fabric = {
    enable = true;
    name = "secure-fabric";
    environment = "production";
    
    network = {
      domain = "fabric.secure";
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
    
    security = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;  # Non-standard port for security
        passwordAuthentication = false;
        permitRootLogin = "no";
        allowUsers = [ "admin" "network" ];
        allowGroups = [ "wheel" "network-admin" ];
        maxAuthTries = 3;
        loginGraceTime = 30;
        banner = "/etc/security-banner";
      };
      firewallEnable = true;
      fail2banEnable = true;
    };
  };

  # FRR Configuration with Security
  network-fabric.frr = {
    enable = true;
    
    security = {
      enable = true;
      bgpTtlSecurity = true;
      bgpMaxPrefix = 500;
      ospfAuthentication = true;
      ospfAuthenticationKey = "secure-ospf-key";
    };
    
    bgp = {
      enable = true;
      as = 65001;
      routerId = "10.254.0.1";
      
      neighbors = {
        spine1 = {
          ip = "10.255.0.1";
          as = 65000;
          updateSource = "lo";
          description = "Connection to spine router";
        };
      };
      
      networks = [
        "10.254.0.0/16"
        "10.255.0.0/24"
      ];
      
      addressFamilies = [ "ipv4 unicast" "ipv6 unicast" ];
    };
    
    ospf = {
      enable = true;
      routerId = "10.254.0.1";
      area = 0;
      networks = [
        "10.254.0.0/24"
        "10.0.0.0/16"
      ];
      passiveInterfaces = [ "eth0" ];
    };
  };

  # WireGuard Configuration with Security
  network-fabric.wireguard = {
    enable = true;
    interfaceName = "wgtransport";
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/private.key";
    ips = [ "10.255.0.1/24" ];
    
    security = {
      enable = true;
      firewallEnable = true;
      mtu = 1420;
      persistentKeepalive = 25;
      rateLimit = "500/m";  # More restrictive rate limiting
    };
    
    peers = {
      spine1 = {
        publicKey = "spine1-public-key-here";
        endpoint = "spine.fabric.secure:51820";
        allowedIPs = [ "10.255.0.2/32" ];
        persistentKeepalive = 25;
      };
    };
  };

  # Network Security Integration
  network-fabric.network-security = {
    enable = true;
    
    policies = {
      defaultDeny = true;
      stateTracking = true;
      enableLogging = true;
      logPrefix = "secure-fabric";
      sshRateLimit = "5/minute";  # More restrictive
      icmpRateLimit = "3/sec";    # More restrictive
      vlanIsolation = true;
    };
    
    protocolSecurity = {
      bgp = {
        ttlSecurity = true;
        maxPrefix = 500;
        prefixFiltering = true;
        rpkiValidation = true;  # Enable RPKI if available
      };
      
      ospf = {
        authentication = true;
        authenticationKey = "secure-ospf-key";
        md5KeyId = 1;
      };
      
      wireguard = {
        rateLimiting = "500/m";
        interfaceRestriction = true;
        mtu = 1420;
        keepalive = 25;
      };
    };
  };

  # Additional system hardening
  security.hardening = {
    enable = true;
    kernel = {
      sysctl = {
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.default.accept_source_route" = 0;
      };
    };
    
    network = {
      enable = true;
      ipv6 = {
        privacyExtensions = true;
        useTempAddress = true;
      };
    };
  };

  # System configuration
  networking = {
    hostName = "secure-leaf1";
    interfaces = {
      lo = {
        ipv4Addresses = [ { address = "127.0.0.1"; prefixLength = 8; } ];
        ipv6Addresses = [ { address = "::1"; prefixLength = 128; } ];
      };
    };
  };

  # Time synchronization for security logs
  services.ntp = {
    enable = true;
    servers = [ "0.pool.ntp.org" "1.pool.ntp.org" ];
  };

  # Logging configuration
  services.logging = {
    enable = true;
    syslog = {
      enable = true;
      remote = {
        enable = true;
        server = "log.fabric.secure";
        port = 514;
      };
    };
  };
}