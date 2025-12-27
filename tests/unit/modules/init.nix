# Security Module Test Suite Entry Point
# 
# This file serves as the main entry point for security module tests,
# providing a clean interface for running different test scenarios.

{ pkgs ? import <nixpkgs> {} }:

let
  lib = import <nixpkgs/lib>;
  
  # Import all security test modules
  securityTests = [
    ./default.nix  # Main security test suite
  ];

  # Combine all test configurations
  combinedTests = lib.foldl' (acc: testModule: 
    acc // (import testModule { inherit pkgs lib; })
  ) {} securityTests;

in combinedTests