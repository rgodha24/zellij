{
  description = "Zellij with OSC52 clipboard read support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-wasip1" ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustToolchain
            pkg-config
            openssl
            libiconv
            protobuf
            
            # Additional build tools
            cargo
            rustc
            rust-analyzer
          ];

          shellHook = ''
            echo "Zellij development environment"
            echo "Rust version: $(rustc --version)"
            echo ""
            echo "To build:"
            echo "  cargo build --release"
            echo ""
            echo "To run:"
            echo "  cargo run --release"
            echo ""
            echo "Binary will be at: target/release/zellij"
          '';

          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        };

        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "zellij";
          version = "0.41.2-osc52-clipboard-read";

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
          ];

          meta = with pkgs.lib; {
            description = "Zellij with OSC52 clipboard read support";
            homepage = "https://github.com/zellij-org/zellij";
            license = licenses.mit;
          };
        };
      }
    );
}
