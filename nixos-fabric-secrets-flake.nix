{
  description = "Nixos-Fabric Secrets - Encrypted secrets repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    {
      # Ce repo contient uniquement des secrets chiffrés
      # Pas de outputs NixOS, juste des fichiers à importer
    };
}