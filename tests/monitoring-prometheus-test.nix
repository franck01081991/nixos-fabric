{ pkgs, ... }:

let
  # Test Prometheus configuration
  prometheusConfig = {
    enable = true;
    port = 9090;
    scrapeInterval = "15s";
    scrapeTargets = [
      {
        targets = [ "localhost:9090" ];
        labels = { job = "prometheus"; };
      }
    ];
  };
in
{
  prometheusConfig = prometheusConfig;
  isValid = prometheusConfig.enable != null && prometheusConfig.port != null;
}