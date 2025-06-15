{

  networking.firewall.interfaces."enp7s0".allowedTCPPorts = [ 22 80 443 514 ];
  networking.firewall.interfaces."enp7s0".allowedUDPPorts = [ 51820 ];

  networking.firewall.interfaces."wg0".allowedTCPPorts = [ 22 80 443 514 ];

  networking.firewall.interfaces."nomad".allowedTCPPorts = [ 9633 9100 9753 8083 9374 9199 9167 ];
  networking.firewall.interfaces."nomad".allowedUDPPorts = [ 53 ];

  networking.firewall.interfaces."docker".allowedUDPPorts = [ 53 ];

  # This is necessary so that cross-network traffic is allowed to reach my VMs on VLAN106
  networking.firewall.checkReversePath = false;
  networking.vlans.vlan106 = {
    id = 106;
    interface = "enp7s0";
  };

  networking.bridges = {
    "br-vlan106" = {
      interfaces = [ "vlan106" ];
    };

    "nomad-br0" = {
      interfaces = [ ];
    };
  };

  # Solely used for nomad-to-nomad comms
  networking.interfaces."nomad-br0" = {
    ipv4.addresses = [{
      address = "192.168.100.1";
      prefixLength = 24;
    }];
  };
  networking.firewall.extraCommands =
    ''
      iptables -I FORWARD -i nomad -d 172.16.0.0/12 -j DROP
      iptables -I FORWARD -i nomad -d 192.168.0.0/16 -j DROP
      iptables -I FORWARD -i nomad -d 10.0.0.8/8 -j DROP
      iptables -I FORWARD -i nomad -o enp7s0 -d 192.168.5.3/32 -p tcp --dport 9100 -j ACCEPT
      iptables -I FORWARD -i nomad -o enp7s0 -d 192.168.3.4/32 -p tcp --dport 1883 -j ACCEPT
      iptables -I FORWARD -i nomad -o enp7s0 -d 192.168.3.147/32 -j ACCEPT
      iptables -I FORWARD -i nomad -o enp7s0 -d 192.168.3.0/24 -p tcp --dport 80 -j ACCEPT
      iptables -I FORWARD -i nomad -o enp7s0 -d 192.168.2.1/32 -p tcp --match multiport --dports 9100,9167,9374 -j ACCEPT
      iptables -I FORWARD -i nomad -d 172.26.64.1/20 -j ACCEPT
    '';
  networking.dhcpcd.denyInterfaces = [ "veth*" ];

  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "10.192.123.1/24" ];
      listenPort = 51820;
      privateKeyFile = "/zfs/wg-privkey";

      peers = [
        {
          # work-lapton
          publicKey = "oxynuj7S/TeyRvcnBcNOMfwmlFxSLBVwGX5KggUoSic=";
          allowedIPs = [ "10.192.123.2/32" ];
        }
        {
          # mobile
          publicKey = "+my/01kg+R8Dza1Ge3jiapKXu5Eo+CFGoxrZRXhW0g0=";
          allowedIPs = [ "10.192.123.3/32" ];
        }
        {
          # ilektraphon
          publicKey = "ow8UIpVPsV0BcnZ/6d0VRWjgwvgpxYg7Du38WfQPli8=";
          allowedIPs = [ "10.192.123.5/32" ];
        }
        {
          # Ipad
          publicKey = "mzdCqfAIY4cxFoIu9L7l9fACWwyKHldOBccpPUiB7Go=";
          allowedIPs = [ "10.192.123.6/32" ];
        }
      ];
    };
  };

}
