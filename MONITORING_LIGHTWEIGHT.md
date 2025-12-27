# Monitoring Lightweight - Exporters Only

## Introduction

Cette configuration permet de surveiller l'infrastructure sans exécuter de logiciels lourds (Prometheus, Grafana) directement sur les routeurs. Seuls des exporters légers sont installés, qui peuvent envoyer leurs métriques à un serveur central.

## Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                        rtr-sapinet (Spine)                     │
│                                                               │
│  Exporters:                                                   │
│    ├─ Node Exporter (9100) - Métriques système                │
│    └─ FRR Exporter (2605) - Métriques BGP                     │
└───────────────────────────────────────────────────────────────┘
                                      ↓ Métriques (Pull)
                                      ↓ ou Push Gateway
┌───────────────────────────────────────────────────────────────┐
│                        rtr-noisy (Leaf)                        │
│                                                               │
│  Exporters:                                                   │
│    ├─ Node Exporter (9100) - Métriques système                │
│    ├─ WireGuard Exporter (9586) - Métriques WireGuard          │
│    └─ FRR Exporter (2605) - Métriques BGP                     │
└───────────────────────────────────────────────────────────────┘
                                      ↓ Métriques (Pull)
                                      ↓ ou Push Gateway
┌───────────────────────────────────────────────────────────────┐
│                   Serveur de Monitoring Central               │
│                                                               │
│  Prometheus (9090) - Collecte et stockage des métriques      │
│  Grafana (3000) - Visualisation                               │
│  Alertmanager - Alertes                                        │
└───────────────────────────────────────────────────────────────┘
```

## Configuration

### 1. Configuration des exporters (sur les routeurs)

La configuration est déjà activée dans `hosts/rtr-noisy/default.nix` et peut être ajoutée à `hosts/rtr-sapinet/default.nix` si nécessaire.

**Pour activer sur rtr-sapinet:**

```nix
# Dans hosts/rtr-sapinet/default.nix
network-fabric.monitoring = {
  enable = true;
  lightweightMode = true;
  
  nodeExporter = {
    enable = true;
    port = 9100;
  };
  
  frrExporter = {
    enable = true;
    port = 2605;
  };
};
```

### 2. Configuration du serveur Prometheus distant

**Option 1: Mode Pull (recommandé)**

Configurer Prometheus pour scraper les exporters:

```yaml
# prometheus.yml sur le serveur central
scrape_configs:
  - job_name: 'rtr-sapinet'
    static_configs:
      - targets: ['rtr-sapinet:9100']  # Node Exporter
      - targets: ['rtr-sapinet:2605']  # FRR Exporter
  
  - job_name: 'rtr-noisy'
    static_configs:
      - targets: ['rtr-noisy:9100']    # Node Exporter
      - targets: ['rtr-noisy:9586']    # WireGuard Exporter
      - targets: ['rtr-noisy:2605']    # FRR Exporter
```

**Option 2: Mode Push (si les routeurs sont derrière NAT)**

Configurer le push gateway:

```nix
# Sur les routeurs
network-fabric.monitoring = {
  enable = true;
  lightweightMode = true;
  
  nodeExporter = {
    enable = true;
    port = 9100;
    pushGateway = "http://monitoring.example.com:9091";
  };
  
  # ... autres exporters
};
```

### 3. Configuration du pare-feu

Les ports des exporters sont déjà ouverts dans la configuration nftables. Pour autoriser l'accès depuis un serveur spécifique:

```nix
# Dans modules/security/nftables-advanced.nix
# Ajouter dans la chaîne input:
iifname "${wanInterface}" ip saddr { 1.2.3.4 } tcp dport { 9100 9586 2605 } accept comment "Allow monitoring server"
```

## Vérification

### 1. Vérifier que les exporters sont en cours d'exécution

```bash
# Sur chaque routeur
curl -s http://localhost:9100/metrics | head  # Node Exporter
curl -s http://localhost:9586/metrics | head  # WireGuard Exporter (rtr-noisy)
curl -s http://localhost:2605/metrics | head  # FRR Exporter
```

### 2. Vérifier les métriques spécifiques

**Node Exporter:**
```bash
curl -s http://localhost:9100/metrics | grep node_cpu
curl -s http://localhost:9100/metrics | grep node_memory
```

**WireGuard Exporter (rtr-noisy):**
```bash
curl -s http://localhost:9586/metrics | grep wireguard
```

**FRR Exporter:**
```bash
curl -s http://localhost:2605/metrics | grep frr_bgp
```

### 3. Vérifier depuis le serveur Prometheus

```bash
# Sur le serveur Prometheus
curl -s http://localhost:9090/targets | jq
```

## Métriques disponibles

### Node Exporter (9100)
- `node_cpu_seconds_total` - Utilisation CPU
- `node_memory_MemAvailable_bytes` - Mémoire disponible
- `node_network_receive_bytes_total` - Trafic réseau reçu
- `node_network_transmit_bytes_total` - Trafic réseau envoyé
- `node_load1`, `node_load5`, `node_load15` - Charge système
- `node_disk_io_time_seconds_total` - Temps d'I/O disque

### WireGuard Exporter (9586) - rtr-noisy seulement
- `wireguard_peers` - Nombre de pairs connectés
- `wireguard_data_received_bytes_total` - Données reçues
- `wireguard_data_sent_bytes_total` - Données envoyées
- `wireguard_handshake_seconds` - Temps depuis le dernier handshake
- `wireguard_peers_connected` - État de connexion des pairs

### FRR Exporter (2605)
- `frr_bgp_neighbor_state` - État des sessions BGP
- `frr_bgp_prefixes_received` - Préfixes reçus
- `frr_bgp_prefixes_advertised` - Préfixes annoncés
- `frr_bgp_neighbor_uptime_seconds` - Temps de fonctionnement de la session
- `frr_bgp_messages_received` - Messages BGP reçus
- `frr_bgp_messages_sent` - Messages BGP envoyés

## Alertes recommandées

Voici quelques règles d'alerte pour Prometheus:

```yaml
# alert.rules.yml
groups:
- name: network-alerts
  rules:
  - alert: WireGuardDown
    expr: wireguard_peers_connected == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "WireGuard tunnel is down"
      description: "WireGuard tunnel on {{ $labels.instance }} has been down for 5 minutes"
  
  - alert: BGPSessionDown
    expr: frr_bgp_neighbor_state{state="established"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "BGP session is down"
      description: "BGP session on {{ $labels.instance }} has been down for 5 minutes"
  
  - alert: HighCPUUsage
    expr: 100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100) > 80
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage"
      description: "CPU usage on {{ $labels.instance }} is above 80% for 10 minutes"
  
  - alert: HighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage"
      description: "Memory usage on {{ $labels.instance }} is above 85% for 10 minutes"
```

## Tableaux de bord Grafana

Même si Grafana n'est pas installé localement, vous pouvez importer les tableaux de bord fournis dans votre instance Grafana centrale:

1. Importer `modules/monitoring/dashboards/wireguard.json`
2. Importer `modules/monitoring/dashboards/bgp.json`
3. Importer `modules/monitoring/dashboards/system.json`

## Bonnes pratiques

1. **Sécurité:**
   - Limiter l'accès aux ports des exporters (9100, 9586, 2605)
   - Utiliser HTTPS si les exporters sont exposés sur Internet
   - Configurer l'authentification pour Prometheus

2. **Performance:**
   - Les exporters consomment très peu de ressources (quelques Mo de mémoire)
   - Le mode pull est préférable au mode push pour la précision
   - Intervalle de scrape recommandé: 15-30 secondes

3. **Maintenance:**
   - Vérifier régulièrement que les exporters sont accessibles
   - Surveiller les logs des exporters: `journalctl -u node-exporter`
   - Mettre à jour les exporters avec les packages système

## Dépannage

### Les exporters ne démarrent pas
```bash
# Vérifier les logs
journalctl -u node-exporter
journalctl -u wireguard-exporter
journalctl -u frr-exporter

# Vérifier les ports
ss -tulnp | grep -E "9100|9586|2605"

# Tester manuellement
curl -v http://localhost:9100/metrics
```

### Prometheus ne scrape pas les cibles
```bash
# Vérifier les cibles
curl -s http://prometheus:9090/targets | jq

# Vérifier la connectivité
ping rtr-sapinet
ping rtr-noisy

# Vérifier les pare-feux
nft list ruleset
```

### Métriques manquantes
```bash
# Vérifier que l'exporter a accès aux données
wg show  # Pour WireGuard
vtysh -c "show bgp summary"  # Pour BGP

# Vérifier les permissions
ls -la /etc/wireguard/
ls -la /var/run/frr/
```

## Conclusion

Cette configuration lightweight permet de surveiller efficacement l'infrastructure réseau sans alourdir les routeurs. Les exporters fournissent toutes les métriques nécessaires pour:
- Surveiller la santé des tunnels WireGuard
- Vérifier l'état des sessions BGP
- Suivre l'utilisation des ressources système
- Détecter les problèmes avant qu'ils n'affectent le service

Les métriques peuvent être collectées par un serveur Prometheus central pour une visualisation avec Grafana et la configuration d'alertes.
