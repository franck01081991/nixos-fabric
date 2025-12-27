# NixOS Fabric Security Module Entry Point
# 
# This file serves as the main entry point for the security module,
# providing a clean interface and organization.

{ config, lib, pkgs, ... }:

{
  imports = [
    ./default.nix    # Main security module
    ./ssh.nix        # SSH security module
    ./firewall.nix   # Firewall security module
    ./hardening.nix  # System hardening module
  ];
}