{
  config,
  host,
  inputs,
  lib,
  lib',
  pkgs,
  ...
}:

let
  inherit (lib)
    filterAttrs
    flatten
    mapAttrs'
    mapAttrsToList
    mkDefault
    mkEnableOption
    mkForce
    mkIf
    mkOption
    nameValuePair
    types
    ;

  cfg = config.kompis-os.mobilizon;
  settingsFormat = pkgs.formats.elixirConf { elixir = cfg.package.elixirPackage; };

  eachSite = filterAttrs (name: cfg: cfg.enable) cfg.sites;
  stateDir = appname: "/var/lib/${appname}/mobilizon";
  hostConfig = config;

  siteOpts =
    { name, config, ... }:
    {
      config = {
        appname = mkDefault name;

        containerConf = {
          system.stateVersion = mkForce hostConfig.system.stateVersion;
          users = {
            users.mobilizon = {
              uid = mkForce config.uid;
              group = "mobilizon";
            };
            groups.mobilizon.gid = mkForce config.uid;
          };
          services.mobilizon = {
            enable = true;
            package = inputs.${config.appname}.packages.${host.system}.default;
            nginx.enable = false;
            settings.":mobilizon" = {
              "Mobilizon.Web.Endpoint".http = {
                port = mkForce config.port;
                ip = settingsFormat.lib.mkTuple [
                  0
                  0
                  0
                  0
                ];
              };
              "Mobilizon.Storage.Repo" = {
                hostname = mkForce "127.0.0.1";
                database = config.appname;
                username = config.appname;
                password = config.appname;
                socket_dir = null;
              };
              ":instance" = {
                name = mkForce config.appname;
                hostname = mkForce config.hostname;
              };
            };

          };
        };
      };

      options = {
        enable = mkEnableOption "mobilizon on this host";
        ssl = mkOption {
          description = "Enable HTTPS";
          default = true;
          type = types.bool;
        };
        subnet = mkOption {
          description = "Use self-signed certificates";
          default = false;
          type = types.bool;
        };
        www = mkOption {
          description = "Prefix the url with www.";
          default = "no";
          type = types.enum [
            "no"
            "yes"
            "redirect"
          ];
        };
        port = mkOption {
          description = "Port to serve on";
          type = lib.types.port;
          default = lib'.ids.${config.appname}.port;
        };
        hostname = mkOption {
          description = "Namespace identifying the service externally on the network";
          type = types.str;
        };
        appname = mkOption {
          description = "Namespace identifying the app on the system (user, logging, database, paths etc.)";
          type = types.str;
        };
        uid = mkOption {
          description = "Userid is required to map user in container";
          type = types.int;
          default = lib'.ids.${config.appname}.uid;
        };
        containerConf = mkOption {
          description = "The configuration passed to the mobilizon container";
          type = types.anything;
        };
      };
    };
in
{
  options = {
    kompis-os.mobilizon = {
      sites = mkOption {
        type = types.attrsOf (types.submodule siteOpts);
        default = { };
        description = "Specification of one or more mobilizon sites to serve";
      };
    };
  };

  config = mkIf (eachSite != { }) {

    kompis-os.preserve.directories = mapAttrsToList (name: cfg: {
      directory = stateDir cfg.appname;
      user = cfg.appname;
      group = cfg.appname;
    }) eachSite;

    kompis-os.users = lib.mapAttrs' (
      name: cfg:
      lib.nameValuePair cfg.appname {
        class = "service";
        publicKey = false;
      }
    ) eachSite;

    systemd.tmpfiles.rules = flatten (
      mapAttrsToList (name: cfg: [
        "d '${stateDir cfg.appname}' 0750 ${cfg.appname} ${cfg.appname} - -"
        "Z '${stateDir cfg.appname}' 0750 ${cfg.appname} ${cfg.appname} - -"
      ]) eachSite
    );

    systemd.services = lib'.mergeAttrs (name: cfg: {
      "${cfg.appname}-pgsql-dump" = {
        description = "dump a snapshot of the postgresql database";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.pgsql-dump}/bin/pgsql-dump ${cfg.appname} ${stateDir cfg.appname}";
          User = cfg.appname;
          Group = cfg.appname;
        };
      };

      "${cfg.appname}-pgsql-restore" = {
        description = "restore postgresql database from snapshot";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.pgsql-restore}/bin/pgsql-restore ${cfg.appname} ${stateDir cfg.appname}";
          User = cfg.appname;
          Group = cfg.appname;
        };
      };
    }) eachSite;

    systemd.timers = lib'.mergeAttrs (name: cfg: {
      "${cfg.appname}-pgsql-dump" = {
        description = "scheduled database dump";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Unit = "${cfg.appname}-pgsql-dump.service";
        };
      };
    }) eachSite;

    services.nginx.virtualHosts = lib'.mergeAttrs (
      name: cfg:
      let
        inherit (cfg.containerConf.services.mobilizon) package;
        proxyPass = "http://127.0.0.1:${toString cfg.port}";
        serverName = if cfg.www == "yes" then "www.${cfg.hostname}" else cfg.hostname;
        serverNameRedirect = if cfg.www == "yes" then cfg.hostname else "www.${cfg.hostname}";
      in
      {
        ${serverNameRedirect} = mkIf (cfg.www != "no") {
          forceSSL = cfg.ssl;
          sslCertificate = mkIf cfg.subnet ../public-keys/service-domain-km-tls-cert.pem;
          sslCertificateKey = mkIf cfg.subnet config.sops.secrets."km/tls-cert".path;
          enableACME = cfg.ssl && !cfg.subnet;
          extraConfig = ''
            return 301 $scheme://${serverName}$request_uri;
          '';
        };

        ${serverName} = {
          forceSSL = cfg.ssl;
          sslCertificate = mkIf cfg.subnet ../public-keys/service-domain-km-tls-cert.pem;
          sslCertificateKey = mkIf cfg.subnet config.sops.secrets."km/tls-cert".path;
          enableACME = cfg.ssl && !cfg.subnet;

          locations = {
            "/" = {
              inherit proxyPass;
              recommendedProxySettings = lib.mkDefault true;
              extraConfig = ''
                expires off;
                add_header Cache-Control "public, max-age=0, s-maxage=0, must-revalidate" always;
              '';
            };
          };
          locations."~ ^/(assets|img)" = {
            root = "${package}/lib/mobilizon-${package.version}/priv/static";
            extraConfig = ''
              access_log off;
              add_header Cache-Control "public, max-age=31536000, s-maxage=31536000, immutable";
            '';
          };
          locations."~ ^/(media|proxy)" = {
            inherit proxyPass;
            recommendedProxySettings = lib.mkDefault true;
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_request_buffering off;
              access_log off;
              add_header Cache-Control "public, max-age=31536000, s-maxage=31536000, immutable";
            '';
          };
        };
      }
    ) eachSite;

    containers = mapAttrs' (
      name: cfg:
      (nameValuePair cfg.appname {
        autoStart = true;

        bindMounts = {
          "/var/lib/mobilizon" = {
            isReadOnly = false;
            hostPath = stateDir cfg.appname;
          };
        };

        config = cfg.containerConf;
      })
    ) eachSite;
  };
}
