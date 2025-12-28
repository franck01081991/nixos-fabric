# Configuration Réseau de Base 🌐

## Configuration BGP Basique

```nix
# Fichier: hosts/bgp-router/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/frr.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "bgp-router";
  networking.domain = "example.com";
  
  # Interface réseau
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "192.168.1.1";
    prefixLength = 24;
  } ];
  
  # Routage IP
  networking.ipv4.forward = true;
  
  # FRR - Configuration BGP
  network-fabric.frr = {
    enable = true;
    
    bgp = {
      enable = true;
      asNumber = 65001;
      routerId = "192.168.1.1";
      
      # Réseaux annoncés
      networks = [
        "192.168.1.0/24"
        "10.0.0.0/8"
      ];
      
      # Voisins BGP
      neighbors = [
        {
          ip = "192.168.1.2";
          remoteAs = 65002;
          description = "Peer Principal";
          password = "secret";
        }
        {
          ip = "192.168.1.3";
          remoteAs = 65003;
          description = "Peer Secondaire";
        }
      ];
      
      # Sécurité BGP
      security = {
        ttlSecurity = true;
        ttlValue = 254;
      };
    };
    
    # OSPF (optionnel)
    ospf = {
      enable = false;
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
      allowedTCP = [ 2222 179 ]; # 179 = BGP
      allowedICMP = true;
    };
  };
}
```

## Configuration OSPF Basique

```nix
# Fichier: hosts/ospf-router/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/frr.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "ospf-router";
  
  # Interfaces réseau
  networking.interfaces = {
    ens18 = {
      ipv4.addresses = [ { address = "192.168.1.1"; prefixLength = 24; } ];
    };
    ens19 = {
      ipv4.addresses = [ { address = "192.168.2.1"; prefixLength = 24; } ];
    };
  };
  
  # FRR - Configuration OSPF
  network-fabric.frr = {
    enable = true;
    
    ospf = {
      enable = true;
      routerId = "192.168.1.1";
      
      # Aires OSPF
      areas = [
        {
          id = "0.0.0.0";
          interfaces = [
            {
              name = "ens18";
              cost = 10;
              networkType = "broadcast";
              priority = 100;
            }
            {
              name = "ens19";
              cost = 20;
              networkType = "broadcast";
            }
          ];
        }
      ];
      
      # Redistribution
      redistribution = [
        {
          protocol = "connected";
          metricType = 2;
          metric = 100;
        }
      ];
    };
    
    # BGP (désactivé)
    bgp = {
      enable = false;
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
      allowedTCP = [ 2222 ];
      allowedICMP = true;
    };
  };
}
```

## Configuration WireGuard Basique

```nix
# Fichier: hosts/wireguard-vpn/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/wireguard.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "wireguard-vpn";
  
  # Interface réseau
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
        
        # MTU optimisé
        mtu = 1420;
        
        # Règles pré/post
        preUp = "iptables -A FORWARD -i wg0 -j ACCEPT";
        postDown = "iptables -D FORWARD -i wg0 -j ACCEPT";
        
        peers = [
          {
            publicKey = "client1-public-key";
            allowedIPs = [ "10.8.0.2/32" ];
            endpoint = "client1.example.com:51820";
            persistentKeepalive = 25;
          }
          {
            publicKey = "client2-public-key";
            allowedIPs = [ "10.8.0.3/32" "192.168.2.0/24" ];
            endpoint = "client2.example.com:51820";
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
    };
    firewall = {
      enable = true;
      allowedTCP = [ 2222 ];
      allowedUDP = [ 51820 ];
      rateLimiting = {
        enable = true;
        rules = [
          {
            name = "wireguard-protection";
            protocol = "udp";
            destinationPort = 51820;
            limit = "10/sec";
          }
        ];
      };
    };
  };
}
```

## Configuration Routeur avec VLANs

```nix
# Fichier: hosts/vlan-router/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/networking.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "vlan-router";
  
  # Interface trunk
  networking.interfaces.ens18.vlanTrunk = true;
  
  # VLANs
  networking.vlans = {
    mgmt = {
      id = 10;
      interfaces = [ "ens18" ];
      ipv4.addresses = [ { address = "10.0.10.1"; prefixLength = 24; } ];
      description = "VLAN Management";
    };
    
    data = {
      id = 20;
      interfaces = [ "ens18" ];
      ipv4.addresses = [ { address = "10.0.20.1"; prefixLength = 24; } ];
      description = "VLAN Data";
    };
    
    voice = {
      id = 30;
      interfaces = [ "ens18" ];
      ipv4.addresses = [ { address = "10.0.30.1"; prefixLength = 24; } ];
      description = "VLAN Voice";
    };
    
    guest = {
      id = 40;
      interfaces = [ "ens18" ];
      ipv4.addresses = [ { address = "10.0.40.1"; prefixLength = 24; } ];
      description = "VLAN Guest";
    };
  };
  
  # Routage inter-VLAN
  networking.ipv4.forward = true;
  
  # Règles de routage inter-VLAN
  network-fabric.networking.interVlanRouting = {
    enable = true;
    rules = [
      {
        sourceVlan = 10; # mgmt
        destinationVlan = 20; # data
        action = "allow";
      }
      {
        sourceVlan = 10; # mgmt
        destinationVlan = 30; # voice
        action = "allow";
      }
      {
        sourceVlan = 20; # data
        destinationVlan = 30; # voice
        action = "allow";
      }
      {
        sourceVlan = 40; # guest
        destinationVlan = 10; # mgmt
        action = "deny";
      }
    ];
  };
  
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
      allowedICMP = true;
    };
  };
}
```

## Configuration avec Bonding

```nix
# Fichier: hosts/bonded-router/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/networking.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "bonded-router";
  
  # Bonding LACP
  networking.bonds.bond0 = {
    interfaces = [ "ens18" "ens19" ];
    mode = "802.3ad";
    miimon = 100;
    lacpRate = "fast";
    ipv4.addresses = [ { address = "192.168.1.1"; prefixLength = 24; } ];
  };
  
  # Configuration FRR
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
          updateSource = "bond0";
        }
      ];
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
      allowedTCP = [ 2222 179 ];
      allowedICMP = true;
    };
  };
}
```

## Configuration Routeur avec NAT

```nix
# Fichier: hosts/nat-router/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/networking.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "nat-router";
  
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
  
  # Route par défaut
  networking.defaultGateway = "203.0.113.1";
  
  # NAT
  networking.nat = {
    enable = true;
    externalInterface = "ens19";
    internalInterfaces = [ "ens18" ];
  };
  
  # Port forwarding
  networking.nat.portForwarding = [
    {
      name = "forward-ssh";
      protocol = "tcp";
      externalPort = 2222;
      internalPort = 22;
      internalIP = "192.168.1.100";
    }
    {
      name = "forward-web";
      protocol = "tcp";
      externalPort = 80;
      internalPort = 80;
      internalIP = "192.168.1.100";
    }
  ];
  
  # Sécurité
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
    };
    firewall = {
      enable = true;
      allowedTCP = [ 2222 80 443 ];
      allowedUDP = [ 123 ];
      allowedICMP = true;
    };
  };
}
```

## Configuration Routeur avec DHCP

```nix
# Fichier: hosts/dhcp-router/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/networking.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "dhcp-router";
  
  # Interface
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "192.168.1.1";
    prefixLength = 24;
  } ];
  
  # DHCP Server
  services.dhcpd = {
    enable = true;
    interfaces = [ "ens18" ];
    
    authoritative = true;
    
    subnets = [
      {
        subnet = "192.168.1.0";
        netmask = "255.255.255.0";
        range = {
          from = "192.168.1.100";
          to = "192.168.1.200";
        };
        options = [
          {
            name = "routers";
            value = "192.168.1.1";
          }
          {
            name = "domain-name-servers";
            value = "8.8.8.8, 8.8.4.4";
          }
          {
            name = "domain-name";
            value = "example.com";
          }
        ];
      }
    ];
    
    # Réservations
    reservations = [
      {
        mac = "00:11:22:33:44:55";
        ip = "192.168.1.50";
        hostName = "server1";
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
      allowedTCP = [ 2222 67 68 ]; # DHCP
      allowedUDP = [ 67 68 ];
      allowedICMP = true;
    };
  };
}
```

## Bonnes Pratiques pour les Configurations Réseau

### 1. Planification

- **Documentez** votre schéma d'adressage
- **Prévoyez** pour la croissance
- **Standardisez** les configurations
- **Étiquetez** les interfaces et câbles

### 2. Sécurité

- **Séparez** les réseaux (management, data, guest)
- **Activez** toujours le pare-feu
- **Limitez** les accès aux équipements réseau
- **Surveillez** le trafic réseau

### 3. Performance

- **Utilisez** le bonding pour la redondance
- **Optimisez** les paramètres MTU
- **Équilibrez** la charge réseau
- **Surveillez** les performances

### 4. Maintenance

- **Sauvegardez** les configurations
- **Documentez** les changements
- **Testez** avant déploiement
- **Mettez à jour** régulièrement

### 5. Dépannage

- **Vérifiez** les logs système
- **Testez** la connectivité de base
- **Isolez** les problèmes
- **Utilisez** des outils comme tcpdump, ping, traceroute

## Exemples Supplémentaires

Voir aussi :

- `examples/example-configuration.nix` - Configuration complète
- `examples/network-security-config.nix` - Sécurité réseau
- Tests dans `tests/integration/fabric/` pour des scénarios réels