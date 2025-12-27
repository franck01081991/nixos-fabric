{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.ansible;
  baseCfg = config.network-fabric.base;
  
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
        inventory = "${baseCfg.configDir}/ansible/inventory/hosts.ini";
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
  ansiblePlaybookRunner = pkgs.writeScriptBin "ansible-playbook-runner" {
    interpreter = "${pkgs.bash}/bin/bash";
    text = ''
      set -euo pipefail
      
      PLAYBOOK="${cfg.playbooks[0]}"
    # Set target with default value using conditional
    if [ $# -eq 0 ]; then
      TARGET="all"
    else
      TARGET="$1"
    fi
      
      echo "Running Ansible playbook: $PLAYBOOK"
      ${pkgs.ansible}/bin/ansible-playbook \
        --inventory ${defaultAnsibleConfig.configOptions.defaults.inventory} \
        --limit "$TARGET" \
        "${baseCfg.configDir}/ansible/playbooks/$PLAYBOOK"
    '';
  };

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
      ansible
      ansible-lint
    ];
    
    # Create Ansible directory structure
    systemd.tmpfiles.rules = [
      "d ${defaultAnsibleConfig.configOptions.defaults.inventory} 0755 root root -"
      "d ${baseCfg.configDir}/ansible/playbooks 0755 root root -"
      "d ${baseCfg.configDir}/ansible/roles 0755 root root -"
      "d ${baseCfg.configDir}/ansible/host_vars 0755 root root -"
      "d ${baseCfg.configDir}/ansible/group_vars 0755 root root -"
    ];
    
    # Generate Ansible configuration
    system.activationScripts.ansible-config = ''
      mkdir -p ${baseCfg.configDir}/ansible
      echo "${ansibleConfigContent}" > ${baseCfg.configDir}/ansible/ansible.cfg
    '';
    
    # Generate inventory if enabled
    system.activationScripts.ansible-inventory = lib.optionalString cfg.generateInventory ''
      ${generateInventoryScript}
    '';
    
    # Generate host variables
    system.activationScripts.ansible-host-vars = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (hostName: hostVars:
        ''
          mkdir -p ${baseCfg.configDir}/ansible/host_vars
          echo "${lib.generators.toYAML hostVars}" > ${baseCfg.configDir}/ansible/host_vars/${hostName}.yml
        ''
      ) cfg.hostVars
    );
    
    # Generate group variables
    system.activationScripts.ansible-group-vars = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (groupName: groupVars:
        ''
          mkdir -p ${baseCfg.configDir}/ansible/group_vars
          echo "${lib.generators.toYAML groupVars}" > ${baseCfg.configDir}/ansible/group_vars/${groupName}.yml
        ''
      ) cfg.groupVars
    );
    
    
    # Ensure Ansible can access NixOS configuration
    users.users.root.openssh.authorizedKeys.keys = [
      "${config.network-fabric.base.users.franck.sshKey}"
    ];
  };
}
