# Configuration Sécurité de Base 🔒

## Configuration Sécurité Minimale

```nix
# Fichier: hosts/secure-host/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "secure-host";
  
  # Interface réseau
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "192.168.1.10";
    prefixLength = 24;
  } ];
  
  # Sécurité SSH
  network-fabric.security.ssh = {
    enable = true;
    port = 2222;
    passwordAuthentication = false;
    permitRootLogin = "no";
    allowUsers = [ "admin" ];
    maxAuthTries = 3;
  };
  
  # Pare-feu de base
  network-fabric.security.firewall = {
    enable = true;
    defaultAction = "drop";
    allowedTCP = [ 2222 80 443 ];
    allowedUDP = [ 123 ]; # NTP
    allowedICMP = true;
    enableLogging = true;
  };
  
  # Durcissement système
  network-fabric.security.hardening = {
    enable = true;
    kernel = {
      randomizeVaSpace = true;
      kptrRestrict = 2;
    };
    filesystem = {
      secureMounts = [
        {
          filesystem = "/tmp";
          options = [ "nodev" "nosuid" "noexec" ];
        }
      ];
    };
  };
  
  # Utilisateur sécurisé
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3..." ];
  };
}
```

## Configuration avec Fail2Ban

```nix
# Fichier: hosts/fail2ban-host/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "fail2ban-host";
  
  # Sécurité avec Fail2Ban
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
      passwordAuthentication = false;
    };
    
    firewall = {
      enable = true;
      allowedTCP = [ 2222 80 443 ];
      allowedICMP = true;
    };
    
    fail2ban = {
      enable = true;
      
      global = {
        bantime = 3600;
        findtime = 600;
        maxretry = 3;
        ignoreip = [ "127.0.0.1/8" "192.168.1.0/24" ];
      };
      
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
      };
    };
  };
}
```

## Configuration avec AppArmor

```nix
# Fichier: hosts/apparmor-host/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "apparmor-host";
  
  # Sécurité avec AppArmor
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
    };
    
    firewall = {
      enable = true;
      allowedTCP = [ 2222 ];
      allowedICMP = true;
    };
    
    apparmor = {
      enable = true;
      enforceMode = true;
      
      profiles = [
        {
          name = "nginx";
          content = ''
            #include <tunables/global>
            
            /usr/bin/nginx {
              #include <abstractions/base>
              #include <abstractions/nameservice>
              
              capability net_bind_service,
              capability setgid,
              capability setuid,
              
              /etc/nginx/** r,
              /var/log/nginx/** w,
              /var/www/** r,
              
              deny /etc/shadow r,
              deny /etc/passwd w,
            }
          '';
        }
      ];
    };
  };
  
  # Service nginx
  services.nginx = {
    enable = true;
    recommendProxySettings = true;
  };
}
```

## Configuration avec Auditd

```nix
# Fichier: hosts/auditd-host/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "auditd-host";
  
  # Sécurité avec Auditd
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
    };
    
    firewall = {
      enable = true;
      allowedTCP = [ 2222 ];
      allowedICMP = true;
    };
    
    auditd = {
      enable = true;
      
      global = {
        logFormat = "ENRICHED";
        maxLogFile = 100;
        maxLogFileAction = "ROTATE";
      };
      
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
      ];
    };
  };
}
```

## Configuration Sécurité Réseau

```nix
# Fichier: hosts/network-secure-host/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/networking/networking.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "network-secure-host";
  
  # Interfaces réseau
  networking.interfaces = {
    ens18 = {
      ipv4.addresses = [ { address = "192.168.1.10"; prefixLength = 24; } ];
      description = "Management Interface";
    };
    ens19 = {
      ipv4.addresses = [ { address = "10.0.0.10"; prefixLength = 24; } ];
      description = "Data Interface";
    };
  };
  
  # Sécurité réseau
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
      allowedIPs = [ "192.168.1.0/24" ]; # Seulement depuis le réseau management
    };
    
    firewall = {
      enable = true;
      
      # Zones réseau
      interfaces = [
        {
          name = "ens18";
          zone = "management";
        }
        {
          name = "ens19";
          zone = "data";
        }
      ];
      
      zones = {
        management = {
          defaultAction = "accept";
          logLevel = "info";
        };
        data = {
          defaultAction = "drop";
          logLevel = "warning";
        };
      };
      
      zoneRules = {
        management = [
          {
            name = "allow-ssh";
            action = "accept";
            protocol = "tcp";
            destinationPort = 2222;
          }
        ];
        data = [
          {
            name = "allow-http";
            action = "accept";
            protocol = "tcp";
            destinationPort = [ 80 443 ];
          }
        ];
      };
    };
    
    network-security = {
      enable = true;
      
      interfaceSecurity = {
        ens18 = {
          spoofingProtection = true;
        };
        ens19 = {
          spoofingProtection = true;
          smurfProtection = true;
        };
      };
    };
  };
}
```

## Configuration avec Gestion des Secrets

```nix
# Fichier: hosts/secrets-host/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "secrets-host";
  
  # Gestion des secrets
  network-fabric.security = {
    ssh = {
      enable = true;
      port = 2222;
    };
    
    firewall = {
      enable = true;
      allowedTCP = [ 2222 ];
      allowedICMP = true;
    };
    
    secrets = {
      enable = true;
      backend = "age";
      
      age = {
        keyFile = "/etc/nixos-fabric/secrets/key.txt";
        configDir = "/etc/nixos-fabric/secrets";
      };
      
      secrets = [
        {
          name = "example-secret";
          path = "/etc/example/secret.conf";
          owner = "root";
          group = "example";
          permissions = "640";
          content = "AGE-ENCRYPTED-SECRET-HERE";
        }
      ];
    };
  };
}
```

## Configuration Sécurité Complète

```nix
# Fichier: hosts/full-secure-host/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../modules/core/base.nix
    ../../modules/security/default.nix
  ];
  
  # Configuration de base
  networking.hostName = "full-secure-host";
  
  # Interface réseau
  networking.interfaces.ens18.ipv4.addresses = [ {
    address = "192.168.1.10";
    prefixLength = 24;
  } ];
  
  # Configuration sécurité complète
  network-fabric.security = {
    # SSH sécurisé
    ssh = {
      enable = true;
      port = 2222;
      protocol = 2;
      passwordAuthentication = false;
      permitRootLogin = "no";
      allowUsers = [ "admin" ];
      maxAuthTries = 3;
      loginGraceTime = 30;
      
      # Cryptographie forte
      kexAlgorithms = [ "curve25519-sha256" ];
      ciphers = [ "chacha20-poly1305@openssh.com" ];
      macs = [ "hmac-sha2-512-etm@openssh.com" ];
    };
    
    # Pare-feu avancé
    firewall = {
      enable = true;
      defaultAction = "drop";
      
      allowedTCP = [ 2222 80 443 ];
      allowedUDP = [ 123 ];
      allowedICMP = true;
      
      enableLogging = true;
      logLimit = "10/sec";
      
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
    };
    
    # Fail2Ban
    fail2ban = {
      enable = true;
      
      jails = {
        sshd = {
          enable = true;
          port = "2222";
          maxretry = 3;
          bantime = 7200;
        };
      };
    };
    
    # Durcissement système
    hardening = {
      enable = true;
      
      kernel = {
        randomizeVaSpace = true;
        kptrRestrict = 2;
        dmesgRestrict = 1;
        tcpSyncookies = 1;
      };
      
      filesystem = {
        secureMounts = [
          {
            filesystem = "/tmp";
            options = [ "nodev" "nosuid" "noexec" ];
          }
          {
            filesystem = "/var/tmp";
            options = [ "nodev" "nosuid" "noexec" ];
          }
        ];
      };
    };
    
    # Auditd
    auditd = {
      enable = true;
      
      rules = [
        {
          name = "critical-files";
          content = ''
            -w /etc/passwd -p wa -k identity
            -w /etc/shadow -p wa -k identity
          '';
        }
      ];
    };
  };
  
  # Utilisateur sécurisé
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3..." ];
  };
}
```

## Bonnes Pratiques de Sécurité

### 1. Principes Fondamentaux

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

## Exemples Supplémentaires

Voir aussi :

- `examples/security-example.nix` - Exemple de sécurité de base
- `examples/security-improved-example.nix` - Configuration sécurité complète
- `examples/network-security-config.nix` - Sécurité réseau intégrée
- Tests dans `tests/integration/fabric/security-*.nix` pour des scénarios réels