#!/usr/bin/env bash
# Runs as root on every container start, before distrobox installs additional_packages.
# Repo order sets priority: Arch [core]/[extra] first, then [cachyos], then the local [aur]
# builds, so a package found in both [cachyos] and [aur] (e.g. brave-bin) comes from CachyOS.

set -e

if [ ! -f /etc/arch-release ]; then
	echo "Not arch release. Nothing to do..."
	exit 0
fi

conf=/etc/pacman.conf
cachyos_key=F3B607488DB35A47
changed=0

if ! grep -q '^\[cachyos\]' "$conf"; then
	echo "Adding [cachyos] repo..."
	# The Arch image ships without a local master key, which --lsign-key needs
	if ! gpg --homedir /etc/pacman.d/gnupg --list-secret-keys --with-colons 2>/dev/null | grep -q '^sec'; then
		pacman-key --init
	fi
	pacman-key --recv-keys "$cachyos_key" --keyserver keyserver.ubuntu.com
	pacman-key --lsign-key "$cachyos_key"
	if grep -q '^\[aur\]' "$conf"; then
		sed -i '/^\[aur\]/i [cachyos]\nServer = https://mirror.cachyos.org/repo/x86_64/$repo/\n' "$conf"
	else
		printf '\n[cachyos]\nServer = https://mirror.cachyos.org/repo/x86_64/$repo/\n' >> "$conf"
	fi
	changed=1
fi

if ! grep -q '^\[aur\]' "$conf"; then
	echo "Adding [aur] repo..."
	printf '\n[aur]\nSigLevel = Optional TrustAll\nServer = http://192.168.2.38\n' >> "$conf"
	changed=1
fi

if [ "$changed" -eq 1 ]; then
	pacman -Sy
fi
