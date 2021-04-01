let
  pkgs = import <nixpkgs> {};
  stdenv = pkgs.stdenv;
in with pkgs; {
  myProject = stdenv.mkDerivation {
    name = "myProject";
    version = "1";
    src = if pkgs.lib.inNixShell then null else nix;

    buildInputs = with rPackages; [
      R
      dplyr
      XML
    ];
  };
}
