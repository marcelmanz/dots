#!/usr/bin/env bash

BACKUP_FILE_NAME="arch-packages"
BACKUP_FILE_NAME_AUR="arch-packages-aur"

echo "Backing up Arch Linux packages..."
pacman -Qqen >$BACKUP_FILE_NAME
echo "Backing up Arch Linux AUR packages..."
pacman -Qqem >$BACKUP_FILE_NAME_AUR

if [ $? -eq 0 ]; then
	echo "Backup complete!"
else
	errors=$?
	echo "Backup failed with errors: $errors"
fi
