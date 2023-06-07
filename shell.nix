{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  inherit (lib) optional optionals;

  elixir = (beam.packagesWith erlangR25).elixir.override {
    version = "1.15.0-rc.1";
    sha256 = "11ydbbwcd4jlqhh49a0q7q9i9qwar9wb9z2pjmi4rx7g9akc8kdy";
  };
in

mkShell {
  buildInputs = [
    # Backend
    elixir
    pkgs.sqlite
    pkgs.inotify-tools

    # Frontend
    pkgs.nodejs_20
  ];

  ERL_AFLAGS = "-kernel shell_history enabled";
}
