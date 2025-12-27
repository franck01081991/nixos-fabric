{ lib, config, pkgs, ... }:

# Improved Leaf Role Module
# This module extends the generic role with leaf-specific functionality

let
  inherit (lib) mkOption mkDefault mkEnableOption mkIf mkForce;
  inherit (lib.types) submodule str bool attrs listOf;

  # Import generic role functionality
  genericRole = import ./generic.nix { inherit lib config pkgs; };

  # Leaf-specific options
  leafOptions = {
    networking = mkOption {
      type = submodule {
        options = {
          hostName = mkDefault "leaf-node";
          domain = mkDefault "fabric.local";
          nameservers = mkDefault [ "1.1.1.1" "8.8.8.8" ];
          
          # Leaf-specific network settings
          leafNetworks = mkOption {
            type = listOf str;
            default = [ "10.254.1.0/24" "fd42:1337:254:1::/64" ];
            description = "Networks advertised by leaf";
          };
        };
      };
      default = { };
      description = "Leaf networking configuration";
    };
    
    routing = mkOption {
      type = submodule {
        options = {
          bgp = mkOption {
            type = submodule {
              options = {
                enable = mkDefault true;
                asNumber = mkDefault 65000;
                spinePeers = mkDefault [ "10.254.0.1" ];
                
                # Leaf-specific BGP settings
                evpnEnable = mkDefault true;
                vxlanEnable = mkDefault true;
                vxlanVni = mkDefault 100;
              };
            };
          };
        };
      };
      default = { };
      description = "Leaf routing configuration";
    };
    
    vxlan = mkOption {
      type = submodule {
        options = {
          enable = mkDefault true;
          vni = mkDefault 100;
          interface = mkDefault "vxlan100";
          
          # VXLAN network settings
          ipv4Network = mkDefault "10.254.100.0/24";
          ipv6Network = mkDefault "fd42:1337:254:100::/64";
        };
      };
      default = { };
      description = "Leaf VXLAN configuration";
    };
    
    wireguard = mkOption {
      type = submodule {
        options = {
          enable = mkDefault true;
          interface = mkDefault "wg0";
          
          # Leaf-specific WireGuard settings
          spinePeers = mkOption {
            type = listOf str;
            default = [ "10.254.0.1:51820" ];
            description = "WireGuard spine peers";
          };
        };
      };
      default = { };
      description = "Leaf WireGuard configuration";
    };
  };

  # Leaf role validation
  validateLeafRole = roleConfig: 
    let
      routingConfig = roleConfig.routing or { };
      bgpConfig = routingConfig.bgp or { };
      vxlanConfig = roleConfig.vxlan or { };
    in
    if roleConfig.enable 
    then lib.mkAssert (
      (bgpConfig.evpnEnable && vxlanConfig.enable) || (!bgpConfig.evpnEnable && !vxlanConfig.enable)
    ) "Leaf role: EVPN and VXLAN must be both enabled or both disabled";

  # Leaf activation script
  leafActivationScript = roleConfig: ''
    echo "Configuring leaf role specific settings..."
    
    # Create leaf-specific configuration
    mkdir -p /etc/nixos-fabric/leaf
    cat > /etc/nixos-fabric/leaf/config <<EOF
# Leaf Role Configuration
LEAF_EVPN_ENABLE=${lib.toString (roleConfig.routing.bgp.evpnEnable or true)}
LEAF_VXLAN_ENABLE=${lib.toString (roleConfig.vxlan.enable or true)}
LEAF_VXLAN_VNI=${lib.toString (roleConfig.vxlan.vni or 100)}
LEAF_NETWORKS="${lib.concatStringsSep " " (roleConfig.networking.leafNetworks or [])}"
EOF
    
    echo "Leaf role configuration completed"
  '';

  # Leaf environment variables
  leafEnvironmentVars = roleConfig: {
    NIXOS_FABRIC_LEAF_EVPN_ENABLE = lib.toString (roleConfig.routing.bgp.evpnEnable or true);
    NIXOS_FABRIC_LEAF_VXLAN_ENABLE = lib.toString (roleConfig.vxlan.enable or true);
    NIXOS_FABRIC_LEAF_VXLAN_VNI = lib.toString (roleConfig.vxlan.vni or 100);
  };

  # Leaf FRR configuration
  leafFrrConfig = roleConfig: 
    let
      routingConfig = roleConfig.routing or { };
      bgpConfig = routingConfig.bgp or { };
      vxlanConfig = roleConfig.vxlan or { };
    in 
    {
      services.frr = {
        enable = true;
        zebra = { enable = true; };
        bgpd = lib.mkIf bgpConfig.enable {
          enable = true;
          config = ''
            router bgp ${lib.toString bgpConfig.asNumber}
             bgp router-id ${config.networking.hostName}
             ${lib.concatStringsSep "\n " (lib.map (peer: 
               "neighbor ${peer} remote-as ${lib.toString bgpConfig.asNumber}"
             ) (bgpConfig.spinePeers or []))}
             ${if bgpConfig.evpnEnable then ''
               address-family l2vpn evpn
                neighbor SPINE_PEERS activate
               exit-address-family
             '' else ""}
          '';
        };
      };
    };

  # Leaf VXLAN configuration
  leafVxlanConfig = roleConfig: 
    let
      vxlanConfig = roleConfig.vxlan or { };
    in 
    {
      systemd.network = lib.mkIf vxlanConfig.enable {
        enable = true;
        networks.${vxlanConfig.interface} = {
          kind = "vxlan";
          configureWithoutCarrier = true;
          vxlan = {
            id = vxlanConfig.vni;
            local = "${config.networking.hostName}";
            group = "239.1.1.1";
            port = 4789;
            ttl = 32;
          };
          networkConfig = [
            "Address=${vxlanConfig.ipv4Network}"
            "Address=${vxlanConfig.ipv6Network}"
          ];
        };
      };
    };

  # Leaf WireGuard configuration
  leafWireguardConfig = roleConfig: 
    let
      wgConfig = roleConfig.wireguard or { };
    in 
    {
      services.wireguard = lib.mkIf wgConfig.enable {
        enable = true;
        interfaces = {
          ${wgConfig.interface} = {
            ips = [ "10.255.0.2/24" "fd42:1337:255::2/64" ];
            privateKeyFile = "/etc/wireguard/private.key";
            
            # Leaf spine peers
            peers = lib.mapAttrs (peerName: peerConfig: 
              {
                publicKey = peerConfig.publicKey;
                allowedIPs = peerConfig.allowedIPs;
                endpoint = peerConfig.endpoint;
                persistentKeepalive = peerConfig.persistentKeepalive;
              }
            ) (lib.attrsToAttrs (lib.map (peer: 
              let
                parts = lib.splitString ":" peer;
                name = lib.head parts;
                port = lib.tail parts;
              in "${name}" -> {
                publicKey = ""; # Would be filled from secrets
                allowedIPs = [ "10.255.0.${name}/32" ];
                endpoint = "${name}:${port}";
                persistentKeepalive = 25;
              }
            ) (wgConfig.spinePeers or [])));
          };
        };
      };
    };

in {
  options = {
    network-fabric = {
      roles = {
        leaf = mkOption {
          type = lib.types.nullOr (lib.types.submodule (
            genericRole.options.network-fabric.roles.leaf.options // leafOptions
          ));
          default = null;
          description = "Leaf role configuration";
        };
      };
    };
  };
  
  config = lib.mkIf (config.network-fabric.enable && config.network-fabric.roles.leaf != null) (
    let
      leafConfig = config.network-fabric.roles.leaf or { };
    in 
    lib.mkMerge [
      # Include generic role functionality
      genericRole.config
      
      # Add leaf-specific functionality if enabled
      (lib.mkIf leafConfig.enable {
        # Validate leaf configuration
        validateLeafRole leafConfig;
        
        # Set leaf-specific environment variables
        environment.sessionVariables = leafEnvironmentVars leafConfig;
        
        # Add leaf activation script
        system.activationScripts.leafRole = leafActivationScript leafConfig;
        
        # Configure leaf networking
        networking = {
          hostName = leafConfig.networking.hostName or "leaf-node";
          domain = leafConfig.networking.domain or "fabric.local";
          nameservers = leafConfig.networking.nameservers or [ "1.1.1.1" "8.8.8.8" ];
        };
        
        # Configure leaf services
        lib.mkMerge [
          leafFrrConfig leafConfig
          leafVxlanConfig leafConfig
          leafWireguardConfig leafConfig
        ];
      })
    ]
  );
}