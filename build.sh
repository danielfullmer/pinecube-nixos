#!/usr/bin/env bash

nix-build "<nixpkgs/nixos>" \
    -I nixpkgs=https://github.com/danielfullmer/nixpkgs/archive/e69838e006a7271006ab834b521187891bf93ff4.tar.gz \
    -I nixos-config=./sd-image.nix \
    -A config.system.build.sdImage
