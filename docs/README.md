# NixOS Fabric Documentation

## Welcome to the NixOS Fabric Documentation

This directory contains comprehensive documentation for the NixOS Fabric project, organized by topic for easy navigation.

## Documentation Structure

```
docs/
├── ansible/                  # Ansible role documentation
├── architecture/             # Architecture documentation
├── deployment/               # Deployment guides
├── development/              # Development documentation
├── getting-started/          # Getting started guides
├── historical/               # Historical documentation
├── modules/                  # Module-specific documentation
├── new_structure/            # New structure proposals
├── pull_requests/           # Pull request templates
├── reference/               # Reference documentation
├── reorganization/          # Reorganization documentation
├── roles/                    # Role documentation
├── security/                 # Security documentation
├── troubleshooting/          # Troubleshooting guides
└── README.md                 # This file
```

## Quick Start

If you're new to NixOS Fabric, start with:

1. **[Getting Started Guide](getting-started/quickstart.md)** - Basic setup and configuration
2. **[Installation Guide](getting-started/installation.md)** - Installation instructions
3. **[Tutorial](getting-started/tutorial.md)** - Step-by-step tutorial

## Architecture

Understand the project architecture:

- **[Architecture Overview](architecture/overview.md)** - High-level architecture
- **[Detailed Architecture](architecture/ARCHITECTURE.md)** - Comprehensive architecture

## Modules

Module-specific documentation:

### Security Module
- **[README](modules/security/README.md)** - Comprehensive security documentation
- **[Quick Start](modules/security/quickstart.md)** - Quick start guide
- **[Examples](modules/security/examples.md)** - Configuration examples

### Networking Modules
- Documentation coming soon (see `modules/networking/` for implementations)

### Ansible Roles
- **[Base Role](ansible/role-base.md)** - Base Ansible role
- **[Common Role](ansible/role-common.md)** - Common configuration
- **[WireGuard Role](ansible/role-wireguard.md)** - WireGuard VPN role

## Deployment

Deployment guides and information:

- **[Deployment Guide](deployment/DEPLOYMENT.md)** - Deployment overview
- **[Ansible Integration](development/ANSIBLE_INTEGRATION.md)** - Ansible integration guide

## Development

For developers and contributors:

- **[Contributing Guide](development/contributing.md)** - How to contribute
- **[Conventions](development/conventions.md)** - Coding conventions
- **[Sync Strategy](development/SYNC_STRATEGY.md)** - Synchronization strategy
- **[Testing Summary](development/TESTING_SUMMARY.md)** - Testing overview

## Reference

Reference documentation:

- **[API Reference](reference/API.md)** - API documentation
- **[Structure Reference](reference/STRUCTURE.md)** - Repository structure

## Reorganization

Documentation about the repository reorganization:

- **[Reorganization Summary](reorganization/REORGANIZATION_SUMMARY.md)** - Summary of changes
- **[New Structure Plan](reorganization/NEW_STRUCTURE_PLAN.md)** - Reorganization plan
- **[Complete Documentation](reorganization/REORGANIZATION_COMPLETE.md)** - Complete details
- **[Root Cleanup](reorganization/ROOT_CLEANUP_SUMMARY.md)** - Root directory cleanup
- **[CI/CD Verification](reorganization/CI_CD_VERIFICATION.md)** - CI/CD compatibility
- **[Verification Checklist](reorganization/VERIFICATION_CHECKLIST.md)** - Verification checklist

## Historical

Historical documentation:

- **[Changes](historical/CHANGES.md)** - Change history
- **[Conflict Resolution](historical/CONFLICT_RESOLUTION_PLAN.md)** - Conflict resolution plan
- **[Deployment Testing](historical/DEPLOYMENT_TESTING_SUMMARY.md)** - Deployment testing summary
- **[Pipeline Improvements](historical/PIPELINE_IMPROVEMENTS.md)** - CI/CD pipeline improvements
- **[Release Notes](historical/RELEASE_NOTES.md)** - Release notes
- **[Security Module Fix](historical/SECURITY_MODULE_FIX_SUMMARY.md)** - Security module fixes

## Troubleshooting

Help and troubleshooting:

- **[FAQ](troubleshooting/faq.md)** - Frequently asked questions
- **[Debugging](troubleshooting/debugging.md)** - Debugging guide

## Pull Requests

Templates for pull requests:

- **[Pull Request Template](pull_requests/PULL_REQUEST_TEMPLATE.md)** - Standard PR template
- **[Pull Request Submission](pull_requests/PULL_REQUEST_SUBMISSION.md)** - PR submission guide

## How to Use This Documentation

### For Users

1. Start with the **[Getting Started Guide](getting-started/quickstart.md)**
2. Follow the **[Tutorial](getting-started/tutorial.md)**
3. Check the **[Examples](modules/security/examples.md)**
4. Refer to the **[API Reference](reference/API.md)**

### For Developers

1. Read the **[Contributing Guide](development/contributing.md)**
2. Follow the **[Conventions](development/conventions.md)**
3. Check the **[Structure Reference](reference/STRUCTURE.md)**
4. Use the **[Pull Request Template](pull_requests/PULL_REQUEST_TEMPLATE.md)**

### For Maintainers

1. Review the **[Reorganization Summary](reorganization/REORGANIZATION_SUMMARY.md)**
2. Check the **[Verification Checklist](reorganization/VERIFICATION_CHECKLIST.md)**
3. Monitor the **[CI/CD Verification](reorganization/CI_CD_VERIFICATION.md)**

## Documentation Standards

All documentation follows these standards:

- **Clear structure** with logical organization
- **Comprehensive coverage** of all features
- **Practical examples** for real-world use
- **Consistent formatting** for readability
- **Regular updates** to stay current

## Contributing to Documentation

To contribute to the documentation:

1. Fork the repository
2. Make your changes
3. Follow the **[Conventions](development/conventions.md)**
4. Test your changes
5. Submit a pull request using the **[Pull Request Template](pull_requests/PULL_REQUEST_TEMPLATE.md)**

## Support

For documentation issues:
- Open a GitHub issue
- Check the **[FAQ](troubleshooting/faq.md)**
- Review the **[Debugging Guide](troubleshooting/debugging.md)**

---

**Last Updated**: 2024-07-25
**Version**: 2.0 (Reorganized)
**Maintainer**: Franck
**License**: MIT