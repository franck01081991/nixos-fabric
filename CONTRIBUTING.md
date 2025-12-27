# Contributing to NixOS Fabric

First off, thank you for considering contributing to NixOS Fabric! We welcome contributions from everyone, whether you're fixing bugs, improving documentation, or adding new features.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Setup](#development-setup)
3. [Making Changes](#making-changes)
4. [Code Style](#code-style)
5. [Commit Guidelines](#commit-guidelines)
6. [Pull Request Process](#pull-request-process)
7. [Testing](#testing)
8. [Documentation](#documentation)
9. [Issue Reporting](#issue-reporting)
10. [Community](#community)

## Getting Started

### Prerequisites

- Basic knowledge of Nix and NixOS
- Familiarity with Git and GitHub
- Understanding of network security concepts (for security modules)
- Nix installed on your system

### Repository Structure

Please familiarize yourself with our repository structure by reading:
- [`STRUCTURE.md`](STRUCTURE.md) - Overall repository organization
- [`CONVENTIONS.md`](CONVENTIONS.md) - Naming and coding conventions
- [`modules/security/README.md`](modules/security/README.md) - Security module documentation

## Development Setup

### Clone the Repository

```bash
git clone https://github.com/your-repo/nixos-fabric.git
cd nixos-fabric
```

### Set Up Development Environment

```bash
# Enter a Nix shell with development tools
nix-shell

# Or use direenv (recommended)
echo "use nix" > .envrc
direnv allow
```

### Build and Test

```bash
# Test the security module
nix-instantiate --eval -E 'import ./modules/security/init.nix'

# Run the organized test suite
tests/run-organized-tests.sh

# Test example configuration
nix-instantiate --eval -E 'import ./examples/security-example.nix'
```

## Making Changes

### Branch Strategy

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Create a bugfix branch
git checkout -b bugfix/issue-description

# Create a documentation branch
git checkout -b docs/update-section
```

### Development Workflow

1. **Create a branch** for your changes
2. **Make small, focused changes** - one feature/bug per branch
3. **Test your changes** thoroughly
4. **Update documentation** if needed
5. **Run the test suite** to ensure nothing breaks
6. **Commit your changes** following our guidelines
7. **Push to GitHub** and open a pull request

## Code Style

Please follow our coding conventions outlined in [`CONVENTIONS.md`](CONVENTIONS.md). Key points:

- **Consistent indentation** (2 spaces)
- **Descriptive naming** for variables and functions
- **Comprehensive comments** for complex logic
- **Logical organization** of code sections
- **Clear documentation** for new features

### Example of Good Code

```nix
# ============================================
# SSH Configuration Section
# ============================================
# Configure OpenSSH with security-hardened settings
# including custom ports, authentication restrictions,
# and connection limits.
# ============================================

services.openssh = mkIf cfg.ssh.enable {
  enable = true;
  
  settings = {
    Port = toString cfg.ssh.port;  # Custom SSH port for security
    PermitRootLogin = mkForce cfg.ssh.permitRootLogin;  # Disable root login
    PasswordAuthentication = mkForce cfg.ssh.passwordAuthentication;  # Keys only
    ChallengeResponseAuthentication = false;
    UsePAM = true;
    AllowUsers = cfg.ssh.allowUsers;
    AllowGroups = cfg.ssh.allowGroups;
    MaxAuthTries = toString cfg.ssh.maxAuthTries;
    LoginGraceTime = "${toString cfg.ssh.loginGraceTime}s";
    Banner = cfg.ssh.banner;
  };
};
```

## Commit Guidelines

### Commit Message Format

```bash
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to the build process or auxiliary tools and libraries

### Scopes

- **security**: Security module changes
- **networking**: Networking module changes
- **wireguard**: WireGuard module changes
- **frr**: FRR routing module changes
- **ansible**: Ansible integration changes
- **docs**: Documentation changes
- **tests**: Test suite changes
- **examples**: Example configuration changes
- **structure**: Repository structure changes

### Examples

```bash
# Good commit messages
feat(security): add AppArmor profile support
fix(networking): correct firewall rule generation
docs: update security module README
refactor(security): improve module organization
test(security): add comprehensive test suite
chore: update CI/CD pipeline configuration

# Bad commit messages (avoid these)
fix stuff
update security module
wip
fix bug
add feature
```

### Commit Body

- Explain **what** was changed and **why**
- Include **before/after** examples if helpful
- Reference related issues or pull requests
- Keep lines under 72 characters

### Commit Footer

- Reference issues: `Fixes #123`, `Closes #456`, `Related to #789`
- Breaking changes: `BREAKING CHANGE: ...`
- Reviewed by: `Reviewed-by: @contributor`

## Pull Request Process

### Before Submitting

1. **Rebase your branch** on the latest `master`
2. **Run the test suite** to ensure everything works
3. **Check your code** against our conventions
4. **Update documentation** if your changes affect usage
5. **Write clear commit messages** following our guidelines

### Submitting

1. **Push your branch** to GitHub
2. **Open a Pull Request** with a clear title and description
3. **Include** in the description:
   - What problem you're solving
   - How your solution works
   - Any breaking changes
   - Screenshots if applicable
   - Related issues

### Review Process

1. **Automated checks** will run (CI/CD pipeline)
2. **Maintainers will review** your code
3. **Address feedback** and make requested changes
4. **Once approved**, your PR will be merged

### After Merge

- Your changes will be included in the next release
- Documentation will be updated automatically
- You'll be credited in the contributors list

## Testing

### Test Requirements

All contributions must:
1. **Pass existing tests** - Don't break current functionality
2. **Include new tests** - Cover your new features or bug fixes
3. **Follow test conventions** - Use our organized test structure

### Running Tests

```bash
# Run all organized tests
tests/run-organized-tests.sh

# Test specific module
nix-instantiate --eval -E 'import ./modules/security/init.nix'

# Test example configuration
nix-instantiate --eval -E 'import ./examples/security-example.nix'

# Test in a VM
nixos-rebuild build-vm -I nixos-config=./your-config.nix
```

### Writing Tests

Follow our test organization structure:

```bash
tests/
├── modules/              # Module-specific tests
│   ├── security/         # Security module tests
│   │   ├── init.nix      # Test entry point
│   │   └── default.nix   # Main test suite
│   └── ...               # Other module tests
└── ...                   # Integration tests
```

## Documentation

### Documentation Requirements

All new features must include:
1. **Code comments** explaining the implementation
2. **README updates** if the feature is user-facing
3. **Example configurations** showing usage
4. **API documentation** for new options

### Documentation Standards

Follow our documentation standards from [`CONVENTIONS.md`](CONVENTIONS.md):

- **Complete examples** with all necessary context
- **Clear explanations** of what each option does
- **Usage patterns** for common scenarios
- **Troubleshooting** information

### Documentation Tools

```bash
# Validate markdown
npx markdownlint **/*.md

# Check for broken links
npx markdowntoc --check **/*.md

# Preview documentation
npx grip README.md
```

## Issue Reporting

### Before Reporting

1. **Search existing issues** to avoid duplicates
2. **Check our documentation** for solutions
3. **Test with the latest version** to ensure it's not fixed

### Good Issue Reports

Include:
- **Clear title** describing the problem
- **Detailed description** of what's happening
- **Steps to reproduce** the issue
- **Expected behavior** vs **actual behavior**
- **Environment details** (NixOS version, hardware, etc.)
- **Relevant configuration** (redact sensitive info)
- **Error messages** or logs

### Issue Template

```markdown
## Description

Clear description of the issue.

## Steps to Reproduce

1. Step one
2. Step two
3. Step three

## Expected Behavior

What should happen.

## Actual Behavior

What actually happens.

## Environment

- NixOS Version: 
- Hardware: 
- Configuration: 

## Additional Information

Any other relevant information, logs, or screenshots.
```

## Community

### Ways to Contribute

- **Code**: Fix bugs, add features, improve performance
- **Documentation**: Improve docs, add examples, write tutorials
- **Tests**: Add test coverage, improve test quality
- **Issues**: Report bugs, suggest features, help triage
- **Reviews**: Review pull requests, provide feedback
- **Discussions**: Participate in discussions, share ideas

### Communication

- **GitHub Issues**: For bug reports and feature requests
- **Pull Requests**: For code contributions
- **Discussions**: For general questions and ideas

### Code of Conduct

Please follow our [Code of Conduct](CODE_OF_CONDUCT.md) in all interactions.

## Getting Help

### Resources

- **Documentation**: Start with our comprehensive docs
- **Examples**: Check the `examples/` directory
- **Tests**: Review test configurations for usage patterns
- **Structure**: See `STRUCTURE.md` for organization
- **Conventions**: Follow `CONVENTIONS.md` for style

### Asking for Help

1. **Check existing issues** for similar problems
2. **Review documentation** thoroughly
3. **Search discussions** for answers
4. **Open a new issue** if you can't find a solution

## Development Tips

### Working with Security Module

```bash
# Test security module changes
nix-instantiate --eval -E 'import ./modules/security/init.nix'

# Test with different configurations
nix-instantiate --eval -E '
  let
    config = {
      network-fabric.security = {
        enable = true;
        ssh.port = 2222;
      };
    };
  in import ./modules/security/init.nix { inherit config; }'
```

### Debugging

```bash
# Verbose evaluation
nix-instantiate --eval --show-trace -E 'import ./your-file.nix'

# Check for undefined variables
nix-instantiate --eval --strict -E 'import ./your-file.nix'

# Interactive environment
nix repl
> :l <nixpkgs>
> import ./modules/security/init.nix
```

### Performance

```bash
# Build with timing
time nix-build -E 'import ./your-config.nix'

# Check evaluation time
nix-instantiate --eval -E 'import ./your-config.nix' --time

# Optimize imports
# Use lazy evaluation where possible
# Avoid unnecessary computations
```

## Release Process

### Versioning

We follow **Semantic Versioning** (SemVer):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

- [ ] All tests pass
- [ ] Documentation is up to date
- [ ] Changelog is updated
- [ ] Breaking changes are documented
- [ ] Examples are tested
- [ ] CI/CD pipeline passes

## Maintainers

### Responsibilities

- Review pull requests
- Merge approved changes
- Manage releases
- Maintain roadmap
- Ensure code quality
- Handle security issues

### Becoming a Maintainer

If you're interested in becoming a maintainer:
1. **Contribute regularly** to the project
2. **Demonstrate expertise** in Nix and security
3. **Help others** in the community
4. **Show commitment** to the project's goals
5. **Contact existing maintainers** to discuss

## License

By contributing to NixOS Fabric, you agree that your contributions will be licensed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

## Acknowledgments

Thank you for contributing to NixOS Fabric! Your contributions help make this project better for everyone. We appreciate your time, effort, and expertise.

**Happy coding!** 🚀