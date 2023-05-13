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
        site = pkgs.stdenv.mkDerivation {
          pname = "jalil-salame.github.io";
          version = "0.1.0";
          src = self;
          nativeBuildInputs = [pkgs.zola];
          buildPhase = "zola build --output-dir $out";
        };
      in {
        checks = {};
        packages = {
          inherit site;
          default = site;
        };
        devShells.default = pkgs.mkShell {inputsFrom = [site];};
        formatter = pkgs.alejandra;
      }
    );
}
