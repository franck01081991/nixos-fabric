# Erreurs Courantes et Solutions 🐛

## Table des Matières

- [Erreurs de Configuration NixOS](#erreurs-de-configuration-nixos)
- [Problèmes Réseau](#problèmes-réseau)
- [Problèmes de Routage](#problèmes-de-routage)
- [Problèmes BGP](#problèmes-bgp)
- [Problèmes OSPF](#problèmes-ospf)
- [Problèmes WireGuard](#problèmes-wireguard)
- [Problèmes de Pare-feu](#problèmes-de-pare-feu)
- [Problèmes SSH](#problèmes-ssh)
- [Problèmes de Déploiement](#problèmes-de-déploiement)
- [Problèmes de Performance](#problèmes-de-performance)

## Erreurs de Configuration NixOS

### Erreur: "Unknown option"

**Symptôme** :
```
error: unknown option 'network-fabric.frr.bgp'
```

**Solution** :
1. Vérifiez que vous avez importé le module correct :
   ```nix
   imports = [ ./modules/networking/frr.nix ];
   ```
2. Assurez-vous que le chemin est correct
3. Vérifiez la syntaxe du module

### Erreur: "Infinite recursion"

**Symptôme** :
```
error: infinite recursion encountered
```

**Solution** :
1. Vérifiez les imports circulaires
2. Assurez-vous que les modules ne s'importent pas mutuellement
3. Utilisez des chemins absolus ou relatifs corrects

### Erreur: "Attribute missing"

**Symptôme** :
```
error: attribute 'bgp' missing
```

**Solution** :
1. Vérifiez que le module est activé :
   ```nix
   network-fabric.frr = {
     enable = true;
     bgp = { ... };
   };
   ```
2. Assurez-vous que toutes les options requises sont définies

## Problèmes Réseau

### Pas de Connectivité Réseau

**Symptôme** : Impossible de pinguer d'autres hôtes

**Diagnostic** :
```bash
ip addr show
ping 8.8.8.8
ip route show
```

**Solution** :
1. Vérifiez la configuration de l'interface :
   ```nix
   networking.interfaces.ens18.ipv4.addresses = [ {
     address = "192.168.1.10";
     prefixLength = 24;
   } ];
   ```
2. Vérifiez la route par défaut :
   ```nix
   networking.defaultGateway = "192.168.1.1";
   ```
3. Vérifiez le DNS :
   ```nix
   networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
   ```

### Problème de Résolution DNS

**Symptôme** : Les noms de domaine ne sont pas résolus

**Diagnostic** :
```bash
nslookup example.com
cat /etc/resolv.conf
```

**Solution** :
1. Configurez les serveurs DNS :
   ```nix
   networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
   ```
2. Vérifiez que le service est activé :
   ```bash
   systemctl status systemd-resolved
   ```

## Problèmes de Routage

### Routage Non Fonctionnel

**Symptôme** : Les paquets ne sont pas routés entre les interfaces

**Diagnostic** :
```bash
ip route show
cat /proc/sys/net/ipv4/ip_forward
```

**Solution** :
1. Activez le forwarding IP :
   ```nix
   networking.ipv4.forward = true;
   ```
2. Vérifiez les règles de pare-feu
3. Assurez-vous que les routes sont correctement configurées

### Routes Manquantes

**Symptôme** : Certaines routes ne sont pas présentes

**Diagnostic** :
```bash
ip route show
```

**Solution** :
1. Ajoutez les routes manuellement :
   ```nix
   networking.routes = [
     {
       destination = "192.168.2.0/24";
       via = "192.168.1.2";
     }
   ];
   ```
2. Vérifiez la configuration FRR si vous utilisez des protocoles dynamiques

## Problèmes BGP

### Session BGP Non Établie

**Symptôme** : La session BGP ne s'établit pas

**Diagnostic** :
```bash
sudo vtysh
show ip bgp summary
show ip bgp neighbors
```

**Solution** :
1. Vérifiez la configuration BGP :
   ```nix
   network-fabric.frr.bgp = {
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
   ```
2. Vérifiez la connectivité réseau entre les pairs
3. Assurez-vous que les AS numbers sont corrects
4. Vérifiez que le pare-feu permet le port 179 (TCP)

### Routes BGP Non Annoncées

**Symptôme** : Les routes ne sont pas annoncées aux pairs

**Diagnostic** :
```bash
show ip bgp
show ip route
```

**Solution** :
1. Vérifiez que les réseaux sont configurés :
   ```nix
   networks = [ "192.168.1.0/24" ];
   ```
2. Vérifiez les filtres de préfixes
3. Assurez-vous que la redistribution est configurée si nécessaire

## Problèmes OSPF

### Voisins OSPF Non Découverts

**Symptôme** : Les voisins OSPF ne sont pas découverts

**Diagnostic** :
```bash
show ip ospf neighbor
show ip ospf interface
```

**Solution** :
1. Vérifiez la configuration OSPF :
   ```nix
   network-fabric.frr.ospf = {
     enable = true;
     routerId = "192.168.1.1";
     areas = [
       {
         id = "0.0.0.0";
         interfaces = [
           {
             name = "ens18";
             cost = 10;
           }
         ];
       }
     ];
   };
   ```
2. Vérifiez que les interfaces sont dans le bon réseau
3. Assurez-vous que les paramètres de coût et de type de réseau sont corrects

### Routes OSPF Manquantes

**Symptôme** : Les routes OSPF ne sont pas apprises

**Diagnostic** :
```bash
show ip route ospf
show ip ospf database
```

**Solution** :
1. Vérifiez que la redistribution est configurée si nécessaire
2. Assurez-vous que les aires OSPF sont correctement configurées
3. Vérifiez les filtres de route

## Problèmes WireGuard

### Interface WireGuard Non Active

**Symptôme** : L'interface WireGuard ne s'active pas

**Diagnostic** :
```bash
sudo wg show
ip link show wg0
journalctl -u wg-quick@wg0
```

**Solution** :
1. Vérifiez la configuration WireGuard :
   ```nix
   network-fabric.wireguard = {
     enable = true;
     interfaces = [
       {
         name = "wg0";
         privateKeyFile = "/etc/wireguard/private.key";
         port = 51820;
         addresses = [ "10.8.0.1/24" ];
       }
     ];
   };
   ```
2. Assurez-vous que la clé privée existe et est accessible
3. Vérifiez que le port UDP est disponible

### Pas de Connectivité WireGuard

**Symptôme** : Impossible de communiquer via WireGuard

**Diagnostic** :
```bash
ping 10.8.0.2
sudo wg show
ip route show
```

**Solution** :
1. Vérifiez que les pairs sont correctement configurés
2. Assurez-vous que les allowedIPs sont corrects
3. Vérifiez que le pare-feu permet le port UDP 51820
4. Testez le MTU :
   ```bash
   ping -M do -s 1400 10.8.0.2
   ```

## Problèmes de Pare-feu

### Connexions Bloquées

**Symptôme** : Les connexions sont bloquées par le pare-feu

**Diagnostic** :
```bash
sudo nft list ruleset
journalctl -u nftables
```

**Solution** :
1. Vérifiez la configuration du pare-feu :
   ```nix
   network-fabric.security.firewall = {
     enable = true;
     allowedTCP = [ 22 80 443 ];
     allowedUDP = [ 51820 ];
   };
   ```
2. Assurez-vous que les ports nécessaires sont ouverts
3. Vérifiez l'ordre des règles
4. Testez avec des règles temporaires :
   ```bash
   sudo nft add rule ip filter INPUT tcp dport 80 accept
   ```

### Pare-feu Ne Démarre Pas

**Symptôme** : Le service nftables ne démarre pas

**Diagnostic** :
```bash
systemctl status nftables
journalctl -u nftables
```

**Solution** :
1. Vérifiez la syntaxe des règles :
   ```bash
   sudo nft -c -f /etc/nftables.conf
   ```
2. Assurez-vous que le module est activé :
   ```nix
   network-fabric.security.firewall.enable = true;
   ```
3. Vérifiez les dépendances

## Problèmes SSH

### Connexion SSH Refusée

**Symptôme** : Impossible de se connecter en SSH

**Diagnostic** :
```bash
ssh -v user@host
journalctl -u sshd
```

**Solution** :
1. Vérifiez la configuration SSH :
   ```nix
   network-fabric.security.ssh = {
     enable = true;
     port = 2222;
     passwordAuthentication = false;
   };
   ```
2. Assurez-vous que le pare-feu permet le port SSH
3. Vérifiez que l'utilisateur existe et a les bonnes permissions
4. Testez avec l'authentification par clé

### Authentification SSH Échouée

**Symptôme** : L'authentification SSH échoue

**Diagnostic** :
```bash
ssh -v user@host
journalctl -u sshd
```

**Solution** :
1. Vérifiez que la clé publique est dans authorized_keys
2. Assurez-vous que les permissions sont correctes :
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```
3. Vérifiez que passwordAuthentication est désactivé si vous utilisez des clés

## Problèmes de Déploiement

### Déploiement NixOS Échoué

**Symptôme** : Le déploiement NixOS échoue

**Diagnostic** :
```bash
nixos-rebuild switch --flake .#host
journalctl -b
```

**Solution** :
1. Vérifiez la syntaxe de la configuration :
   ```bash
   nix-instantiate --parse --eval -E 'import ./hosts/host/default.nix'
   ```
2. Testez la configuration en mode dry-run
3. Vérifiez les dépendances et les imports

### Déploiement Ansible Échoué

**Symptôme** : Le playbook Ansible échoue

**Diagnostic** :
```bash
ansible-playbook -i inventory/hosts.ini playbook.yml -v
```

**Solution** :
1. Vérifiez la connectivité SSH
2. Assurez-vous que les variables sont correctement définies
3. Testez avec un playbook simple
4. Vérifiez les permissions

## Problèmes de Performance

### Latence Élevée

**Symptôme** : Latence réseau élevée

**Diagnostic** :
```bash
ping host
mtr host
iperf3 -c host
```

**Solution** :
1. Vérifiez la configuration MTU
2. Optimisez les paramètres de l'interface réseau
3. Vérifiez la charge CPU et mémoire
4. Analysez le trafic avec tcpdump

### Débit Faible

**Symptôme** : Débit réseau faible

**Diagnostic** :
```bash
iperf3 -c host
iftop -i interface
```

**Solution** :
1. Vérifiez la configuration du bonding si utilisé
2. Optimisez les paramètres TCP
3. Vérifiez les limitations du pare-feu
4. Analysez les goulots d'étranglement

## Outils de Dépannage

### Outils Réseau

```bash
# Vérifier les interfaces
ip addr show
ip link show

# Vérifier le routage
ip route show
route -n

# Tester la connectivité
ping host
mtr host
traceroute host

# Analyser le trafic
tcpdump -i interface
iftop -i interface

# Tester le débit
iperf3 -c host
```

### Outils NixOS

```bash
# Vérifier la configuration
nixos-rebuild dry-activate
nix eval -f default.nix config

# Vérifier les services
systemctl status service
journalctl -u service

# Vérifier les modules
nix-instantiate --eval -E 'import ./module.nix'
```

### Outils FRR

```bash
# Vérifier BGP
show ip bgp summary
show ip bgp neighbors
show ip route

# Vérifier OSPF
show ip ospf neighbor
show ip ospf interface
show ip ospf database

# Vérifier les routes
show ip route
show ip route ospf
show ip route bgp
```

### Outils WireGuard

```bash
# Vérifier WireGuard
wg show
wg show all
wg showconf interface

# Vérifier les logs
journalctl -u wg-quick@interface
```

## Bonnes Pratiques de Dépannage

### 1. Méthodologie

- **Isolez** le problème
- **Testez** les composants individuellement
- **Vérifiez** les logs
- **Documentez** les étapes de dépannage

### 2. Journalisation

- **Activez** toujours la journalisation
- **Configurez** le niveau de log approprié
- **Surveillez** les logs régulièrement
- **Archivez** les logs importants

### 3. Tests

- **Testez** les configurations avant déploiement
- **Utilisez** des environnements de test
- **Validez** les changements
- **Automatisez** les tests

### 4. Documentation

- **Documentez** les configurations
- **Notez** les changements
- **Archivez** les configurations fonctionnelles
- **Partagez** les solutions

### 5. Collaboration

- **Demandez** de l'aide si nécessaire
- **Partagez** les problèmes et solutions
- **Contribuez** à la documentation
- **Participez** à la communauté

## Ressources Supplémentaires

- [Documentation NixOS](https://nixos.org/manual/)
- [Documentation FRR](https://docs.frrouting.org/)
- [Documentation WireGuard](https://www.wireguard.com/)
- [Forum NixOS](https://discourse.nixos.org/)
- [GitHub NixOS Fabric](https://github.com/franck01081991/nixos-fabric)