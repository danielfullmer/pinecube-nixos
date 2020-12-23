{ config, lib, pkgs, ... }:

{
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.consoleLogLevel = 7;

  # cma is 64M by default which is waay too much and we can't even unpack initrd
  boot.kernelParams = [ "console=ttyS0,115200n8" "cma=32M" ];

  # See: https://lore.kernel.org/patchwork/project/lkml/list/?submitter=22013&order=name
  boot.kernelPackages = pkgs.linuxPackages_5_9;
  boot.kernelPatches = [
    { name = "pine64-pinecube";
      patch = ./kernel/Pine64-PineCube-support.patch;
      # sunxi_defconfig is missing wireless support
      # TODO: Are all of these options needed here?
      extraConfig = ''
        CFG80211 m
        WIRELESS y
        WLAN y
        RFKILL y
        RFKILL_INPUT y
        RFKILL_GPIO y
      '';
    }
  ];

  boot.kernelModules = [ "spi-nor" ]; # Not sure why this doesn't autoload. Provides SPI NOR at /dev/mtd0
  boot.extraModulePackages = [ config.boot.kernelPackages.rtl8189es ];

  zramSwap.enable = true; # 128MB is not much to work with

  sound.enable = true;

  environment.systemPackages = with pkgs; [
    ffmpeg
    (v4l_utils.override { withGUI = false; })
    usbutils
  ];

  ###

  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  users.users.root.initialPassword = "nixos"; # Log in without a password

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "nixos";
  };
  services.mingetty.autologinUser = "nixos";

  networking.wireless.enable = true;

}
