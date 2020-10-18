#!/usr/bin/env bash

nix-build "<nixpkgs/nixos>" \
    -I nixpkgs=https://github.com/danielfullmer/nixpkgs/archive/409e2f8cf43ba86b1de710308ca0e9aa29d5fc60.tar.gz \
    -I nixos-config=./configuration.nix \
    -A config.system.build.sdImage
