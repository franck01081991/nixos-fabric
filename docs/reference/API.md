# Security Module API Reference

## 📋 Module Options

### `network-fabric.security-improved.enable`
**Type**: Boolean
**Default**: `false`
**Description**: Enable comprehensive security configuration

### `network-fabric.security-improved.ssh`
**Type**: Attribute Set
**Description**: SSH security configuration

#### SSH Options
- `enable`: Boolean (default: `true`) - Enable SSH service
- `port`: Number (default: `22`) - SSH port
- `passwordAuthentication`: Boolean (default: `false`) - Allow password auth
- `permitRootLogin`: String (default: `"prohibit-password"`) - Root login setting
- `allowUsers`: List of strings - Allowed users
- `allowGroups`: List of strings - Allowed groups
- `maxAuthTries`: Number (default: `3`) - Max authentication attempts
- `loginGraceTime`: Number (default: `30`) - Login grace time in seconds
- `banner`: String - SSH banner file path

### `network-fabric.security-improved.firewall`
**Type**: Attribute Set
**Description**: Firewall configuration

#### Firewall Options
- `enable`: Boolean (default: `true`) - Enable firewall
- `allowedTCP`: List of numbers - Allowed TCP ports
- `allowedUDP`: List of numbers - Allowed UDP ports
- `allowedICMP`: Boolean (default: `true`) - Allow ICMP
- `enableLogging`: Boolean (default: `false`) - Enable logging
- `logLimit`: String (default: `"10/sec"`) - Log rate limit

### `network-fabric.security-improved.fail2ban`
**Type**: Attribute Set
**Description**: Fail2ban configuration

#### Fail2ban Options
- `enable`: Boolean (default: `true`) - Enable Fail2ban
- `bantime`: Number (default: `3600`) - Ban time in seconds
- `findtime`: Number (default: `600`) - Find time in seconds
- `maxretry`: Number (default: `3`) - Max retry attempts
- `jails`: Attribute Set - Fail2ban jails
  - `sshd`: Boolean (default: `true`) - Enable SSH jail
  - `recidive`: Boolean (default: `true`) - Enable recidive jail

### `network-fabric.security-improved.apparmor`
**Type**: Attribute Set
**Description**: AppArmor configuration

#### AppArmor Options
- `enable`: Boolean (default: `true`) - Enable AppArmor
- `profiles`: List of strings - Profiles to load
- `enforceMode`: Boolean (default: `true`) - Enforce mode

### `network-fabric.security-improved.auditd`
**Type**: Attribute Set
**Description**: Auditd configuration

#### Auditd Options
- `enable`: Boolean (default: `true`) - Enable Auditd
- `spaceLeft`: Number (default: `50`) - Space left percentage
- `spaceLeftAction`: String (default: `"email"`) - Space left action
- `adminSpaceLeft`: Number (default: `25`) - Admin space left percentage

### `network-fabric.security-improved.secrets`
**Type**: Attribute Set
**Description**: Secret management

#### Secrets Options
- `enable`: Boolean (default: `false`) - Enable secrets management
- `configDir`: String (default: `"/etc/nixos-fabric/secrets"`) - Secrets directory

### `network-fabric.security-improved.updates`
**Type**: Attribute Set
**Description**: Security updates

#### Updates Options
- `enable`: Boolean (default: `false`) - Enable automatic updates
- `checkInterval`: String (default: `"daily"`) - Check interval
- `emailNotifications`: String - Email for notifications

### `network-fabric.security-improved.hardening`
**Type**: Attribute Set
**Description**: System hardening

#### Hardening Options
- `enable`: Boolean (default: `true`) - Enable hardening
- `kernelParameters`: Attribute Set - Kernel parameters
- `filesystemRestrictions`: Attribute Set - Filesystem restrictions

## 📝 Usage Examples

### Minimal Configuration
```nix
network-fabric.security-improved = {
  enable = true;
  ssh.enable = true;
  firewall.enable = true;
};
```

### Complete Configuration
```nix
network-fabric.security-improved = {
  enable = true;
  
  ssh = {
    enable = true;
    port = 2222;
    passwordAuthentication = false;
    permitRootLogin = "no";
    allowUsers = [ "admin" "deploy" ];
    maxAuthTries = 3;
  };
  
  firewall = {
    enable = true;
    allowedTCP = [ 2222 80 443 ];
    allowedUDP = [ 53 ];
    allowedICMP = true;
    enableLogging = true;
    logLimit = "10/sec";
  };
  
  fail2ban = {
    enable = true;
    bantime = 3600;
    findtime = 600;
    maxretry = 3;
    jails = {
      sshd = true;
      recidive = true;
    };
  };
  
  apparmor = {
    enable = true;
    profiles = [ "ssh" "nginx" ];
    enforceMode = true;
  };
  
  auditd = {
    enable = true;
    spaceLeft = 50;
    spaceLeftAction = "email";
  };
};
```

## 🔧 Configuration Reference

All security configurations are available under:
```nix
network-fabric.security-improved.{ssh, firewall, fail2ban, apparmor, auditd, secrets, updates, hardening}
```

See [Security Module README](modules/security/README.md) for complete documentation.
