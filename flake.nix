{
  description = "A Tool for tagging PRs of First-Time Contributors with a specified label";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit.inputs.nixpkgs-stable.follows = "";
    pre-commit.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, pre-commit, ... }:
    flake-utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          checks = {
            pre-commit-check = pre-commit.lib.${system}.run {
              src = ./.;
              hooks = {
                nixpkgs-fmt.enable = true;
                isort.enable = true;
                black.enable = true;
                flake8.enable = true;
              };
            };
          };
          defaultPackage = with pkgs.python3Packages; pkgs.python3.pkgs.buildPythonApplication {
            pname = "first-time-contribution-tagger";
            version = "0.1.1";
            pyproject = true;

            src = ./.;

            nativeBuildInputs = [
              poetry-core
            ];

            propagatedBuildInputs = [
              requests
            ];

            nativeCheckInputs = [
              pytestCheckHook
            ];
            meta = with pkgs.lib; {
              license = licenses.agpl3Only;
              maintainers = with maintainers; [ janik ];
            };
          };
          devShell = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = with pkgs; [
              python3.pkgs.requests
            ];
          };
        }
      ) // {
      nixosModule = { config, lib, pkgs, ... }:
        let cfg = config.services.first-time-contribution-tagger;
        in {
          options.services.first-time-contribution-tagger = {
            enable = lib.mkEnableOption "Enables the first-time-contribution-tagger service";
            interval = lib.mkOption {
              default = "*:0/10";
              type = lib.types.str;
              example = lib.literalExpression "*:0/10";
              description = lib.mdDoc "systemd-timer OnCalendar config, the above example starts the unit every 10 minutes";
            };
            environment = lib.mkOption {
              default = { };
              type = lib.types.attrsOf lib.types.str;
              example = lib.literalExpression ''
                {
                  FIRST_TIME_CONTRIBUTION_LABEL="12. first-time contribution";
                  FIRST_TIME_CONTRIBUTION_CACHE="/var/lib/first-time-contribution-tagger/cache";
                  FIRST_TIME_CONTRIBUTION_REPO="nixpkgs";
                  FIRST_TIME_CONTRIBUTION_ORG="NixOS";
                }
              '';
              description = lib.mdDoc "config envrionment variables, for other options read the [documentation](https://github.com/janik-Haag/first-time-contribution-tagger)";
            };
            environmentFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              example = "/root/first-time-contribution-tagger.env";
              description = lib.mdDoc ''
                File to load environment variables
                from. This is helpful for specifying secrets.
                Example content of environmentFile:
                ```
                FIRST_TIME_CONTRIBUTION_GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
                ```
              '';
            };
          };
          config = lib.mkIf cfg.enable {
            systemd.timers.first-time-contribution-tagger = {
              wantedBy = [ "timers.target" ];
              after = [ "multi-user.target" ];
              timerConfig = {
                OnCalendar = cfg.interval;
              };
            };
            systemd.services.first-time-contribution-tagger = {
              description = "first-time-contribution-tagger service";
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              serviceConfig = {
                DynamicUser = true;
                WorkingDirectory = "%S/first-time-contribution-tagger";
                StateDirectory = "first-time-contribution-tagger";
                StateDirectoryMode = "0700";
                UMask = "0007";
                ConfigurationDirectory = "first-time-contribution-tagger";
                EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
                ExecStart = "${self.defaultPackage.${pkgs.system}}/bin/first-time-contribution-tagger";
                Restart = "on-failure";
                RestartSec = 15;
                CapabilityBoundingSet = "";
                # Security
                NoNewPrivileges = true;
                # Sandboxing
                ProtectSystem = "strict";
                ProtectHome = true;
                PrivateTmp = true;
                PrivateDevices = true;
                PrivateUsers = true;
                ProtectHostname = true;
                ProtectClock = true;
                ProtectKernelTunables = true;
                ProtectKernelModules = true;
                ProtectKernelLogs = true;
                ProtectControlGroups = true;
                RestrictAddressFamilies = [ "AF_UNIX AF_INET AF_INET6" ];
                LockPersonality = true;
                MemoryDenyWriteExecute = true;
                RestrictRealtime = true;
                RestrictSUIDSGID = true;
                PrivateMounts = true;
                # System Call Filtering
                SystemCallArchitectures = "native";
                SystemCallFilter = "~@clock @privileged @cpu-emulation @debug @keyring @module @mount @obsolete @raw-io @reboot @setuid @swap";
              };
              inherit (cfg) environment;
            };
          };
        };
    };
}

