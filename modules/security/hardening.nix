# Security Module: System Hardening
# 
# This module provides comprehensive system hardening
# including kernel, filesystem, and network hardening.

{ config, lib, pkgs, ... }:

{
  options.network-fabric.security.hardening = {
    enable = lib.mkEnableOption "Enable system hardening";
    
    kernel = lib.mkOption {
      type = lib.types.attrs;
      default = {
        kptr_restrict = 2;
        dmesg_restrict = 1;
        yama_ptrace_scope = 2;
        unprivileged_bpf_disabled = 1;
        kexec_load_disabled = 1;
        sysrq = 0;
      };
      description = "Kernel hardening settings";
    };
    
    fs = lib.mkOption {
      type = lib.types.attrs;
      default = {
        protected_fifos = 2;
        protected_regular = 2;
        suid_dumpable = 0;
      };
      description = "Filesystem hardening settings";
    };
    
    network = lib.mkOption {
      type = lib.types.attrs;
      default = {
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
      description = "Network hardening settings";
    };
  };
  
  config = lib.mkIf config.network-fabric.security.hardening.enable {
    boot.kernel.sysctl = {
      "kernel.kptr_restrict" = toString config.network-fabric.security.hardening.kernel.kptr_restrict;
      "kernel.dmesg_restrict" = toString config.network-fabric.security.hardening.kernel.dmesg_restrict;
      "kernel.yama.ptrace_scope" = toString config.network-fabric.security.hardening.kernel.yama_ptrace_scope;
      "kernel.unprivileged_bpf_disabled" = toString config.network-fabric.security.hardening.kernel.unprivileged_bpf_disabled;
      "kernel.kexec_load_disabled" = toString config.network-fabric.security.hardening.kernel.kexec_load_disabled;
      "kernel.sysrq" = toString config.network-fabric.security.hardening.kernel.sysrq;
      
      "fs.protected_fifos" = toString config.network-fabric.security.hardening.fs.protected_fifos;
      "fs.protected_regular" = toString config.network-fabric.security.hardening.fs.protected_regular;
      "fs.suid_dumpable" = toString config.network-fabric.security.hardening.fs.suid_dumpable;
      
      "net.ipv4.tcp_syncookies" = toString config.network-fabric.security.hardening.network.ipv4.tcp_syncookies;
      "net.ipv4.conf.all.rp_filter" = toString config.network-fabric.security.hardening.network.ipv4.rp_filter;
      "net.ipv4.conf.default.rp_filter" = toString config.network-fabric.security.hardening.network.ipv4.rp_filter;
      "net.ipv4.conf.all.accept_redirects" = toString config.network-fabric.security.hardening.network.ipv4.accept_redirects;
      "net.ipv4.conf.default.accept_redirects" = toString config.network-fabric.security.hardening.network.ipv4.accept_redirects;
      "net.ipv4.conf.all.send_redirects" = toString config.network-fabric.security.hardening.network.ipv4.send_redirects;
      "net.ipv4.conf.default.send_redirects" = toString config.network-fabric.security.hardening.network.ipv4.send_redirects;
      "net.ipv4.conf.all.accept_source_route" = toString config.network-fabric.security.hardening.network.ipv4.accept_source_route;
      "net.ipv4.conf.default.accept_source_route" = toString config.network-fabric.security.hardening.network.ipv4.accept_source_route;
      
      "net.ipv6.conf.all.accept_redirects" = toString config.network-fabric.security.hardening.network.ipv6.accept_redirects;
      "net.ipv6.conf.default.accept_redirects" = toString config.network-fabric.security.hardening.network.ipv6.accept_redirects;
      "net.ipv6.conf.all.accept_source_route" = toString config.network-fabric.security.hardening.network.ipv6.accept_source_route;
      "net.ipv6.conf.default.accept_source_route" = toString config.network-fabric.security.hardening.network.ipv6.accept_source_route;
    };
  };
}