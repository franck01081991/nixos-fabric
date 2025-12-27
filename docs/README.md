# NixOS Fabric Documentation

Welcome to the NixOS Fabric documentation! This repository provides comprehensive security and networking configuration for NixOS deployments.

## 📚 Documentation Structure

### Getting Started
- [Installation Guide](getting-started/INSTALLATION.md)
- [Quick Start](getting-started/QUICKSTART.md)
- [Step-by-Step Tutorial](getting-started/TUTORIAL.md)

### Architecture
- [Overview](architecture/OVERVIEW.md)
- [Components](architecture/COMPONENTS.md)

### Modules
- **Security Module**: Comprehensive security configuration
  - [README](modules/security/README.md)
  - [Quick Start](modules/security/QUICKSTART.md)
  - [Examples](modules/security/EXAMPLES.md)
- **Ansible Integration**: NixOS and Ansible integration
  - [README](modules/ansible/README.md)
  - [Examples](modules/ansible/EXAMPLES.md)

### Development
- [Contributing Guide](development/CONTRIBUTING.md)
- [Coding Conventions](development/CONVENTIONS.md)
- [Testing Guide](development/TESTING.md)

### Deployment
- [Deployment Guide](deployment/DEPLOYMENT.md)
- [Production Setup](deployment/PRODUCTION.md)

### Reference
- [Module Options API](reference/API.md)
- [Roles Reference](reference/ROLES.md)
- [Repository Structure](reference/STRUCTURE.md)

### Troubleshooting
- [FAQ](troubleshooting/FAQ.md)
- [Debugging Guide](troubleshooting/DEBUGGING.md)

### Historical
- [Changes and Migration](historical/CHANGES.md)
- [Release Notes](historical/RELEASE_NOTES.md)

## 🚀 Quick Links

- **Main Repository**: [README.md](../README.md)
- **Security Module**: [modules/security/README.md](modules/security/README.md)
- **Ansible Integration**: [modules/ansible/README.md](modules/ansible/README.md)
- **Contributing**: [development/CONTRIBUTING.md](development/CONTRIBUTING.md)

## 📖 Documentation Standards

This documentation follows these principles:
- **Clear and Concise**: Easy to understand
- **Example-Driven**: Practical examples included
- **Up-to-Date**: Reflects current implementation
- **Well-Organized**: Logical structure

## 🔍 Search Documentation

Use `grep` to search documentation:
```bash
grep -r "search term" docs/
```

Or use `find` to locate files:
```bash
find docs/ -name "*.md" | grep -i "keyword"
```

## 🤝 Contribute to Documentation

See [Contributing Guide](development/CONTRIBUTING.md) for how to improve documentation.

---

*Last updated: $(date +%Y-%m-%d)*
*Documentation version: 1.0*
