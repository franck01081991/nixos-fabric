# Configuration WireGuard Simple 🔐

## Configuration WireGuard de Base

```nix
# Fichier: hosts/wireguard-server/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/wireguard.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "wireguard-server";
  networking.domain = "example.com";
  
  # Interface réseau publique
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "203.0.113.10";
    prefixLength = 24;
  } ];
  
  # Configuration WireGuard
  network-fabric.wireguard = {
    enable = true;
    
    interfaces = [
      {
        name = "wg0";
        privateKeyFile = "/etc/wireguard/private.key";
        port = 51820;
        addresses = [ "10.8.0.1/24" ];
        
        # MTU optimisé pour éviter la fragmentation
        mtu = 1420;
        
        # Règles pré/post pour le routage
        preUp = "iptables -A FORWARD -i wg0 -j ACCEPT";
        postDown = "iptables -D FORWARD -i wg0 -j ACCEPT";
        
        peers = [
          {
            publicKey = "client1-public-key-here";
            allowedIPs = [ "10.8.0.2/32" ];
            endpoint = "client1.example.com:51820";
            persistentKeepalive = 25;
          }
          {
            publicKey = "client2-public-key-here";
            allowedIPs = [ "10.8.0.3/32" "192.168.2.0/24" ];
            endpoint = "client2.example.com:51820";
          }
        ];
      }
    ];
  };
  
  # Routage IP
  networking.ipv4.forward = true;
  
  # Sécurité
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
      passwordAuthentication = false;
    };
    
    firewall = {
      enable = true;
      allowedTCP = [ 2222 80 443 ];
      allowedUDP = [ 51820 ];
      
      # Protection contre les attaques
      rateLimiting = {
        enable = true;
        rules = [
          {
            name = "wireguard-protection";
            protocol = "udp";
            destinationPort = 51820;
            limit = "10/sec";
            burst = 20;
          }
          {
            name = "ssh-protection";
            protocol = "tcp";
            destinationPort = 2222;
            limit = "5/minute";
            burst = 10;
          }
        ];
      };
    };
  };
  
  # Services
  services.openssh.enable = true;
  services.ntp.enable = true;
}
```

## Configuration WireGuard avec BGP

```nix
# Fichier: hosts/wireguard-bgp/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/wireguard.nix
    ../../modules/networking/frr.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "wireguard-bgp";
  
  # Interface publique
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "203.0.113.10";
    prefixLength = 24;
  } ];
  
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
            publicKey = "peer-public-key";
            allowedIPs = [ "10.8.0.2/32" ];
            endpoint = "peer.example.com:51820";
            persistentKeepalive = 25;
          }
        ];
      }
    ];
  };
  
  # BGP sur WireGuard
  network-fabric.frr = {
    enable = true;
    bgp = {
      enable = true;
      asNumber = 65001;
      routerId = "10.8.0.1";
      
      neighbors = [
        {
          ip = "10.8.0.2";
          remoteAs = 65002;
          description = "BGP Peer via WireGuard";
          updateSource = "wg0";
          
          # Sécurité BGP
          password = "secret";
          ttlSecurity = true;
          ttlValue = 254;
        }
      ];
    };
  };
  
  # Routage
  networking.ipv4.forward = true;
  
  # Sécurité
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
    };
    firewall = {
      enable = true;
      allowedTCP = [ 2222 179 ]; # 179 = BGP
      allowedUDP = [ 51820 ];
    };
  };
}
```

## Configuration WireGuard avec NAT

```nix
# Fichier: hosts/wireguard-nat/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/wireguard.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "wireguard-nat";
  
  # Interfaces
  networking.interfaces = {
    ens18 = {
      ipv4.addresses = [ { address = "203.0.113.10"; prefixLength = 24; } ];
      description = "WAN Interface";
    };
    ens19 = {
      ipv4.addresses = [ { address = "192.168.1.1"; prefixLength = 24; } ];
      description = "LAN Interface";
    };
  };
  
  # Route par défaut
  networking.defaultGateway = "203.0.113.1";
  
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
            publicKey = "remote-client-key";
            allowedIPs = [ "10.8.0.2/32" ];
            endpoint = "client.example.com:51820";
          }
        ];
      }
    ];
  };
  
  # NAT pour WireGuard et LAN
  networking.nat = {
    enable = true;
    externalInterface = "ens18";
    internalInterfaces = [ "ens19" "wg0" ];
  };
  
  # Routage
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
      allowedUDP = [ 51820 ];
    };
  };
}
```

## Configuration WireGuard avec VLANs

```nix
# Fichier: hosts/wireguard-vlan/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/wireguard.nix
    ../../modules/networking/networking.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "wireguard-vlan";
  
  # Interface trunk
  networking.interfaces.ens18.vlanTrunk = true;
  
  # VLANs
  networking.vlans = {
    mgmt = {
      id = 10;
      interfaces = [ "ens18" ];
      ipv4.addresses = [ { address = "10.0.10.1"; prefixLength = 24; } ];
    };
    data = {
      id = 20;
      interfaces = [ "ens18" ];
      ipv4.addresses = [ { address = "10.0.20.1"; prefixLength = 24; } ];
    };
  };
  
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
            publicKey = "remote-site-key";
            allowedIPs = [ "10.8.0.2/32" "10.0.20.0/24" ];
            endpoint = "remote.example.com:51820";
          }
        ];
      }
    ];
  };
  
  # Routage
  networking.ipv4.forward = true;
  
  # Sécurité
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
      allowedIPs = [ "10.0.10.0/24" ]; # Seulement depuis VLAN mgmt
    };
    firewall = {
      enable = true;
      allowedTCP = [ 2222 ];
      allowedUDP = [ 51820 ];
    };
  };
}
```

## Configuration WireGuard avec Fail2Ban

```nix
# Fichier: hosts/wireguard-fail2ban/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/wireguard.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "wireguard-fail2ban";
  
  # Interface
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "203.0.113.10";
    prefixLength = 24;
  } ];
  
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
            publicKey = "client-key";
            allowedIPs = [ "10.8.0.2/32" ];
            endpoint = "client.example.com:51820";
          }
        ];
      }
    ];
  };
  
  # Sécurité avec Fail2Ban
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
      passwordAuthentication = false;
    };
    
    firewall = {
      enable = true;
      allowedTCP = [ 2222 ];
      allowedUDP = [ 51820 ];
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
        
        # Protection WireGuard (si disponible)
        wireguard = {
          enable = true;
          port = "51820";
          protocol = "udp";
          maxretry = 5;
          bantime = 1800;
        };
      };
    };
  };
}
```

## Configuration WireGuard avec Monitoring

```nix
# Fichier: hosts/wireguard-monitoring/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/wireguard.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "wireguard-monitoring";
  
  # Interface
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "203.0.113.10";
    prefixLength = 24;
  } ];
  
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
            publicKey = "client-key";
            allowedIPs = [ "10.8.0.2/32" ];
            endpoint = "client.example.com:51820";
            persistentKeepalive = 25;
          }
        ];
      }
    ];
  };
  
  # Monitoring
  services.netdata = {
    enable = true;
    port = 19999;
    
    network = {
      enable = true;
      interfaces = [ "ens18" "wg0" ];
    };
  };
  
  # Sécurité
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
    };
    firewall = {
      enable = true;
      allowedTCP = [ 2222 19999 ]; # Netdata
      allowedUDP = [ 51820 ];
    };
  };
}
```

## Bonnes Pratiques pour WireGuard

### 1. Configuration

- **Utilisez** toujours des clés fortes
- **Changez** le port par défaut (51820)
- **Activez** persistent keepalive pour les connexions stables
- **Optimisez** le MTU pour éviter la fragmentation
- **Limitez** les IP autorisées avec allowedIPs

### 2. Sécurité

- **Activez** le pare-feu pour protéger le port WireGuard
- **Configurez** le rate limiting pour éviter les attaques
- **Utilisez** des clés différentes pour chaque pair
- **Rotatez** les clés régulièrement
- **Surveillez** les connexions actives

### 3. Performance

- **Ajustez** le MTU en fonction de votre réseau
- **Activez** le persistent keepalive pour les NAT
- **Surveillez** la latence et le débit
- **Optimisez** les paramètres de cryptographie
- **Testez** avec différents algorithmes

### 4. Routage

- **Configurez** correctement le routage IP
- **Activez** le forwarding si nécessaire
- **Testez** la connectivité entre les pairs
- **Vérifiez** les routes ajoutées automatiquement
- **Documentez** votre schéma de routage

### 5. Monitoring

- **Surveillez** les interfaces WireGuard
- **Vérifiez** les statistiques de trafic
- **Journalisez** les connexions
- **Configurez** des alertes pour les problèmes
- **Utilisez** des outils comme wg-show et netdata

## Commandes Utiles

### Vérification de WireGuard

```bash
# Voir l'état des interfaces WireGuard
sudo wg show

# Voir l'état détaillé
sudo wg show all

# Voir les statistiques
sudo wg show wg0 transfer

# Vérifier la configuration
sudo wg showconf wg0
```

### Dépannage

```bash
# Vérifier les logs
sudo journalctl -u wg-quick@wg0

# Tester la connectivité
ping 10.8.0.2

# Vérifier le routage
ip route show

# Tester le MTU
ping -M do -s 1400 10.8.0.2
```

### Gestion des Clés

```bash
# Générer une nouvelle paire de clés
wg genkey | tee private.key | wg pubkey > public.key

# Afficher la clé publique
cat public.key

# Afficher la clé privée
sudo cat /etc/wireguard/private.key
```

## Exemples Supplémentaires

Voir aussi :

- `examples/example-configuration.nix` - Configuration complète
- `examples/network-security-config.nix` - Sécurité réseau
- Tests dans `tests/integration/fabric/wireguard-*.nix` pour des scénarios réels