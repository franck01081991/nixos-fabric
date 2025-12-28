{ config, lib, pkgs, ... }:

{
  # Leaf role configuration using the new role system
  network-fabric.roles.leaf = {
    enable = true;
    roleId = "leaf1";
    
    # Override default leaf networking
    networking = {
      hostName = "rtr-noisy";
      domain = "fabric.local";
    };
    
    # WireGuard configuration
    wireguard = {
      interfaces = {
        wg0 = {
          ips = [ "10.255.0.2/24" "fd42:1337:255::2/64" ];
          privateKeyFile = "/etc/wireguard/rtr-noisy.key";
        };
      };
    };
    
    # FRR/BGP configuration
    frr = {
      zebra = {
        enable = true;
      };
      bgpd = {
        enable = true;
      };
    };
  };
}