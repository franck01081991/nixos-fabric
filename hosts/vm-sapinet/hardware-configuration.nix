{ config, lib, pkgs, ... }:
{
  # Hardware-specific configuration for vm-sapinet (VPS)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network interfaces
  networking.useNetworkd = false;
  systemd.network.enable = false;

  # Force-disable/mask networkd units
  systemd.services.systemd-networkd.wantedBy = lib.mkForce [ ];
  systemd.sockets.systemd-networkd.wantedBy = lib.mkForce [ ];
  systemd.sockets.systemd-networkd-varlink.wantedBy = lib.mkForce [ ];

  networking.useDHCP = false;

  # WAN interface (hardware-specific)
  networking.interfaces.ens18 = {
    ipv4.addresses = [
      { address = "45.90.162.251"; prefixLength = 32; }
    ];
    ipv6.addresses = [
      { address = "2a0c:8881:5:a5::1"; prefixLength = 64; }
    ];
  };

  # Default gateways
  networking.defaultGateway = {
    address = "100.100.100.1";
    interface = "ens18";
  };

  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "ens18";
  };

  # DNS servers
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "9.9.9.9"
    "2606:4700:4700::1111"
    "2620:fe::fe"
  ];
}
