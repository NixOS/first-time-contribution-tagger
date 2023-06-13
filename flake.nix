{
  description = "A Tool for tagging PRs of First-Time Contributors with a specified label";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix.url = "github:nix-community/poetry2nix";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix, pre-commit-hooks, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ poetry2nix.overlay ]; };
      in
      {
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              isort.enable = true;
              black.enable = true;
              #autoflake.enable = true;
              flake8.enable = true;
            };
          };
        };
        defaultPackage = pkgs.poetry2nix.mkPoetryApplication {
          projectDir = ./.;
        };
        devShell = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = with pkgs; [
            python3Packages.types-pyyaml
            (pkgs.poetry2nix.mkPoetryEnv {
              projectDir = ./.;

              editablePackageSources = {
                my-app = ./src;
              };
            })
          ];
        };
      }
    );
}

