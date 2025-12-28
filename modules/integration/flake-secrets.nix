{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.flake-secrets;
  secretsDir = "/etc/nixos-fabric/secrets";
  
  # Default configuration for flake secrets management
  defaultConfig = {
    enable = false;
    
    # Secret storage backend
    backend = lib.mkDefault "file"; # file, vault, sops, age
    
    # File backend settings
    fileBackend = lib.mkDefault {
      secretsPath = "./secrets";
      permissions = "0600";
      owner = "root";
      group = "root";
    };
    
    # Age encryption settings
    ageBackend = lib.mkDefault {
      enable = false;
      publicKeys = [];
      privateKeyPath = "";
    };
    
    # Sops settings
    sopsBackend = lib.mkDefault {
      enable = false;
      configPath = "";
    };
    
    # Vault settings
    vaultBackend = lib.mkDefault {
      enable = false;
      address = "";
      tokenPath = "";
    };
    
    # Secret definitions
    secrets = lib.mkDefault {};
    
    # Flake-specific secrets
    flakeSecrets = lib.mkDefault {
      wireguard = lib.mkDefault {
        enable = false;
        privateKeyPath = "";
        publicKeyPath = "";
      };
      ssh = lib.mkDefault {
        enable = false;
        privateKeyPath = "";
        publicKeyPath = "";
      };
      apiTokens = lib.mkDefault {};
    };
    
    # Deployment settings
    deploySecrets = lib.mkDefault true;
    secretPermissions = lib.mkDefault "0600";
  };
  
  # Generate secret deployment script
  secretDeploymentScript = pkgs.writeScriptBin "deploy-secrets" {
    interpreter = "${pkgs.bash}/bin/bash";
    text = ''
      set -euo pipefail
      
      SECRETS_DIR="${secretsDir}"
      BACKEND="${cfg.backend}"
      
      echo "Deploying secrets using backend: $BACKEND"
      
      # Create secrets directory
      mkdir -p "$SECRETS_DIR"
      chmod 0700 "$SECRETS_DIR"
      
      case "$BACKEND" in
        file)
          echo "Using file backend..."
          # Copy secrets from file backend
          if [ -d "${cfg.fileBackend.secretsPath}" ]; then
            cp -r "${cfg.fileBackend.secretsPath}"/* "$SECRETS_DIR/"
            chmod -R ${cfg.fileBackend.permissions} "$SECRETS_DIR/"
            chown -R ${cfg.fileBackend.owner}:${cfg.fileBackend.group} "$SECRETS_DIR/"
          else
            echo "File backend path not found: ${cfg.fileBackend.secretsPath}"
            exit 1
          fi
          ;;
        age)
          echo "Using age backend..."
          if [ "${cfg.ageBackend.enable}" = true ]; then
            # Decrypt age-encrypted secrets
            if command -v age &>/dev/null; then
              for secret_file in "${cfg.fileBackend.secretsPath}"/*.age; do
                if [ -f "$secret_file" ]; then
                  output_file="$SECRETS_DIR/$(basename "$secret_file" .age)"
                  age --decrypt -i "${cfg.ageBackend.privateKeyPath}" "$secret_file" > "$output_file"
                  chmod ${cfg.secretPermissions} "$output_file"
                fi
              done
            else
              echo "age command not found"
              exit 1
            fi
          else
            echo "Age backend not enabled"
            exit 1
          fi
          ;;
        sops)
          echo "Using sops backend..."
          if [ "${cfg.sopsBackend.enable}" = true ]; then
            if command -v sops &>/dev/null; then
              for secret_file in "${cfg.fileBackend.secretsPath}"/*.yaml "${cfg.fileBackend.secretsPath}"/*.json; do
                if [ -f "$secret_file" ]; then
                  output_file="$SECRETS_DIR/$(basename "$secret_file")"
                  sops --decrypt "$secret_file" > "$output_file"
                  chmod ${cfg.secretPermissions} "$output_file"
                fi
              done
            else
              echo "sops command not found"
              exit 1
            fi
          else
            echo "Sops backend not enabled"
            exit 1
          fi
          ;;
        vault)
          echo "Using vault backend..."
          if [ "${cfg.vaultBackend.enable}" = true ]; then
            if command -v vault &>/dev/null; then
              # Export vault token
              export VAULT_ADDR="${cfg.vaultBackend.address}"
              export VAULT_TOKEN="$(cat "${cfg.vaultBackend.tokenPath}")"
              
              # Fetch secrets from vault
              for secret_path in "${cfg.secrets}"; do
                secret_name=$(basename "$secret_path")
                vault kv get -field=value "$secret_path" > "$SECRETS_DIR/$secret_name"
                chmod ${cfg.secretPermissions} "$SECRETS_DIR/$secret_name"
              done
            else
              echo "vault command not found"
              exit 1
            fi
          else
            echo "Vault backend not enabled"
            exit 1
          fi
          ;;
        *)
          echo "Unknown backend: $BACKEND"
          exit 1
          ;;
      esac
      
      echo "Secrets deployed successfully to $SECRETS_DIR"
    '';
  };
  
  # Generate secret verification script
  secretVerificationScript = pkgs.writeScriptBin "verify-secrets" {
    interpreter = "${pkgs.bash}/bin/bash";
    text = ''
      set -euo pipefail
      
      SECRETS_DIR="${secretsDir}"
      
      echo "Verifying secrets deployment..."
      
      # Check if secrets directory exists
      if [ ! -d "$SECRETS_DIR" ]; then
        echo "Secrets directory not found: $SECRETS_DIR"
        exit 1
      fi
      
      # Check permissions
      if [ "$(stat -c %a "$SECRETS_DIR")" != "700" ]; then
        echo "Incorrect permissions on secrets directory"
        exit 1
      fi
      
      # Check for required secrets
      REQUIRED_SECRETS=(
        "wireguard/private.key"
        "wireguard/public.key"
        "ssh/id_ed25519"
        "ssh/id_ed25519.pub"
      )
      
      for secret in "${REQUIRED_SECRETS[@]}"; do
        if [ ! -f "$SECRETS_DIR/$secret" ]; then
          echo "Required secret not found: $secret"
          exit 1
        fi
        
        if [ "$(stat -c %a "$SECRETS_DIR/$secret")" != "${cfg.secretPermissions}" ]; then
          echo "Incorrect permissions on secret: $secret"
          exit 1
        fi
      done
      
      echo "Secrets verification successful"
    '';
  };
  
  # Generate secret rotation script
  secretRotationScript = pkgs.writeScriptBin "rotate-secrets" {
    interpreter = "${pkgs.bash}/bin/bash";
    text = ''
      set -euo pipefail
      
      SECRETS_DIR="${secretsDir}"
      BACKEND="${cfg.backend}"
      
      echo "Rotating secrets using backend: $BACKEND"
      
      case "$BACKEND" in
        file)
          echo "Rotating secrets for file backend..."
          
          # Rotate WireGuard keys
          if [ "${cfg.flakeSecrets.wireguard.enable}" = true ]; then
            echo "Rotating WireGuard keys..."
            mkdir -p "$SECRETS_DIR/wireguard"
            wg genkey | tee "$SECRETS_DIR/wireguard/private.key" | wg pubkey > "$SECRETS_DIR/wireguard/public.key"
            chmod ${cfg.secretPermissions} "$SECRETS_DIR/wireguard/private.key" "$SECRETS_DIR/wireguard/public.key"
          fi
          
          # Rotate SSH keys
          if [ "${cfg.flakeSecrets.ssh.enable}" = true ]; then
            echo "Rotating SSH keys..."
            mkdir -p "$SECRETS_DIR/ssh"
            ssh-keygen -t ed25519 -f "$SECRETS_DIR/ssh/id_ed25519" -N "" -C "nixos-fabric"
            chmod ${cfg.secretPermissions} "$SECRETS_DIR/ssh/id_ed25519" "$SECRETS_DIR/ssh/id_ed25519.pub"
          fi
          ;;
        age)
          echo "Rotating secrets for age backend..."
          # Similar rotation but with age encryption
          ;;
        *)
          echo "Secret rotation not supported for backend: $BACKEND"
          exit 1
          ;;
      esac
      
      echo "Secrets rotation completed"
    '';
  };

in {
  options.network-fabric.flake-secrets = {
    enable = lib.mkEnableOption "Enable flake secrets management";
    
    backend = lib.mkOption {
      type = lib.types.enum [ "file" "age" "sops" "vault" ];
      default = defaultConfig.backend;
      description = "Secret storage backend";
    };
    
    fileBackend = lib.mkOption {
      type = lib.types.attrs;
      default = defaultConfig.fileBackend;
      description = "File backend configuration";
    };
    
    ageBackend = lib.mkOption {
      type = lib.types.attrs;
      default = defaultConfig.ageBackend;
      description = "Age encryption backend configuration";
    };
    
    sopsBackend = lib.mkOption {
      type = lib.types.attrs;
      default = defaultConfig.sopsBackend;
      description = "Sops backend configuration";
    };
    
    vaultBackend = lib.mkOption {
      type = lib.types.attrs;
      default = defaultConfig.vaultBackend;
      description = "Vault backend configuration";
    };
    
    secrets = lib.mkOption {
      type = lib.types.attrs;
      default = defaultConfig.secrets;
      description = "Secret definitions";
    };
    
    flakeSecrets = lib.mkOption {
      type = lib.types.attrs;
      default = defaultConfig.flakeSecrets;
      description = "Flake-specific secrets configuration";
    };
    
    deploySecrets = lib.mkOption {
      type = lib.types.bool;
      default = defaultConfig.deploySecrets;
      description = "Deploy secrets during system activation";
    };
    
    secretPermissions = lib.mkOption {
      type = lib.types.str;
      default = defaultConfig.secretPermissions;
      description = "Permissions for deployed secrets";
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Install required packages based on backend
    environment.systemPackages = with pkgs; [
      bash
      coreutils
    ] ++ lib.optional (cfg.backend == "age") [ age ]
    ++ lib.optional (cfg.backend == "sops") [ sops ]
    ++ lib.optional (cfg.backend == "vault") [ vault ]
    ++ lib.optional (cfg.flakeSecrets.wireguard.enable) [ wireguard-tools ]
    ++ lib.optional (cfg.flakeSecrets.ssh.enable) [ openssh ];
    
    # Create secrets directory
    systemd.tmpfiles.rules = [
      "d ${secretsDir} 0700 root root -"
      "d ${secretsDir}/wireguard 0700 root root -"
      "d ${secretsDir}/ssh 0700 root root -"
      "d ${secretsDir}/api 0700 root root -"
    ];
    
    # Deploy secrets during activation
    system.activationScripts.deploy-secrets = lib.optionalString cfg.deploySecrets ''
      echo "Deploying secrets..."
      ${secretDeploymentScript}
      echo "Secrets deployed"
    '';
    
    # Create secret management scripts
    system.activationScripts.secret-scripts = ''
      mkdir -p ${secretsDir}/scripts
      cp ${secretDeploymentScript} ${secretsDir}/scripts/
      cp ${secretVerificationScript} ${secretsDir}/scripts/
      cp ${secretRotationScript} ${secretsDir}/scripts/
      chmod 0700 ${secretsDir}/scripts/*
    '';
    
    # Generate environment configuration
    system.activationScripts.secret-environment = ''
      cat > /etc/profile.d/flake-secrets.sh <<EOF
#!/bin/bash
export FLAKE_SECRETS_DIR="${secretsDir}"
export DEPLOY_SECRETS_SCRIPT="${secretsDir}/scripts/deploy-secrets"
export VERIFY_SECRETS_SCRIPT="${secretsDir}/scripts/verify-secrets"
export ROTATE_SECRETS_SCRIPT="${secretsDir}/scripts/rotate-secrets"
EOF
    '';
    
    # Generate WireGuard keys if enabled
    system.activationScripts.wireguard-secrets = lib.optionalString cfg.flakeSecrets.wireguard.enable ''
      mkdir -p ${secretsDir}/wireguard
      
      # Generate keys if they don't exist
      if [ ! -f ${secretsDir}/wireguard/private.key ]; then
        echo "Generating WireGuard keys..."
        wg genkey | tee ${secretsDir}/wireguard/private.key | wg pubkey > ${secretsDir}/wireguard/public.key
        chmod ${cfg.secretPermissions} ${secretsDir}/wireguard/private.key ${secretsDir}/wireguard/public.key
      fi
    '';
    
    # Generate SSH keys if enabled
    system.activationScripts.ssh-secrets = lib.optionalString cfg.flakeSecrets.ssh.enable ''
      mkdir -p ${secretsDir}/ssh
      
      # Generate keys if they don't exist
      if [ ! -f ${secretsDir}/ssh/id_ed25519 ]; then
        echo "Generating SSH keys..."
        ssh-keygen -t ed25519 -f ${secretsDir}/ssh/id_ed25519 -N "" -C "nixos-fabric"
        chmod ${cfg.secretPermissions} ${secretsDir}/ssh/id_ed25519 ${secretsDir}/ssh/id_ed25519.pub
      fi
    '';
  };
}
