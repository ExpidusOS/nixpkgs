{
  callPackage,
  buildPlatform,
  targetPlatform,
  fetchgit,
  tools ? callPackage ./tools.nix { inherit buildPlatform; },
  curl,
  pkg-config,
  git,
  python3,
  runCommand,
  writeText,
  cacert,
  version,
  hashes,
  url,
}:
let
  target-constants = callPackage ./constants.nix { platform = targetPlatform; };
  build-constants = callPackage ./constants.nix { platform = buildPlatform; };

  boolOption = value: if value then "True" else "False";
in
runCommand "flutter-engine-source-${version}-${buildPlatform.system}-${targetPlatform.system}"
  {
    pname = "flutter-engine-source";
    inherit version;

    inherit (tools) depot_tools;

    nativeBuildInputs = [
      curl
      pkg-config
      git
      tools.cipd
      (python3.withPackages (
        ps: with ps; [
          httplib2
          six
        ]
      ))
    ];

    gclient = writeText "flutter-engine-${version}.gclient" ''
      solutions = [{
        "managed": False,
        "name": "src/flutter",
        "url": "${url}",
        "custom_vars": {
          "download_fuchsia_deps": False,
          "download_android_deps": False,
          "download_linux_deps": ${boolOption targetPlatform.isLinux},
          "setup_githooks": False,
          "download_esbuild": False,
          "download_dart_sdk": False,
          "host_cpu": "${build-constants.alt-arch}",
          "host_os": "${build-constants.alt-os}",
        },
      }]

      target_os_only = True
      target_os = [
        "${target-constants.alt-os}"
      ]

      target_cpu_only = True
      target_cpu = [
        "${target-constants.alt-arch}"
      ]
    '';

    NIX_SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    GIT_SSL_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    DEPOT_TOOLS_UPDATE = "0";
    DEPOT_TOOLS_COLLECT_METRICS = "0";
    PYTHONDONTWRITEBYTECODE = "1";

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = hashes."${buildPlatform.system}-${targetPlatform.system}" or (throw "Hash not set for ${targetPlatform.system} on ${buildPlatform.system}");
  }
  ''
    source ${../../../../build-support/fetchgit/deterministic-git}
    export -f clean_git
    export -f make_deterministic_repo

    mkdir -p $out
    cp $gclient $out/.gclient
    cd $out

    export PATH=$PATH:$depot_tools
    python3 $depot_tools/gclient.py sync --no-history --shallow --nohooks -j $NIX_BUILD_CORES
    find $out -name '.git' -exec dirname {} \; | xargs bash -c 'make_deterministic_repo $@' _
    find $out -path '*/.git/*' ! -name 'HEAD' -prune -exec rm -rf {} \;
    find $out -name '.git' -exec mkdir {}/logs \;
    find $out -name '.git' -exec cp {}/HEAD {}/logs/HEAD \;

    rm -rf $out/src/flutter/{buildtools,prebuilts,third_party/swiftshader}

    rm -rf $out/.cipd $out/.gclient $out/.gclient_entries $out/.gclient_previous_custom_vars $out/.gclient_previous_sync_commits
  ''
