# Configuration Sécurité Avancée 🔒

## Table des Matières

- [Sécurité SSH Avancée](#sécurité-ssh-avancée)
- [Pare-feu Avancé](#pare-feu-avancé)
- [Durcissement Système](#durcissement-système)
- [Fail2Ban](#fail2ban)
- [AppArmor](#apparmor)
- [Auditd](#auditd)
- [Gestion des Secrets](#gestion-des-secrets)
- [Mises à Jour de Sécurité](#mises-à-jour-de-sécurité)
- [Sécurité Réseau Intégrée](#sécurité-réseau-intégrée)

## Sécurité SSH Avancée

### Configuration Complète SSH

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.ssh = {
    enable = true;
    
    # Paramètres de base
    port = 2222;
    protocol = 2;
    
    # Authentification
    passwordAuthentication = false;
    permitRootLogin = "no";
    permitEmptyPasswords = false;
    challengeResponseAuthentication = false;
    
    # Contrôle d'accès
    allowUsers = [ "franck" "admin" ];
    allowGroups = [ "wheel" "sshusers" ];
    denyUsers = [ "guest" "test" ];
    
    # Sécurité de session
    maxAuthTries = 3;
    loginGraceTime = 30;
    maxSessions = 5;
    
    # Cryptographie
    kexAlgorithms = [
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
      "diffie-hellman-group-exchange-sha256"
    ];
    
    ciphers = [
      "chacha20-poly1305@openssh.com"
      "aes256-gcm@openssh.com"
      "aes128-gcm@openssh.com"
    ];
    
    macs = [
      "hmac-sha2-512-etm@openssh.com"
      "hmac-sha2-256-etm@openssh.com"
    ];
    
    # Bannière
    banner = ''
      ███╗   ██╗██╗███╗   ██╗██╗   ██╗██╗███████╗██████╗ 
      ████╗  ██║██║████╗  ██║██║   ██║██║██╔════╝██╔══██╗
      ██╔██╗ ██║██║██╔██╗ ██║██║   ██║██║█████╗  ██████╔╝
      ██║╚██╗██║██║██║╚██╗██║╚██╗ ██╔╝██║██╔══╝  ██╔══██╗
      ██║ ╚████║██║██║ ╚████║ ╚████╔╝ ██║███████╗██║  ██║
      ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚══════╝╚═╝  ╚═╝
      
      ACCES RESTREINT - SYSTEME NIXOS FABRIC
      Toute activité non autorisée sera surveillée et enregistrée
      
      Host: ${config.networking.hostName}
      Date: $(date)
      IP: $SSH_CONNECTION
    '';
    
    # Journalisation
    logLevel = "VERBOSE";
    printLastLog = true;
    
    # Paramètres avancés
    clientAliveInterval = 300;
    clientAliveCountMax = 2;
    tcpKeepAlive = true;
    
    # Restrictions supplémentaires
    allowTcpForwarding = false;
    x11Forwarding = false;
    permitTunnel = false;
  };
}
```

### Restriction par IP

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.ssh = {
    enable = true;
    
    # Restriction par IP
    listenAddress = [ "192.168.1.1" "10.0.0.1" ];
    
    # Ou utiliser le pare-feu pour restreindre
    firewallIntegration = {
      enable = true;
      allowedIPs = [ "192.168.1.0/24" "10.0.0.0/8" ];
    };
  };
}
```

## Pare-feu Avancé

### Configuration Complète du Pare-feu

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.firewall = {
    enable = true;
    
    # Politique par défaut
    defaultAction = "drop";
    
    # Interfaces
    interfaces = [
      {
        name = "ens18";
        zone = "external";
      }
      {
        name = "ens19";
        zone = "internal";
      }
      {
        name = "wg0";
        zone = "vpn";
      }
    ];
    
    # Zones
    zones = {
      external = {
        defaultAction = "drop";
        logLevel = "info";
      };
      internal = {
        defaultAction = "accept";
        logLevel = "warning";
      };
      vpn = {
        defaultAction = "accept";
        logLevel = "notice";
      };
    };
    
    # Règles globales
    globalRules = [
      {
        name = "allow-established";
        action = "accept";
        state = [ "ESTABLISHED" "RELATED" ];
      }
      {
        name = "allow-loopback";
        action = "accept";
        interface = "lo";
      }
      {
        name = "allow-icmp";
        action = "accept";
        protocol = "icmp";
        icmpType = [ "echo-request" "destination-unreachable" "time-exceeded" ];
      }
    ];
    
    # Règles par zone
    zoneRules = {
      external = [
        {
          name = "allow-ssh";
          action = "accept";
          protocol = "tcp";
          destinationPort = 2222;
          sourceIP = "192.168.1.0/24";
        }
        {
          name = "allow-http";
          action = "accept";
          protocol = "tcp";
          destinationPort = [ 80 443 ];
        }
        {
          name = "allow-wireguard";
          action = "accept";
          protocol = "udp";
          destinationPort = 51820;
        }
      ];
      
      internal = [
        {
          name = "allow-all-internal";
          action = "accept";
        }
      ];
    };
    
    # Rate limiting
    rateLimiting = {
      enable = true;
      rules = [
        {
          name = "ssh-protection";
          protocol = "tcp";
          destinationPort = 2222;
          limit = "5/minute";
          burst = 10;
        }
      ];
    };
    
    # Journalisation
    enableLogging = true;
    logLimit = "10/sec";
    logPrefix = "[NIXOS-FABRIC] ";
    
    # Options avancées
    enableSynCookies = true;
    enableTcpMssClamping = true;
    enableConntrack = true;
  };
}
```

### Règles de NAT

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.firewall = {
    enable = true;
    
    nat = {
      enable = true;
      
      # MASQUERADE pour le trafic sortant
      masquerade = {
        enable = true;
        interfaces = [ "ens18" ];
      };
      
      # Port forwarding
      portForwarding = [
        {
          name = "forward-http";
          protocol = "tcp";
          destinationPort = 80;
          toPort = 80;
          toIP = "192.168.1.100";
        }
        {
          name = "forward-ssh";
          protocol = "tcp";
          destinationPort = 2222;
          toPort = 22;
          toIP = "192.168.1.100";
        }
      ];
      
      # DNAT
      dnat = [
        {
          name = "dnat-example";
          protocol = "tcp";
          destinationIP = "203.0.113.10";
          destinationPort = 443;
          toIP = "192.168.1.50";
          toPort = 443;
        }
      ];
    };
  };
}
```

## Durcissement Système

### Configuration Complète de Durcissement

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.hardening = {
    enable = true;
    
    # Sécurité du noyau
    kernel = {
      # Protection mémoire
      randomizeVaSpace = true;
      kptrRestrict = 2;
      dmesgRestrict = 1;
      
      # Paramètres réseau
      ipForwarding = false;
      ipv6Forwarding = false;
      
      # Protection contre les attaques
      tcpSyncookies = 1;
      tcpRfc1337 = 1;
      
      # Restrictions diverses
      unprivilegedBpfDisabled = 1;
      unprivilegedUserfaultfd = 0;
    };
    
    # Sécurité des services
    services = {
      # Désactiver les services inutiles
      disableUnused = true;
      
      # Restrictions spécifiques
      restrictions = {
        sshd = {
          chroot = "/var/empty";
          privilegeSeparation = "sandbox";
        };
      };
    };
    
    # Sécurité des utilisateurs
    users = {
      # Restrictions des utilisateurs
      restrictions = {
        maxPasswordAge = 90;
        minPasswordAge = 1;
        passwordHistory = 5;
      };
      
      # Politiques de mot de passe
      passwordPolicy = {
        minLength = 12;
        requireUppercase = true;
        requireLowercase = true;
        requireDigit = true;
        requireSpecial = true;
      };
    };
    
    # Sécurité du système de fichiers
    filesystem = {
      # Montages sécurisés
      secureMounts = [
        {
          filesystem = "/tmp";
          options = [ "nodev" "nosuid" "noexec" ];
        }
        {
          filesystem = "/var/tmp";
          options = [ "nodev" "nosuid" "noexec" ];
        }
        {
          filesystem = "/dev/shm";
          options = [ "nodev" "nosuid" "noexec" ];
        }
      ];
      
      # Restrictions supplémentaires
      restrictHomePerms = true;
      restrictSystemPerms = true;
    };
    
    # Sécurité du réseau
    network = {
      # Désactiver les protocoles non sécurisés
      disableInsecureProtocols = true;
      
      # Restrictions ICMP
      icmpRestrictions = {
        echoIgnoreBroadcasts = true;
        ignoreBogusErrorResponses = true;
      };
    };
    
    # Journalisation et audit
    logging = {
      enableSyslog = true;
      remoteLogging = {
        enable = true;
        server = "log.example.com";
        port = 514;
      };
    };
  };
}
```

## Fail2Ban

### Configuration Complète Fail2Ban

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.fail2ban = {
    enable = true;
    
    # Paramètres globaux
    global = {
      bantime = 3600;
      findtime = 600;
      maxretry = 3;
      ignoreip = [ "127.0.0.1/8" "192.168.1.0/24" ];
      banaction = "iptables-multiport";
    };
    
    # Jails
    jails = {
      sshd = {
        enable = true;
        port = "2222";
        filter = "sshd";
        logpath = "/var/log/auth.log";
        maxretry = 3;
        bantime = 7200;
      };
      
      recidive = {
        enable = true;
        bantime = 86400;
        findtime = 86400;
        maxretry = 5;
      };
      
      nginx-badbots = {
        enable = true;
        port = "http,https";
        filter = "nginx-badbots";
        logpath = "/var/log/nginx/access.log";
        maxretry = 2;
      };
    };
    
    # Actions
    actions = {
      email = {
        enable = true;
        name = "email";
        action = "${pkgs.fail2ban}/libexec/fail2ban/action.d/mail-whois-lines.conf";
        dest = "admin@example.com";
        sender = "fail2ban@example.com";
      };
    };
    
    # Filtres personnalisés
    filters = {
      custom-ssh = {
        enable = true;
        definition = ''
          [Definition]
          failregex = ^%(__prefix_line)s(?:error: PAM: )?Authentication failure for .* from <HOST>$
                     ^%(__prefix_line)s(?:error: PAM: )?User not known to the underlying authentication module for .* from <HOST>$
        '';
      };
    };
  };
}
```

## AppArmor

### Configuration AppArmor

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.apparmor = {
    enable = true;
    
    # Mode global
    enforceMode = true;
    
    # Profils
    profiles = [
      {
        name = "frr";
        content = ''
          #include <tunables/global>
          
          /usr/lib/frr/** {
            #include <abstractions/base>
            #include <abstractions/nameservice>
            
            capability net_admin,
            capability net_raw,
            capability sys_admin,
            
            network inet stream,
            network inet6 stream,
            network inet dgram,
            network inet6 dgram,
            
            /etc/frr/** r,
            /var/run/frr/** rw,
            /var/log/frr/** w,
            
            deny /etc/shadow r,
            deny /etc/passwd w,
          }
        '';
      }
      {
        name = "wireguard";
        content = ''
          #include <tunables/global>
          
          /usr/bin/wg {
            #include <abstractions/base>
            
            capability net_admin,
            capability sys_module,
            
            /etc/wireguard/** r,
            /dev/net/tun rw,
            
            deny @{PROC}/kcore r,
            deny @{PROC}/mem r,
          }
        '';
      }
    ];
    
    # Intégration avec les services
    serviceIntegration = {
      frr = true;
      wireguard = true;
      sshd = true;
    };
  };
}
```

## Auditd

### Configuration Auditd

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.auditd = {
    enable = true;
    
    # Paramètres globaux
    global = {
      logFormat = "ENRICHED";
      logFile = "/var/log/audit/audit.log";
      maxLogFile = 100;
      maxLogFileAction = "ROTATE";
      spaceLeft = 75;
      spaceLeftAction = "SYSLOG";
      adminSpaceLeft = 50;
      adminSpaceLeftAction = "SUSPEND";
    };
    
    # Règles
    rules = [
      {
        name = "system-calls";
        content = ''
          -a always,exit -F arch=b64 -S execve,execveat -k exec
          -a always,exit -F arch=b32 -S execve,execveat -k exec
        '';
      }
      {
        name = "file-access";
        content = ''
          -w /etc/passwd -p wa -k identity
          -w /etc/shadow -p wa -k identity
          -w /etc/group -p wa -k identity
          -w /etc/sudoers -p wa -k privilege-escalation
        '';
      }
      {
        name = "network-changes";
        content = ''
          -w /etc/hosts -p wa -k network-modify
          -w /etc/resolv.conf -p wa -k network-modify
          -w /etc/network/ -p wa -k network-modify
        '';
      }
      {
        name = "user-logins";
        content = ''
          -w /var/log/faillog -p wa -k logins
          -w /var/log/lastlog -p wa -k logins
          -w /var/log/tallylog -p wa -k logins
        '';
      }
    ];
    
    # Alertes
    alerts = {
      email = {
        enable = true;
        to = "admin@example.com";
        from = "auditd@example.com";
        subject = "Audit Alert: ${config.networking.hostName}";
      };
    };
  };
}
```

## Gestion des Secrets

### Configuration de la Gestion des Secrets

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.secrets = {
    enable = true;
    
    # Backend
    backend = "age";
    
    # Configuration du backend
    age = {
      keyFile = "/etc/nixos-fabric/secrets/key.txt";
      configDir = "/etc/nixos-fabric/secrets";
    };
    
    # Secrets
    secrets = [
      {
        name = "wireguard-private-key";
        path = "/etc/wireguard/private.key";
        owner = "root";
        group = "wireguard";
        permissions = "600";
        content = "AGE-ENCRYPTED-SECRET";
      }
      {
        name = "frr-password";
        path = "/etc/frr/frr.conf";
        owner = "frr";
        group = "frr";
        permissions = "640";
        content = "AGE-ENCRYPTED-SECRET";
      }
    ];
    
    # Intégration avec les services
    serviceIntegration = {
      wireguard = true;
      frr = true;
      sshd = true;
    };
  };
}
```

## Mises à Jour de Sécurité

### Configuration des Mises à Jour

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.updates = {
    enable = true;
    
    # Vérification automatique
    autoCheck = {
      enable = true;
      interval = "daily";
      time = "03:00";
    };
    
    # Mises à jour automatiques (déconseillé en production)
    autoUpdate = {
      enable = false;
      interval = "weekly";
      time = "04:00";
      reboot = false;
    };
    
    # Notifications
    notifications = {
      email = {
        enable = true;
        to = "admin@example.com";
        from = "updates@example.com";
        subject = "Security Updates Available: ${config.networking.hostName}";
      };
      
      slack = {
        enable = false;
        webhook = "https://hooks.slack.com/...";
        channel = "#security-updates";
      };
    };
    
    # Exclusions
    exclusions = {
      packages = [ "linux" ]; # Ne pas mettre à jour le noyau automatiquement
      services = [ "frr" ];    # Services critiques
    };
  };
}
```

## Sécurité Réseau Intégrée

### Configuration Complète de Sécurité Réseau

```nix
{ config, pkgs, ... }:
{
  network-fabric.security.network-security = {
    enable = true;
    
    # Politiques globales
    policies = {
      defaultDeny = true;
      stateTracking = true;
      enableLogging = true;
      logLevel = "info";
    };
    
    # Sécurité par protocole
    protocolSecurity = {
      bgp = {
        ttlSecurity = true;
        ttlValue = 254;
        prefixFiltering = true;
        maxPrefixes = 1000;
        rpkiValidation = true;
      };
      
      ospf = {
        authentication = true;
        authType = "md5";
        authKey = "secret";
      };
      
      wireguard = {
        rateLimiting = true;
        interfaceRestriction = true;
        firewallIntegration = true;
      };
    };
    
    # Sécurité des interfaces
    interfaceSecurity = {
      ens18 = {
        spoofingProtection = true;
        smurfProtection = true;
        broadcastProtection = true;
      };
      
      wg0 = {
        vpnSecurity = true;
        tunnelProtection = true;
      };
    };
    
    # Détection d'intrusion
    intrusionDetection = {
      enable = true;
      
      signatures = {
        scanDetection = true;
        portScanDetection = true;
        dosDetection = true;
      };
      
      actions = {
        banIP = true;
        banTime = 3600;
        logIncident = true;
      };
    };
    
    # Intégration avec le monitoring
    monitoringIntegration = {
      enable = true;
      
      metrics = {
        securityEvents = true;
        firewallStats = true;
        intrusionAttempts = true;
      };
      
      alerts = {
        critical = true;
        warning = true;
        threshold = 10;
      };
    };
  };
}
```

## Bonnes Pratiques de Sécurité

### 1. Principes de Base

- **Moindres privilèges** : Donnez seulement les permissions nécessaires
- **Défense en profondeur** : Plusieurs couches de sécurité
- **Sécurité par défaut** : Tout est bloqué sauf ce qui est explicitement autorisé
- **Journalisation complète** : Tout doit être journalisé et surveillé

### 2. Configuration SSH

- **Désactivez** toujours l'authentification par mot de passe
- **Utilisez** des clés SSH fortes (ED25519)
- **Changez** le port SSH par défaut
- **Limitez** les tentatives de connexion
- **Activez** Fail2Ban pour SSH

### 3. Pare-feu

- **Bloquez** tout par défaut
- **Autorisez** seulement les ports nécessaires
- **Activez** le logging pour les connexions bloquées
- **Configurez** le rate limiting pour les services exposés
- **Testez** régulièrement vos règles

### 4. Durcissement

- **Désactivez** les services inutiles
- **Appliquez** les mises à jour de sécurité régulièrement
- **Configurez** AppArmor pour les services critiques
- **Activez** Auditd pour le monitoring
- **Sécurisez** le système de fichiers

### 5. Monitoring

- **Surveillez** les logs système
- **Configurez** des alertes pour les événements critiques
- **Vérifiez** régulièrement les tentatives d'intrusion
- **Analysez** les patterns de trafic réseau
- **Documentez** les incidents de sécurité

## Exemples Complets

Voir les fichiers dans `examples/` pour des configurations complètes :

- `examples/security-example.nix` - Exemple de sécurité de base
- `examples/security-improved-example.nix` - Configuration sécurité complète
- `examples/network-security-config.nix` - Sécurité réseau intégrée