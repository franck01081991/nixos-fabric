# Problèmes de Sécurité et Solutions 🔒

## Table des Matières

- [Problèmes SSH](#problèmes-ssh)
- [Problèmes de Pare-feu](#problèmes-de-pare-feu)
- [Problèmes de Durcissement](#problèmes-de-durcissement)
- [Problèmes Fail2Ban](#problèmes-fail2ban)
- [Problèmes AppArmor](#problèmes-apparmor)
- [Problèmes Auditd](#problèmes-auditd)
- [Problèmes de Gestion des Secrets](#problèmes-de-gestion-des-secrets)
- [Problèmes de Mises à Jour](#problèmes-de-mises-à-jour)
- [Problèmes de Sécurité Réseau](#problèmes-de-sécurité-réseau)
- [Outils de Diagnostic](#outils-de-diagnostic)

## Problèmes SSH

### Connexion SSH Refusée

**Symptôme** : Impossible de se connecter en SSH

**Diagnostic** :
```bash
ssh -v user@host
journalctl -u sshd
ss -tulnp | grep 22
```

**Causes possibles** :
- Service SSH désactivé
- Port SSH incorrect
- Pare-feu bloquant le port SSH
- Authentification incorrecte

**Solution** :
1. Vérifiez que le service SSH est activé :
   ```nix
   network-fabric.security.ssh = {
     enable = true;
     port = 2222;
   };
   ```
2. Vérifiez le pare-feu :
   ```nix
   network-fabric.security.firewall = {
     enable = true;
     allowedTCP = [ 2222 ];
   };
   ```
3. Testez avec l'authentification par clé

### Authentification SSH Échouée

**Symptôme** : L'authentification SSH échoue

**Diagnostic** :
```bash
ssh -v user@host
journalctl -u sshd
tail -f /var/log/auth.log
```

**Causes possibles** :
- Clé SSH incorrecte
- Permissions incorrectes sur les fichiers SSH
- Authentification par mot de passe désactivée
- Compte utilisateur verrouillé

**Solution** :
1. Vérifiez les permissions :
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   chown user:user ~/.ssh -R
   ```
2. Vérifiez la configuration SSH :
   ```nix
   network-fabric.security.ssh = {
     enable = true;
     passwordAuthentication = false;
     allowUsers = [ "user" ];
   };
   ```
3. Testez avec une nouvelle paire de clés

### Tentatives de Connexion SSH Excessives

**Symptôme** : Nombre élevé de tentatives de connexion SSH

**Diagnostic** :
```bash
journalctl -u sshd | grep "Failed password"
fail2ban-client status sshd
grep "sshd" /var/log/auth.log
```

**Causes possibles** :
- Attaque par force brute
- Configuration SSH trop permissive
- Absence de Fail2Ban

**Solution** :
1. Configurez Fail2Ban :
   ```nix
   network-fabric.security.fail2ban = {
     enable = true;
     jails.sshd = {
       enable = true;
       maxretry = 3;
       bantime = 3600;
     };
   };
   ```
2. Changez le port SSH par défaut
3. Limitez les utilisateurs autorisés

## Problèmes de Pare-feu

### Connexions Non Bloquées

**Symptôme** : Le pare-feu ne bloque pas les connexions indésirables

**Diagnostic** :
```bash
sudo nft list ruleset
journalctl -u nftables
tcpdump -i interface port 22
```

**Causes possibles** :
- Politique par défaut incorrecte
- Règles manquantes ou mal ordonnées
- Service pare-feu désactivé

**Solution** :
1. Configurez une politique par défaut restrictive :
   ```nix
   network-fabric.security.firewall = {
     enable = true;
     defaultAction = "drop";
   };
   ```
2. Ajoutez des règles spécifiques pour les services nécessaires
3. Vérifiez l'ordre des règles

### Connexions Légitimes Bloquées

**Symptôme** : Le pare-feu bloque des connexions légitimes

**Diagnostic** :
```bash
sudo nft list ruleset
journalctl -u nftables
tcpdump -i interface port 80
```

**Causes possibles** :
- Règles trop restrictives
- Ordre des règles incorrect
- Problème de zones réseau

**Solution** :
1. Vérifiez les règles du pare-feu :
   ```nix
   network-fabric.security.firewall = {
     enable = true;
     allowedTCP = [ 80 443 ];
     allowedUDP = [ 53 ];
   };
   ```
2. Testez avec des règles temporaires
3. Vérifiez les logs pour identifier les connexions bloquées

### Pare-feu Ne Démarre Pas

**Symptôme** : Le service pare-feu ne démarre pas

**Diagnostic** :
```bash
systemctl status nftables
journalctl -u nftables
sudo nft -c -f /etc/nftables.conf
```

**Causes possibles** :
- Erreur de syntaxe dans les règles
- Conflit avec d'autres services
- Module noyau manquant

**Solution** :
1. Vérifiez la syntaxe des règles
2. Désactivez les services conflictuels
3. Vérifiez que les modules noyau sont chargés

## Problèmes de Durcissement

### Paramètres de Noyau Non Appliqués

**Symptôme** : Les paramètres de durcissement du noyau ne sont pas appliqués

**Diagnostic** :
```bash
sysctl -a | grep kernel.kptr_restrict
cat /proc/sys/kernel/kptr_restrict
```

**Causes possibles** :
- Configuration incorrecte
- Module de durcissement désactivé
- Conflit avec d'autres paramètres

**Solution** :
1. Vérifiez la configuration de durcissement :
   ```nix
   network-fabric.security.hardening = {
     enable = true;
     kernel = {
       kptrRestrict = 2;
       randomizeVaSpace = true;
     };
   };
   ```
2. Appliquez manuellement les paramètres :
   ```bash
   sudo sysctl -w kernel.kptr_restrict=2
   ```

### Montages Sécurisés Non Appliqués

**Symptôme** : Les options de montage sécurisées ne sont pas appliquées

**Diagnostic** :
```bash
mount | grep /tmp
cat /proc/mounts | grep /tmp
```

**Causes possibles** :
- Configuration incorrecte
- Conflit avec d'autres montages
- Service de durcissement désactivé

**Solution** :
1. Vérifiez la configuration des montages :
   ```nix
   network-fabric.security.hardening = {
     enable = true;
     filesystem = {
       secureMounts = [
         {
           filesystem = "/tmp";
           options = [ "nodev" "nosuid" "noexec" ];
         }
       ];
     };
   };
   ```
2. Montez manuellement avec les options correctes

## Problèmes Fail2Ban

### Fail2Ban Ne Bannit Pas les IP

**Symptôme** : Fail2Ban ne bannit pas les IP malgré les tentatives d'intrusion

**Diagnostic** :
```bash
fail2ban-client status
fail2ban-client status sshd
journalctl -u fail2ban
tail -f /var/log/fail2ban.log
```

**Causes possibles** :
- Configuration incorrecte
- Service Fail2Ban désactivé
- Logs non surveillés

**Solution** :
1. Vérifiez la configuration Fail2Ban :
   ```nix
   network-fabric.security.fail2ban = {
     enable = true;
     jails.sshd = {
       enable = true;
       maxretry = 3;
       bantime = 3600;
     };
   };
   ```
2. Vérifiez que le service est démarré
3. Testez manuellement le bannissement

### IP Bannies Incorrectement

**Symptôme** : Fail2Ban bannit des IP légitimes

**Diagnostic** :
```bash
fail2ban-client status sshd
journalctl -u fail2ban
grep "fail2ban" /var/log/auth.log
```

**Causes possibles** :
- Seuil trop bas
- Faux positifs dans les logs
- Configuration incorrecte

**Solution** :
1. Ajustez les paramètres de détection :
   ```nix
   network-fabric.security.fail2ban = {
     jails.sshd = {
       maxretry = 5;
       findtime = 600;
     };
   };
   ```
2. Ajoutez les IP légitimes à la liste d'exclusion
3. Vérifiez les expressions régulières des filtres

## Problèmes AppArmor

### Profils AppArmor Non Chargés

**Symptôme** : Les profils AppArmor ne sont pas chargés

**Diagnostic** :
```bash
sudo aa-status
sudo apparmor_status
journalctl -u apparmor
```

**Causes possibles** :
- Service AppArmor désactivé
- Configuration incorrecte
- Erreur de syntaxe dans les profils

**Solution** :
1. Vérifiez que le service est activé :
   ```nix
   network-fabric.security.apparmor = {
     enable = true;
     enforceMode = true;
   };
   ```
2. Vérifiez la syntaxe des profils
3. Chargez manuellement les profils

### Applications Bloquées par AppArmor

**Symptôme** : Les applications sont bloquées par AppArmor

**Diagnostic** :
```bash
sudo aa-status
journalctl -u apparmor
dmesg | grep apparmor
```

**Causes possibles** :
- Profil trop restrictif
- Permissions manquantes
- Chemin incorrect dans le profil

**Solution** :
1. Passez en mode "complain" pour le débogage :
   ```bash
   sudo aa-complain /usr/bin/application
   ```
2. Analysez les logs pour identifier les permissions manquantes
3. Mettez à jour le profil AppArmor

## Problèmes Auditd

### Auditd Ne Journalise Pas

**Symptôme** : Auditd ne journalise pas les événements

**Diagnostic** :
```bash
systemctl status auditd
journalctl -u auditd
tail -f /var/log/audit/audit.log
```

**Causes possibles** :
- Service Auditd désactivé
- Configuration incorrecte
- Permissions incorrectes sur les fichiers de log

**Solution** :
1. Vérifiez que le service est activé :
   ```nix
   network-fabric.security.auditd = {
     enable = true;
   };
   ```
2. Vérifiez les permissions des fichiers de log
3. Testez avec des règles de base

### Fichiers de Log Auditd Trop Volumineux

**Symptôme** : Les fichiers de log Auditd deviennent trop volumineux

**Diagnostic** :
```bash
ls -lh /var/log/audit/
df -h
```

**Causes possibles** :
- Rotation des logs désactivée
- Trop d'événements journalisés
- Configuration de rotation incorrecte

**Solution** :
1. Configurez la rotation des logs :
   ```nix
   network-fabric.security.auditd = {
     global = {
       maxLogFile = 50;
       maxLogFileAction = "ROTATE";
     };
   };
   ```
2. Limitez les événements journalisés
3. Configurez une rotation externe avec logrotate

## Problèmes de Gestion des Secrets

### Secrets Non Déchiffrés

**Symptôme** : Les secrets ne sont pas déchiffrés correctement

**Diagnostic** :
```bash
journalctl -b
cat /etc/nixos-fabric/secrets/key.txt
```

**Causes possibles** :
- Clé de chiffrement incorrecte
- Backend de chiffrement non supporté
- Permissions incorrectes sur les fichiers

**Solution** :
1. Vérifiez la configuration des secrets :
   ```nix
   network-fabric.security.secrets = {
     enable = true;
     backend = "age";
     age = {
       keyFile = "/etc/nixos-fabric/secrets/key.txt";
     };
   };
   ```
2. Vérifiez que la clé est correcte
3. Testez le déchiffrement manuellement

### Permissions Incorrectes sur les Secrets

**Symptôme** : Les fichiers de secrets ont des permissions incorrectes

**Diagnostic** :
```bash
ls -la /etc/secrets/
cat /etc/nixos-fabric/secrets/key.txt
```

**Causes possibles** :
- Configuration incorrecte
- Processus de déploiement incorrect
- Attaque sur les permissions

**Solution** :
1. Configurez les permissions correctes :
   ```nix
   network-fabric.security.secrets = {
     secrets = [
       {
         name = "example-secret";
         path = "/etc/example/secret.conf";
         owner = "root";
         group = "example";
         permissions = "640";
       }
     ];
   };
   ```
2. Vérifiez les permissions après déploiement

## Problèmes de Mises à Jour

### Mises à Jour Non Appliquées

**Symptôme** : Les mises à jour de sécurité ne sont pas appliquées

**Diagnostic** :
```bash
nix-env -u
nix-channel --list
journalctl -u nix-daemon
```

**Causes possibles** :
- Configuration incorrecte
- Service de mises à jour désactivé
- Conflit de versions

**Solution** :
1. Vérifiez la configuration des mises à jour :
   ```nix
   network-fabric.security.updates = {
     enable = true;
     autoCheck = {
       enable = true;
       interval = "daily";
     };
   };
   ```
2. Appliquez manuellement les mises à jour
3. Vérifiez les canaux Nix

### Mises à Jour Automatiques Échouées

**Symptôme** : Les mises à jour automatiques échouent

**Diagnostic** :
```bash
journalctl -u nix-daemon
nixos-rebuild dry-activate
```

**Causes possibles** :
- Configuration incorrecte
- Problème de réseau
- Conflit de configuration

**Solution** :
1. Vérifiez les logs pour identifier l'erreur
2. Testez les mises à jour manuellement
3. Corrigiez les conflits de configuration

## Problèmes de Sécurité Réseau

### Sécurité BGP Non Appliquée

**Symptôme** : La sécurité BGP n'est pas appliquée

**Diagnostic** :
```bash
show ip bgp neighbors
show running-config
```

**Causes possibles** :
- Configuration incorrecte
- Module de sécurité réseau désactivé
- Problème de compatibilité

**Solution** :
1. Vérifiez la configuration de sécurité BGP :
   ```nix
   network-fabric.security.network-security = {
     enable = true;
     protocolSecurity.bgp = {
       ttlSecurity = true;
       ttlValue = 254;
     };
   };
   ```
2. Vérifiez la configuration FRR
3. Testez la connectivité BGP

### Sécurité WireGuard Non Appliquée

**Symptôme** : La sécurité WireGuard n'est pas appliquée

**Diagnostic** :
```bash
wg show
ip route show
sudo nft list ruleset
```

**Causes possibles** :
- Configuration incorrecte
- Règles de pare-feu manquantes
- Problème de routage

**Solution** :
1. Vérifiez la configuration de sécurité WireGuard :
   ```nix
   network-fabric.security.network-security = {
     enable = true;
     protocolSecurity.wireguard = {
       rateLimiting = true;
       interfaceRestriction = true;
     };
   };
   ```
2. Vérifiez les règles de pare-feu
3. Testez la connectivité WireGuard

## Outils de Diagnostic

### Outils de Sécurité SSH

```bash
# Vérifier la configuration SSH
ssh -v user@host
ssh -G user@host

# Vérifier les connexions SSH
ss -tulnp | grep ssh
netstat -tulnp | grep ssh

# Vérifier les logs SSH
journalctl -u sshd
tail -f /var/log/auth.log

# Tester l'authentification
ssh -i ~/.ssh/key.pem user@host
```

### Outils de Pare-feu

```bash
# Vérifier les règles de pare-feu
sudo nft list ruleset
sudo nft list ruleset -a

# Vérifier les connexions
ss -tulnp
netstat -tulnp

# Tester les règles
sudo nft add rule ip filter INPUT tcp dport 80 accept
sudo nft delete rule ip filter INPUT handle X

# Vérifier les logs
journalctl -u nftables
tail -f /var/log/kern.log | grep nftables
```

### Outils de Durcissement

```bash
# Vérifier les paramètres du noyau
sysctl -a
cat /proc/sys/kernel/*

# Vérifier les montages
mount
cat /proc/mounts

# Vérifier les services
systemctl list-units --type=service

# Vérifier les utilisateurs
cat /etc/passwd
cat /etc/shadow
```

### Outils Fail2Ban

```bash
# Vérifier le statut Fail2Ban
fail2ban-client status
fail2ban-client status sshd

# Vérifier les logs
journalctl -u fail2ban
tail -f /var/log/fail2ban.log

# Tester le bannissement
fail2ban-client set sshd banip 192.168.1.100
fail2ban-client set sshd unbanip 192.168.1.100

# Vérifier les jails
fail2ban-client status
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf
```

### Outils AppArmor

```bash
# Vérifier le statut AppArmor
sudo aa-status
sudo apparmor_status

# Vérifier les profils
cat /etc/apparmor.d/*

# Vérifier les logs
journalctl -u apparmor
dmesg | grep apparmor

# Tester les profils
sudo apparmor_parser -r /etc/apparmor.d/profile
sudo aa-complain /usr/bin/application
sudo aa-enforce /usr/bin/application
```

### Outils Auditd

```bash
# Vérifier le statut Auditd
systemctl status auditd
journalctl -u auditd

# Vérifier les règles
auditctl -l
auditctl -s

# Vérifier les logs
tail -f /var/log/audit/audit.log
ausearch -m USER_LOGIN -i

# Tester les règles
auditctl -a exit,always -F arch=b64 -S execve
```

### Outils de Gestion des Secrets

```bash
# Vérifier les secrets
ls -la /etc/nixos-fabric/secrets/
cat /etc/nixos-fabric/secrets/key.txt

# Tester le chiffrement
age -d -i /etc/nixos-fabric/secrets/key.txt -o secret.txt secret.age

# Vérifier les permissions
ls -la /etc/secrets/
chmod 600 /etc/secrets/*
```

## Bonnes Pratiques de Sécurité

### 1. Principes de Base

- **Moindres privilèges** : Donnez seulement les permissions nécessaires
- **Défense en profondeur** : Plusieurs couches de sécurité
- **Sécurité par défaut** : Tout est bloqué sauf ce qui est explicitement autorisé
- **Journalisation complète** : Tout doit être journalisé et surveillé

### 2. Maintenance

- **Mettez à jour** régulièrement les systèmes
- **Surveillez** les logs de sécurité
- **Testez** les configurations de sécurité
- **Documentez** les configurations

### 3. Réponse aux Incidents

- **Isolez** les systèmes compromis
- **Analysez** les logs et les événements
- **Corrigez** les vulnérabilités
- **Communiquez** les incidents

### 4. Amélioration Continue

- **Évaluez** régulièrement la sécurité
- **Testez** les défenses
- **Formez** le personnel
- **Améliorez** les processus

## Ressources Supplémentaires

- [Guide de Sécurité NixOS](https://nixos.org/manual/nixos/stable/index.html#sec-security)
- [Documentation Fail2Ban](https://www.fail2ban.org/wiki/index.php/Main_Page)
- [Documentation AppArmor](https://wiki.ubuntu.com/AppArmor)
- [Documentation Auditd](https://linux.die.net/man/8/auditd)
- [Guide de Sécurité Linux](https://www.tldp.org/HOWTO/Security-HOWTO/)
- [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/)