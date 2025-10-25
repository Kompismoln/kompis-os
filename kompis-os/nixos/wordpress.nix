{
  config,
  lib,
  lib',
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.wordpress;
  webserver = config.services.nginx;
  eachSite = lib.filterAttrs (name: cfg: cfg.enable) cfg.sites;
  stateDir = appname: "/var/lib/${appname}/wordpress";

  siteOpts =
    { name, ... }:
    {
      config.appname = lib.mkDefault name;
      options = {
        enable = lib.mkEnableOption "wordpress on this host.";
        ssl = lib.mkOption {
          description = "Enable HTTPS.";
          type = lib.types.bool;
          default = true;
        };
        subnet = lib.mkOption {
          description = "Use self-signed certificates";
          default = false;
          type = lib.types.bool;
        };
        www = lib.mkOption {
          description = "Prefix the url with www.";
          default = "no";
          type = lib.types.enum [
            "no"
            "yes"
            "redirect"
          ];
        };
        basicAuth = lib.mkOption {
          description = "Protect the site with basic auth.";
          type = with lib.types; attrsOf str;
          default = { };
        };
        hostname = lib.mkOption {
          description = "Namespace identifying the service externally on the network.";
          type = lib.types.str;
        };
        appname = lib.mkOption {
          description = "Namespace identifying the app on the system (user, logging, database, paths etc.)";
          type = lib.types.str;
        };
      };
    };

  wpPhp = pkgs.php.buildEnv {
    extensions =
      { enabled, all }:
      with all;
      enabled
      ++ [
        imagick
        memcached
        opcache
      ];
    extraConfig = ''
      memory_limit = 256M
      cgi.fix_pathinfo = 0
    '';
  };
in
{
  options = {
    kompis-os.wordpress = {
      sites = lib.mkOption {
        type = with lib.types; attrsOf (submodule siteOpts);
        default = { };
        description = "Specification of one or more wordpress sites to serve";
      };
    };
  };

  config = lib.mkIf (eachSite != { }) {

    kompis-os.preserve.directories = lib.mapAttrsToList (name: cfg: {
      directory = stateDir cfg.appname;
      user = cfg.appname;
      group = cfg.appname;
    }) eachSite;

    kompis-os.redis.servers = lib.mapAttrs (name: cfg: {
      enable = true;
    }) eachSite;

    kompis-os.users = lib.mapAttrs' (
      name: cfg:
      lib.nameValuePair "${cfg.appname}" {
        class = "service";
        publicKey = false;
        members = [
          webserver.group
        ];
      }
    ) eachSite;

    services.nginx.virtualHosts = lib'.mergeAttrs (
      name: cfg:
      let
        serverName = if cfg.www == "yes" then "www.${cfg.hostname}" else cfg.hostname;
        serverNameRedirect = if cfg.www == "yes" then cfg.hostname else "www.${cfg.hostname}";
      in
      {
        ${serverNameRedirect} = lib.mkIf (cfg.www != "no") {
          forceSSL = cfg.ssl;
          sslCertificate = lib.mkIf cfg.subnet lib'.public-artifacts "service" "domain-km" "tls-cert";
          sslCertificateKey = lib.mkIf cfg.subnet config.sops.secrets."km/tls-cert".path;
          enableACME = cfg.ssl && !cfg.subnet;
          extraConfig = ''
            return 301 $scheme://${serverName}$request_uri;
          '';
        };

        ${serverName} = {
          forceSSL = cfg.ssl;
          sslCertificate = lib.mkIf cfg.subnet lib'.public-artifacts "service" "domain-km" "tls-cert";
          sslCertificateKey = lib.mkIf cfg.subnet config.sops.secrets."km/tls-cert".path;
          enableACME = cfg.ssl && !cfg.subnet;

          root = stateDir cfg.appname;
          basicAuth = lib.mkIf (cfg.basicAuth != { }) cfg.basicAuth;

          extraConfig = ''
            index index.php;
          '';

          locations = {
            "/favicon.ico" = {
              priority = 100;
              extraConfig = ''
                log_not_found off;
                access_log off;
              '';
            };

            "/robots.txt" = {
              priority = 100;
              extraConfig = ''
                allow all;
                log_not_found off;
                access_log off;
              '';
            };

            "/" = {
              priority = 200;
              extraConfig = ''
                try_files $uri $uri/ /index.php?$args;
              '';
            };

            "~ \\.php$" = {
              priority = 300;
              extraConfig = ''
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:${config.services.phpfpm.pools.${cfg.appname}.socket};
                fastcgi_index index.php;
                include ${config.services.nginx.package}/conf/fastcgi.conf;
                fastcgi_intercept_errors on;
                fastcgi_param HTTP_PROXY "";
                fastcgi_buffer_size 16k;
                fastcgi_buffers 4 16k;
              '';
            };

            "~ /\\." = {
              priority = 800;
              extraConfig = ''deny all;'';
            };

            "~ \.(log|sql)$" = {
              priority = 800;
              extraConfig = ''deny all;'';
            };

            "~* /(?:uploads|files)/.*\\.php$" = {
              priority = 900;
              extraConfig = ''deny all;'';
            };

            "~* \\.(js|css|png|jpg|jpeg|gif|ico)$" = {
              priority = 1000;
              extraConfig = ''
                expires max;
                log_not_found off;
              '';
            };
          };
        };
      }
    ) eachSite;

    services.phpfpm.pools = lib.mapAttrs' (
      name: cfg:
      lib.nameValuePair cfg.appname {
        user = cfg.appname;
        group = cfg.appname;
        phpPackage = wpPhp;
        phpOptions = ''
          upload_max_filesize = 16M;
          post_max_size = 16M;
          error_reporting = E_ALL;
          display_errors = Off;
          log_errors = On;
          error_log = ${stateDir cfg.appname}/error.log;
          extension=${pkgs.phpExtensions.redis}/lib/php/extensions/redis.so
        '';
        settings = {
          "listen.owner" = webserver.user;
          "listen.group" = webserver.group;
          "pm" = "dynamic";
          "pm.max_children" = 32;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 2;
          "pm.max_spare_servers" = 4;
          "pm.max_requests" = 500;
        };
      }
    ) eachSite;

    systemd.services = lib'.mergeAttrs (name: cfg: {
      "${cfg.appname}-mysql-dump" = {
        description = "dump a snapshot of the mysql database";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.bash} -c '${pkgs.mariadb}/bin/mysqldump -u ${cfg.appname} ${cfg.appname} > ${stateDir cfg.appname}/dbdump.sql'";
          User = cfg.appname;
          Group = cfg.appname;
        };
      };
      "${cfg.appname}-mysql-restore" = {
        description = "restore mysql database from snapshot";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.bash} -c '${pkgs.mariadb}/bin/mysql -u ${cfg.appname} ${cfg.appname} < ${stateDir cfg.appname}/dbdump.sql'";
          User = cfg.appname;
          Group = cfg.appname;
        };
      };
    }) eachSite;

    systemd.timers = lib'.mergeAttrs (name: cfg: {
      "${cfg.appname}-mysql-dump" = {
        description = "scheduled database dump";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Unit = "${cfg.appname}-mysql-dump.service";
        };
      };
    }) eachSite;
  };
}
