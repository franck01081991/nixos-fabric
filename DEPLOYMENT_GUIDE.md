# Guide de déploiement complet

## Table des matières

1. [Prérequis](#prérequis)
2. [Architecture](#architecture)
3. [Préparation](#préparation)
4. [Déploiement manuel](#déploiement-manuel)
5. [Déploiement automatisé](#déploiement-automatisé)
6. [Vérification](#vérification)
7. [Monitoring](#monitoring)
8. [Maintenance](#maintenance)
9. [Dépannage](#dépannage)
10. [Sécurité](#sécurité)

## Prérequis

### Matériel
- **rtr-sapinet** : VPS avec IP publique (45.90.162.251)
- **rtr-noisy** : Machine physique avec ports LAN (enp2s0-enp6s0)
- Connexion réseau entre les deux machines

### Logiciel
- NixOS 25.11 sur les deux machines
- Accès root ou sudo
- Clés SSH configurées

### Réseau
- Ports ouverts : TCP 22, UDP 51820
- MTU compatible avec WireGuard (1420)

## Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                        rtr-sapinet (Spine)                     │
│                                                               │
│  WAN: ens18 (45.90.162.251/32)                                │
│  Loopback: 10.254.0.1/32                                      │
│  WireGuard: wgtransport (10.255.0.1/24)                       │
│  BGP: AS 65000, iBGP avec rtr-noisy                           │
└───────────────────────────────────────────────────────────────┘
                                      ↓ WireGuard (UDP 51820)
                                      ↓ BGP (TCP 179)
                                      ↓ VXLAN (UDP 4789)
┌───────────────────────────────────────────────────────────────┐
│                        rtr-noisy (Spine+Leaf)                  │
│                                                               │
│  WAN: enp1s0 (DHCP)                                          │
│  Loopback: 10.254.0.11/32                                     │
│  WireGuard: wgtransport (10.255.0.11/24)                      │
│  BGP: AS 65000, iBGP avec rtr-sapinet, Cluster-ID 10.254.0.11 │
│                                                               │
│  Bridge: br0 (VLAN-aware)                                    │
│    ├─ VLAN10: 10.10.10.1/24 (Management, DHCP)                │
│    ├─ VLAN20: 10.10.20.1/24 (No DHCP)                         │
│    ├─ VLAN30: 10.10.30.1/24 (DHCP)                            │
│    └─ VLAN40: 10.10.40.1/24 (DHCP)                            │
│                                                               │
│  VXLAN: vxlan10-40 (VNI 1010-1040)                           │
│  LAN Ports: enp2s0-enp6s0 (Untagged VLAN10)                   │
│                                                               │
│  Monitoring: Prometheus, Grafana, Node Exporter               │
└───────────────────────────────────────────────────────────────┘
```

## Préparation

### 1. Cloner le dépôt

```bash
git clone https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric
```

### 2. Configurer l'inventaire Ansible

Éditez `ansible/inventory/hosts.ini`:

```ini
[rtr-sapinet]
rtr-sapinet ansible_host=45.90.162.251 ansible_user=franck

[rtr-noisy]
rtr-noisy ansible_host=rtr-noisy.local ansible_user=franck

[routers:children]
rtr-sapinet
rtr-noisy
```

### 3. Installer les dépendances

```bash
# Sur votre machine de contrôle
sudo apt install ansible sops age

# Ou avec Nix
nix-shell -p ansible sops age
```

## Déploiement manuel

### 1. Générer les clés WireGuard

**Sur rtr-sapinet:**
```bash
sudo mkdir -p /etc/wireguard
wg genkey | sudo tee /etc/wireguard/rtr-sapinet.key | wg pubkey | sudo tee /etc/wireguard/rtr-sapinet.pub
sudo chmod 600 /etc/wireguard/rtr-sapinet.key
```

**Sur rtr-noisy:**
```bash
sudo mkdir -p /etc/wireguard
wg genkey | sudo tee /etc/wireguard/rtr-noisy.key | wg pubkey | sudo tee /etc/wireguard/rtr-noisy.pub
sudo chmod 600 /etc/wireguard/rtr-noisy.key
```

### 2. Échanger les clés publiques

**Depuis rtr-sapinet:**
```bash
scp /etc/wireguard/rtr-sapinet.pub franck@rtr-noisy:/tmp/
```

**Depuis rtr-noisy:**
```bash
scp /etc/wireguard/rtr-noisy.pub franck@rtr-sapinet:/tmp/
```

### 3. Configurer les placeholders

**Sur rtr-sapinet:**
```bash
sudo sed -i "s/__RTR_NOISY_PUB__/$(cat /tmp/rtr-noisy.pub)/" /etc/nixos/variables.nix
```

**Sur rtr-noisy:**
```bash
sudo sed -i "s/__RTR_SAPINET_PUB__/$(cat /tmp/rtr-sapinet.pub)/" /etc/nixos/variables.nix
```

### 4. Appliquer la configuration

**Sur les deux machines:**
```bash
sudo nixos-rebuild switch
```

## Déploiement automatisé

### 1. Utiliser le script de déploiement

```bash
# Sur votre machine de contrôle
./scripts/deploy-wireguard-bgp.sh
```

Ou en mode dry-run:
```bash
./scripts/deploy-wireguard-bgp.sh --dry-run
```

### 2. Utiliser le playbook Ansible

```bash
# Depuis le répertoire ansible
ansible-playbook playbooks/deploy-wireguard-bgp.yml
```

### 3. Utiliser sops-nix pour les secrets

Voir [SECRETS_GUIDE.md](SECRETS_GUIDE.md) pour la gestion sécurisée des secrets.

## Vérification

### 1. Vérifier WireGuard

```bash
# Sur les deux machines
wg show

# Tester la connectivité
ping 10.255.0.1    # Depuis rtr-noisy
ping 10.255.0.11   # Depuis rtr-sapinet
```

### 2. Vérifier BGP

```bash
# Sur les deux machines
vtysh -c "show bgp summary"
vtysh -c "show bgp neighbors"

# Vérifier les routes
vtysh -c "show ip bgp"
```

### 3. Vérifier les VLANs (rtr-noisy seulement)

```bash
bridge vlan show
ip a show br0.10
ip a show br0.20
ip a show br0.30
ip a show br0.40
```

### 4. Tester DHCP

Branchez un appareil sur un port LAN (enp2s0-enp6s0) en mode untagged. L'appareil devrait recevoir une IP dans 10.10.10.0/24.

## Monitoring

### 1. Accéder à Grafana

Sur rtr-noisy, accédez à http://rtr-noisy:3000

### 2. Vérifier les exporteurs

```bash
# Vérifier que les exporteurs sont en cours d'exécution
curl -s http://localhost:9100/metrics | head  # Node Exporter
curl -s http://localhost:9586/metrics | head  # WireGuard Exporter
curl -s http://localhost:2605/metrics | head  # FRR Exporter
```

### 3. Vérifier Prometheus

```bash
curl -s http://localhost:9090/targets | jq
```

## Maintenance

### 1. Mises à jour

```bash
# Mettre à jour le système
sudo nix-channel --update
sudo nixos-rebuild switch --upgrade
```

### 2. Rotation des clés WireGuard

```bash
# Générer de nouvelles clés
wg genkey | sudo tee /etc/wireguard/$(hostname).key | wg pubkey | sudo tee /etc/wireguard/$(hostname).pub

# Mettre à jour la configuration
sudo systemctl restart wg-quick@wgtransport
```

### 3. Sauvegardes

```bash
# Sauvegarder la configuration
sudo cp -r /etc/nixos /backup/nixos-$(date +%Y%m%d)

# Sauvegarder les clés (sécurisé!)
sudo cp /etc/wireguard/*.key /backup/wireguard-$(date +%Y%m%d).key
sudo chmod 600 /backup/wireguard-$(date +%Y%m%d).key
```

## Dépannage

### Problèmes WireGuard

**Symptôme:** Pas de handshake
```bash
# Vérifier l'interface
wg show

# Vérifier les logs
journalctl -u wg-quick@wgtransport

# Tester la connectivité
ping -M do -s 1400 10.255.0.1
```

### Problèmes BGP

**Symptôme:** Session BGP non établie
```bash
# Vérifier l'état BGP
vtysh -c "show bgp neighbors"

# Vérifier les logs FRR
journalctl -u frr

# Tester la connectivité entre loopbacks
ping 10.254.0.11
```

### Problèmes VLAN

**Symptôme:** VLANs non fonctionnels
```bash
# Vérifier la configuration du bridge
bridge vlan show

# Vérifier les logs du service
journalctl -u vlan-port-flags
journalctl -u vxlan-port-flags

# Redémarrer les services
sudo systemctl restart systemd-networkd
sudo systemctl restart vlan-port-flags
sudo systemctl restart vxlan-port-flags
```

## Sécurité

### 1. Vérifier le pare-feu

```bash
# Vérifier les règles nftables
sudo nft list ruleset

# Tester les règles
sudo nft -a list ruleset
```

### 2. Vérifier SSH

```bash
# Vérifier la configuration
sudo sshd -T

# Tester la connexion
ssh -v franck@localhost
```

### 3. Vérifier le hardening

```bash
# Vérifier les paramètres sysctl
sudo sysctl -a | grep net.ipv4.conf

# Vérifier les services
sudo systemctl status fail2ban
sudo systemctl status apparmor
sudo systemctl status auditd
```

## Annexes

### Commandes utiles

```bash
# Redémarrer tous les services réseau
sudo systemctl restart systemd-networkd frr wg-quick@wgtransport

# Vérifier tous les services
sudo systemctl status systemd-networkd frr wg-quick@wgtransport prometheus node-exporter grafana

# Vérifier les logs
journalctl -u systemd-networkd -u frr -u wg-quick@wgtransport
```

### Schéma réseau

Voir [NETWORK_DIAGRAM.md](NETWORK_DIAGRAM.md) pour un schéma détaillé.

### Journal des changements

Voir [CHANGELOG.md](CHANGELOG.md) pour l'historique des modifications.
