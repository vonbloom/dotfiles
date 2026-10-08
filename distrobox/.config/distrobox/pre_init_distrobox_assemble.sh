#!/usr/bin/env bash
# Runs as root on every container start, before distrobox installs additional_packages.
# Repo order sets priority: Arch [core]/[extra] first, then [cachyos], then the local [aur]
# builds, so a package found in both [cachyos] and [aur] (e.g. brave-bin) comes from CachyOS.

set -e

if [ ! -f /etc/arch-release ]; then
	echo "Not arch release. Nothing to do..."
	exit 0
fi

# A container stopped in the middle of a pacman transaction keeps the lock, and every later start
# fails ("unable to lock database"). The first setup takes minutes, and logging out or rebooting
# stops the user's containers. Nothing else runs in the container yet at this point.
if [ -e /var/lib/pacman/db.lck ]; then
	echo "Removing the pacman lock of an interrupted transaction..."
	rm -f /var/lib/pacman/db.lck
fi

# Package hooks that call systemctl fail without systemd as PID 1 ("System has not been booted with
# systemd"). openssh (installed by distrobox, no sshd runs here) marks sshd for restart on every
# upgrade. A /dev/null link in /etc/pacman.d/hooks disables the hook of the same name.
mkdir -p /etc/pacman.d/hooks
ln -sf /dev/null /etc/pacman.d/hooks/10-openssh-mark-sshd-for-restart.hook

conf=/etc/pacman.conf
cachyos_key=F3B607488DB35A47
# [aur] is signed by the build server (distro-builder: keys/distro-builder.asc, copied here)
aur_key=CF471E6685974BF43EA113623F9EBD77B1E60E55
aur_key_file=$(dirname "$(readlink -f "$0")")/distro-builder.asc
changed=0

# The Arch image ships without a local master key, which --lsign-key needs
ensure_keyring() {
	if ! gpg --homedir /etc/pacman.d/gnupg --list-secret-keys --with-colons 2>/dev/null | grep -q '^sec'; then
		pacman-key --init
	fi
}

if ! grep -q '^\[cachyos\]' "$conf"; then
	echo "Adding [cachyos] repo..."
	ensure_keyring
	pacman-key --recv-keys "$cachyos_key" --keyserver keyserver.ubuntu.com
	pacman-key --lsign-key "$cachyos_key"
	if grep -q '^\[aur\]' "$conf"; then
		sed -i '/^\[aur\]/i [cachyos]\nServer = https://mirror.cachyos.org/repo/x86_64/$repo/\n' "$conf"
	else
		printf '\n[cachyos]\nServer = https://mirror.cachyos.org/repo/x86_64/$repo/\n' >> "$conf"
	fi
	changed=1
fi

if ! pacman-key --list-keys "$aur_key" &>/dev/null; then
	echo "Trusting the [aur] signing key..."
	ensure_keyring
	pacman-key --add "$aur_key_file"
	pacman-key --lsign-key "$aur_key" # fails if the file holds another key
fi

aur_server=http://192.168.2.50/aur

if ! grep -q '^\[aur\]' "$conf"; then
	echo "Adding [aur] repo..."
	printf '\n[aur]\nSigLevel = Required\nServer = %s\n' "$aur_server" >> "$conf"
	changed=1
elif sed -n '/^\[aur\]/,/^\[/p' "$conf" | grep -q '^SigLevel = Optional TrustAll$'; then
	# Containers created before [aur] was signed
	echo "Requiring signatures for [aur]..."
	sed -i '/^\[aur\]/,/^\[/ s/^SigLevel = Optional TrustAll$/SigLevel = Required/' "$conf"
	changed=1
fi

if grep -q '^Server = http://192.168.2.38$' "$conf"; then
	# Containers created before aur-builder replaced the LXC builder
	echo "Moving [aur] repo to $aur_server..."
	sed -i "s#^Server = http://192.168.2.38\$#Server = $aur_server#" "$conf"
	changed=1
fi

if [ "$changed" -eq 1 ]; then
	pacman -Sy
fi
