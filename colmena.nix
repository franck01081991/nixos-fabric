{ flake, ... }:
{
  # Configuration Colmena pour le déploiement NixOS Fabric
  
  # Import des configurations externes
  imports = [
    ./external/rtr-noisy-config/default.nix
    ./external/rtr-sapinet-config/default.nix
  ];
  
  # Définition des hôtes à déployer
  colmena = {
    # Configuration globale
    global = {
      # Options de déploiement par défaut
      deployment = {
        # Utiliser les flakes pour le déploiement
        flake = true;
        # Mode dry-run par défaut pour la sécurité
        dryRun = false;
        # Afficher les changements avant application
        showDiff = true;
      };
      
      # Configuration SSH
      ssh = {
        # Utilisateur par défaut pour les connexions
        user = "root";
        # Options SSH
        options = [
          "-o" "ConnectTimeout=10"
          "-o" "ServerAliveInterval=60"
          "-o" "StrictHostKeyChecking=no"
        ];
      };
    };
    
    # Définition des hôtes
    hosts = {
      # Routeur rtr-noisy
      "rtr-noisy" = {
        hostname = "rtr-noisy";
        address = "rtr-noisy.lan";
        
        # Configuration spécifique à cet hôte
        configuration = {
          imports = [
            ./external/rtr-noisy-config/default.nix
            ./external/rtr-noisy-config/hardware-configuration.nix
            ./external/rtr-noisy-config/base-variables.nix
            ./external/rtr-noisy-config/role-variables.nix
          ];
          
          # Rôle de cet hôte dans le fabric
          network-fabric.role = "hybrid";
          
          # Variables spécifiques
          network-fabric.hostname = "rtr-noisy";
          network-fabric.domain = "fabric.local";
        };
        
        # Options de déploiement spécifiques
        deployment = {
          # Activer le déploiement pour cet hôte
          enable = true;
          # Priorité de déploiement
          priority = 10;
        };
      };
      
      # Routeur rtr-sapinet
      "rtr-sapinet" = {
        hostname = "rtr-sapinet";
        address = "rtr-sapinet.lan";
        
        # Configuration spécifique à cet hôte
        configuration = {
          imports = [
            ./external/rtr-sapinet-config/default.nix
            ./external/rtr-sapinet-config/hardware-configuration.nix
            ./external/rtr-sapinet-config/base-variables.nix
            ./external/rtr-sapinet-config/role-variables.nix
          ];
          
          # Rôle de cet hôte dans le fabric
          network-fabric.role = "spine";
          
          # Variables spécifiques
          network-fabric.hostname = "rtr-sapinet";
          network-fabric.domain = "fabric.local";
        };
        
        # Options de déploiement spécifiques
        deployment = {
          # Activer le déploiement pour cet hôte
          enable = true;
          # Priorité de déploiement
          priority = 20;
        };
      };
      
      # Ajoutez d'autres hôtes ici selon le même modèle
      # "host-name" = { ... };
    };
    
    # Groupes d'hôtes pour un déploiement ciblé
    groups = {
      "all" = [ "rtr-noisy" "rtr-sapinet" ];
      "spine" = [ "rtr-sapinet" ];
      "leaf" = [ "rtr-noisy" ];
      "hybrid" = [ "rtr-noisy" ];
      "routers" = [ "rtr-noisy" "rtr-sapinet" ];
    };
  };
}