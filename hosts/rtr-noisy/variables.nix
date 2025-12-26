{ config, lib, pkgs, ... }:

{
  networking = {
    hostName = "rtr-noisy";
    timeZone = "Europe/Paris";
    useDHCP = false;
    useNetworkd = true;
      nameservers = [ "1.1.1.1" "9.9.9.9" ];
      
      loopback = {
        enable = true;
        ipv4 = [ { address = "10.254.0.11"; prefixLength = 32; } ];
      };
    };

    wireguard = {
      enable = true;
      interfaceName = "wgtransport";
      listenPort = 51820;
      privateKeyFile = "/etc/wireguard/rtr-noisy.key";
      ips = [ "10.255.0.11/24" ];
      
      peers = {
        rtr-sapinet = {
          publicKey = "__SAPINET_PUB__";
          endpoint = "45.90.162.251:51820";
          allowedIPs = [ "10.255.0.1/32" "10.254.0.1/32" ];
          persistentKeepalive = 25;
        };
      };
    };

    frr = {
      enable = true;
      
      bgp = {
        enable = true;
        as = 65000;
        routerId = "10.254.0.11";
        clusterId = "10.254.0.11";
        
        neighbors = {
          rtr-sapinet = {
            ip = "10.254.0.1";
            as = 65000;
            updateSource = "lo";
            ebgpMultihop = 5;
            addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
          };
        };
        
        networks = [ "10.254.0.11/32" ];
        addressFamilies = [ "ipv4 unicast" "l2vpn evpn" ];
      };
      
      evpn = {
        enable = true;
        neighbors = [ "10.254.0.1" ];
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
      
      hardening = {
        enable = true;
        # Use default hardening settings
      };
    };
  };
}