{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
  makeWrapper,
  gh,
  fzf,
  coreutils,
  gawk,
  gnused,
  withBat ? false,
  bat,
}:
let
  binPath = lib.makeBinPath (
    [
      gh
      fzf
      coreutils
      gawk
      gnused
    ]
    ++ lib.optional withBat bat
  );
in
stdenvNoCC.mkDerivation rec {
  pname = "gh-f";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "gennaro-tedesco";
    repo = "gh-f";
    tag = "v${version}";
    hash = "sha256-62FVFW2KLdH0uonIf3OVBFMGLcCteMjydaLAjWtxwUo=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    install -D -m755 "gh-f" "$out/bin/gh-f"
  '';

  postFixup = ''
    wrapProgram "$out/bin/gh-f" --prefix PATH : "${binPath}"
  '';

  meta = with lib; {
    homepage = "https://github.com/gennaro-tedesco/gh-f";
    description = "GitHub CLI ultimate FZF extension";
    maintainers = with maintainers; [ loicreynier ];
    license = licenses.unlicense;
    mainProgram = "gh-f";
    platforms = platforms.all;
  };
}
