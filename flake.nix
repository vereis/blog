{
  description = "Vereis' Blog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        with pkgs; {
          devShells.default = mkShell {
            buildInputs = [
              elixir
              erlang
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
            '';
          };
        }
    );
}
