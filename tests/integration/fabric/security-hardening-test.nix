{ pkgs, ... }:

let
  # Test system hardening configuration
  hardeningConfig = {
    kernel = {
      sysctl = {
        "kernel.kptr_restrict" = 1;
        "kernel.dmesg_restrict" = 1;
        "net.ipv4.conf.all.rp_filter" = 1;
      };
    };
    users = {
      restrictRootSSH = true;
      restrictSudo = true;
    };
  };
in
{
  hardeningConfig = hardeningConfig;
  isValid = hardeningConfig.kernel != null && hardeningConfig.users != null;
}