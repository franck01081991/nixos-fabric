{ config, lib, pkgs, ... }:

{
  network-fabric.network = {
    hostName = "rtr-sapinet";
    timeZone = "Europe/Paris";
    useDHCP = false;
    useNetworkd = false;
      nameservers = [ "1.1.1.1" "1.0.0.1" "9.9.9.9" "2606:4700:4700::1111" "2620:fe::fe" ];
      
      defaultGateway = {
        enable = true;
        address = "100.100.100.1";
        interface = "ens18";
      };
      
      interfaces = {
        ens18 = {
          ipv4 = [
            { address = "45.90.162.251"; prefixLength = 32; }
          ];
          ipv6 = [
            { address = "2a0c:8881:5:a5::1"; prefixLength = 64; }
          ];
        };
      };
      
      loopback = {
        enable = true;
        ipv4 = [ { address = "10.254.0.1"; prefixLength = 32; } ];
        ipv6 = [ { address = "fd42:1337:254::1"; prefixLength = 128; } ];
      };
    };

    wireguard = {
      enable = true;
      interfaceName = "wgtransport";
      listenPort = 51820;
      privateKeyFile = "/etc/wireguard/rtr-sapinet.key";
      ips = [ "10.255.0.1/24" "fd42:1337:255::1/64" ];
      mtu = 1420;  # Safe MTU for WireGuard over Internet
      
      peers = {
        rtr-noisy = {
          publicKey = "__RTR_NOISY_PUB__";
          endpoint = "45.90.162.251:51820";  # rtr-noisy will initiate to this public endpoint
          allowedIPs = [ "10.255.0.11/32" "10.254.0.11/32" ];
          persistentKeepalive = 25;
        };
      };
    };

    frr = {
      enable = true;
      
      bgp = {
        enable = true;
        as = 65000;
        routerId = "10.254.0.1";
        
        neighbors = {
          rtr-noisy = {
            ip = "10.254.0.11";
            as = 65000;
            updateSource = "lo";
            ebgpMultihop = 5;
            addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
          };
        };
        
        networks = [ "10.254.0.1/32" ];
        addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
      };
      
      ospf = {
        enable = true;
        routerId = "10.254.0.1";
        area = 0;
        networks = [ "10.254.0.1/32" "10.255.0.0/24" ];
        passiveInterfaces = [ "default" "wgtransport" ];
      };
      
      evpn = {
        enable = true;
        neighbors = [ "10.254.0.11" ];
      };
    };

    security = {
      enable = true;
      
      ssh = {
        enable = true;
        port = 22;
        permitRootLogin = "prohibit-password";
        passwordAuthentication = false;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
        ];
      };
      
      fail2ban = {
        enable = true;
        jails = {
          sshd = {
            enabled = true;
            backend = "systemd";
            maxretry = 5;
            findtime = "10m";
            bantime = "1h";
          };
        };
      };
      
      hardening = {
        enable = true;
        # Use default hardening settings
      };
    };
  };
}