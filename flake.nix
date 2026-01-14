{
  description = "Zellij";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = ["wasm32-wasip1"];
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustToolchain
            pkg-config
            openssl
            libiconv
            curl
            protobuf

            # Additional build tools
            cargo
            rustc
            rust-analyzer
            zlib
          ];

          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        };

        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "zellij";
          version = "0.44.1";

          src = ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            protobuf
            rustToolchain
            perl
          ];

          buildInputs = with pkgs; [
            openssl
            libiconv
            curl
            zlib
          ];

          meta = with pkgs.lib; {
            description = "Zellij";
            homepage = "https://github.com/rgodha24/zellij";
            license = licenses.mit;
          };
        };
      }
    );
}
