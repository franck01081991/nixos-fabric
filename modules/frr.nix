{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.frr || {};
  
  # Generate BGP neighbor configurations
  generateBGPNeighbors = neighbors: 
    lib.concatStringsSep "\n" (
      lib.mapAttrs (name: neighborConfig: 
        ''
        neighbor ${neighborConfig.ip} remote-as ${toString neighborConfig.as}
        neighbor ${neighborConfig.ip} update-source ${neighborConfig.updateSource or "lo"}
        ${if neighborConfig.ebgpMultihop then "neighbor ${neighborConfig.ip} ebgp-multihop ${toString neighborConfig.ebgpMultihop}" else ""}
        ${if neighborConfig.description then "neighbor ${neighborConfig.ip} description ${neighborConfig.description}" else ""}
        ''
      ) neighbors
    );

  # Generate OSPF network statements
  generateOSPFNetworks = networks: 
    lib.concatStringsSep "\n" (
      lib.map (network: "network ${network} area ${toString (cfg.ospf.area or 0)}") networks
    );

in {
  options.network-fabric.frr = {
    enable = lib.mkDefault false;
    
    # Security settings for FRR
    security = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          # BGP security - RFC 8205 (BGPsec) and RFC 7454 (BGP Operations and Security)
          bgpMaxPrefix = lib.mkDefault 1000;
          bgpTtlSecurity = lib.mkDefault true;
          bgpPrefixList = lib.mkDefault [];
          # OSPF security
          ospfAuthentication = lib.mkDefault false;
          ospfAuthenticationKey = lib.mkDefault "";
        };
      };
    };
    
    bgp = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault false;
          as = lib.mkDefault 65000;
          routerId = lib.mkDefault "10.254.0.1";
          neighbors = lib.mkDefault {};
          networks = lib.mkDefault [];
          addressFamilies = lib.mkDefault [ "ipv4 unicast" ];
        };
      };
    };

    ospf = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault false;
          routerId = lib.mkDefault "10.254.0.1";
          area = lib.mkDefault 0;
          networks = lib.mkDefault [];
          passiveInterfaces = lib.mkDefault [ "default" ];
        };
      };
    };

    evpn = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault false;
          neighbors = lib.mkDefault [];
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.frr = {
      enable = true;
      bgpd.enable = cfg.bgp.enable;
      ospfd.enable = cfg.ospf.enable;
      
      config = lib.concatStringsSep "\n" [
        ''
        frr defaults traditional
        hostname ${config.networking.hostName}
        service integrated-vtysh-config
        log syslog informational
        ''
        
        # Security configuration
        lib.mkIf cfg.security.enable ''
        # BGP Security - RFC 8205 (BGPsec) and RFC 7454 (BGP Operations and Security)
        ${lib.mkIf cfg.security.bgpTtlSecurity ''
        !
        ! BGP TTL Security - RFC 5082
        !
        access-list BGP_TTL_SECURITY permit any
        !
        ''}
        
        ${lib.mkIf (cfg.security.bgpMaxPrefix != null && cfg.security.bgpMaxPrefix > 0) ''
        !
        ! BGP Prefix Limit - RFC 7606
        !
        ${lib.concatStringsSep "\n" (lib.map (neighborName: 
          ''
          neighbor ${(builtins.attrValues cfg.bgp.neighbors)[0].ip} maximum-prefix ${toString cfg.security.bgpMaxPrefix} warning-threshold 80 restart 60
          ''
        ) (builtins.attrNames cfg.bgp.neighbors))}
        !
        ''}
        
        # OSPF Security
        ${lib.mkIf cfg.security.ospfAuthentication ''
        !
        ! OSPF Authentication
        !
        interface ${lib.concatStringsSep " " (lib.map (network: lib.stringReplace "\/.*" "" network) cfg.ospf.networks)}
          ip ospf authentication message-digest
          ip ospf message-digest-key 1 md5 ${cfg.security.ospfAuthenticationKey}
        !
        ''}
        
        # BGP configuration
        lib.mkIf cfg.bgp.enable ''
        router bgp "${toString cfg.bgp.as}"
          bgp router-id "${cfg.bgp.routerId}"
          ${if cfg.bgp.clusterId then "bgp cluster-id \"${cfg.bgp.clusterId}\"" else ""}
          
          ${generateBGPNeighbors cfg.bgp.neighbors}
          
          ${lib.concatStringsSep "\n" (lib.map (af: 
            ''
            address-family "${af}"
              ${lib.concatStringsSep "\n" (lib.map (network: "network \"${network}\"") cfg.bgp.networks)}
              ${generateBGPNeighbors (lib.filterAttrs (name: neighbor: neighbor.addressFamilies && lib.elem af neighbor.addressFamilies) cfg.bgp.neighbors)}
            exit-address-family
            ''
          ) cfg.bgp.addressFamilies)}
        !
        ''
        
        # EVPN configuration
        lib.mkIf cfg.evpn.enable ''
        router bgp "${toString cfg.bgp.as}" vrf default
          address-family l2vpn evpn
            neighbor ${lib.concatStringsSep " " cfg.evpn.neighbors} activate
          exit-address-family
        !
        ''
         
        # OSPF configuration
        lib.mkIf cfg.ospf.enable ''
        router ospf
          ospf router-id "${cfg.ospf.routerId}"
          ${generateOSPFNetworks cfg.ospf.networks}
          ${lib.concatStringsSep "\n" (lib.map (iface: "passive-interface ${iface}") cfg.ospf.passiveInterfaces)}
        !
        ''
      ];
    };
    
    # Firewall rules for FRR (BGP port 179)
    networking.nftables.ruleset = lib.concatStringsSep "\n" [
      (if cfg.security.enable then ''
        table inet filter {
          chain input {
            # Allow BGP on WireGuard interface
            iifname "wgtransport" tcp dport 179 accept comment "Allow BGP on WireGuard"
            # Allow OSPF multicast
            udp dport { 89 520 } accept comment "Allow OSPF multicast"
          }
        }
      '' else "")
    ];
  };
}