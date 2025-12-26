{ config, lib, pkgs, ... }:

{
  # Base system configuration
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    wireguard-tools
    frr
    apparmor-utils
  ];
  
  # Users configuration
  users.users.franck = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "networking" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
    ];
  };
  
  # System configuration
  system.stateVersion = "25.11";
  console.keyMap = "fr";
}