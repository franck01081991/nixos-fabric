{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.secrets || {};
  
in {
  options.network-fabric.secrets = {
    enable = lib.mkDefault false;
    
    # WireGuard keys
    wireguard = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault false;
          rtr-sapinet = lib.mkOption {
            type = lib.types.submodule {
              options = {
                privateKey = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "WireGuard private key for rtr-sapinet";
                };
                publicKey = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "WireGuard public key for rtr-sapinet";
                };
              };
            };
          };
          rtr-noisy = lib.mkOption {
            type = lib.types.submodule {
              options = {
                privateKey = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "WireGuard private key for rtr-noisy";
                };
                publicKey = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "WireGuard public key for rtr-noisy";
                };
              };
            };
          };
        };
      };
    };
    
    # Age configuration for sops-nix
    age = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault false;
          publicKey = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Age public key for encryption";
          };
          privateKey = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Age private key for decryption";
          };
        };
      };
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Import sops-nix module if age encryption is enabled
    imports = lib.mkIf cfg.age.enable [
      (pkgs.sops-nix.nixosModules.sops)
    ];
    
    # Configure sops-nix
    sops = lib.mkIf cfg.age.enable {
      defaultSopsFile = "./secrets/wireguard.sops.yaml";
      age = {
        publicKeys = [ cfg.age.publicKey ];
        privateKeys = [ cfg.age.privateKey ];
      };
    };
    
    # WireGuard configuration using secrets
    networking.wireguard = lib.mkIf cfg.wireguard.enable {
      interfaces = {
        wgtransport = {
          privateKey = cfg.wireguard.rtr-sapinet.privateKey;
          listenPort = 51820;
          ips = [ "10.255.0.1/24" ];
          peers = [
            {
              publicKey = cfg.wireguard.rtr-noisy.publicKey;
              allowedIPs = [ "10.255.0.11/32" "10.254.0.11/32" ];
              endpoint = "45.90.162.251:51820";
              persistentKeepalive = 25;
            }
          ];
        };
      };
    };
  };
}
