{ ... }:

{
  network-fabric.roles.spine = {
    enable = true;
    roleId = "spine1";
    
    networking = {
      loopback = {
        ipv4 = [ { address = "10.254.0.1"; prefixLength = 32; } ];
        ipv6 = [ { address = "fd42:1337:254::1"; prefixLength = 128; } ];
      };
    };
    
    wireguard = {
      privateKeyFile = "/etc/wireguard/vm-sapinet.key";
      ips = [ "10.255.0.1/24" "fd42:1337:255::1/64" ];
      peers = {
        rtr-noisy = {
          publicKey = "__NOISY_PUB__";
          endpoint = "__NOISY_ENDPOINT__:51820";
          allowedIPs = [
            "10.255.0.11/32"
            "fd42:1337:255::11/128"
            "10.254.0.11/32"
            "fd42:1337:254::11/128"
          ];
          persistentKeepalive = 25;
        };
        bondy = {
          publicKey = "__BONDY_PUB__";
          endpoint = "__BONDY_ENDPOINT__:51820";
          allowedIPs = [
            "10.255.0.3/32"
            "fd42:1337:255::3/128"
            "10.254.0.3/32"
            "fd42:1337:254::3/128"
          ];
          persistentKeepalive = 25;
        };
        lepre = {
          publicKey = "__LEPRE_PUB__";
          endpoint = "__LEPRE_ENDPOINT__:51820";
          allowedIPs = [
            "10.255.0.4/32"
            "fd42:1337:255::4/128"
            "10.254.0.4/32"
            "fd42:1337:254::4/128"
          ];
          persistentKeepalive = 25;
        };
      };
    };
    
    frr = {
      ospf = {
        routerId = "10.254.0.1";
      };
      
      bgp = {
        routerId = "10.254.0.1";
        neighbors = {
          rtr-noisy = {
            ip = "10.254.0.11";
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
      };
    };
    
    security = {
      ssh = {
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
        ];
      };
    };
  };
}