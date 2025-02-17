{ lib, config, pkgs, ... }:
{
  options.headscale.hostname = lib.mkOption {
    type = lib.types.str;
    description = "The hostname to use for headscale";
  };

  options.headscale.acmeEmail = lib.mkOption {
    type = lib.types.str;
    description = "Email to use with ACME registration";
  };

  options.headscale.v4Prefix = lib.mkOption {
    type = lib.types.str;
    description = "V4 prefix to use";
  };

  config.services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 443;
    settings = {
      server_url = "https://${config.headscale.hostname}";
      tls_letsencrypt_hostname = config.headscale.hostname;
      grpc_listen_addr = "127.0.0.1:50443";
      metrics_listen_addr = "127.0.0.1:9090";
      dns = {
        magic_dns = false;
      };
      prefixes = {
        v4 = config.headscale.v4Prefix;
      };
    };
  };
}
