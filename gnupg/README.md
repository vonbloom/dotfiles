# Export backup of private keys and owner trust
```bash
gpg --export-secret-keys --armor > backup.asc
gpg --export-ownertrust > trust.txt
```
# Import private keys and owner trust
```bash
gpg --import backup.asc
gpg --import-ownertrust < trust.txt
```
