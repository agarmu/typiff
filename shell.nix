{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShellNoCC {
  packages = with pkgs; [
    /* rust development -- toolchain */
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer
    rustPlatform.rustLibSrc
    /* typst development */
    typst
    tinymist
    typstyle
    /* wasm development */
    wasm-tools
    /* general tools */
    lld
    gnumake
    pkg-config
  ];

  RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
}
