{
  description = "My Blog/Website using Zola";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  inputs.kangae.flake = false;
  inputs.kangae.url = "github:ayushnix/kangae";

  outputs = {
    self,
    nixpkgs,
    kangae,
  }: let
    # Helpers for producing system-specific outputs
    supportedSystems = ["x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux"];
    forEachSupportedSystem' = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
          inherit system;
        });
    forEachSupportedSystem = f: forEachSupportedSystem' ({pkgs, ...}: f pkgs);
    themeName = (builtins.fromTOML (builtins.readFile "${theme}/theme.toml")).name;
    theme = kangae;
  in {
    packages = forEachSupportedSystem (pkgs: let
      site = pkgs.stdenv.mkDerivation {
        pname = "jalil-salame.github.io";
        version = "2024-02-10";
        src = builtins.path {
          path = ./.;
          name = "blog";
        };
        nativeBuildInputs = [pkgs.zola];
        configurePhase = ''
          mkdir -p 'themes/${themeName}'
          cp -r ${theme}/* 'themes/${themeName}'
        '';
        buildPhase = "zola build --output-dir $out";
      };
    in {
      inherit site;
      default = site;
    });
    formatter = forEachSupportedSystem (pkgs: pkgs.nixpkgs-fmt);
    apps = forEachSupportedSystem' ({
      pkgs,
      system,
    }: let
      site = self.packages.${system}.site;
      serve = pkgs.writeShellScriptBin "pages" "${pkgs.miniserve}/bin/miniserve --interfaces=127.0.0.1 --index ${site}/index.html ${site}";
    in {
      default.type = "app";
      default.program = "${serve}/bin/pages";
    });
    devShells = forEachSupportedSystem' ({
      pkgs,
      system,
    }: {
      default = pkgs.mkShell {
        inputsFrom = [self.packages.${system}.site];
        shellHook = ''
          mkdir -p themes
          ln -snf '${theme}' 'themes/${themeName}'
        '';
      };
    });
  };
}
