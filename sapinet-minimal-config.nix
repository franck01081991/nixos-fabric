{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./sapinet-wireguard.nix
  ];

  # Basic system configuration
  boot.kernelParams = [
    "lockdown=confidentiality"
    "slab_nomerge"
    "pti=on"
  ];

  # Network configuration
  networking.hostName = "sapinet";
  time.timeZone = "Europe/Paris";
  console.keyMap = "fr";

  # Enable SSH
  services.openssh.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    wireguard-tools
    frr
  ];

  # FRR configuration
  services.frr = {
    enable = true;
    zebra = {
      enable = true;
      interface = [ "wgtransport" "lo" ];
    };
    
    ospf = {
      enable = true;
      routerId = "10.254.0.1";
      area = "0";
      networks = [
        "10.254.0.1/32"
        "10.255.0.0/24"
      ];
      passiveInterfaces = [ "wgtransport" ];
    };
    
    bgp = {
      enable = true;
      routerId = "10.254.0.1";
      localAs = 65000;
      neighbors = [
        {
          address = "10.255.0.2";
          remoteAs = 65000;
          ebgpMultihop = 5;
        }
      ];
      networks = [
        "10.254.0.1/32"
        "10.255.0.0/24"
      ];
    };
  };

  # Enable FRR service
  systemd.services.frr = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  # System settings
  system.stateVersion = "25.11";
}
