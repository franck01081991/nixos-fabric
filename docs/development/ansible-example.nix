{ config, lib, pkgs, ... }:

{
  # Enable Ansible integration
  network-fabric.ansible = {
    enable = true;
    
    # Use a specific Ansible version
    version = "core-2.15";
    
    # Automatically generate inventory from NixOS hosts
    generateInventory = true;
    
    # List of playbooks to make available
    playbooks = [
      "main.yml"
      "verify-fabric.yml"
      "deploy-new-node.yml"
    ];
    
    # Custom Ansible configuration
    configOptions = {
      defaults = {
        inventory = "/etc/nixos-fabric/ansible/inventory/hosts.ini";
        remote_user = "root";
        host_key_checking = false;
        interpreter_python = "auto_silent";
      };
      privilege_escalation = {
        become = true;
        become_method = "sudo";
        become_user = "root";
        become_ask_pass = false;
      };
      ssh_connection = {
        pipelining = true;
        ssh_args = "-o ControlMaster=auto -o ControlPersist=60s";
      };
    };
    
    # Host-specific variables
    hostVars = {
      "rtr-sapinet" = {
        wireguard_address = "10.255.0.1/24";
        wireguard_endpoint = "45.90.162.251";
        frr_ospf_router_id = "10.254.0.1";
        node_role = "spine";
        
        # WireGuard peers
        wireguard_peers = [
          {
            name = "rtr-noisy";
            public_key = "BASE64_PUBLIC_KEY";
            endpoint = "RTR_NOISY_IP:51820";
            allowed_ips = "10.255.0.11/32";
          }
        ];
      };
      
      "rtr-noisy" = {
        wireguard_address = "10.255.0.11/24";
        wireguard_endpoint = "RTR_NOISY_IP";
        frr_ospf_router_id = "10.254.0.11";
        node_role = "hybrid";
        
        # Hybrid role configuration
        hybrid_roles = [ "spine" "leaf" ];
        
        # WireGuard peers
        wireguard_peers = [
          {
            name = "rtr-sapinet";
            public_key = "BASE64_PUBLIC_KEY";
            endpoint = "45.90.162.251:51820";
            allowed_ips = "10.255.0.1/32";
          }
        ];
      };
    };
    
    # Group variables
    groupVars = {
      "spine" = {
        frr_bgp_as_number = 65000;
        fabric_networks = [
          "10.254.0.0/24"
          "10.255.0.0/24"
          "fd42:1337:254::/64"
        ];
        
        # Spine-specific FRR configuration
        frr_ospf = {
          area = "0.0.0.0";
          networks = [
            "10.254.0.0/24"
            "10.255.0.0/24"
          ];
        };
      };
      
      "leaf" = {
        frr_bgp_as_number = 65000;
        fabric_networks = [
          "10.254.0.0/24"
          "10.255.0.0/24"
          "fd42:1337:254::/64"
        ];
        
        # Leaf-specific EVPN configuration
        frr_evpn = {
          enable = true;
          vni = 100;
        };
      };
      
      "all" = {
        # Common variables for all hosts
        ansible_user = "root";
        ansible_become = true;
        
        # Common packages to ensure
        common_packages = [
          "git"
          "curl"
          "vim"
          "wireguard-tools"
          "frr"
        ];
      };
    };
  };
  
  # Ensure base configuration is enabled
  network-fabric.base = {
    enable = true;
    configDir = "/etc/nixos-fabric";
  };
}