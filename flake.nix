{
  description = "My Blog/Website using Zola";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    # Helpers for producing system-specific outputs
    supportedSystems = ["x86_64-linux" "aarch64-linux"];
    forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f (import nixpkgs {inherit system;}));
    themeName = (builtins.fromTOML (builtins.readFile ./config.toml)).theme;
    theme' = pkgs: (pkgs.callPackage ./themes.nix {}).${themeName};
    site' = pkgs: let theme = theme' pkgs; in pkgs.callPackage ./default.nix {inherit theme themeName;};
  in {
    packages = forEachSupportedSystem (pkgs: let
      site = site' pkgs;
    in {
      inherit site;
      default = site;
    });
    apps = forEachSupportedSystem (pkgs: {
      default = let
        script = pkgs.writers.writeDash "pages" ''
          ${pkgs.miniserve}/bin/miniserve \
              --interfaces=127.0.0.1 \
              --index ${site' pkgs}/index.html \
              ${site' pkgs}
        '';
      in {
        type = "app";
        program = "${script}";
      };
    });
    devShells = forEachSupportedSystem (pkgs: let
      site = site' pkgs;
      theme = theme' pkgs;
    in {
      default = pkgs.mkShell {
        inputsFrom = [site];
        shellHook = ''
          mkdir -p themes
          ln -sn '${theme}' 'themes/${themeName}'
        '';
      };
    });
    formatter = forEachSupportedSystem (pkgs: pkgs.alejandra);
  };
}
