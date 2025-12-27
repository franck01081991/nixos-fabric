# NixOS Fabric Security Module

The `security.nix` module provides comprehensive security configuration for NixOS Fabric deployments. It offers advanced security features including SSH hardening, firewall configuration, intrusion detection, mandatory access control, system auditing, secret management, and automatic security updates.

## Features

- **SSH Hardening**: Secure SSH configuration with custom ports, authentication restrictions, and connection limits
- **Firewall Configuration**: Advanced firewall rules with rate limiting and logging
- **Intrusion Detection**: Fail2ban integration with configurable jails and ban policies
- **Mandatory Access Control**: AppArmor profiles for critical services
- **System Auditing**: Comprehensive audit logging with disk space management
- **Secret Management**: Secure storage and management of sensitive data
- **Automatic Updates**: Scheduled security updates with notification support
- **System Hardening**: Kernel, filesystem, and network hardening settings

## Usage

### Basic Configuration

```nix
{ config, lib, pkgs, ... }:

{
  imports = [ ./modules/security.nix ];
  
  network-fabric = {
    security = {
      enable = true;
      
      # Basic SSH configuration
      ssh = {
        enable = true;
        port = 2222;
        passwordAuthentication = false;
        permitRootLogin = "no";
      };
      
      # Basic firewall configuration
      firewall = {
        enable = true;
        allowedTCP = [ 2222 80 443 ];
        allowedUDP = [ ];
      };
    };
  };
}
```

### Complete Configuration

See `examples/security-example.nix` for a comprehensive configuration with all features enabled.

## Configuration Options

### `network-fabric.security-improved.enable` (Boolean)
Enable the security module. Default: `false`

### `network-fabric.security-improved.ssh` (Attribute Set)
SSH security configuration:
- `enable`: Enable SSH service (default: `true`)
- `port`: SSH port (default: `22`)
- `passwordAuthentication`: Allow password authentication (default: `false`)
- `permitRootLogin`: Root login policy (default: `"prohibit-password"`)
- `allowUsers`: List of allowed users
- `allowGroups`: List of allowed groups
- `maxAuthTries`: Maximum authentication attempts (default: `3`)
- `loginGraceTime`: Login grace time in seconds (default: `30`)
- `banner`: SSH banner file (default: `"/etc/issue"`)

### `network-fabric.security-improved.firewall` (Attribute Set)
Firewall configuration:
- `enable`: Enable firewall (default: `true`)
- `allowedTCP`: List of allowed TCP ports
- `allowedUDP`: List of allowed UDP ports
- `allowedICMP`: Allow ICMP traffic (default: `true`)
- `enableLogging`: Enable firewall logging (default: `true`)
- `logLimit`: Log rate limit (default: `"10/sec"`)

### `network-fabric.security-improved.fail2ban` (Attribute Set)
Fail2ban configuration:
- `enable`: Enable Fail2ban (default: `true`)
- `bantime`: Ban duration in seconds (default: `3600`)
- `findtime`: Time window for attempts (default: `600`)
- `maxretry`: Maximum attempts before ban (default: `3`)
- `jails`: Fail2ban jails configuration

### `network-fabric.security-improved.apparmor` (Attribute Set)
AppArmor configuration:
- `enable`: Enable AppArmor (default: `true`)
- `profiles`: List of AppArmor profiles
- `enforceMode`: Enable enforce mode (default: `true`)

### `network-fabric.security-improved.auditd` (Attribute Set)
Auditd configuration:
- `enable`: Enable auditd (default: `true`)
- `spaceLeft`: Disk space left percentage (default: `50`)
- `spaceLeftAction`: Action when space left (default: `"email"`)
- `adminSpaceLeft`: Admin space left percentage (default: `25`)
- `maxLogFile`: Maximum log file size (default: `50`)
- `maxLogFileAction`: Action when max log file reached (default: `"rotate"`)

### `network-fabric.security-improved.secrets` (Attribute Set)
Secret management configuration:
- `enable`: Enable secret management (default: `true`)
- `backend`: Secret backend (default: `"age"`)
- `keyFile`: Secret key file path
- `configDir`: Secret configuration directory

### `network-fabric.security-improved.updates` (Attribute Set)
Security updates configuration:
- `enable`: Enable automatic updates (default: `true`)
- `autoUpdate`: Automatically apply updates (default: `false`)
- `checkInterval`: Update check interval (default: `"daily"`)
- `emailNotifications`: Email for notifications

### `network-fabric.security-improved.hardening` (Attribute Set)
System hardening configuration:
- `enable`: Enable system hardening (default: `true`)
- `kernel`: Kernel hardening settings
- `fs`: Filesystem hardening settings
- `network`: Network hardening settings

## Testing

Test the security module configuration:

```bash
# Test module syntax
nix-instantiate --eval -E 'import ./modules/security.nix'

# Test example configuration
nix-instantiate --eval -E 'import ./examples/security-example.nix'

# Test in a VM
nixos-rebuild build-vm -I nixos-config=./examples/security-example.nix
```

## Integration with Other Modules

The security module integrates seamlessly with other NixOS Fabric modules:

```nix
{
  imports = [
    ./modules/security.nix
    ./modules/wireguard.nix
    ./modules/frr.nix
  ];
  
  network-fabric = {
    security = {
      enable = true;
      firewall = {
        allowedTCP = [ 22 80 443 51820 ];  # Include WireGuard port
        allowedUDP = [ 51820 ];             # WireGuard UDP
      };
    };
    
    wireguard = {
      enable = true;
      # WireGuard configuration
    };
    
    frr = {
      enable = true;
      # FRR configuration
    };
  };
}
```

## Migration from security-improved.nix

If you were using the old `security-improved.nix` module, update your configuration:

**Before:**
```nix
network-fabric.security-improved = {
  enable = true;
  # ...
};
```

**After:**
```nix
network-fabric.security-improved = {
  enable = true;
  # ...
};
```

## Best Practices

1. **Use custom SSH ports**: Change from port 22 to reduce automated attacks
2. **Disable password authentication**: Use SSH keys only
3. **Enable all security features**: Use all available security layers
4. **Regular updates**: Keep the security module and configurations updated
5. **Monitor logs**: Regularly check security logs and alerts
6. **Test configurations**: Test security configurations in a staging environment first

## Troubleshooting

### Module doesn't apply
- Ensure `network-fabric.security-improved.enable = true;`
- Check for syntax errors with `nix-instantiate --eval`
- Verify module is imported in your configuration

### SSH connection issues
- Check firewall rules allow your SSH port
- Verify SSH service is running
- Test with `ssh -v user@host` for detailed errors

### Fail2ban not working
- Check Fail2ban service status: `systemctl status fail2ban`
- Verify jail configuration: `fail2ban-client status`
- Check logs: `journalctl -u fail2ban`

## License

This security module is part of the NixOS Fabric project and is licensed under the MIT License.