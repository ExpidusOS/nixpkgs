{ lib, callPackage }:
with lib;
let
  mkPackage = args: callPackage (import ./package.nix args) {};
  mkPackageSet = args: callPackage (import ./package-set.nix args) {};

  versions = {
    "3.7.10" = mkPackageSet {
      pname = "flutter-engine";
      version = "3.7.10";
      engineUrl = "https://github.com/flutter/engine.git@ec975089acb540fc60752606a3d3ba809dd1528b";
      sourceHash = "sha256-A9DWDuOL0fG5CNJ758mnXnFIk6i7EM2hsB3IU/kzBaw=";
      customDeps = {};
      customVars = {};
      configureFlags = [];
      enableParallelBuilding = true;
    };
  };
in versions // {
  stable = versions."3.7.10";
}
