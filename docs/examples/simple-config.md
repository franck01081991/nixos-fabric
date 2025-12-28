# Exemple de Configuration Simple 🐒

## Configuration Minimale pour Démarrer

Voici un exemple de configuration minimale pour un routeur NixOS Fabric :

```nix
# Fichier: hosts/mon-routeur/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/networking.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "mon-routeur";
  networking.domain = "example.com";
  
  # Interface réseau
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "192.168.1.1";
    prefixLength = 24;
  } ];
  
  # Routage IP
  networking.ipv4.forward = true;
  
  # Utilisateur
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networking" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3..." ];
  };
  
  # Sécurité SSH
  network-fabric.security.ssh = {
    enable = true;
    port = 2222;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };
  
  # Pare-feu simple
  network-fabric.security.firewall = {
    enable = true;
    allowedTCP = [ 2222 ];
    allowedICMP = true;
  };
  
  # FRR - BGP basique
  network-fabric.frr = {
    enable = true;
    bgp = {
      enable = true;
      asNumber = 65001;
      routerId = "192.168.1.1";
      neighbors = [
        {
          ip = "192.168.1.2";
          remoteAs = 65002;
        }
      ];
    };
  };
}
```

## Configuration WireGuard Simple

```nix
# Fichier: hosts/mon-vpn/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/wireguard.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "mon-vpn";
  
  # WireGuard
  network-fabric.wireguard = {
    enable = true;
    interfaces = [
      {
        name = "wg0";
        privateKeyFile = "/etc/wireguard/private.key";
        port = 51820;
        addresses = [ "10.8.0.1/24" ];
        peers = [
          {
            publicKey = "client-public-key-here";
            allowedIPs = [ "10.8.0.2/32" ];
            endpoint = "client.example.com:51820";
          }
        ];
      }
    ];
  };
  
  # Sécurité
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
    };
    firewall = {
      enable = true;
      allowedTCP = [ 2222 ];
      allowedUDP = [ 51820 ];
    };
  };
}
```

## Configuration Routeur + VPN

```nix
# Fichier: hosts/routeur-vpn/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/networking.nix
    ../../modules/networking/frr.nix
    ../../modules/networking/wireguard.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "routeur-vpn";
  networking.domain = "example.com";
  
  # Interfaces
  networking.interfaces = {
    ens18 = {
      ipv4.addresses = [ { address = "192.168.1.1"; prefixLength = 24; } ];
      description = "LAN Interface";
    };
    ens19 = {
      ipv4.addresses = [ { address = "203.0.113.10"; prefixLength = 24; } ];
      description = "WAN Interface";
    };
  };
  
  # Routage
  networking.ipv4.forward = true;
  networking.defaultGateway = "203.0.113.1";
  
  # WireGuard VPN
  network-fabric.wireguard = {
    enable = true;
    interfaces = [
      {
        name = "wg0";
        privateKeyFile = "/etc/wireguard/private.key";
        port = 51820;
        addresses = [ "10.8.0.1/24" ];
        peers = [
          {
            publicKey = "remote-site-key";
            allowedIPs = [ "10.8.0.2/32" "192.168.2.0/24" ];
            endpoint = "remote.example.com:51820";
            persistentKeepalive = 25;
          }
        ];
      }
    ];
  };
  
  # BGP
  network-fabric.frr = {
    enable = true;
    bgp = {
      enable = true;
      asNumber = 65001;
      routerId = "192.168.1.1";
      networks = [ "192.168.1.0/24" "10.8.0.0/24" ];
      neighbors = [
        {
          ip = "203.0.113.2";
          remoteAs = 65002;
          description = "ISP Peer";
        }
      ];
    };
  };
  
  # Sécurité
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
      allowUsers = [ "admin" ];
    };
    firewall = {
      enable = true;
      allowedTCP = [ 2222 80 443 ];
      allowedUDP = [ 51820 ];
      enableLogging = true;
    };
  };
  
  # Services
  services.openssh.enable = true;
  services.ntp.enable = true;
}
```

## Configuration avec VLANs

```nix
# Fichier: hosts/routeur-vlan/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/networking.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "routeur-vlan";
  
  # Interface trunk
  networking.interfaces.ens18.vlanTrunk = true;
  
  # VLANs
  networking.vlans = {
    vlan10 = {
      id = 10;
      interfaces = [ "ens18" ];
      ipv4.addresses = [ { address = "10.0.10.1"; prefixLength = 24; } ];
      description = "VLAN Management";
    };
    
    vlan20 = {
      id = 20;
      interfaces = [ "ens18" ];
      ipv4.addresses = [ { address = "10.0.20.1"; prefixLength = 24; } ];
      description = "VLAN Data";
    };
    
    vlan30 = {
      id = 30;
      interfaces = [ "ens18" ];
      ipv4.addresses = [ { address = "10.0.30.1"; prefixLength = 24; } ];
      description = "VLAN Voice";
    };
  };
  
  # Routage inter-VLAN
  networking.ipv4.forward = true;
  
  # Sécurité
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
    };
    firewall = {
      enable = true;
      allowedTCP = [ 2222 ];
      allowedICMP = true;
    };
  };
}
```

## Configuration avec Fail2Ban

```nix
# Fichier: hosts/routeur-secure/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/networking.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "routeur-secure";
  
  # Interface
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "192.168.1.1";
    prefixLength = 24;
  } ];
  
  # Sécurité avancée
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
      passwordAuthentication = false;
      maxAuthTries = 3;
    };
    
    firewall = {
      enable = true;
      allowedTCP = [ 2222 80 443 ];
      allowedUDP = [ 123 ];
      enableLogging = true;
    };
    
    fail2ban = {
      enable = true;
      jails = {
        sshd = {
          enable = true;
          port = "2222";
          maxretry = 3;
          bantime = 3600;
        };
      };
    };
    
    hardening = {
      enable = true;
      kernel = {
        randomizeVaSpace = true;
        kptrRestrict = 2;
      };
    };
  };
  
  # Services
  services.openssh.enable = true;
  services.ntp.enable = true;
}
```

## Configuration pour le Développement

```nix
# Fichier: hosts/dev-vm/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/networking.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base pour le développement
  networking.hostName = "dev-vm";
  
  # Interface simple
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "192.168.122.100";
    prefixLength = 24;
  } ];
  
  # Utilisateur de développement
  users.users.developer = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3..." ];
  };
  
  # Sécurité simplifiée pour le dev
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 22;
      passwordAuthentication = false;
    };
    firewall = {
      enable = true;
      allowedTCP = [ 22 80 443 8080 3000 ];
      allowedICMP = true;
    };
  };
  
  # Outils de développement
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    tmux
    curl
    wget
    nmap
    tcpdump
    wireguard-tools
  ];
  
  # Services utiles
  services = {
    openssh.enable = true;
    nginx.enable = true;
    docker.enable = true;
  };
}
```

## Bonnes Pratiques pour les Exemples

### 1. Commencez Simple

- Utilisez une configuration minimale au début
- Ajoutez des fonctionnalités progressivement
- Testez chaque changement

### 2. Sécurité par Défaut

- Activez toujours le module de sécurité
- Changez le port SSH par défaut
- Désactivez l'authentification par mot de passe

### 3. Documentation

- Documentez vos configurations
- Utilisez des commentaires clairs
- Notez les dépendances et prérequis

### 4. Tests

- Testez en environnement isolé
- Validez les configurations avant déploiement
- Surveillez après déploiement

### 5. Évolutivité

- Structurez pour la croissance
- Utilisez des modules séparés
- Prévoyez pour l'ajout de nouveaux services

## Exemples Supplémentaires

Voir aussi :

- `examples/example-configuration.nix` - Configuration de base complète
- `examples/network-security-config.nix` - Configuration sécurité réseau
- `examples/security-example.nix` - Exemple de sécurité
- `examples/security-improved-example.nix` - Configuration sécurité avancée