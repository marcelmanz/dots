#!/usr/bin/env bash

APP_PACKAGE="com.whatsapp"
APK_PATH="/tmp/whatsapp.apk"

# If you pass a link as an argument, it uses that. Otherwise, it defaults to the main site.
CUSTOM_URL="$1"
DEFAULT_URL="https://www.whatsapp.com/android/download/"
DOWNLOAD_URL="${CUSTOM_URL:-$DEFAULT_URL}"

USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

echo "Checking Waydroid status..."

# 1. Check system container
if ! systemctl is-active --quiet waydroid-container; then
    echo "Waydroid container is inactive. Starting it now..."
    sudo systemctl start waydroid-container
    sleep 3
fi

# 2. Check and start user session
if ! waydroid status | grep -q "Session:\s*RUNNING"; then
    echo "Starting Waydroid user session..."
    waydroid session start &

    sleep 5

    # Catch the dreaded waydroid-net.sh error
    if ! waydroid status | grep -q "Session:\s*RUNNING"; then
        echo "Error: Waydroid session failed to start."
        echo "Try running: sudo systemctl restart waydroid-container"
        exit 1
    fi
else
    echo "Waydroid session is already active."
fi

# 3. Check for WhatsApp and Install
if ! waydroid app list | grep -q "$APP_PACKAGE"; then
    echo "WhatsApp is not installed."
    echo "Downloading APK from: $DOWNLOAD_URL"

    curl -L -A "$USER_AGENT" -o "$APK_PATH" "$DOWNLOAD_URL"

    # Verify it's an APK (starts with 'PK' zip header)
    if head -c 2 "$APK_PATH" | grep -q "PK"; then
        echo "Download verified. Installing..."
        waydroid app install "$APK_PATH"
        rm "$APK_PATH"
    else
        echo "Error: The downloaded file is not a valid APK."
        echo "If the default link failed, try passing a direct link like this:"
        echo "./launch-whatsapp.sh \"https://your-direct-link.apk\""
        rm "$APK_PATH"
        exit 1
    fi
else
    echo "WhatsApp is already installed."
fi

# 4. Launch WhatsApp
echo "Launching WhatsApp..."
waydroid app launch "$APP_PACKAGE"

echo "Done!"
