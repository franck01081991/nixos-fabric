#!/usr/bin/env bash

# Script to create a standardized Ansible role structure
# Usage: ./scripts/create-ansible-role.sh role_name [description]

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 role_name [description]"
  exit 1
fi

ROLE_NAME=$1
DESCRIPTION=${2:-"Ansible role for $ROLE_NAME"}
ROLE_DIR="ansible/roles/$ROLE_NAME"

# Check if role already exists
if [ -d "$ROLE_DIR" ]; then
  echo "❌ Role '$ROLE_NAME' already exists!"
  exit 1
fi

echo "🛠️  Creating Ansible role: $ROLE_NAME"

# Create role directory structure
mkdir -p "$ROLE_DIR"
mkdir -p "$ROLE_DIR/tasks" "$ROLE_DIR/handlers" "$ROLE_DIR/templates" "$ROLE_DIR/vars" "$ROLE_DIR/defaults" "$ROLE_DIR/meta" "$ROLE_DIR/files" "$ROLE_DIR/tests"

# Create meta/main.yml
cat > "$ROLE_DIR/meta/main.yml" <<EOF
---
galaxy_info:
  author: NixOS Fabric Team
  description: $DESCRIPTION
  company: NixOS Fabric
  license: MIT
  min_ansible_version: 2.15
  platforms:
    - name: Linux
      versions:
        - all
  galaxy_tags:
    - nixos
    - fabric
    - $ROLE_NAME

dependencies: []
EOF

# Create tasks/main.yml
cat > "$ROLE_DIR/tasks/main.yml" <<EOF
---
# tasks file for $ROLE_NAME

- name: Include OS-specific variables
  ansible.builtin.include_vars: "{{ item }}"
  with_first_found:
    - files:
        - "{{ ansible_distribution }}-{{ ansible_distribution_major_version }}.yml"
        - "{{ ansible_distribution }}.yml"
        - "{{ ansible_os_family }}.yml"
      paths:
        - "{{ role_path }}/vars"
      skip: true

- name: Ensure $ROLE_NAME directories exist
  ansible.builtin.file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
    owner: root
    group: root
  loop: "{{ ${ROLE_NAME}_directories | default([]) }}"
  when: ${ROLE_NAME}_directories is defined

- name: Configure $ROLE_NAME
  ansible.builtin.template:
    src: "{{ item.src }}"
    dest: "{{ item.dest }}"
    mode: "{{ item.mode | default('0644') }}"
    owner: "{{ item.owner | default('root') }}"
    group: "{{ item.group | default('root') }}"
  loop: "{{ ${ROLE_NAME}_templates | default([]) }}"
  when: ${ROLE_NAME}_templates is defined
  notify: restart ${ROLE_NAME}

- name: Ensure $ROLE_NAME services are running
  ansible.builtin.service:
    name: "{{ item }}"
    state: started
    enabled: true
  loop: "{{ ${ROLE_NAME}_services | default([]) }}"
  when: ${ROLE_NAME}_services is defined
EOF

# Create handlers/main.yml
cat > "$ROLE_DIR/handlers/main.yml" <<EOF
---
# handlers file for $ROLE_NAME

- name: restart $ROLE_NAME
  ansible.builtin.service:
    name: "{{ ${ROLE_NAME}_service_name | default('$ROLE_NAME') }}"
    state: restarted
  listen: restart $ROLE_NAME

- name: reload $ROLE_NAME
  ansible.builtin.service:
    name: "{{ ${ROLE_NAME}_service_name | default('$ROLE_NAME') }}"
    state: reloaded
  listen: reload $ROLE_NAME
EOF

# Create defaults/main.yml
cat > "$ROLE_DIR/defaults/main.yml" <<EOF
---
# defaults file for $ROLE_NAME

# Directories to create
${ROLE_NAME}_directories: []

# Templates to deploy
${ROLE_NAME}_templates: []

# Services to manage
${ROLE_NAME}_services: []

# Service name
${ROLE_NAME}_service_name: "$ROLE_NAME"

# Configuration options
${ROLE_NAME}_config: {}
EOF

# Create README.md
cat > "$ROLE_DIR/README.md" <<EOF
# Ansible Role: $ROLE_NAME

## Description

$DESCRIPTION

## Requirements

- Ansible >= 2.15
- NixOS (recommended)

## Role Variables

### Default Variables

See `defaults/main.yml` for all available variables.

### Required Variables

None

## Dependencies

None

## Example Playbook

```yaml
- hosts: all
  roles:
    - $ROLE_NAME
```

## Usage

### Basic Usage

```yaml
- hosts: all
  roles:
    - role: $ROLE_NAME
      vars:
        ${ROLE_NAME}_directories:
          - /etc/$ROLE_NAME
          - /var/lib/$ROLE_NAME
```

### Advanced Usage

```yaml
- hosts: all
  roles:
    - role: $ROLE_NAME
      vars:
        ${ROLE_NAME}_templates:
          - src: config.j2
            dest: /etc/$ROLE_NAME/config.yaml
            mode: '0640'
        ${ROLE_NAME}_services:
          - $ROLE_NAME
```

## Testing

Run the test suite:

```bash
ansible-playbook tests/test.yml
```

## License

MIT

## Author Information

NixOS Fabric Team
EOF

# Create tests/test.yml
cat > "$ROLE_DIR/tests/test.yml" <<EOF
---
# Test playbook for $ROLE_NAME role

- name: Test $ROLE_NAME role
  hosts: localhost
  connection: local
  become: true
  
  roles:
    - $ROLE_NAME
  
  tasks:
    - name: Verify $ROLE_NAME directories exist
      ansible.builtin.stat:
        path: "{{ item }}"
      loop: "{{ ${ROLE_NAME}_directories | default([]) }}"
      when: ${ROLE_NAME}_directories is defined
      register: dir_stats
      
    - name: Assert directories were created
      ansible.builtin.assert:
        that: item.stat.exists and item.stat.isdir
        quiet: true
      loop: "{{ dir_stats.results }}"
      when: ${ROLE_NAME}_directories is defined
EOF

echo "✅ Ansible role '$ROLE_NAME' created successfully!"
echo "📁 Location: $ROLE_DIR"
echo "💡 Edit the role variables in defaults/main.yml and add your tasks in tasks/main.yml"
