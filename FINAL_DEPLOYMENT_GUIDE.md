# Guide de déploiement final pour l'interconnexion rtr-sapinet <-> rtr-noisy

## Résumé de la situation

Après plusieurs tentatives, nous avons identifié que :

1. **Les configurations NixOS existent déjà** sur les deux hôtes
2. **Les clés WireGuard sont déjà générées**
3. **Les configurations FRR/BGP sont déjà en place**
4. **Seuls les placeholders doivent être remplacés**

## Clés publiques existantes

- **rtr-sapinet**: `e18dkmQzQl4sBL9N0xWnVMyFZ9RqXmrSrN6C10IGSW0=`
- **rtr-noisy**: `Qvhgie7O3gKZF8pMmTS0YG2YmbNfANtCX3sBE21ODg8=`

## Étapes manuelles pour le déploiement

### Étape 1: Sauvegarder les configurations originales

```bash
# Sur rtr-sapinet
ssh root@45.90.162.251 "cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup"

# Sur rtr-noisy
ssh root@10.10.10.1 "cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup"
```

### Étape 2: Remplacer les placeholders sur rtr-sapinet

```bash
# Remplacer la clé publique de noisy
ssh root@45.90.162.251 "sed -i 's/__NOISY_PUB__/Qvhgie7O3gKZF8pMmTS0YG2YmbNfANtCX3sBE21ODg8=/g' /etc/nixos/configuration.nix"

# Remplacer l'endpoint de noisy
ssh root@45.90.162.251 "sed -i 's/__NOISY_ENDPOINT__/10.10.10.1/g' /etc/nixos/configuration.nix"
```

### Étape 3: Remplacer les placeholders sur rtr-noisy

```bash
# Remplacer la clé publique de sapinet
ssh root@10.10.10.1 "sed -i 's/__SAPINET_PUB__/e18dkmQzQl4sBL9N0xWnVMyFZ9RqXmrSrN6C10IGSW0=/g' /etc/nixos/configuration.nix"

# Remplacer l'endpoint de sapinet
ssh root@10.10.10.1 "sed -i 's/__SAPINET_ENDPOINT__/45.90.162.251/g' /etc/nixos/configuration.nix"
```

### Étape 4: Appliquer les configurations NixOS

```bash
# Sur rtr-sapinet
ssh root@45.90.162.251 "nixos-rebuild switch"

# Sur rtr-noisy
ssh root@10.10.10.1 "nixos-rebuild switch"
```

### Étape 5: Vérifier le déploiement

```bash
# Vérifier WireGuard sur sapinet
ssh root@45.90.162.251 "wg show wgtransport"

# Vérifier WireGuard sur noisy
ssh root@10.10.10.1 "wg show wgtransport"

# Vérifier BGP sur sapinet
ssh root@45.90.162.251 "vtysh -c 'show bgp summary'"

# Vérifier BGP sur noisy
ssh root@10.10.10.1 "vtysh -c 'show bgp summary'"

# Tester la connectivité
ssh root@45.90.162.251 "ping -c 3 10.255.0.2"
ssh root@10.10.10.1 "ping -c 3 10.255.0.1"
```

## Commandes utiles pour le débogage

### Vérifier l'état des services

```bash
# Sur les deux hôtes
ssh root@host_ip "systemctl status wg-quick@wgtransport"
ssh root@host_ip "systemctl status frr"
ssh root@host_ip "journalctl -u wg-quick@wgtransport -n 20"
ssh root@host_ip "journalctl -u frr -n 20"
```

### Vérifier les configurations

```bash
# Voir la configuration WireGuard
ssh root@host_ip "cat /etc/wireguard/wgtransport.conf"

# Voir la configuration FRR
ssh root@host_ip "cat /etc/frr/frr.conf"
```

### Redémarrer les services

```bash
ssh root@host_ip "systemctl restart wg-quick@wgtransport"
ssh root@host_ip "systemctl restart frr"
```

## Problèmes courants et solutions

### Problème: Le fichier de configuration est vide après modification

**Solution**: Restaurer à partir de la sauvegarde et utiliser des commandes plus simples:

```bash
# Utiliser perl au lieu de sed pour les remplacements complexes
ssh root@host_ip "perl -pi -e 's/__NOISY_PUB__/NEW_KEY/g' /etc/nixos/configuration.nix"
```

### Problème: Erreur de syntaxe NixOS

**Solution**: Vérifier la syntaxe avant d'appliquer:

```bash
ssh root@host_ip "nix-instantiate --parse /etc/nixos/configuration.nix"
```

### Problème: Services WireGuard échoués

**Solution**: Vérifier les journaux et les permissions:

```bash
ssh root@host_ip "journalctl -u wg-quick@wgtransport"
ssh root@host_ip "ls -la /etc/wireguard/"
ssh root@host_ip "chmod 600 /etc/wireguard/*.key"
```

## Configuration réseau attendue

### Adresses IP WireGuard

- **rtr-sapinet**: `10.255.0.1/24`
- **rtr-noisy**: `10.255.0.2/24`

### Configuration BGP

- **AS Number**: 65001
- **rtr-sapinet BGP ID**: 10.254.0.1
- **rtr-noisy BGP ID**: 10.254.0.11
- **Peer IP**: 10.255.0.2 (from sapinet), 10.255.0.1 (from noisy)

### Routes annoncées

- **rtr-sapinet**: 10.254.0.1/32, 10.255.0.0/24
- **rtr-noisy**: 10.254.0.11/32, 10.255.0.0/24

## Vérification finale

Une fois le déploiement terminé, vous devriez voir:

1. **WireGuard**: Handshake établi entre les deux hôtes
2. **BGP**: Session établie (état "Established")
3. **Connectivité**: Ping réussi entre 10.255.0.1 et 10.255.0.2
4. **Routes**: Les routes BGP devraient être visibles dans la table de routage

## Fichiers de référence

- `hosts/rtr-sapinet/default.nix` - Configuration originale sapinet
- `hosts/rtr-noisy/default.nix` - Configuration originale noisy
- `ansible/host_vars/rtr-sapinet.yml` - Variables Ansible sapinet
- `ansible/host_vars/rtr-noisy.yml` - Variables Ansible noisy

## Notes supplémentaires

- Les configurations incluent également des peers pour d'autres hôtes (bondy, lepre) qui ne sont pas encore configurés
- Les configurations FRR incluent OSPF et BGP
- Les configurations sont conçues pour un réseau fabric avec plusieurs routeurs
- Les clés WireGuard sont stockées dans `/etc/wireguard/` avec des permissions restrictives

## Support

Si vous rencontrez des problèmes, vérifiez:
1. Les journaux système (`journalctl -xe`)
2. L'état des services (`systemctl status`)
3. La syntaxe des fichiers de configuration
4. Les permissions des fichiers de clés

Bon déploiement ! 🚀
