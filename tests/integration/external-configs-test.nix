{ pkgs, ... }:

let
  # Import test utilities
  testUtils = import ../../modules/utils/lib/utils.nix;
  
  # Find all external configurations dynamically
  externalConfigs = builtins.filter (path: 
    builtins.isAttrs (builtins.tryEval (builtins.import path)) 
  ) (
    builtins.attrNames (
      builtins.filterAttrs (name: _: 
        builtins.stringLength name > 0 && 
        builtins.hasSuffix "-config" name
      ) (builtins.readDir ./external)
    )
  );
  
  # Test each external configuration
  testExternalConfig = configPath: 
    let
      configName = builtins.baseNameOfFile configPath;
      
      # Try to import and evaluate the configuration
      configResult = builtins.tryEval (
        with import <nixpkgs> {}; 
        callPackage (./external/${configName}/default.nix) {}
      );
      
      # Check for required attributes
      hasRequiredAttrs = 
        configResult.success && 
        builtins.isAttrs configResult.value && 
        builtins.hasAttr "network-fabric" configResult.value;
      
      # Check for common security issues
      securityChecks = 
        if hasRequiredAttrs && builtins.hasAttr "network-fabric" configResult.value then
          let
            nf = configResult.value.network-fabric;
          in
          {
            hasSecurity = builtins.hasAttr "security" nf;
            hasNetworking = builtins.hasAttr "networking" nf;
            hasProperStructure = 
              builtins.isAttrs nf && 
              (builtins.hasAttr "security" nf || builtins.hasAttr "networking" nf);
          }
        else
          {
            hasSecurity = false;
            hasNetworking = false;
            hasProperStructure = false;
          };
      
    in {
      inherit configName;
      success = configResult.success;
      hasRequiredAttrs = hasRequiredAttrs;
      inherit securityChecks;
      error = if configResult.success then null else "Evaluation failed: ${configResult.error}";
    };
  
  # Run tests on all external configs
  testResults = builtins.listToAttrs (
    builtins.map (idx: 
      let configName = externalConfigs[idx]; in
      "${configName}" -> testExternalConfig ("external/${configName}")
    ) (builtins.genList (idx: idx) (builtins.length externalConfigs - 1))
  );
  
  # Overall test status
  allPassed = builtins.all (result: result.success && result.hasRequiredAttrs) 
    (builtins.attrValues testResults);
  
in {
  inherit testResults allPassed;
  
  # Summary information
  summary = {
    totalConfigs = builtins.length externalConfigs;
    passedConfigs = builtins.length (
      builtins.filterAttrs (name: result: result.success && result.hasRequiredAttrs) testResults
    );
    failedConfigs = builtins.length (
      builtins.filterAttrs (name: result: !result.success || !result.hasRequiredAttrs) testResults
    );
    
    # Detailed failure information
    failures = builtins.filterAttrs (name: result: !result.success || !result.hasRequiredAttrs) testResults;
  };
  
  # Return test results in a structured format
  inherit externalConfigs;
}