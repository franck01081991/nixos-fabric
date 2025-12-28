{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./sapinet-wireguard.nix
    ./sapinet-frr-config.nix
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

  # Bootloader configuration
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    mirroredBoots = true;
  };

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

  # System settings
  system.stateVersion = "25.11";
}
