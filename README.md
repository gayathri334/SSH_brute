# SSH Brute-Force Detection Lab

This directory contains the defensive components of the SSH Brute-Force detection SIEM setup:

## Directory Structure

- `spl_queries.md`: Contains the 6 core production SPL queries designed to detect brute forcing, username enumeration, and SSH credential compromise.
- `splunk_app_ssh_detection/`: A Splunk application structure containing:
  - `default/inputs.conf`: Configures Splunk to monitor `/var/log/auth.log` and ingestion into the `ssh_security` index.
  - `default/props.conf`: Sourcetype configurations for `linux_secure`.
  - `default/transforms.conf`: RegEx extractions for fields: `src_ip`, `username`, `port`, `auth_method`, `status`.
  - `default/savedsearches.conf`: Alert definitions for detecting brute force, username enumeration, and credential stuffing.
  - `default/indexes.conf`: Defines the `ssh_security` index configuration with a 30-day retention window.
  - `default/data/ui/views/ssh_brute_force_dashboard.xml`: SimpleXML source for the Splunk Dashboard.
- `target_setup.sh`: Automated bash script to install and harden OpenSSH on Ubuntu 22.04, create decoy accounts, install Splunk Universal Forwarder, and configure log forwarding.
- `splunk_setup.sh`: Automated bash script to configure the Splunk Indexer receiving port and create the `ssh_security` index.

## How to use

To deploy the Splunk app, you can copy the `splunk_app_ssh_detection` folder to your Splunk Enterprise instance's apps directory (e.g., `/opt/splunk/etc/apps/`) and restart Splunk.

*(Note: Active attack simulations using Hydra/Metasploit/Nmap and target configurations must be run inside an isolated laboratory network).*
