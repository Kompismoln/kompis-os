{
  config,
  host,
  lib,
  lib',
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.wordpress;
  webserver = config.services.nginx;
  eachApp = lib.filterAttrs (app: appCfg: appCfg.enable) cfg.apps;

  appOpts = lib'.mkAppOpts host "wordpress" { };

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
      apps = lib.mkOption {
        type = with lib.types; attrsOf (submodule appOpts);
        default = { };
        description = "Specification of one or more wordpress apps to serve";
      };
    };
  };

  config = lib.mkIf (eachApp != { }) {

    kompis-os.preserve.directories = lib.mapAttrsToList (app: appCfg: {
      directory = appCfg.home;
      user = appCfg.user;
      group = appCfg.user;
    }) eachApp;

    services.nginx.virtualHosts = lib.mapAttrs' (
      app: appCfg:
      lib.nameValuePair appCfg.endpoint {
        forceSSL = appCfg.ssl;
        enableACME = appCfg.ssl;

        root = appCfg.home;

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
              fastcgi_pass unix:${config.services.phpfpm.pools.${app}.socket};
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
      }
    ) eachApp;

    services.phpfpm.pools = lib.mapAttrs (app: appCfg: {
      user = appCfg.user;
      group = appCfg.user;
      phpPackage = wpPhp;
      phpOptions = ''
        upload_max_filesize = 16M;
        post_max_size = 16M;
        error_reporting = E_ALL;
        display_errors = Off;
        log_errors = On;
        error_log = ${appCfg.home}/error.log;
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
    }) eachApp;

    systemd.services = lib'.mergeAttrs (app: appCfg: {
      "${app}-mysql-dump" = {
        description = "dump a snapshot of the mysql database";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.bash} -c '${pkgs.mariadb}/bin/mysqldump -u ${appCfg.user} ${appCfg.user} > ${appCfg.home}/dbdump.sql'";
          User = appCfg.user;
          Group = appCfg.user;
        };
      };
      "${app}-mysql-restore" = {
        description = "restore mysql database from snapshot";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.bash} -c '${pkgs.mariadb}/bin/mysql -u ${appCfg.user} ${appCfg.user} < ${appCfg.home}/dbdump.sql'";
          User = appCfg.user;
          Group = appCfg.user;
        };
      };
    }) eachApp;

    systemd.timers = lib'.mergeAttrs (app: appCfg: {
      "${app}-mysql-dump" = {
        description = "scheduled database dump";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Unit = "${app}-mysql-dump.service";
        };
      };
    }) eachApp;
  };
}
