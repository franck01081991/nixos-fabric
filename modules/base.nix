{ config, lib, pkgs, ... }:
{
  time.timeZone = "Europe/Paris";
  console.keyMap = "fr";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    git vim curl tcpdump iproute2
  ];
}
