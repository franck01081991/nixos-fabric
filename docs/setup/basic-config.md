# Configuration de Base 🛠️

## Structure du Projet

```
nixos-fabric/
├── hosts/                      # Configurations des hôtes
│   ├── production/             # Environnement de production
│   ├── development/            # Environnement de développement
│   └── test-vm/                # Machine de test
├── modules/                    # Modules NixOS
│   ├── networking/             # Modules réseau
│   ├── security/               # Modules sécurité
│   └── integration/            # Modules d'intégration
├── examples/                   # Exemples de configuration
├── docs/                       # Documentation
└── scripts/                    # Scripts utilitaires
```

## Configuration d'un Hôte

### 1. Créer un nouveau dossier d'hôte

```bash
mkdir -p hosts/mon-serveur
cd hosts/mon-serveur
```

### 2. Créer hardware-configuration.nix

```nix
# Fichier: hardware-configuration.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/networking.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration matérielle spécifique
  boot.initrd.postDeviceCommands = "";
  hardware.cpu.intel.updateMicrocode = true;
}
```

### 3. Créer configuration.nix

```nix
# Fichier: configuration.nix
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  
  # Configuration réseau de base
  networking.hostName = "mon-serveur";
  networking.domain = "example.com";
  
  # Configuration utilisateur
  users.users.franck = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networking" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3..." ];
  };
  
  # Services de base
  services.openssh.enable = true;
  services.ntp.enable = true;
  
  # Import des modules spécifiques
  imports = [
    ../../modules/networking/frr.nix
    ../../modules/networking/wireguard.nix
    ../../modules/security/firewall.nix
  ];
}
```

## Configuration Réseau

### Interfaces Réseau

```nix
{ config, pkgs, ... }:
{
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "192.168.1.10";
    prefixLength = 24;
  } ];
  
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
}
```

### VLANs

```nix
{ config, pkgs, ... }:
{
  networking.vlans.vlan10 = {
    id = 10;
    interfaces = [ "ens18" ];
    ipv4.addresses = [ {
      address = "10.0.10.1";
      prefixLength = 24;
    } ];
  };
}
```

### Ponts (Bridges)

```nix
{ config, pkgs, ... }:
{
  networking.bridges.br0 = {
    interfaces = [ "ens18" "ens19" ];
    ipv4.addresses = [ {
      address = "192.168.1.1";
      prefixLength = 24;
    } ];
  };
}
```

## Configuration FRR (Routing)

### BGP Basique

```nix
{ config, pkgs, ... }:
{
  network-fabric.frr = {
    enable = true;
    bgp = {
      enable = true;
      asNumber = 65001;
      routerId = "192.168.1.1";
      networks = [
        "192.168.1.0/24"
        "10.0.0.0/8"
      ];
      neighbors = [
        {
          ip = "192.168.1.2";
          remoteAs = 65002;
          description = "Peer avec le routeur voisin";
        }
      ];
    };
  };
}
```

### OSPF

```nix
{ config, pkgs, ... }:
{
  network-fabric.frr = {
    enable = true;
    ospf = {
      enable = true;
      routerId = "192.168.1.1";
      areas = [
        {
          id = "0.0.0.0";
          interfaces = [
            {
              name = "ens18";
              cost = 10;
              networkType = "broadcast";
            }
          ];
        }
      ];
    };
  };
}
```

## Configuration WireGuard

### Interface Simple

```nix
{ config, pkgs, ... }:
{
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
            publicKey = "peer-public-key-here";
            allowedIPs = [ "10.8.0.2/32" ];
            endpoint = "example.com:51820";
            persistentKeepalive = 25;
          }
        ];
      }
    ];
  };
}
```

### Configuration Avancée

```nix
{ config, pkgs, ... }:
{
  network-fabric.wireguard = {
    enable = true;
    interfaces = [
      {
        name = "wg0";
        privateKeyFile = "/etc/wireguard/private.key";
        port = 51820;
        addresses = [ "10.8.0.1/24" ];
        mtu = 1420;
        preUp = "iptables -A FORWARD -i wg0 -j ACCEPT";
        postDown = "iptables -D FORWARD -i wg0 -j ACCEPT";
        peers = [
          {
            publicKey = "peer1-public-key";
            allowedIPs = [ "10.8.0.2/32" "192.168.2.0/24" ];
            endpoint = "peer1.example.com:51820";
            persistentKeepalive = 25;
          }
          {
            publicKey = "peer2-public-key";
            allowedIPs = [ "10.8.0.3/32" ];
            endpoint = "peer2.example.com:51820";
          }
        ];
      }
    ];
  };
}
```

## Configuration Sécurité

### Pare-feu de Base

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.firewall = {
    enable = true;
    defaultAction = "drop";
    allowedTCP = [ 22 80 443 51820 ];
    allowedUDP = [ 51820 123 ];
    allowedICMP = true;
    enableLogging = true;
    logLimit = "10/sec";
  };
}
```

### Règles Avancées

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.firewall = {
    enable = true;
    rules = [
      {
        name = "allow-ssh";
        action = "accept";
        protocol = "tcp";
        destinationPort = 22;
        sourceIP = "192.168.1.0/24";
      }
      {
        name = "allow-http";
        action = "accept";
        protocol = "tcp";
        destinationPort = 80;
      }
      {
        name = "allow-wireguard";
        action = "accept";
        protocol = "udp";
        destinationPort = 51820;
      }
    ];
  };
}
```

### Sécurité SSH

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.ssh = {
    enable = true;
    port = 2222;
    passwordAuthentication = false;
    permitRootLogin = "no";
    allowUsers = [ "franck" "admin" ];
    allowGroups = [ "wheel" ];
    maxAuthTries = 3;
    loginGraceTime = 30;
    banner = "";
  };
}
```

## Bonnes Pratiques

### 1. Modularité

- **Séparez** la configuration en modules logiques
- **Import** les modules dont vous avez besoin
- **Évitez** les configurations monolithiques

### 2. Sécurité

- **Activez toujours** le module de sécurité
- **Changez le port SSH** par défaut
- **Désactivez** l'authentification par mot de passe
- **Limitez** les accès utilisateurs

### 3. Réseau

- **Documentez** vos schémas d'adressage
- **Testez** les configurations avant déploiement
- **Surveillez** les performances réseau
- **Sauvegardez** les configurations

### 4. Déploiement

- **Testez** en environnement de développement
- **Validez** avec les scripts de test
- **Déployez** progressivement en production
- **Surveillez** après déploiement

## Exemples Complets

Voir le dossier `examples/` pour des configurations complètes et prêtes à l'emploi :

- `examples/example-configuration.nix` - Configuration de base
- `examples/network-security-config.nix` - Configuration sécurité réseau
- `examples/security-example.nix` - Exemple de sécurité complet