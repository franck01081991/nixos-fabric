{ config, lib, pkgs, ... }:

let
  # Default WireGuard configuration that can be overridden per host
  cfg = config.network-fabric.wireguard || {};
  
  # Generate peer configurations from the peers list
  generatePeers = peers: 
    lib.mapAttrs (name: peerConfig: 
      {
        publicKey = peerConfig.publicKey or "";
        endpoint = peerConfig.endpoint or "";
        allowedIPs = peerConfig.allowedIPs or [];
        persistentKeepalive = peerConfig.persistentKeepalive or null;
        extraConfig = peerConfig.extraConfig or "";
      }
    ) peers;

in {
  options.network-fabric.wireguard = {
    enable = lib.mkDefault false;
    interfaceName = lib.mkDefault "wgtransport";
    listenPort = lib.mkDefault 51820;
    privateKeyFile = lib.mkDefault "/etc/wireguard/${config.networking.hostName}.key";
    ips = lib.mkDefault [ "10.255.0.1/24" ];
    peers = lib.mkDefault {};
    
    # Security settings
    security = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          firewallEnable = lib.mkDefault true;
          allowedPorts = lib.mkDefault [ 51820 ];
          # WireGuard specific security
          mtu = lib.mkDefault 1420;
          persistentKeepalive = lib.mkDefault 25;
          # Rate limiting
          rateLimit = lib.mkDefault "1000/m";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.wireguard.interfaces.${cfg.interfaceName} = {
      ips = cfg.ips;
      listenPort = cfg.listenPort;
      privateKeyFile = cfg.privateKeyFile;
      peers = generatePeers cfg.peers;
      mtu = cfg.security.mtu;
      
      # Apply persistent keepalive to all peers if configured
      peers = lib.mapAttrs (name: peerConfig: 
        {
          publicKey = peerConfig.publicKey or "";
          endpoint = peerConfig.endpoint or "";
          allowedIPs = peerConfig.allowedIPs or [];
          persistentKeepalive = peerConfig.persistentKeepalive or cfg.security.persistentKeepalive;
          extraConfig = peerConfig.extraConfig or "";
        }
      ) cfg.peers;
    };

    # Firewall rules for WireGuard with enhanced security
    networking.nftables.ruleset = lib.concatStringsSep "\n" [
      (if cfg.security.enable then ''
        table inet filter {
          chain input {
            # WireGuard with rate limiting
            udp dport ${toString cfg.listenPort} limit rate ${cfg.security.rateLimit} accept comment "WireGuard with rate limiting"
            udp dport ${toString cfg.listenPort} drop comment "WireGuard rate limit exceeded"
          }
        }
      '' else "")
    ];
    
    # Additional security: restrict WireGuard to specific interfaces if needed
    # This can be customized per deployment
    networking.firewall.extraCommands = lib.concatStringsSep "\n" [
      (if cfg.security.firewallEnable then ''
        # Restrict WireGuard to management interface only
        iptables -A INPUT -p udp --dport ${toString cfg.listenPort} ! -i eth0 -j DROP
      '' else "")
    ];
  };
}