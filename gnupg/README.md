# gnupg

GnuPG config (`common.conf`, `gpg-agent.conf` with SSH support, `sshcontrol`: the keygrips of the
authentication subkeys offered to SSH) and three scripts in `~/.local/bin`.

## Keys

One primary key, `C785 B084 B567 7B84 91FE  E41D 7E0E B22A 2520 16A3` (ed25519, certify and
sign), with two user IDs (personal `vonbloom@gmail.com`, work `roger@apptramit.com`) and these
subkeys:

| Subkey | Use | Keygrip (`sshcontrol`) | SSH comment | Where it goes |
|---|---|---|---|---|
| `6DE3D0D2F4CD2BA7` (cv25519) | encryption | | | decrypts the homelab vault password (`.vault-pass.gpg`) |
| `DD8A445D5646ACB4` (ed25519) | SSH, personal | `9D705C5D…D5906F93` | `openpgp:0x5646ACB4` | homelab servers (`admin_ssh_keys`), `install-ssh-key` |
| `79687A6997265102` (ed25519) | SSH, work | `AD4D1059…D1E18F10` | `openpgp:0x97265102` | work servers, `install-ssh-key -w` |

This key is the root of everything else: through the vault it also protects the distro-builder
signing key. Losing it without a backup means losing the vault.

## Back up the keys
```bash
gpg-backup [output_dir]
```
Writes `gnupg-backup-YYYY-MM-DD.tar.gz` (never overwrites one) with the secret keys (still
protected by their passphrase, gpg asks for it), the public keys, the owner trust and the
revocation certificates of `~/.gnupg/openpgp-revocs.d`. Before writing it, the backup is imported
into a throwaway keyring and must restore every secret key and subkey, otherwise nothing is
written. Keep copies off the laptop (USB stick, file server).

Without a revocation certificate it warns; create one so a lost or stolen key can be revoked:
```bash
gpg --output ~/.gnupg/openpgp-revocs.d/<fingerprint>.rev --gen-revoke <fingerprint>
```

## Restore the keys
```bash
gpg-restore gnupg-backup-YYYY-MM-DD.tar.gz
```
Imports keys and owner trust (merging with what is there), adds missing revocation certificates
and reloads the agent. SSH then works with the subkeys in `sshcontrol`.

## Install or remove the SSH key on a server
```bash
install-ssh-key user@host      # adds the personal subkey (vonbloom@gmail.com) to ~/.ssh/authorized_keys
install-ssh-key -w user@host   # the work subkey (roger@apptramit.com) instead
install-ssh-key -u user@host   # removes it (-u -w: the work one)
```
Idempotent: whole lines are compared, the key goes to the remote shell on stdin.

Note: gpg-agent rewrites `~/.gnupg/sshcontrol` when a key is added with `ssh-add`, replacing the
stow link with a plain file. Copy it back here after such a change.

## Backup routine

Do it now and again after any change to the key (new subkey, new expiry, new revocation
certificate). Keep two copies off the laptop.

1. Once: create the revocation certificate. It revokes nothing by itself; it is the only way to
   revoke the key if it is ever lost or stolen, and creating it needs the key:
   ```bash
   mkdir -p -m 700 ~/.gnupg/openpgp-revocs.d
   gpg --output ~/.gnupg/openpgp-revocs.d/C785B084B5677B8491FEE41D7E0EB22A252016A3.rev \
       --gen-revoke C785B084B5677B8491FEE41D7E0EB22A252016A3
   ```
2. Make the backup (a dialog asks for the key passphrase):
   ```bash
   gpg-backup ~
   ```
3. Copy it to a USB stick:
   ```bash
   lsblk                               # find the stick, e.g. /dev/sda1
   udisksctl mount -b /dev/sda1        # mounted at /run/media/roger/<label>
   cp ~/gnupg-backup-*.tar.gz /run/media/roger/<label>/
   udisksctl unmount -b /dev/sda1
   ```
4. Copy it to the file server (zeus HDD pool):
   ```bash
   ssh root@192.168.2.10 'mkdir -p -m 700 /mnt/pool/backup/gnupg'
   scp ~/gnupg-backup-*.tar.gz root@192.168.2.10:/mnt/pool/backup/gnupg/
   ```
5. Remove the local copy: `rm ~/gnupg-backup-*.tar.gz`.

To check a copy can still be restored, without touching `~/.gnupg`:
```bash
GNUPGHOME=$(mktemp -d) gpg-restore gnupg-backup-YYYY-MM-DD.tar.gz
```
