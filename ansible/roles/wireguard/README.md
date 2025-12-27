# WireGuard Role

This role configures WireGuard for NixOS Fabric nodes.

## Role Variables

### Required Variables

- `wg_private_key`: WireGuard private key (generated if not provided).
- `wg_public_key`: WireGuard public key (generated if not provided).

### Dynamic Variables

The following variables are dynamically set by the role:

- `wg_ip_address`: WireGuard IP address (e.g., `10.255.0.1/24`).
- `wg_port`: WireGuard listen port (default: `51820`).
- `wg_mtu`: WireGuard MTU (default: `1420`).
- `wg_peers`: List of WireGuard peers with the following attributes:
  - `public_key`: Peer public key.
  - `allowed_ips`: List of allowed IPs for the peer.
  - `endpoint`: Peer endpoint (optional).
  - `persistent_keepalive`: Persistent keepalive interval (optional, default: `25`).
- `wireguard_peers`: List of WireGuard peers with the following attributes:
  - `name`: Peer name.
  - `public_key`: Peer public key.
  - `allowed_ips`: List of allowed IPs for the peer.
  - `endpoint`: Peer endpoint (optional).

## Example Playbook

```yaml
- name: Configure WireGuard
  hosts: all
  roles:
    - wireguard
  vars:
    wg_ip_address: "10.255.0.1/24"
    wg_peers:
      - public_key: "peer_public_key"
        allowed_ips: ["10.255.0.11/32", "10.254.0.11/32"]
        endpoint: "45.90.162.251:51820"
        persistent_keepalive: 25
    wireguard_peers:
      - name: "rtr-noisy"
        public_key: "peer_public_key"
        allowed_ips: ["10.255.0.11/32", "10.254.0.11/32"]
        endpoint: "45.90.162.251"
```

## Templates

- `wg0.conf.j2`: WireGuard interface configuration.
- `wireguard-secrets.j2`: WireGuard secrets configuration.
- `wireguard.nix.j2`: WireGuard Nix configuration.

## Dependencies

None.

## License

MIT

## Author Information

Franck