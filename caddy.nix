{ lib, buildGo118Module, fetchFromGitHub, nixosTests, plugins ? [ ], pkgs }:
let
  version = "2.6.0-beta.3";

  dist = fetchFromGitHub {
    owner = "caddyserver";
    repo = "dist";
    rev = "v${version}";
    sha256 = "sha256-yw84ooXEqamWKANXmd5pU5Ig7ANDplBUwynF/qPLq1g=";
  };

  imports = lib.flip lib.concatMapStrings plugins (pkg: "  _ \"${pkg}\"\n");

  main = ''
    package main

    import (
      caddycmd "github.com/caddyserver/caddy/v2/cmd"
      _ "github.com/caddyserver/caddy/v2/modules/standard"
    ${imports}
    )

    func main() {
      caddycmd.Main()
    }
  '';

in buildGo118Module {
  pname = "caddy";
  inherit version;
  runVend = true;

  subPackages = [ "cmd/caddy" ];

  src = fetchFromGitHub {
    owner = "caddyserver";
    repo = "caddy";
    rev = "v${version}";
    sha256 = "sha256-PAm/XsxDwsnI7ICAz4867DzSNKurgL1/o4TcLyjaqzE=";
  };

  vendorSha256 = "sha256-0PzFRTN/DQ+u1OVLVUakVbl44LsvU36nhaGSIOp9K84=";

  overrideModAttrs = (_: {
    preBuild = ''
      echo '${main}'
      echo '${main}' > cmd/caddy/main.go
    '';
    postInstall = "cp go.sum go.mod $out/ && ls $out/";
  });

  postPatch = ''
    echo '${main}' > cmd/caddy/main.go
    cat cmd/caddy/main.go
  '';

  postConfigure = ''
    cp vendor/go.sum ./
    cp vendor/go.mod ./
  '';

  postInstall = ''
    install -Dm644 ${dist}/init/caddy.service ${dist}/init/caddy-api.service -t $out/lib/systemd/system

    substituteInPlace $out/lib/systemd/system/caddy.service --replace "/usr/bin/caddy" "$out/bin/caddy"
    substituteInPlace $out/lib/systemd/system/caddy-api.service --replace "/usr/bin/caddy" "$out/bin/caddy"
  '';

  passthru.tests = { inherit (nixosTests) caddy; };

  meta = with lib; {
    homepage = "https://caddyserver.com";
    description = "Fast, cross-platform HTTP/2 web server with automatic HTTPS";
    license = licenses.asl20;
    maintainers = with maintainers; [ Br1ght0ne techknowlogick ];
  };
}
