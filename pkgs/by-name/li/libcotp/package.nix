{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  libgcrypt,
}:

stdenv.mkDerivation rec {
  pname = "libcotp";
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "paolostivanin";
    repo = "libcotp";
    tag = "v${version}";
    sha256 = "sha256-Ol/vWaXcbDcy+d8V//fK4SYUpnYmwuYJxkO3/+kqgdM=";
  };

  postPatch = lib.optionalString stdenv.cc.isClang ''
    substituteInPlace CMakeLists.txt \
      --replace "add_link_options(-Wl," "# add_link_options(-Wl,"
  '';

  buildInputs = [ libgcrypt ];
  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  meta = with lib; {
    description = "C library that generates TOTP and HOTP";
    homepage = "https://github.com/paolostivanin/libcotp";
    license = licenses.asl20;
    maintainers = with maintainers; [ alexbakker ];
    platforms = platforms.all;
  };
}
