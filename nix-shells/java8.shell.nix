{ pkgs ? import <nixpkgs> {} }:

(pkgs.buildFHSEnv {
  name = "java8-env";
  targetPkgs = pkgs: (with pkgs; [
    maven
    openjdk8-bootstrap
    subversion
    p7zip
  ]);
  runScript = "bash";
  profile = '' export JAVA_HOME="${pkgs.openjdk8-bootstrap}" '';
}).env
