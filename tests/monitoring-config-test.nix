{ pkgs, ... }:

let
  # Test monitoring configuration
  monitoringConfig = {
    prometheus = {
      enable = true;
      port = 9090;
      scrapeInterval = "15s";
    };
    nodeExporter = {
      enable = true;
      port = 9100;
    };
    grafana = {
      enable = true;
      port = 3000;
    };
  };
in
{
  monitoringConfig = monitoringConfig;
  isValid = monitoringConfig.prometheus != null && monitoringConfig.nodeExporter != null && monitoringConfig.grafana != null;
}