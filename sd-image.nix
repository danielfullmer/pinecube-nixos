{ config, pkgs, ... }:

let
  uboot = pkgs.callPackage ./uboot {};
in
{
  imports = [ 
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>
    ./configuration.nix
    ./cross-config.nix
  ];

  sdImage.populateFirmwareCommands = "";
  sdImage.populateRootCommands = ''
    mkdir -p ./files/boot
    ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
  '';
  sdImage.postBuildCommands = ''
    dd if=${uboot}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
  '';
}
