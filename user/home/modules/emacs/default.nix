{pkgs, custom-pkgs, opt-config, pkgs-2505, ...}: 
let
in
{
  home.packages = with pkgs; [
  	## For Emacs
  	custom-pkgs.emacs29-gtk-xwidget
    ripgrep
    findutils
    fd
    libtool
    #pkgs.nerd-fonts.symbols-only

	## For LSP
    pandoc # Markdown
    shellcheck # Shell
    lua-language-server # Lua
    pyright # Python
    clang-tools # C family
    jdt-language-server # Java
    nil # Nix
    nodePackages.bash-language-server # Bash
    rust-analyzer # Rust
    vue-language-server typescript # Vue
    typescript-language-server # TS, JS, TSX
    kotlin-language-server # Kotlin

    custom-pkgs.rassumfrassum

	## For Treesitter
  ];

}
