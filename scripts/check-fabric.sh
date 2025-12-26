#!/usr/bin/env bash
set -euo pipefail

# Fabric Connectivity Check Script
# Run this on any host to verify the fabric status

echo "=== Fabric Connectivity Check ==="
echo "Host: $(hostname)"
echo "Date: $(date)"
echo

# Check WireGuard
echo "--- WireGuard Status ---"
if ip link show wgtransport > /dev/null 2>&1; then
    echo "✓ wgtransport interface exists"
    sudo wg show wgtransport || echo "WireGuard interface exists but no peers"
else
    echo "✗ wgtransport interface not found"
fi
echo

# Check routes
echo "--- Routing Table ---"
ip route | grep -E "(10.255|10.254)" || echo "No fabric routes found"
echo

# Check BGP (if FRR is running)
echo "--- BGP Status ---"
if systemctl is-active --quiet frr; then
    echo "✓ FRR service is running"
    if command -v vtysh > /dev/null 2>&1; then
        echo "BGP Summary:"
        vtysh -c "show ip bgp summary" || echo "BGP not configured"
    else
        echo "vtysh not available"
    fi
else
    echo "✗ FRR service not running"
fi
echo

# Check OSPF (if FRR is running)
echo "--- OSPF Status ---"
if systemctl is-active --quiet frr; then
    if command -v vtysh > /dev/null 2>&1; then
        echo "OSPF Neighbors:"
        vtysh -c "show ip ospf neighbor" || echo "OSPF not configured"
    fi
else
    echo "FRR not running, OSPF not available"
fi
echo

# Check connectivity to known peers
echo "--- Peer Connectivity ---"
PEERS=("10.255.0.1" "10.255.0.2" "10.254.0.1" "10.254.0.2")
for peer in "${PEERS[@]}"; do
    if ping -c 1 -W 1 "$peer" > /dev/null 2>&1; then
        echo "✓ $peer is reachable"
    else
        echo "✗ $peer is not reachable"
    fi
done
echo

# Check firewall
echo "--- Firewall Status ---"
if systemctl is-active --quiet nftables; then
    echo "✓ nftables service is running"
    echo "Rules loaded: $(sudo nft list ruleset | wc -l) lines"
else
    echo "✗ nftables service not running"
fi
echo

echo "=== Check Complete ==="
