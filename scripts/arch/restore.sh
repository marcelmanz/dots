#!/usr/bin/env bash

BACKUP_FILE_NAME="arch-packages"
BACKUP_FILE_NAME_AUR="arch-packages-aur"

echo "Restoring Arch Linux packages..."
sudo pacman -S --needed - <$BACKUP_FILE_NAME

echo "Restoring Arch Linux AUR packages..."
for x in $(<$BACKUP_FILE_NAME_AUR); do yay -S $x; done

if [ $? -eq 0 ]; then
	echo "Restore complete!"
else
	errors=$?
	echo "Restore failed with errors: $errors"
fi
