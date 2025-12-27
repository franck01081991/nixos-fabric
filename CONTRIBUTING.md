# Contributing to NixOS Fabric

Welcome to the NixOS Fabric project! We appreciate your interest in contributing. This guide will help you get started with contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#-code-of-conduct)
- [Getting Started](#-getting-started)
- [Development Workflow](#-development-workflow)
- [Configuration Guidelines](#-configuration-guidelines)
- [Testing](#-testing)
- [Documentation](#-documentation)
- [Submitting Changes](#-submitting-changes)
- [Review Process](#-review-process)
- [Maintenance](#-maintenance)

## 🤝 Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it to understand the expected behavior.

## 🚀 Getting Started

### Prerequisites

- NixOS 25.11 or later
- Git
- Basic understanding of Nix language
- Familiarity with network concepts (OSPF, BGP, EVPN)

### Setting Up Your Environment

```bash
# Clone the repository
git clone https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric

# Initialize submodules
git submodule update --init --recursive

# Check the flake
nix flake check

# Build a configuration
nix build .#nixosConfigurations.rtr-sapinet.config.system.build.toplevel
```

### Project Structure

```
nixos-fabric/
├── docs/                  # Documentation
├── hosts/                 # Host configurations
├── modules/               # Nix modules
├── scripts/               # Utility scripts
├── ansible/               # Ansible integration
├── external/              # External submodules
└── tests/                 # Test configurations
```

## 🔧 Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feat/your-feature-name
```

### 2. Make Your Changes

- Follow the existing code style
- Keep changes focused and atomic
- Update documentation as needed
- Add tests for new functionality

### 3. Test Your Changes

```bash
# Test configuration evaluation
nix eval .#nixosConfigurations.rtr-sapinet.config.networking.hostName

# Test configuration building
nix build .#nixosConfigurations.rtr-sapinet.config.system.build.toplevel

# Test in a VM
nix run .#nixosConfigurations.rtr-sapinet.config.system.build.vm
```

### 4. Run the Test Suite

```bash
./tests/run-tests.nix
```

### 5. Update Documentation

- Update relevant documentation files
- Add examples if applicable
- Update architecture diagrams if needed

### 6. Commit Your Changes

```bash
git add .
git commit -m "feat: add your feature description"
```

### 7. Push to Your Fork

```bash
git push origin feat/your-feature-name
```

### 8. Create a Pull Request

- Provide a clear description of your changes
- Reference any related issues
- Include screenshots if applicable
- Request review from maintainers

## 📖 Configuration Guidelines

### Nix Module Structure

```nix
# Recommended module structure
{ config, lib, pkgs, ... }:

{
  options = {
    # Define your options here
    your-module.enable = lib.mkEnableOption "Enable your module";
    your-module.setting = lib.mkOption {
      type = lib.types.str;
      default = "default-value";
      description = "Description of this setting";
    };
  };
  
  config = lib.mkIf config.your-module.enable {
    # Your configuration here
    environment.systemPackages = with pkgs; [ your-package ];
    systemd.services.your-service = {
      description = "Your service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${your-package}/bin/your-service";
      };
    };
  };
}
```

### Role Configuration

```nix
# Spine role example
{
  network-fabric.roles.spine = {
    enable = true;
    roleId = "spine1";
    # Spine-specific configuration
    routing = {
      ospf = {
        area = "0.0.0.0";
        networks = [ "10.254.0.0/16" ];
      };
      bgp = {
        asNumber = 65000;
        neighbors = [ "10.254.0.11" ];
      };
    };
  };
}
```

### Network Configuration

```nix
# Network interface example
{
  networking.interfaces.eth0 = {
    ipv4.addresses = [ {
      address = "10.254.0.1";
      prefixLength = 24;
    } ];
    ipv6.addresses = [ {
      address = "fd42:1337:254::1";
      prefixLength = 64;
    } ];
  };
}
```

## 🧪 Testing

### Test Structure

```
tests/
├── hosts/               # Host-specific tests
├── modules/              # Module tests
├── integration/          # Integration tests
└── run-tests.nix         # Test runner
```

### Writing Tests

```nix
# Example test in tests/modules/networking.nix
{ pkgs, ... }:

let
  testConfig = {
    networking.interfaces.eth0.ipv4.addresses = [ {
      address = "10.0.0.1";
      prefixLength = 24;
    } ];
  };
  
  testModule = { config, lib, pkgs, ... }: {
    options = { };
    config = { };
  };
  
  testResult = pkgs.lib.nixosTest {
    name = "networking-config";
    inherit testModule;
    testScript = ''
      machine.succeed("ip addr show eth0 | grep '10.0.0.1'")
    '';
  };

in testResult
```

### Running Tests

```bash
# Run all tests
./tests/run-tests.nix

# Run specific test
nix-build tests/modules/networking.nix

# Run in a VM
nix run .#nixosConfigurations.rtr-sapinet.config.system.build.vm --test
```

## 📚 Documentation

### Documentation Structure

```
docs/
├── architecture/        # Architecture documents
├── deployment/          # Deployment guides
├── development/         # Development documentation
├── reference/           # Reference materials
└── troubleshooting/      # Troubleshooting guides
```

### Writing Documentation

```markdown
# Example Documentation Structure

## 🎯 Overview

Brief description of the topic.

## 🔧 Configuration

### Basic Configuration

```nix
# Example configuration
{
  your-module.enable = true;
  your-module.setting = "value";
}
```

### Advanced Configuration

```nix
# Advanced example
{
  your-module = {
    enable = true;
    advanced = {
      setting1 = "value1";
      setting2 = "value2";
    };
  };
}
```

## 🚀 Usage

### Basic Usage

```bash
# Example command
your-command --option value
```

### Advanced Usage

```bash
# Advanced example
your-command --advanced-option value --another-option value
```

## 🛡️ Security

Security considerations and best practices.

## 📚 References

- [Related Documentation](link-to-docs)
- [Official Documentation](link-to-official-docs)
```

### Documentation Standards

1. **Use clear section headers** with emojis for visual separation
2. **Provide examples** for all configuration options
3. **Include usage examples** with actual commands
4. **Document security considerations** where applicable
5. **Link to related documentation** for further reading

## 📤 Submitting Changes

### Commit Message Guidelines

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding or modifying tests
- `chore`: Maintenance tasks

**Example:**
```
feat(networking): add IPv6 support for WireGuard

- Add IPv6 address configuration to WireGuard module
- Update documentation with IPv6 examples
- Add tests for IPv6 connectivity

Closes #42
```

### Pull Request Guidelines

1. **Clear title** describing the change
2. **Detailed description** explaining:
   - What problem is being solved
   - How the solution works
   - Any breaking changes
   - Testing performed
3. **Reference related issues** using `Closes #123` or `Related to #123`
4. **Include screenshots** if UI changes are involved
5. **Request specific reviewers** if needed

## 👀 Review Process

### Review Checklist

- [ ] Code follows project style guidelines
- [ ] Changes are focused and atomic
- [ ] Documentation is updated
- [ ] Tests are added/modified
- [ ] No breaking changes without justification
- [ ] Security considerations are addressed
- [ ] Performance impact is acceptable

### Review Timeline

1. **Initial Review**: Within 48 hours of PR submission
2. **Feedback Response**: Within 72 hours of feedback
3. **Final Approval**: Within 24 hours of final changes
4. **Merge**: After all checks pass

## 🛠️ Maintenance

### Versioning

We follow semantic versioning:
- `MAJOR`: Breaking changes
- `MINOR`: New features (backward compatible)
- `PATCH`: Bug fixes (backward compatible)

### Release Process

1. **Create release branch**: `release/vX.Y.Z`
2. **Update changelog**: Document all changes
3. **Run full test suite**: Ensure all tests pass
4. **Create Git tag**: `vX.Y.Z`
5. **Publish release**: Create GitHub release
6. **Merge to master**: Update main branch

### Deprecation Policy

1. **Announce deprecation** in release notes
2. **Maintain deprecated features** for 2 minor versions
3. **Remove in major version** with clear migration path

## 🤝 Community

### Getting Help

- **GitHub Issues**: For bug reports and feature requests
- **Discussions**: For general questions and ideas
- **Documentation**: For usage and configuration questions

### Community Guidelines

1. **Be respectful** and considerate
2. **Help others** when you can
3. **Share knowledge** through documentation
4. **Give constructive feedback**
5. **Celebrate successes** together

## 🎉 Thank You!

Your contributions help make NixOS Fabric better for everyone. We appreciate your time and effort in improving this project!

Happy hacking! 🚀