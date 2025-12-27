# NixOS Fabric - Secure Network Infrastructure

## Overview

**NixOS Fabric** is a **pure network-focused** project that provides a **secure, declarative** approach to building and managing network infrastructure using NixOS. This project integrates **routing (FRR), VPN (WireGuard), and comprehensive security** into a unified, reproducible configuration system.

## Key Features

### 🔒 **Security-First Network Design**
- **Integrated Security**: Security is not an afterthought - it's built into every network component
- **BGP Security**: RFC 8205 (BGPsec) compliance with TTL security, prefix filtering, and RPKI validation
- **WireGuard Security**: Rate limiting, interface restriction, and comprehensive firewall rules
- **OSPF Security**: Message digest authentication for secure routing
- **Fail2Ban Integration**: Automatic intrusion prevention for SSH and network services
- **Stateful Firewall**: Advanced nftables rules with logging and rate limiting

### 🌐 **Core Network Components**

#### **FRR (Free Range Routing)**
- **BGP**: Full BGP implementation with security extensions
- **OSPF**: Secure OSPF with authentication support
- **EVPN**: L2VPN EVPN for overlay networks
- **Protocol Security**: Integrated security policies for all routing protocols

#### **WireGuard VPN**
- **Secure Transport**: Encrypted overlay networks with modern cryptography
- **Performance Optimized**: Proper MTU settings and persistent keepalive
- **Rate Limiting**: Protection against DoS attacks
- **Firewall Integration**: Automatic firewall rules for WireGuard interfaces

#### **Unified Security Architecture**
- **Network Security Module**: Centralized security policies that integrate with all network components
- **VLAN Isolation**: Secure network segmentation with explicit inter-VLAN routing rules
- **Default Deny**: Security-by-default posture with explicit allow rules
- **Comprehensive Logging**: Detailed security logging for auditing and compliance

## Architecture

```
┌───────────────────────────────────────────────────────┐
│                 NixOS Fabric Architecture               │
├───────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   FRR       │    │  WireGuard  │    │  Security   │  │
│  │  (Routing)  │    │   (VPN)     │    │  (Firewall) │  │
│  └─────────────┘    └─────────────┘    └─────────────┘  │
│          │               │                   │           │
│          ▼               ▼                   ▼           │
│  ┌───────────────────────────────────────────────────┐  │
│  │         Network Security Integration           │  │
│  │  (Unified policies, VLAN isolation, logging)   │  │
│  └───────────────────────────────────────────────────┘  │
│                                                       │
└───────────────────────────────────────────────────────┘
```

## Getting Started

### Prerequisites
- NixOS system
- Basic understanding of networking concepts
- Familiarity with Nix language

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-repo/nixos-fabric.git
   cd nixos-fabric
   ```

2. **Review the example configuration:**
   ```bash
   less examples/network-security-config.nix
   ```

3. **Deploy to a test system:**
   ```bash
   sudo nixos-rebuild switch --flake .#your-hostname
   ```

## Configuration Examples

### Basic Secure Fabric

```nix
{
  network-fabric = {
    enable = true;
    name = "my-secure-fabric";
    
    security = {
      enable = true;
      ssh = {
        port = 2222;
        passwordAuthentication = false;
      };
      firewallEnable = true;
      fail2banEnable = true;
    };
  };

  network-fabric.frr = {
    enable = true;
    security = {
      bgpTtlSecurity = true;
      ospfAuthentication = true;
    };
  };

  network-fabric.wireguard = {
    enable = true;
    security = {
      rateLimit = "1000/m";
      mtu = 1420;
    };
  };
}
```

### Advanced Security Policies

```nix
network-fabric.network-security = {
  enable = true;
  
  policies = {
    defaultDeny = true;
    vlanIsolation = true;
    sshRateLimit = "5/minute";
    icmpRateLimit = "3/sec";
  };
  
  protocolSecurity = {
    bgp = {
      ttlSecurity = true;
      maxPrefix = 500;
      rpkiValidation = true;
    };
    
    wireguard = {
      rateLimiting = "500/m";
      interfaceRestriction = true;
    };
  };
};
```

## Security Features

### BGP Security (RFC 8205)
- **TTL Security**: Prevents CPU exhaustion attacks
- **Prefix Filtering**: Limits number of accepted prefixes
- **RPKI Validation**: Route origin validation
- **Max Prefix Limits**: Protection against route leaks

### WireGuard Security
- **Rate Limiting**: Protection against DoS attacks
- **Interface Restriction**: Limits WireGuard to specific interfaces
- **MTU Optimization**: Prevents fragmentation issues
- **Persistent Keepalive**: Maintains stable connections

### Network Security
- **Default Deny Policy**: Security-by-default posture
- **VLAN Isolation**: Prevents VLAN hopping attacks
- **Stateful Firewall**: Comprehensive connection tracking
- **Protocol-Specific Rules**: Tailored security for each protocol

## Deployment Patterns

### Spine-Leaf Architecture
```nix
# Spine Router Configuration
network-fabric.frr.bgp = {
  as = 65000;
  neighbors = {
    leaf1 = { ip = "10.255.0.1"; as = 65001; };
    leaf2 = { ip = "10.255.0.2"; as = 65002; };
  };
};

# Leaf Router Configuration  
network-fabric.frr.bgp = {
  as = 65001;
  neighbors = {
    spine1 = { ip = "10.255.0.100"; as = 65000; };
  };
};
```

### Secure Overlay Network
```nix
network-fabric.wireguard = {
  enable = true;
  peers = {
    peer1 = {
      publicKey = "...";
      endpoint = "peer1.example.com:51820";
      allowedIPs = [ "10.255.0.2/32" ];
    };
  };
  
  security = {
    rateLimit = "1000/m";
    interfaceRestriction = true;
  };
};
```

## Best Practices

### Security Recommendations
1. **Use Non-Standard SSH Ports**: Reduce automated attack surface
2. **Enable Rate Limiting**: Protect against brute force attacks
3. **Use RPKI Validation**: Prevent BGP hijacking
4. **Enable OSPF Authentication**: Secure routing protocol exchanges
5. **Restrict WireGuard Interfaces**: Limit VPN access to management interfaces
6. **Enable Fail2Ban**: Automatic intrusion prevention
7. **Use VLAN Isolation**: Prevent lateral movement in case of compromise

### Performance Optimization
1. **Proper MTU Settings**: Avoid fragmentation (1420 for WireGuard)
2. **Persistent Keepalive**: Maintain stable WireGuard connections
3. **BGP TTL Security**: Prevent CPU exhaustion without affecting performance
4. **Stateful Firewall**: Maintain connection tracking for legitimate traffic

## Documentation

- **Module Reference**: Detailed documentation for each module
- **Security Guide**: Comprehensive security configuration guide
- **Deployment Patterns**: Recommended architectures and configurations
- **Troubleshooting**: Common issues and solutions

## Contributing

Contributions are welcome! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please open an issue on GitHub or contact the maintainers.

---

**NixOS Fabric** - Building Secure Networks with NixOS

*Security is not a feature, it's a requirement.*