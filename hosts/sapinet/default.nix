{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Host identity
  networking.hostName = "sapinet";
  time.timeZone = "Europe/Paris";

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.sandbox = false;

  # Kernel parameters
  boot.kernelParams = [
    "lockdown=confidentiality"
    "slab_nomerge"
    "pti=on"
  ];

  # Fabric loopback (stable endpoints)
  networking.interfaces.lo = {
    ipv4.addresses = [ { address = "10.254.0.1"; prefixLength = 32; } ];
    ipv6.addresses = [ { address = "fd42:1337:254::1"; prefixLength = 128; } ];
  };

  # WireGuard transport
  networking.wireguard.interfaces.wgtransport = {
    ips = [
      "10.255.0.1/24"
      "fd42:1337:255::1/64"
    ];
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/sapinet.key";

    peers = [
      {
        # noisy-le-sec-rtr (loopback 10.254.0.2)
        publicKey = "__NOISY_PUB__";  # Will be replaced by secrets
        endpoint = "__NOISY_ENDPOINT__:51820";  # Will be replaced by secrets
        allowedIPs = [
          "10.255.0.2/32"
          "fd42:1337:255::2/128"
          "10.254.0.2/32"
          "fd42:1337:254::2/128"
        ];
        persistentKeepalive = 25;
      }
      {
        # bondy-rtr (loopback 10.254.0.3)
        publicKey = "__BONDY_PUB__";  # Will be replaced by secrets
        endpoint = "__BONDY_ENDPOINT__:51820";  # Will be replaced by secrets
        allowedIPs = [
          "10.255.0.3/32"
          "fd42:1337:255::3/128"
          "10.254.0.3/32"
          "fd42:1337:254::3/128"
        ];
        persistentKeepalive = 25;
      }
      {
        # le-pre-saint-gervais-rtr (loopback 10.254.0.4)
        publicKey = "__LEPRE_PUB__";  # Will be replaced by secrets
        endpoint = "__LEPRE_ENDPOINT__:51820";  # Will be replaced by secrets
        allowedIPs = [
          "10.255.0.4/32"
          "fd42:1337:255::4/128"
          "10.254.0.4/32"
          "fd42:1337:254::4/128"
        ];
        persistentKeepalive = 25;
      }
    ];
  };

  # SSH configuration
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
  ];

  users.users.franck = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8tv95u6m802GPmgaZYVW+nE7hnuVU+3nbjYxciBGfV franck@franck-latitude3400"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "prohibit-password";
    AllowAgentForwarding = false;
    AllowTcpForwarding = false;
    X11Forwarding = false;
    UseDns = false;
    LogLevel = "VERBOSE";
    MaxAuthTries = 4;
    LoginGraceTime = "20s";
  };

  systemd.services.sshd.serviceConfig = {
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectControlGroups = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    LockPersonality = true;
  };

  # Firewall (nftables)
  networking.firewall.enable = false;
  networking.nftables.enable = true;
  networking.nftables.ruleset = ''
    table inet filter {
      chain input {
        type filter hook input priority 0; policy drop;

        ct state established,related accept
        iifname "lo" accept

        ip protocol icmp accept
        ip6 nexthdr ipv6-icmp accept

        # SSH public (rate-limited)
        tcp dport 22 ct state new limit rate 15/minute burst 20 packets accept

        # WireGuard from Internet
        udp dport 51820 accept

        # OSPF on wgtransport only
        iifname "wgtransport" ip protocol 89 accept

        # BGP on wgtransport only
        iifname "wgtransport" tcp dport 179 accept
      }

      chain forward { type filter hook forward priority 0; policy drop; }
      chain output  { type filter hook output priority 0; policy accept; }
    }
  '';

  # Fail2ban
  services.fail2ban.enable = true;
  services.fail2ban.jails.sshd.settings = {
    enabled = true;
    backend = "systemd";
    port = "ssh";
    filter = "sshd";
    maxretry = 5;
    findtime = "10m";
    bantime = "1h";
  };

  # Security hardening
  security.apparmor.enable = true;
  security.apparmor.packages = with pkgs; [ apparmor-utils ];

  security.auditd.enable = true;
  security.audit.enable = true;

  services.journald.extraConfig = ''
    Storage=persistent
    Compress=yes
    SystemMaxUse=512M
    RuntimeMaxUse=128M
    SystemMaxFileSize=64M
    RateLimitIntervalSec=30s
    RateLimitBurst=1000
  '';

  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.yama.ptrace_scope" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.kexec_load_disabled" = 1;
    "kernel.sysrq" = 0;

    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    "fs.suid_dumpable" = 0;

    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;

    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
  };

  # FRR (OSPF + BGP)
  services.frr = {
    ospfd.enable = true;
    bgpd.enable = true;

    config = ''
      frr defaults traditional
      hostname sapinet
      service integrated-vtysh-config
      log syslog informational

      router ospf
        ospf router-id 10.254.0.1
        passive-interface default
        no passive-interface wgtransport
        network 10.254.0.1/32 area 0
        network 10.255.0.0/24 area 0

      router bgp 65000
        bgp router-id 10.254.0.1

        neighbor 10.254.0.2 remote-as 65000
        neighbor 10.254.0.2 update-source lo
        neighbor 10.254.0.2 ebgp-multihop 5

        neighbor 10.254.0.3 remote-as 65000
        neighbor 10.254.0.3 update-source lo
        neighbor 10.254.0.3 ebgp-multihop 5

        neighbor 10.254.0.4 remote-as 65103
        neighbor 10.254.0.4 update-source lo
        neighbor 10.254.0.4 ebgp-multihop 5
    '';
  };

  # Packages
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    wireguard-tools
    frr
  ];

  system.stateVersion = "25.11";
}
