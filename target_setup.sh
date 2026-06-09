#!/usr/bin/env bash
# target_setup.sh - Complete setup for Ubuntu 22.04 target machine
# Usage: sudo ./target_setup.sh

set -euo pipefail

# Configurations
SPLUNK_UF_URL="https://download.splunk.com/products/universalforwarder/releases/9.1.1/linux/splunkforwarder-9.1.1-64e843ea36b1-linux-2.6-amd64.deb"
SPLUNK_INDEXER="192.168.1.102:9997"
INDEX_NAME="ssh_security"
DECOY_PASSWORD="Password123!" # Simple weak password for simulation purposes

function log() {
    echo -e "\n[*] $1"
}

# 1. Root verification
if [[ $EUID -ne 0 ]]; then
   echo "[-] This script must be run as root (sudo)."
   exit 1
fi

# 2. OpenSSH Server Installation & Hardening
log "Installing OpenSSH server and utilities..."
apt-get update
apt-get install -y openssh-server rsyslog wget

log "Hardening OpenSSH Configuration..."
SSHD_CONFIG="/etc/ssh/sshd_config"
# Backup original config
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak"

# Apply hardening and verbosity parameters
# LogLevel VERBOSE records key fingerprints on login, useful for auditing
sed -i 's/^#\?LogLevel.*/LogLevel VERBOSE/' "$SSHD_CONFIG"
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 4/' "$SSHD_CONFIG"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"

log "Restarting SSH and Rsyslog services..."
systemctl restart ssh
systemctl enable --now rsyslog
systemctl restart rsyslog

# 3. Create Decoy User Accounts
log "Creating 5 decoy user accounts with weak passwords..."
for i in {1..5}; do
    USERNAME="user${i}"
    if id "$USERNAME" &>/dev/null; then
        log "User $USERNAME already exists. Resetting password..."
    else
        useradd -m -s /bin/bash "$USERNAME"
    fi
    echo "${USERNAME}:${DECOY_PASSWORD}" | chpasswd
    log "User $USERNAME configured (Password: $DECOY_PASSWORD)"
done

# 4. Verify auth.log is working
log "Verifying auth.log generation..."
touch /var/log/auth.log
chmod 640 /var/log/auth.log
chown syslog:adm /var/log/auth.log
logger -p auth.info "SSH detection lab setup test log entry"
if grep -q "SSH detection lab setup test log entry" /var/log/auth.log; then
    echo "[+] System logging to /var/log/auth.log verified successfully."
else
    echo "[!] Warning: Test entry not found in /var/log/auth.log. Check rsyslog configuration."
fi

# 5. Install Splunk Universal Forwarder
log "Downloading Splunk Universal Forwarder..."
if [[ ! -f "/tmp/splunkforwarder.deb" ]]; then
    wget -O /tmp/splunkforwarder.deb "$SPLUNK_UF_URL"
fi

log "Installing Splunk Universal Forwarder package..."
dpkg -i /tmp/splunkforwarder.deb

# 6. Configure boot start and start UF
log "Enabling Splunk Forwarder boot-start..."
/opt/splunkforwarder/bin/splunk enable boot-start -user splunk -systemd-managed 1 --accept-license --answer-yes --no-prompt

log "Starting Splunk Forwarder service..."
systemctl start SplunkForwarder

# 7. Configure Forwarding (outputs.conf)
log "Configuring outputs.conf to send data to $SPLUNK_INDEXER..."
sudo -u splunk /opt/splunkforwarder/bin/splunk add forward-server "$SPLUNK_INDEXER" -auth admin:changeme

# 8. Configure Monitoring (inputs.conf)
log "Configuring inputs.conf to monitor /var/log/auth.log..."
sudo -u splunk /opt/splunkforwarder/bin/splunk add monitor /var/log/auth.log -index "$INDEX_NAME" -sourcetype linux_secure

# 9. Ensure correct permissions on auth.log so splunk forwarder can read it
log "Configuring log permissions for Splunk Forwarder..."
# Add splunk user to adm group to read auth.log
usermod -aG adm splunk

log "Restarting Splunk Forwarder..."
systemctl restart SplunkForwarder

log "Verifying Forwarder Status..."
sudo -u splunk /opt/splunkforwarder/bin/splunk list forward-server -auth admin:changeme

echo -e "\n[+] Component 1 Setup Complete!"
echo "Target machine is configured. Logs from /var/log/auth.log are routed to $SPLUNK_INDEXER (Index: $INDEX_NAME)."
