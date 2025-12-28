# Private Submodules Setup Guide

This guide explains how to set up the private submodules for NixOS Fabric GitOps.

## 🎯 Overview

The NixOS Fabric GitOps model uses **private GitHub repositories** for external machine configurations to ensure security and separation of concerns.

### Architecture

```
Public Repository (nixos-fabric)
├── .gitmodules → git@github.com:your-org/rtr-sapinet-config.git (PRIVATE)
├── .gitmodules → git@github.com:your-org/rtr-noisy-config.git (PRIVATE)
├── gitops/
│   ├── external-gitops-flake.nix
│   └── external-integration.nix
└── .github/workflows/gitops-pipeline.yml
```

## 🔧 Setup Instructions

### Step 1: Create Private Repositories

1. **On GitHub**, create two new private repositories:
   - `rtr-sapinet-config`
   - `rtr-noisy-config`

2. **Set visibility to Private**:
   - Go to each repository settings
   - Under "Danger Zone", set visibility to "Private"
   - Confirm the change

### Step 2: Populate Private Repositories

```bash
# Clone the private repositories locally
git clone git@github.com:your-org/rtr-sapinet-config.git
git clone git@github.com:your-org/rtr-noisy-config.git

# Copy existing configurations from the main repository
cp -r external/rtr-sapinet-config/* rtr-sapinet-config/
cp -r external/rtr-noisy-config/* rtr-noisy-config/

# Commit and push to private repositories
cd rtr-sapinet-config
git add .
git commit -m "Initial private configuration"
git push origin master

cd ../rtr-noisy-config
git add .
git commit -m "Initial private configuration"
git push origin master
```

### Step 3: Configure Submodules in Main Repository

```bash
# Remove existing external directories (if any)
rm -rf external/rtr-sapinet-config
git rm -r external/rtr-sapinet-config

rm -rf external/rtr-noisy-config
git rm -r external/rtr-noisy-config

# Add submodules using SSH URLs
git submodule add git@github.com:your-org/rtr-sapinet-config.git external/rtr-sapinet-config
git submodule add git@github.com:your-org/rtr-noisy-config.git external/rtr-noisy-config

# Update .gitmodules to use SSH
git submodule sync

# Commit the changes
git add .gitmodules external/
git commit -m "Add private submodules for external configurations"
git push origin master
```

### Step 4: Generate SSH Deploy Key

```bash
# Generate a new SSH key pair for CI/CD
ssh-keygen -t ed25519 -C "nixos-fabric-ci-cd" -f nixos-fabric-ci-key

# This creates two files:
# - nixos-fabric-ci-key (private key)
# - nixos-fabric-ci-key.pub (public key)
```

### Step 5: Add Public Key to Private Repositories

1. **Copy the public key**:
   ```bash
   cat nixos-fabric-ci-key.pub | pbcopy  # Mac
   cat nixos-fabric-ci-key.pub | xclip -selection clipboard  # Linux
   ```

2. **On GitHub for each private repository**:
   - Go to "Settings" > "Deploy keys"
   - Click "Add deploy key"
   - Paste the public key
   - Title: "CI/CD Deploy Key"
   - Check "Allow write access" (optional, read-only is sufficient)
   - Click "Add key"

### Step 6: Add Private Key to CI/CD Secrets

1. **Copy the private key**:
   ```bash
   cat nixos-fabric-ci-key
   ```

2. **On GitHub for the main repository**:
   - Go to "Settings" > "Secrets" > "Actions"
   - Click "New repository secret"
   - Name: `SSH_DEPLOY_KEY`
   - Paste the private key content
   - Click "Add secret"

### Step 7: Configure Known Hosts

The CI/CD pipeline automatically sets up known hosts, but you can verify:

```bash
ssh-keyscan github.com
```

### Step 8: Test the Configuration

```bash
# Clone the main repository with submodules
git clone --recurse-submodules git@github.com:your-org/nixos-fabric.git
cd nixos-fabric

# Verify submodules are private
git submodule status

# Test building external configurations
nix build ./gitops/external-gitops-flake.nix#rtr-noisy-gitops
nix build ./gitops/external-gitops-flake.nix#rtr-sapinet-gitops
```

## 🔐 Security Best Practices

### Access Control

1. **Principle of Least Privilege**:
   - Deploy keys should be read-only
   - Only necessary collaborators should have access
   - Use SSH instead of HTTPS for submodules

2. **Key Rotation**:
   - Rotate deploy keys every 90 days
   - Remove old keys from deploy keys list
   - Update CI/CD secrets when rotating

### Monitoring

1. **Audit Logs**:
   - Monitor GitHub audit logs for repository access
   - Set up alerts for unusual activity
   - Review deploy key usage regularly

2. **CI/CD Security**:
   - Restrict CI/CD workflow permissions
   - Use environment-specific secrets
   - Monitor workflow runs for failures

### Repository Management

1. **Branch Protection**:
   ```bash
   # Enable branch protection on all repositories
   # Required status checks
   # Require pull request reviews
   # Restrict who can push to master
   ```

2. **Secret Scanning**:
   - Enable GitHub secret scanning
   - Review alerts regularly
   - Rotate any exposed secrets immediately

## 🚀 CI/CD Pipeline Configuration

The pipeline is already configured to use the SSH deploy key:

```yaml
# In .github/workflows/gitops-pipeline.yml
- name: Checkout repository
  uses: actions/checkout@v4
  with:
    submodules: recursive
    ssh-key: ${{ secrets.SSH_DEPLOY_KEY }}

- name: Setup SSH for private submodules
  run: |
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    ssh-keyscan github.com >> ~/.ssh/known_hosts
    chmod 644 ~/.ssh/known_hosts
```

## 🔧 Troubleshooting

### Submodule Clone Failures

**Symptom**: `fatal: could not read from remote repository`

**Solutions**:
1. Verify SSH key is added to GitHub secrets
2. Check deploy key has correct permissions
3. Ensure repository is set to private (not public)
4. Verify SSH URL in .gitmodules

### Permission Denied

**Symptom**: `Permission denied (publickey)`

**Solutions**:
1. Verify SSH key is correctly formatted
2. Check for extra whitespace in the key
3. Ensure key is added as a deploy key
4. Test SSH connection manually

### Submodule Not Found

**Symptom**: `fatal: repository not found`

**Solutions**:
1. Verify repository name and organization
2. Check repository visibility (should be private)
3. Ensure you have access to the repository
4. Verify SSH URL format

## 📚 Reference

### GitHub Documentation
- [About Deploy Keys](https://docs.github.com/en/developers/overview/managing-deploy-keys)
- [Managing Submodules](https://docs.github.com/en/repositories/working-with-files/using-files/working-with-submodules)
- [Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

### Git Commands
```bash
# Initialize submodules
git submodule init

# Update submodules
git submodule update --remote

# Change submodule URL
git submodule set-url <path> <new-url>

# Sync submodules
git submodule sync
```

## 🙏 Support

For issues with private submodules:
- Check GitHub status: https://www.githubstatus.com/
- Review GitHub documentation
- Contact repository administrators

---

**Security Note**: Never commit private keys or sensitive information to any repository. Always use GitHub secrets and deploy keys for secure access to private repositories.