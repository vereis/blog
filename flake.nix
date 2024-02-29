{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
        let
          pkgs = import nixpkgs { inherit system; };

          # `sha256` can be programmatically obtained via running the following:
          # `nix-prefetch-url --unpack https://github.com/elixir-lang/elixir/archive/v${version}.tar.gz`
          elixir_1_15_7 = (pkgs.beam.packagesWith pkgs.erlangR26).elixir_1_15.override {
            version = "1.15.7";
            sha256 = "0yfp16fm8v0796f1rf1m2r0m2nmgj3qr7478483yp1x5rk4xjrz8";
          };
        in
        with pkgs; {
          devShells.default = mkShell {
            buildInputs = [
              # API Deps ------------------------------------
              elixir_1_15_7 sqlite

              # Web Deps ------------------------------------
              nodePackages.prettier nodejs_20
            ]
              ++ lib.optionals stdenv.isLinux  ([ libnotify inotify-tools ])
              ++ lib.optionals stdenv.isDarwin ([ terminal-notifier
                                                  darwin.apple_sdk.frameworks.CoreFoundation
                                                  darwin.apple_sdk.frameworks.CoreServices
                                               ]);

            env = {
              ERL_AFLAGS = "-kernel shell_history enabled";
            };
          };
        }
    );
}
