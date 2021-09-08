{ pkgs }:

pkgs.buildUBoot {
  patches = [ ./Pine64-PineCube-uboot-support.patch ];

  defconfig = "pinecube_defconfig";

  # Putting this here because it's more a design choice and not generic support
  # for hardware.
  extraConfig = ''
    CONFIG_CMD_BOOTMENU=y
  '';

  extraMeta.platforms = ["armv7l-linux"];
  filesToInstall = ["u-boot-sunxi-with-spl.bin"];
}
