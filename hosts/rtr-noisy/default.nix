{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./base-variables.nix
    ./role-variables.nix
  ];

  # System tweaks
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Fix systemd-networkd credentials issue
  systemd.services.systemd-networkd.serviceConfig = {
    LoadCredential = lib.mkForce [ ];
    LoadCredentialEncrypted = lib.mkForce [ ];
    SetCredential = lib.mkForce [ ];
    SetCredentialEncrypted = lib.mkForce [ ];
  };

  # EVPN bridge + VXLAN configuration
  systemd.network.netdevs = {
    "br0" = {
      netdevConfig = { Name = "br0"; Kind = "bridge"; };
      bridgeConfig = { VLANFiltering = true; STP = false; };
      extraConfig = ''
        [Bridge]
        DefaultPVID=10
      '';
    };
  };

  systemd.network.networks = {
    # WAN DHCP
    "10-wan" = {
      matchConfig.Name = "enp1s0";
      networkConfig = { DHCP = "yes"; IPv6AcceptRA = true; };
    };

    # Loopback
    "05-lo" = {
      matchConfig.Name = "lo";
      networkConfig.Address = [ "10.254.0.11/32" ];
    };

    # br0
    "20-br0" = {
      matchConfig.Name = "br0";
      networkConfig.VLAN = [ "br0.10" "br0.20" "br0.30" "br0.40" ];
      extraConfig = ''
        [BridgeVLAN]
        VLAN=10
        [BridgeVLAN]
        VLAN=20
        [BridgeVLAN]
        VLAN=30
        [BridgeVLAN]
        VLAN=40
      '';
    };

    # LAN ports -> br0
    "21-lan-enp2s0" = { matchConfig.Name = "enp2s0"; networkConfig.Bridge = "br0"; };
    "22-lan-enp3s0" = { matchConfig.Name = "enp3s0"; networkConfig.Bridge = "br0"; };
    "23-lan-enp4s0" = { matchConfig.Name = "enp4s0"; networkConfig.Bridge = "br0"; };
    "24-lan-enp5s0" = { matchConfig.Name = "enp5s0"; networkConfig.Bridge = "br0"; };
    "25-lan-enp6s0" = { matchConfig.Name = "enp6s0"; networkConfig.Bridge = "br0"; };
  };

  # VLAN port flags workaround
  systemd.services.vlan-port-flags = {
    description = "Force VLAN10 untagged PVID on LAN ports; VLAN20/30/40 tagged";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-networkd.service" ];
    wants = [ "systemd-networkd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      BR="${pkgs.iproute2}/bin/bridge"
      IP="${pkgs.iproute2}/bin/ip"

      for i in $(seq 1 50); do
        if $IP link show br0 >/dev/null 2>&1; then break; fi
        sleep 0.1
      done

      for dev in enp2s0 enp3s0 enp4s0 enp5s0 enp6s0; do
        if ! $IP link show "$dev" >/dev/null 2>&1; then
          continue
        fi

        $BR vlan del dev "$dev" vid 1 2>/dev/null || true
        $BR vlan add dev "$dev" vid 10 pvid untagged
        $BR vlan add dev "$dev" vid 20
        $BR vlan add dev "$dev" vid 30
        $BR vlan add dev "$dev" vid 40
      done

      $BR vlan del dev br0 vid 1 2>/dev/null || true
      $BR vlan show
    '';
  };
}