#!/usr/bin/env nix
# NixOS Fabric Test Runner
# This script runs all tests for the fabric configuration

{ pkgs, ... }:

let
  # Import test utilities
  testUtils = import ./utils/default.nix { inherit pkgs; };
  
  # Test modules - Updated for new structure
  fabricTests = import ./modules/core/network-fabric.nix { inherit pkgs testUtils; };
  roleTests = import ./modules/networking/roles/generic.nix { inherit pkgs testUtils; };
  ansibleTests = import ./modules/integration/ansible.nix { inherit pkgs testUtils; };
  integrationTests = import ./modules/security/network-security.nix { inherit pkgs testUtils; };
  
  # All tests
  allTests = [
    fabricTests
    roleTests
    ansibleTests
    integrationTests
  ];

in 
{
  # Run all tests
  runAll = pkgs.stdenv.mkDerivation {
    name = "nixos-fabric-tests";
    buildInputs = [ pkgs.bash pkgs.coreutils pkgs.jq pkgs.nix ];
    
    buildPhase = ''
      echo "🧪 Running NixOS Fabric Tests"
      echo "================================"
      
      # Run each test suite
      ${pkgs.concatStringsSep "\n" (map (test: 
        ''
          echo "Running ${test.name}..."
          ${test.command}
          if [ $? -ne 0 ]; then
            echo "❌ ${test.name} failed"
            exit 1
          fi
          echo "✅ ${test.name} passed"
        ''
      ) (pkgs.concatLists (map (testSuite: testSuite.tests) allTests))}
      
      echo ""
      echo "🎉 All tests passed!"
    '';
  };
  
  # Individual test suites
  inherit fabricTests roleTests ansibleTests integrationTests;
  
  # Test runner script
  testRunner = pkgs.writeScriptBin "fabric-test-runner" {
    interpreter = "${pkgs.bash}/bin/bash";
    text = ''
      set -euo pipefail
      
      echo "NixOS Fabric Test Runner"
      echo "Usage: $0 [test-suite] [test-name]"
      echo ""
      echo "Available test suites:"
      echo "  all          - Run all tests"
      echo "  fabric       - Fabric configuration tests"
      echo "  roles        - Role system tests"
      echo "  ansible      - Ansible integration tests"
      echo "  integration  - Integration tests"
      echo ""
      echo "Examples:"
      echo "  $0 all                        # Run all tests"
      echo "  $0 fabric                     # Run fabric tests"
      echo "  $0 roles hybrid-validation    # Run specific role test"
    '';
  };
}