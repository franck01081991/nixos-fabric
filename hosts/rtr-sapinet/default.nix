{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./base-variables.nix
    ./role-variables.nix
    ../default-ansible.nix
  ];

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.sandbox = false;

  # Kernel parameters
  boot.kernelParams = [
    "lockdown=confidentiality"
    "slab_nomerge"
    "pti=on"
  ];

  # Fix systemd-networkd credentials issue
  systemd.services.systemd-networkd.serviceConfig = {
    LoadCredential = lib.mkForce [ ];
    LoadCredentialEncrypted = lib.mkForce [ ];
    SetCredential = lib.mkForce [ ];
    SetCredentialEncrypted = lib.mkForce [ ];
  };

  # System services
  services.journald.extraConfig = ''
    Storage=persistent
    Compress=yes
    SystemMaxUse=512M
    RuntimeMaxUse=128M
    SystemMaxFileSize=64M
    RateLimitIntervalSec=30s
    RateLimitBurst=1000
  '';

  network-fabric.security-improved.apparmor.enable = true;
  network-fabric.security-improved.auditd.enable = true;
}