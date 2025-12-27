{ pkgs, ... }:

# Test utilities for NixOS Fabric

let
  # Test result structure
  makeTestResult = { success, message, details }:
    {
      success = success;
      message = message;
      details = details;
      timestamp = builtins.currentTime;
    };
  
  # Test assertion functions
  assertEquals = expected: actual: 
    if expected == actual then
      makeTestResult {
        success = true;
        message = "Assertion passed";
        details = "Expected: ${builtins.toString expected}, Actual: ${builtins.toString actual}";
      }
    else
      makeTestResult {
        success = false;
        message = "Assertion failed";
        details = "Expected: ${builtins.toString expected}, Actual: ${builtins.toString actual}";
      };
  
  assertNotEquals = unexpected: actual: 
    if unexpected != actual then
      makeTestResult {
        success = true;
        message = "Assertion passed";
        details = "Unexpected: ${builtins.toString unexpected}, Actual: ${builtins.toString actual}";
      }
    else
      makeTestResult {
        success = false;
        message = "Assertion failed";
        details = "Value should not be: ${builtins.toString actual}";
      };
  
  assertTrue = condition: 
    if condition then
      makeTestResult {
        success = true;
        message = "Assertion passed";
        details = "Condition is true";
      }
    else
      makeTestResult {
        success = false;
        message = "Assertion failed";
        details = "Condition is false";
      };
  
  assertFalse = condition: 
    if !condition then
      makeTestResult {
        success = true;
        message = "Assertion passed";
        details = "Condition is false";
      }
    else
      makeTestResult {
        success = false;
        message = "Assertion failed";
        details = "Condition is true";
      };
  
  # Configuration validation functions
  validateConfig = config: schema: 
    let
      validateField = field: 
        if builtins.hasAttr field config && builtins.hasAttr field schema then
          let
            expectedType = schema.${field};
            actualValue = config.${field};
            typeCheck = 
              if expectedType == "string" then builtins.isString actualValue
              else if expectedType == "boolean" then builtins.isBool actualValue
              else if expectedType == "number" then builtins.isInt actualValue || builtins.isFloat actualValue
              else if expectedType == "list" then builtins.isList actualValue
              else if expectedType == "attrs" then builtins.isAttrs actualValue
              else true;
          in 
          if typeCheck then
            makeTestResult {
              success = true;
              message = "Field ${field} is valid";
              details = "Type: ${expectedType}, Value: ${builtins.toString actualValue}";
            }
          else
            makeTestResult {
              success = false;
              message = "Field ${field} has invalid type";
              details = "Expected: ${expectedType}, Got: ${builtins.typeOf actualValue}";
            }
        else if builtins.hasAttr field schema then
          makeTestResult {
            success = false;
            message = "Required field ${field} is missing";
            details = "Field is required but not present in config";
          }
        else
          makeTestResult {
            success = true;
            message = "Field ${field} is valid";
            details = "Field is optional";
          };
    in 
    {
      results = builtins.mapAttrs (name: value: validateField name) schema;
      overallSuccess = builtins.all (result: result.success) (builtins.attrValues (builtins.mapAttrs (name: value: validateField name) schema));
    };
  
  # NixOS test wrapper
  nixosTest = name: config: testScript: 
    pkgs.nixosTest {
      name = name;
      inherit config;
      testScript = testScript;
    };
  
  # Fabric-specific test helpers
  testFabricConfig = config: 
    let
      schema = {
        enable = "boolean";
        name = "string";
        environment = "string";
        configDir = "string";
        ansibleDir = "string";
        roles = "attrs";
        network = "attrs";
        security = "attrs";
      };
    in 
    validateConfig config schema;
  
  testRoleConfig = roleConfig: 
    let
      schema = {
        enable = "boolean";
        roleId = "string";
        description = "string";
        priority = "number";
      };
    in 
    validateConfig roleConfig schema;
  
  # Test reporting
  generateTestReport = results: 
    let
      passed = builtins.length (builtins.filter (result: result.success) results);
      failed = builtins.length (builtins.filter (result: !result.success) results);
      total = builtins.length results;
      
      failedTests = builtins.map (result: 
        "- ${result.message}: ${result.details}"
      ) (builtins.filter (result: !result.success) results);
    in 
    {
      summary = ''
        Test Results Summary
        ====================
        Total: ${builtins.toString total}
        Passed: ${builtins.toString passed}
        Failed: ${builtins.toString failed}
        Success Rate: ${builtins.toString (if total > 0 then (passed * 100) / total else 0)}%
        
        ${if failed > 0 then ''
        Failed Tests:
        ${builtins.concatStringsSep "\n" failedTests}
        '' else ""}
      '';
      success = failed == 0;
      passed = passed;
      failed = failed;
      total = total;
    };

in {
  inherit makeTestResult assertEquals assertNotEquals assertTrue assertFalse;
  inherit validateConfig nixosTest;
  inherit testFabricConfig testRoleConfig;
  inherit generateTestReport;
  
  # Additional test utilities
  runTest = name: testFunc: 
    let
      result = testFunc ();
    in {
      name = name;
      result = result;
      success = result.success;
    };
  
  createTestSuite = name: tests: 
    {
      name = name;
      tests = tests;
      run = (): builtins.map (test: runTest test.name test.func) tests;
    };
}