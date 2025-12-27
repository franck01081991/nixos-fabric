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
        
        # BGP configuration
        lib.mkIf cfg.bgp.enable ''
        router bgp ${toString cfg.bgp.as}
          bgp router-id ${cfg.bgp.routerId}
          ${if cfg.bgp.clusterId then "bgp cluster-id ${cfg.bgp.clusterId}" else ""}
          
          ${generateBGPNeighbors cfg.bgp.neighbors}
          
          ${lib.concatStringsSep "\n" (lib.map (af: 
            ''
            address-family ${af}
              ${lib.concatStringsSep "\n" (lib.map (network: "network ${network}") cfg.bgp.networks)}
              ${generateBGPNeighbors (lib.filterAttrs (name: neighbor: neighbor.addressFamilies && lib.elem af neighbor.addressFamilies) cfg.bgp.neighbors)}
            exit-address-family
            ''
          ) cfg.bgp.addressFamilies)}
        !
        ''
        
        # EVPN configuration
        lib.mkIf cfg.evpn.enable ''
        router bgp ${toString cfg.bgp.as} vrf default
          address-family l2vpn evpn
            neighbor ${lib.concatStringsSep " " cfg.evpn.neighbors} activate
          exit-address-family
        !
        ''
        
        # OSPF configuration
        lib.mkIf cfg.ospf.enable ''
        router ospf
          ospf router-id ${cfg.ospf.routerId}
          ${generateOSPFNetworks cfg.ospf.networks}
          ${lib.concatStringsSep "\n" (lib.map (iface: "passive-interface ${iface}") cfg.ospf.passiveInterfaces)}
        !
        ''
      ];
    };
  };
}