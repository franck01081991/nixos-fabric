# Security Improved Module - Example Configuration
# 
# This file demonstrates how to use the security-improved module with all its features.
# Copy this configuration to your host configuration and adapt as needed.

{ config, pkgs, ... }:

{
  imports = [
    ./modules/security-improved.nix  # Import the improved security module
  ];

  # Network fabric configuration
  network-fabric = {
    name = "production-fabric";
    environment = "production";
  };

  # Security Improved Module Configuration
  network-fabric.security-improved = {
    enable = true;  # Enable the comprehensive security configuration

    # SSH Configuration - Hardened SSH settings
    ssh = {
      enable = true;
      port = 2222;  # Custom SSH port for security
      passwordAuthentication = false;  # Disable password authentication
      permitRootLogin = "no";  # Disable root login
      allowUsers = [ "admin" "backup" "monitoring" ];  # Specific allowed users
      allowGroups = [ "wheel" "sshusers" ];  # Specific allowed groups
      maxAuthTries = 3;  # Limit authentication attempts
      loginGraceTime = 30;  # 30 seconds grace time
      banner = "/etc/issue";  # Custom SSH banner
    };

    # Firewall Configuration - Advanced network filtering
    firewall = {
      enable = true;
      allowedTCP = [ 2222 80 443 51820 ];  # SSH, HTTP, HTTPS, WireGuard
      allowedUDP = [ 51820 53 ];  # WireGuard, DNS
      allowedICMP = true;  # Allow ping for diagnostics
      enableLogging = true;  # Log dropped packets
      logLimit = "10/sec";  # Rate limit logging
    };

    # Fail2Ban Configuration - Brute force protection
    fail2ban = {
      enable = true;
      bantime = 3600;  # 1 hour ban
      findtime = 600;  # 10 minute window
      maxretry = 3;  # 3 attempts before ban
      
      # Configure which jails to enable
      jails = {
        sshd = true;  # Protect SSH
        recidive = true;  # Protect against repeat offenders
        # Additional jails can be added here
        # nginx-badbots = true;
        # nginx-noscript = true;
      };
    };

    # AppArmor Configuration - Mandatory Access Control
    apparmor = {
      enable = true;
      profiles = [ "frr" "wireguard" "ssh" "nftables" ];  # Profiles to load
      enforceMode = true;  # Enforce mode (not complain)
    };

    # Auditd Configuration - Comprehensive system auditing
    auditd = {
      enable = true;
      # Note: Advanced settings are configured via activation scripts
      # Basic settings are handled by NixOS standard options
    };

    # Secret Management - Secure secrets handling
    secrets = {
      enable = true;
      backend = "age";  # Can be "age", "sops", or "vault"
      keyFile = "/etc/nixos-fabric/secrets/key.txt";
      configDir = "/etc/nixos-fabric/secrets";
    };

    # Security Updates - Automatic update checking
    updates = {
      enable = true;
      autoUpdate = false;  # Manual updates for production
      checkInterval = "daily";  # Check daily
      emailNotifications = "admin@example.com";  # Notification email
    };
  };

  # Enable Prometheus for security monitoring (optional)
  services.prometheus = {
    enable = true;
    scrapeConfigs = [
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

  # Security environment variables
  environment.sessionVariables = {
    NIXOS_FABRIC_SECURITY_ENABLED = "true";
    NIXOS_FABRIC_SSH_PORT = "2222";
  };
}

# Usage Notes:
#
# 1. This configuration provides comprehensive security hardening
# 2. All security features are configurable through network-fabric.security-improved
# 3. The module uses standard NixOS options where possible
# 4. Custom activation scripts handle complex configurations
# 5. Remember to update your SSH configuration if changing the port
# 6. Test in a non-production environment first
# 7. Review all settings for your specific security requirements

# Migration from old security configuration:
#
# Old: network-fabric.security.{...}
# New: network-fabric.security-improved.{...}
#
# Example migration:
# network-fabric.security.enable = true;
# becomes:
# network-fabric.security-improved.enable = true;
