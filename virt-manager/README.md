# libvirt / virt-manager remote access over TLS

Lets you manage this host's VMs from another machine via
`qemu+tls://<host>/system` (virsh or virt-manager), encrypted and
authenticated with x509 certificates. The daemon listens on TCP **16514**.

## Why TLS

- **SSH** (`qemu+ssh://`) needs no server config but requires a shell account
  per client.
- **plain TCP** (`qemu+tcp://`, 16509) is unencrypted.
- **TLS** (`qemu+tls://`, 16514) — what this sets up — encrypts the channel and
  authenticates clients by certificate, no shell account needed.

## What the setup does

`setup-libvirt-remote` (run as root on the host):

1. Creates a self-signed CA at `/etc/pki/CA/` (reused on re-run).
2. Issues the server cert into `/etc/pki/libvirt/` with CN = `hostname -f`.
3. Issues a local client cert so the host can self-test.
4. Sets `auth_tls = "none"` (x509 client-cert auth) in the active daemon's conf,
   inside a marked, idempotent block (original saved as `*.dms.bak`).
5. Enables the TLS socket and opens 16514/tcp in firewalld.
6. Adds the invoking user to the `libvirt` group.

It auto-detects monolithic `libvirtd` vs the modular daemons (`virtproxyd`) and
targets the matching socket + conf. **This host currently runs the monolithic
`libvirtd`**, so it configures `libvirtd-tls.socket` + `/etc/libvirt/libvirtd.conf`.

## Usage

```sh
# On the host:
sudo ./setup-libvirt-remote

# Self-test:
virsh -c qemu+tls://$(hostname -f)/system list --all
```

### Connecting from another machine

```sh
# On the host, mint a cert for that client:
sudo ./gen-client-cert my-laptop
# -> writes client-certs/my-laptop/{cacert,clientcert,clientkey}.pem
```

Copy those three files to the client and install them (system-wide):

```sh
sudo install -D -m 0644 cacert.pem     /etc/pki/CA/cacert.pem
sudo install -D -m 0644 clientcert.pem /etc/pki/libvirt/clientcert.pem
sudo install -D -m 0600 clientkey.pem  /etc/pki/libvirt/private/clientkey.pem
```

Then from the client:

```sh
virsh -c qemu+tls://<host>/system list --all
```

In **virt-manager**: *File → Add Connection → Hypervisor: QEMU/KVM →
Connect to remote host over **TLS** → Hostname: `<host>`*.

## Notes

- The server cert CN must match the hostname clients use in the URI. To connect
  by IP or alternate name, reissue with extra SANs:
  `sudo SERVER_SAN_IP="192.168.1.10" SERVER_SAN_DNS="myhost.lan" FORCE=1 ./setup-libvirt-remote`
- To restrict which client certs are accepted, list their DNs:
  `sudo LIBVIRT_TLS_ALLOWED_DN="O=dev-machine-setup,CN=my-laptop" ./setup-libvirt-remote`
  (find a cert's DN with `certtool -i < clientcert.pem | grep Subject`).
- The CA private key lives at `/etc/pki/CA/private/cakey.pem` (root-only). Keep
  it safe; anyone with it can mint trusted client certs.
