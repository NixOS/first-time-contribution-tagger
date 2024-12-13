{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;

  cfg = config.services.first-time-contribution-tagger;

  package =
    (self.packages.${system}
      or (throw "first-time-contribution-tagger: ${system} is not supported by our Flake!")
    ).first-time-contribution-tagger;
in

{
  options.services.first-time-contribution-tagger = {
    enable = lib.mkEnableOption "Enables the first-time-contribution-tagger service";

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
      description = lib.mdDoc "config environment variables, for other options read the [documentation](https://github.com/janik-Haag/first-time-contribution-tagger)";
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

    interval = lib.mkOption {
      default = "*:0/10";
      type = lib.types.str;
      example = lib.literalExpression "*:0/10";
      description = lib.mdDoc "systemd-timer OnCalendar config, the above example starts the unit every 10 minutes";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.first-time-contribution-tagger = {
      description = "first-time-contribution-tagger service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      inherit (cfg) environment;

      serviceConfig = {
        DynamicUser = true;
        WorkingDirectory = "%S/first-time-contribution-tagger";
        StateDirectory = "first-time-contribution-tagger";
        StateDirectoryMode = "0700";
        UMask = "0007";
        ConfigurationDirectory = "first-time-contribution-tagger";
        EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
        ExecStart = lib.getExe package;
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
    };

    systemd.timers.first-time-contribution-tagger = {
      wantedBy = [ "timers.target" ];
      after = [ "multi-user.target" ];
      timerConfig = {
        OnCalendar = cfg.interval;
      };
    };
  };
}
