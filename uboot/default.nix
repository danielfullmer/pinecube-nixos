{ pkgs }:

pkgs.buildUBoot {
  patches = [
    ./0001-WIP-Initial-support-for-pinecube.patch
    ./0002-sun8i-emac-sun8i-v3s-compatibility-for-sun8i-emac.patch
    ./0003-pinecube-Add-ethernet-support.patch
  ];

  defconfig = "pinecube_defconfig";
  extraMeta.platforms = ["armv7l-linux"];
  filesToInstall = ["u-boot-sunxi-with-spl.bin"];
}
