# NixOS Fabric Security Module Entry Point
# 
# This file serves as the main entry point for the security module,
# providing a clean interface and organization.

{ config, lib, pkgs, ... }:

let
  # Import all security submodules
  securityModules = [
    ./default.nix  # Main security module
  ];

  # Combine all security configurations
  combinedConfig = lib.foldl' (acc: module: 
    acc // (import module { inherit config lib pkgs; })
  ) {} securityModules;

in combinedConfig