{ config, lib, pkgs, ... }:
{
  # Hardware-specific configuration for noisy-edge1
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network interfaces
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.enable = true;

  # Hardware-specific settings only
  # lanPorts and wanIf are defined in variables.nix
}
