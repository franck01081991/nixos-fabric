{ lib, ... }:

let
  # Test result structure
  makeTestResult = success: message: data:
    {
      success = success;
      message = message;
      data = data;
      timestamp = lib.mkDefault (builtins.currentTime);
    };

  # Try to evaluate and return test result
  tryEval = expr:
    let
      result = builtins.tryEval expr;
    in
    if result.success then
      makeTestResult true "Evaluation successful" result.value
    else
      makeTestResult false ("Evaluation failed: ${result.error}") null;

  # Assert equality
  assertEqual = expected: actual: message:
    if expected == actual then
      makeTestResult true (message or "Values are equal") {
        expected = expected;
        actual = actual;
      }
    else
      makeTestResult false (message or "Values are not equal") {
        expected = expected;
        actual = actual;
      };

  # Assert not null
  assertNotNull = value: message:
    if value != null then
      makeTestResult true (message or "Value is not null") value
    else
      makeTestResult false (message or "Value is null") null;

  # Assert contains
  assertContains = container: value: message:
    if builtins.elem value (builtins.attrValues container) then
      makeTestResult true (message or "Container contains value") {
        container = container;
        value = value;
      }
    else
      makeTestResult false (message or "Container does not contain value") {
        container = container;
        value = value;
      };

  # Assert config has attribute
  assertHasAttr = config: attrPath: message:
    let
      attrs = lib.splitString "." attrPath;
      result = builtins.tryEval (builtins.listToAttrs [
        { name = "config"; value = config; }
      ] // { inherit (builtins) getAttr; } + "getAttr config ${attrs}");
    in
    if result.success then
      makeTestResult true (message or "Config has attribute") {
        attribute = attrPath;
        value = result.value;
      }
    else
      makeTestResult false (message or "Config missing attribute") {
        attribute = attrPath;
        error = result.error;
      };

in {
  inherit makeTestResult tryEval assertEqual assertNotNull assertContains assertHasAttr;
}