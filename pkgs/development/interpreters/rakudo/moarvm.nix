{
  lib,
  stdenv,
  fetchFromGitHub,
  perl,
  CoreServices,
  ApplicationServices,
}:

stdenv.mkDerivation rec {
  pname = "moarvm";
  version = "2025.01";

  # nixpkgs-update: no auto update
  src = fetchFromGitHub {
    owner = "moarvm";
    repo = "moarvm";
    tag = version;
    hash = "sha256-Xvkn1edzOeXBiBn2QSwk0eKfSG1JvfSkVrCAmyYtlmI=";
    fetchSubmodules = true;
  };

  postPatch =
    ''
      patchShebangs .
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      substituteInPlace Configure.pl \
        --replace '`/usr/bin/arch`' '"${stdenv.hostPlatform.darwinArch}"' \
        --replace '/usr/bin/arch' "$(type -P true)" \
        --replace '/usr/' '/nope/'
      substituteInPlace 3rdparty/dyncall/configure \
        --replace '`sw_vers -productVersion`' '"11.0"'
    '';

  buildInputs =
    [ perl ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      CoreServices
      ApplicationServices
    ];
  doCheck = false; # MoarVM does not come with its own test suite

  configureScript = "${perl}/bin/perl ./Configure.pl";

  meta = with lib; {
    description = "VM with adaptive optimization and JIT compilation, built for Rakudo";
    homepage = "https://moarvm.org";
    license = licenses.artistic2;
    maintainers = with maintainers; [
      thoughtpolice
      sgo
    ];
    mainProgram = "moar";
    platforms = platforms.unix;
  };
}
