# Minimal hardware configuration for test VM
# 
# This configuration is used for testing purposes only
# and provides basic hardware settings for the test environment.

{ config, pkgs, lib, ... }:

{
  # Basic hardware configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.postDeviceCommands = "";
  };
  
  # Filesystem configuration
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
  
  # Swap configuration
  swapDevices = [ {
    device = "/dev/sda2";
  } ];
  
  # Network configuration
  networking = {
    hostId = "00000000";
    useDHCP = lib.mkForce true;
  };
  
  # Basic system settings
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}