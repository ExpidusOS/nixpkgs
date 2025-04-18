{
  fetchFromGitHub,
  lib,
  stdenv,
}:

stdenv.mkDerivation rec {
  pname = "bash_unit";
  version = "2.3.2";

  src = fetchFromGitHub {
    owner = "pgrange";
    repo = "bash_unit";
    tag = "v${version}";
    sha256 = "sha256-n5ehN7NrWID72xP7EYOk/mpnQJaDn71esIugWrLbZr0=";
  };

  patchPhase = ''
    runHook prePatch

    patchShebangs bash_unit

    for t in tests/test_*; do
      chmod +x "$t" # make test file visible to `patchShebangs`
      patchShebangs "$t"
      chmod -x "$t"
    done

    runHook postPatch
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck

    ./bash_unit ./tests/test_core.sh

    runHook postCheck
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bash_unit $out/bin/
  '';

  meta = with lib; {
    description = "Bash unit testing enterprise edition framework for professionals";
    maintainers = with maintainers; [ pamplemousse ];
    platforms = platforms.all;
    license = licenses.gpl3Plus;
    mainProgram = "bash_unit";
  };
}
