#!/usr/bin/env bash

if [ ! -f /etc/arch-release ]; then
	echo "Not arch release. Nothing to do..."
	exit 0
fi

if grep -q "\[aur\]" /etc/pacman.conf; then
	echo "Repo already present. Nothing to do..."
	exit 0
fi

echo -e "\n[aur]\nSigLevel = Optional TrustAll\nServer = http://192.168.2.38" | tee -a /etc/pacman.conf
pacman -Sy
