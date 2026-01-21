# This package will install utils to backup/restore and install ssh keys
## Export backup of private keys and owner trust
```bash
gpg-backup
```

## Import private keys and owner trust
```bash
gpg-restore
```

## Install ssh key to server
```bash
install-ssh-key user@host
```

## Uninstall ssh key from server
```bash
install-ssh-key -u user@host
```
