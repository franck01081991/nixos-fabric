# Frequently Asked Questions

## 🤔 General Questions

### What is NixOS Fabric?
NixOS Fabric is a comprehensive security and networking configuration framework for NixOS deployments. It provides modular security configurations including SSH hardening, firewall setup, intrusion detection, and system auditing.

### What changed in the security module?
The security module was reorganized to avoid conflicts:
- **Old path**: `network-fabric.security`
- **New path**: `network-fabric.security-improved`
- **Reason**: Avoid conflicts with existing options

### How do I update my configuration?
Change all references from:
```nix
network-fabric.security = { ... }
```
to:
```nix
network-fabric.security-improved = { ... }
```

## 📋 Configuration Questions

### How do I enable the security module?
```nix
{ config, lib, pkgs, ... }:
{
  imports = [ ./modules/security/init.nix ];
  
  network-fabric.security-improved.enable = true;
}
```

### What's the minimal configuration?
```nix
network-fabric.security-improved = {
  enable = true;
  ssh.enable = true;
  firewall.enable = true;
};
```

### How do I configure SSH?
```nix
network-fabric.security-improved.ssh = {
  enable = true;
  port = 2222;
  passwordAuthentication = false;
  permitRootLogin = "no";
  allowUsers = [ "admin" "deploy" ];
};
```

### How do I set up the firewall?
```nix
network-fabric.security-improved.firewall = {
  enable = true;
  allowedTCP = [ 2222 80 443 ];
  allowedUDP = [ 53 ];
  allowedICMP = true;
};
```

### How do I enable Fail2ban?
```nix
network-fabric.security-improved.fail2ban = {
  enable = true;
  bantime = 3600;  # 1 hour
  findtime = 600;  # 10 minutes
  maxretry = 3;
  jails.sshd = true;
};
```

## 🔧 Technical Questions

### Why do I get "function called without required argument 'lib'"?
The security module requires three arguments: `config`, `lib`, and `pkgs`.

**Correct**:
```nix
import ./modules/security/init.nix { inherit config lib pkgs; }
```

**Incorrect**:
```nix
import ./modules/security/init.nix { inherit config; }
```

### How do I test my configuration?
```bash
# Check syntax
nix-instantiate --eval -E 'import ./modules/security/init.nix'

# Run flake check
nix flake check

# Run security tests
bash tests/run-security-tests.sh
```

### How do I debug firewall issues?
```bash
# Check firewall status
sudo nft list ruleset

# Check nftables service
sudo systemctl status nftables

# View logs
journalctl -u nftables
```

### How do I check if Fail2ban is working?
```bash
# Check Fail2ban status
sudo fail2ban-client status

# Check Fail2ban logs
journalctl -u fail2ban

# Check banned IPs
sudo fail2ban-client status sshd
```

## 🚀 Deployment Questions

### How do I deploy to production?
```bash
# Test first
sudo nixos-rebuild test

# Dry run
sudo nixos-rebuild dry-activate

# Actual deployment
sudo nixos-rebuild switch
```

### How do I roll back?
```bash
# List generations
sudo nixos-rebuild list-generations

# Roll back to previous generation
sudo nixos-rebuild switch --rollback
```

### How do I update the configuration?
```bash
# Edit configuration.nix
nano /etc/nixos/configuration.nix

# Test and deploy
sudo nixos-rebuild test && sudo nixos-rebuild switch
```

## 📚 Documentation Questions

### Where is the documentation?
- [Main Documentation](README.md)
- [Security Module](modules/security/README.md)
- [Quick Start](getting-started/QUICKSTART.md)
- [API Reference](reference/API.md)

### How do I contribute?
See [Contributing Guide](development/CONTRIBUTING.md)

### Where are the examples?
See [Examples](modules/security/EXAMPLES.md)

## 🤝 Community Questions

### How do I get help?
1. Check this FAQ
2. Review [Debugging Guide](DEBUGGING.md)
3. Open an issue on GitHub
4. Ask on NixOS Discord or Forum

### How do I report a bug?
Open an issue on GitHub with:
- Detailed description
- Steps to reproduce
- Expected vs actual behavior
- Logs if available

### How do I request a feature?
Open an issue on GitHub with:
- Use case description
- Proposed solution
- Benefits

---

*Last updated: $(date +%Y-%m-%d)*
