{ pkgs, ... }:

let
  # Test SSH security configuration
  sshSecurityConfig = {
    port = 2222;
    permitRootLogin = "no";
    passwordAuthentication = "no";
    allowedUsers = [ "franck" ];
  };
in
{
  sshSecurityConfig = sshSecurityConfig;
  isValid = sshSecurityConfig.port != null && sshSecurityConfig.permitRootLogin != null;
}