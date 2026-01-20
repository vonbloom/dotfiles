# Export backup of private keys and owner trust
gpg --export-secret-keys --armor > backup.asc
gpg --export-ownertrust > trust.txt

# Import private keys and owner trust
gpg --import backup.asc
gpg --import-ownertrust < trust.txt
