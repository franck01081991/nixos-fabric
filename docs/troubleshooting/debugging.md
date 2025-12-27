# Debugging Guide

## 🐛 Common Issues and Solutions

### 1. Flake Check Fails

**Error**: `nix flake check` fails with various errors

**Solution**:
```bash
# Check for syntax errors
nix-instantiate --eval -E 'import ./modules/security/init.nix'

# Verify flake structure
nix flake show

# Check specific host configuration
nix-instantiate --eval -E 'import ./hosts/rtr-sapinet/default.nix'
```

### 2. Security Module Import Errors

**Error**: `function called without required argument 'lib'`

**Solution**: Ensure proper import:
```nix
# Correct way
import ./modules/security/init.nix { inherit config lib pkgs; }

# Wrong way (missing arguments)
import ./modules/security/init.nix { inherit config; }
```

### 3. Firewall Conflicts

**Error**: `networking.firewall.enable has conflicting definition values`

**Solution**: The security module now handles this automatically:
```nix
# The module checks if nftables is enabled
networking.firewall = mkIf (cfg.firewall.enable && !config.networking.nftables.enable) {
  # ... firewall config
};
```

### 4. Path Not Found Errors

**Error**: `Path 'modules/security-improved.nix' does not exist`

**Solution**: Use the new security module structure:
```nix
# Old (broken)
imports = [ ./modules/security-improved.nix ];

# New (correct)
imports = [ ./modules/security/init.nix ];
```

### 5. Test Failures

**Error**: Security test suite fails

**Solution**:
```bash
# Run tests individually
bash tests/run-security-tests.sh

# Check test module
nix-instantiate --eval -E 'import ./tests/modules/security/init.nix'
```

## 🔍 Debugging Commands

### Check Module Syntax
```bash
nix-instantiate --eval -E 'import ./modules/security/init.nix'
```

### Evaluate Module
```bash
nix-instantiate --eval -E '
let
  nixpkgs = import <nixpkgs> {};
  lib = nixpkgs.lib;
  pkgs = nixpkgs;
  config = { network-fabric.security-improved = { enable = true; }; };
in import ./modules/security/init.nix { inherit config lib pkgs; }
'
```

### Check Flake
```bash
nix flake check
nix flake show
```

### Verify Host Configurations
```bash
nix-instantiate --eval -E 'import ./hosts/rtr-sapinet/default.nix'
nix-instantiate --eval -E 'import ./hosts/rtr-noisy/default.nix'
```

## 📚 Debugging Resources

### Log Files
- `/var/log/nixos-fabric/` - Fabric-specific logs
- `/var/log/security/` - Security module logs
- `/var/log/audit/` - Audit logs

### Common Log Commands
```bash
# View security logs
journalctl -u nixos-fabric-security

# View fail2ban logs
journalctl -u fail2ban

# View audit logs
journalctl -u auditd
```

### Configuration Validation
```bash
# Validate NixOS configuration
sudo nixos-validate

# Test configuration without applying
sudo nixos-rebuild test
```

## 🤝 Getting Help

1. **Check FAQ**: [FAQ](FAQ.md)
2. **Review Documentation**: [README](../README.md)
3. **Open Issue**: GitHub Issues
4. **Community**: NixOS Discord/Forum

## 🎯 Best Practices

1. **Test Before Deploy**: Always run `nix flake check`
2. **Use New Path**: `network-fabric.security-improved`
3. **Provide All Arguments**: `{ inherit config lib pkgs; }`
4. **Check Logs**: Monitor `/var/log/` for issues
5. **Update Regularly**: Keep documentation in sync

---

*Last updated: $(date +%Y-%m-%d)*
