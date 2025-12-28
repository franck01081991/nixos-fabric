# WireGuard Setup and Verification Guide

## Key Generation

On each machine, generate WireGuard keys:

```bash
# On rtr-sapinet
sudo mkdir -p /etc/wireguard
wg genkey | sudo tee /etc/wireguard/rtr-sapinet.key | wg pubkey | sudo tee /etc/wireguard/rtr-sapinet.pub

# On rtr-noisy
sudo mkdir -p /etc/wireguard
wg genkey | sudo tee /etc/wireguard/rtr-noisy.key | wg pubkey | sudo tee /etc/wireguard/rtr-noisy.pub
```

## Configuration Update

Replace the placeholder public keys in the configuration files:

1. In `hosts/rtr-sapinet/variables.nix`:
   - Replace `__RTR_NOISY_PUB__` with the content of `/etc/wireguard/rtr-noisy.pub` from rtr-noisy

2. In `hosts/rtr-noisy/variables.nix`:
   - Replace `__RTR_SAPINET_PUB__` with the content of `/etc/wireguard/rtr-sapinet.pub` from rtr-sapinet

## Deployment

Apply the configuration on both machines:

```bash
# On both machines
sudo nixos-rebuild switch
```

## Verification

### WireGuard Connection

```bash
# Check WireGuard interface
wg show

# Test connectivity over WireGuard
ping 10.255.0.1    # From rtr-noisy to rtr-sapinet
ping 10.255.0.11   # From rtr-sapinet to rtr-noisy
```

### BGP Session

```bash
# Check BGP session status
vtysh -c "show bgp summary"

# Verify BGP routes
vtysh -c "show bgp neighbors 10.254.0.11"
vtysh -c "show bgp neighbors 10.254.0.1"
```

### Bridge and VLAN Configuration

```bash
# Check bridge VLAN configuration
bridge vlan show

# Verify bridge interfaces
ip a show br0.10
ip a show br0.20
ip a show br0.30
ip a show br0.40
```

### DHCP Testing

Connect a device to one of the LAN ports (enp2s0-enp6s0) in untagged mode. The device should receive an IP address in the 10.10.10.0/24 range via DHCP.

## Troubleshooting

### MTU Issues

If you experience connectivity issues, the MTU is set to 1420 for WireGuard over Internet. You can test with:

```bash
ping -M do -s 1400 10.255.0.1
```

### VLAN Configuration

If VLANs are not working correctly, check the systemd service logs:

```bash
journalctl -u vlan-port-flags
journalctl -u vxlan-port-flags
```

### BGP Debugging

```bash
vtysh -c "show bgp neighbors"
vtysh -c "show ip bgp"
```