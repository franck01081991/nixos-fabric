# Virtual Machine Test Configuration
# 
# This configuration is designed for testing the security-improved module
# in a real NixOS environment using a virtual machine.

{ config, pkgs, ... }:

{
  imports = [
    ../modules/security-improved.nix
  ];

  # Basic system configuration
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Network configuration
  networking = {
    hostName = "security-test-vm";
    networkmanager.enable = true;
  };
  
  # Enable SSH for testing
  services.openssh.enable = true;
  
  # Security module configuration
  network-fabric = {
    name = "test-fabric";
    environment = "test";
    
    security-improved = {
      enable = true;
      
      # SSH Configuration - Use custom port for testing
      ssh = {
        enable = true;
        port = 2222;
        passwordAuthentication = false;
        permitRootLogin = "no";
        allowUsers = [ "nixos" "testuser" ];
        allowGroups = [ "wheel" ];
        maxAuthTries = 3;
        loginGraceTime = 30;
        banner = "/etc/issue";
      };
      
      # Firewall Configuration
      firewall = {
        enable = true;
        allowedTCP = [ 2222 80 443 ];
        allowedUDP = [ 53 ];
        allowedICMP = true;
        enableLogging = true;
        logLimit = "10/sec";
      };
      
      # Fail2Ban Configuration
      fail2ban = {
        enable = true;
        bantime = 3600;
        findtime = 600;
        maxretry = 3;
        jails = {
          sshd = true;
          recidive = true;
        };
      };
      
      # AppArmor Configuration
      apparmor = {
        enable = true;
        profiles = [ "ssh" ];
        enforceMode = true;
      };
      
      # Auditd Configuration
      auditd = {
        enable = true;
      };
      
      # Secret Management (disabled for testing)
      secrets = {
        enable = false;
      };
      
      # Security Updates (disabled for testing)
      updates = {
        enable = false;
      };
    };
  };
  
  # Create test user for validation
  users.users.testuser = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... testuser@test"
    ];
  };
  
  # Enable basic services for testing
  services = {
    nginx.enable = true;
    fail2ban.enable = true;
    apparmor.enable = true;
    auditd.enable = true;
  };
  
  # System configuration
  system.stateVersion = "23.11";
  
  # Environment variables for testing
  environment.sessionVariables = {
    TEST_ENVIRONMENT = "true";
    SECURITY_TEST_VM = "true";
  };
}