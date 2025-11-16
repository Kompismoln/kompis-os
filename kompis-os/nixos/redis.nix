{
  config,
  lib,
  pkgs,
  lib',
  ...
}:
let
  cfg = config.kompis-os.redis;

  mkValueString =
    value:
    if value == true then
      "yes"
    else if value == false then
      "no"
    else
      lib.generators.mkValueStringDefault { } value;

  redisConfig =
    settings:
    pkgs.writeText "redis.conf" (
      lib.generators.toKeyValue {
        listsAsDuplicateKeys = true;
        mkKeyValue = lib.generators.mkKeyValueDefault { inherit mkValueString; } " ";
      } settings
    );

  eachServer = lib.filterAttrs (server: serverCfg: serverCfg.enable) config.kompis-os.redis.servers;

in
{
  options = {
    kompis-os.redis = {
      package = lib.mkPackageOption pkgs "redis" { };

      servers = lib.mkOption {
        description = "Configuration of multiple `redis-server` instances.";
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule (
            { config, name, ... }:
            {
              options = {
                enable = lib.mkEnableOption "Redis server";
                entity = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                };
                user = lib.mkOption {
                  type = lib.types.str;
                  default = config.entity;
                };
                home = lib.mkOption {
                  description = "path to app's filesystem";
                  default = "/var/lib/${config.entity}/redis";
                  type = lib.types.str;
                };
                extraParams = lib.mkOption {
                  description = "Extra parameters to append to redis-server invocation";
                  type = with lib.types; listOf str;
                  default = [ ];
                };
                bind = lib.mkOption {
                  description = ''The IP interface to bind to. `null` means "all interfaces".'';
                  type = lib.types.str;
                  default = "127.0.0.1";
                };
                unixSocket = lib.mkOption {
                  description = "The path to the socket to bind to.";
                  type = with lib.types; nullOr path;
                  default = "/run/${name}/redis.sock";
                };
                unixSocketPerm = lib.mkOption {
                  description = "Change permissions for the socket";
                  type = lib.types.int;
                  default = 660;
                };
                logLevel = lib.mkOption {
                  description = ''Specify the server verbosity level, options: debug, verbose, notice, warning.'';
                  type = lib.types.str;
                  default = "notice";
                };
                syslog = lib.mkOption {
                  description = "Enable logging to the system logger.";
                  type = lib.types.bool;
                  default = true;
                };
                databases = lib.mkOption {
                  description = "Set the number of databases.";
                  type = lib.types.int;
                  default = 16;
                };
                maxclients = lib.mkOption {
                  description = "Set the max number of connected clients at the same time.";
                  type = lib.types.int;
                  default = 10000;
                };
                save = lib.mkOption {
                  description = ''
                    The schedule in which data is persisted to disk, represented
                    as a list of lists where the first element represent the
                    amount of seconds and the second the number of changes.

                    If set to the empty list (`[]`) then RDB persistence will be
                    disabled (useful if you are using AOF or don't want any
                    persistence).
                  '';
                  type = with lib.types; listOf (listOf int);
                  default = [
                    [
                      900
                      1
                    ]
                    [
                      300
                      10
                    ]
                    [
                      60
                      10000
                    ]
                  ];
                };
                slaveOf = lib.mkOption {
                  description = "IP and port to which this redis instance acts as a slave.";
                  default = null;
                  type =
                    with lib.types;
                    nullOr (submodule {
                      options = {
                        ip = lib.mkOption {
                          type = str;
                          description = "IP of the Redis master";
                        };
                        port = lib.mkOption {
                          type = port;
                          description = "port of the Redis master";
                        };
                      };
                    });
                };
                requirePass = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
                appendOnly = lib.mkOption {
                  description = ''
                    By default data is only periodically persisted to disk, enable
                    this option to use an append-only file for improved
                    persistence.
                  '';
                  type = lib.types.bool;
                  default = false;
                };
                appendFsync = lib.mkOption {
                  description = ''How often to fsync the append-only log, options: no, always, everysec.'';
                  type = lib.types.str;
                  default = "everysec";
                };
                slowLogLogSlowerThan = lib.mkOption {
                  description = "Log queries whose execution take longer than X in milliseconds.";
                  type = lib.types.int;
                  default = 10000;
                };
                slowLogMaxLen = lib.mkOption {
                  description = "Maximum number of items to keep in slow log.";
                  type = lib.types.int;
                  default = 128;
                };
                settings = lib.mkOption {
                  description = ''Redis configuration.'';
                  default = { };
                  type =
                    with lib.types;
                    attrsOf (oneOf [
                      bool
                      int
                      str
                      (listOf str)
                    ]);
                };
              };
              config.settings = lib.mkMerge [
                {
                  inherit (config)
                    databases
                    maxclients
                    appendOnly
                    ;
                  logfile = "/dev/null";
                  port = lib'.ports name;
                  daemonize = false;
                  supervised = "systemd";
                  loglevel = config.logLevel;
                  syslog-enabled = config.syslog;
                  syslog-ident = name;
                  save =
                    if config.save == [ ] then
                      ''""'' # Disable saving with `save = ""`
                    else
                      map (d: "${toString (builtins.elemAt d 0)} ${toString (builtins.elemAt d 1)}") config.save;
                  dbfilename = "dump.rdb";
                  dir = config.home;
                  appendfsync = config.appendFsync;
                  slowlog-log-slower-than = config.slowLogLogSlowerThan;
                  slowlog-max-len = config.slowLogMaxLen;
                }
                (lib.mkIf (config.bind != null) { inherit (config) bind; })
                (lib.mkIf (config.unixSocket != null) {
                  unixsocket = config.unixSocket;
                  unixsocketperm = toString config.unixSocketPerm;
                })
                (lib.mkIf (config.slaveOf != null) {
                  slaveof = "${config.slaveOf.ip} ${toString config.slaveOf.port}";
                })
              ];
            }
          )
        );
      };
    };
  };

  config = lib.mkIf (eachServer != { }) {

    #(Suggested for Background Saving: <https://redis.io/docs/get-started/faq/>)
    boot.kernel.sysctl."vm.overcommit_memory" = lib.mkDefault "1";

    environment.systemPackages = [ cfg.package ];

    kompis-os.paths = lib.mapAttrs' (
      server: serverCfg: lib.nameValuePair serverCfg.home { inherit (serverCfg) user; }
    ) eachServer;

    preservation.preserveAt."/srv/database" = {
      directories = lib.mapAttrsToList (server: serverCfg: {
        directory = serverCfg.home;
        user = serverCfg.user;
        group = serverCfg.user;
      }) eachServer;
    };

    systemd.services = lib.mapAttrs (server: serverCfg: {
      description = "Redis Server - ${server}";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/${
          cfg.package.serverBin or "redis-server"
        } ${serverCfg.home}/redis.conf ${lib.escapeShellArgs serverCfg.extraParams}";
        ExecStartPre =
          "+"
          + pkgs.writeShellScript "${server}-prep-conf" (
            let
              redisConfVar = "${serverCfg.home}/redis.conf";
              redisConfRun = "${serverCfg.home}/nixos.conf";
              redisConfStore = redisConfig serverCfg.settings;
            in
            ''
              touch "${redisConfVar}" "${redisConfRun}"
              chown '${serverCfg.user}':'${serverCfg.user}' "${redisConfVar}" "${redisConfRun}"
              chmod 0600 "${redisConfVar}" "${redisConfRun}"
              if [ ! -s ${redisConfVar} ]; then
                echo 'include "${redisConfRun}"' > "${redisConfVar}"
              fi
              echo 'include "${redisConfStore}"' > "${redisConfRun}"
              ${lib.optionalString serverCfg.requirePass ''
                {
                  echo -n "requirepass "
                  cat ${lib.escapeShellArg config.sops.secrets."${serverCfg.entity}/secret-key".path}
                } >> "${redisConfRun}"
              ''}
            ''
          );
        Type = "notify";
        User = serverCfg.user;
        Group = serverCfg.user;
        RuntimeDirectory = server;
        RuntimeDirectoryMode = "0750";
        StateDirectory = lib.removePrefix "/var/lib/" serverCfg.home;
        StateDirectoryMode = "0700";
        UMask = "0077";
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        LimitNOFILE = lib.mkDefault "${toString (serverCfg.maxclients + 32)}";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = cfg.package.pname != "keydb";
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        PrivateMounts = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "~@cpu-emulation @debug @keyring @memlock @mount @obsolete @privileged @resources @setuid";
      };
    }) eachServer;

  };
}
