{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.ansible || {};
  
  # Default Ansible configuration
  defaultAnsibleConfig = {
    enable = false;
    
    # Ansible version
    version = "core-2.15";
    
    # Inventory generation
    generateInventory = lib.mkDefault true;
    
    # Playbooks to run
    playbooks = lib.mkDefault [
      "main.yml"
      "verify-fabric.yml"
    ];
    
    # Ansible configuration options
    configOptions = lib.mkDefault {
      defaults = {
        inventory = "${config.network-fabric.base.configDir}/ansible/inventory/hosts.ini";
        remote_user = "root";
        host_key_checking = false;
        interpreter_python = "auto_silent";
      };
      privilege_escalation = {
        become = true;
        become_method = "sudo";
        become_user = "root";
        become_ask_pass = false;
      };
      ssh_connection = {
        pipelining = true;
      };
    };
    
    # Host variables
    hostVars = lib.mkDefault {};
    
    # Group variables
    groupVars = lib.mkDefault {};
  };
  
  # Generate Ansible configuration file
  ansibleConfigContent = lib.generators.toINI defaultAnsibleConfig.configOptions;
  
  # Generate inventory from NixOS hosts
  generateInventoryScript = lib.stringFromFile {
    file = ./scripts/generate-ansible-inventory.sh;
    inherit (cfg) generateInventory;
  };
  
  # Generate Ansible playbook runner
  ansiblePlaybookRunner = pkgs.writeShellScriptBin "ansible-playbook-runner" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    PLAYBOOK="${cfg.playbooks[0]}"
    TARGET="${1:-all}"
    
    echo "Running Ansible playbook: $PLAYBOOK"
    ${pkgs.ansible}/bin/ansible-playbook \
      --inventory ${defaultAnsibleConfig.configOptions.defaults.inventory} \
      --limit "$TARGET" \
      "${config.network-fabric.base.configDir}/ansible/playbooks/$PLAYBOOK"
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
  };
  
  config = lib.mkIf cfg.enable {
    # Install Ansible
    environment.systemPackages = with pkgs; [
      (ansible_${cfg.version} // ansible)
      ansible-lint
    ];
    
    # Create Ansible directory structure
    systemd.tmpfiles.rules = [
      "d ${defaultAnsibleConfig.configOptions.defaults.inventory} 0755 root root -"
      "d ${config.network-fabric.base.configDir}/ansible/playbooks 0755 root root -"
      "d ${config.network-fabric.base.configDir}/ansible/roles 0755 root root -"
      "d ${config.network-fabric.base.configDir}/ansible/host_vars 0755 root root -"
      "d ${config.network-fabric.base.configDir}/ansible/group_vars 0755 root root -"
    ];
    
    # Generate Ansible configuration
    system.activationScripts.ansible-config = ''
      mkdir -p ${config.network-fabric.base.configDir}/ansible
      echo "${ansibleConfigContent}" > ${config.network-fabric.base.configDir}/ansible/ansible.cfg
    '';
    
    # Generate inventory if enabled
    system.activationScripts.ansible-inventory = lib.optionalString cfg.generateInventory ''
      ${generateInventoryScript}
    '';
    
    # Generate host variables
    system.activationScripts.ansible-host-vars = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (hostName: hostVars:
        ''
          mkdir -p ${config.network-fabric.base.configDir}/ansible/host_vars
          echo "${lib.generators.toYAML hostVars}" > ${config.network-fabric.base.configDir}/ansible/host_vars/${hostName}.yml
        ''
      ) cfg.hostVars
    );
    
    # Generate group variables
    system.activationScripts.ansible-group-vars = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (groupName: groupVars:
        ''
          mkdir -p ${config.network-fabric.base.configDir}/ansible/group_vars
          echo "${lib.generators.toYAML groupVars}" > ${config.network-fabric.base.configDir}/ansible/group_vars/${groupName}.yml
        ''
      ) cfg.groupVars
    );
    
    # Provide Ansible playbook runner
    environment.systemPackages = with pkgs; [ ansiblePlaybookRunner ];
    
    # Ensure Ansible can access NixOS configuration
    users.users.root.openssh.authorizedKeys.keys = [
      "${config.network-fabric.base.users.franck.sshKey}"
    ];
  };
}