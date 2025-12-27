# Deployment Guide for NixOS Fabric

This guide will help you deploy the NixOS Fabric project. It covers the deployment process from start to finish, including setting up the environment, configuring the nodes, and running the playbooks.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setting Up the Environment](#setting-up-the-environment)
- [Configuring the Nodes](#configuring-the-nodes)
- [Running the Playbooks](#running-the-playbooks)
- [Verifying the Deployment](#verifying-the-deployment)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Prerequisites

Before you start, ensure you have the following:

- NixOS or Nix package manager installed
- Git
- Basic knowledge of Nix and Ansible
- Access to the nodes you want to deploy

## Setting Up the Environment

### Clone the Repository

1. Clone the repository:

```bash
git clone https://github.com/franck01081991/nixos-fabric.git
cd nixos-fabric
```

2. Initialize the submodules:

```bash
git submodule update --init --recursive
```

### Install the Required Dependencies

1. Install the required dependencies:

```bash
nix-shell
```

2. Install Ansible:

```bash
nix-env -iA nixos.ansible
```

## Configuring the Nodes

### Configure the Inventory

1. Edit the inventory file to include your nodes:

```bash
vim ansible/inventory/hosts.ini
```

2. Add your nodes to the inventory file:

```ini
[spine]
rtr-sapinet ansible_host=192.168.1.1

[leaf]
rtr-noisy ansible_host=192.168.1.2

[fabric:children]
spine
leaf

[fabric:vars]
ansible_user=root
ansible_become=true
```

### Configure the Host Variables

1. Edit the host variables for each node:

```bash
vim ansible/host_vars/rtr-sapinet.yml
vim ansible/host_vars/rtr-noisy.yml
```

2. Add the required variables for each node:

```yaml
# Example host variables for rtr-sapinet
wg_ip_address: "10.255.0.1/24"
wg_port: 51820
wg_mtu: 1420
wg_peers:
  - public_key: "peer_public_key"
    allowed_ips: ["10.255.0.11/32", "10.254.0.11/32"]
    endpoint: "45.90.162.251:51820"
    persistent_keepalive: 25
```

### Configure the Group Variables

1. Edit the group variables for each group:

```bash
vim ansible/group_vars/spine.yml
vim ansible/group_vars/leaf.yml
```

2. Add the required variables for each group:

```yaml
# Example group variables for spine
bgp_as: 65001
bgp_router_id: "10.254.0.1"
bgp_cluster_id: "10.254.0.11"
bgp_neighbors:
  - ip: "10.254.0.11"
    as: 65001
    ebgp_multihop: 5
bgp_networks: ["10.254.0.1/32"]
bgp_evpn_enabled: false
```

## Running the Playbooks

### Run the Common Setup Playbook

1. Run the common setup playbook to set up the common configuration on all nodes:

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/setup-common.yml
```

### Run the Main Playbook

1. Run the main playbook to configure the nodes:

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/main.yml
```

### Run the Verification Playbook

1. Run the verification playbook to verify the deployment:

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/verify-fabric.yml
```

## Verifying the Deployment

### Verify the WireGuard Configuration

1. Verify the WireGuard configuration on each node:

```bash
sudo wg show
```

2. Verify the WireGuard interface:

```bash
ip addr show wgtransport
```

### Verify the FRR Configuration

1. Verify the FRR configuration on each node:

```bash
sudo vtysh
show running-config
```

2. Verify the BGP neighbors:

```bash
show ip bgp neighbors
```

### Verify the Monitoring Configuration

1. Verify the Prometheus configuration:

```bash
sudo systemctl status prometheus
```

2. Verify the Grafana configuration:

```bash
sudo systemctl status grafana
```

## Troubleshooting

### Common Issues

1. **Connection Issues**: Ensure that the nodes are accessible and that the SSH configuration is correct.

2. **Permission Issues**: Ensure that the Ansible user has the necessary permissions to run the playbooks.

3. **Configuration Issues**: Ensure that the configuration files are correct and that the variables are properly defined.

### Debugging

1. **Run the Playbooks with Verbose Output**:

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/main.yml -v
```

2. **Check the Logs**:

```bash
sudo journalctl -u wireguard
sudo journalctl -u frr
sudo journalctl -u prometheus
sudo journalctl -u grafana
```

## Best Practices

### Configuration Best Practices

- Keep the configuration files organized and well-documented.
- Use meaningful variable names and comments.
- Test the configuration locally before deploying to production.

### Deployment Best Practices

- Use a staging environment to test the deployment before deploying to production.
- Use version control to track changes to the configuration files.
- Use Ansible tags to run specific parts of the playbooks.

### Monitoring Best Practices

- Monitor the deployment to ensure that the nodes are running correctly.
- Use Prometheus and Grafana to monitor the performance and health of the nodes.
- Set up alerts to notify you of any issues.

## Conclusion

This guide has covered the deployment process for the NixOS Fabric project. By following these steps, you should be able to deploy the project successfully. If you encounter any issues, please refer to the troubleshooting section or open an issue on GitHub.

## License

This guide is licensed under the MIT License.

## Thank You

Thank you for using NixOS Fabric! Your feedback and contributions are greatly appreciated.
