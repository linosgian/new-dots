{ config, pkgs, ... }:
let
  # Create a derivation for the certificate conversion script
  keycloakCertConverter = pkgs.writeScriptBin "keycloak-cert-converter" ''
    #!${pkgs.bash}/bin/bash

    CERT_DIR="$1"
    KEYCLOAK_CERTS="$2"
    PASSWORD="$3"

    # Create output directory
    mkdir -p "$KEYCLOAK_CERTS"
    echo "Converting certificates to Java keystore..."

    # Create PKCS12 keystore
    ${pkgs.openssl}/bin/openssl pkcs12 -export \
      -in "$CERT_DIR/cert.pem" \
      -inkey "$CERT_DIR/key.pem" \
      -out "$KEYCLOAK_CERTS/keystore.p12" \
      -name keycloak \
      -passout "pass:$PASSWORD"

    # Convert to JKS format
    ${pkgs.jdk}/bin/keytool -importkeystore \
      -srckeystore "$KEYCLOAK_CERTS/keystore.p12" \
      -srcstoretype PKCS12 \
      -srcstorepass "$PASSWORD" \
      -destkeystore "$KEYCLOAK_CERTS/keystore.jks" \
      -deststoretype JKS \
      -deststorepass "$PASSWORD" \
      -destkeypass "$PASSWORD"

    # Create truststore
    ${pkgs.jdk}/bin/keytool -import \
      -file "$CERT_DIR/chain.pem" \
      -alias root \
      -keystore "$KEYCLOAK_CERTS/truststore.jks" \
      -storepass "$PASSWORD" \
      -noprompt

    # Also copy PEM files (for flexibility)
    cp "$CERT_DIR/cert.pem" "$KEYCLOAK_CERTS/tls.crt"
    cp "$CERT_DIR/key.pem" "$KEYCLOAK_CERTS/tls.key"
    cp "$CERT_DIR/chain.pem" "$KEYCLOAK_CERTS/ca.crt"

    # Set proper permissions
    chmod 644 "$KEYCLOAK_CERTS"/*

    # Clean up temporary files
    rm "$KEYCLOAK_CERTS/keystore.p12"

    echo "Restarting Nomad job for Keycloak..."
    ${pkgs.nomad}/bin/nomad job restart -detach keycloak
  '';
in
{
  environment.systemPackages = with pkgs; [
    # required for id.lgian.com ACME postRun
    openjdk
    openssl
    keycloakCertConverter
  ];
  security.acme.defaults.email = "linosgian00@gmail.com";
  security.acme.acceptTerms = true;
  security.acme.certs."id.lgian.com" = {
    domain = "id.lgian.com";
    dnsProvider = "digitalocean";
    dnsPropagationCheck = true;
    environmentFile = config.sops.templates."acme-do-opts".path;
    postRun = ''
      ${keycloakCertConverter}/bin/keycloak-cert-converter \
        "/var/lib/acme/id.lgian.com" \
        "/var/lib/keycloak/certs" \
        "whocares"
    '';
  };
  security.acme.certs."lgian.com" = {
    domain = "*.lgian.com";
    dnsProvider = "digitalocean";
    dnsPropagationCheck = true;
    environmentFile = config.sops.templates."acme-do-opts".path;
  };
}
