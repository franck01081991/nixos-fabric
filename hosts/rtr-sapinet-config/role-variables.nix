{ config, lib, pkgs, ... }:

{
  # Spine role configuration using the new role system
  network-fabric.roles.spine = {
    enable = true;
    roleId = "spine1";
    
    # Override default spine networking
    networking = {
      hostName = "rtr-sapinet";
      domain = "fabric.local";
    };
    
    # WireGuard configuration
    wireguard = {
      interfaces = {
        wg0 = {
          ips = [ "10.255.0.1/24" "fd42:1337:255::1/64" ];
          privateKeyFile = "/etc/wireguard/rtr-sapinet.key";
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