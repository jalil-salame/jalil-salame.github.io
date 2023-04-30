{
  description = "My Blog/Website using Zola";

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
            pname = "jalil-salame";
            version = "0.1.0";
            src = self;
            buildInputs = [pkgs.zola];
            buildPhase = "zola build";
          };
          default = site;
        };
        devShells.default = pkgs.mkShell {buildInputs = [pkgs.zola];};
        formatter = pkgs.alejandra;
      }
    );
}
