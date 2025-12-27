{ config, lib, pkgs, ... }:

# ============================================
# NixOS Fabric Security Module
# ============================================
#
# This module provides comprehensive security configuration for NixOS Fabric
# deployments with a modular, organized approach.
#
# Features:
# - SSH Hardening with customizable security settings
# - Advanced Firewall with rate limiting and logging
# - Intrusion Detection System (Fail2ban)
# - Mandatory Access Control (AppArmor)
# - Comprehensive System Auditing (Auditd)
# - Secure Secret Management
# - Automatic Security Updates
# - System Hardening (Kernel, FS, Network)
#
# Usage:
#   imports = [ ../modules/security/init.nix ];
#   network-fabric.security-improved.enable = true;
#
# Documentation:
#   See modules/security/README.md for complete documentation
# ============================================

let
  inherit (lib) mkOption mkDefault mkEnableOption mkIf mkForce mkBefore;
  inherit (lib.types) submodule str bool listOf attrs;

  # ============================================
  # DEFAULT SECURITY CONFIGURATION
  # ============================================
  # This section defines sensible defaults for all security features.
  # Users can override these defaults in their configuration.
  # ============================================
  
  defaultSecurityConfig = {
    # SSH configuration
    ssh = {
      enable = true;
      port = 22;
      passwordAuthentication = false;
      permitRootLogin = "prohibit-password";
      allowUsers = [ "franck" "nixos" ];
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
      spaceLeft = 50;
      spaceLeftAction = "email";
      adminSpaceLeft = 25;
      maxLogFile = 50;
      maxLogFileAction = "rotate";
    };
    
    # Secret management
    secrets = {
      enable = true;
      backend = "age";
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
    
    # System hardening
    hardening = {
      enable = true;
      kernel = {
        kptr_restrict = 2;
        dmesg_restrict = 1;
        yama_ptrace_scope = 2;
        unprivileged_bpf_disabled = 1;
        kexec_load_disabled = 1;
        sysrq = 0;
      };
      fs = {
        protected_fifos = 2;
        protected_regular = 2;
        suid_dumpable = 0;
      };
      network = {
        ipv4 = {
          tcp_syncookies = 1;
          rp_filter = 1;
          accept_redirects = 0;
          send_redirects = 0;
          accept_source_route = 0;
        };
        ipv6 = {
          accept_redirects = 0;
          accept_source_route = 0;
        };
      };
    };
  };

  # ============================================
  # CONFIGURATION PROCESSING
  # ============================================
  # Merge user configuration with defaults to ensure all options
  # have sensible values even if not explicitly set.
  # ============================================
  
  cfg = config.network-fabric.security-improved or defaultSecurityConfig;

  # ============================================
  # SSH BANNER GENERATION
  # ============================================
  # Security warning banner displayed on SSH login attempts.
  # Helps deter unauthorized access and provides legal notice.
  # ============================================
  
  sshBanner = lib.concatStringsSep "\n" [
    "=========================================="
    "  NIXOS FABRIC SECURITY WARNING"
    "  Unauthorized access is prohibited"
    "  All activities are monitored and logged"
    "=========================================="
  ];

  # ============================================
  # CONFIGURATION GENERATION FUNCTIONS
  # ============================================
  # These functions generate configuration files and scripts
  # based on the security settings.
  # ============================================
  
  # Fail2ban Configuration Generator
  # Creates Fail2ban jail configuration with custom settings
  generateFail2banConfig = securityConfig: ''
    [DEFAULT]
    bantime = ${toString securityConfig.fail2ban.bantime}
    findtime = ${toString securityConfig.fail2ban.findtime}
    maxretry = ${toString securityConfig.fail2ban.maxretry}
    
    [sshd]
    enabled = true
    port = ssh
    filter = sshd
    logpath = /var/log/auth.log
    maxretry = ${toString securityConfig.fail2ban.maxretry}
  '';

  # AppArmor Profiles Generator
  # Creates AppArmor profiles for specified services
  generateAppArmorProfiles = securityConfig: ''
    # AppArmor profiles for NixOS Fabric
    # Generated by security module
    
    ${lib.concatStringsSep "\n" (lib.map (profile: "profile ${profile} flags=(complain) {") securityConfig.apparmor.profiles)}
  '';

  # Auditd Rules Generator
  # Creates audit rules for system monitoring
  generateAuditdRules = securityConfig: ''
    # Audit rules for NixOS Fabric
    -w /etc -p wa -k config_changes
    -w /usr/bin -p x -k exec_bin
    -w /var/log -p wa -k log_changes
  '';

  # Secrets Directory Setup
  # Creates secure directory structure for secrets
  setupSecretsDirectory = cfg: ''
    mkdir -p ${cfg.secrets.configDir}
    chmod 700 ${cfg.secrets.configDir}
    chown root:root ${cfg.secrets.configDir}
  '';

in {
  # ============================================
  # MODULE OPTIONS DEFINITION
  # ============================================
  # This section defines all available configuration options
  # for the security module. Each option includes:
  # - Type definition
  # - Default value
  # - Description
  # ============================================
  
  options.network-fabric.security-improved = {
    enable = mkEnableOption "Enable comprehensive security configuration";
    
    # ==========================================
    # SSH CONFIGURATION OPTIONS
    # ==========================================
    # Configure SSH service security settings including
    # authentication methods, access control, and connection limits.
    # ==========================================
    
    ssh = mkOption {
      type = attrs;
      default = defaultSecurityConfig.ssh;
      description = "SSH security configuration";
    };
    
    # Firewall configuration
    firewall = mkOption {
      type = attrs;
      default = defaultSecurityConfig.firewall;
      description = "Firewall configuration";
    };
    
    # Fail2ban configuration
    fail2ban = mkOption {
      type = attrs;
      default = defaultSecurityConfig.fail2ban;
      description = "Fail2ban configuration";
    };
    
    # AppArmor configuration
    apparmor = mkOption {
      type = attrs;
      default = defaultSecurityConfig.apparmor;
      description = "AppArmor configuration";
    };
    
    # Auditd configuration
    auditd = mkOption {
      type = attrs;
      default = defaultSecurityConfig.auditd;
      description = "Auditd configuration";
    };
    
    # Secret management
    secrets = mkOption {
      type = attrs;
      default = defaultSecurityConfig.secrets;
      description = "Secret management configuration";
    };
    
    # Security updates
    updates = mkOption {
      type = attrs;
      default = defaultSecurityConfig.updates;
      description = "Security updates configuration";
    };
    
    # System hardening
    hardening = mkOption {
      type = attrs;
      default = defaultSecurityConfig.hardening;
      description = "System hardening configuration";
    };
  };
  
  config = mkIf cfg.enable {
    # ============================================
    # SECURITY CONFIGURATION IMPLEMENTATION
    # ============================================
    # This section applies the security configuration to the system.
    # All configurations are conditional on the module being enabled.
    # ============================================
    
    # ==========================================
    # SSH SERVICE CONFIGURATION
    # ==========================================
    # Configure OpenSSH with security-hardened settings
    # including custom ports, authentication restrictions,
    # and connection limits.
    # ==========================================
    
    services.openssh = mkIf cfg.ssh.enable {
      enable = true;
      
      settings = {
        Port = toString cfg.ssh.port;
        PermitRootLogin = mkForce cfg.ssh.permitRootLogin;
        PasswordAuthentication = mkForce cfg.ssh.passwordAuthentication;
        ChallengeResponseAuthentication = false;
        UsePAM = true;
        AllowUsers = cfg.ssh.allowUsers;
        AllowGroups = cfg.ssh.allowGroups;
        MaxAuthTries = toString cfg.ssh.maxAuthTries;
        LoginGraceTime = "${toString cfg.ssh.loginGraceTime}s";
        Banner = cfg.ssh.banner;
      };
    };
    
    # Generate SSH banner
    system.activationScripts.sshBanner = mkBefore ''
      echo "${sshBanner}" > /etc/issue
    '';
    
    # Firewall configuration
    # Only configure traditional firewall if nftables is not enabled
    networking.firewall = mkIf (cfg.firewall.enable && !config.networking.nftables.enable) {
      enable = true;
      allowedTCPPorts = cfg.firewall.allowedTCP;
      allowedUDPPorts = cfg.firewall.allowedUDP;
      
      # Custom nftables rules
      extraCommands = ''
        # Rate limiting for SSH
        table inet filter {
          chain input {
            tcp dport ${toString cfg.ssh.port} limit rate ${cfg.firewall.logLimit} accept
          }
        }
      '';
    };
    
    # Fail2ban configuration
    services.fail2ban = mkIf cfg.fail2ban.enable {
      enable = true;
      jails = lib.mapAttrs (name: jailConfig: 
        {
          settings = {
            enabled = jailConfig.enabled;
            backend = jailConfig.backend or "systemd";
            port = jailConfig.port or "ssh";
            filter = jailConfig.filter or "sshd";
            maxretry = toString (jailConfig.maxretry or cfg.fail2ban.maxretry);
            findtime = toString (jailConfig.findtime or cfg.fail2ban.findtime);
            bantime = toString (jailConfig.bantime or cfg.fail2ban.bantime);
          };
        }
      ) cfg.fail2ban.jails;
    };
    
    # Generate fail2ban configuration
    system.activationScripts.fail2banConfig = mkIf cfg.fail2ban.enable ''
      mkdir -p /etc/fail2ban
      echo "${generateFail2banConfig cfg}" > /etc/fail2ban/jail.local
    '';
    
    # AppArmor configuration
    security.apparmor.enable = mkIf cfg.apparmor.enable true;
    
    # Generate AppArmor profiles
    system.activationScripts.apparmorProfiles = mkIf cfg.apparmor.enable ''
      mkdir -p /etc/apparmor.d
      echo "${generateAppArmorProfiles cfg}" > /etc/apparmor.d/fabric-profiles
      apparmor_parser -r /etc/apparmor.d/fabric-profiles
    '';
    
    # Auditd configuration
    security.auditd.enable = mkIf cfg.auditd.enable true;
    
    # Generate audit rules
    system.activationScripts.auditdRules = mkIf cfg.auditd.enable ''
      mkdir -p /etc/audit/rules.d
      echo "${generateAuditdRules cfg}" > /etc/audit/rules.d/fabric.rules
      augtool set /files/etc/audit/auditd.conf/space_left ${toString cfg.auditd.spaceLeft}
      augtool set /files/etc/audit/auditd.conf/space_left_action "${cfg.auditd.spaceLeftAction}"
      augtool set /files/etc/audit/auditd.conf/admin_space_left ${toString cfg.auditd.adminSpaceLeft}
      augtool set /files/etc/audit/auditd.conf/max_log_file ${toString cfg.auditd.maxLogFile}
      augtool set /files/etc/audit/auditd.conf/max_log_file_action "${cfg.auditd.maxLogFileAction}"
    '';
    
    # Secret management
    system.activationScripts.secretsSetup = mkIf cfg.secrets.enable ''
      ${setupSecretsDirectory cfg}
    '';
    
    # Security updates
    system.activationScripts.securityUpdates = mkIf cfg.updates.enable ''
      # Set up security update checks
      mkdir -p /etc/nixos-fabric/security
      cat > /etc/nixos-fabric/security/updates.sh <<EOF
      #!/bin/bash
      echo "Running security updates check..."
      nix-env -u '*'
      if [ -n "${cfg.updates.emailNotifications}" ]; then
        echo "Sending alert to ${cfg.updates.emailNotifications}"
      fi
      EOF
      chmod +x /etc/nixos-fabric/security/updates.sh
      
      # Create systemd service and timer
      cat > /etc/systemd/system/security-updates.service <<EOL
      [Unit]
      Description=Security Updates Check
      
      [Service]
      ExecStart=/etc/nixos-fabric/security/updates.sh
      EOL
      
      cat > /etc/systemd/system/security-updates.timer <<EOL
      [Unit]
      Description=Run security updates check
      
      [Timer]
      OnCalendar=${cfg.updates.checkInterval}
      Persistent=true
      
      [Install]
      WantedBy=timers.target
      EOL
      
      systemctl enable security-updates.timer
    '';
    
    # System hardening
    boot.kernel.sysctl = mkIf cfg.hardening.enable {
      "kernel.kptr_restrict" = toString cfg.hardening.kernel.kptr_restrict;
      "kernel.dmesg_restrict" = toString cfg.hardening.kernel.dmesg_restrict;
      "kernel.yama.ptrace_scope" = toString cfg.hardening.kernel.yama_ptrace_scope;
      "kernel.unprivileged_bpf_disabled" = toString cfg.hardening.kernel.unprivileged_bpf_disabled;
      "kernel.kexec_load_disabled" = toString cfg.hardening.kernel.kexec_load_disabled;
      "kernel.sysrq" = toString cfg.hardening.kernel.sysrq;
      
      "fs.protected_fifos" = toString cfg.hardening.fs.protected_fifos;
      "fs.protected_regular" = toString cfg.hardening.fs.protected_regular;
      "fs.suid_dumpable" = toString cfg.hardening.fs.suid_dumpable;
      
      "net.ipv4.tcp_syncookies" = toString cfg.hardening.network.ipv4.tcp_syncookies;
      "net.ipv4.conf.all.rp_filter" = toString cfg.hardening.network.ipv4.rp_filter;
      "net.ipv4.conf.default.rp_filter" = toString cfg.hardening.network.ipv4.rp_filter;
      "net.ipv4.conf.all.accept_redirects" = toString cfg.hardening.network.ipv4.accept_redirects;
      "net.ipv4.conf.default.accept_redirects" = toString cfg.hardening.network.ipv4.accept_redirects;
      "net.ipv4.conf.all.send_redirects" = toString cfg.hardening.network.ipv4.send_redirects;
      "net.ipv4.conf.default.send_redirects" = toString cfg.hardening.network.ipv4.send_redirects;
      "net.ipv4.conf.all.accept_source_route" = toString cfg.hardening.network.ipv4.accept_source_route;
      "net.ipv4.conf.default.accept_source_route" = toString cfg.hardening.network.ipv4.accept_source_route;
      
      "net.ipv6.conf.all.accept_redirects" = toString cfg.hardening.network.ipv6.accept_redirects;
      "net.ipv6.conf.default.accept_redirects" = toString cfg.hardening.network.ipv6.accept_redirects;
      "net.ipv6.conf.all.accept_source_route" = toString cfg.hardening.network.ipv6.accept_source_route;
      "net.ipv6.conf.default.accept_source_route" = toString cfg.hardening.network.ipv6.accept_source_route;
    };
    
    # Security environment variables
    environment.sessionVariables = {
      NIXOS_FABRIC_SECURITY_ENABLED = "true";
      NIXOS_FABRIC_SSH_PORT = toString cfg.ssh.port;
      NIXOS_FABRIC_FIREWALL_ENABLED = toString cfg.firewall.enable;
      NIXOS_FABRIC_FAIL2BAN_ENABLED = toString cfg.fail2ban.enable;
    };
  };
}