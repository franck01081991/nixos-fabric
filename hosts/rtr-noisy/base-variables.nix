{ ... }:

{
  network-fabric.base = {
    enable = true;
    
    packages = [
      "vim"
      "git"
      "tcpdump"
      "frr"
      "wireguard-tools"
      "iproute2"
    ];
    
    users = {
      franck = {
        enable = true;
        sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400";
      };
    };
    
    system = {
      stateVersion = "25.11";
      console = {
        keyMap = "fr";
      };
    };
  };
}