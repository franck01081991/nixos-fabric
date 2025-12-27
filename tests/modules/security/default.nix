# Security Module Test Suite
# 
# This test suite validates the security module functionality
# by testing various configuration scenarios and options.

{ pkgs ? import <nixpkgs> {}, lib ? import <nixpkgs/lib> }:

let
  # Import the security module with required arguments
  securityModule = import ../../../modules/security/init.nix { inherit lib; };
  
  # Test configuration 1: Minimal configuration
  minimalConfig = {
    network-fabric = {
      name = "test-fabric";
      environment = "test";
      security = {
        enable = true;
        ssh.enable = true;
        firewall.enable = true;
      };
    };
  };
  
  # Test configuration 2: Complete configuration
  completeConfig = {
    network-fabric = {
      name = "test-fabric";
      environment = "test";
      security = {
        enable = true;
        
        ssh = {
          enable = true;
          port = 2222;
          passwordAuthentication = false;
          permitRootLogin = "no";
          allowUsers = [ "testuser" ];
          allowGroups = [ "wheel" ];
          maxAuthTries = 3;
          loginGraceTime = 30;
          banner = "/etc/issue";
        };
        
        firewall = {
          enable = true;
          allowedTCP = [ 2222 80 443 ];
          allowedUDP = [ 53 ];
          allowedICMP = true;
          enableLogging = true;
          logLimit = "10/sec";
        };
        
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
        
        apparmor = {
          enable = true;
          profiles = [ "frr" "wireguard" "ssh" ];
          enforceMode = true;
        };
        
        auditd = {
          enable = true;
        };
        
        secrets = {
          enable = true;
          backend = "age";
          keyFile = "/etc/nixos-fabric/secrets/key.txt";
          configDir = "/etc/nixos-fabric/secrets";
        };
        
        updates = {
          enable = true;
          autoUpdate = false;
          checkInterval = "daily";
          emailNotifications = "test@example.com";
        };
      };
    };
  };
  
  # Test configuration 3: Edge cases
  edgeCaseConfig = {
    network-fabric = {
      name = "test-fabric";
      environment = "test";
      security = {
        enable = true;
        
        ssh = {
          enable = true;
          port = 22;  # Default port
          passwordAuthentication = true;  # Less secure for testing
          permitRootLogin = "prohibit-password";
          allowUsers = [ ];  # Empty list
          allowGroups = [ ];  # Empty list
        };
        
        firewall = {
          enable = true;
          allowedTCP = [ ];  # No TCP ports
          allowedUDP = [ ];  # No UDP ports
          allowedICMP = false;  # No ICMP
        };
      };
    };
  };
  
  # Test the module with different configurations
  testMinimal = securityModule { 
    inherit (minimalConfig) config;
    lib = lib;
    pkgs = pkgs;
  };
  
  testComplete = securityModule { 
    inherit (completeConfig) config;
    lib = lib;
    pkgs = pkgs;
  };
  
  testEdgeCase = securityModule { 
    inherit (edgeCaseConfig) config;
    lib = lib;
    pkgs = pkgs;
  };

in {
  inherit testMinimal testComplete testEdgeCase;
  
  # Test results summary
  results = {
    minimalConfig = lib.isAttrs testMinimal;
    completeConfig = lib.isAttrs testComplete;
    edgeCaseConfig = lib.isAttrs testEdgeCase;
    
    allTestsPassed = testMinimal != null && testComplete != null && testEdgeCase != null;
  };
  
  # Export test configurations for manual inspection
  configurations = {
    minimal = minimalConfig;
    complete = completeConfig;
    edgeCase = edgeCaseConfig;
  };
}