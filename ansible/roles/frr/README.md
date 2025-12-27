# FRR Role

This role configures FRR (Free Range Routing) for NixOS Fabric nodes.

## Role Variables

### Required Variables

None.

### Dynamic Variables

The following variables are dynamically set by the role:

- `bgp_as`: BGP autonomous system number (default: `65001`).
- `bgp_router_id`: BGP router ID (e.g., `10.254.0.1`).
- `bgp_cluster_id`: BGP cluster ID (optional, e.g., `10.254.0.11`).
- `bgp_neighbors`: List of BGP neighbors with the following attributes:
  - `ip`: Neighbor IP address.
  - `as`: Neighbor autonomous system number.
  - `ebgp_multihop`: EBGP multihop value (optional, default: `5`).
- `bgp_networks`: List of BGP networks (e.g., `["10.254.0.1/32"]`).
- `bgp_evpn_enabled`: Enable BGP EVPN (optional, default: `false`).
- `ospf_router_id`: OSPF router ID (e.g., `10.254.0.1`).
- `ospf_networks`: List of OSPF networks (e.g., `["10.254.0.1/32", "10.255.0.0/24"]`).
- `ospf_area`: OSPF area (optional, default: `0`).
- `ospf_passive_interfaces`: List of OSPF passive interfaces (optional, default: `["wgtransport"]`).

## Example Playbook

```yaml
- name: Configure FRR
  hosts: all
  roles:
    - frr
  vars:
    bgp_as: 65001
    bgp_router_id: "10.254.0.1"
    bgp_cluster_id: "10.254.0.11"
    bgp_neighbors:
      - ip: "10.254.0.11"
        as: 65001
        ebgp_multihop: 5
    bgp_networks: ["10.254.0.1/32"]
    bgp_evpn_enabled: false
    ospf_router_id: "10.254.0.1"
    ospf_networks: ["10.254.0.1/32", "10.255.0.0/24"]
    ospf_area: 0
    ospf_passive_interfaces: ["wgtransport"]
```

## Templates

- `frr.nix.j2`: FRR Nix configuration.

## Dependencies

None.

## License

MIT

## Author Information

Franck