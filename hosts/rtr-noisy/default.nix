{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Host identity
  networking.hostName = "rtr-noisy";

  # Router-ID / VTEP loopback
  # VLAN/VNI definitions (simplified for now)
  # vlans = [
  #   { id = 10; vni = 1010; gw = "10.10.10.1/24"; mac = "02:00:10:10:10:01"; dhcp = true; }
  #   { id = 20; vni = 1020; gw = "10.10.20.1/24"; mac = "02:00:10:10:20:01"; dhcp = false; }
  #   { id = 30; vni = 1030; gw = "10.10.30.1/24"; mac = "02:00:10:10:30:01"; dhcp = true; }
  #   { id = 40; vni = 1040; gw = "10.10.40.1/24"; mac = "02:00:10:10:40:01"; dhcp = true; }
  # ];

  # Base settings
  time.timeZone = "Europe/Paris";
  console.keyMap = "fr";

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

  # WireGuard (public key will be in secrets)
  networking.wireguard.interfaces.wgtransport = {
    ips = [ "10.255.0.11/24" ];
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/rtr-noisy.key";

    peers = [
      {
        publicKey = "__SAPINET_PUB__";  # Will be replaced by secrets
        endpoint = "45.90.162.251:51820";
        allowedIPs = [
          "10.255.0.1/32"
          "10.254.0.1/32"
        ];
        persistentKeepalive = 25;
      }
    ];
  };

  # EVPN bridge + VXLAN
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

  # DHCP/DNS (simplified - comment out for now)
  # services.dnsmasq = {
  #   enable = true;
  #   settings = {
  #     bind-dynamic = true;
  #     domain-needed = true;
  #     bogus-priv = true;
  #     interface = [ "br0.10" "br0.30" "br0.40" ];
  #     dhcp-range = [
  #       "br0.10,10.10.10.50,10.10.10.199,255.255.255.0,12h"
  #       "br0.30,10.10.30.50,10.10.30.199,255.255.255.0,12h"
  #       "br0.40,10.10.40.50,10.10.40.199,255.255.255.0,6h"
  #     ];
  #     dhcp-option = [
  #       "br0.10,3,10.10.10.1" "br0.10,6,10.10.10.1"
  #       "br0.30,3,10.10.30.1" "br0.30,6,10.10.30.1"
  #       "br0.40,3,10.10.40.1" "br0.40,6,10.10.40.1"
  #     ];
  #     server = [ "1.1.1.1" "9.9.9.9" ];
  #   };
  # };

  # Firewall
  networking.firewall.enable = false;
  networking.nftables.enable = true;

  networking.nftables.ruleset = ''
    define WAN = "enp1s0"
    define WG  = "wgtransport"

    table inet filter {
      chain input {
        type filter hook input priority 0; policy drop;

        ct state established,related accept
        iifname "lo" accept
        ip protocol icmp accept
        ip6 nexthdr ipv6-icmp accept

        # SSH depuis mgmt VLAN10
        iifname "br0.10" tcp dport 22 accept

        # DHCP/DNS
        iifname { "br0.10", "br0.30", "br0.40" } udp dport { 67, 68, 53 } accept
        iifname { "br0.10", "br0.30", "br0.40" } tcp dport 53 accept

        # SSH WAN (rate limit)
        iifname $WAN tcp dport 22 ct state new limit rate 10/minute burst 20 packets accept

        # WireGuard
        iifname $WAN udp dport 51820 accept

        # BGP + VXLAN via WG
        iifname $WG tcp dport 179 accept
        iifname $WG udp dport 4789 accept
      }

      chain forward {
        type filter hook forward priority 0; policy drop;
        ct state established,related accept
        iifname { "br0.10", "br0.20", "br0.30", "br0.40" } oifname $WAN accept
        iifname "br0.10" oifname { "br0.20", "br0.30", "br0.40" } accept
      }

      chain output { type filter hook output priority 0; policy accept; }
    }

    table ip nat {
      chain postrouting {
        type nat hook postrouting priority 100; policy accept;
        oifname $WAN masquerade
      }
    }
  '';

  # SSH
  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    UseDns = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
  ];
  users.users.franck = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # FRR BGP + EVPN
  services.frr = {
    bgpd.enable = true;

    config = ''
      frr defaults traditional
      hostname rtr-noisy
      service integrated-vtysh-config
      log syslog informational

      router bgp 65000
        bgp router-id 10.254.0.11
        bgp cluster-id 10.254.0.11

        neighbor 10.254.0.1 remote-as 65000
        neighbor 10.254.0.1 update-source lo
        neighbor 10.254.0.1 ebgp-multihop 5

        address-family ipv4 unicast
          network 10.254.0.11/32
          neighbor 10.254.0.1 activate
        exit-address-family

        address-family l2vpn evpn
          neighbor 10.254.0.1 activate
          advertise-all-vni
          advertise-svi-ip
        exit-address-family
      !
    '';
  };

  # Packages
  environment.systemPackages = with pkgs; [
    vim git tcpdump frr wireguard-tools iproute2
  ];

  system.stateVersion = "25.11";
}
