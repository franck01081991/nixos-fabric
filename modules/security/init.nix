{ ... }:

{
  imports = [
    ./default.nix
    ./firewall.nix
    ./hardening.nix
    ./ssh.nix
    ./nftables-advanced.nix
    ./network-security.nix
  ];
}