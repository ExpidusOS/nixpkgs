{
  lib,
  fetchFromGitHub,
  crystal,
  gobject-introspection,
  gitUpdater,
}:
crystal.buildCrystalPackage rec {
  pname = "gi-crystal";
  version = "0.24.0";

  src = fetchFromGitHub {
    owner = "hugopl";
    repo = "gi-crystal";
    tag = "v${version}";
    hash = "sha256-0LsYREn4zWLQYUTpNWJhLLHWmg7UQzxOoQiAMmw3ZXQ=";
  };

  # Make sure gi-crystal picks up the name of the so or dylib and not the leading nix store path
  # when the package name happens to start with “lib”.
  patches = [
    ./src.patch
    ./store-friendly-library-name.patch
  ];

  nativeBuildInputs = [ gobject-introspection ];
  buildTargets = [ "generator" ];

  doCheck = false;
  doInstallCheck = false;

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp -r * $out

    runHook postInstall
  '';

  passthru = {
    updateScript = gitUpdater { rev-prefix = "v"; };
  };

  meta = with lib; {
    description = "GI Crystal is a binding generator used to generate Crystal bindings for GObject based libraries using GObject Introspection";
    homepage = "https://github.com/hugopl/gi-crystal";
    mainProgram = "gi-crystal";
    maintainers = with maintainers; [ sund3RRR ];
  };
}
