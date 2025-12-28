{ config, lib, pkgs, ... }:

{
  # Base system configuration
  environment.systemPackages = with pkgs; [
    vim
    git
    tcpdump
    frr
    wireguard-tools
    iproute2
  ];
  
  # Users configuration
  users.users.franck = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "networking" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
    ];
  };
  
  # System configuration
  system.stateVersion = "25.11";
  console.keyMap = "fr";
  
  # Bootloader configuration (basic setup)
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    useOSProber = true;
    # Devices for GRUB installation
    devices = [ "/dev/sda" "/dev/vda" "/dev/nvme0n1" ];
  };
  
  # For virtual machines, you might want to disable GRUB
  # and use the hypervisor's bootloader instead:
  # boot.loader.grub.enable = false;
}