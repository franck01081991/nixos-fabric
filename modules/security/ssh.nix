# Security Module: SSH Configuration
# 
# This module provides comprehensive SSH security configuration
# with sensible defaults and customization options.

{ config, lib, pkgs, ... }:

{
  options.network-fabric.security.ssh = {
    enable = lib.mkEnableOption "Enable SSH security configuration";
    
    port = lib.mkOption {
      type = lib.types.int;
      default = 22;
      description = "SSH port number";
    };
    
    passwordAuthentication = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow password authentication";
    };
    
    permitRootLogin = lib.mkOption {
      type = lib.types.str;
      default = "prohibit-password";
      description = "Root login permission";
    };
    
    allowUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "franck" "nixos" ];
      description = "Allowed SSH users";
    };
    
    allowGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "wheel" ];
      description = "Allowed SSH groups";
    };
    
    maxAuthTries = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Maximum authentication attempts";
    };
    
    loginGraceTime = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Login grace time in seconds";
    };
    
    banner = lib.mkOption {
      type = lib.types.str;
      default = "/etc/issue";
      description = "SSH banner file";
    };
  };
  
  config = lib.mkIf config.network-fabric.security.ssh.enable {
    services.openssh = {
      enable = true;
      settings = {
        Port = lib.mkForce (toString config.network-fabric.security.ssh.port);
        PermitRootLogin = lib.mkForce config.network-fabric.security.ssh.permitRootLogin;
        PasswordAuthentication = lib.mkForce (toString config.network-fabric.security.ssh.passwordAuthentication);
        ChallengeResponseAuthentication = false;
        UsePAM = true;
        AllowUsers = config.network-fabric.security.ssh.allowUsers;
        AllowGroups = config.network-fabric.security.ssh.allowGroups;
        MaxAuthTries = lib.mkForce (toString config.network-fabric.security.ssh.maxAuthTries);
        LoginGraceTime = lib.mkForce ("${toString config.network-fabric.security.ssh.loginGraceTime}s");
        Banner = config.network-fabric.security.ssh.banner;
      };
    };
    
    system.activationScripts.sshBanner = lib.mkBefore ''
      echo "=========================================="
      echo "  NIXOS FABRIC SECURITY WARNING"
      echo "  Unauthorized access is prohibited"
      echo "  All activities are monitored and logged"
      echo "==========================================" > /etc/issue
    '';
  };
}