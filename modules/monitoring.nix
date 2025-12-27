{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.monitoring;
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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable monitoring functionality";
    };
    
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
  
  config = lib.mkIf (config.network-fabric.monitoring.enable) {
    # Lightweight monitoring: only exporters, no Prometheus/Grafana
    systemd.services.node-exporter = lib.mkIf cfg.nodeExporter.enable {
      description = "Node Exporter";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.node_exporter}/bin/node_exporter \
          --web.listen-address=:${toString cfg.nodeExporter.port} \
          ${lib.mkIf cfg.nodeExporter.collectSystemdUnits "--collector.systemd" ""} \
          --collector.textfile.directory=${pkgs.node_exporter}/share/node_exporter/textfile_collector \
          ${lib.mkIf (cfg.remotePrometheus.enable && cfg.remotePrometheus.server != "") "--web.listen-address=0.0.0.0:${toString cfg.nodeExporter.port}" ""}";
        Restart = "always";
        User = "node-exporter";
      };
    };
    
    # WireGuard Exporter (only on leaf nodes)
    systemd.services.wireguard-exporter = lib.mkIf (cfg.wireguardExporter.enable && isLeaf) {
      description = "WireGuard Exporter";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.wireguard-exporter}/bin/wireguard_exporter \
          --web.listen-address=:${toString cfg.wireguardExporter.port} \
          --interface=${cfg.wireguardExporter.interface} \
          ${lib.mkIf cfg.remotePrometheus.enable "--web.listen-address=0.0.0.0:${toString cfg.wireguardExporter.port}" ""}";
        Restart = "always";
        User = "wireguard-exporter";
      };
    };
    
    # FRR Exporter (commented out as frr-exporter service doesn't exist in NixOS)
    # services.frr-exporter = lib.mkIf cfg.frrExporter.enable {
    #   enable = true;
    #   port = cfg.frrExporter.port;
    #   frrAddress = "localhost";
    #   frrPort = 2605;
    #   settings = lib.mkIf cfg.remotePrometheus.enable {
    #     listen-address = "0.0.0.0:${toString cfg.frrExporter.port}";
    #   };
    # };
    
    # Open firewall only for exporter ports (no Prometheus/Grafana)
    networking.firewall.allowedTCPPorts = lib.mkAfter [
      nodeExporterPort
      wireguardExporterPort
      frrExporterPort
    ];
    
    # Optional: Push gateway for remote monitoring
    systemd.services.pushgateway = lib.mkIf (cfg.nodeExporter.pushGateway != "") {
      description = "Push Gateway";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.prometheus}/bin/pushgateway \
          --web.listen-address=:${toString cfg.nodeExporter.port} \
          --push.interval=60s \
          --push.job=node_exporter \
          --push.address=http://localhost:${toString cfg.nodeExporter.port}";
        Restart = "always";
        User = "pushgateway";
      };
    };
  };
}
