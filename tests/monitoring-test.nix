{ pkgs, ... }:

let
  testPrometheus = import ./monitoring-prometheus-test.nix;
  testGrafana = import ./monitoring-grafana-test.nix;
  testExporters = import ./monitoring-exporters-test.nix;
  
in {
  prometheus = testPrometheus;
  grafana = testGrafana;
  exporters = testExporters;
}
