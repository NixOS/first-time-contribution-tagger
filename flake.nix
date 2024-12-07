{
  description = "A Tool for tagging PRs of First-Time Contributors with a specified label";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    pre-commit = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "";
        flake-compat.follows = "";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pre-commit,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:

      let
        pkgs = nixpkgs.legacyPackages.${system};
      in

      {
        checks = {
          pre-commit-check = pre-commit.lib.${system}.run {
            src = ./.;
            hooks = {
              black.enable = true;
              flake8.enable = true;
              isort.enable = true;
              nixfmt-rfc-style.enable = true;
            };
          };
        };

        packages = {
          default = self.packages.${system}.first-time-contribution-tagger;
          first-time-contribution-tagger = pkgs.callPackage ./nix/package.nix { inherit self; };
        };

        devShells.default = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;

          inputsFrom = [ self.packages.${system}.first-time-contribution-tagger ];
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    )
    // {
      # TODO: Remove when NixOS/infra no longer uses it
      nixosModule = self.nixosModules.default;

      nixosModules.default = nixpkgs.lib.modules.importApply ./nix/module.nix { inherit self; };
    };
}
