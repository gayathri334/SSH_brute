#!/usr/bin/env bash
# splunk_setup.sh - Configures the Splunk Server (Indexer)
# Usage: sudo ./splunk_setup.sh

set -euo pipefail

SPLUNK_BIN="/opt/splunk/bin/splunk"
INDEX_NAME="ssh_security"

function usage() {
    echo "Usage: sudo $0"
    echo "Configures receiving port 9997 and creates the $INDEX_NAME index."
    exit 1
}

if [[ ! -f "$SPLUNK_BIN" ]]; then
    echo "[-] Splunk binary not found at $SPLUNK_BIN. Ensure Splunk Enterprise is installed."
    exit 1
fi

echo "[*] Enabling receiving on port 9997..."
$SPLUNK_BIN enable listen 9997 -auth admin:changeme || echo "[!] Port 9997 may already be listening."

echo "[*] Creating index '$INDEX_NAME'..."
# Create the index from CLI if it doesn't exist (can also be managed by placing indexes.conf in local/ or default/)
$SPLUNK_BIN add index "$INDEX_NAME" -auth admin:changeme || echo "[!] Index $INDEX_NAME may already exist."

echo "[*] Setting 30-day retention on index '$INDEX_NAME'..."
# Update the index configuration to set max age to 30 days (2592000 seconds)
$SPLUNK_BIN edit index "$INDEX_NAME" -maxDataSize auto_high_volume -frozenTimePeriodInSecs 2592000 -auth admin:changeme

echo "[+] Splunk setup complete! Ensure the Splunk App configurations (inputs, props, transforms, indexes) are copied to /opt/splunk/etc/apps/."
