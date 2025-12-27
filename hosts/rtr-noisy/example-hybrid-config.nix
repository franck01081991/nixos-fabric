# Example Hybrid Configuration for rtr-noisy
# This demonstrates how to configure both spine and leaf roles simultaneously

{ config, lib, pkgs, ... }:

{
  # Enable the fabric and set basic configuration
  network-fabric = {
    enable = true;
    name = "production-fabric";
    environment = "production";
    
    # Network configuration
    network = {
      domain = "fabric.prod";
      dnsServers = [ "1.1.1.1" "8.8.8.8" ];
      
      ipv4 = {
        prefix = "10.254.0.0/16";
        gateway = "10.254.0.1";
      };
      
      ipv6 = {
        prefix = "fd42:1337:254::/64";
        gateway = "fd42:1337:254::1";
      };
    };
    
    # Security configuration
    security = {
      sshPort = 22;
      fail2banEnable = true;
      firewallEnable = true;
    };
    
    # Role configuration - both spine and leaf enabled for hybrid node
    roles = {
      spine = {
        enable = true;
        roleId = "spine2";
        description = "Hybrid node spine component";
        priority = 200;  # Higher priority than leaf
        
        networking = {
          hostName = "rtr-noisy";
          spineNetworks = [ "10.254.0.0/16" "fd42:1337:254::/64" ];
        };
        
        routing = {
          ospf = {
            enable = true;
            area = "0.0.0.0";
            networks = [ "10.254.0.0/16" ];
          };
          
          bgp = {
            enable = true;
            asNumber = 65000;
            fullMesh = true;
            multihop = true;
            multihopTtl = 255;
            neighbors = [ "10.254.0.1" ];  # rtr-sapinet
          };
        };
        
        wireguard = {
          enable = true;
          interface = "wg0";
          spinePeers = [ "rtr-sapinet:51820" ];
        };
      };
      
      leaf = {
        enable = true;
        roleId = "leaf1";
        description = "Hybrid node leaf component";
        priority = 100;
        
        networking = {
          hostName = "rtr-noisy";
          leafNetworks = [ "10.254.1.0/24" "fd42:1337:254:1::/64" ];
        };
        
        routing = {
          bgp = {
            enable = true;
            asNumber = 65000;
            evpnEnable = true;
            vxlanEnable = true;
            vxlanVni = 100;
            spinePeers = [ "10.254.0.1" ];  # rtr-sapinet
          };
        };
        
        vxlan = {
          enable = true;
          vni = 100;
          interface = "vxlan100";
          ipv4Network = "10.254.100.0/24";
          ipv6Network = "fd42:1337:254:100::/64";
        };
        
        wireguard = {
          enable = true;
          interface = "wg0";
          spinePeers = [ "rtr-sapinet:51820" ];
        };
      };
    };
  };
  
  # Additional hybrid-specific configuration
  system.activationScripts.hybridSetup = lib.mkBefore ''
    echo "Setting up hybrid node configuration..."
    
    # Create hybrid configuration marker
    mkdir -p /etc/nixos-fabric/hybrid
    cat > /etc/nixos-fabric/hybrid/config <<EOF
# Hybrid Node Configuration
HYBRID_SPINE_ROLE_ID="spine2"
HYBRID_LEAF_ROLE_ID="leaf1"
HYBRID_NODE_HOSTNAME="${config.networking.hostName}"
HYBRID_NODE_DESCRIPTION="Hybrid Spine+Leaf Node"
EOF
    
    # Set up role priority environment variables
    echo "export HYBRID_SPINE_PRIORITY=200" >> /etc/profile.d/hybrid-roles.sh
    echo "export HYBRID_LEAF_PRIORITY=100" >> /etc/profile.d/hybrid-roles.sh
    
    echo "Hybrid node setup completed"
  '';
  
  # Hybrid-specific environment variables
  environment.sessionVariables = {
    NIXOS_FABRIC_HYBRID_NODE = "true";
    NIXOS_FABRIC_HYBRID_SPINE_ROLE = "spine2";
    NIXOS_FABRIC_HYBRID_LEAF_ROLE = "leaf1";
  };
  
  # Hybrid monitoring configuration
  services.prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "hybrid-node";
        static_configs = [
          {
            targets = [ "localhost:9100" ];
            labels = {
              role = "hybrid";
              spine_role = "spine2";
              leaf_role = "leaf1";
            };
          }
        ];
      }
    ];
  };
}