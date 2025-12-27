{ pkgs, ... }:

let
  # Test Grafana configuration
  grafanaConfig = {
    enable = true;
    port = 3000;
    auth = {
      anonymous = {
        enabled = false;
      };
    };
  };
in
{
  grafanaConfig = grafanaConfig;
  isValid = grafanaConfig.enable != null && grafanaConfig.port != null;
}