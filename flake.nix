{
  description = "My Blog/Website using Zola";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ inputs.treefmt-nix.flakeModule ];

      perSystem =
        { pkgs, ... }:
        let
          themeName = (builtins.fromTOML (builtins.readFile ./config.toml)).theme;
          theme = (pkgs.callPackage ./themes.nix { }).${themeName};
          site = pkgs.callPackage ./default.nix { inherit theme themeName; };
        in
        {
          packages = {
            inherit site;
            default = site;
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              statix.enable = true;
              typos.enable = true;
            };
            settings.formatter.typos.excludes = [ "static/*" ];
          };

          apps.default =
            let
              script = pkgs.writers.writeDash "pages" ''
                ${pkgs.miniserve}/bin/miniserve \
                    --interfaces=127.0.0.1 \
                    --index ${site}/index.html \
                    ${site}
              '';
            in
            {
              type = "app";
              program = "${script}";
            };

          devShells.default = pkgs.mkShell {
            inputsFrom = [ site ];
            shellHook = ''
              mkdir -p themes
              ln -sn ${theme} themes/${themeName}
            '';
          };
        };
    };
}
