{ config, lib, pkgs, ... }:

{
  nixpkgs.crossSystem = lib.recursiveUpdate lib.systems.examples.armv7l-hf-multiplatform {
    platform = {
      name = "pinecube";
      kernelBaseConfig = "sunxi_defconfig";
    };
  };

  nixpkgs.overlays = [ (self: super: {
    # Dependency minimization for cross-compiling
    cairo = super.cairo.override { glSupport = false; };
    #libass = super.libass.override { encaSupport = false; };
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
