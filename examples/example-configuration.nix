{ config, pkgs, ... }:

{
  # Example NixOS Fabric configuration
  
  # Enable the NixOS Fabric module
  network-fabric = {
    enable = true;
    
    # Ansible integration
    ansible = {
      enable = true;
      generateInventory = true;
      playbooks = [
        "setup-common.yml"
        "main.yml"
        "verify-fabric.yml"
      ];
    };
    
    # Security module
    security = {
      enable = true;
      
      # SSH configuration
      ssh = {
        enable = true;
        port = 2222;
        permitRootLogin = "no";
        passwordAuthentication = "no";
      };
      
      # Firewall configuration
      firewall = {
        enable = true;
        allowedTCPPorts = [ 2222 80 443 ];
        allowedUDPPorts = [ 53 123 ];
      };
      
      # System hardening
      hardening = {
        enable = true;
        kernel = {
          sysctl = {
            "kernel.kptr_restrict" = 1;
            "kernel.dmesg_restrict" = 1;
          };
        };
      };
    };
    
    # Networking configuration
    networking = {
      enable = true;
      
      # WireGuard configuration
      wireguard = {
        enable = true;
        interfaces = {
          wgtransport = {
            privateKeyFile = "/etc/wireguard/private.key";
            listenPort = 51820;
            ips = [ "10.255.0.1/24" ];
            peers = [
              {
                publicKey = "peer_public_key";
                allowedIPs = [ "10.255.0.11/32" "10.254.0.11/32" ];
                endpoint = "peer_endpoint:51820";
                persistentKeepalive = 25;
              }
            ];
          };
        };
      };
      
      # FRR configuration
      frr = {
        enable = true;
        bgpd = {
          enable = true;
          config = ''
            router bgp 65001
              bgp router-id 10.254.0.1
              neighbor 10.254.0.11 remote-as 65001
              neighbor 10.254.0.11 update-source lo
              address-family ipv4 unicast
                network 10.254.0.1/32
                neighbor 10.254.0.11 activate
              exit-address-family
          '';
        };
        ospfd = {
          enable = true;
          config = ''
            router ospf
              ospf router-id 10.254.0.1
              network 10.254.0.1/32 area 0
              network 10.255.0.0/24 area 0
          '';
        };
      };
    };
    
    # Monitoring configuration
    monitoring = {
      enable = true;
      
      # Prometheus configuration
      prometheus = {
        enable = true;
        port = 9090;
        scrapeInterval = "15s";
      };
      
      # Grafana configuration
      grafana = {
        enable = true;
        port = 3000;
      };
      
      # Node Exporter configuration
      nodeExporter = {
        enable = true;
        port = 9100;
      };
    };
  };
  
  # Enable the required services
  services = {
    openssh = {
      enable = true;
      settings = {
        Port = config.network-fabric.security.ssh.port;
        PermitRootLogin = config.network-fabric.security.ssh.permitRootLogin;
        PasswordAuthentication = config.network-fabric.security.ssh.passwordAuthentication;
      };
    };
    
    fail2ban = {
      enable = config.network-fabric.security.firewall.enable;
      jails = {
        sshd = {
          settings = {
            enabled = true;
            port = config.network-fabric.security.ssh.port;
          };
        };
      };
    };
    
    prometheus = {
      enable = config.network-fabric.monitoring.prometheus.enable;
      port = config.network-fabric.monitoring.prometheus.port;
      scrapeInterval = config.network-fabric.monitoring.prometheus.scrapeInterval;
    };
    
    grafana = {
      enable = config.network-fabric.monitoring.grafana.enable;
      port = config.network-fabric.monitoring.grafana.port;
    };
    
    nodeExporter = {
      enable = config.network-fabric.monitoring.nodeExporter.enable;
      port = config.network-fabric.monitoring.nodeExporter.port;
    };
  };
  
  # Networking configuration
  networking = {
    firewall = {
      enable = config.network-fabric.security.firewall.enable;
      allowedTCPPorts = config.network-fabric.security.firewall.allowedTCPPorts;
      allowedUDPPorts = config.network-fabric.security.firewall.allowedUDPPorts;
    };
    
    wireguard = {
      enable = config.network-fabric.networking.wireguard.enable;
      interfaces = config.network-fabric.networking.wireguard.interfaces;
    };
  };
  
  # System configuration
  boot = {
    kernel = {
      sysctl = config.network-fabric.security.hardening.kernel.sysctl;
    };
  };
}