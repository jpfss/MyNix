# emacs29-x11-gtk3-xwidgets-webkit41.nix
{ pkgs, ... }:

let
  lib = pkgs.lib;

  version = "29.4";
  rev = "emacs-29.4";

  src = pkgs.fetchzip {
    url = "mirror://gnu/emacs/${rev}.tar.xz";
    hash = "sha256-p4jFYnpWdq7op8VqMpvEgdXNkqpyxznli5q6K1TEohk=";
  };

  siteStart = pkgs.writeText "site-start.el" ''
    ;; Minimal site-start for Nix-built Emacs.
    ;; Keep empty on purpose.
  '';

  # knobs
  withNativeCompilation = false;
  withDbus = pkgs.stdenv.hostPlatform.isLinux;
  withSystemd = lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.systemd;
  withSelinux = pkgs.stdenv.hostPlatform.isLinux;
  withMailutils = true;
  withSQLite3 = true;
  withTreeSitter = true;
  withWebP = true;
  withGlibNetworking = true;        # GTK / WebKit 常用
  withToolkitScrollBars = true;
  withCompressInstall = true;

  # X11 knobs
  withX = true;
  withGTK3 = true;                  # toolkit=gtk3
  withXwidgets = true;              # keep xwidgets
  withCairo = true;                 # nixpkgs 預設 withX 時會打開 cairo
  withXinput2 = true;

in

pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "emacs-29-x11-gtk3-xwidgets-webkit41";
  inherit version src;

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.makeWrapper
    pkgs.wrapGAppsHook3
    pkgs.texinfo
  ];

  buildInputs =
    [
      pkgs.gettext
      pkgs.gnutls
      (lib.getDev pkgs.harfbuzz)
      pkgs.libxml2
      pkgs.ncurses

      # X11 + GTK3 toolkit stack
      pkgs.gtk3-x11
      pkgs.gsettings-desktop-schemas

      # X11 text input / intl (和 nixpkgs 官方一致的思路)
      pkgs.libotf
      pkgs.m17n_lib

      # X11 libs（和 nixpkgs 官方 withX 分支接近）
      pkgs.Xaw3d
      pkgs.libxaw
      pkgs.libxpm
      pkgs.libxrandr
      pkgs.libxi
    ]
    ++ lib.optionals withCairo [
      pkgs.cairo
    ]
    ++ lib.optionals withGlibNetworking [
      pkgs.glib-networking
    ]
    ++ lib.optionals withDbus [
      pkgs.dbus
    ]
    ++ lib.optionals withSelinux [
      pkgs.libselinux
    ]
    ++ lib.optionals withSQLite3 [
      pkgs.sqlite
    ]
    ++ lib.optionals withSystemd [
      pkgs.systemd
    ]
    ++ lib.optionals withTreeSitter [
      pkgs.tree-sitter
    ]
    ++ lib.optionals withWebP [
      pkgs.libwebp
    ]
    ++ [
      # common image libs
      pkgs.giflib
      pkgs.libjpeg
      pkgs.libpng
      pkgs.librsvg
      pkgs.libtiff
      pkgs.libxpm
    ]
    ++ [
      # xwidgets on Linux needs WebKitGTK — force 4.1
      pkgs.webkitgtk_4_1
    ]
    ++ lib.optionals withNativeCompilation [
      pkgs.libgccjit
      pkgs.zlib
    ];

  propagatedUserEnvPkgs = lib.optionals withMailutils [
    pkgs.mailutils
  ];

  postPatch = lib.concatStringsSep "\n" [
    ''
      find . -type f \( -name "*.elc" -o -name "*loaddefs.el" \) -exec rm -f {} \; || true
    ''

    ''
      for fn in tramp-compat-process-running-p tramp-process-running-p; do
        sed -i 's#('"$fn"' "gvfs-fuse-daemon")#('"$fn"' "gvfs-fuse-daemon") ('"$fn"' ".gvfsd-fuse-wrapped")#' lisp/net/tramp-gvfs.el || true
      done
    ''

    ''
      substituteInPlace src/Makefile.in \
        --replace 'RUN_TEMACS = ./temacs' 'RUN_TEMACS = env -i ./temacs'
    ''

    ''
      substituteInPlace lisp/international/mule-cmds.el \
        --replace /usr/share/locale ${pkgs.gettext}/share/locale || true

      for makefile_in in $(find . -name Makefile.in -print); do
        substituteInPlace "$makefile_in" --replace /bin/pwd pwd || true
      done
    ''

    ''
      substituteInPlace lisp/net/mailcap.el \
        --replace-fail '"/etc/mime.types"' \
                       '"/etc/mime.types" "${pkgs.mailcap}/etc/mime.types"' \
        --replace-fail '("/etc/mailcap" system)' \
                       '("/etc/mailcap" system) ("${pkgs.mailcap}/etc/mailcap" system)' || true
    ''
  ];

  hardeningDisable = [ "format" ];
  enableParallelBuilding = true;

  configureFlags =
    [
      (lib.enableFeature false "build-details")
      (lib.withFeature true "modules")

      # ---- X11 + GTK3 (NOT pgtk) ----
      (lib.withFeature true "x")
      "--with-x-toolkit=gtk3"
      (lib.withFeature withCairo "cairo")
      (lib.withFeature withXinput2 "xinput2")

      (lib.withFeature false "pgtk")

      # xwidgets (requires GTK3 on X11)
      (lib.withFeature true "xwidgets")

      (lib.withFeature withCompressInstall "compress-install")
      (lib.withFeature withToolkitScrollBars "toolkit-scroll-bars")

      (lib.withFeature withNativeCompilation "native-compilation")

      (lib.withFeature withMailutils "mailutils")
      (lib.withFeature withTreeSitter "tree-sitter")
      (lib.withFeature withSQLite3 "sqlite3")
      (lib.withFeature withDbus "dbus")
      (lib.withFeature withSelinux "selinux")
    ];

  env =
    lib.optionalAttrs withNativeCompilation {
      NATIVE_FULL_AOT = "1";
      LIBRARY_PATH = lib.concatStringsSep ":" [
        "${lib.getLib pkgs.libgccjit}/lib/gcc"
        "${lib.getLib pkgs.stdenv.cc.libc}/lib"
      ];
    };

  installTargets = [ "tags" "install" ];

  postInstall = ''
    mkdir -p $out/share/emacs/site-lisp
    cp ${siteStart} $out/share/emacs/site-lisp/site-start.el
    $out/bin/emacs --batch -f batch-byte-compile $out/share/emacs/site-lisp/site-start.el || true

    siteVersionDir="$(ls $out/share/emacs | grep -v site-lisp | head -n 1)"
    rm -rf "$out/share/emacs/$siteVersionDir/site-lisp" || true

    for srcdir in src lisp lwlib ; do
      dstdir="$out/share/emacs/$siteVersionDir/$srcdir"
      mkdir -p "$dstdir"
      find "$srcdir" -name "*.[chm]" -exec cp {} "$dstdir" \; || true
      cp "$srcdir/TAGS" "$dstdir" || true
      echo '((nil . ((tags-file-name . "TAGS"))))' > "$dstdir/.dir-locals.el"
    done
  ''
  + lib.optionalString withNativeCompilation ''
    echo "Generating native-compiled trampolines..."
    $out/bin/emacs --batch --eval "(mapatoms (lambda (s) \
      (when (subr-primitive-p (symbol-function s)) (print s))))" \
      | xargs -n $((1000/NIX_BUILD_CORES + 1)) -P $NIX_BUILD_CORES \
        $out/bin/emacs --batch -l comp --eval "(while argv \
          (comp-trampoline-compile (intern (pop argv))))" || true

    mkdir -p $out/share/emacs/native-lisp
    $out/bin/emacs --batch \
      --eval "(add-to-list 'native-comp-eln-load-path \"$out/share/emacs/native-lisp\")" \
      -f batch-native-compile $out/share/emacs/site-lisp/site-start.el || true
  '';

  postFixup = ''
    # Keep xwidgets/WebKit stability knobs
    wrapProgram "$out/bin/emacs" \
      --set-default GDK_GL disable \
      --set-default WEBKIT_DISABLE_COMPOSITING_MODE 1

    if [ -x "$out/bin/emacsclient" ]; then
      wrapProgram "$out/bin/emacsclient" \
        --set-default GDK_GL disable \
        --set-default WEBKIT_DISABLE_COMPOSITING_MODE 1
    fi
  '';

  passthru = {
    inherit withNativeCompilation;
    withXwidgets = true;
    withX11 = true;
    withGtk3 = true;
  };

  meta = with lib; {
    description = "GNU Emacs 29.4 (X11 + GTK3 toolkit + xwidgets, forced WebKitGTK 4.1) – standalone derivation";
    homepage = "https://www.gnu.org/software/emacs/";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "emacs";
  };
})
