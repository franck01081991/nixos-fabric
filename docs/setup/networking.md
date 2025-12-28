# Configuration Réseau Avancée 🌐

## Table des Matières

- [Configuration Multi-Interfaces](#configuration-multi-interfaces)
- [Routing Avancé](#routing-avancé)
- [VLANs et Trunking](#vlans-et-trunking)
- [Bonding et Agrégation](#bonding-et-agrégation)
- [Configuration BGP Avancée](#configuration-bgp-avancée)
- [Configuration OSPF Avancée](#configuration-ospf-avancée)
- [Intégration WireGuard et BGP](#intégration-wireguard-et-bgp)
- [Quality of Service (QoS)](#quality-of-service-qos)
- [Monitoring Réseau](#monitoring-réseau)

## Configuration Multi-Interfaces

### Plusieurs Interfaces avec Différents Rôles

```nix
{ config, pkgs, ... }:
{
  networking.interfaces = {
    ens18 = {
      ipv4.addresses = [ { address = "192.168.1.1"; prefixLength = 24; } ];
      description = "Interface Management";
    };
    
    ens19 = {
      ipv4.addresses = [ { address = "10.0.0.1"; prefixLength = 24; } ];
      description = "Interface Data";
    };
    
    ens20 = {
      ipv4.addresses = [ { address = "172.16.0.1"; prefixLength = 24; } ];
      description = "Interface Backup";
    };
  };
  
  # Routage entre interfaces
  networking.ipv4.forward = true;
}
```

## Routing Avancé

### Routage Statique avec Métriques

```nix
{ config, pkgs, ... }:
{
  networking.routes = [
    {
      destination = "192.168.2.0/24";
      via = "192.168.1.2";
      metric = 100;
    }
    {
      destination = "10.1.0.0/16";
      via = "10.0.0.2";
      metric = 50;
    }
  ];
}
```

### Routage Basé sur les Politiques (PBR)

```nix
{ config, pkgs, ... }:
{
  networking.policyRouting = {
    enable = true;
    tables = [
      {
        id = 100;
        name = "backup";
        rules = [
          {
            from = "192.168.1.100";
            table = 100;
          }
        ];
        routes = [
          {
            destination = "0.0.0.0/0";
            via = "172.16.0.2";
          }
        ];
      }
    ];
  };
}
```

## VLANs et Trunking

### Configuration VLAN Complète

```nix
{ config, pkgs, ... }:
{
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
  
  # Configuration trunk
  networking.interfaces.ens18.vlanTrunk = true;
}
```

### Routage Inter-VLAN

```nix
{ config, pkgs, ... }:
{
  network-fabric.networking.interVlanRouting = {
    enable = true;
    rules = [
      {
        sourceVlan = 10;
        destinationVlan = 20;
        action = "allow";
      }
      {
        sourceVlan = 10;
        destinationVlan = 30;
        action = "allow";
      }
    ];
  };
}
```

## Bonding et Agrégation

### Configuration Bonding (LACP)

```nix
{ config, pkgs, ... }:
{
  networking.bonds.bond0 = {
    interfaces = [ "ens18" "ens19" ];
    mode = "802.3ad";
    miimon = 100;
    lacpRate = "fast";
    ipv4.addresses = [ { address = "192.168.1.1"; prefixLength = 24; } ];
  };
}
```

### Configuration Active-Backup

```nix
{ config, pkgs, ... }:
{
  networking.bonds.bond0 = {
    interfaces = [ "ens18" "ens19" ];
    mode = "active-backup";
    primary = "ens18";
    miimon = 100;
    ipv4.addresses = [ { address = "192.168.1.1"; prefixLength = 24; } ];
  };
}
```

## Configuration BGP Avancée

### BGP avec Plusieurs Voisins

```nix
{ config, pkgs, ... }:
{
  network-fabric.frr.bgp = {
    enable = true;
    asNumber = 65001;
    routerId = "192.168.1.1";
    
    # Configuration globale
    global = {
      logNeighborChanges = true;
      gracefulRestart = true;
      gracefulRestartTime = 120;
    };
    
    # Réseaux annoncés
    networks = [
      "192.168.1.0/24"
      "10.0.0.0/8"
      "172.16.0.0/16"
    ];
    
    # Voisins BGP
    neighbors = [
      {
        ip = "192.168.1.2";
        remoteAs = 65002;
        description = "Peer Principal";
        password = "secret";
        ttlSecurity = true;
        ttlValue = 254;
        prefixListIn = "PL-IN";
        prefixListOut = "PL-OUT";
      }
      {
        ip = "192.168.1.3";
        remoteAs = 65003;
        description = "Peer Secondaire";
        password = "secret";
        ttlSecurity = true;
      }
    ];
    
    # Listes de préfixes
    prefixLists = {
      "PL-IN" = [
        { network = "0.0.0.0/0"; action = "permit"; }
      ];
      "PL-OUT" = [
        { network = "192.168.1.0/24"; action = "permit"; }
        { network = "10.0.0.0/8"; action = "permit"; }
      ];
    };
    
    # Communautés BGP
    communities = {
      "NO_EXPORT" = 65535;
      "NO_ADVERTISE" = 65534;
    };
  };
}
```

### BGP avec Route Reflection

```nix
{ config, pkgs, ... }:
{
  network-fabric.frr.bgp = {
    enable = true;
    asNumber = 65001;
    routerId = "192.168.1.1";
    
    # Configuration comme route reflector
    routeReflector = {
      enable = true;
      clusterId = "192.168.1.1";
      clients = [ "192.168.1.10" "192.168.1.11" ];
    };
    
    # Voisins
    neighbors = [
      {
        ip = "192.168.1.10";
        remoteAs = 65001;
        routeReflectorClient = true;
      }
      {
        ip = "192.168.1.11";
        remoteAs = 65001;
        routeReflectorClient = true;
      }
    ];
  };
}
```

## Configuration OSPF Avancée

### OSPF Multi-Area

```nix
{ config, pkgs, ... }:
{
  network-fabric.frr.ospf = {
    enable = true;
    routerId = "192.168.1.1";
    
    # Configuration globale
    global = {
      referenceBandwidth = 1000;
      autoCost = true;
      passiveInterfaces = [ "lo" ];
    };
    
    # Aires OSPF
    areas = [
      {
        id = "0.0.0.0";
        type = "normal";
        interfaces = [
          {
            name = "ens18";
            cost = 10;
            networkType = "broadcast";
            priority = 100;
          }
        ];
        ranges = [
          { network = "192.168.1.0/24"; advertise = false; }
        ];
      }
      {
        id = "0.0.0.1";
        type = "stub";
        interfaces = [
          {
            name = "ens19";
            cost = 50;
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
      {
        protocol = "static";
        metricType = 2;
        metric = 200;
      }
    ];
  };
}
```

### OSPF avec Authentification

```nix
{ config, pkgs, ... }:
{
  network-fabric.frr.ospf = {
    enable = true;
    routerId = "192.168.1.1";
    
    areas = [
      {
        id = "0.0.0.0";
        interfaces = [
          {
            name = "ens18";
            authentication = {
              enable = true;
              type = "md5";
              keyId = 1;
              key = "secret";
            };
          }
        ];
      }
    ];
  };
}
```

## Intégration WireGuard et BGP

### Configuration Complète WireGuard + BGP

```nix
{ config, pkgs, ... }:
{
  imports = [
    ./modules/networking/wireguard.nix
    ./modules/networking/frr.nix
  ];
  
  # Configuration WireGuard
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
  
  # Configuration BGP sur WireGuard
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
          description = "Peer via WireGuard";
          updateSource = "wg0";
        }
      ];
    };
  };
  
  # Routage entre interfaces
  networking.ipv4.forward = true;
}
```

## Quality of Service (QoS)

### Configuration QoS Basique

```nix
{ config, pkgs, ... }:
{
  network-fabric.qos = {
    enable = true;
    interfaces = [ "ens18" ];
    
    classes = [
      {
        name = "voip";
        priority = 1;
        rate = "10mbit";
        ceil = "10mbit";
        match = {
          protocol = "udp";
          ports = [ 5060 10000 20000 ];
        };
      }
      {
        name = "video";
        priority = 2;
        rate = "20mbit";
        ceil = "30mbit";
        match = {
          protocol = "udp";
          ports = [ 1234 5678 ];
        };
      }
      {
        name = "default";
        priority = 3;
        rate = "50mbit";
        ceil = "100mbit";
      }
    ];
  };
}
```

## Monitoring Réseau

### Configuration SNMP

```nix
{ config, pkgs, ... }:
{
  services.snmpd = {
    enable = true;
    community = "public";
    location = "Datacenter Rack A";
    contact = "admin@example.com";
    
    interfaces = [ "ens18" "ens19" "lo" ];
    
    # Accès autorisé
    allowedIPs = [ "192.168.1.0/24" "10.0.0.0/8" ];
  };
}
```

### Configuration Netdata

```nix
{ config, pkgs, ... }:
{
  services.netdata = {
    enable = true;
    port = 19999;
    
    # Configuration réseau
    network = {
      enable = true;
      interfaces = [ "ens18" "ens19" "wg0" ];
    };
    
    # Alertes
    alerts = {
      enable = true;
      email = "admin@example.com";
    };
  };
}
```

## Bonnes Pratiques Réseau

### 1. Sécurité

- **Isolez** toujours les interfaces de management
- **Activez** l'authentification pour les protocoles de routing
- **Limitez** les accès aux interfaces réseau
- **Surveillez** le trafic réseau

### 2. Performance

- **Équilibrez** la charge avec le bonding
- **Optimisez** les routes avec des métriques appropriées
- **Surveillez** la latence et la perte de paquets
- **Ajustez** les paramètres MTU pour les VPN

### 3. Disponibilité

- **Utilisez** plusieurs chemins avec BGP
- **Configurez** des routes de secours
- **Testez** les basculements automatiques
- **Documentez** les procédures de récupération

### 4. Monitoring

- **Activez** SNMP pour le monitoring
- **Configurez** des alertes pour les problèmes réseau
- **Surveillez** les sessions BGP/OSPF
- **Journalisez** les changements de routing

## Exemples Avancés

Voir les fichiers dans `examples/` pour des configurations complètes :

- `examples/network-security-config.nix` - Sécurité réseau avancée
- `examples/security-improved-example.nix` - Configuration sécurité complète
- Tests dans `tests/integration/fabric/` pour des scénarios réels