# Security Module Quick Start Guide

## Basic Setup

### 1. Import the Security Module

```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/security/init.nix  # Import security module
  ];

  # Enable basic security
  network-fabric.security.enable = true;
}
```

### 2. Basic SSH Configuration

```nix
network-fabric.security = {
  enable = true;
  
  ssh = {
    enable = true;
    port = 2222;  # Change from default SSH port
    passwordAuthentication = false;  # Disable password auth
    permitRootLogin = "no";  # Disable root login
  };
};
```

### 3. Basic Firewall Configuration

```nix
network-fabric.security = {
  enable = true;
  
  firewall = {
    enable = true;
    allowedTCP = [ 2222 80 443 ];  # Allow SSH, HTTP, HTTPS
    allowedUDP = [ ];  # No UDP ports by default
    enableLogging = true;  # Log firewall activity
  };
};
```

## Common Configurations

### Production Security Setup

```nix
network-fabric.security = {
  enable = true;
  
  # Secure SSH
  ssh = {
    enable = true;
    port = 2222;
    passwordAuthentication = false;
    permitRootLogin = "no";
    allowUsers = [ "admin" "deploy" ];
    maxAuthTries = 3;
    loginGraceTime = 30;
  };
  
  # Restrictive Firewall
  firewall = {
    enable = true;
    allowedTCP = [ 2222 80 443 51820 ];  # SSH, Web, WireGuard
    allowedUDP = [ 51820 ];  # WireGuard
    allowedICMP = true;
    enableLogging = true;
    logLimit = "10/sec";
  };
  
  # Enable Intrusion Detection
  fail2ban = {
    enable = true;
    bantime = 3600;  # 1 hour ban
    findtime = 600;  # 10 minute window
    maxretry = 3;
    jails = {
      sshd = true;  # Protect SSH
      recidive = true;  # Protect against repeat offenders
    };
  };
  
  # Enable System Hardening
  hardening = {
    enable = true;
    # Uses secure defaults for kernel, fs, and network
  };
};
```

### Development/Testing Setup

```nix
network-fabric.security = {
  enable = true;
  
  # Less restrictive SSH for development
  ssh = {
    enable = true;
    port = 22;  # Use default port for easier testing
    passwordAuthentication = true;  # Allow password for testing
    permitRootLogin = "prohibit-password";  # Allow root with keys only
  };
  
  # Basic firewall for development
  firewall = {
    enable = true;
    allowedTCP = [ 22 80 443 8080 ];  # Include common dev ports
    allowedUDP = [ ];
    enableLogging = false;  # Less verbose for development
  };
  
  # Disable intrusion detection for testing
  fail2ban = {
    enable = false;
  };
};
```

## Configuration Reference

### SSH Options

```nix
ssh = {
  enable = true/false;  # Enable SSH service
  port = 22;  # SSH port number
  passwordAuthentication = true/false;  # Allow password authentication
  permitRootLogin = "no"/"prohibit-password"/"yes";  # Root login policy
  allowUsers = [ "user1" "user2" ];  # List of allowed users
  allowGroups = [ "group1" "group2" ];  # List of allowed groups
  maxAuthTries = 3;  # Maximum authentication attempts
  loginGraceTime = 30;  # Login grace time in seconds
  banner = "/etc/issue";  # SSH banner file path
};
```

### Firewall Options

```nix
firewall = {
  enable = true/false;  # Enable firewall
  allowedTCP = [ 22 80 443 ];  # List of allowed TCP ports
  allowedUDP = [ 51820 ];  # List of allowed UDP ports
  allowedICMP = true/false;  # Allow ICMP traffic
  enableLogging = true/false;  # Enable firewall logging
  logLimit = "10/sec";  # Log rate limit
};
```

### Fail2ban Options

```nix
fail2ban = {
  enable = true/false;  # Enable Fail2ban
  bantime = 3600;  # Ban duration in seconds
  findtime = 600;  # Time window for attempts in seconds
  maxretry = 3;  # Maximum attempts before ban
  jails = {
    sshd = true/false;  # Enable SSH jail
    recidive = true/false;  # Enable recidive jail
    # Add custom jails as needed
  };
};
```

## Testing Your Configuration

### Validate Syntax

```bash
# Test module syntax
nix-instantiate --eval -E 'import ./modules/security/init.nix'

# Test your configuration
nix-instantiate --eval -E 'import ./your-config.nix'
```

### Test in a VM

```bash
# Build and test in a VM
nixos-rebuild build-vm -I nixos-config=./your-config.nix

# Run the VM
./result/bin/run-nixos-vm
```

## Troubleshooting

### SSH Connection Issues

1. **Check firewall rules**: Ensure your SSH port is allowed
2. **Verify SSH service**: `systemctl status sshd`
3. **Test with verbose**: `ssh -v user@host`
4. **Check logs**: `journalctl -u sshd`

### Firewall Problems

1. **Check status**: `systemctl status nftables`
2. **View rules**: `nft list ruleset`
3. **Check logs**: `journalctl -k | grep nftables`

### Fail2ban Not Working

1. **Check service**: `systemctl status fail2ban`
2. **Verify jails**: `fail2ban-client status`
3. **Check logs**: `journalctl -u fail2ban`

## Best Practices

### Security Recommendations

1. **Use custom SSH ports** to reduce automated attacks
2. **Disable password authentication** and use SSH keys only
3. **Enable all security layers** for defense in depth
4. **Regularly update** security configurations
5. **Monitor logs** for suspicious activity
6. **Test configurations** before production deployment

### Performance Tips

1. **Adjust logging levels** based on your needs
2. **Tune Fail2ban settings** for your traffic patterns
3. **Optimize firewall rules** for your specific requirements
4. **Balance security and usability** for your use case

## Migration Guide

### From security-improved.nix

**Before:**
```nix
network-fabric.security-improved = {
  enable = true;
  # ...
};
```

**After:**
```nix
network-fabric.security = {
  enable = true;
  # ...
};
```

### From basic security.nix

**Before:**
```nix
network-fabric.security = {
  enable = true;
  sshPort = 2222;
  # ...
};
```

**After:**
```nix
network-fabric.security = {
  enable = true;
  ssh = {
    enable = true;
    port = 2222;
    # ...
  };
  # ...
};
```

## Support

For issues and questions:
- Check the full documentation in `modules/security/README.md`
- Review examples in `examples/security-example.nix`
- Consult the structure guide in `STRUCTURE.md`
- Open an issue on the GitHub repository