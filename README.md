SSH Brute-Force Detection in Splunk

📌 Project Overview

This project demonstrates how to simulate SSH brute-force attacks in a controlled lab environment and detect them using Splunk. The solution collects SSH authentication logs from a Linux server, analyzes failed and successful login attempts, and generates threshold-based alerts to identify credential abuse patterns.

The project helps security analysts understand how attackers perform brute-force attacks and how Security Information and Event Management (SIEM) platforms such as Splunk Enterprise can be used to detect and respond to such threats.

🎯 Objectives
Simulate SSH brute-force attacks in a lab environment.
Collect and monitor SSH authentication logs.
Ingest Linux authentication logs into Splunk.
Create dashboards for login monitoring.
Build threshold-based detection rules.
Generate alerts for suspicious login activity.
Visualize attack trends and attacker IP addresses.

🛠 Technologies Used
Tool	Purpose
Kali Linux	Attack machine
Metasploit Framework	SSH brute-force simulation
Nmap	Host discovery and port scanning
Splunk Enterprise	Log analysis and SIEM
Ubuntu/Linux Server	Target system
auth.log	Authentication log source

🏗 Architecture

+----------------+
| Kali Linux     |
| (Attacker)     |
+--------+-------+
         |
         | SSH Brute Force
         v
+----------------+
| Linux Server   |
| SSH Service    |
+--------+-------+
         |
         | auth.log
         v
+----------------+
| Splunk Forwarder|
+--------+-------+
         |
         v
+----------------+
| Splunk SIEM    |
| Dashboards     |
| Alerts         |
+----------------+

🔧 Lab Setup
Attacker Machine
Kali Linux
Metasploit Framework
Nmap
Target Machine
Ubuntu Server
OpenSSH Service Enabled
Monitoring Machine
Splunk Enterprise
Splunk Universal Forwarder

📂 Log Source

Linux authentication logs:

/var/log/auth.log

Example failed login event:

Jun 10 10:15:20 ubuntu sshd[1520]:
Failed password for invalid user admin
from 192.168.1.10 port 52621 ssh2

Example successful login event:

Jun 10 10:18:10 ubuntu sshd[1601]:
Accepted password for user1
from 192.168.1.10 port 52645 ssh2
🚀 Attack Simulation
Step 1: Scan Target
nmap -sV 192.168.1.20

Verify SSH service is running.

Step 2: Create Username List
root
admin
user
test
ubuntu
Step 3: Launch SSH Brute Force

Using Metasploit:

msfconsole
use auxiliary/scanner/ssh/ssh_login
set RHOSTS 192.168.1.20
set USER_FILE users.txt
set PASS_FILE passwords.txt
set VERBOSE true
run

📥 Splunk Log Ingestion
Monitor auth.log
Settings → Data Inputs → Files & Directories

Add:

/var/log/auth.log

Source Type:

linux_secure

Index:

security

🔍 Splunk Detection Queries
Failed SSH Login Attempts
index=security sourcetype=linux_secure
"Failed password"
| stats count by src
| sort -count
Top Attacker IPs
index=security sourcetype=linux_secure
"Failed password"
| stats count by src
| sort -count
Successful SSH Logins
index=security sourcetype=linux_secure
"Accepted password"
| stats count by user
Brute Force Detection Rule

Detect more than 10 failed logins within 5 minutes:

index=security sourcetype=linux_secure
"Failed password"
| bucket _time span=5m
| stats count by src,_time
| where count > 10

📊 Dashboard Components
SSH Security Dashboard
Panels
Total Failed Logins
Total Successful Logins
Top Source IP Addresses
Failed Login Trend
Successful Login Trend
SSH Login Heatmap
Geographic Source Analysis (Optional)

🚨 Alert Configuration
Alert Name
SSH Brute Force Detection
Trigger Condition
index=security sourcetype=linux_secure
"Failed password"
| bucket _time span=5m
| stats count by src,_time
| where count > 10
Alert Type
Scheduled
Schedule
Every 5 Minutes
Trigger
When Number of Results > 0
Actions
Email Notification
Dashboard Alert
Incident Creation
Webhook Integration
📈 Expected Results

The dashboard should identify:

Repeated failed SSH logins.
Credential stuffing attempts.
Password spraying attacks.
Suspicious attacker IP addresses.
Successful logins following multiple failures.
Attack timelines and trends.

🔐 Security Use Cases
Brute-Force Attack Detection
Credential Abuse Monitoring
Insider Threat Monitoring
Unauthorized Access Detection
SSH Activity Auditing
Security Operations Center (SOC) Monitoring

📸 Sample Screenshots
screenshots/
├── dashboard.png
├── alert_configuration.png
├── failed_logins.png
├── top_attackers.png
└── brute_force_alert.png
📚 Learning Outcomes

After completing this project, you will understand:

SSH authentication mechanisms.
Linux authentication logging.
Splunk data ingestion.
SIEM dashboard creation.
Threat detection engineering.
Security alert tuning.
SOC monitoring workflows.
⚠ Disclaimer

This project is intended strictly for educational and authorized cybersecurity lab environments. Do not perform brute-force attacks against systems without explicit permission.

👨‍💻 Author

Gayathri.M

Role: Cybersecurity Analyst / SOC Analyst
Skills: Splunk, SIEM, Threat Detection, Log Analysis, Linux Security
GitHub: https://github.com/Gayathri334
⭐ Future Enhancements
Integrate GeoIP Enrichment
Add Risk-Based Alerting
MITRE ATT&CK Mapping
Automated Incident Response
Splunk Enterprise Security Integration
Machine Learning-Based Anomaly Detection
MITRE ATT&CK Mapping
Technique	ID
Brute Force	T1110
Password Guessing	T1110.001
Valid Accounts	T1078
Remote Services (SSH)	T1021.004
