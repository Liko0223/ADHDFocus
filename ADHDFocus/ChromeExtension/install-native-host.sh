#!/bin/bash
HOST_NAME="com.lilinke.adhdfocus"
APP_PATH="/Applications/ADHDFocus.app/Contents/MacOS/ADHDFocusNativeHost"
MANIFEST_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"

mkdir -p "$MANIFEST_DIR"

cat > "$MANIFEST_DIR/$HOST_NAME.json" << EOF
{
  "name": "$HOST_NAME",
  "description": "ADHD Focus Native Messaging Host",
  "path": "$APP_PATH",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://EXTENSION_ID_HERE/"
  ]
}
EOF

echo "Native Messaging Host manifest installed to:"
echo "  $MANIFEST_DIR/$HOST_NAME.json"
echo ""
echo "NOTE: Replace EXTENSION_ID_HERE with your Chrome extension ID."
echo "Find it at chrome://extensions after loading the extension."
