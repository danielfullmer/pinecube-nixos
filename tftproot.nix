# Example tftproot, based on my configuration
let
  pkgs = import <nixpkgs> {};
  pinecube = import <nixpkgs/nixos> {
    configuration = { pkgs, lib, ... }: {
      imports = [ ./configuration.nix ./cross-config.nix ];

      # Ensure ethernet is available before mounting
      boot.initrd.network.enable = true;

      # Don't shut down network after initrd, we need it since we network mount /nix/store
      boot.initrd.network.flushBeforeStage2 = false; # TODO: This causes it to have two IP addresses...

      #boot.kernelParams = [ "boot.debug1devices" "boot.shell_on_fail" ];

      fileSystems."/" = {
        device = "none";
        fsType = "tmpfs";
        options = [ "defaults" "size=30M" "mode=755" ];
      };

      fileSystems."/nix/store" = {
        device = "192.168.5.1:/nix/store";
        fsType = "nfs";
        options = [ "ro" "port=2049" "nolock" "proto=tcp" ];
      };
    };
  };
  extlinux-conf-builder = import ./generic-extlinux-compatible/extlinux-conf-builder.nix {
    pkgs = pkgs.buildPackages;
  };
  extlinuxFiles = pkgs.runCommand "extlinuxFiles" {} ''
    mkdir -p $out
    ${extlinux-conf-builder} -t 3 -c ${pinecube.config.system.build.toplevel} -d $out
  '';
  tftpRoot = pkgs.runCommand "tftp-root" {} ''
    mkdir -p $out
    mkdir -p $out/pxelinux.cfg
    cp -r ${extlinuxFiles}/extlinux/extlinux.conf $out/pxelinux.cfg/default
    cp -r ${extlinuxFiles}/extlinux/extlinux.conf $out/pxelinux.cfg/01-02-01-51-db-b2-9d
    cp -r ${extlinuxFiles}/nixos $out/
  '';
in
  tftpRoot
