{ stdenv, fetchFromGitHub
, pkg-config
, gnumake
, xorg
, pango
, yajl
}:
stdenv.mkDerivation {
  pname = "dwm";
  version = "6.6";
  src = fetchFromGitHub {
    owner = "novel2430";
    repo = "DWM-6.6";
    rev = "cd59b8271d3f8555c9fc7713e1f739611a557c3b";
    sha256 = "sha256-HxdLO/1sh+s8+O6XCHIMLTaeW4P1RBV2l/S0C84uuWQ=";
  };

  nativeBuildInputs = [
    pkg-config
    gnumake
  ];

  buildInputs = with xorg; [
    pango
    yajl
    libX11
    libXft
    libXinerama
  ];

  buildPhase = ''
    runHook preBuild
    make
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    install -Dm555 dwm $out/bin/dwm
    install -Dm555 dwm-msg $out/bin/dwm-msg

    runHook postInstall
  '';
}

