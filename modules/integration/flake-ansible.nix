{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.flake-ansible;
  ansibleConfigDir = "/etc/nixos-fabric/ansible";
  
  # Default configuration for flake-ansible integration
  defaultConfig = {
    enable = false;
    
    # Flake-specific settings
    flakePath = lib.mkDefault ".";
    flakeTargets = lib.mkDefault [ "rtr-sapinet" "rtr-noisy" ];
    
    # Ansible integration
    ansibleVersion = lib.mkDefault "core-2.15";
    ansiblePlaybooks = lib.mkDefault [
      "setup-common.yml"
      "deploy-fabric.yml"
      "verify-fabric.yml"
    ];
    
    # Deployment options
    deploymentStrategy = lib.mkDefault "local"; # local, remote, hybrid
    remoteBuildHost = lib.mkDefault "localhost";
    
    # Flake deployment settings
    nixBuildOptions = lib.mkDefault {
      maxJobs = 4;
      cores = 2;
      sandbox = true;
    };
    
    # Post-deployment verification
    enableVerification = lib.mkDefault true;
    verificationTimeout = lib.mkDefault 300; # 5 minutes
  };
  
  # Generate Ansible inventory from flake targets
  generateFlakeInventory = lib.stringFromFile {
    file = ./scripts/generate-flake-inventory.sh;
    inherit (cfg) flakeTargets;
  };
  
  # Generate flake deployment script
  flakeDeploymentScript = pkgs.writeScriptBin "flake-deploy" {
    interpreter = "${pkgs.bash}/bin/bash";
    text = ''
      set -euo pipefail
      
      # Flake deployment wrapper for Ansible
      FLAKE_PATH="${cfg.flakePath}"
      TARGET="${1:-${cfg.flakeTargets[0]}}"
      STRATEGY="${cfg.deploymentStrategy}"
      
      echo "Deploying flake target: $TARGET"
      echo "Strategy: $STRATEGY"
      
      case "$STRATEGY" in
        local)
          echo "Local deployment..."
          sudo nixos-rebuild switch --flake "$FLAKE_PATH#$TARGET" \
            --option max-jobs ${toString cfg.nixBuildOptions.maxJobs} \
            --option cores ${toString cfg.nixBuildOptions.cores}
          ;;
        remote)
          echo "Remote deployment..."
          nixos-rebuild switch --flake "$FLAKE_PATH#$TARGET" \
            --target-host root@$TARGET \
            --build-host ${cfg.remoteBuildHost}
          ;;
        hybrid)
          echo "Hybrid deployment..."
          # Build locally, deploy remotely
          nix build "$FLAKE_PATH#nixosConfigurations.$TARGET.config.system.build.toplevel"
          nixos-rebuild switch --flake "$FLAKE_PATH#$TARGET" \
            --target-host root@$TARGET \
            --build-host localhost
          ;;
        *)
          echo "Unknown strategy: $STRATEGY"
          exit 1
          ;;
      esac
    '';
  };
  
  # Generate verification script
  verificationScript = pkgs.writeScriptBin "flake-verify" {
    interpreter = "${pkgs.bash}/bin/bash";
    text = ''
      set -euo pipefail
      
      TARGET="${1:-${cfg.flakeTargets[0]}}"
      TIMEOUT="${toString cfg.verificationTimeout}"
      
      echo "Verifying flake deployment for: $TARGET"
      
      # Basic system checks
      echo "Checking system status..."
      if ! systemctl is-system-running --quiet; then
        echo "System not running properly"
        exit 1
      fi
      
      # Service checks
      echo "Checking critical services..."
      for service in ssh dbus systemd-journald; do
        if ! systemctl is-active --quiet "$service"; then
          echo "Service $service is not active"
          exit 1
        fi
      done
      
      # Network checks
      echo "Checking network connectivity..."
      if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        echo "No network connectivity"
        exit 1
      fi
      
      echo "Verification successful for $TARGET"
    '';
  };
  
  # Generate Ansible playbook for flake deployment
  flakeDeploymentPlaybook = pkgs.writeText "flake-deployment.yml" ''
---
- name: Deploy NixOS Flake
  hosts: "{{ target | default('all') }}"
  become: true
  vars:
    flake_path: "{{ flake_path | default('.') }}"
    flake_target: "{{ inventory_hostname }}"
    deployment_strategy: "{{ deployment_strategy | default('local') }}"
  
  tasks:
    - name: Ensure Nix is installed
      ansible.builtin.package:
        name: nix
        state: present
      when: ansible_os_family == 'Debian'
      
    - name: Enable flakes feature
      ansible.builtin.copy:
        dest: /etc/nix/nix.conf
        content: |
          experimental-features = nix-command flakes
        mode: '0644'
      become: true
      
    - name: Create flake deployment directory
      ansible.builtin.file:
        path: /etc/nixos-flake
        state: directory
        mode: '0755'
      
    - name: Copy flake deployment script
      ansible.builtin.copy:
        src: "{{ playbook_dir }}/flake-deploy"
        dest: /usr/local/bin/flake-deploy
        mode: '0755'
      
    - name: Deploy flake configuration
      ansible.builtin.command: 
        cmd: /usr/local/bin/flake-deploy "{{ flake_target }}"
      register: deploy_result
      changed_when: true
      
    - name: Verify deployment
      ansible.builtin.command: 
        cmd: /usr/local/bin/flake-verify "{{ flake_target }}"
      when: enable_verification | default(true) | bool
      register: verify_result
      changed_when: false
      
    - name: Display deployment results
      ansible.builtin.debug:
        msg: "Flake deployment completed for {{ flake_target }}"
'';

in {
  options.network-fabric.flake-ansible = {
    enable = lib.mkEnableOption "Enable flake-ansible integration";
    
    flakePath = lib.mkOption {
      type = lib.types.str;
      default = defaultConfig.flakePath;
      description = "Path to the flake directory";
    };
    
    flakeTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultConfig.flakeTargets;
      description = "List of flake targets to manage";
    };
    
    ansibleVersion = lib.mkOption {
      type = lib.types.str;
      default = defaultConfig.ansibleVersion;
      description = "Ansible version to use";
    };
    
    ansiblePlaybooks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultConfig.ansiblePlaybooks;
      description = "Ansible playbooks for flake deployment";
    };
    
    deploymentStrategy = lib.mkOption {
      type = lib.types.enum [ "local" "remote" "hybrid" ];
      default = defaultConfig.deploymentStrategy;
      description = "Deployment strategy for flakes";
    };
    
    remoteBuildHost = lib.mkOption {
      type = lib.types.str;
      default = defaultConfig.remoteBuildHost;
      description = "Remote build host for flake deployment";
    };
    
    nixBuildOptions = lib.mkOption {
      type = lib.types.attrs;
      default = defaultConfig.nixBuildOptions;
      description = "Nix build options for flake deployment";
    };
    
    enableVerification = lib.mkOption {
      type = lib.types.bool;
      default = defaultConfig.enableVerification;
      description = "Enable post-deployment verification";
    };
    
    verificationTimeout = lib.mkOption {
      type = lib.types.int;
      default = defaultConfig.verificationTimeout;
      description = "Timeout for post-deployment verification in seconds";
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Install required packages
    environment.systemPackages = with pkgs; [
      ansible
      ansible-lint
      jq
      nix
    ];
    
    # Create directory structure
    systemd.tmpfiles.rules = [
      "d ${ansibleConfigDir}/flake-deploy 0755 root root -"
      "d ${ansibleConfigDir}/scripts 0755 root root -"
      "d ${ansibleConfigDir}/playbooks 0755 root root -"
    ];
    
    # Generate flake deployment configuration
    system.activationScripts.flake-ansible-config = ''
      mkdir -p ${ansibleConfigDir}/flake-deploy
      
      # Copy deployment scripts
      cp ${flakeDeploymentScript} ${ansibleConfigDir}/flake-deploy/
      cp ${verificationScript} ${ansibleConfigDir}/flake-deploy/
      
      # Copy playbook
      cp ${flakeDeploymentPlaybook} ${ansibleConfigDir}/playbooks/flake-deployment.yml
      
      # Generate flake inventory
      ${generateFlakeInventory}
      
      # Create environment configuration
      cat > /etc/profile.d/flake-ansible.sh <<EOF
#!/bin/bash
export FLAKE_ANSIBLE_DIR="${ansibleConfigDir}"
export FLAKE_DEPLOY_SCRIPT="${ansibleConfigDir}/flake-deploy/flake-deploy"
export FLAKE_VERIFY_SCRIPT="${ansibleConfigDir}/flake-deploy/flake-verify"
EOF
    '';
    
    # Generate Ansible configuration for flake deployment
    system.activationScripts.flake-ansible-integration = ''
      cat > ${ansibleConfigDir}/flake-ansible.cfg <<EOF
[defaults]
inventory = ${ansibleConfigDir}/inventory/flake-hosts.ini
remote_user = root
host_key_checking = False
interpreter_python = auto_silent

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false

[ssh_connection]
pipelining = true
EOF
    '';
  };
}
