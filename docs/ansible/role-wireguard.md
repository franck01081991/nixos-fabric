# Ansible Role: wireguard

## Tasks

```yaml
# WireGuard configuration for NixOS fabric
---
- name: Generate WireGuard private key
  ansible.builtin.command: wg genkey
  register: wg_private_key
  changed_when: false
  when: wg_private_key_file is not defined or not wg_private_key_file.stat.exists
  
- name: Save WireGuard private key
  ansible.builtin.copy:
    dest: "/etc/wireguard/{{ inventory_hostname }}.key"
    content: "{{ wg_private_key.stdout }}"
    mode: '0600'
  when: wg_private_key is defined and wg_private_key.stdout
  
- name: Generate WireGuard public key
  ansible.builtin.command: "echo {{ wg_private_key.stdout }} | wg pubkey"
  register: wg_public_key
  changed_when: false
  when: wg_private_key is defined and wg_private_key.stdout
  
- name: Create WireGuard secrets file
  ansible.builtin.template:
    src: wireguard-secrets.j2
    dest: /etc/nixos/secrets/wireguard.nix
    mode: '0600'
  
- name: Configure WireGuard interface
  ansible.builtin.template:
    src: wg0.conf.j2
    dest: /etc/wireguard/wgtransport.conf
    mode: '0600'
  
- name: Enable WireGuard service
  ansible.builtin.systemd:
    name: wg-quick@wgtransport
    enabled: true
    state: started
```

## Usage

```yaml
- hosts: all
  roles:
    - wireguard
```

