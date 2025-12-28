{ config, lib, pkgs, ... }:

{
  ############################################################
  # Underlay: WireGuard vers noisy
  ############################################################
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
}
