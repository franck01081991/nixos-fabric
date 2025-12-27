{ pkgs, ... }:

let
  # Test exporters configuration
  exportersConfig = {
    nodeExporter = {
      enable = true;
      port = 9100;
    };
    blackboxExporter = {
      enable = true;
      port = 9115;
    };
  };
in
{
  exportersConfig = exportersConfig;
  isValid = exportersConfig.nodeExporter != null && exportersConfig.blackboxExporter != null;
}