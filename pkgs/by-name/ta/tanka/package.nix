{
  buildGoModule,
  fetchFromGitHub,
  lib,
  installShellFiles,
}:

buildGoModule rec {
  pname = "tanka";
  version = "0.31.3";

  src = fetchFromGitHub {
    owner = "grafana";
    repo = pname;
    tag = "v${version}";
    sha256 = "sha256-MaWO9I2+xHA+55tUSQ91yJ7suubnWP4V7JxZTruN1A0=";
  };

  vendorHash = "sha256-jTvKNl0L+Dl3u5qHQg0R/rtNtLljLoIvciXYKRe/zNg=";

  doCheck = false;
  # Required for versions >= 0.28 as they introduce a gowork.sum file. This is only used for tests so we can safely disable GOWORK
  env.GOWORK = "off";

  subPackages = [ "cmd/tk" ];

  ldflags = [
    "-s"
    "-w"
    "-extldflags '-static'"
    "-X github.com/grafana/tanka/pkg/tanka.CurrentVersion=v${version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    echo "complete -C $out/bin/tk tk" > tk.bash

    cat >tk.fish <<EOF

    function __complete_tk
        set -lx COMP_LINE (commandline -cp)
        test -z (commandline -ct)
        and set COMP_LINE "\$COMP_LINE "
        $out/bin/tk
    end
    complete -f -c tk -a "(__complete_tk)"

    EOF

    cat >tk.zsh <<EOF
    #compdef tk
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C $out/bin/tk tk
    EOF

    installShellCompletion \
      --cmd tk \
      --bash tk.bash \
      --fish tk.fish \
      --zsh tk.zsh
  '';

  meta = with lib; {
    description = "Flexible, reusable and concise configuration for Kubernetes";
    homepage = "https://tanka.dev";
    license = licenses.asl20;
    maintainers = with maintainers; [ mikefaille ];
    mainProgram = "tk";
  };
}
