# Comment ça marche ? 🤯

**Explication simple pour ne pas se prendre la tête :**

## La Philosophie

NixOS Fabric utilise 3 principes simples :

1. **Tout est du code** (pas de clics, que du texte)
2. **Tout est reproductible** (la même config donne le même résultat)
3. **Tout est modulaire** (tu prends ce dont tu as besoin)

## Les 4 Composants Principaux

### 1. 📦 Modules Nix

Des briques de configuration toutes faites :
- `wireguard.nix` → Configure WireGuard
- `frr.nix` → Configure le routage
- `security.nix` → Configure la sécurité
- `networking.nix` → Configure le réseau

**Exemple :**
```nix
# J'importe le module WireGuard
imports = [ ./modules/networking/wireguard.nix ];

# Je l'active
network-fabric.wireguard.enable = true;
```

### 2. 🎭 Rôles

Des configurations pré-établies pour différents types de machines :
- **Spine** : Machine qui fait du routage pur
- **Leaf** : Machine qui connecte des serveurs
- **Hybrid** : Machine qui fait les deux

**Exemple :**
```nix
# Je dis que ma machine est un "hybrid"
network-fabric.role = "hybrid";
```

### 3. 🏠 Configurations Hôtes

La configuration spécifique pour chaque machine :
```
hosts/
├── mon-serveur-1/
│   ├── variables.nix  # Variables spécifiques
│   └── default.nix   # Configuration principale
└── mon-serveur-2/
    ├── variables.nix
    └── default.nix
```

### 4. 🤖 Ansible (Optionnel)

Pour automatiser le déploiement sur plusieurs machines :
```bash
# Une seule commande pour tout configurer
ansible-playbook deploy-fabric.yml
```

## Le Flux de Travail

```
1. Tu écris la configuration → fichiers .nix
2. Tu testes en local → nixos-rebuild test
3. Tu déploires → nixos-rebuild switch
4. Ça marche (ou pas) → tu corriges
```

## Exemple Complet

**Fichier** : `hosts/mon-serveur/variables.nix`
```nix
{ config, lib, pkgs, ... }:
{
  network-fabric = {
    # J'active WireGuard
    wireguard.enable = true;
    
    # Je configure mon interface WireGuard
    wireguard.interfaces.wg0 = {
      privateKey = "ma-cle-privee";
      listenPort = 51820;
      peers = [
        {
          publicKey = "cle-publique-de-l-autre-machine";
          allowedIPs = [ "10.0.0.2/32" ];
        }
      ];
    };
    
    # J'active la sécurité
    security.enable = true;
    security.ssh.port = 2222;  # Je change le port SSH
  };
}
```

## Comment les Machines Communiquent ?

```
[Machine A] --WireGuard-- [Machine B]
       ↓                 ↓
   (10.0.0.1)         (10.0.0.2)
       ↓                 ↓
   [FRR Routage] ←→ [FRR Routage]
       ↓                 ↓
   [Internet] ←→ [Internet]
```

1. **WireGuard** crée un tunnel sécurisé entre les machines
2. **FRR** gère le routage pour que les paquets arrivent à destination
3. **NFTables** filtre le trafic pour la sécurité

**Prochaine étape** : 👉 [Architecture simple](architecture.md)