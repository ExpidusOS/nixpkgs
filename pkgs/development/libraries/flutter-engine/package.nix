{ pname
, version
, engineUrl
, sourceHash
, customDeps ? {}
, customVars ? {}
, runtimeMode ? "release"
, configureFlags ? []
, enableParallelBuilding ? true
}@args:
{ buildFHSUserEnv
, writeText
, writeShellScript
, fetchgit
, targetPlatform
, stdenv
, lib
, cacert
, ninja
, python3
, pkg-config
, git
}:
with lib;
let
  VPYTHON_BYPASS = "manually managed python not supported by chrome operations";

  customVars = {
    download_emsdk = if (targetPlatform.isWasm or targetPlatform.isWasi) then "True" else "False";
  } // args.customVars;

  targetDir = "${targetPlatform.parsed.cpu.name}${optionalString (targetPlatform.parsed.kernel.name != "unknown") "-${targetPlatform.parsed.kernel.name}"}-${runtimeMode}";

  drvName = "flutter-engine-${version}";

  fhsEnv = buildFHSUserEnv {
    name = "${drvName}-fhs-env";

    targetPkgs = pkgs:
      with pkgs; [
        bash
        curl
        git
        python3
        pkg-config
      ];
  };

  gclient = writeText "${drvName}.gclient" ''
    solutions = [
      {
        "managed": False,
        "name": "src/flutter",
        "url": "${args.engineUrl}",
        "custom_deps": {
          ${concatStrings (attrValues (mapAttrs (name: src: ''
            "${name}": "${src}",
          '') args.customDeps))}
        },
        "custom_vars": {
          ${concatStrings (attrValues (mapAttrs (name: value: ''
            "${name}": ${value},
          '') customVars))}
        }
      }
    ]
  '';

  depot_tools = fetchgit {
    url = "https://chromium.googlesource.com/chromium/tools/depot_tools.git";
    rev = "25cf78395cd77e11b13c1bd26124e0a586c19166";
    sha256 = "sha256-Qn0rqX2+wYpbyfwYzeaFsbsLvuGV6+S9GWrH3EqaHmU=";
  };

  gclientSetup = ''
    cp -r -P --no-preserve=ownership,mode ${depot_tools} $NIX_BUILD_TOP/depot_tools

    for name in cipd vpython3 update_depot_tools; do
      chmod +x $NIX_BUILD_TOP/depot_tools/$name
    done
  '';

  src = stdenv.mkDerivation {
    name = "${drvName}-source";

    inherit gclient;

    unpackPhase = ''
      runHook preUnpack
      ${gclientSetup}
      runHook postUnpack
    '';

    NIX_SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      mkdir -p $out
      cd $out
      cp $gclient $out/.gclient

      runHook preInstall
      export PATH=$PATH:$NIX_BUILD_TOP/depot_tools

      ${fhsEnv}/bin/${fhsEnv.name} $NIX_BUILD_TOP/depot_tools/gclient sync

      find $out -name '*.pyc' -type f -delete
      find $out -name 'package_config.json' -type f -exec sed -i '/"generated": /d' {} \;
      find $out -name '.git' -type d -exec ${writeShellScript "${drvName}-fix-git" ''
        head=$(cat $1/logs/HEAD | awk 'NF=2')
        rm -rf $1
        mkdir -p $1/logs
        echo $head >$1/logs/HEAD
      ''} {} \;

      cp ${./git_revision.py} $out/src/flutter/build/git_revision.py

      rm -rf $out/.cipd $out/.gclient $out/.gclient_entries $out/.gclient_previous_custom_vars $out/.gclient_previous_sync_commits
      runHook postInstall
    '';

    outputHash = args.sourceHash;
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in stdenv.mkDerivation {
  inherit (args) pname version enableParallelBuilding configureFlags;
  inherit src gclient VPYTHON_BYPASS targetDir;

  passthru = {
    mkPackage = args: callPackage (import ./package.nix args) {};
  };

  postUnpack = ''
    ${gclientSetup}
  '';

  configurePhase = ''
    runHook preConfigure

    export PATH=$PATH:$NIX_BUILD_TOP/depot_tools
    ${fhsEnv}/bin/${fhsEnv.name} $NIX_BUILD_TOP/depot_tools/vpython3 $NIX_BUILD_TOP/${src.name}/src/flutter/tools/gn \
      --runtime-mode ${runtimeMode} \
      --no-goma \
      --depot-tools $NIX_BUILD_TOP/depot_tools \
      --no-prebuilt-dart-sdk \
      --target-triple ${targetPlatform.parsed.cpu.name}-${if targetPlatform.parsed.kernel.name == "unknown" then "freestanding" else targetPlatform.parsed.kernel.name}-${targetPlatform.parsed.abi.name} \
      --out-dir $out/lib/flutter-engine \
      --target-dir ${targetDir} \
      $configureFlags

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cat << EOF >build.sh
#!/usr/bin/env sh
buildCores=1
if [ "''${enableParallelBuilding-1}" ]; then
  buildCores=$NIX_BUILD_CORES
fi

flagsArray=(-j$buildCores $buildFlags)
export PATH=$PATH:${python3}/bin:${git}/bin:$NIX_BUILD_TOP/depot_tools
exec ${ninja}/bin/ninja -C $out/lib/flutter-engine/out/${targetDir} $flagsArray $@
EOF
    chmod +x build.sh
    TERM=dumb ${fhsEnv}/bin/${fhsEnv.name} build.sh
    rm build.sh

    runHook postBuild
  '';

  dontInstall = true;
  dontFixup = true;

  meta = {
    description = "The Flutter engine (${runtimeMode})";
    homepage = "https://flutter.dev";
    license = licenses.bsd3;
    platforms = [ "aarch64-linux" "x86_64-linux" ];
    maintainers = with maintainers; [ RossComputerGuy ];
  };
}
