{ config, lib, pkgs, ... }:

let
  cfg = config.network-fabric.security || {};
  
  # Default security hardening settings
  defaultHardening = {
    kernel = {
      kptr_restrict = 2;
      dmesg_restrict = 1;
      yama_ptrace_scope = 2;
      unprivileged_bpf_disabled = 1;
      kexec_load_disabled = 1;
      sysrq = 0;
    };
    
    fs = {
      protected_fifos = 2;
      protected_regular = 2;
      suid_dumpable = 0;
    };
    
    network = {
      ipv4 = {
        tcp_syncookies = 1;
        rp_filter = 1;
        accept_redirects = 0;
        send_redirects = 0;
        accept_source_route = 0;
      };
      ipv6 = {
        accept_redirects = 0;
        accept_source_route = 0;
      };
    };
  };

in {
  options.network-fabric.security = {
    enable = lib.mkDefault false;
    
    ssh = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          port = lib.mkDefault 22;
          permitRootLogin = lib.mkDefault "prohibit-password";
          passwordAuthentication = lib.mkDefault false;
          authorizedKeys = lib.mkDefault [];
        };
      };
    };

    firewall = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          allowedServices = lib.mkDefault [ "ssh" "wireguard" ];
          rateLimits = lib.mkOption {
            type = lib.types.submodule {
              options = {
                ssh = lib.mkDefault {
                  enable = true;
                  rate = "15/minute";
                  burst = 20;
                };
              };
            };
          };
        };
      };
    };

    hardening = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault true;
          kernel = lib.mkDefault defaultHardening.kernel;
          fs = lib.mkDefault defaultHardening.fs;
          network = lib.mkDefault defaultHardening.network;
        };
      };
    };

    fail2ban = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkDefault false;
          jails = lib.mkDefault {
            sshd = {
              enabled = true;
              backend = "systemd";
              maxretry = 5;
              findtime = "10m";
              bantime = "1h";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # SSH configuration
    services.openssh = lib.mkIf cfg.ssh.enable {
      enable = true;
      settings = {
        Port = toString cfg.ssh.port;
        PermitRootLogin = cfg.ssh.permitRootLogin;
        PasswordAuthentication = cfg.ssh.passwordAuthentication;
        KbdInteractiveAuthentication = false;
        UseDns = false;
        LogLevel = "VERBOSE";
        MaxAuthTries = 4;
        LoginGraceTime = "20s";
      };
    };

    # Users and SSH keys
    users.users.root.openssh.authorizedKeys.keys = cfg.ssh.authorizedKeys;
    
    # System hardening
    boot.kernel.sysctl = lib.mkIf cfg.hardening.enable {
      "kernel.kptr_restrict" = toString cfg.hardening.kernel.kptr_restrict;
      "kernel.dmesg_restrict" = toString cfg.hardening.kernel.dmesg_restrict;
      "kernel.yama.ptrace_scope" = toString cfg.hardening.kernel.yama_ptrace_scope;
      "kernel.unprivileged_bpf_disabled" = toString cfg.hardening.kernel.unprivileged_bpf_disabled;
      "kernel.kexec_load_disabled" = toString cfg.hardening.kernel.kexec_load_disabled;
      "kernel.sysrq" = toString cfg.hardening.kernel.sysrq;
      
      "fs.protected_fifos" = toString cfg.hardening.fs.protected_fifos;
      "fs.protected_regular" = toString cfg.hardening.fs.protected_regular;
      "fs.suid_dumpable" = toString cfg.hardening.fs.suid_dumpable;
      
      "net.ipv4.tcp_syncookies" = toString cfg.hardening.network.ipv4.tcp_syncookies;
      "net.ipv4.conf.all.rp_filter" = toString cfg.hardening.network.ipv4.rp_filter;
      "net.ipv4.conf.default.rp_filter" = toString cfg.hardening.network.ipv4.rp_filter;
      "net.ipv4.conf.all.accept_redirects" = toString cfg.hardening.network.ipv4.accept_redirects;
      "net.ipv4.conf.default.accept_redirects" = toString cfg.hardening.network.ipv4.accept_redirects;
      "net.ipv4.conf.all.send_redirects" = toString cfg.hardening.network.ipv4.send_redirects;
      "net.ipv4.conf.default.send_redirects" = toString cfg.hardening.network.ipv4.send_redirects;
      "net.ipv4.conf.all.accept_source_route" = toString cfg.hardening.network.ipv4.accept_source_route;
      "net.ipv4.conf.default.accept_source_route" = toString cfg.hardening.network.ipv4.accept_source_route;
      
      "net.ipv6.conf.all.accept_redirects" = toString cfg.hardening.network.ipv6.accept_redirects;
      "net.ipv6.conf.default.accept_redirects" = toString cfg.hardening.network.ipv6.accept_redirects;
      "net.ipv6.conf.all.accept_source_route" = toString cfg.hardening.network.ipv6.accept_source_route;
      "net.ipv6.conf.default.accept_source_route" = toString cfg.hardening.network.ipv6.accept_source_route;
    };

    # Fail2ban
    services.fail2ban = lib.mkIf cfg.fail2ban.enable {
      enable = true;
      jails = lib.mapAttrs (name: jailConfig: 
        {
          settings = {
            enabled = jailConfig.enabled;
            backend = jailConfig.backend or "systemd";
            port = jailConfig.port or "ssh";
            filter = jailConfig.filter or "sshd";
            maxretry = toString (jailConfig.maxretry or 5);
            findtime = jailConfig.findtime or "10m";
            bantime = jailConfig.bantime or "1h";
          };
        }
      ) cfg.fail2ban.jails;
    };
  };
}