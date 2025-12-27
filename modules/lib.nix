{ lib, ... }:

let
  utils = import ./lib/utils.nix { inherit lib; };

in {
  options = utils.fabricUtils;
}