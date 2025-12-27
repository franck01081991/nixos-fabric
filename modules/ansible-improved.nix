{ config, lib, pkgs, ... }:

# Improved Ansible Integration Module
# This module provides deep integration between NixOS Fabric and Ansible

let
  cfg = config.network-fabric.ansible;
  fabricConfig = config.network-fabric;
  ansibleConfigDir = fabricConfig.configDir + "/ansible";

  # Generate environment file for Ansible with fabric integration
  ansibleEnvContent = ''
    export ANSIBLE_CONFIG="${ansibleConfigDir}/ansible.cfg"
    export ANSIBLE_INVENTORY="${ansibleConfigDir}/inventory/hosts.ini"
    export ANSIBLE_ROLES_PATH="${ansibleConfigDir}/roles"
    export NIXOS_FABRIC_ANSIBLE_DIR="${ansibleConfigDir}"
    export NIXOS_FABRIC_CONFIG_DIR="${fabricConfig.configDir}"
    export NIXOS_FABRIC_NAME="${fabricConfig.name}"
    export NIXOS_FABRIC_ENVIRONMENT="${fabricConfig.environment}"
  '';

  # Default Ansible configuration with fabric awareness
  defaultAnsibleConfig = {
    enable = false;
    
    # Ansible version
    version = "core-2.15";
    
    # Inventory generation
    generateInventory = lib.mkDefault true;
    
    # Playbooks to run
    playbooks = lib.mkDefault [
      "setup-common.yml"
      "main.yml"
      "verify-fabric.yml"
      "deploy-roles.yml"  # New role deployment playbook
    ];
    
    # Ansible configuration options
    configOptions = lib.mkDefault {
      defaults = {
        inventory = "${ansibleConfigDir}/inventory/hosts.ini";
        remote_user = "root";
        host_key_checking = false;
        interpreter_python = "auto_silent";
        
        # Fabric-specific defaults
        module_name = "nixos";
        strategy = "linear";
        strategy_plugins = "${ansibleConfigDir}/plugins/strategy";
      };
      privilege_escalation = {
        become = true;
        become_method = "sudo";
        become_user = "root";
        become_ask_pass = false;
      };
      ssh_connection = {
        pipelining = true;
        scp_if_ssh = true;
      };
    };
    
    # Host variables
    hostVars = lib.mkDefault { };
    
    # Group variables
    groupVars = lib.mkDefault { };
    
    # Role-specific variables
    roleVars = lib.mkDefault { };
    
    # Fabric integration settings
    fabricIntegration = lib.mkDefault {
      autoDetectRoles = true;
      generateRolePlaybooks = true;
      syncFrequency = "daily";
    };
  };

  # Generate Ansible configuration file with fabric integration
  ansibleConfigContent = lib.generators.toINI (defaultAnsibleConfig.configOptions // {
    defaults = defaultAnsibleConfig.configOptions.defaults // {
      # Add fabric-specific inventory plugins
      inventory_plugins = "${ansibleConfigDir}/plugins/inventory";
      lookup_plugins = "${ansibleConfigDir}/plugins/lookup";
    };
  });

  # Generate inventory from NixOS hosts with role detection
  generateInventoryScript = ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    echo "Generating Ansible inventory from NixOS Fabric configuration..."
    
    # Create inventory directory
    mkdir -p ${ansibleConfigDir}/inventory
    
    # Generate hosts.ini with role detection
    cat > ${ansibleConfigDir}/inventory/hosts.ini <<'EOF'
[all:vars]
ansible_user=root
ansible_become=true
ansible_python_interpreter=/run/current-system/sw/bin/python3

[spine:children]
${lib.concatStringsSep "\n" (lib.mapAttrsToList (hostname: hostConfig: 
  if hostConfig.network-fabric.roles.spine.enable then hostname else ""
) config.nixosConfigurations)}

[leaf:children]
${lib.concatStringsSep "\n" (lib.mapAttrsToList (hostname: hostConfig: 
  if hostConfig.network-fabric.roles.leaf.enable then hostname else ""
) config.nixosConfigurations)}

[hybrid:children]
${lib.concatStringsSep "\n" (lib.mapAttrsToList (hostname: hostConfig: 
  if hostConfig.network-fabric.roles.spine.enable && hostConfig.network-fabric.roles.leaf.enable 
  then hostname else ""
) config.nixosConfigurations)}

[fabric:children]
spine
leaf
hybrid

[fabric:vars]
fabric_name=${fabricConfig.name}
fabric_environment=${fabricConfig.environment}
EOF
    
    # Generate individual host entries
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (hostname: hostConfig: 
      let
        networking = hostConfig.networking or { };
        fabric = hostConfig.network-fabric or { };
        spineRole = fabric.roles.spine or { };
        leafRole = fabric.roles.leaf or { };
        
        # Determine if this is a hybrid node
        isHybrid = spineRole.enable && leafRole.enable;
        
        # Get IP addresses
        ipv4 = lib.concatStringsSep " " (lib.mapAttrsToList (ifname: ifconfig: 
          lib.concatStringsSep " " (lib.mapAttrsToList (addrIdx: addrConfig: 
            addrConfig.address
          ) ifconfig.ipv4.addresses)
        ) networking.interfaces);
        
        ipv6 = lib.concatStringsSep " " (lib.mapAttrsToList (ifname: ifconfig: 
          lib.concatStringsSep " " (lib.mapAttrsToList (addrIdx: addrConfig: 
            addrConfig.address
          ) ifconfig.ipv6.addresses)
        ) networking.interfaces);
      in 
      ''
        echo "" >> ${ansibleConfigDir}/inventory/hosts.ini
        echo "[${hostname}]" >> ${ansibleConfigDir}/inventory/hosts.ini
        echo "${hostname} ansible_host=${lib.head (lib.splitString " " ipv4)} ipv4='${ipv4}' ipv6='${ipv6}'" >> ${ansibleConfigDir}/inventory/hosts.ini
        echo "" >> ${ansibleConfigDir}/inventory/hosts.ini
        echo "[${hostname}:vars]" >> ${ansibleConfigDir}/inventory/hosts.ini
        echo "fabric_role_spine=${lib.toString spineRole.enable}" >> ${ansibleConfigDir}/inventory/hosts.ini
        echo "fabric_role_leaf=${lib.toString leafRole.enable}" >> ${ansibleConfigDir}/inventory/hosts.ini
        echo "fabric_role_hybrid=${lib.toString isHybrid}" >> ${ansibleConfigDir}/inventory/hosts.ini
        echo "fabric_spine_role_id=${spineRole.roleId or ""}" >> ${ansibleConfigDir}/inventory/hosts.ini
        echo "fabric_leaf_role_id=${leafRole.roleId or ""}" >> ${ansibleConfigDir}/inventory/hosts.ini
      ''
    ) config.nixosConfigurations)}
    
    echo "Ansible inventory generation completed"
  '';

  # Generate role-specific playbooks
  generateRolePlaybooks = ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    echo "Generating role-specific Ansible playbooks..."
    
    # Create playbooks directory
    mkdir -p ${ansibleConfigDir}/playbooks
    
    # Generate spine role playbook
    cat > ${ansibleConfigDir}/playbooks/deploy-spine.yml <<'EOF'
---
- name: Deploy Spine Role Configuration
  hosts: spine
  become: true
  
  tasks:
    - name: Ensure spine configuration directory exists
      file:
        path: /etc/nixos-fabric/spine
        state: directory
        mode: '0755'
    
    - name: Configure spine routing
      template:
        src: templates/frr-spine.conf.j2
        dest: /etc/frr/frr-spine.conf
        owner: frr
        group: frr
        mode: '0644'
      notify: restart frr
    
    - name: Configure spine WireGuard
      template:
        src: templates/wireguard-spine.conf.j2
        dest: /etc/wireguard/wg-spine.conf
        owner: root
        group: root
        mode: '0600'
      notify: restart wireguard
    
  handlers:
    - name: restart frr
      service:
        name: frr
        state: restarted
    
    - name: restart wireguard
      service:
        name: wg-quick@wg-spine
        state: restarted
EOF
    
    # Generate leaf role playbook
    cat > ${ansibleConfigDir}/playbooks/deploy-leaf.yml <<'EOF'
---
- name: Deploy Leaf Role Configuration
  hosts: leaf
  become: true
  
  tasks:
    - name: Ensure leaf configuration directory exists
      file:
        path: /etc/nixos-fabric/leaf
        state: directory
        mode: '0755'
    
    - name: Configure leaf routing with EVPN
      template:
        src: templates/frr-leaf-evpn.conf.j2
        dest: /etc/frr/frr-leaf.conf
        owner: frr
        group: frr
        mode: '0644'
      notify: restart frr
    
    - name: Configure leaf VXLAN
      template:
        src: templates/vxlan-leaf.conf.j2
        dest: /etc/systemd/network/vxlan-leaf.netdev
        owner: root
        group: root
        mode: '0644'
      notify: restart systemd-networkd
    
    - name: Configure leaf WireGuard
      template:
        src: templates/wireguard-leaf.conf.j2
        dest: /etc/wireguard/wg-leaf.conf
        owner: root
        group: root
        mode: '0600'
      notify: restart wireguard
    
  handlers:
    - name: restart frr
      service:
        name: frr
        state: restarted
    
    - name: restart systemd-networkd
      service:
        name: systemd-networkd
        state: restarted
    
    - name: restart wireguard
      service:
        name: wg-quick@wg-leaf
        state: restarted
EOF
    
    # Generate hybrid role playbook
    cat > ${ansibleConfigDir}/playbooks/deploy-hybrid.yml <<'EOF'
---
- name: Deploy Hybrid Role Configuration
  hosts: hybrid
  become: true
  
  tasks:
    - name: Ensure hybrid configuration directory exists
      file:
        path: /etc/nixos-fabric/hybrid
        state: directory
        mode: '0755'
    
    - name: Configure hybrid routing (spine + leaf)
      template:
        src: templates/frr-hybrid.conf.j2
        dest: /etc/frr/frr-hybrid.conf
        owner: frr
        group: frr
        mode: '0644'
      notify: restart frr
    
    - name: Configure hybrid VXLAN
      template:
        src: templates/vxlan-hybrid.conf.j2
        dest: /etc/systemd/network/vxlan-hybrid.netdev
        owner: root
        group: root
        mode: '0644'
      notify: restart systemd-networkd
    
    - name: Configure hybrid WireGuard
      template:
        src: templates/wireguard-hybrid.conf.j2
        dest: /etc/wireguard/wg-hybrid.conf
        owner: root
        group: root
        mode: '0600'
      notify: restart wireguard
    
  handlers:
    - name: restart frr
      service:
        name: frr
        state: restarted
    
    - name: restart systemd-networkd
      service:
        name: systemd-networkd
        state: restarted
    
    - name: restart wireguard
      service:
        name: wg-quick@wg-hybrid
        state: restarted
EOF
    
    echo "Role-specific playbooks generation completed"
  '';

  # Generate Ansible playbook runner with fabric awareness
  ansiblePlaybookRunner = pkgs.writeScriptBin "ansible-playbook-runner" {
    interpreter = "${pkgs.bash}/bin/bash";
    text = ''
      set -euo pipefail
      
      # Source fabric environment
      if [ -f "${fabricConfig.configDir}/environment" ]; then
        source "${fabricConfig.configDir}/environment"
      fi
      
      # Display help
      if [ "$#" -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Usage: $0 [playbook] [target] [options]"
        echo ""
        echo "Available playbooks:"
        ${lib.concatStringsSep "\n" (lib.map (playbook: 
          echo "  - ${playbook}"
        ) defaultAnsibleConfig.playbooks)}
        echo ""
        echo "Examples:"
        echo "  $0 main.yml all                    # Run main playbook on all hosts"
        echo "  $0 deploy-spine.yml spine          # Deploy spine role"
        echo "  $0 deploy-leaf.yml leaf            # Deploy leaf role"
        echo "  $0 deploy-hybrid.yml hybrid        # Deploy hybrid role"
        exit 0
      fi
      
      PLAYBOOK="$1"
      TARGET="${2:-all}"
      shift 2
      
      echo "🚀 Running Ansible playbook: $PLAYBOOK"
      echo "🎯 Target: $TARGET"
      echo "🏗️ Fabric: $FABRIC_NAME ($FABRIC_ENVIRONMENT)"
      
      ${pkgs.ansible}/bin/ansible-playbook \
        --inventory ${defaultAnsibleConfig.configOptions.defaults.inventory} \
        --limit "$TARGET" \
        "$@" \
        "${ansibleConfigDir}/playbooks/$PLAYBOOK"
    '';
  };

  # Generate fabric-specific Ansible variables
  generateFabricVars = ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    echo "Generating fabric-specific Ansible variables..."
    
    # Create variables directory
    mkdir -p ${ansibleConfigDir}/group_vars
    
    # Generate fabric variables
    cat > ${ansibleConfigDir}/group_vars/all.yml <<EOF
---
# Fabric-wide variables
fabric_name: "${fabricConfig.name}"
fabric_environment: "${fabricConfig.environment}"
fabric_config_dir: "${fabricConfig.configDir}"
fabric_ansible_dir: "${ansibleConfigDir}"

# Network configuration
fabric_network_domain: "${fabricConfig.network.domain}"
fabric_network_dns_servers: ${lib.generators.toYAML fabricConfig.network.dnsServers}
fabric_network_ipv4_prefix: "${fabricConfig.network.ipv4.prefix}"
fabric_network_ipv4_gateway: "${fabricConfig.network.ipv4.gateway}"
fabric_network_ipv6_prefix: "${fabricConfig.network.ipv6.prefix}"
fabric_network_ipv6_gateway: "${fabricConfig.network.ipv6.gateway}"

# Security configuration
fabric_security_ssh_port: ${lib.toString fabricConfig.security.sshPort}
fabric_security_fail2ban_enable: ${lib.toString fabricConfig.security.fail2banEnable}
fabric_security_firewall_enable: ${lib.toString fabricConfig.security.firewallEnable}

# Role configuration
fabric_roles:
  ${lib.generators.toYAML fabricConfig.roles}
EOF
    
    # Generate spine-specific variables
    cat > ${ansibleConfigDir}/group_vars/spine.yml <<EOF
---
# Spine role variables
spine_role_enabled: true
spine_role_description: "Core routing role"
spine_routing_protocol: "OSPF+BGP"
spine_topology: "full-mesh"
EOF
    
    # Generate leaf-specific variables
    cat > ${ansibleConfigDir}/group_vars/leaf.yml <<EOF
---
# Leaf role variables
leaf_role_enabled: true
leaf_role_description: "Edge routing role"
leaf_routing_protocol: "BGP+EVPN"
leaf_topology: "point-to-spine"
EOF
    
    # Generate hybrid-specific variables
    cat > ${ansibleConfigDir}/group_vars/hybrid.yml <<EOF
---
# Hybrid role variables
hybrid_role_enabled: true
hybrid_role_description: "Combined spine+leaf role"
hybrid_routing_protocols: ["OSPF", "BGP", "EVPN"]
hybrid_topology: "mixed"
EOF
    
    echo "Fabric variables generation completed"
  '';

  # Generate Ansible configuration directory structure
  ansibleDirectoryStructure = ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    echo "Creating Ansible directory structure..."
    
    # Create main directories
    mkdir -p ${ansibleConfigDir}/{inventory,playbooks,roles,templates,plugins,files}
    mkdir -p ${ansibleConfigDir}/plugins/{inventory,lookup,strategy}
    mkdir -p ${ansibleConfigDir}/roles/{base,spine,leaf,hybrid}/{tasks,handlers,templates,vars,files}
    
    # Create basic role structure
    for role in base spine leaf hybrid; do
      mkdir -p ${ansibleConfigDir}/roles/${role}/{tasks,handlers,templates,vars,files,meta}
      
      # Create main tasks file
      cat > ${ansibleConfigDir}/roles/${role}/tasks/main.yml <<EOF
---
# ${role} role tasks
- name: Include ${role} configuration
  include_tasks: configure.yml
  when: ${role}_role_enabled | default(false)
EOF
      
      # Create configure tasks file
      cat > ${ansibleConfigDir}/roles/${role}/tasks/configure.yml <<EOF
---
# Configuration tasks for ${role} role
- name: Ensure ${role} configuration directory exists
  file:
    path: /etc/nixos-fabric/${role}
    state: directory
    mode: '0755'
  
- name: Configure ${role} specific settings
  template:
    src: config.j2
    dest: /etc/nixos-fabric/${role}/config
    mode: '0644'
EOF
      
      # Create templates directory
      mkdir -p ${ansibleConfigDir}/roles/${role}/templates
      cat > ${ansibleConfigDir}/roles/${role}/templates/config.j2 <<EOF
# ${role} Role Configuration
# Generated by Ansible
ROLE_NAME="${role}"
ROLE_ENABLED="true"
EOF
      
      # Create vars directory
      mkdir -p ${ansibleConfigDir}/roles/${role}/vars
      cat > ${ansibleConfigDir}/roles/${role}/vars/main.yml <<EOF
---
# ${role} role variables
${role}_config_dir: "/etc/nixos-fabric/${role}"
${role}_enabled: true
EOF
      
      # Create meta directory
      mkdir -p ${ansibleConfigDir}/roles/${role}/meta
      cat > ${ansibleConfigDir}/roles/${role}/meta/main.yml <<EOF
---
dependencies: []
EOF
    done
    
    echo "Ansible directory structure created"
  '';

  # Generate Ansible verification playbook
  ansibleVerificationPlaybook = ''
---
- name: Verify NixOS Fabric Configuration
  hosts: all
  become: true
  gather_facts: true
  
  tasks:
    - name: Check fabric configuration directory
      stat:
        path: "${fabricConfig.configDir}"
      register: fabric_config_dir
      
    - name: Verify fabric configuration exists
      assert:
        that: fabric_config_dir.stat.exists
        msg: "Fabric configuration directory not found"
      
    - name: Check fabric environment file
      stat:
        path: "${fabricConfig.configDir}/environment"
      register: fabric_env_file
      
    - name: Verify fabric environment exists
      assert:
        that: fabric_env_file.stat.exists
        msg: "Fabric environment file not found"
      
    - name: Check role configurations
      stat:
        path: "${fabricConfig.configDir}/roles"
      register: fabric_roles_dir
      
    - name: Verify role configurations exist
      assert:
        that: fabric_roles_dir.stat.exists
        msg: "Fabric roles directory not found"
      
    - name: Check spine role (if enabled)
      stat:
        path: "${fabricConfig.configDir}/spine"
      register: spine_role_dir
      when: fabric_roles.spine.enable | default(false)
      
    - name: Verify spine role exists
      assert:
        that: spine_role_dir.stat.exists
        msg: "Spine role directory not found"
      when: fabric_roles.spine.enable | default(false)
      
    - name: Check leaf role (if enabled)
      stat:
        path: "${fabricConfig.configDir}/leaf"
      register: leaf_role_dir
      when: fabric_roles.leaf.enable | default(false)
      
    - name: Verify leaf role exists
      assert:
        that: leaf_role_dir.stat.exists
        msg: "Leaf role directory not found"
      when: fabric_roles.leaf.enable | default(false)
      
    - name: Check hybrid role (if enabled)
      stat:
        path: "${fabricConfig.configDir}/hybrid"
      register: hybrid_role_dir
      when: fabric_roles.spine.enable | default(false) and fabric_roles.leaf.enable | default(false)
      
    - name: Verify hybrid role exists
      assert:
        that: hybrid_role_dir.stat.exists
        msg: "Hybrid role directory not found"
      when: fabric_roles.spine.enable | default(false) and fabric_roles.leaf.enable | default(false)
      
    - name: Check FRR service
      service:
        name: frr
        state: started
        enabled: true
      register: frr_service
      ignore_errors: true
      
    - name: Verify FRR is running
      assert:
        that: frr_service.state == "started"
        msg: "FRR service is not running"
      when: fabric_roles.spine.enable | default(false) or fabric_roles.leaf.enable | default(false)
      
    - name: Check WireGuard service
      service:
        name: wg-quick@wg0
        state: started
        enabled: true
      register: wireguard_service
      ignore_errors: true
      
    - name: Verify WireGuard is running
      assert:
        that: wireguard_service.state == "started"
        msg: "WireGuard service is not running"
      when: fabric_roles.spine.enable | default(false) or fabric_roles.leaf.enable | default(false)
      
    - name: Display fabric verification summary
      debug:
        msg: |
          🎉 NixOS Fabric Verification Summary
          ==================================
          Fabric Name: {{ fabric_name }}
          Environment: {{ fabric_environment }}
          
          Roles Detected:
          - Spine: {{ fabric_roles.spine.enable | default(false) | ternary('Enabled', 'Disabled') }}
          - Leaf: {{ fabric_roles.leaf.enable | default(false) | ternary('Enabled', 'Disabled') }}
          - Hybrid: {{ (fabric_roles.spine.enable | default(false) and fabric_roles.leaf.enable | default(false)) | ternary('Enabled', 'Disabled') }}
          
          Services Status:
          - FRR: {{ frr_service.state | default('Not applicable') }}
          - WireGuard: {{ wireguard_service.state | default('Not applicable') }}
          
          Configuration: ✅ Verified
EOF
  '';

in {
  options.network-fabric.ansible = {
    enable = lib.mkEnableOption "Enable Ansible integration";
    
    version = lib.mkOption {
      type = lib.types.str;
      default = defaultAnsibleConfig.version;
      description = "Ansible version to install";
    };
    
    generateInventory = lib.mkOption {
      type = lib.types.bool;
      default = defaultAnsibleConfig.generateInventory;
      description = "Automatically generate Ansible inventory from NixOS hosts";
    };
    
    playbooks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultAnsibleConfig.playbooks;
      description = "List of Ansible playbooks to make available";
    };
    
    configOptions = lib.mkOption {
      type = lib.types.attrs;
      default = defaultAnsibleConfig.configOptions;
      description = "Ansible configuration options";
    };
    
    hostVars = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = defaultAnsibleConfig.hostVars;
      description = "Host-specific Ansible variables";
    };
    
    groupVars = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = defaultAnsibleConfig.groupVars;
      description = "Group-specific Ansible variables";
    };
    
    roleVars = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = defaultAnsibleConfig.roleVars;
      description = "Role-specific Ansible variables";
    };
    
    fabricIntegration = lib.mkOption {
      type = lib.types.submodule {
        options = {
          autoDetectRoles = lib.mkOption {
            type = lib.types.bool;
            default = defaultAnsibleConfig.fabricIntegration.autoDetectRoles;
            description = "Automatically detect roles from NixOS configurations";
          };
          generateRolePlaybooks = lib.mkOption {
            type = lib.types.bool;
            default = defaultAnsibleConfig.fabricIntegration.generateRolePlaybooks;
            description = "Generate role-specific playbooks";
          };
          syncFrequency = lib.mkOption {
            type = lib.types.str;
            default = defaultAnsibleConfig.fabricIntegration.syncFrequency;
            description = "Frequency for syncing Ansible configurations";
          };
        };
      };
      default = defaultAnsibleConfig.fabricIntegration;
      description = "Fabric integration settings";
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Install Ansible and dependencies
    environment.systemPackages = with pkgs; [
      ansible
      ansible-lint
      jmespath
      python3
      python3Packages.ansible
      python3Packages.pyyaml
      python3Packages.jinja2
      python3Packages.jmespath
    ];
    
    # Create Ansible directory structure
    systemd.tmpfiles.rules = [
      "d ${ansibleConfigDir} 0755 root root -"
      "d ${ansibleConfigDir}/inventory 0755 root root -"
      "d ${ansibleConfigDir}/playbooks 0755 root root -"
      "d ${ansibleConfigDir}/roles 0755 root root -"
      "d ${ansibleConfigDir}/templates 0755 root root -"
      "d ${ansibleConfigDir}/plugins 0755 root root -"
      "d ${ansibleConfigDir}/files 0755 root root -"
      "d ${ansibleConfigDir}/host_vars 0755 root root -"
      "d ${ansibleConfigDir}/group_vars 0755 root root -"
    ];
    
    # Generate Ansible configuration
    system.activationScripts.ansible-config = ''
      mkdir -p ${ansibleConfigDir}
      echo "${ansibleConfigContent}" > ${ansibleConfigDir}/ansible.cfg
      echo "${ansibleEnvContent}" > /etc/profile.d/ansible.sh
      
      # Create Ansible directory structure
      ${ansibleDirectoryStructure}
      
      # Generate fabric variables
      ${generateFabricVars}
      
      # Generate role-specific playbooks if enabled
      ${lib.optionalString cfg.fabricIntegration.generateRolePlaybooks generateRolePlaybooks}
      
      # Create verification playbook
      echo "${ansibleVerificationPlaybook}" > ${ansibleConfigDir}/playbooks/verify-fabric.yml
    '';
    
    # Generate inventory if enabled
    system.activationScripts.ansible-inventory = lib.optionalString cfg.generateInventory ''
      ${generateInventoryScript}
    '';
    
    # Generate host variables
    system.activationScripts.ansible-host-vars = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (hostName: hostVars:
        ''
          mkdir -p ${ansibleConfigDir}/host_vars
          echo "${lib.generators.toYAML hostVars}" > ${ansibleConfigDir}/host_vars/${hostName}.yml
        ''
      ) cfg.hostVars
    );
    
    # Generate group variables
    system.activationScripts.ansible-group-vars = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (groupName: groupVars:
        ''
          mkdir -p ${ansibleConfigDir}/group_vars
          echo "${lib.generators.toYAML groupVars}" > ${ansibleConfigDir}/group_vars/${groupName}.yml
        ''
      ) cfg.groupVars
    );
    
    # Generate role variables
    system.activationScripts.ansible-role-vars = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (roleName: roleVars:
        ''
          mkdir -p ${ansibleConfigDir}/role_vars
          echo "${lib.generators.toYAML roleVars}" > ${ansibleConfigDir}/role_vars/${roleName}.yml
        ''
      ) cfg.roleVars
    );
    
    # Create Ansible playbook runner
    environment.systemPackages = [ ansiblePlaybookRunner ];
    
    # Ensure Ansible can access NixOS configuration
    users.users.root.openssh.authorizedKeys.keys = [
      "${config.network-fabric.base.users.franck.sshKey}"
    ];
    
    # Create systemd service for Ansible configuration sync
    systemd.services.nixos-fabric-ansible-sync = {
      description = "NixOS Fabric Ansible Configuration Sync";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          echo "Synchronizing Ansible configuration..."
          ${ansibleDirectoryStructure}
          ${generateInventoryScript}
          ${generateFabricVars}
          ${lib.optionalString cfg.fabricIntegration.generateRolePlaybooks generateRolePlaybooks}
          echo "Ansible configuration sync completed"
        '';
      };
      
      # Create timer for regular sync
      systemd.timers.nixos-fabric-ansible-sync = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.fabricIntegration.syncFrequency;
          Persistent = true;
        };
      };
    };
  };
}