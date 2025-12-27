{ config, lib, pkgs, ... }:

# Network Security Integration Module
# This module provides unified network security configuration
# that integrates with FRR, WireGuard, and other network components

let
  cfg = config.network-fabric.network-security || {};
  hostname = config.networking.hostName;
  
  # Get security settings from other modules
  frrCfg = config.network-fabric.frr || {};
  wgCfg = config.network-fabric.wireguard || {};
  
  # Determine node role based on hostname
  isSpine = hostname == "rtr-sapinet";
  isLeaf = hostname == "rtr-noisy";
  
  # Common security ports
  sshPort = config.network-fabric.security.ssh.port or 22;
  wgPort = wgCfg.listenPort or 51820;
  
  # Interface definitions
  wanInterface = if isSpine then "ens18" else "enp1s0";
  wgInterface = "wgtransport";
  lanInterfaces = if isLeaf then [ "br0.10" "br0.30" "br0.40" ] else [];

in {
  options.network-fabric.network-security = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable unified network security integration";
    };
    
    # Global security policies
    policies = lib.mkOption {
      type = lib.types.submodule {
        options = {
          # Default deny policy
          defaultDeny = lib.mkDefault true;
          
          # State tracking
          stateTracking = lib.mkDefault true;
          
          # Logging
          enableLogging = lib.mkDefault true;
          logPrefix = lib.mkDefault "nixos-fabric-sec";
          
          # Rate limiting
          sshRateLimit = lib.mkDefault "10/minute";
          icmpRateLimit = lib.mkDefault "5/sec";
          
          # Network segmentation
          segmentRouting = lib.mkDefault false;
          vlanIsolation = lib.mkDefault true;
        };
      };
    };
    
    # Protocol-specific security
    protocolSecurity = lib.mkOption {
      type = lib.types.submodule {
        options = {
          bgp = lib.mkOption {
            type = lib.types.submodule {
              options = {
                # BGP security - RFC 8205 (BGPsec)
                ttlSecurity = lib.mkDefault true;
                maxPrefix = lib.mkDefault 1000;
                prefixFiltering = lib.mkDefault true;
                rpkiValidation = lib.mkDefault false;
              };
            };
          };
          
          ospf = lib.mkOption {
            type = lib.types.submodule {
              options = {
                authentication = lib.mkDefault false;
                authenticationKey = lib.mkDefault "";
                md5KeyId = lib.mkDefault 1;
              };
            };
          };
          
          wireguard = lib.mkOption {
            type = lib.types.submodule {
              options = {
                rateLimiting = lib.mkDefault "1000/m";
                interfaceRestriction = lib.mkDefault true;
                mtu = lib.mkDefault 1420;
                keepalive = lib.mkDefault 25;
              };
            };
          };
        };
      };
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Unified nftables configuration that integrates all network components
    networking.nftables = {
      enable = true;
      
      ruleset = lib.concatStringsSep "\n" [
        ''
        table inet filter {
          chain input {
            type filter hook input priority 0; 
            ${if cfg.policies.defaultDeny then "policy drop;" else "policy accept;"}
            
            # State tracking
            ${if cfg.policies.stateTracking then "ct state established,related accept comment \"Accept established/related connections\"" else ""}
            
            # Loopback interface
            iif lo accept comment "Accept loopback traffic"
            
            # ICMP/ICMPv6 with rate limiting
            icmp type { echo-request, echo-reply, destination-unreachable, time-exceeded } limit rate ${cfg.policies.icmpRateLimit} accept comment "Accept ICMP"
            icmpv6 type { echo-request, echo-reply, destination-unreachable, time-exceeded, packet-too-big, parameter-problem } limit rate ${cfg.policies.icmpRateLimit} accept comment "Accept ICMPv6"
            
            # SSH with rate limiting
            tcp dport ${toString sshPort} limit rate ${cfg.policies.sshRateLimit} accept comment "Accept SSH with rate limiting"
            
            # WireGuard security
            iifname "${wanInterface}" udp dport ${toString wgPort} limit rate ${cfg.protocolSecurity.wireguard.rateLimiting} accept comment "Accept WireGuard on WAN with rate limiting"
            
            # BGP security - only on WireGuard interface
            iifname "${wgInterface}" tcp dport 179 accept comment "Accept BGP on WireGuard"
            
            # OSPF multicast
            udp dport { 89 520 } accept comment "Allow OSPF multicast"
            
            # VXLAN - only on WireGuard interface
            iifname "${wgInterface}" udp dport 4789 accept comment "Accept VXLAN on WireGuard"
            
            # DHCP/DNS on LAN interfaces (only for leaf nodes)
            ${lib.concatStringsSep "\n" (lib.map (iface: 
              ''
              iifname "${iface}" udp dport { 67, 68, 53 } accept comment "Accept DHCP/DNS on ${iface}"
              ''
            ) lanInterfaces)}
            
            # Allow ping from LAN networks (only for leaf nodes)
            ${lib.mkIf isLeaf ''
              ip saddr 10.10.10.0/24 icmp type echo-request accept comment "Allow ping from VLAN10"
              ip saddr 10.10.30.0/24 icmp type echo-request accept comment "Allow ping from VLAN30"
              ip saddr 10.10.40.0/24 icmp type echo-request accept comment "Allow ping from VLAN40"
            ''}
            
            # Network segmentation - VLAN isolation
            ${lib.mkIf cfg.policies.vlanIsolation ''
              # Prevent VLAN hopping
              iifname "br0" oifname "br0" drop comment "Prevent VLAN hopping"
            ''}
            
            # Logging of dropped packets
            ${lib.mkIf cfg.policies.enableLogging ''
              counter drop log prefix "${cfg.policies.logPrefix}: " limit rate 5/sec
            ''}
          }
          
          chain forward {
            type filter hook forward priority 0; 
            ${if cfg.policies.defaultDeny then "policy drop;" else "policy accept;"}
            
            # State tracking
            ${if cfg.policies.stateTracking then "ct state established,related accept comment \"Accept established/related connections\"" else ""}
            
            # Network segmentation - control inter-VLAN routing
            ${lib.mkIf (isLeaf && cfg.policies.vlanIsolation) ''
              # Explicit VLAN routing rules
              iifname "br0.10" oifname "br0.30" accept comment "Allow VLAN10 to VLAN30"
              iifname "br0.10" oifname "br0.40" accept comment "Allow VLAN10 to VLAN40"
              iifname "br0.30" oifname "br0.10" accept comment "Allow VLAN30 to VLAN10"
              iifname "br0.30" oifname "br0.40" accept comment "Allow VLAN30 to VLAN40"
              iifname "br0.40" oifname "br0.10" accept comment "Allow VLAN40 to VLAN10"
              iifname "br0.40" oifname "br0.30" accept comment "Allow VLAN40 to VLAN30"
              
              # Default deny for other VLAN combinations
              iifname "br0.*" oifname "br0.*" drop comment "Deny other VLAN combinations"
            ''}
            
            # Allow forwarding to/from WireGuard
            iifname "${wgInterface}" accept comment "Allow forwarding from WireGuard"
            oifname "${wgInterface}" accept comment "Allow forwarding to WireGuard"
            
            # Logging
            ${lib.mkIf cfg.policies.enableLogging ''
              counter drop log prefix "${cfg.policies.logPrefix}-forward: " limit rate 5/sec
            ''}
          }
          
          chain output {
            type filter hook output priority 0; policy accept;
          }
        }
        ''
        
        # NAT for leaf nodes
        lib.mkIf isLeaf ''
          table ip nat {
            chain postrouting {
              type nat hook postrouting priority 100; policy accept;
              
              # MASQUERADE for VLANs going to WAN
              oifname "${wanInterface}" ip saddr { 10.10.10.0/24, 10.10.30.0/24, 10.10.40.0/24 } masquerade comment "MASQUERADE VLAN traffic to WAN"
            }
          }
        ''
      ];
    };
    
    # Integrate with existing security modules
    services.fail2ban = lib.mkIf (config.network-fabric.security.fail2banEnable) {
      enable = true;
      settings = {
        ignoreip = [ "127.0.0.1/8" "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" ];
        bantime = 3600;
        findtime = 600;
        maxretry = 3;
      };
      
      jails = lib.mkMerge [
        {
          sshd = {
            enable = true;
            port = sshPort;
          };
        }
        (lib.mkIf wgCfg.enable {
          wireguard = {
            enable = true;
            port = wgPort;
            filter = "wg";
            logpath = "/var/log/syslog";
          };
        })
      ];
    };
    
    # SSH hardening
    services.openssh = lib.mkIf (config.network-fabric.security.ssh.enable) {
      enable = true;
      settings = {
        Port = sshPort;
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
        AllowUsers = config.network-fabric.security.ssh.allowUsers;
        AllowGroups = config.network-fabric.security.ssh.allowGroups;
        MaxAuthTries = config.network-fabric.security.ssh.maxAuthTries;
        LoginGraceTime = "${toString config.network-fabric.security.ssh.loginGraceTime}s";
        Banner = config.network-fabric.security.ssh.banner;
        
        # Additional security settings
        Protocol = 2;
        PermitEmptyPasswords = false;
        X11Forwarding = false;
        AllowTcpForwarding = false;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
        
        # Restrict to specific interfaces
        ListenAddress = [
          "0.0.0.0"
          "::"
        ];
      };
    };
  };
}