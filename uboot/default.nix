{ pkgs }:

pkgs.buildUBoot {
  patches = [ ./Pine64-PineCube-uboot-support.patch ];

  defconfig = "pinecube_defconfig";
  extraMeta.platforms = ["armv7l-linux"];
  filesToInstall = ["u-boot-sunxi-with-spl.bin"];
}
