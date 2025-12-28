{ config, lib, pkgs, ... }:

{
  # FRR configuration
  services.frr = {
    bgpd.enable = true;

    config = ''
      frr defaults traditional
      hostname sapinet
      service integrated-vtysh-config
      log syslog informational

      router bgp 65000
        bgp router-id 10.254.0.1
        neighbor 10.255.0.2 remote-as 65000
        neighbor 10.255.0.2 update-source wgtransport
        neighbor 10.255.0.2 ebgp-multihop 5

        address-family ipv4 unicast
          network 10.254.0.1/32
          network 10.255.0.0/24
          neighbor 10.255.0.2 activate
        exit-address-family
    '';
  };

  # Enable FRR service
  systemd.services.frr = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };
}
