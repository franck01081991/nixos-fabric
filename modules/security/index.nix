# Security Module Index
# 
# This file provides an overview of the security module structure
# and serves as a reference for available security features.

# Security Module Structure:
# 
# modules/security/
# ├── init.nix          # Main entry point
# ├── index.nix         # Module documentation and reference
# ├── default.nix       # Core security module
# └── README.md        # Comprehensive documentation

# Available Security Features:
# 
# 1. SSH Hardening
#    - Custom ports
#    - Authentication restrictions
#    - Connection limits
#    - Security banners
#
# 2. Firewall Configuration
#    - TCP/UDP port management
#    - ICMP control
#    - Rate limiting
#    - Logging
#
# 3. Intrusion Detection (Fail2ban)
#    - Configurable jails
#    - Ban policies
#    - Time-based restrictions
#
# 4. Mandatory Access Control (AppArmor)
#    - Service profiles
#    - Enforcement modes
#    - Policy management
#
# 5. System Auditing (Auditd)
#    - Comprehensive logging
#    - Disk space management
#    - Alert configurations
#
# 6. Secret Management
#    - Secure storage
#    - Access control
#    - Encryption backends
#
# 7. Security Updates
#    - Scheduled checks
#    - Notification system
#    - Update policies
#
# 8. System Hardening
#    - Kernel parameters
#    - Filesystem restrictions
#    - Network hardening

# Usage Example:
# 
# { config, lib, pkgs, ... }:
# {
#   imports = [
#     ../modules/security/init.nix  # Import security module
#   ];
#
#   network-fabric.security = {
#     enable = true;
#     ssh.port = 2222;
#     firewall.allowedTCP = [ 2222 80 443 ];
#     # ... other security configurations
#   };
# }

# Configuration Reference:
# 
# All security configurations are available under:
# network-fabric.security.{ssh, firewall, fail2ban, apparmor, auditd, secrets, updates, hardening}

# See modules/security/README.md for detailed documentation