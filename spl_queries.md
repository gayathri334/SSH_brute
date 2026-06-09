# SSH Brute-Force Detection - Splunk Queries

Below are the 6 core production-ready SPL queries designed for the SSH Brute-Force Detection Lab. Run these queries in your Splunk search bar within the `ssh_security` index.

---

## Query 1: Brute-Force Threshold Detection

Detects when a single source IP generates more than 10 failed SSH attempts within a 5-minute window.

```spl
index=ssh_security sourcetype=linux_secure status=failure earliest=-5m
| stats count as attempt_count, min(_time) as first_attempt, max(_time) as last_attempt, values(username) as targeted_users by src_ip
| where attempt_count > 10
| eval first_attempt=strftime(first_attempt, "%Y-%m-%d %H:%M:%S"), last_attempt=strftime(last_attempt, "%Y-%m-%d %H:%M:%S")
```

---

## Query 2: Successful Login After Multiple Failures (Credential Stuffing)

Correlates a series of failed logins followed by a successful login from the same IP address within a 10-minute span. This represents a potential active account compromise.

```spl
index=ssh_security sourcetype=linux_secure (status=failure OR status=success) earliest=-24h
| transaction src_ip maxspan=10m
| search status=failure AND status=success
| eval fail_count=mvcount(mvfilter(status=="failure"))
| where fail_count >= 5
| eval success_time=strftime(max(eval(if(status=="success", _time, null))), "%Y-%m-%d %H:%M:%S")
| table src_ip, fail_count, success_time, username
```

---

## Query 3: Username Enumeration Pattern

Detects a single source IP attempting to authenticate against 3 or more distinct usernames within a 15-minute window, which indicates scanning or username harvesting.

```spl
index=ssh_security sourcetype=linux_secure status=failure earliest=-15m
| stats dc(username) as distinct_usernames, values(username) as username_list, count as total_attempts by src_ip
| where distinct_usernames >= 3
```

---

## Query 4: Geographic Anomaly Detection

Uses Splunk's internal MaxMind IP database (`iplocation`) to flag SSH login failures originating from unexpected or foreign countries.

```spl
index=ssh_security sourcetype=linux_secure status=failure
| iplocation src_ip
| fillnull value="Unknown" Country
| where Country != "United States" AND Country != "Local" AND Country != "Unknown"
| stats count by src_ip, Country, City
| sort - count
```

---

## Query 5: After-Hours Login Attempts

Flags successful or failed SSH attempts occurring during non-standard hours (between 11:00 PM and 6:00 AM local time).

```spl
index=ssh_security sourcetype=linux_secure
| eval hour=strftime(_time, "%H")
| where hour >= 23 OR hour < 6
| stats count, values(username) as attempted_users, values(status) as statuses by src_ip, hour
| sort - count
```

---

## Query 6: Top Attackers Summary

Generates a leaderboard of the top 10 external IP addresses ranked by the number of failed SSH attempts over the last 24 hours.

```spl
index=ssh_security sourcetype=linux_secure status=failure earliest=-24h
| stats count as total_attempts, dc(username) as unique_users_targeted, values(username) as sample_users by src_ip
| sort - total_attempts
| head 10
```
