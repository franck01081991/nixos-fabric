{ lib, ... }:
{
  # Pour CI: pas de vraie machine, donc pas de bootloader ni de disque.
  boot.isContainer = true;

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  fileSystems."/" = lib.mkForce {
    device = "nodev";
    fsType = "tmpfs";
    options = [ "mode=0755" ];
  };

  # Evite le warning
  system.stateVersion = "25.11";
}