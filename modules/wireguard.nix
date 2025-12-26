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
    firewall = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          allowedPorts = lib.mkDefault [ 51820 ];
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
    };

    # Firewall rules for WireGuard
    networking.nftables.ruleset = lib.concatStringsSep "\n" [
      (if cfg.firewall.enable then ''
        table inet filter {
          chain input {
            udp dport ${toString cfg.listenPort} accept
          }
        }
      '' else "")
    ];
  };
}