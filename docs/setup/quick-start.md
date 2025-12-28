# Guide de Démarrage Rapide 🚀

## Prérequis

- Un système avec NixOS installé
- Accès root ou sudo
- Connexion internet
- Git installé

## Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric
```

### 2. Initialiser les sous-modules

```bash
./scripts/setup-submodules.sh
```

### 3. Configuration de base

Copiez le fichier d'exemple et modifiez-le :

```bash
cp examples/example-configuration.nix hosts/test-vm/default.nix
nano hosts/test-vm/default.nix
```

### 4. Déploiement avec NixOS

```bash
# Pour une machine locale
sudo nixos-rebuild switch --flake .#test-vm

# Pour une machine distante
nixos-rebuild switch --flake .#test-vm --target-host root@ip-serveur --build-host localhost
```

## Configuration Réseau Basique

### Configuration FRR (BGP)

```nix
{ config, pkgs, ... }:
{
  imports = [ ./modules/networking/frr.nix ];
  
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

### Configuration WireGuard

```nix
{ config, pkgs, ... }:
{
  imports = [ ./modules/networking/wireguard.nix ];
  
  network-fabric.wireguard = {
    enable = true;
    interfaces = [
      {
        name = "wg0";
        privateKeyFile = "/etc/wireguard/private.key";
        port = 51820;
        peers = [
          {
            publicKey = "peer-public-key";
            allowedIPs = [ "10.0.0.2/32" ];
            endpoint = "example.com:51820";
          }
        ];
      }
    ];
  };
}
```

## Configuration Sécurité

### Pare-feu de base

```nix
{ config, pkgs, ... }:
{
  imports = [ ./modules/security/firewall.nix ];
  
  network-fabric.security.firewall = {
    enable = true;
    allowedTCP = [ 22 80 443 51820 ];
    allowedUDP = [ 51820 ];
    enableLogging = true;
  };
}
```

### Sécurité SSH

```nix
{ config, pkgs, ... }:
{
  imports = [ ./modules/security/ssh.nix ];
  
  network-fabric.security.ssh = {
    enable = true;
    port = 2222;
    passwordAuthentication = false;
    permitRootLogin = "no";
    allowUsers = [ "admin" "franck" ];
  };
}
```

## Déploiement avec Ansible

### 1. Configurer Ansible

```bash
cd ansible
cp inventory/example inventory/production
nano inventory/production/hosts.ini
```

### 2. Exécuter le playbook

```bash
ansible-playbook -i inventory/production/hosts.ini playbooks/deploy-fabric.yml
```

## Vérification

### Vérifier la configuration FRR

```bash
sudo vtysh
show ip bgp summary
show ip route
```

### Vérifier WireGuard

```bash
sudo wg show
ping 10.0.0.2
```

### Vérifier le pare-feu

```bash
sudo nft list ruleset
sudo journalctl -u nftables -f
```

## Prochaines Étapes

- 📖 [Configuration de base](basic-config.md) - Configuration plus détaillée
- 🔒 [Sécurité simple](security.md) - Configuration de sécurité avancée
- 🌐 [Réseau](networking.md) - Configuration réseau complète
- 🐒 [Exemples pratiques](../examples/simple-config.md) - Exemples prêts à l'emploi