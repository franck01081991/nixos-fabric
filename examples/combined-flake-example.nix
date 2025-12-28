{ config, lib, pkgs, ... }:

{
  # Exemple complet combinant flake-ansible et flake-secrets
  
  # Module flake-ansible pour le déploiement automatisé
  network-fabric.flake-ansible = {
    enable = true;
    flakePath = ".";
    flakeTargets = [ "rtr-sapinet" "rtr-noisy" ];
    deploymentStrategy = "remote";
    enableVerification = true;
  };
  
  # Module flake-secrets pour la gestion sécurisée
  network-fabric.flake-secrets = {
    enable = true;
    backend = "file";
    
    flakeSecrets = {
      wireguard = {
        enable = true;
      };
      ssh = {
        enable = true;
      };
    };
  };
  
  # Configuration réseau de base
  networking = {
    hostName = "nixos-fabric-node";
    domain = "fabric.local";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };
  
  # Services requis
  environment.systemPackages = with pkgs; [
    ansible
    ansible-lint
    jq
    nix
    bash
    coreutils
    wireguard-tools
    openssh
  ];
  
  # Intégration avec les services système
  systemd.services.ansible-deploy = {
    enable = true;
    script = ''
      ${pkgs.ansible}/bin/ansible-playbook \
        -i /etc/nixos-fabric/ansible/inventory/flake-hosts.ini \
        /etc/nixos-fabric/ansible/playbooks/main.yml
    '';
    wantedBy = [ "multi-user.target" ];
  };
  
  # Configuration de sécurité
  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };
    ssh = {
      enable = true;
      passwordAuthentication = false;
    };
  };
}
