# Network Fabric Roles System - Usage Guide

This document explains how to use the roles system for scalable spine/leaf fabric configuration.

## Overview

The roles system provides a structured way to configure network nodes as either **spine** or **leaf** roles in a spine-leaf fabric architecture. This makes the configuration:

- **Reproducible**: Consistent configuration across similar nodes
- **Scalable**: Easy to add new nodes with predefined roles
- **Maintainable**: Role-specific configuration is centralized

## Available Roles

### Spine Role

Spine nodes form the core of the fabric and provide high-speed interconnectivity between leaf nodes.

### Leaf Role

Leaf nodes connect to spine nodes and provide access to servers, services, and external networks.

## Configuration Structure

Each host should be configured with its appropriate role in its `role-variables.nix` file.

## Example Configurations

### Spine Node Configuration

For a spine node (e.g., `vm-sapinet`):

```nix
{ config, lib, pkgs, ... }:

{
  # Spine role configuration
  network-fabric.roles.spine = {
    enable = true;
    roleId = "spine1";
    
    # Override default spine networking
    networking = {
      hostName = "vm-sapinet";
      domain = "fabric.local";
    };
    
    # Additional spine-specific configuration can go here
    # frr = { ... };
    # wireguard = { ... };
  };
}
```

### Leaf Node Configuration

For a leaf node (e.g., `rtr-noisy`):

```nix
{ config, lib, pkgs, ... }:

{
  # Leaf role configuration
  network-fabric.roles.leaf = {
    enable = true;
    roleId = "leaf1";
    
    # Override default leaf networking
    networking = {
      hostName = "rtr-noisy";
      domain = "fabric.local";
    };
    
    # Additional leaf-specific configuration can go here
    # frr = { ... };
    # wireguard = { ... };
  };
}
```

## Adding New Nodes

To add a new node to the fabric:

1. **Create a new host directory**:
   ```bash
   mkdir -p hosts/new-node
   ```

2. **Create hardware configuration**:
   ```bash
   # Generate hardware configuration for the new node
   nixos-generate-config --dir hosts/new-node
   ```

3. **Create role configuration**:
   - Copy an existing `role-variables.nix` as a template
   - Modify the role (`spine` or `leaf`) and node-specific settings

4. **Add to flake.nix**:
   ```nix
   nixosConfigurations = {
     "vm-sapinet" = mkHost { system = "x86_64-linux"; hostname = "vm-sapinet"; };
     "rtr-noisy" = mkHost { system = "x86_64-linux"; hostname = "rtr-noisy"; };
     "new-node" = mkHost { system = "x86_64-linux"; hostname = "new-node"; };  # Add this line
   };
   ```

## Role Options Reference

### Common Options (both roles)

- `enable`: Boolean to enable the role
- `roleId`: String identifier for the node (e.g., "spine1", "leaf2")
- `networking`: Networking configuration overrides
- `frr`: FRR/BGP configuration (future)
- `wireguard`: WireGuard configuration (future)

### Spine-Specific Defaults

- Default hostname: "spine-node"
- Default domain: "fabric.local"
- Default nameservers: ["1.1.1.1" "8.8.8.8"]

### Leaf-Specific Defaults

- Default hostname: "leaf-node"
- Default domain: "fabric.local"
- Default nameservers: ["1.1.1.1" "8.8.8.8"]

## Best Practices

1. **Use role defaults**: Start with the role defaults and only override what's necessary
2. **Consistent naming**: Use consistent roleId patterns (e.g., spine1, spine2, leaf1, leaf2)
3. **Separation of concerns**: Keep role-specific configuration in role modules, node-specific in host configs
4. **Document changes**: Add comments explaining why you override specific settings

## Future Enhancements

The roles system will be enhanced to include:

- Automatic FRR/BGP configuration based on role
- WireGuard peer management
- Service discovery and DNS integration
- Monitoring and metrics configuration

## Troubleshooting

If you encounter issues:

1. **Check role activation**: Ensure `enable = true` in your role configuration
2. **Verify imports**: Make sure `role-variables.nix` is imported in your host's `default.nix`
3. **Review flake checks**: Run `nix flake check` to validate your configuration
4. **Check logs**: Look at system logs for service-specific issues

## Example: Adding a Second Spine Node

```nix
# hosts/spine2/role-variables.nix
{ config, lib, pkgs, ... }:

{
  network-fabric.roles.spine = {
    enable = true;
    roleId = "spine2";
    
    networking = {
      hostName = "spine2";
      domain = "fabric.local";
      # Override IP addresses for this specific spine
      interfaces.eth0.ipv4.addresses = [{
        address = "10.0.2.2";
        prefixLength = 24;
      }];
    };
  };
}
```

This system provides a solid foundation for building scalable, maintainable network fabrics using NixOS.