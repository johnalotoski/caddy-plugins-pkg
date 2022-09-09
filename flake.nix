{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  outputs = {self, nixpkgs}: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in  {
    packages.x86_64-linux.caddy = pkgs.callPackage ./caddy.nix {
      plugins = [
        "github.com/caddyserver/nginx-adapter"
        "github.com/caddyserver/ntlm-transport"
      ];
    };
  };
}
