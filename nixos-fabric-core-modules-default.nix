{ lib, pkgs, ... }:

{
  imports = [
    ./core/network-fabric.nix
    # Ajouter d'autres modules ici
    # ./networking/*.nix
    # ./security/*.nix
    # ./system/*.nix
  ];
}