{
  description = "My Blog/Website using Zola";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.kangae.flake = false;
  inputs.kangae.url = "github:ayushnix/kangae";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    kangae,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        themeName = (builtins.fromTOML (builtins.readFile "${theme}/theme.toml")).name;
        theme = kangae;
        site = pkgs.stdenv.mkDerivation {
          pname = "jalil-salame.github.io";
          version = "2023-07-15";
          src = ./.;
          nativeBuildInputs = [pkgs.zola];
          configurePhase = ''	
            mkdir -p 'themes/${themeName}'
            cp -r ${theme}/* 'themes/${themeName}'
          '';
          buildPhase = "zola build --output-dir $out";
        };
      in {
        checks = {};
        packages = {
          inherit site;
          default = site;
        };
        apps.default = flake-utils.lib.mkApp {
          drv = pkgs.writeShellScriptBin "pages" "${pkgs.miniserve}/bin/miniserve --index ${site}/index.html ${site}";
        };
        devShells.default = pkgs.mkShell {
            inputsFrom = [site];
            shellHook = ''
                mkdir -p themes
                ln -sn '${theme}' 'themes/${themeName}'
            '';
        };
        formatter = pkgs.alejandra;
      }
    );
}
