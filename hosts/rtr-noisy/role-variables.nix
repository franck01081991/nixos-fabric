{ ... }:

{
  network-fabric.roles = {
    spine = {
      enable = true;
      roleId = "spine2";  # rtr-noisy as spine
      
      networking = {
        loopback = {
          ipv4 = [ { address = "10.254.0.11"; prefixLength = 32; } ];
          ipv6 = [ { address = "fd42:1337:254::11"; prefixLength = 128; } ];
        };
      };
      
      wireguard = {
        privateKeyFile = "/etc/wireguard/rtr-noisy.key";
        ips = [ "10.255.0.11/24" "fd42:1337:255::11/64" ];
        peers = {
          vm-sapinet = {
            publicKey = "__SAPINET_PUB__";
            endpoint = "45.90.162.251:51820";
            allowedIPs = [
              "10.255.0.1/32"
              "fd42:1337:255::1/128"
              "10.254.0.1/32"
              "fd42:1337:254::1/128"
            ];
            persistentKeepalive = 25;
          };
        };
      };
      
      frr = {
        ospf = {
          enable = true;
          routerId = "10.254.0.11";
          area = 0;
          networks = [
            "10.254.0.11/32"
            "10.255.0.0/24"
          ];
          passiveInterfaces = [ "default" "wgtransport" ];
        };
        
        bgp = {
          enable = true;
          as = 65000;
          routerId = "10.254.0.11";
          neighbors = {
            vm-sapinet = {
              ip = "10.254.0.1";
              as = 65000;
              updateSource = "lo";
              ebgpMultihop = 5;
              addressFamilies = [ "ipv4 unicast" ];
            };
          };
          networks = [ "10.254.0.11/32" ];
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
    
    leaf = {
      enable = true;
      roleId = "leaf1";  # rtr-noisy as leaf
      
      networking = {
        loopback = {
          ipv4 = [ { address = "10.254.0.11"; prefixLength = 32; } ];
        };
      };
      
      wireguard = {
        privateKeyFile = "/etc/wireguard/rtr-noisy.key";
        ips = [ "10.255.0.11/24" ];
        peers = {
          vm-sapinet = {
            publicKey = "__SAPINET_PUB__";
            endpoint = "45.90.162.251:51820";
            allowedIPs = [
              "10.255.0.1/32"
              "fd42:1337:255::1/128"
              "10.254.0.1/32"
              "fd42:1337:254::1/128"
            ];
            persistentKeepalive = 25;
          };
        };
      };
      
      frr = {
        bgp = {
          enable = true;
          as = 65000;
          routerId = "10.254.0.11";
          clusterId = "10.254.0.11";
          neighbors = {
            vm-sapinet = {
              ip = "10.254.0.1";
              as = 65000;
              updateSource = "lo";
              ebgpMultihop = 5;
              addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
            };
          };
          networks = [ "10.254.0.11/32" ];
        };
        
        evpn = {
          enable = true;
          neighbors = [ "10.254.0.1" ];
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
  };
}