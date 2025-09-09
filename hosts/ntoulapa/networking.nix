{

  networking.firewall.interfaces."enp2s0".allowedTCPPorts = [
    22
    80
    443
    514
  ];
  networking.firewall.interfaces."enp2s0".allowedUDPPorts = [ 51820 ];

  networking.firewall.interfaces."wg0".allowedTCPPorts = [
    22
    80
    443
    514
  ];

  # This is necessary so that cross-network traffic is allowed to reach my VMs on VLAN106
  networking.firewall.checkReversePath = false;
  networking.vlans.vlan106 = {
    id = 106;
    interface = "enp2s0";
  };

  networking.bridges = {
    "br-vlan106" = {
      interfaces = [ "vlan106" ];
    };
  };

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
