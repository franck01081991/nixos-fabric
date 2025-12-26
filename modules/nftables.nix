{ config, lib, pkgs, ... }:
{
  networking.firewall.enable = false;
  networking.nftables.enable = true;
}
