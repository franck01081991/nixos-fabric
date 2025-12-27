# Network Host Role
# 
# This role provides common network configuration for routing devices
# including FRR, WireGuard, and basic networking.

{ config, lib, pkgs, ... }:

{
  # Network services
  services.wireguard = {
    enable = true;
    interfaces = {}
    # WireGuard interfaces will be defined in specific host configurations
  };

  # FRR routing suite
  services.frr = {
    enable = true;
    zebra = {
      enable = true;
      password = "zebra";
    };
    ospfd = {
      enable = true;
      password = "ospf";
    };
    bgpd = {
      enable = true;
      password = "bgp";
    };
  };

  # Network configuration
  networking = {
    hostName = "undefined-host"; # Will be overridden by specific hosts
    useDHCP = false;
    interfaces = {}
    # Interface configurations will be defined in specific host configurations
  };

  # Network tools
  environment.systemPackages = with pkgs; [
    iproute2
    iptables
    nmap
    tcpdump
    mtr
    iftop
  ];

  # Network services
  services.ntpd.enable = true;
  services.dhcpd.enable = false; # Enable in specific hosts if needed

  # Network hardening
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
  };
}