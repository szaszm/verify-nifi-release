{ pkgs ? import <nixpkgs> {} }:

(pkgs.buildFHSEnv {
  name = "minificpp-env";
  targetPkgs = pkgs: (with pkgs; [
    cmake
    flex
    bison
    libtool
    autoconf
    automake
    gcc
    clang
    git
    wget
    gnupg
    jq
    p7zip
    subversion
    gnum4
    ninja
    gnumake
    python3Full
  ]);
  runScript = "bash";
}).env
