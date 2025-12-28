# NixOS Fabric Security Module

## Overview

The **Security Module** provides comprehensive security configuration for NixOS Fabric deployments. It integrates multiple security components into a unified, declarative configuration system.

## Features

### Core Security Components

1. **SSH Security**
   - Hardened SSH configuration
   - Customizable security parameters
   - Access control and authentication options
   - Security banners and logging

2. **Firewall Configuration**
   - Advanced nftables rules
   - Stateful packet filtering
   - Port and service management
   - Rate limiting and logging

3. **System Hardening**
   - Kernel parameters optimization
   - Service security settings
   - User and group restrictions
   - Filesystem protections

4. **Network Security Integration**
   - Unified security policies
   - Role-based security rules
   - Protocol-specific protections
   - VLAN and interface security

5. **Advanced nftables Rules**
   - Complex filtering rules
   - Connection tracking
   - Logging and monitoring
   - Performance optimization

## Module Structure

```
modules/security/
├── init.nix          # Main entry point (imports all submodules)
├── index.nix         # Module documentation and reference
├── default.nix       # Core security module
├── firewall.nix      # Firewall configuration
├── hardening.nix     # System hardening
├── ssh.nix           # SSH security
├── nftables-advanced.nix # Advanced firewall rules
├── network-security.nix # Network security integration
└── README.md        # This documentation
```

## Usage

### Basic Configuration

```nix
{ config, pkgs, ... }:

{
  imports = [ ./modules/security/init.nix ];
  
  network-fabric.security = {
    enable = true;
    
    ssh = {
      enable = true;
      port = 2222;
      passwordAuthentication = false;
    };
    
    firewall = {
      enable = true;
      allowedTCP = [ 2222 80 443 51820 ];
    };
  };
}
```

### Advanced Configuration

```nix
{ config, pkgs, ... }:

{
  imports = [ ./modules/security/init.nix ];
  
  network-fabric.security = {
    enable = true;
    
    # SSH Configuration
    ssh = {
      enable = true;
      port = 2222;
      passwordAuthentication = false;
      permitRootLogin = "no";
      allowUsers = [ "admin" "franck" ];
      maxAuthTries = 3;
      loginGraceTime = 30;
    };
    
    # Firewall Configuration
    firewall = {
      enable = true;
      allowedTCP = [ 2222 80 443 51820 ];
      allowedUDP = [ 51820 ];
      enableLogging = true;
      logLimit = "10/sec";
    };
    
    # System Hardening
    hardening = {
      enable = true;
      kernelParameters = {
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
      };
    };
    
    # Network Security
    network-security = {
      enable = true;
      policies = {
        defaultDeny = true;
        stateTracking = true;
        enableLogging = true;
      };
    };
  };
}
```

## Configuration Options

### Top-Level Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | boolean | `false` | Enable security module |

### SSH Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ssh.enable` | boolean | `true` | Enable SSH configuration |
| `ssh.port` | integer | `22` | SSH port number |
| `ssh.passwordAuthentication` | boolean | `false` | Allow password authentication |
| `ssh.permitRootLogin` | string | `"no"` | Root login permission |
| `ssh.allowUsers` | list | `[]` | Allowed SSH users |
| `ssh.maxAuthTries` | integer | `3` | Maximum authentication attempts |

### Firewall Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `firewall.enable` | boolean | `true` | Enable firewall configuration |
| `firewall.allowedTCP` | list | `[ 22 80 443 ]` | Allowed TCP ports |
| `firewall.allowedUDP` | list | `[]` | Allowed UDP ports |
| `firewall.enableLogging` | boolean | `true` | Enable logging |
| `firewall.logLimit` | string | `"10/sec"` | Log rate limit |

### Hardening Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hardening.enable` | boolean | `true` | Enable system hardening |
| `hardening.kernelParameters` | attrs | `{}` | Kernel parameter settings |
| `hardening.serviceRestrictions` | attrs | `{}` | Service-specific restrictions |

### Network Security Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `network-security.enable` | boolean | `true` | Enable network security integration |
| `network-security.policies.defaultDeny` | boolean | `true` | Default deny policy |
| `network-security.policies.stateTracking` | boolean | `true` | Enable state tracking |
| `network-security.policies.enableLogging` | boolean | `true` | Enable security logging |

## Integration with Other Modules

The security module integrates with:

- **FRR Module**: Provides BGP/OSPF security settings
- **WireGuard Module**: Configures VPN security parameters
- **Networking Module**: Applies security to network interfaces
- **Ansible Module**: Security configuration for Ansible deployments

## Best Practices

### Security Recommendations

1. **Enable all security features** for production deployments
2. **Use non-standard SSH ports** to reduce automated attacks
3. **Disable password authentication** and use SSH keys
4. **Enable firewall logging** for security monitoring
5. **Regularly review** security configurations
6. **Test changes** in development before production
7. **Monitor logs** for security events

### Performance Considerations

1. **Logging levels**: Adjust based on monitoring needs
2. **Rate limiting**: Balance security with performance
3. **State tracking**: Enable for legitimate traffic
4. **Rule complexity**: Keep firewall rules manageable

## Testing

### Module Validation

```bash
# Test module syntax
nix-instantiate --eval -E 'import ./modules/security/init.nix'

# Test with configuration
nix-instantiate --eval -E 'import ./your-config.nix'

# Test flake integration
nix flake check
```

### Deployment Testing

1. Test SSH access with new settings
2. Verify firewall rules are applied
3. Check security logging is working
4. Validate network security policies
5. Confirm hardening settings are active

## Troubleshooting

### Common Issues

**SSH access problems:**
- Verify SSH port is correct
- Check firewall allows the port
- Confirm user access is configured

**Firewall blocking traffic:**
- Review allowed ports and services
- Check rule order and priorities
- Verify state tracking is enabled

**Module conflicts:**
- Check for duplicate security configurations
- Review import order
- Verify option namespaces

### Debugging Commands

```bash
# Check security configuration
nix eval -f your-config.nix config.network-fabric.security

# Check SSH service
sudo systemctl status sshd
sudo journalctl -u sshd

# Check firewall rules
sudo nft list ruleset
sudo nft list ruleset | grep nixos-fabric

# Check security logs
sudo journalctl -u nftables
sudo journalctl -k | grep nixos-fabric
```

## Migration

### From Previous Versions

If migrating from older security configurations:

1. **Review new options** and update configuration
2. **Test in development** environment first
3. **Gradually enable** new security features
4. **Monitor for issues** after deployment

### From No Security Module

If adding security for the first time:

1. **Start with basic configuration**
2. **Enable features gradually**
3. **Test each feature** before production
4. **Document your setup** for future reference

## Contributing

Contributions are welcome! See `CONTRIBUTING.md` for guidelines.

## License

This module is licensed under the MIT License.

## Support

For support, please open an issue on GitHub or contact the maintainers.

---

**Security Module** - Comprehensive security for NixOS Fabric
**Status**: ✅ Production Ready
**Maintainer**: Franck
**License**: MIT# Security Improved Module

## Overview

The `security-improved.nix` module provides comprehensive security configuration for NixOS Fabric deployments. It offers advanced security features including SSH hardening, firewall configuration, intrusion detection, mandatory access control, system auditing, secret management, and automatic security updates.

## Features

### 1. SSH Security
- **Hardened SSH configuration** with customizable settings
- **Custom SSH banners** with fabric information
- **Access control** with allowed users and groups
- **Security parameters** (max auth tries, login grace time, etc.)

### 2. Firewall Configuration
- **Advanced nftables rules** for network filtering
- **Port management** for TCP and UDP services
- **ICMP control** for network diagnostics
- **Logging and rate limiting** for security monitoring

### 3. Fail2Ban Integration
- **Brute force protection** for SSH and other services
- **Customizable jails** with configurable parameters
- **Automatic banning** of malicious IPs
- **Integration with system services**

### 4. AppArmor Support
- **Mandatory Access Control** for critical services
- **Custom profiles** for FRR, WireGuard, SSH, and nftables
- **Enforcement mode** for production environments

### 5. Auditd Configuration
- **Comprehensive system auditing**
- **File access monitoring** for critical directories
- **User activity logging** for security analysis
- **Network change tracking**

### 6. Secret Management
- **Multiple backend support** (age, sops, vault)
- **Secure key storage** with proper permissions
- **Environment integration** for applications

### 7. Security Updates
- **Automatic update checking**
- **Configurable intervals** (daily, weekly, etc.)
- **Notification system** for administrators

## Usage

### Basic Configuration

```nix
{ config, pkgs, ... }:
{
  imports = [ ./modules/security-improved.nix ];
  
  network-fabric.security-improved = {
    enable = true;
    
    ssh = {
      enable = true;
      port = 22;
      passwordAuthentication = false;
    };
    
    firewall = {
      enable = true;
      allowedTCP = [ 22 80 443 ];
    };
  };
}
```

### Complete Configuration

See `examples/security-improved-example.nix` for a comprehensive configuration example with all features enabled.

## Configuration Options

### Top-Level Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | boolean | `false` | Enable comprehensive security configuration |

### SSH Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ssh.enable` | boolean | `true` | Enable SSH configuration |
| `ssh.port` | integer | `22` | SSH port number |
| `ssh.passwordAuthentication` | boolean | `false` | Allow password authentication |
| `ssh.permitRootLogin` | string | `"no"` | Root login permission |
| `ssh.allowUsers` | list | `[ "franck" ]` | Allowed SSH users |
| `ssh.allowGroups` | list | `[ "wheel" ]` | Allowed SSH groups |
| `ssh.maxAuthTries` | integer | `3` | Maximum authentication attempts |
| `ssh.loginGraceTime` | integer | `30` | Login grace time in seconds |
| `ssh.banner` | string | `"/etc/issue"` | SSH banner file path |

### Firewall Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `firewall.enable` | boolean | `true` | Enable firewall configuration |
| `firewall.allowedTCP` | list | `[ 22 80 443 51820 ]` | Allowed TCP ports |
| `firewall.allowedUDP` | list | `[ 51820 ]` | Allowed UDP ports |
| `firewall.allowedICMP` | boolean | `true` | Allow ICMP (ping) |
| `firewall.enableLogging` | boolean | `true` | Enable logging of dropped packets |
| `firewall.logLimit` | string | `"10/sec"` | Log rate limit |

### Fail2Ban Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `fail2ban.enable` | boolean | `true` | Enable Fail2Ban |
| `fail2ban.bantime` | integer | `3600` | Ban time in seconds |
| `fail2ban.findtime` | integer | `600` | Find time window in seconds |
| `fail2ban.maxretry` | integer | `3` | Maximum retry attempts |
| `fail2ban.jails.sshd` | boolean | `true` | Enable SSH jail |
| `fail2ban.jails.recidive` | boolean | `true` | Enable recidive jail |

### AppArmor Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `apparmor.enable` | boolean | `true` | Enable AppArmor |
| `apparmor.profiles` | list | `[ "frr" "wireguard" "ssh" ]` | AppArmor profiles to load |
| `apparmor.enforceMode` | boolean | `true` | Use enforce mode (vs complain) |

### Auditd Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `auditd.enable` | boolean | `true` | Enable Auditd |

### Secrets Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `secrets.enable` | boolean | `true` | Enable secret management |
| `secrets.backend` | string | `"age"` | Secret backend (age, sops, vault) |
| `secrets.keyFile` | string | `"/etc/nixos-fabric/secrets/key.txt"` | Key file path |
| `secrets.configDir` | string | `"/etc/nixos-fabric/secrets"` | Configuration directory |

### Updates Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `updates.enable` | boolean | `true` | Enable security updates |
| `updates.autoUpdate` | boolean | `false` | Automatic updates (not recommended for production) |
| `updates.checkInterval` | string | `"daily"` | Check interval (daily, weekly, etc.) |
| `updates.emailNotifications` | string | `"admin@example.com"` | Notification email address |

## Implementation Details

### NixOS Integration

The module integrates with standard NixOS options:

- `services.openssh` for SSH configuration
- `networking.firewall` for firewall rules
- `services.fail2ban` for intrusion detection
- `security.apparmor` for mandatory access control
- `security.auditd` for system auditing

### Activation Scripts

The module uses NixOS activation scripts for complex configurations:

- `sshBanner` - Generates custom SSH banners
- `fail2banConfig` - Configures Fail2Ban jails
- `apparmorProfiles` - Loads custom AppArmor profiles
- `auditdRules` - Sets up audit rules
- `secretsSetup` - Initializes secret management
- `securityUpdates` - Configures update checking

### Conflict Resolution

To avoid conflicts with the existing `network-fabric.nix` module, this module uses the path:

```nix
network-fabric.security-improved
```

Instead of:

```nix
network-fabric.security
```

## Migration Guide

### From Previous Versions

If you were using the old security configuration, update your configuration:

```nix
# Old configuration
network-fabric.security = {
  enable = true;
  ssh.enable = true;
  # ...
};

# New configuration
network-fabric.security-improved = {
  enable = true;
  ssh.enable = true;
  # ...
};
```

### From No Security Module

If you're adding security for the first time:

1. Add the import to your configuration
2. Enable the module with basic settings
3. Gradually add more security features as needed
4. Test each feature before deploying to production

## Testing

### Module Validation

```bash
# Test module syntax
nix-instantiate --eval -E 'import ./modules/security-improved.nix'

# Test with minimal configuration
nix-instantiate --eval -E 'import ./examples/security-improved-example.nix'

# Test flake integration
nix flake check
```

### Deployment Testing

1. Test in a development environment first
2. Verify SSH access with new settings
3. Check firewall rules are applied correctly
4. Validate Fail2Ban is monitoring services
5. Confirm AppArmor profiles are loaded
6. Verify audit logs are being generated

## Best Practices

### Security Recommendations

1. **Start with basic configuration** and gradually enable more features
2. **Test in development** before deploying to production
3. **Monitor logs** after deployment for any issues
4. **Review settings** for your specific security requirements
5. **Keep secrets secure** and properly backed up
6. **Regularly update** security configurations
7. **Document your setup** for future reference

### Performance Considerations

1. **Logging levels** - Adjust based on your monitoring needs
2. **Fail2Ban settings** - Balance security with performance impact
3. **AppArmor profiles** - Test for application compatibility
4. **Auditd rules** - Configure based on storage capacity

## Troubleshooting

### Common Issues

**Module not loading:**
- Verify the import path is correct
- Check for syntax errors in your configuration
- Ensure the module is enabled

**SSH access problems:**
- Verify the SSH port is correct
- Check firewall rules allow the port
- Confirm user access is properly configured

**Fail2Ban not working:**
- Check Fail2Ban service is running
- Verify jail configuration
- Review Fail2Ban logs

**AppArmor errors:**
- Check profile syntax
- Test in complain mode first
- Review application logs

### Debugging Commands

```bash
# Check module evaluation
nix eval -f your-config.nix config.network-fabric.security-improved

# Check SSH configuration
sudo systemctl status sshd
sudo journalctl -u sshd

# Check Fail2Ban status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Check AppArmor status
sudo aa-status
sudo systemctl status apparmor

# Check Auditd status
sudo systemctl status auditd
sudo ausearch -m USER_LOGIN -i

# Check firewall rules
sudo nft list ruleset
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository** and create a feature branch
2. **Add tests** for new features
3. **Update documentation** for changes
4. **Follow existing code style**
5. **Submit a pull request** with clear description

### Areas for Contribution

- Additional security features
- More AppArmor profiles
- Enhanced monitoring integration
- Better error handling
- Additional documentation
- Test cases and examples

## License

This module is licensed under the MIT License. See the LICENSE file for details.

## Support

For questions and issues:

- **GitHub Issues**: For bug reports and feature requests
- **Discussions**: For general questions and ideas
- **Email**: franck01081991@gmail.com (for private matters)

## Changelog

See `CHANGES.md` for detailed information about changes and migrations.

## Related Documentation

- `CHANGES.md` - Detailed change information and migration guide
- `examples/security-improved-example.nix` - Complete configuration example
- `docs/architecture/ARCHITECTURE.md` - Overall architecture documentation
- `docs/reference/ROLES.md` - Role system documentation

---

**Module Status**: ✅ Production Ready
**Last Updated**: 2024-07-25
**Maintainer**: Franck
**License**: MIT