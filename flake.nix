{
  description = "My Blog/Website using Zola";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        checks = {};
        packages = rec {
          site = pkgs.stdenv.mkDerivation {
            pname = "jalil-salame.github.io";
            version = "0.1.0";
            src = self;
            buildInputs = [pkgs.zola];
            buildPhase = "zola build";
            installPhase = ''
              mkdir -p $out
              cp -r public/* $out
            '';
          };
          default = site;
        };
        devShells.default = pkgs.mkShell {buildInputs = [pkgs.zola];};
        formatter = pkgs.alejandra;
      }
    );
}
