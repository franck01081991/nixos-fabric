{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.monitoring || {};
  hostname = config.networking.hostName;
  isLeaf = hostname == "rtr-noisy";
  isSpine = hostname == "rtr-sapinet";
  
  # Default monitoring ports
  nodeExporterPort = 9100;
  prometheusPort = 9090;
  grafanaPort = 3000;
  wireguardExporterPort = 9586;
  frrExporterPort = 2605;
  
in {
  options.network-fabric.monitoring = {
    enable = lib.mkDefault false;
    
    # Lightweight mode: only exporters, no Prometheus/Grafana
    lightweightMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable lightweight monitoring (exporters only, no Prometheus/Grafana)";
    };
    
    # Remote Prometheus server (optional)
    remotePrometheus = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault false;
          server = lib.mkDefault "";
          port = lib.mkDefault 9090;
        };
      };
    };
    
    nodeExporter = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          port = lib.mkDefault nodeExporterPort;
          collectSystemdUnits = lib.mkDefault true;
          # Optional: push gateway for remote monitoring
          pushGateway = lib.mkDefault "";
        };
      };
    };
    
    wireguardExporter = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault isLeaf;
          port = lib.mkDefault wireguardExporterPort;
          interface = lib.mkDefault "wgtransport";
        };
      };
    };
    
    frrExporter = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          port = lib.mkDefault frrExporterPort;
        };
      };
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Lightweight monitoring: only exporters, no Prometheus/Grafana
    services.node-exporter = lib.mkIf cfg.nodeExporter.enable {
      enable = true;
      port = cfg.nodeExporter.port;
      collectSystemdUnits = cfg.nodeExporter.collectSystemdUnits;
      extraFlags = lib.mkAfter [
        "--collector.textfile.directory=${pkgs.node_exporter}/share/node_exporter/textfile_collector"
        (lib.mkIf (cfg.remotePrometheus.enable && cfg.remotePrometheus.server != "") 
          "--web.listen-address=0.0.0.0:${toString cfg.nodeExporter.port}")
      ];
    };
    
    # WireGuard Exporter (only on leaf nodes)
    services.wireguard-exporter = lib.mkIf (cfg.wireguardExporter.enable && isLeaf) {
      enable = true;
      port = cfg.wireguardExporter.port;
      interface = cfg.wireguardExporter.interface;
      settings = lib.mkIf cfg.remotePrometheus.enable {
        listen-address = "0.0.0.0:${toString cfg.wireguardExporter.port}";
      };
    };
    
    # FRR Exporter
    services.frr-exporter = lib.mkIf cfg.frrExporter.enable {
      enable = true;
      port = cfg.frrExporter.port;
      frrAddress = "localhost";
      frrPort = 2605;
      settings = lib.mkIf cfg.remotePrometheus.enable {
        listen-address = "0.0.0.0:${toString cfg.frrExporter.port}";
      };
    };
    
    # Open firewall only for exporter ports (no Prometheus/Grafana)
    networking.firewall.allowedTCPPorts = lib.mkAfter [
      nodeExporterPort
      wireguardExporterPort
      frrExporterPort
    ];
    
    # Optional: Push gateway for remote monitoring
    services.pushgateway = lib.mkIf (cfg.nodeExporter.pushGateway != "") {
      enable = true;
      address = cfg.nodeExporter.pushGateway;
      interval = "60s";
      jobs = [
        {
          name = "node_exporter";
          address = "http://localhost:${toString cfg.nodeExporter.port}";
        }
      ];
    };
  };
}
