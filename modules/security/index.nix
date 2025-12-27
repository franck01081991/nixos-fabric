# Security Module Index

# This file provides an overview of the security module structure
# and serves as the main entry point for security configuration.

# Module Structure:
# - default.nix: Main security module with core options
# - firewall.nix: Firewall configuration and rules
# - hardening.nix: System hardening options
# - ssh.nix: SSH security configuration
# - nftables-advanced.nix: Advanced nftables rules
# - network-security.nix: Network security integration

# Usage:
# Import this module to get all security features:
# imports = [ ./modules/security/init.nix ];

# Or import individual components:
# imports = [
#   ./modules/security/default.nix
#   ./modules/security/firewall.nix
#   # ... other security modules
# ];

{}: {
  # This is an index file - actual configuration is in the imported modules
}