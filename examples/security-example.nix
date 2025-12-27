# NixOS Fabric Security Module Example
# 
# This example demonstrates how to use the comprehensive security module
# with all its features enabled and properly configured.

{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/security/init.nix  # Import the comprehensive security module
  ];

  # Basic system configuration
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Network configuration
  networking = {
    hostName = "secure-fabric-node";
    useDHCP = true;
  };

  # Security module configuration
  network-fabric = {
    name = "production-fabric";
    environment = "production";
    
    security = {
      enable = true;
      
      # SSH Configuration - Use custom port for security
      ssh = {
        enable = true;
        port = 2222;
        passwordAuthentication = false;
        permitRootLogin = "no";
        allowUsers = [ "franck" "nixos" ];
        allowGroups = [ "wheel" "admin" ];
        maxAuthTries = 3;
        loginGraceTime = 30;
        banner = "/etc/issue";
      };
      
      # Firewall Configuration
      firewall = {
        enable = true;
        allowedTCP = [ 2222 80 443 51820 ];  # SSH, HTTP, HTTPS, WireGuard
        allowedUDP = [ 51820 ];               # WireGuard
        allowedICMP = true;
        enableLogging = true;
        logLimit = "10/sec";
      };
      
      # Fail2ban Configuration
      fail2ban = {
        enable = true;
        bantime = 3600;    # 1 hour ban
        findtime = 600;    # 10 minute window
        maxretry = 3;
        
        jails = {
          sshd = true;      # Protect SSH
          recidive = true;  # Protect against repeat offenders
        };
      };
      
      # AppArmor Configuration
      apparmor = {
        enable = true;
        profiles = [ "frr" "wireguard" "ssh" "nginx" ];
        enforceMode = true;
      };
      
      # Auditd Configuration
      auditd = {
        enable = true;
        spaceLeft = 50;              # 50% disk space left
        spaceLeftAction = "email";   # Send email alert
        adminSpaceLeft = 25;         # 25% admin space left
        maxLogFile = 50;             # 50MB max log file
        maxLogFileAction = "rotate"; # Rotate logs
      };
      
      # Secret Management
      secrets = {
        enable = true;
        backend = "age";
        keyFile = "/etc/nixos-fabric/secrets/key.txt";
        configDir = "/etc/nixos-fabric/secrets";
      };
      
      # Security Updates
      updates = {
        enable = true;
        autoUpdate = false;           # Manual updates for production
        checkInterval = "daily";     # Check daily
        emailNotifications = "admin@example.com";
      };
      
      # System Hardening
      hardening = {
        enable = true;
        kernel = {
          kptr_restrict = 2;           # Restrict kernel pointer exposure
          dmesg_restrict = 1;          # Restrict dmesg access
          yama_ptrace_scope = 2;       # Restrict ptrace to ancestors only
          unprivileged_bpf_disabled = 1; # Disable unprivileged BPF
          kexec_load_disabled = 1;     # Disable kexec load
          sysrq = 0;                   # Disable sysrq completely
        };
        fs = {
          protected_fifos = 2;         # Restrict FIFO access
          protected_regular = 2;       # Restrict regular file access
          suid_dumpable = 0;           # No core dumps for SUID programs
        };
        network = {
          ipv4 = {
            tcp_syncookies = 1;         # Enable SYN cookies
            rp_filter = 1;              # Enable reverse path filtering
            accept_redirects = 0;       # Disable ICMP redirects
            send_redirects = 0;         # Disable sending redirects
            accept_source_route = 0;    # Disable source routing
          };
          ipv6 = {
            accept_redirects = 0;       # Disable ICMPv6 redirects
            accept_source_route = 0;    # Disable source routing
          };
        };
      };
    };
  };

  # Additional services
  services = {
    nginx.enable = true;
    fail2ban.enable = true;
  };

  # Security services
  security = {
    apparmor.enable = true;
    auditd.enable = true;
  };

  # System configuration
  system.stateVersion = "23.11";
}