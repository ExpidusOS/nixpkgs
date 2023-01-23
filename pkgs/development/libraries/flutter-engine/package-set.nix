{ pname
, version
, engineUrl
, sourceHash
, customDeps ? {}
, customVars ? {}
, configureFlags ? []
, enableParallelBuilding ? true
}@args:
{ lib
, callPackage
, stdenv
}:
with lib;
let
  mkPackage = pkgArgs: callPackage (import ./package.nix pkgArgs) {};

  runtimeModeNames = [
    "debug"
    "profile"
    "release"
    "jit_release"
  ];

  runtimeModes = genAttrs runtimeModeNames
    (runtimeMode: mkPackage (args // {
      pname = "${args.pname}-${runtimeMode}";
      inherit runtimeMode;
    }));
in stdenv.mkDerivation {
  inherit pname version;

  # Can be any of the runtime modes as it'll be the same derivation.
  inherit (runtimeModes.release) src;

  passthru = {
    inherit mkPackage runtimeModes;
    mkPackageSet = args: callPackage (import ./package-set.nix args) {};
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib/flutter-engine/out
    ${concatStrings (attrValues (mapAttrs (runtimeMode: pkg: ''
      ln -s ${pkg}/lib/flutter-engine/out/${pkg.targetDir} $out/lib/flutter-engine/out/${pkg.targetDir}
    '') runtimeModes))}
  '';

  meta = {
    description = "The Flutter engine";
    homepage = "https://flutter.dev";
    license = licenses.bsd3;
    platforms = [ "aarch64-linux" "x86_64-linux" ];
    maintainers = with maintainers; [ RossComputerGuy ];
  };
}
