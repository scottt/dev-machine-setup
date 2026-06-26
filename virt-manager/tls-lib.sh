# shellcheck shell=bash
# Shared TLS PKI helpers for libvirt remote access.
# Sourced by setup-libvirt-remote and gen-client-cert. Not meant to be run directly.
#
# libvirt's default x509 file layout (see ca_file/cert_file/key_file in
# libvirtd.conf / virtproxyd.conf):
#   CA cert      : /etc/pki/CA/cacert.pem
#   server cert  : /etc/pki/libvirt/servercert.pem
#   server key   : /etc/pki/libvirt/private/serverkey.pem
#   client cert  : /etc/pki/libvirt/clientcert.pem
#   client key   : /etc/pki/libvirt/private/clientkey.pem

PKI_CA=/etc/pki/CA
PKI_CA_CERT="$PKI_CA/cacert.pem"
PKI_CA_KEY="$PKI_CA/private/cakey.pem"
PKI_LIBVIRT=/etc/pki/libvirt
PKI_LIBVIRT_PRIV="$PKI_LIBVIRT/private"

# Tunables (override via environment).
ORG="${LIBVIRT_TLS_ORG:-dev-machine-setup}"
DAYS="${LIBVIRT_TLS_DAYS:-3650}"

# gen_ca: create a self-signed CA if one is not already present. Idempotent.
gen_ca() {
    install -d -m 0755 "$PKI_CA"
    install -d -m 0700 "$PKI_CA/private"
    if [ -f "$PKI_CA_CERT" ] && [ -f "$PKI_CA_KEY" ]; then
        echo "CA already present: $PKI_CA_CERT"
        return 0
    fi
    echo "Generating CA -> $PKI_CA_CERT"
    local info
    info="$(mktemp)"
    ( umask 077; certtool --generate-privkey > "$PKI_CA_KEY" )
    chmod 0600 "$PKI_CA_KEY"
    cat > "$info" <<EOF
cn = $ORG libvirt CA
ca
cert_signing_key
expiration_days = $DAYS
EOF
    certtool --generate-self-signed \
        --load-privkey "$PKI_CA_KEY" \
        --template "$info" \
        --outfile "$PKI_CA_CERT"
    rm -f "$info"
}

# gen_server_cert <cn>: issue the server cert/key into the system libvirt PKI dir.
# Honors SERVER_SAN_DNS / SERVER_SAN_IP (space-separated) for extra SANs and
# FORCE=1 to regenerate. The CN must match the hostname clients put in the URI.
gen_server_cert() {
    local cn="$1"
    install -d -m 0755 "$PKI_LIBVIRT"
    install -d -m 0700 "$PKI_LIBVIRT_PRIV"
    local cert="$PKI_LIBVIRT/servercert.pem"
    local key="$PKI_LIBVIRT_PRIV/serverkey.pem"
    if [ -f "$cert" ] && [ -f "$key" ] && [ "${FORCE:-0}" != 1 ]; then
        echo "Server cert already present: $cert (set FORCE=1 to regenerate)"
        return 0
    fi
    echo "Generating server cert for CN=$cn -> $cert"
    local info
    info="$(mktemp)"
    ( umask 077; certtool --generate-privkey > "$key" )
    chmod 0600 "$key"
    {
        echo "organization = $ORG"
        echo "cn = $cn"
        echo "dns_name = $cn"
        local short; short="$(hostname -s 2>/dev/null || true)"
        [ -n "$short" ] && [ "$short" != "$cn" ] && echo "dns_name = $short"
        local d ip
        for d in ${SERVER_SAN_DNS:-}; do echo "dns_name = $d"; done
        for ip in ${SERVER_SAN_IP:-}; do echo "ip_address = $ip"; done
        echo "tls_www_server"
        echo "encryption_key"
        echo "signing_key"
        echo "expiration_days = $DAYS"
    } > "$info"
    certtool --generate-certificate \
        --load-privkey "$key" \
        --load-ca-certificate "$PKI_CA_CERT" \
        --load-ca-privkey "$PKI_CA_KEY" \
        --template "$info" \
        --outfile "$cert"
    rm -f "$info"
}

# gen_client_cert <cn> <outdir>: issue a client cert/key plus a copy of the CA
# cert into <outdir>, as clientcert.pem / clientkey.pem / cacert.pem.
gen_client_cert() {
    local cn="$1" outdir="$2"
    install -d -m 0700 "$outdir"
    local cert="$outdir/clientcert.pem"
    local key="$outdir/clientkey.pem"
    echo "Generating client cert for CN=$cn -> $cert"
    local info
    info="$(mktemp)"
    ( umask 077; certtool --generate-privkey > "$key" )
    chmod 0600 "$key"
    cat > "$info" <<EOF
organization = $ORG
cn = $cn
tls_www_client
encryption_key
signing_key
expiration_days = $DAYS
EOF
    certtool --generate-certificate \
        --load-privkey "$key" \
        --load-ca-certificate "$PKI_CA_CERT" \
        --load-ca-privkey "$PKI_CA_KEY" \
        --template "$info" \
        --outfile "$cert"
    rm -f "$info"
    cp "$PKI_CA_CERT" "$outdir/cacert.pem"
    chmod 0644 "$outdir/cacert.pem" "$cert"
}
