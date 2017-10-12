{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
    name = "parse_13f";
    buildInputs = [pkgs.python36.withPackages (ps: [ps.pandas])];
}
