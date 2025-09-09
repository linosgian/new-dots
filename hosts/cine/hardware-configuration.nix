{
  config,
  lib,
  pkgs,
  ...
}:
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  boot.loader.grub.device = lib.mkDefault "/dev/vda";
  boot.kernelParams = [
    "console=ttyS0,115200"
  ];
  boot.growPartition = true;

  # Same as ntoulapa
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
      libva-vdpau-driver # Previously vaapiVdpau
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      vpl-gpu-rt # QSV on 11th gen or newer
      intel-ocl # OpenCL support
    ];
  };
}
