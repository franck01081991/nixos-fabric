# Monitoring Host Role
# 
# This role provides monitoring capabilities including
# Prometheus, Grafana, and basic system monitoring.

{ config, lib, pkgs, ... }:

{
  # Monitoring services
  services.prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [ { targets = [ "localhost:9100" ] } ];
      }
    ];
  };

  services.node-exporter = {
    enable = true;
  };

  services.grafana = {
    enable = true;
    address = "0.0.0.0";
    port = 3000;
    datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        url = "http://localhost:9090";
        access = "proxy";
        isDefault = true;
      }
    ];
  };

  # Monitoring tools
  environment.systemPackages = with pkgs; [
    prometheus
    grafana
    node_exporter
    netdata
    htop
    iotop
    iftop
  ];

  # Monitoring configuration
  systemd.services.prometheus = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
  };

  systemd.services.node-exporter = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
  };

  # Monitoring ports
  networking.firewall.allowedTCPPorts = lib.mkIf (config.networking.firewall.enable) [
    9090  # Prometheus
    3000  # Grafana
    9100  # Node Exporter
  ];
}