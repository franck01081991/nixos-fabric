{ config, pkgs, ... }:

{
  imports = [
    ../../tests/vm-test-config.nix
  ];
  
  # Test-specific configuration
  environment.sessionVariables.TEST_VM = "true";
}