{
  stdenvNoCC,
  zola,
  theme,
  themeName,
}:
stdenvNoCC.mkDerivation {
  pname = "jalil-salame.github.io";
  version = "2023-07-15";
  src = ./.;
  nativeBuildInputs = [ zola ];
  # Add theme to themes folder
  patchPhase = ''
    mkdir -p 'themes/${themeName}'
    cp -r ${theme}/* 'themes/${themeName}'
  '';
  buildPhase = "zola build --output-dir $out";
}
