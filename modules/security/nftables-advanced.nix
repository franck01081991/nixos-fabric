{ config, lib, pkgs, ... }:

let
  # Get host-specific configuration
  hostname = config.networking.hostName;
  isSpine = hostname == "rtr-sapinet";
  isLeaf = hostname == "rtr-noisy";
  
  # Common ports
  sshPort = config.network-fabric.security.ssh.port or 22;
  wgPort = config.network-fabric.wireguard.listenPort or 51820;
  
  # Interface definitions
  wanInterface = if isSpine then "ens18" else "enp1s0";
  wgInterface = "wgtransport";
  lanInterfaces = if isLeaf then [ "br0.10" "br0.30" "br0.40" ] else [];
  
  # Rate limiting
  sshRateLimit = "10/minute";
  icmpRateLimit = "5/sec";
  
  # Logging
  enableLogging = true;
  logPrefix = "nftables-drop";
  
in {
  options.network-fabric.security.nftables-advanced = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable advanced nftables firewall";
    };
    
    sshRateLimit = lib.mkOption {
      type = lib.types.str;
      default = "10/minute";
      description = "Rate limit for SSH connections";
    };
    
    icmpRateLimit = lib.mkOption {
      type = lib.types.str;
      default = "5/sec";
      description = "Rate limit for ICMP packets";
    };
    
    enableLogging = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable logging of dropped packets";
    };
  };
  
  config = lib.mkIf (config.network-fabric.security.nftables-advanced.enable || config.network-fabric.security.firewall.enable) {
    networking.nftables = {
      enable = true;
      
      ruleset = lib.concatStringsSep "\n" [
        ''
        table inet filter {
          chain input {
            type filter hook input priority 0; policy drop;
            
            # State tracking - accept established/related connections
            ct state established,related accept comment "Accept established/related connections"
            
            # Loopback interface
            iif lo accept comment "Accept loopback traffic"
            
            # ICMP/ICMPv6 with rate limiting
            icmp type { echo-request, echo-reply, destination-unreachable, time-exceeded } limit rate ${icmpRateLimit} accept comment "Accept ICMP"
            icmpv6 type { echo-request, echo-reply, destination-unreachable, time-exceeded, packet-too-big, parameter-problem } limit rate ${icmpRateLimit} accept comment "Accept ICMPv6"
            
            # SSH with rate limiting
            tcp dport ${toString sshPort} limit rate ${sshRateLimit} accept comment "Accept SSH with rate limiting"
            
            # WireGuard - only on WAN interface
            iifname "${wanInterface}" udp dport ${toString wgPort} accept comment "Accept WireGuard on WAN"
            
            # BGP - only on WireGuard interface
            iifname "${wgInterface}" tcp dport 179 accept comment "Accept BGP on WireGuard"
            
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
            
            # Logging of dropped packets
            ${lib.mkIf enableLogging ''
              counter drop log prefix "${logPrefix}: " limit rate 5/sec
            ''}
          }
          
          chain forward {
            type filter hook forward priority 0; policy drop;
            
            # State tracking
            ct state established,related accept comment "Accept established/related connections"
            
            # Allow forwarding between VLANs (only for leaf nodes)
            ${lib.mkIf isLeaf ''
              iifname "br0.10" oifname "br0.30" accept comment "Allow VLAN10 to VLAN30"
              iifname "br0.10" oifname "br0.40" accept comment "Allow VLAN10 to VLAN40"
              iifname "br0.30" oifname "br0.10" accept comment "Allow VLAN30 to VLAN10"
              iifname "br0.30" oifname "br0.40" accept comment "Allow VLAN30 to VLAN40"
              iifname "br0.40" oifname "br0.10" accept comment "Allow VLAN40 to VLAN10"
              iifname "br0.40" oifname "br0.30" accept comment "Allow VLAN40 to VLAN30"
            ''}
            
            # Allow forwarding to/from WireGuard
            iifname "${wgInterface}" accept comment "Allow forwarding from WireGuard"
            oifname "${wgInterface}" accept comment "Allow forwarding to WireGuard"
            
            # Logging
            ${lib.mkIf enableLogging ''
              counter drop log prefix "${logPrefix}-forward: " limit rate 5/sec
            ''}
          }
          
          chain output {
            type filter hook output priority 0; policy accept;
          }
        }
        ''
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
  };
}
