# Base Host Role
# 
# This role provides common configuration that applies to all hosts
# including basic packages, users, and system settings.

{ config, lib, pkgs, ... }:

{
  # Common packages for all hosts
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    htop
    tmux
    wireguard-tools
    frr
  ];

  # Common users
  users.users.franck = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "" ];
  };

  # Common system settings
  system.stateVersion = "25.11";
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;

  # Common environment
  environment.sessionVariables = {
    EDITOR = "vim";
    PAGER = "less";
  };

  # Common services
  services.ntp = {
    enable = true;
    servers = [ "pool.ntp.org" ];
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/5 * * * * root /run/current-system/sw/bin/nix-collect-garbage -d"
    ];
  };

  # Common security settings
  security.sudo.wheelNeedsPassword = false;

  # Common directories
  system.activationScripts.createDirectories = ''
    mkdir -p /etc/nixos-fabric
    mkdir -p /var/log/nixos-fabric
    chown root:root /etc/nixos-fabric
    chmod 750 /etc/nixos-fabric
  '';
}