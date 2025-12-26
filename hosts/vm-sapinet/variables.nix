{ config, lib, pkgs, ... }:

{
  networking = {
    hostName = "vm-sapinet";
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
      privateKeyFile = "/etc/wireguard/vm-sapinet.key";
      ips = [ "10.255.0.1/24" "fd42:1337:255::1/64" ];
      
      peers = {
        rtr-noisy = {
          publicKey = "__NOISY_PUB__";
          endpoint = "__NOISY_ENDPOINT__:51820";
          allowedIPs = [ "10.255.0.2/32" "fd42:1337:255::2/128" "10.254.0.2/32" "fd42:1337:254::2/128" ];
          persistentKeepalive = 25;
        };
        bondy = {
          publicKey = "__BONDY_PUB__";
          endpoint = "__BONDY_ENDPOINT__:51820";
          allowedIPs = [ "10.255.0.3/32" "fd42:1337:255::3/128" "10.254.0.3/32" "fd42:1337:254::3/128" ];
          persistentKeepalive = 25;
        };
        lepre = {
          publicKey = "__LEPRE_PUB__";
          endpoint = "__LEPRE_ENDPOINT__:51820";
          allowedIPs = [ "10.255.0.4/32" "fd42:1337:255::4/128" "10.254.0.4/32" "fd42:1337:254::4/128" ];
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
            ip = "10.254.0.2";
            as = 65000;
            updateSource = "lo";
            ebgpMultihop = 5;
            addressFamilies = [ "ipv4 unicast" ];
          };
          bondy = {
            ip = "10.254.0.3";
            as = 65000;
            updateSource = "lo";
            ebgpMultihop = 5;
            addressFamilies = [ "ipv4 unicast" ];
          };
          lepre = {
            ip = "10.254.0.4";
            as = 65103;
            updateSource = "lo";
            ebgpMultihop = 5;
            addressFamilies = [ "ipv4 unicast" ];
          };
        };
        
        networks = [ "10.254.0.1/32" ];
        addressFamilies = [ "ipv4 unicast" ];
      };
      
      ospf = {
        enable = true;
        routerId = "10.254.0.1";
        area = 0;
        networks = [ "10.254.0.1/32" "10.255.0.0/24" ];
        passiveInterfaces = [ "default" "wgtransport" ];
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