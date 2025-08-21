{ config, pkgs, ... }:
{
  security.acme.defaults.email = "linosgian00@gmail.com";
  security.acme.acceptTerms = true;
  security.acme.certs."lgian.com" = {
    domain = "*.lgian.com";
    dnsProvider = "digitalocean";
    dnsPropagationCheck = true;
    environmentFile = config.sops.templates."acme-do-opts".path;
  };
}
