{
  description = "Vereis' Blog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (
      system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs { inherit system overlays; };
          rustToolchain = pkgs.rust-bin.nightly.latest.default;
        in
        with pkgs; {
          devShells.default = mkShell {
            buildInputs = [
              elixir
              erlang
              rustToolchain
            ]
              ++ lib.optionals stdenv.isLinux  ([ inotify-tools ])
              ++ lib.optionals stdenv.isDarwin ([ darwin.apple_sdk.frameworks.CoreFoundation
                                                  darwin.apple_sdk.frameworks.CoreServices
                                               ]);

            shellHook = ''
              export ERL_AFLAGS="-kernel shell_history enabled"
              
              if [ -f .env ]; then
                export $(cat .env | xargs)
              fi
              
              # Build mcp-proxy if not already in PATH
              if ! command -v mcp-proxy &> /dev/null; then
                if [ ! -f ./bin/mcp-proxy ]; then
                  echo "Building mcp-proxy from source..."
                  cargo install --git https://github.com/tidewave-ai/mcp_proxy_rust --root . --locked
                fi
                export PATH="$PWD/bin:$PATH"
              fi
            '';
          };
        }
    );
}
