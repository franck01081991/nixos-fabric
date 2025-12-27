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
**License**: MIT