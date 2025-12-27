# Security Module: Firewall Configuration
# 
# This module provides comprehensive firewall configuration
# with support for TCP/UDP ports, ICMP, and logging.

{ config, lib, pkgs, ... }:

{
  options.network-fabric.security.firewall = {
    enable = lib.mkEnableOption "Enable firewall configuration";
    
    allowedTCP = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [ 22 80 443 51820 ];
      description = "Allowed TCP ports";
    };
    
    allowedUDP = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [ 51820 ];
      description = "Allowed UDP ports";
    };
    
    allowedICMP = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow ICMP traffic";
    };
    
    enableLogging = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable firewall logging";
    };
    
    logLimit = lib.mkOption {
      type = lib.types.str;
      default = "10/sec";
      description = "Log rate limit";
    };
  };
  
  config = lib.mkIf config.network-fabric.security.firewall.enable {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = config.network-fabric.security.firewall.allowedTCP;
      allowedUDPPorts = config.network-fabric.security.firewall.allowedUDP;
      
      # Custom nftables rules for rate limiting
      extraCommands = lib.mkIf config.network-fabric.security.firewall.enableLogging ''
        table inet filter {
          chain input {
            tcp dport ${toString config.network-fabric.security.ssh.port} limit rate ${config.network-fabric.security.firewall.logLimit} accept
          }
        }
      '';
    };
    
    # ICMP configuration
    boot.kernel.sysctl."net.ipv4.icmp_echo_ignore_all" = lib.mkIf (!config.network-fabric.security.firewall.allowedICMP) 1 0;
  };
}