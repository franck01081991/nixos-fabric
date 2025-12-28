{ config, lib, pkgs, ... }:

{
  # Exemple de configuration pour le module flake-ansible
  network-fabric.flake-ansible = {
    enable = true;
    
    # Chemin vers le flake (peut être un chemin local ou une URL)
    flakePath = ".";
    
    # Cibles flake à gérer
    flakeTargets = [ "rtr-sapinet" "rtr-noisy" "test" ];
    
    # Stratégie de déploiement
    # Options: local, remote, hybrid
    deploymentStrategy = "remote";
    
    # Options de construction Nix
    nixBuildOptions = {
      maxJobs = 4;
      cores = 2;
      sandbox = true;
    };
    
    # Activation de la vérification post-déploiement
    enableVerification = true;
    verificationTimeout = 300; # 5 minutes
  };
  
  # Configuration réseau de base
  networking = {
    hostName = "nixos-fabric-node";
    domain = "fabric.local";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };
  
  # Services requis pour le déploiement
  environment.systemPackages = with pkgs; [
    ansible
    ansible-lint
    jq
    nix
  ];
}
