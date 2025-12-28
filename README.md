# NixOS Fabric - GitOps Edition

[![GitOps Pipeline](https://github.com/your-org/nixos-fabric/actions/workflows/gitops-pipeline.yml/badge.svg)](https://github.com/your-org/nixos-fabric/actions/workflows/gitops-pipeline.yml)

**Modern NixOS infrastructure with pure GitOps deployment model**

## 🚀 Quick Start

```bash
# Clone the repository
git clone git@github.com:your-org/nixos-fabric.git
cd nixos-fabric

# Explore the GitOps structure
ls -la gitops/

# Read the complete GitOps documentation
cat GITOPS_README.md
```

## 🎯 What is NixOS Fabric GitOps?

NixOS Fabric GitOps is a **pure GitOps deployment model** for NixOS infrastructure that combines:

- **Day-0 Bootstrap**: Initial deployment via CI/CD pipeline
- **Day-2 GitOps**: Machines automatically pull and apply updates from Git
- **Flake-based**: Modern Nix flakes for reproducible configurations
- **CI/CD Integration**: Comprehensive validation and testing pipeline

## 🔧 Features

### Day-0 Bootstrap
- ✅ Minimal initial configuration
- ✅ SSH access setup
- ✅ Basic system hardening
- ✅ Fabric directory structure
- ✅ CI/CD pipeline deployment

### Day-2 GitOps
- ✅ Automatic Git repository tracking
- ✅ Periodic update checks (every 15 minutes)
- ✅ Automatic `nixos-rebuild` on changes
- ✅ Systemd service and timer
- ✅ Comprehensive logging

### CI/CD Pipeline
- ✅ Full configuration validation
- ✅ Automatic artifact creation
- ✅ Deployment package generation
- ✅ Scheduled updates
- ✅ Pull request validation

## 📁 Project Structure

```
.
├── .github/                  # GitHub CI/CD workflows
│   └── workflows/            # GitOps pipeline
│       └── gitops-pipeline.yml
├── gitops/                   # GitOps configurations
│   ├── day-0/                # Day-0 Bootstrap
│   │   └── bootstrap-flake.nix
│   ├── day-2/                # Day-2 GitOps
│   │   ├── gitops-flake.nix
│   │   └── modules/          # GitOps modules
│   │       └── gitops.nix
│   └── README.md             # GitOps documentation
├── GITOPS_README.md          # Complete GitOps guide
├── README.md                 # This file
└── ...                       # Other project files
```

## 🛠️ Usage

### 1. Initial Setup

```bash
# Clone the repository
git clone git@github.com:your-org/nixos-fabric.git
cd nixos-fabric

# Customize configurations
vim gitops/day-0/bootstrap-flake.nix
vim gitops/day-2/gitops-flake.nix

# Commit and push
git add .
git commit -m "Initial GitOps setup"
git push origin master
```

### 2. Deploy Day-0

1. Wait for CI/CD pipeline to complete
2. Download the `nixos-fabric-complete-deployment` artifact
3. Run the deployment script:

```bash
./deploy.sh root@target-machine
```

### 3. Activate Day-2

```bash
./activate-gitops.sh root@target-machine
```

### 4. Monitor GitOps

```bash
# Check service status
ssh root@target-machine "systemctl status nixos-fabric-gitops"

# View logs
ssh root@target-machine "journalctl -u nixos-fabric-gitops -f"

# Check timer
ssh root@target-machine "systemctl list-timers | grep gitops"
```

### 5. Deploy to External Machines

```bash
# After CI/CD pipeline completes, download the deployment package
# Then deploy to individual machines:

# Deploy to rtr-noisy
./deploy-rtr-noisy.sh root@rtr-noisy

# Deploy to rtr-sapinet
./deploy-rtr-sapinet.sh root@rtr-sapinet

# Or deploy to all external machines at once
./deploy-all-external.sh
```

### 6. Monitor External Machines

```bash
# Check external machines GitOps status
ssh root@rtr-noisy "systemctl status nixos-fabric-gitops-external"
ssh root@rtr-sapinet "systemctl status nixos-fabric-gitops-external"

# View external machines logs
ssh root@rtr-noisy "journalctl -u nixos-fabric-gitops-external -f"
ssh root@rtr-sapinet "journalctl -u nixos-fabric-gitops-external -f"
```

## 🔄 Development Workflow

### Making Changes

```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes to configurations
vim gitops/day-2/gitops-flake.nix

# Test locally
nix build ./gitops/day-2#gitops

# Commit changes
git add .
git commit -m "Add new feature"
git push origin feature/new-feature
```

### Pull Request Process

1. Create pull request to `master`
2. CI/CD pipeline validates changes
3. Review and approve
4. Merge to `master`
5. Machines automatically pull updates

## 🌐 External Machines Integration

The GitOps model integrates with existing external machine configurations:

- **rtr-noisy**: Hybrid router configuration
- **rtr-sapinet**: Spine router configuration

### External Machines Configuration

```nix
# gitops/external
{
  description = "NixOS Fabric - External Machines GitOps Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations = {
        # Individual machine configurations
        rtr-noisy-gitops = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              imports = [
                ./external-integration.nix
                ../external/rtr-noisy-config/default.nix
                ../hosts/default-ansible.nix
                ./modules/gitops.nix
              ];
              
              # Machine-specific GitOps settings
              network-fabric.gitops.machines."rtr-noisy".enable = true;
              networking.hostName = "rtr-noisy";
            })
          ];
        };

        # Combined configuration for all external machines
        external-gitops = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              imports = [
                ./external-integration.nix
                ./modules/gitops.nix
              ];
              
              network-fabric.gitops = {
                enable = true;
                machines = {
                  "rtr-noisy" = {
                    enable = true;
                    configPath = "external/rtr-noisy-config/default.nix";
                  };
                  "rtr-sapinet" = {
                    enable = true;
                    configPath = "external/rtr-sapinet-config/default.nix";
                  };
                };
              };
            })
          ];
        };
      };
    };
}
```

## 📊 Configuration Examples

### Basic Bootstrap

```nix
# gitops/day-0/bootstrap-flake.nix
{
  description = "NixOS Fabric - Day-0 Bootstrap Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations = {
        bootstrap = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              # Your bootstrap configuration here
              networking.hostName = "nixos-fabric";
              services.openssh.enable = true;
            })
          ];
        };
      };
    };
}
```

### GitOps Configuration

```nix
# gitops/day-2/gitops-flake.nix
{
  description = "NixOS Fabric - Day-2 GitOps Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations = {
        gitops = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              imports = [ ./modules/gitops.nix ];

              network-fabric.gitops = {
                enable = true;
                repository = "git@github.com:your-org/nixos-fabric.git";
                branch = "master";
                interval = "15m";
              };
            })
          ];
        };
      };
    };
}
```

## 🛡️ Security

### Bootstrap Phase
- Temporary SSH access with root login
- Minimal attack surface
- Basic security hardening

### GitOps Phase
- Read-only Git access via deploy keys
- Automatic security updates
- Comprehensive logging
- Service isolation

### Best Practices
- Rotate deploy keys regularly
- Monitor SSH access logs
- Audit all configuration changes
- Backup configurations before major updates

## 📚 Documentation

- **[Complete GitOps Guide](GITOPS_README.md)** - Detailed GitOps implementation
- **[CI/CD Pipeline](.github/workflows/gitops-pipeline.yml)** - GitOps pipeline definition
- **[Day-0 Bootstrap](gitops/day-0/bootstrap-flake.nix)** - Initial deployment configuration
- **[Day-2 GitOps](gitops/day-2/gitops-flake.nix)** - Continuous deployment configuration

## 🤝 Contributing

### How to Contribute

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request
6. Wait for CI/CD validation
7. Get reviewed and merged

### Testing

```bash
# Test bootstrap configuration
nix build ./gitops/day-0#bootstrap

# Test GitOps configuration
nix build ./gitops/day-2#gitops

# Validate flakes
nix flake check ./gitops/day-0
nix flake check ./gitops/day-2
nix flake check ./gitops/external

# Test external machines configurations
nix build ./gitops/external#rtr-noisy-gitops
nix build ./gitops/external#rtr-sapinet-gitops
nix build ./gitops/external#external-gitops
```

### Code Style

- Follow NixOS best practices
- Use flakes for all configurations
- Document all modules and options
- Keep configurations modular and reusable

## 🔒 Private Submodules

**Important Security Note**: The external machine configurations (`external/rtr-sapinet-config` and `external/rtr-noisy-config`) are stored in **private GitHub repositories** as submodules. This ensures that sensitive configuration details are not exposed in the public repository.

### Setup Required

1. **Create private repositories** on GitHub for the external configurations
2. **Configure SSH access** using deploy keys
3. **Set up CI/CD secrets** with the SSH private key
4. **Initialize submodules** after cloning the main repository

See [GITOPS_README.md](GITOPS_README.md) for detailed setup instructions.

**Complete Setup Guide**: [PRIVATE_SUBMODULES_SETUP.md](PRIVATE_SUBMODULES_SETUP.md)

## 📝 License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- NixOS community for the excellent infrastructure
- GitOps community for deployment best practices
- All contributors who make this project possible

---

**NixOS Fabric GitOps** - Modern infrastructure deployment with NixOS and GitOps principles.

📧 **Contact**: contact@your-org.com
🌐 **Website**: https://your-org.com/nixos-fabric
🐦 **Twitter**: @yourorg
💼 **Organization**: Your Organization