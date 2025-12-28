# Problèmes Réseau et Solutions 🌐

## Table des Matières

- [Problèmes de Connectivité](#problèmes-de-connectivité)
- [Problèmes de Routage](#problèmes-de-routage)
- [Problèmes DNS](#problèmes-dns)
- [Problèmes de Latence](#problèmes-de-latence)
- [Problèmes de Débit](#problèmes-de-débit)
- [Problèmes de Pare-feu](#problèmes-de-pare-feu)
- [Problèmes VLAN](#problèmes-vlan)
- [Problèmes de Bonding](#problèmes-de-bonding)
- [Problèmes NAT](#problèmes-nat)
- [Outils de Diagnostic](#outils-de-diagnostic)

## Problèmes de Connectivité

### Pas de Connectivité IP

**Symptôme** : Impossible de pinguer d'autres hôtes sur le même réseau

**Diagnostic** :
```bash
ip addr show
ping 192.168.1.1
arp -a
```

**Causes possibles** :
- Adresse IP incorrecte
- Masque de sous-réseau incorrect
- Interface réseau désactivée
- Problème de câblage

**Solution** :
1. Vérifiez la configuration de l'interface :
   ```nix
   networking.interfaces.ens18.ipv4.addresses = [ {
     address = "192.168.1.10";
     prefixLength = 24;
   } ];
   ```
2. Activez l'interface :
   ```bash
   ip link set ens18 up
   ```
3. Vérifiez le câblage physique

### Connectivité Intermittente

**Symptôme** : La connectivité est instable

**Diagnostic** :
```bash
ping -c 100 192.168.1.1
mtr 192.168.1.1
```

**Causes possibles** :
- Problème de câblage
- Interface réseau défectueuse
- Problème de driver
- Interférences réseau

**Solution** :
1. Testez avec un autre câble
2. Vérifiez les logs du noyau :
   ```bash
   dmesg | grep eth
   ```
3. Testez avec une autre interface
4. Mettez à jour les drivers

## Problèmes de Routage

### Routage Non Fonctionnel

**Symptôme** : Impossible de communiquer avec d'autres sous-réseaux

**Diagnostic** :
```bash
ip route show
traceroute 192.168.2.1
cat /proc/sys/net/ipv4/ip_forward
```

**Causes possibles** :
- Forwarding IP désactivé
- Routes manquantes
- Route par défaut manquante
- Problème de pare-feu

**Solution** :
1. Activez le forwarding IP :
   ```nix
   networking.ipv4.forward = true;
   ```
2. Ajoutez les routes manquantes :
   ```nix
   networking.routes = [
     {
       destination = "192.168.2.0/24";
       via = "192.168.1.2";
     }
   ];
   ```
3. Vérifiez le pare-feu

### Route par Défaut Manquante

**Symptôme** : Impossible d'accéder à Internet

**Diagnostic** :
```bash
ip route show
ping 8.8.8.8
```

**Causes possibles** :
- Route par défaut non configurée
- Passerelle incorrecte
- Interface WAN désactivée

**Solution** :
1. Configurez la route par défaut :
   ```nix
   networking.defaultGateway = "192.168.1.1";
   ```
2. Vérifiez que la passerelle est accessible
3. Assurez-vous que l'interface WAN est active

## Problèmes DNS

### Résolution DNS Échouée

**Symptôme** : Les noms de domaine ne sont pas résolus

**Diagnostic** :
```bash
nslookup example.com
cat /etc/resolv.conf
dig example.com
```

**Causes possibles** :
- Serveurs DNS incorrects
- Service DNS désactivé
- Problème de connectivité aux serveurs DNS
- Cache DNS corrompu

**Solution** :
1. Configurez les serveurs DNS :
   ```nix
   networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
   ```
2. Vérifiez le service DNS :
   ```bash
   systemctl status systemd-resolved
   ```
3. Testez avec différents serveurs DNS

### Résolution DNS Lente

**Symptôme** : La résolution DNS est lente

**Diagnostic** :
```bash
time dig example.com
time nslookup example.com
```

**Causes possibles** :
- Serveurs DNS lointains
- Problème de cache DNS
- Problème de réseau

**Solution** :
1. Utilisez des serveurs DNS plus proches
2. Configurez un cache DNS local
3. Vérifiez la connectivité réseau

## Problèmes de Latence

### Latence Élevée

**Symptôme** : Temps de réponse élevé

**Diagnostic** :
```bash
ping host
mtr host
traceroute host
```

**Causes possibles** :
- Problème de routage
- Congestion réseau
- Problème de MTU
- Problème de qualité de service

**Solution** :
1. Identifiez le saut problématique avec mtr
2. Vérifiez la configuration MTU
3. Optimisez les paramètres de l'interface
4. Configurez la qualité de service

### Latence Variable (Jitter)

**Symptôme** : Variation importante des temps de réponse

**Diagnostic** :
```bash
ping -c 100 host
mtr --report host
```

**Causes possibles** :
- Congestion réseau
- Problème de buffer
- Problème de qualité de service

**Solution** :
1. Analysez le trafic avec iftop
2. Configurez la qualité de service
3. Optimisez les buffers réseau

## Problèmes de Débit

### Débit Faible

**Symptôme** : Débit réseau inférieur aux attentes

**Diagnostic** :
```bash
iperf3 -c host
iftop -i interface
```

**Causes possibles** :
- Problème de duplex
- Problème de négociation automatique
- Problème de MTU
- Congestion réseau

**Solution** :
1. Vérifiez les paramètres de l'interface :
   ```bash
   ethtool ens18
   ```
2. Configurez manuellement le duplex et la vitesse :
   ```bash
   ethtool -s ens18 speed 1000 duplex full
   ```
3. Optimisez le MTU

### Débit Asymétrique

**Symptôme** : Débit différent dans les deux directions

**Diagnostic** :
```bash
iperf3 -c host -R
iftop -i interface
```

**Causes possibles** :
- Problème de duplex
- Problème de qualité de service
- Problème de routage asymétrique

**Solution** :
1. Vérifiez les paramètres de duplex
2. Configurez la qualité de service
3. Vérifiez le routage

## Problèmes de Pare-feu

### Connexions Bloquées

**Symptôme** : Certaines connexions sont bloquées

**Diagnostic** :
```bash
sudo nft list ruleset
journalctl -u nftables
tcpdump -i interface port 80
```

**Causes possibles** :
- Règles de pare-feu incorrectes
- Ordre des règles incorrect
- Politique par défaut incorrecte

**Solution** :
1. Vérifiez la configuration du pare-feu :
   ```nix
   network-fabric.security.firewall = {
     enable = true;
     allowedTCP = [ 80 443 ];
     allowedUDP = [ 53 ];
   };
   ```
2. Vérifiez l'ordre des règles
3. Testez avec des règles temporaires

### Pare-feu Trop Permissif

**Symptôme** : Le pare-feu ne bloque pas les connexions indésirables

**Diagnostic** :
```bash
sudo nft list ruleset
journalctl -u nftables
```

**Causes possibles** :
- Politique par défaut incorrecte
- Règles manquantes
- Règles mal ordonnées

**Solution** :
1. Configurez une politique par défaut restrictive :
   ```nix
   network-fabric.security.firewall = {
     enable = true;
     defaultAction = "drop";
   };
   ```
2. Ajoutez des règles spécifiques pour les services nécessaires

## Problèmes VLAN

### VLAN Non Accessible

**Symptôme** : Impossible d'accéder à un VLAN

**Diagnostic** :
```bash
ip addr show
vconfig -a
bridge vlan show
```

**Causes possibles** :
- Configuration VLAN incorrecte
- Interface trunk mal configurée
- Problème de routage inter-VLAN

**Solution** :
1. Vérifiez la configuration VLAN :
   ```nix
   networking.vlans.vlan10 = {
     id = 10;
     interfaces = [ "ens18" ];
     ipv4.addresses = [ { address = "10.0.10.1"; prefixLength = 24; } ];
   };
   ```
2. Configurez l'interface trunk :
   ```nix
   networking.interfaces.ens18.vlanTrunk = true;
   ```
3. Vérifiez le routage inter-VLAN

### Problème de Routage Inter-VLAN

**Symptôme** : Impossible de communiquer entre VLANs

**Diagnostic** :
```bash
ip route show
ping 10.0.20.1
```

**Causes possibles** :
- Routage inter-VLAN désactivé
- Règles de pare-feu bloquantes
- Routes manquantes

**Solution** :
1. Activez le routage inter-VLAN :
   ```nix
   networking.ipv4.forward = true;
   ```
2. Configurez les règles de routage :
   ```nix
   network-fabric.networking.interVlanRouting = {
     enable = true;
     rules = [
       {
         sourceVlan = 10;
         destinationVlan = 20;
         action = "allow";
       }
     ];
   };
   ```

## Problèmes de Bonding

### Bonding Non Fonctionnel

**Symptôme** : Le bonding ne fonctionne pas correctement

**Diagnostic** :
```bash
cat /proc/net/bonding/bond0
ip link show bond0
```

**Causes possibles** :
- Configuration bonding incorrecte
- Interfaces membres désactivées
- Mode bonding non supporté

**Solution** :
1. Vérifiez la configuration bonding :
   ```nix
   networking.bonds.bond0 = {
     interfaces = [ "ens18" "ens19" ];
     mode = "802.3ad";
     miimon = 100;
   };
   ```
2. Assurez-vous que les interfaces membres sont actives
3. Vérifiez que le mode est supporté par le switch

### Basculement Non Fonctionnel

**Symptôme** : Le basculement ne fonctionne pas

**Diagnostic** :
```bash
cat /proc/net/bonding/bond0
ip link show bond0
```

**Causes possibles** :
- Configuration miimon incorrecte
- Problème de détection de lien
- Mode bonding incorrect

**Solution** :
1. Configurez miimon :
   ```nix
   networking.bonds.bond0 = {
     miimon = 100;
     updelay = 200;
     downdelay = 200;
   };
   ```
2. Testez le basculement manuel

## Problèmes NAT

### NAT Non Fonctionnel

**Symptôme** : Le NAT ne fonctionne pas

**Diagnostic** :
```bash
ip route show
iptables -t nat -L -n
ping 8.8.8.8
```

**Causes possibles** :
- Configuration NAT incorrecte
- Forwarding IP désactivé
- Règles de pare-feu bloquantes

**Solution** :
1. Vérifiez la configuration NAT :
   ```nix
   networking.nat = {
     enable = true;
     externalInterface = "ens18";
     internalInterfaces = [ "ens19" ];
   };
   ```
2. Activez le forwarding IP
3. Vérifiez les règles de pare-feu

### Port Forwarding Non Fonctionnel

**Symptôme** : Le port forwarding ne fonctionne pas

**Diagnostic** :
```bash
iptables -t nat -L -n
tcpdump -i interface port 80
```

**Causes possibles** :
- Configuration de port forwarding incorrecte
- Règles de pare-feu bloquantes
- Service non démarré

**Solution** :
1. Vérifiez la configuration de port forwarding :
   ```nix
   networking.nat.portForwarding = [
     {
       name = "forward-web";
       protocol = "tcp";
       externalPort = 80;
       internalPort = 80;
       internalIP = "192.168.1.100";
     }
   ];
   ```
2. Vérifiez que le service est démarré
3. Testez avec des règles temporaires

## Outils de Diagnostic

### Outils de Base

```bash
# Vérifier les interfaces
ip addr show
ip link show
ifconfig -a

# Vérifier le routage
ip route show
route -n
netstat -rn

# Tester la connectivité
ping host
mtr host
traceroute host
tracepath host

# Analyser le trafic
tcpdump -i interface
tcpdump -i interface port 80
tcpdump -i interface host 192.168.1.1

# Vérifier les connexions
ss -tulnp
netstat -tulnp
lsof -i
```

### Outils Avancés

```bash
# Analyser le trafic en temps réel
iftop -i interface
ntopng -i interface

# Tester le débit
iperf3 -c host
iperf3 -s

# Analyser les performances
nuttcp -i1 -T60 host

# Vérifier les erreurs
ethtool -S interface
ip -s link show interface

# Vérifier les statistiques
cat /proc/net/dev
cat /proc/net/snmp
```

### Outils Spécifiques

```bash
# Vérifier les VLANs
vconfig -a
bridge vlan show

# Vérifier le bonding
cat /proc/net/bonding/bond0

# Vérifier le bridging
brctl show
bridge link show

# Vérifier le NAT
iptables -t nat -L -n -v

# Vérifier le pare-feu
nft list ruleset
nft list ruleset -a
```

## Bonnes Pratiques

### 1. Diagnostic

- **Commencez** par les bases (interfaces, routage)
- **Isolez** le problème
- **Testez** les composants individuellement
- **Vérifiez** les logs

### 2. Résolution

- **Documentez** les changements
- **Testez** les solutions
- **Validez** la résolution
- **Surveillez** après résolution

### 3. Prévention

- **Surveillez** régulièrement le réseau
- **Configurez** des alertes
- **Documentez** les configurations
- **Testez** les changements

### 4. Collaboration

- **Partagez** les solutions
- **Contribuez** à la documentation
- **Demandez** de l'aide si nécessaire
- **Participez** à la communauté

## Ressources Supplémentaires

- [Documentation NixOS Networking](https://nixos.org/manual/nixos/stable/index.html#sec-networking)
- [Guide de Dépannage Réseau Linux](https://www.tldp.org/HOWTO/Net-HOWTO/index.html)
- [Outils Réseau Linux](https://linux.die.net/man/)
- [Documentation FRR](https://docs.frrouting.org/)
- [Documentation WireGuard](https://www.wireguard.com/)