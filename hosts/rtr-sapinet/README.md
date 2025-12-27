# rtr-sapinet-config - Pure Spine Node Configuration

This repository contains the complete NixOS configuration for a pure spine node in the hybrid fabric network.

## 📦 Repository Structure

```
.
├── base-variables.nix      # Base network variables
├── default.nix             # Main configuration entry point
├── hardware-configuration.nix  # Hardware-specific settings
├── role-variables.nix      # Spine role configuration
└── variables.nix           # Detailed network configuration
```

## 🚀 Usage

### Standalone Usage

```bash
# Clone this repository
git clone https://github.com/franck01081991/rtr-sapinet-config.git
cd rtr-sapinet-config

# Build the configuration
nix build .#nixosConfigurations.rtr-sapinet.config.system.build.toplevel

# Deploy to a machine
sudo nixos-rebuild switch --flake .#rtr-sapinet
```

### Integration with Main Fabric Repository

This repository is designed to work with the main [nixos-fabric](https://github.com/franck01081991/nixos-fabric) repository:

```bash
# Clone the main repository
git clone https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric

# Add this as a submodule (optional)
git submodule add https://github.com/franck01081991/rtr-sapinet-config.git external/rtr-sapinet-config

# Or copy the configuration
cp -r rtr-sapinet-config/* hosts/rtr-sapinet/
```

## 🔧 Configuration Details

### Spine Role
- **Primary Role**: Core routing (spine)
- **Routing Protocols**: OSPF + BGP (IPv4 + IPv6)
- **WireGuard**: Full mesh topology
- **Security**: Fail2ban, AppArmor, Auditd

### Network Configuration
- **Hostname**: rtr-sapinet
- **Domain**: fabric.local
- **WireGuard IP**: 10.255.0.1/24, fd42:1337:255::1/64
- **BGP AS**: 65000
- **OSPF Area**: 0

## 📖 Documentation

See the main [nixos-fabric documentation](https://github.com/franck01081991/nixos-fabric) for:
- Complete architecture overview
- Deployment instructions
- Troubleshooting guide
- Role system documentation

## 🔄 Update Process

```bash
# Update from main repository
git pull origin master

# Or sync with main fabric
git fetch && git merge origin/master
```

## 🛡️ Security

- Regularly update NixOS: `sudo nixos-rebuild switch --upgrade`
- Monitor security advisories
- Review WireGuard peer configurations
- Audit BGP/OSPF neighbors

## 🤝 Contributing

Contributions are welcome! Please open issues or pull requests in the main [nixos-fabric](https://github.com/franck01081991/nixos-fabric) repository.