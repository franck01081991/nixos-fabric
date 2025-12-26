{ pkgs, ... }:

let
  # Import test utilities
  testUtils = import ./utils;

  # Define test suites
  testSuites = {
    modules = {
      networking = import ./modules/networking;
      wireguard = import ./modules/wireguard;
      frr = import ./modules/frr;
      ssh = import ./modules/ssh;
      security = import ./modules/security;
    };
    
    hosts = {
      vm-sapinet = import ./hosts/vm-sapinet;
      rtr-noisy = import ./hosts/rtr-noisy;
    };
    
    integration = import ./integration;
  };

  # Run all tests and collect results
  runTests = config: 
    let
      results = builtins.mapAttrs (suiteName: suiteTests:
        builtins.mapAttrs (testName: testFunc:
          tryEval (testFunc config)
        ) suiteTests
      ) testSuites;
      
      # Count passed/failed tests
      stats = builtins.foldl' (acc: result:
        if result.success then
          { passed = acc.passed + 1; failed = acc.failed; }
        else
          { passed = acc.passed; failed = acc.failed + 1; }
      ) { passed = 0; failed = 0; } (builtins.concatLists (builtins.attrValues (builtins.mapAttrs (name: tests: builtins.attrValues tests) results)));
    in
    {
      results = results;
      stats = stats;
      success = stats.passed > 0 && stats.failed == 0;
    };

in {
  inherit runTests;
  testSuites = testSuites;
}