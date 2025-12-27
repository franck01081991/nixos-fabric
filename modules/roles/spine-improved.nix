{ lib, config, pkgs, ... }:

# Improved Spine Role Module
# This module extends the generic role with spine-specific functionality

let
  inherit (lib) mkOption mkDefault mkEnableOption mkIf mkForce;
  inherit (lib.types) submodule str bool attrs listOf;

  # Import generic role functionality
  genericRole = import ./generic.nix { inherit lib config pkgs; };

  # Spine-specific options
  spineOptions = {
    networking = mkOption {
      type = submodule {
        options = {
          hostName = mkDefault "spine-node";
          domain = mkDefault "fabric.local";
          nameservers = mkDefault [ "1.1.1.1" "8.8.8.8" ];
          
          # Spine-specific network settings
          spineNetworks = mkOption {
            type = listOf str;
            default = [ "10.254.0.0/16" "fd42:1337:254::/64" ];
            description = "Networks advertised by spine";
          };
        };
      };
      default = { };
      description = "Spine networking configuration";
    };
    
    routing = mkOption {
      type = submodule {
        options = {
          ospf = mkOption {
            type = submodule {
              options = {
                enable = mkDefault true;
                area = mkDefault "0.0.0.0";
                networks = mkDefault [ "10.254.0.0/16" ];
              };
            };
          };
          
          bgp = mkOption {
            type = submodule {
              options = {
                enable = mkDefault true;
                asNumber = mkDefault 65000;
                neighbors = mkDefault [ ];
                
                # Spine-specific BGP settings
                fullMesh = mkDefault true;
                multihop = mkDefault true;
                multihopTtl = mkDefault 255;
              };
            };
          };
        };
      };
      default = { };
      description = "Spine routing configuration";
    };
    
    wireguard = mkOption {
      type = submodule {
        options = {
          enable = mkDefault true;
          interface = mkDefault "wg0";
          
          # Spine-specific WireGuard settings
          spinePeers = mkOption {
            type = listOf str;
            default = [ ];
            description = "WireGuard peers for spine full mesh";
          };
        };
      };
      default = { };
      description = "Spine WireGuard configuration";
    };
  };

  # Spine role validation
  validateSpineRole = roleConfig: 
    let
      routingConfig = roleConfig.routing or { };
      bgpConfig = routingConfig.bgp or { };
    in
    if roleConfig.enable 
    then lib.mkAssert (
      bgpConfig.fullMesh || (lib.length bgpConfig.neighbors > 0)
    ) "Spine role requires either full mesh or BGP neighbors configuration";

  # Spine activation script
  spineActivationScript = roleConfig: ''
    echo "Configuring spine role specific settings..."
    
    # Create spine-specific configuration
    mkdir -p /etc/nixos-fabric/spine
    cat > /etc/nixos-fabric/spine/config <<EOF
# Spine Role Configuration
SPINE_FULL_MESH=${lib.toString (roleConfig.routing.bgp.fullMesh or true)}
SPINE_MULTIHOP_TTL=${lib.toString (roleConfig.routing.bgp.multihopTtl or 255)}
SPINE_NETWORKS="${lib.concatStringsSep " " (roleConfig.networking.spineNetworks or [])}"
EOF
    
    echo "Spine role configuration completed"
  '';

  # Spine environment variables
  spineEnvironmentVars = roleConfig: {
    NIXOS_FABRIC_SPINE_FULL_MESH = lib.toString (roleConfig.routing.bgp.fullMesh or true);
    NIXOS_FABRIC_SPINE_MULTIHOP_TTL = lib.toString (roleConfig.routing.bgp.multihopTtl or 255);
  };

  # Spine FRR configuration
  spineFrrConfig = roleConfig: 
    let
      routingConfig = roleConfig.routing or { };
      ospfConfig = routingConfig.ospf or { };
      bgpConfig = routingConfig.bgp or { };
    in 
    {
      services.frr = {
        enable = true;
        zebra = { enable = true; };
        ospfd = lib.mkIf ospfConfig.enable {
          enable = true;
          config = ''
            router ospf
             ospf router-id ${config.networking.hostName}
             network ${lib.concatStringsSep "\n network " (ospfConfig.networks or [])}
             area ${ospfConfig.area}
          '';
        };
        bgpd = lib.mkIf bgpConfig.enable {
          enable = true;
          config = ''
            router bgp ${lib.toString bgpConfig.asNumber}
             bgp router-id ${config.networking.hostName}
             ${if bgpConfig.fullMesh then "bgp listen range 10.254.0.0/16 peer-group SPINE_PEERS" else ""}
             ${lib.concatStringsSep "\n " (lib.map (neighbor: 
               "neighbor ${neighbor} remote-as ${lib.toString bgpConfig.asNumber}"
             ) (bgpConfig.neighbors or []))}
          '';
        };
      };
    };

  # Spine WireGuard configuration
  spineWireguardConfig = roleConfig: 
    let
      wgConfig = roleConfig.wireguard or { };
    in 
    {
      services.wireguard = lib.mkIf wgConfig.enable {
        enable = true;
        interfaces = {
          ${wgConfig.interface} = {
            ips = [ "10.255.0.1/24" "fd42:1337:255::1/64" ];
            privateKeyFile = "/etc/wireguard/private.key";
            
            # Spine full mesh peers
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
        spine = mkOption {
          type = lib.types.nullOr (lib.types.submodule (
            genericRole.options.network-fabric.roles.spine.options // spineOptions
          ));
          default = null;
          description = "Spine role configuration";
        };
      };
    };
  };
  
  config = lib.mkIf (config.network-fabric.enable && config.network-fabric.roles.spine != null) (
    let
      spineConfig = config.network-fabric.roles.spine or { };
    in 
    lib.mkMerge [
      # Include generic role functionality
      genericRole.config
      
      # Add spine-specific functionality if enabled
      (lib.mkIf spineConfig.enable {
        # Validate spine configuration
        validateSpineRole spineConfig;
        
        # Set spine-specific environment variables
        environment.sessionVariables = spineEnvironmentVars spineConfig;
        
        # Add spine activation script
        system.activationScripts.spineRole = spineActivationScript spineConfig;
        
        # Configure spine networking
        networking = {
          hostName = spineConfig.networking.hostName or "spine-node";
          domain = spineConfig.networking.domain or "fabric.local";
          nameservers = spineConfig.networking.nameservers or [ "1.1.1.1" "8.8.8.8" ];
        };
        
        # Configure spine services
        lib.mkMerge [
          spineFrrConfig spineConfig
          spineWireguardConfig spineConfig
        ];
      })
    ]
  );
}