#!/bin/sh

echo "Validating the desktop entry..."
desktop-file-validate $1
if [ $? -ne 0 ]; then
	exit 1
fi

echo "The desktop entry has been validated."
