{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  testers,
  fishnet,
}:

let
  # These files can be found in Stockfish/src/evaluate.h
  nnueBigFile = "nn-1111cefa1111.nnue";
  nnueBig = fetchurl {
    url = "https://tests.stockfishchess.org/api/nn/${nnueBigFile}";
    sha256 = "sha256-ERHO+hERa3cWG9SxTatMUPJuWSDHVvSGFZK+Pc1t4XQ=";
  };
  nnueSmallFile = "nn-37f18f62d772.nnue";
  nnueSmall = fetchurl {
    url = "https://tests.stockfishchess.org/api/nn/${nnueSmallFile}";
    sha256 = "sha256-N/GPYtdy8xB+HWqso4mMEww8hvKrY+ZVX7vKIGNaiZ0=";
  };
in
rustPlatform.buildRustPackage rec {
  pname = "fishnet";
  version = "2.9.4";

  src = fetchFromGitHub {
    owner = "lichess-org";
    repo = "fishnet";
    tag = "v${version}";
    hash = "sha256-JhllThFiHeC/5AAFwwZQ0mgbENIWP1cA7aD01DeDVL8=";
    fetchSubmodules = true;
  };

  postPatch = ''
    cp -v '${nnueBig}' 'Stockfish/src/${nnueBigFile}'
    cp -v '${nnueBig}' 'Fairy-Stockfish/src/${nnueBigFile}'
    cp -v '${nnueSmall}' 'Stockfish/src/${nnueSmallFile}'
    cp -v '${nnueSmall}' 'Fairy-Stockfish/src/${nnueSmallFile}'
  '';

  useFetchCargoVendor = true;
  cargoHash = "sha256-aUSppXw0UDqCDX7YX+sYNEcmiABXDn0nrow0H9UjpaA=";

  passthru.tests.version = testers.testVersion {
    package = fishnet;
  };

  meta = with lib; {
    description = "Distributed Stockfish analysis for lichess.org";
    homepage = "https://github.com/lichess-org/fishnet";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      tu-maurice
      thibaultd
    ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    mainProgram = "fishnet";
  };
}
