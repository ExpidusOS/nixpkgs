{
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  lib,
  nixosTests,
}:

buildGoModule rec {
  pname = "ghostunnel";
  version = "1.8.4";

  src = fetchFromGitHub {
    owner = "ghostunnel";
    repo = "ghostunnel";
    tag = "v${version}";
    hash = "sha256-NnRm1HEdfK6WI5ntilLSwdR2B5czG5CIcMFzl2TzEds=";
  };

  vendorHash = null;

  deleteVendor = true;

  # The certstore directory isn't recognized as a subpackage, but is when moved
  # into the vendor directory.
  postUnpack = ''
    mkdir -p $sourceRoot/vendor/ghostunnel
    mv $sourceRoot/certstore $sourceRoot/vendor/ghostunnel/
  '';

  passthru.tests = {
    nixos = nixosTests.ghostunnel;
    podman = nixosTests.podman-tls-ghostunnel;
  };

  meta = with lib; {
    broken = stdenv.hostPlatform.isDarwin;
    description = "TLS proxy with mutual authentication support for securing non-TLS backend applications";
    homepage = "https://github.com/ghostunnel/ghostunnel#readme";
    changelog = "https://github.com/ghostunnel/ghostunnel/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ roberth ];
    mainProgram = "ghostunnel";
  };
}
