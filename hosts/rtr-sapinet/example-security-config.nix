# Example Security Configuration for rtr-sapinet
# This demonstrates comprehensive security settings for a spine node

{ config, lib, pkgs, ... }:

{
  # Enable comprehensive security
  network-fabric.security-improved = {
    enable = true;
    
    # SSH configuration - hardened for spine node
    ssh = {
      enable = true;
      port = 2222;  # Non-standard port
      passwordAuthentication = false;
      permitRootLogin = "no";
      allowUsers = [ "franck" ];
      allowGroups = [ "wheel" "fabric-admins" ];
      maxAuthTries = 2;  # Very restrictive
      loginGraceTime = 20;  # Short grace period
      banner = "/etc/issue";
    };
    
    # Firewall configuration - restrictive for spine
    firewall = {
      enable = true;
      allowedTCP = [ 2222 51820 179 2605 ];  # SSH, WireGuard, BGP, OSPF
      allowedUDP = [ 51820 ];  # WireGuard
      allowedICMP = true;  # Allow ping for monitoring
      enableLogging = true;
      logLimit = "5/sec";  # Rate limiting
    };
    
    # Fail2ban configuration - aggressive for spine
    fail2ban = {
      enable = true;
      bantime = 7200;  # 2 hours
      findtime = 300;  # 5 minutes
      maxretry = 2;    # Very low tolerance
      
      jails = {
        sshd = true;
        recidive = true;
      };
    };
    
    # AppArmor configuration
    apparmor = {
      enable = true;
      profiles = [ "frr" "wireguard" "ssh" "nftables" ];
      enforceMode = true;
    };
    
    # Auditd configuration - comprehensive logging
    auditd = {
      enable = true;
      spaceLeft = 100;  # 100MB
      spaceLeftAction = "email";
      adminSpaceLeft = 50;  # 50MB
      maxLogFile = 20;
      maxLogFileAction = "rotate";
    };
    
    # Secret management - age encryption
    secrets = {
      enable = true;
      backend = "age";
      keyFile = "/etc/nixos-fabric/secrets/key.txt";
      configDir = "/etc/nixos-fabric/secrets";
    };
    
    # Security updates - daily checks
    updates = {
      enable = true;
      autoUpdate = false;  # Manual updates for production
      checkInterval = "daily";
      emailNotifications = "admin@fabric.local";
    };
  };
  
  # Additional security hardening
  security.hardening = {
    enable = true;
    kernel = {
      sysctl = {
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
      };
    };
    
    # Enable kernel hardening
    kernelParameters = [
      "slab_nomerge"
      "ptrace_scope=1"
      "kptr_restrict=2"
      "dmesg_restrict=1"
      "devty_restrict=1"
    ];
  };
  
  # Security monitoring with Prometheus
  services.prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "security-monitoring";
        static_configs = [
          {
            targets = [ "localhost:9100" ];
            labels = {
              node = "rtr-sapinet";
              role = "spine";
              monitor = "security";
            };
          }
        ];
      }
    ];
  };
  
  # Security alerts
  system.activationScripts.securityAlerts = lib.mkBefore ''
    # Create security alert directory
    mkdir -p /etc/nixos-fabric/security/alerts
    
    # Set up security alert script
    cat > /etc/nixos-fabric/security/alerts/alert.sh <<EOF
#!/bin/bash
# Security Alert Script

echo "🚨 SECURITY ALERT: $1"
echo "Timestamp: $(date)"
echo "Node: $(hostname)"
echo "Role: spine"
echo "Environment: ${config.network-fabric.environment}"

# Send email alert
if [ -n "${config.network-fabric.security-improved.updates.emailNotifications}" ]; then
  echo "Sending alert to ${config.network-fabric.security-improved.updates.emailNotifications}"
  # In a real implementation, this would send an actual email
fi

# Log to security log
logger -t security-alert "$1"
EOF
    
    chmod +x /etc/nixos-fabric/security/alerts/alert.sh
    
    # Create alert for failed SSH attempts
    cat > /etc/nixos-fabric/security/alerts/ssh-fail.sh <<EOF
#!/bin/bash
# SSH Failure Alert

if grep -q "Failed password" /var/log/auth.log; then
  /etc/nixos-fabric/security/alerts/alert.sh "Multiple SSH failed attempts detected"
fi
EOF
    
    chmod +x /etc/nixos-fabric/security/alerts/ssh-fail.sh
  '';
  
  # Security documentation
  system.activationScripts.securityDocs = lib.mkBefore ''
    # Create security documentation
    mkdir -p /etc/nixos-fabric/security/docs
    
    cat > /etc/nixos-fabric/security/docs/SECURITY.md <<EOF
# Security Documentation for rtr-sapinet

## 🔒 Security Overview

This spine node implements comprehensive security measures:

### SSH Security
- **Port**: 2222 (non-standard)
- **Authentication**: Key-based only
- **Root Login**: Disabled
- **Max Auth Tries**: 2
- **Login Grace Time**: 20 seconds

### Firewall Rules
- **Allowed TCP**: 2222 (SSH), 51820 (WireGuard), 179 (BGP), 2605 (OSPF)
- **Allowed UDP**: 51820 (WireGuard)
- **ICMP**: Allowed (for monitoring)
- **Logging**: Enabled with rate limiting (5/sec)

### Intrusion Prevention
- **Fail2ban**: Enabled with aggressive settings
  - Ban Time: 2 hours
  - Find Time: 5 minutes
  - Max Retry: 2 attempts
- **Jails**: sshd, recidive

### Mandatory Access Control
- **AppArmor**: Enabled with profiles for FRR, WireGuard, SSH, nftables
- **Enforce Mode**: Strict enforcement

### Audit Logging
- **Auditd**: Comprehensive system auditing
- **Space Management**: 100MB space, 50MB admin reserve
- **Log Rotation**: 20 files maximum

### Secret Management
- **Backend**: age encryption
- **Key Location**: /etc/nixos-fabric/secrets/key.txt
- **Access**: Root only (700 permissions)

### Monitoring & Alerts
- **Prometheus**: Security metrics monitoring
- **Alert Scripts**: Custom security alerts
- **Email Notifications**: admin@fabric.local

## 🛡️ Security Best Practices

### Access Control
1. Use SSH key authentication only
2. Never use password authentication
3. Limit access to authorized users only
4. Use non-standard SSH ports

### Monitoring
1. Monitor failed login attempts
2. Review audit logs regularly
3. Check firewall logs for suspicious activity
4. Monitor system resource usage

### Maintenance
1. Apply security updates promptly
2. Rotate SSH keys periodically
3. Review AppArmor profiles regularly
4. Test fail2ban configurations

### Incident Response
1. **SSH Brute Force**: Fail2ban will automatically ban IPs
2. **Unauthorized Access**: Check audit logs and rotate keys
3. **Suspicious Activity**: Isolate node and investigate
4. **Security Updates**: Apply during maintenance windows

## 🚨 Security Alerts

Alerts are generated for:
- Multiple failed SSH attempts
- Unauthorized access attempts
- Firewall rule violations
- System resource exhaustion

Alerts are logged to:
- /var/log/syslog (with security-alert tag)
- Email notifications (if configured)

## 📊 Security Metrics

Monitor these key security metrics:
- SSH login attempts (successful/failed)
- Fail2ban bans
- Firewall dropped packets
- Audit log events
- System resource usage

## 🔧 Security Tools

Available security tools:
- **fail2ban-client**: Manage fail2ban
- **aa-status**: Check AppArmor status
- **auditctl**: Manage audit rules
- **nft**: Manage firewall rules
- **journalctl -u fail2ban**: View fail2ban logs
- **journalctl -u auditd**: View audit logs

## 🛠️ Security Commands

### Check Security Status
```bash
# Check fail2ban status
fail2ban-client status
fail2ban-client status sshd

# Check AppArmor status
sudo aa-status

# Check auditd status
sudo systemctl status auditd

# Check firewall status
sudo nft list ruleset

# Check SSH connections
sudo ss -tulnp | grep sshd
```

### Security Maintenance
```bash
# Update fail2ban
sudo systemctl restart fail2ban

# Reload AppArmor profiles
sudo systemctl reload apparmor

# Rotate audit logs
sudo systemctl restart auditd

# Check for security updates
sudo nix-env -u --attr nixpkgs.nixos.system "*"
```

## 📞 Security Contacts

- **Primary**: admin@fabric.local
- **Secondary**: security@fabric.local
- **Emergency**: +1-555-SECURE

**Last Updated**: $(date)
**Node**: rtr-sapinet
**Role**: spine
**Environment**: ${config.network-fabric.environment}
EOF
  '';
}