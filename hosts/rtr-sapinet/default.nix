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
  
  # Security hardening
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.perf_event_paranoid" = 3;
  };
}