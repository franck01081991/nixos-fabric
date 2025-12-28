{ description = "NixOS Fabric - Simple Flake for Deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations = {
        rtr-sapinet = lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              imports = [
                ./hosts/rtr-sapinet/hardware-configuration.nix
              ];

              boot.kernelParams = [
                "lockdown=confidentiality"
                "slab_nomerge"
                "pti=on"
              ];

              networking.hostName = "sapinet";
              time.timeZone = "Europe/Paris";
              console.keyMap = "fr";

              services.openssh.enable = true;

              environment.systemPackages = with pkgs; [
                git
                curl
                vim
                wireguard-tools
                frr
              ];

              # WireGuard configuration
              networking.wireguard.interfaces.wgtransport = {
                ips = [ "10.255.0.1/24" ];
                listenPort = 51820;
                privateKeyFile = "/etc/wireguard/sapinet.key";

                peers = [
                  {
                    publicKey = "Qvhgie7O3gKZF8pMmTS0YG2YmbNfANtCX3sBE21ODg8=";
                    endpoint = "10.10.10.1:51820";
                    allowedIPs = [
                      "10.255.0.2/32"
                      "10.254.0.11/32"
                    ];
                    persistentKeepalive = 25;
                  }
                ];
              };

              # FRR configuration
              services.frr = {
                bgpd.enable = true;

                config = ''
                  frr defaults traditional
                  hostname sapinet
                  service integrated-vtysh-config
                  log syslog informational

                  router bgp 65000
                    bgp router-id 10.254.0.1
                    neighbor 10.255.0.2 remote-as 65000
                    neighbor 10.255.0.2 update-source wgtransport
                    neighbor 10.255.0.2 ebgp-multihop 5

                    address-family ipv4 unicast
                      network 10.254.0.1/32
                      network 10.255.0.0/24
                      neighbor 10.255.0.2 activate
                    exit-address-family
                '';
              };

              systemd.services.frr = {
                enable = true;
                wantedBy = [ "multi-user.target" ];
              };

              boot.loader.grub = {
                enable = true;
                efiSupport = true;
                devices = [ "/dev/sda" ];
              };

              system.stateVersion = "25.11";
            })
          ];
        };

        rtr-noisy = lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              imports = [
                ./hosts/rtr-noisy/hardware-configuration.nix
              ];

              boot.kernelParams = [
                "lockdown=confidentiality"
                "slab_nomerge"
                "pti=on"
              ];

              networking.hostName = "noisy";
              time.timeZone = "Europe/Paris";
              console.keyMap = "fr";

              services.openssh.enable = true;

              environment.systemPackages = with pkgs; [
                git
                curl
                vim
                wireguard-tools
                frr
              ];

              # WireGuard configuration
              networking.wireguard.interfaces.wgtransport = {
                ips = [ "10.255.0.2/24" ];
                listenPort = 51820;
                privateKeyFile = "/etc/wireguard/noisy-edge1.key";

                peers = [
                  {
                    publicKey = "e18dkmQzQl4sBL9N0xWnVMyFZ9RqXmrSrN6C10IGSW0=";
                    endpoint = "45.90.162.251:51820";
                    allowedIPs = [
                      "10.255.0.1/32"
                      "10.254.0.1/32"
                    ];
                    persistentKeepalive = 25;
                  }
                ];
              };

              # FRR configuration
              services.frr = {
                bgpd.enable = true;

                config = ''
                  frr defaults traditional
                  hostname noisy
                  service integrated-vtysh-config
                  log syslog informational

                  router bgp 65000
                    bgp router-id 10.254.0.11
                    neighbor 10.255.0.1 remote-as 65000
                    neighbor 10.255.0.1 update-source wgtransport
                    neighbor 10.255.0.1 ebgp-multihop 5

                    address-family ipv4 unicast
                      network 10.254.0.11/32
                      network 10.255.0.0/24
                      neighbor 10.255.0.1 activate
                    exit-address-family
                '';
              };

              systemd.services.frr = {
                enable = true;
                wantedBy = [ "multi-user.target" ];
              };

              boot.loader.grub = {
                enable = true;
                efiSupport = true;
                devices = [ "/dev/sda" ];
              };

              system.stateVersion = "25.11";
            })
          ];
        };
      };
    };
}
