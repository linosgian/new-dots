{
  config,
  pkgs,
  lib,
  strovilosSrc,
  ...
}:
let
  stateDir = "/var/lib/strovilos";
  staticDir = "${stateDir}/static";
  mediaDir = "${stateDir}/media";
  logDir = "${stateDir}/log";
  socketPath = "/run/strovilos/gunicorn.sock";
  secretSettingsPath = config.sops.templates."strovilos_secret_settings".path;

  # Patch secret_settings.py so it reads the sops-rendered file at runtime.
  # `from .secret_settings import *` in settings.py will import this module,
  # which exec's the actual secrets file into its own global scope — all
  # variables (SECRET_KEY, DATABASES, …) become importable.
  appSrc = pkgs.runCommand "strovilos-src" { } ''
        cp -r ${strovilosSrc} $out
        chmod -R u+w $out
        cat > $out/strovilos/secret_settings.py << 'EOF'
    import os as _os
    exec(open(_os.environ['SECRET_SETTINGS_PATH']).read())
    EOF
  '';

  django-tinymce = pkgs.python312Packages.buildPythonPackage rec {
    pname = "django-tinymce";
    version = "4.1.0";
    pyproject = true;
    src = pkgs.fetchPypi {
      pname = "django_tinymce";
      inherit version;
      hash = "sha256-AuO3DpQP0pnw++9DFa7lwYVmTh64zTlrF2ljlU5DV8k=";
    };
    build-system = [ pkgs.python312Packages.setuptools ];
    dependencies = [ pkgs.python312Packages.django ];
    doCheck = false;
  };

  django-grappelli = pkgs.python312Packages.buildPythonPackage rec {
    pname = "django-grappelli";
    version = "5.0.0";
    pyproject = true;
    src = pkgs.fetchPypi {
      pname = "django_grappelli";
      inherit version;
      hash = "sha256-QEyEgAJHWLU3vtcjBwxk7vaV3lV61HC0MWHb/wqkxkI=";
    };
    build-system = [ pkgs.python312Packages.setuptools ];
    dependencies = [ pkgs.python312Packages.django ];
    doCheck = false;
  };

  pythonEnv = pkgs.python312.withPackages (
    ps: with ps; [
      beautifulsoup4
      django
      django-anymail
      django-appconf
      django-compressor
      gunicorn
      pillow
      django-tinymce
      django-grappelli
    ]
  );

  setupScript = pkgs.writeShellScript "strovilos-setup" ''
    set -eu
    ${pythonEnv}/bin/python ${appSrc}/manage.py migrate --noinput
    ${pythonEnv}/bin/python ${appSrc}/manage.py collectstatic --noinput --clear
  '';
in
{
  sops.secrets.strovilos_secret_key = {
    owner = "strovilos";
  };
  sops.secrets.strovilos_sendgrid_api_key = {
    owner = "strovilos";
  };

  sops.templates."strovilos_secret_settings" = {
    owner = "strovilos";
    content = ''
      SECRET_KEY = "${config.sops.placeholder.strovilos_secret_key}"
      SENDGRID_API_KEY = "${config.sops.placeholder.strovilos_sendgrid_api_key}"
      DATABASES = {
          'default': {
              'ENGINE': 'django.db.backends.sqlite3',
              'NAME': '${stateDir}/db.sqlite3',
          }
      }
      DEBUG = False
      ROOT_DIR = '${stateDir}'
      STATIC_ROOT = '${staticDir}'
      MEDIA_ROOT = '${mediaDir}'
      ALLOWED_HOSTS = ['83.212.102.122', 'strovilos.lgian.com']
    '';
  };

  users.users.strovilos = {
    isSystemUser = true;
    group = "strovilos";
    home = stateDir;
    createHome = true;
  };
  users.groups.strovilos = { };

  systemd.tmpfiles.rules = [
    "d ${stateDir}  0711 strovilos strovilos -"
    "d ${staticDir} 0755 strovilos strovilos -"
    "d ${mediaDir}  0755 strovilos strovilos -"
    "d ${logDir}    0750 strovilos strovilos -"
  ];

  systemd.services.strovilos = {
    description = "Strovilos Django app";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      DJANGO_SETTINGS_MODULE = "strovilos.settings";
      PYTHONPATH = appSrc;
      SECRET_SETTINGS_PATH = secretSettingsPath;
    };

    serviceConfig = {
      Type = "simple";
      User = "strovilos";
      Group = "strovilos";
      WorkingDirectory = appSrc;
      ExecStartPre = setupScript;
      ExecStart = lib.concatStringsSep " " [
        "${pythonEnv}/bin/gunicorn"
        "strovilos.wsgi:application"
        "--bind unix:${socketPath}"
        "--workers 3"
        "--access-logfile ${logDir}/access.log"
        "--error-logfile ${logDir}/error.log"
      ];
      Restart = "on-failure";
      RuntimeDirectory = "strovilos";
      RuntimeDirectoryMode = "0755";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."strovilos" = {
      serverName = "strovilos.lgian.com";
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
      locations = {
        "/" = {
          proxyPass = "http://unix:${socketPath}";
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_set_header X-Forwarded-Proto http;
            client_max_body_size 50M;
          '';
        };
        "/static/" = {
          alias = "${staticDir}/";
          extraConfig = "expires 30d;";
        };
        "/media/" = {
          alias = "${mediaDir}/";
          extraConfig = "expires 7d;";
        };
      };
    };
  };
}
