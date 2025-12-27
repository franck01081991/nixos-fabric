# NixOS Fabric Tests

## Overview

This directory contains comprehensive tests for the NixOS Fabric project, organized by test type and purpose.

## Test Structure

```
tests/
├── unit/                # Unit tests
│   ├── modules/         # Module-specific tests
│   └── utils/           # Utility function tests
│
├── integration/        # Integration tests
│   ├── fabric/          # Fabric-level integration tests
│   └── scenarios/       # Complex scenario tests
│
├── vm/                 # VM-based tests
│   ├── configurations/  # Test VM configurations
│   └── test-vm.nix      # Main VM test configuration
│
├── scripts/            # Test execution scripts
│   ├── run-local-tests.sh # Local test runner
│   ├── run-organized-tests.sh # Organized test runner
│   ├── run-security-tests.sh # Security test runner
│   └── deploy-and-test.sh # Deployment + test script
│
└── README.md            # This documentation
```

## Test Types

### Unit Tests

Unit tests verify individual modules and functions in isolation.

**Location**: `tests/unit/`

**Examples**:
- `tests/unit/modules/security/default.nix` - Security module tests
- `tests/unit/modules/networking/default.nix` - Networking module tests
- `tests/unit/utils/default.nix` - Utility function tests

**Run unit tests**:
```bash
./tests/scripts/run-local-tests.sh
```

### Integration Tests

Integration tests verify interactions between multiple components.

**Location**: `tests/integration/`

**Examples**:
- `tests/integration/fabric/wireguard-test.nix` - WireGuard integration
- `tests/integration/fabric/bgp-test.nix` - BGP integration
- `tests/integration/fabric/vlan-test.nix` - VLAN integration

**Run integration tests**:
```bash
./tests/scripts/run-organized-tests.sh
```

### VM Tests

VM tests run in actual NixOS virtual machines for realistic testing.

**Location**: `tests/vm/`

**Examples**:
- `tests/vm/test-vm.nix` - Main VM test configuration
- `tests/vm/configurations/` - Specific test configurations

**Run VM tests**:
```bash
nix-build tests/vm/test-vm.nix
```

## Test Execution

### Running All Tests

```bash
# Run all tests locally
./tests/scripts/run-local-tests.sh

# Run organized test suite
./tests/scripts/run-organized-tests.sh

# Run security-specific tests
./tests/scripts/run-security-tests.sh
```

### Running Specific Tests

```bash
# Run a specific unit test
nix-instantiate tests/unit/modules/security/default.nix

# Run a specific integration test
nix-instantiate tests/integration/fabric/wireguard-test.nix

# Run VM test
nix-build tests/vm/test-vm.nix
```

## Test Development

### Writing Unit Tests

Unit tests should:

1. **Test one module** or function at a time
2. **Use simple inputs** and expected outputs
3. **Be fast to execute**
4. **Cover edge cases**

**Example**:
```nix
# tests/unit/modules/security/default.nix
{ pkgs, ... }:

let
  testModule = import ../../../modules/security/default.nix;
  
  # Test configuration
  testConfig = {
    network-fabric.security = {
      enable = true;
      ssh = {
        port = 2222;
        passwordAuthentication = false;
      };
    };
  };
  
  # Expected result
  expectedResult = {
    services.openssh.settings.Port = 2222;
    services.openssh.settings.PasswordAuthentication = false;
  };
  
in {
  # Test that module produces expected configuration
  assert (testModule.config == expectedResult);
  
  # Return test result
  inherit (testModule) config;
}
```

### Writing Integration Tests

Integration tests should:

1. **Test interactions** between multiple components
2. **Use realistic configurations**
3. **Verify end-to-end behavior**
4. **Include error handling**

**Example**:
```nix
# tests/integration/fabric/wireguard-test.nix
{ pkgs, ... }:

let
  # Import multiple modules
  networkModule = import ../../../../modules/networking/networking.nix;
  wireguardModule = import ../../../../modules/networking/wireguard.nix;
  securityModule = import ../../../../modules/security/default.nix;
  
  # Test configuration with multiple modules
  testConfig = {
    imports = [
      networkModule
      wireguardModule
      securityModule
    ];
    
    network-fabric = {
      networking.enable = true;
      wireguard.enable = true;
      security.enable = true;
    };
  };
  
in {
  # Verify that modules work together correctly
  assert (testConfig.config.network-fabric.wireguard.enable);
  assert (testConfig.config.network-fabric.security.enable);
  
  # Return combined configuration
  inherit (testConfig) config;
}
```

### Writing VM Tests

VM tests should:

1. **Test in real NixOS environment**
2. **Include system-level testing**
3. **Verify service behavior**
4. **Test deployment scenarios**

**Example**:
```nix
# tests/vm/test-vm.nix
{ pkgs, ... }:

let
  # VM configuration
  vmConfig = {
    imports = [
      ../../../modules/core/network-fabric.nix
      ../../../modules/networking/wireguard.nix
      ../../../modules/security/init.nix
    ];
    
    network-fabric = {
      name = "test-fabric";
      environment = "test";
      
      wireguard = {
        enable = true;
        peers = [
          {
            name = "test-peer";
            publicKey = "test-key";
            allowedIPs = [ "10.0.0.2/32" ];
          }
        ];
      };
      
      security = {
        enable = true;
        firewall = {
          allowedTCP = [ 22 51820 ];
        };
      };
    };
  };
  
in {
  # Create test VM
  vm = pkgs.nixosTest {
    name = "nixos-fabric-test";
    configuration = vmConfig;
    
    # Test script
    testScript = ''
      # Verify WireGuard interface
      ip link show wgtransport
      
      # Verify firewall rules
      nft list ruleset | grep "wireguard"
      
      # Verify SSH configuration
      grep "Port 22" /etc/ssh/sshd_config
    '';
  };
  
  inherit vm;
}
```

## Test Best Practices

### General Guidelines

1. **Keep tests focused** - Each test should verify one thing
2. **Use descriptive names** - Clear test names help debugging
3. **Test both success and failure** cases
4. **Keep tests fast** - Slow tests discourage running them
5. **Document test purpose** - Add comments explaining what's tested

### Test Organization

1. **Group related tests** together
2. **Use consistent naming** conventions
3. **Separate test data** from test logic
4. **Keep test configurations** simple and focused

### Performance Optimization

1. **Run unit tests first** - They're fastest
2. **Use caching** for expensive operations
3. **Parallelize tests** when possible
4. **Skip slow tests** in development when appropriate

## Test Maintenance

### Updating Tests

When updating code:

1. **Update corresponding tests**
2. **Add new tests** for new features
3. **Verify all tests pass**
4. **Document changes** in test documentation

### Test Refactoring

When refactoring:

1. **Run tests frequently** during refactoring
2. **Update tests incrementally**
3. **Verify behavior** remains the same
4. **Add regression tests** for fixed bugs

## Continuous Integration

Tests are automatically run in CI/CD pipelines:

- **Unit tests**: Run on every commit
- **Integration tests**: Run on pull requests
- **VM tests**: Run on main branch and releases

See `.github/workflows/ci-cd-pipeline.yml` for CI configuration.

## Troubleshooting

### Common Test Issues

**Test failures**:
- Check test output for specific errors
- Verify test assumptions are correct
- Test in isolation to identify conflicts

**Slow tests**:
- Profile test execution
- Optimize test setup
- Consider test parallelization

**Flaky tests**:
- Add retries for unreliable operations
- Improve test isolation
- Verify external dependencies

### Debugging Commands

```bash
# Run specific test with verbose output
nix-instantiate -v tests/unit/modules/security/default.nix

# Check test evaluation
nix eval -f tests/unit/modules/security/default.nix

# Test in Nix shell
nix-shell -p nix-info --run "nix-instantiate tests/unit/modules/security/default.nix"

# Debug VM test
nix-build tests/vm/test-vm.nix -K
```

## Contributing Tests

Contributions to the test suite are welcome!

### Test Contribution Guidelines

1. **Add tests for new features**
2. **Follow existing patterns**
3. **Document test purpose**
4. **Keep tests maintainable**
5. **Verify tests pass** before submitting

### Areas Needing Tests

- Additional module coverage
- Edge case scenarios
- Error handling paths
- Performance testing
- Security testing

## License

Tests are licensed under the MIT License, same as the main project.

## Support

For test-related issues, please open a GitHub issue with the `test` tag.