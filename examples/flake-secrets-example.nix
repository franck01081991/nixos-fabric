{ config, lib, pkgs, ... }:

{
  # Exemple de configuration pour le module flake-secrets
  network-fabric.flake-secrets = {
    enable = true;
    
    # Choix du backend de stockage des secrets
    # Options: file, age, sops, vault
    backend = "file";
    
    # Configuration du backend fichier
    fileBackend = {
      secretsPath = "./secrets";
      permissions = "0600";
      owner = "root";
      group = "root";
    };
    
    # Configuration spécifique aux secrets du fabric
    flakeSecrets = {
      wireguard = {
        enable = true;
        # Les clés seront générées automatiquement si elles n'existent pas
        privateKeyPath = "/etc/nixos-fabric/secrets/wireguard/private.key";
        publicKeyPath = "/etc/nixos-fabric/secrets/wireguard/public.key";
      };
      
      ssh = {
        enable = true;
        privateKeyPath = "/etc/nixos-fabric/secrets/ssh/id_ed25519";
        publicKeyPath = "/etc/nixos-fabric/secrets/ssh/id_ed25519.pub";
      };
      
      # Tokens API (exemple)
      apiTokens = {
        monitoringToken = "exemple-token-monitoring";
        githubToken = "exemple-token-github";
      };
    };
    
    # Options de déploiement
    deploySecrets = true;
    secretPermissions = "0600";
  };
  
  # Configuration réseau de base
  networking = {
    hostName = "nixos-fabric-node";
    domain = "fabric.local";
  };
  
  # Services requis
  environment.systemPackages = with pkgs; [
    bash
    coreutils
    wireguard-tools
    openssh
  ];
}
