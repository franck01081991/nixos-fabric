{ config, lib, pkgs, ... }:

# Improved Security Module for NixOS Fabric
# This module provides comprehensive security configuration and secret management

let
  inherit (lib) mkOption mkDefault mkEnableOption mkIf mkForce;
  inherit (lib.types) submodule str bool listOf attrs;

  # Default security configuration
  defaultSecurityConfig = {
    # SSH configuration
    ssh = {
      enable = true;
      port = 22;
      passwordAuthentication = false;
      permitRootLogin = "no";
      allowUsers = [ "franck" ];
      allowGroups = [ "wheel" ];
      maxAuthTries = 3;
      loginGraceTime = 30;
      banner = "/etc/issue";
    };
    
    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCP = [ 22 80 443 51820 ];  # SSH, HTTP, HTTPS, WireGuard
      allowedUDP = [ 51820 ];             # WireGuard
      allowedICMP = true;
      enableLogging = true;
      logLimit = "10/sec";
    };
    
    # Fail2ban configuration
    fail2ban = {
      enable = true;
      bantime = 3600;
      findtime = 600;
      maxretry = 3;
      
      # Jails to enable
      jails = {
        sshd = true;
        recidive = true;
      };
    };
    
    # AppArmor configuration
    apparmor = {
      enable = true;
      profiles = [ "frr" "wireguard" "ssh" ];
      enforceMode = true;
    };
    
    # Auditd configuration
    auditd = {
      enable = true;
      spaceLeft = 50;  # MB
      spaceLeftAction = "email";
      adminSpaceLeft = 25;  # MB
      maxLogFile = 10;
      maxLogFileAction = "rotate";
    };
    
    # Secret management
    secrets = {
      enable = true;
      backend = "age";  # or "sops" or "vault"
      keyFile = "/etc/nixos-fabric/secrets/key.txt";
      configDir = "/etc/nixos-fabric/secrets";
    };
    
    # Security updates
    updates = {
      enable = true;
      autoUpdate = false;
      checkInterval = "daily";
      emailNotifications = "admin@example.com";
    };
  };

  # Generate SSH banner
  sshBanner = ''
    ##########################################################
    #  NixOS Fabric - ${config.network-fabric.name}
    #  Environment: ${config.network-fabric.environment}
    #  Access: Authorized personnel only
    #  Monitoring: All activities are logged and monitored
    ##########################################################
  '';

  # Generate firewall rules
  generateFirewallRules = securityConfig: 
    let
      allowedTCP = securityConfig.firewall.allowedTCP or defaultSecurityConfig.firewall.allowedTCP;
      allowedUDP = securityConfig.firewall.allowedUDP or defaultSecurityConfig.firewall.allowedUDP;
    in 
    ''
      # Allow established/related connections
      iif lo accept
      
      # Allow ICMP (ping)
      ${if securityConfig.firewall.allowedICMP then "icmp type echo-request accept" else "icmp type echo-request drop"}
      
      # Allow TCP ports
      ${lib.concatStringsSep "\n" (map (port: "tcp dport ${lib.toString port} accept") allowedTCP)}
      
      # Allow UDP ports
      ${lib.concatStringsSep "\n" (map (port: "udp dport ${lib.toString port} accept") allowedUDP)}
      
      # Log dropped packets
      ${if securityConfig.firewall.enableLogging then "counter log drop" else "counter drop"}
    '';

  # Generate Fail2ban configuration
  generateFail2banConfig = securityConfig: 
    ''
      [DEFAULT]
      bantime = ${lib.toString securityConfig.fail2ban.bantime}
      findtime = ${lib.toString securityConfig.fail2ban.findtime}
      maxretry = ${lib.toString securityConfig.fail2ban.maxretry}
      
      [sshd]
      enabled = ${lib.toString securityConfig.fail2ban.jails.sshd}
      
      [recidive]
      enabled = ${lib.toString securityConfig.fail2ban.jails.recidive}
    '';

  # Generate AppArmor profiles
  generateAppArmorProfiles = securityConfig: 
    ''
      # FRR AppArmor profile
      profile frr flags=(attach_disconnected) {
        #include <abstractions/base>
        #include <abstractions/nameservice>
        
        /usr/sbin/frr ix,
        /etc/frr/** r,
        /var/log/frr/** w,
        /run/frr/** rw,
        
        network inet stream,
        network inet dgram,
        network inet6 stream,
        network inet6 dgram,
        
        capability net_admin,
        capability net_raw,
        capability net_bind_service,
      }
      
      # WireGuard AppArmor profile
      profile wg flags=(attach_disconnected) {
        #include <abstractions/base>
        
        /usr/bin/wg ix,
        /etc/wireguard/** r,
        /dev/net/tun rw,
        
        network inet stream,
        network inet dgram,
        network inet6 stream,
        network inet6 dgram,
        
        capability net_admin,
        capability net_raw,
      }
    '';

  # Generate Auditd rules
  generateAuditdRules = securityConfig: 
    ''
      # Monitor file access
      -w /etc/nixos-fabric -p wa -k fabric_config
      -w /etc/frr -p wa -k frr_config
      -w /etc/wireguard -p wa -k wireguard_config
      
      # Monitor user activity
      -w /var/log/auth.log -p wa -k auth_log
      -w /var/log/syslog -p wa -k sys_log
      
      # Monitor network changes
      -w /etc/network -p wa -k network_config
      -w /etc/systemd/network -p wa -k systemd_network
      
      # Monitor security events
      -w /var/log/fail2ban.log -p wa -k fail2ban
      -a exit,always -F arch=b64 -S execve -k exec
    '';

  # Secret management functions
  setupSecretsDirectory = ''
    # Create secrets directory
    mkdir -p /etc/nixos-fabric/secrets
    chmod 700 /etc/nixos-fabric/secrets
    chown root:root /etc/nixos-fabric/secrets
    
    # Create key file if it doesn't exist
    if [ ! -f /etc/nixos-fabric/secrets/key.txt ]; then
      echo "Generating new secret key..."
      ${pkgs.age}/bin/age-keygen -o /etc/nixos-fabric/secrets/key.txt
      chmod 600 /etc/nixos-fabric/secrets/key.txt
      chown root:root /etc/nixos-fabric/secrets/key.txt
    fi
    
    # Create environment file
    cat > /etc/nixos-fabric/secrets/environment <<EOF
# Secret Management Environment
SECRETS_DIR="/etc/nixos-fabric/secrets"
SECRETS_KEY="$SECRETS_DIR/key.txt"
SECRETS_BACKEND="age"
EOF
    
    # Source environment
    echo "source /etc/nixos-fabric/secrets/environment" >> /etc/profile.d/fabric-secrets.sh
  '';

  # Security validation function (removed for now due to syntax issues)
  # TODO: Re-add validation with proper syntax

in {
  options.network-fabric.security = {
    enable = mkEnableOption "Enable comprehensive security configuration";
    
    # SSH configuration
    ssh = mkOption {
      type = submodule {
        options = {
          enable = mkDefault defaultSecurityConfig.ssh.enable;
          port = mkDefault defaultSecurityConfig.ssh.port;
          passwordAuthentication = mkDefault defaultSecurityConfig.ssh.passwordAuthentication;
          permitRootLogin = mkDefault defaultSecurityConfig.ssh.permitRootLogin;
          allowUsers = mkDefault defaultSecurityConfig.ssh.allowUsers;
          allowGroups = mkDefault defaultSecurityConfig.ssh.allowGroups;
          maxAuthTries = mkDefault defaultSecurityConfig.ssh.maxAuthTries;
          loginGraceTime = mkDefault defaultSecurityConfig.ssh.loginGraceTime;
          banner = mkDefault defaultSecurityConfig.ssh.banner;
        };
      };
      default = defaultSecurityConfig.ssh;
      description = "SSH security configuration";
    };
    
    # Firewall configuration
    firewall = mkOption {
      type = submodule {
        options = {
          enable = mkDefault defaultSecurityConfig.firewall.enable;
          allowedTCP = mkDefault defaultSecurityConfig.firewall.allowedTCP;
          allowedUDP = mkDefault defaultSecurityConfig.firewall.allowedUDP;
          allowedICMP = mkDefault defaultSecurityConfig.firewall.allowedICMP;
          enableLogging = mkDefault defaultSecurityConfig.firewall.enableLogging;
          logLimit = mkDefault defaultSecurityConfig.firewall.logLimit;
        };
      };
      default = defaultSecurityConfig.firewall;
      description = "Firewall configuration";
    };
    
    # Fail2ban configuration
    fail2ban = mkOption {
      type = submodule {
        options = {
          enable = mkDefault defaultSecurityConfig.fail2ban.enable;
          bantime = mkDefault defaultSecurityConfig.fail2ban.bantime;
          findtime = mkDefault defaultSecurityConfig.fail2ban.findtime;
          maxretry = mkDefault defaultSecurityConfig.fail2ban.maxretry;
          
          jails = mkOption {
            type = submodule {
              options = {
                sshd = mkDefault defaultSecurityConfig.fail2ban.jails.sshd;
                recidive = mkDefault defaultSecurityConfig.fail2ban.jails.recidive;
              };
            };
          };
        };
      };
      default = defaultSecurityConfig.fail2ban;
      description = "Fail2ban configuration";
    };
    
    # AppArmor configuration
    apparmor = mkOption {
      type = submodule {
        options = {
          enable = mkDefault defaultSecurityConfig.apparmor.enable;
          profiles = mkDefault defaultSecurityConfig.apparmor.profiles;
          enforceMode = mkDefault defaultSecurityConfig.apparmor.enforceMode;
        };
      };
      default = defaultSecurityConfig.apparmor;
      description = "AppArmor configuration";
    };
    
    # Auditd configuration
    auditd = mkOption {
      type = submodule {
        options = {
          enable = mkDefault defaultSecurityConfig.auditd.enable;
          spaceLeft = mkDefault defaultSecurityConfig.auditd.spaceLeft;
          spaceLeftAction = mkDefault defaultSecurityConfig.auditd.spaceLeftAction;
          adminSpaceLeft = mkDefault defaultSecurityConfig.auditd.adminSpaceLeft;
          maxLogFile = mkDefault defaultSecurityConfig.auditd.maxLogFile;
          maxLogFileAction = mkDefault defaultSecurityConfig.auditd.maxLogFileAction;
        };
      };
      default = defaultSecurityConfig.auditd;
      description = "Auditd configuration";
    };
    
    # Secret management
    secrets = mkOption {
      type = submodule {
        options = {
          enable = mkDefault defaultSecurityConfig.secrets.enable;
          backend = mkDefault defaultSecurityConfig.secrets.backend;
          keyFile = mkDefault defaultSecurityConfig.secrets.keyFile;
          configDir = mkDefault defaultSecurityConfig.secrets.configDir;
        };
      };
      default = defaultSecurityConfig.secrets;
      description = "Secret management configuration";
    };
    
    # Security updates
    updates = mkOption {
      type = submodule {
        options = {
          enable = mkDefault defaultSecurityConfig.updates.enable;
          autoUpdate = mkDefault defaultSecurityConfig.updates.autoUpdate;
          checkInterval = mkDefault defaultSecurityConfig.updates.checkInterval;
          emailNotifications = mkDefault defaultSecurityConfig.updates.emailNotifications;
        };
      };
      default = defaultSecurityConfig.updates;
      description = "Security updates configuration";
    };
  };
  
  config = lib.mkIf config.network-fabric.security.enable {
    # Validate security configuration (removed for now due to syntax issues)
    # TODO: Re-add validation with proper syntax
    
    # SSH configuration
    services.openssh = lib.mkIf config.network-fabric.security.ssh.enable {
      enable = true;
      permitRootLogin = config.network-fabric.security.ssh.permitRootLogin;
      passwordAuthentication = config.network-fabric.security.ssh.passwordAuthentication;
      challengeResponseAuthentication = false;
      usePAM = true;
      
      settings = {
        Port = lib.toString config.network-fabric.security.ssh.port;
        AllowUsers = lib.concatStringsSep " " config.network-fabric.security.ssh.allowUsers;
        AllowGroups = lib.concatStringsSep " " config.network-fabric.security.ssh.allowGroups;
        MaxAuthTries = lib.toString config.network-fabric.security.ssh.maxAuthTries;
        LoginGraceTime = "${lib.toString config.network-fabric.security.ssh.loginGraceTime}s";
        Banner = config.network-fabric.security.ssh.banner;
      };
    };
    
    # Generate SSH banner
    system.activationScripts.sshBanner = lib.mkBefore ''
      echo "${sshBanner}" > /etc/issue
      echo "${sshBanner}" > /etc/issue.net
    '';
    
    # Firewall configuration
    networking.firewall = lib.mkIf config.network-fabric.security.firewall.enable {
      enable = true;
      allowedTCPPorts = config.network-fabric.security.firewall.allowedTCP;
      allowedUDPPorts = config.network-fabric.security.firewall.allowedUDP;
      
      # Custom nftables rules
      extraCommands = ''
        ${generateFirewallRules config.network-fabric.security}
      '';
    };
    
    # Fail2ban configuration
    security.fail2ban = lib.mkIf config.network-fabric.security.fail2ban.enable {
      enable = true;
      settings = {
        bantime = lib.toString config.network-fabric.security.fail2ban.bantime;
        findtime = lib.toString config.network-fabric.security.fail2ban.findtime;
        maxretry = lib.toString config.network-fabric.security.fail2ban.maxretry;
      };
      
      # Generate fail2ban configuration
      system.activationScripts.fail2banConfig = lib.mkBefore ''
        mkdir -p /etc/fail2ban
        echo "${generateFail2banConfig config.network-fabric.security}" > /etc/fail2ban/jail.local
      '';
    };
    
    # AppArmor configuration
    security.apparmor = lib.mkIf config.network-fabric.security.apparmor.enable {
      enable = true;
      
      # Generate AppArmor profiles
      system.activationScripts.apparmorProfiles = lib.mkBefore ''
        mkdir -p /etc/apparmor.d
        echo "${generateAppArmorProfiles config.network-fabric.security}" > /etc/apparmor.d/fabric-profiles
        apparmor_parser -r /etc/apparmor.d/fabric-profiles
      '';
    };
    
    # Auditd configuration
    security.auditd = lib.mkIf config.network-fabric.security.auditd.enable {
      enable = true;
      
      settings = {
        space_left = lib.toString config.network-fabric.security.auditd.spaceLeft;
        space_left_action = config.network-fabric.security.auditd.spaceLeftAction;
        admin_space_left = lib.toString config.network-fabric.security.auditd.adminSpaceLeft;
        max_log_file = lib.toString config.network-fabric.security.auditd.maxLogFile;
        max_log_file_action = config.network-fabric.security.auditd.maxLogFileAction;
      };
      
      # Generate audit rules
      system.activationScripts.auditdRules = lib.mkBefore ''
        mkdir -p /etc/audit/rules.d
        echo "${generateAuditdRules config.network-fabric.security}" > /etc/audit/rules.d/fabric.rules
        augtool set /files/etc/audit/auditd.conf/space_left ${lib.toString config.network-fabric.security.auditd.spaceLeft}
        augtool set /files/etc/audit/auditd.conf/space_left_action "${config.network-fabric.security.auditd.spaceLeftAction}"
        augtool set /files/etc/audit/auditd.conf/admin_space_left ${lib.toString config.network-fabric.security.auditd.adminSpaceLeft}
        augtool set /files/etc/audit/auditd.conf/max_log_file ${lib.toString config.network-fabric.security.auditd.maxLogFile}
        augtool set /files/etc/audit/auditd.conf/max_log_file_action "${config.network-fabric.security.auditd.maxLogFileAction}"
      '';
    };
    
    # Secret management
    system.activationScripts.secretsSetup = lib.mkIf config.network-fabric.security.secrets.enable ''
      ${setupSecretsDirectory}
    '';
    
    # Security updates
    system.activationScripts.securityUpdates = lib.mkIf config.network-fabric.security.updates.enable ''
      # Set up security update checks
      mkdir -p /etc/nixos-fabric/security
      cat > /etc/nixos-fabric/security/updates.sh <<EOF
#!/bin/bash
# Security update checker

echo "Checking for security updates..."
nix-env -u --attr nixpkgs.nixos.system "*"
echo "Security update check completed"
EOF
      
      chmod +x /etc/nixos-fabric/security/updates.sh
      
      # Create systemd service and timer
      cat > /etc/systemd/system/nixos-fabric-security-updates.service <<EOL
[Unit]
Description=NixOS Fabric Security Updates

[Service]
Type=oneshot
ExecStart=/etc/nixos-fabric/security/updates.sh
EOL
      
      cat > /etc/systemd/system/nixos-fabric-security-updates.timer <<EOL
[Unit]
Description=Run security updates check

[Timer]
OnCalendar=${config.network-fabric.security.updates.checkInterval}
Persistent=true

[Install]
WantedBy=timers.target
EOL
      
      systemctl enable nixos-fabric-security-updates.timer
      systemctl start nixos-fabric-security-updates.timer
    '';
    
    # Security environment variables
    environment.sessionVariables = {
      NIXOS_FABRIC_SECURITY_ENABLED = "true";
      NIXOS_FABRIC_SSH_PORT = lib.toString config.network-fabric.security.ssh.port;
      NIXOS_FABRIC_FIREWALL_ENABLED = lib.toString config.network-fabric.security.firewall.enable;
      NIXOS_FABRIC_FAIL2BAN_ENABLED = lib.toString config.network-fabric.security.fail2ban.enable;
    };
    
    # Security monitoring
    services.prometheus = lib.mkIf (config.services.prometheus.enable or false) {
      scrapeConfigs = (config.services.prometheus.scrapeConfigs or []) ++ [
        {
          job_name = "security-monitoring";
          static_configs = [
            {
              targets = [ "localhost:9100" ];
              labels = {
                monitor = "security";
              };
            }
          ];
        }
      ];
    };
  };
}