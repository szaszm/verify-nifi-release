{ pkgs ? import <nixpkgs> {} }:

(pkgs.buildFHSEnv {
  name = "java22-env";
  targetPkgs = pkgs: (with pkgs; [
    maven
    jdk22
    subversion
    p7zip
    unzip
    git
  ]);
  runScript = "bash";
  profile = '' export JAVA_HOME="${pkgs.jdk22}" '';
}).env
