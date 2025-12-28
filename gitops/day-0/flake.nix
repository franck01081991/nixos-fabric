{
  description = "NixOS Fabric - Day-0 Bootstrap Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations = {
        bootstrap = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, lib, ... }: {
              # Basic system configuration
              boot.supportedFilesystems = [ "zfs" "btrfs" "f2fs" ];

              # Enable SSH for initial access
              services.openssh = {
                enable = true;
                permitRootLogin = "yes";
                passwordAuthentication = true;
              };

              # Set up initial user
              users.users.franck = {
                isNormalUser = true;
                extraGroups = [ "wheel" "sudo" ];
              };

              # Enable sudo for wheel group
              security.sudo.wheelNeedsPassword = false;

              # Basic networking
              networking = {
                hostName = "nixos-fabric-bootstrap";
                useDHCP = true;
                nameservers = [ "1.1.1.1" "8.8.8.8" ];
              };

              # Enable flakes
              nix.settings.experimental-features = "nix-command flakes";

              # Install basic tools
              environment.systemPackages = with pkgs; [
                git
                curl
                wget
                vim
                tmux
                htop
              ];

              # Create fabric directory structure
              system.activationScripts.createFabricStructure = lib.mkBefore ''
                mkdir -p /etc/nixos-fabric
                mkdir -p /etc/nixos-fabric/bootstrap
                mkdir -p /var/log/nixos-fabric
                
                # Create initial bootstrap marker
                echo "$(date) - NixOS Fabric Bootstrap Completed" > /etc/nixos-fabric/bootstrap/completed
                
                # Set permissions
                chown -R root:root /etc/nixos-fabric
                chmod -R 750 /etc/nixos-fabric
              '';

              # Enable serial console for headless servers
              boot.kernelParams = [ "console=ttyS0" "console=tty0" ];

              # Basic hardware support
              hardware = {
                cpu.intel.updateMicrocode = true;
                enableRedistributableFirmware = true;
              };

              # Time synchronization
              services.ntp = {
                enable = true;
                servers = [ "pool.ntp.org" ];
              };

              # Systemd services for fabric
              systemd.services.nixos-fabric-bootstrap = {
                description = "NixOS Fabric Bootstrap Service";
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart = "${pkgs.bash}/bin/bash -c 'echo Fabric bootstrap service active';";
                };
              };
            })
          ];
        };
      };
    };
}