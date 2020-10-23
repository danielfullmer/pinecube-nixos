{ config, lib, pkgs, ... }:

let
  uboot = pkgs.callPackage ./uboot {};
in
{
  imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix> ];

  nixpkgs.crossSystem = lib.recursiveUpdate lib.systems.examples.armv7l-hf-multiplatform {
    platform = {
      name = "pinecube";
      kernelBaseConfig = "sunxi_defconfig";
    };
  };

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.consoleLogLevel = 7;

  # cma is 64M by default which is waay too much and we can't even unpack initrd
  boot.kernelParams = [ "console=ttyS0,115200n8" "cma=32M" ];

  sdImage.populateFirmwareCommands = "";
  sdImage.populateRootCommands = ''
    mkdir -p ./files/boot
    ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
  '';
  sdImage.postBuildCommands = ''
    dd if=${uboot}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
  '';

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
    { name = "pinecube-ir-leds"; patch = ./kernel/0001-ARM-dts-sun8i-s3l-fix-Pinecube-IR-LEDs.patch; }
  ];

  boot.extraModulePackages = [ config.boot.kernelPackages.rtl8189es ];

  environment.systemPackages = with pkgs; [
    alsaUtils
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

  ###


  nixpkgs.overlays = [ (self: super: {
    # Dependency minimization for cross-compiling
    cairo = super.cairo.override { glSupport = false; };
    libass = super.libass.override { encaSupport = false; };
    gnutls = super.gnutls.override { guileBindings = false; };
    polkit = super.polkit.override { withIntrospection = false; };
  }) ];

  # disable more stuff to minimize cross-compilation
  # some from: https://github.com/illegalprime/nixos-on-arm/blob/master/images/mini/default.nix
  environment.noXlibs = true;
  documentation.info.enable = false;
  documentation.man.enable = false;
  programs.command-not-found.enable = false;
  security.polkit.enable = false;
  security.audit.enable = false;
  services.udisks2.enable = false;
  boot.enableContainers = false;
}
