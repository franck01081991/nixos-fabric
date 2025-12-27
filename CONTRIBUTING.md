# Contributing to NixOS Fabric

Thank you for your interest in contributing to NixOS Fabric! This guide will help you get started with contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Running Tests](#running-tests)
- [Submitting Changes](#submitting-changes)
- [Code Review](#code-review)
- [Documentation](#documentation)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Community](#community)

## Getting Started

Before you start contributing, please:

1. Read the [README.md](README.md) to understand the project structure and goals.
2. Read the [CONVENTIONS.md](CONVENTIONS.md) to understand the coding conventions and best practices.
3. Read the [STRUCTURE.md](STRUCTURE.md) to understand the project structure and organization.

## Development Setup

### Prerequisites

- NixOS or Nix package manager installed
- Git
- Basic knowledge of Nix and Ansible

### Setting Up the Development Environment

1. Clone the repository:

```bash
git clone https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric
```

2. Initialize the submodules:

```bash
git submodule update --init --recursive
```

3. Install the required dependencies:

```bash
nix-shell
```

## Making Changes

### Branching Strategy

We use the following branching strategy:

- `master`: The main branch with stable code.
- `feature/*`: Feature branches for new features.
- `bugfix/*`: Bugfix branches for bug fixes.
- `hotfix/*`: Hotfix branches for critical bug fixes.

### Creating a Feature Branch

1. Create a new feature branch:

```bash
git checkout -b feature/your-feature-name
```

2. Make your changes and commit them:

```bash
git add .
git commit -m "feat: Add your feature description"
```

3. Push the branch to GitHub:

```bash
git push origin feature/your-feature-name
```

## Running Tests

### Running All Tests

To run all tests, use the following command:

```bash
./tests/run-tests.sh
```

### Running Quick Tests

To run only the quick tests, use the following command:

```bash
./tests/run-tests.sh --quick
```

### Running Tests with Verbose Output

To run tests with verbose output, use the following command:

```bash
./tests/run-tests.sh --verbose
```

### Running Specific Tests

To run specific tests, you can use the `nix-instantiate` command:

```bash
nix-instantiate --eval -E "import ./tests/your-test-file.nix"
```

## Submitting Changes

### Creating a Pull Request

1. Push your feature branch to GitHub:

```bash
git push origin feature/your-feature-name
```

2. Create a pull request from your feature branch to the `master` branch.

3. Fill in the pull request template with a clear description of your changes.

### Pull Request Template

```markdown
## Description

Please include a summary of the changes and the related issue. Please also include relevant motivation and context.

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Checklist

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published in downstream modules
```

## Code Review

### Review Process

1. Once you submit a pull request, it will be reviewed by the project maintainers.
2. The reviewers will provide feedback and may request changes.
3. Once the pull request is approved, it will be merged into the `master` branch.

### Review Guidelines

- Be respectful and constructive in your feedback.
- Provide clear and actionable feedback.
- Be open to feedback and willing to make changes.

## Documentation

### Updating Documentation

Please update the documentation to reflect your changes. This includes:

- Updating the README.md file.
- Updating the relevant module documentation.
- Adding examples and guides for new features.

### Documentation Structure

The documentation is organized as follows:

- `README.md`: The main README file with an overview of the project.
- `STRUCTURE.md`: The project structure and organization.
- `CONVENTIONS.md`: The coding conventions and best practices.
- `CONTRIBUTING.md`: The contributing guide.
- `docs/`: Additional documentation and guides.

## Examples

### Example: Adding a New Ansible Role

To add a new Ansible role, follow these steps:

1. Create a new role directory:

```bash
mkdir -p ansible/roles/your_role/{tasks,handlers,templates,vars,defaults,meta}
```

2. Add role metadata in `ansible/roles/your_role/meta/main.yml`:

```yaml
galaxy_info:
  author: Your Name
  description: Your role description
  company: Your Company
  license: MIT
  min_ansible_version: 2.15
  platforms:
    - name: NixOS
      versions:
        - all
  galaxy_tags:
    - your
    - tags
    - here

dependencies: []
```

3. Create tasks in `ansible/roles/your_role/tasks/main.yml`:

```yaml
---
- name: Example task
  ansible.builtin.debug:
    msg: "Hello, world!"
```

4. Add the role to your playbook:

```yaml
- name: Example playbook
  hosts: all
  roles:
    - your_role
```

### Example: Adding a New Test

To add a new test, follow these steps:

1. Create a new test file in the `tests/` directory with the `.nix` extension:

```nix
{ pkgs, ... }:

let
  # Import the module to test
  config = import ./path/to/module.nix {
    variable1 = "value1";
    variable2 = "value2";
  };
in
{
  config = config;
  isValid = config.someAttribute != null;
}
```

2. Add the test to the `tests/run-tests.sh` script:

```bash
run_test "your-test-name" "tests/your-test-file.nix" "Your test description"
total_tests=$((total_tests + 1))
[ $? -eq 0 ] && passed_tests=$((passed_tests + 1)) || failed_tests=$((failed_tests + 1))
```

## Best Practices

### Coding Best Practices

- Follow the coding conventions defined in `CONVENTIONS.md`.
- Write clear and concise code.
- Comment your code, particularly in hard-to-understand areas.
- Write tests for your code.
- Keep your changes small and focused.

### Testing Best Practices

- Write tests for all new features and bug fixes.
- Ensure that your tests cover all edge cases.
- Run the tests locally before submitting your changes.
- Ensure that all tests pass before submitting your changes.

### Documentation Best Practices

- Update the documentation to reflect your changes.
- Write clear and concise documentation.
- Provide examples and guides for new features.
- Keep the documentation up-to-date.

## Community

### Getting Help

If you need help, you can:

- Open an issue on GitHub.
- Ask a question on the project's discussion forum.
- Contact the project maintainers.

### Contributing to the Community

You can contribute to the community by:

- Reviewing pull requests.
- Answering questions on the discussion forum.
- Helping to improve the documentation.
- Sharing your knowledge and experience.

### Code of Conduct

Please read the [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for guidelines on how to interact with the community.

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

## Thank You

Thank you for contributing to NixOS Fabric! Your contributions are greatly appreciated.
