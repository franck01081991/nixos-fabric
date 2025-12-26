# NixOS Fabric Documentation

Welcome to the NixOS Fabric documentation! This guide will help you understand, use, and contribute to the spine/leaf fabric network system.

## 📚 Documentation Structure

```
docs/
├── architecture/      # System architecture and design
├── development/       # Development workflows and tools
├── deployment/        # Deployment procedures and guides
├── reference/         # Technical reference and API
├── troubleshooting/   # Common issues and solutions
└── README.md          # This file
```

## 🚀 Getting Started

### Quick Start Guide

1. **Clone the repository** (with submodules):
   ```bash
   git clone --recurse-submodules https://github.com/franck01081991/nixos-fabric.git
   cd nixos-fabric
   ```

2. **Validate the configuration**:
   ```bash
   nix flake check
   ```

3. **Build a configuration**:
   ```bash
   nix build .#nixosConfigurations.rtr-sapinet.config.system.build.toplevel
   ```

4. **Deploy to a machine**:
   ```bash
   sudo nixos-rebuild switch --flake .#rtr-sapinet
   ```

## 📖 Documentation Guide

### For New Users

Start with these documents:

1. **[Architecture Overview](architecture/OVERVIEW.md)** - Understand the system design
2. **[Quick Start Guide](architecture/QUICKSTART.md)** - Get up and running quickly
3. **[Role System](reference/ROLES.md)** - Learn about spine/leaf roles
4. **[Development Workflow](development/WORKFLOW.md)** - Understand how to work with the codebase

### For Developers

Development-specific documentation:

1. **[Development Environment](development/ENVIRONMENT.md)** - Set up your dev environment
2. **[Synchronization Strategy](development/SYNC_STRATEGY.md)** - Understand the bidirectional sync system
3. **[Adding New Nodes](development/ADDING_NODES.md)** - Add new hosts to the fabric
4. **[Testing Guide](development/TESTING.md)** - Run and write tests

### For Operators

Deployment and operations:

1. **[Deployment Guide](deployment/DEPLOYMENT.md)** - Deploy the fabric
2. **[Upgrade Process](deployment/UPGRADE.md)** - Upgrade existing deployments
3. **[Monitoring](deployment/MONITORING.md)** - Monitor the fabric
4. **[Backup and Restore](deployment/BACKUP.md)** - Backup strategies

### Technical Reference

Detailed technical documentation:

1. **[Configuration Reference](reference/CONFIGURATION.md)** - All configuration options
2. **[Module Reference](reference/MODULES.md)** - Available NixOS modules
3. **[Role Reference](reference/ROLES.md)** - Spine and leaf roles
4. **[API Reference](reference/API.md)** - Programmatic interfaces

### Troubleshooting

Common issues and solutions:

1. **[Common Issues](troubleshooting/COMMON.md)** - Frequent problems
2. **[Debugging Guide](troubleshooting/DEBUGGING.md)** - Debugging techniques
3. **[Error Reference](troubleshooting/ERRORS.md)** - Error messages
4. **[FAQ](troubleshooting/FAQ.md)** - Frequently asked questions

## 📦 Project Structure

```
nixos-fabric/
├── docs/                  # Documentation (you are here)
├── external/              # External submodules
│   ├── rtr-sapinet-config/
│   └── rtr-noisy-config/
├── hosts/                 # Host configurations
│   ├── rtr-sapinet/
│   └── rtr-noisy/
├── modules/               # NixOS modules
│   ├── roles/
│   │   ├── spine.nix
│   │   └── leaf.nix
│   ├── frr.nix
│   ├── networking.nix
│   └── ...
├── scripts/               # Automation scripts
│   ├── deploy-and-verify.sh
│   ├── setup-submodules.sh
│   └── sync-bidirectional.sh
├── .github/               # GitHub configuration
│   └── workflows/
│       └── main.yml       # CI/CD pipeline
├── flake.nix              # Nix flake configuration
└── README.md              # Project README
```

## 🤝 Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on how to contribute to this project.

## 📞 Support

For questions and support:
- Open an issue on GitHub
- Check the [FAQ](troubleshooting/FAQ.md)
- Review the [troubleshooting guides](troubleshooting/)

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.