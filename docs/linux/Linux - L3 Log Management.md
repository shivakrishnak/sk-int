---
layout: default
title: "Linux - L3 Log Management"
parent: "Linux"
nav_order: 7
permalink: /linux/l3-log-management/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Difficulty |
|---|---------|------------|
| 16 | [Log Management: journald, syslog, and logrotate](#log-management-journald-syslog-and-logrotate) | ★★☆ |
| 17 | [Linux Security: sudo, SELinux, and AppArmor](#linux-security-sudo-selinux-and-apparmor) | ★★☆ |

---

# Log Management: journald, syslog, and logrotate

**Interview Weight:** High - log management is a fundamental backend
operations skill; diagnosing crashed services, investigating security
incidents, and preventing disk-full outages all depend on knowing the
Linux logging stack.

---

### 🎯 Model Answer

**30-second answer:**

"Linux logging uses two layers: journald collects structured logs from
all systemd services (queried with journalctl), and syslog/rsyslog
writes plain text to `/var/log/`. logrotate rotates, compresses, and
purges log files on schedule. The three tools work together: journald
can forward to syslog, syslog writes files, logrotate manages file size.
Disk-full is the most dangerous failure mode - logs stop, services may
crash, diagnose with `journalctl --disk-usage` and `df -h /var/log`."

**3-minute answer:**

"The Linux logging stack has three tiers. First, systemd-journald
captures everything written to stdout/stderr by any systemd unit plus
kernel messages. It stores data as a binary database in `/var/log/
journal/` (if persistent) or `/run/log/journal/` (in-memory only).
Queried with `journalctl`.

Second, rsyslog (or syslog-ng) is the traditional syslog daemon. It
can receive messages from journald (via `imjournal` input module),
network syslog (UDP/TCP port 514), and direct syslog() system calls.
It writes to files like `/var/log/messages`, `/var/log/secure`, etc.

Third, logrotate runs daily via cron and rotates, compresses, and
purges old log files. It uses configuration in `/etc/logrotate.conf`
and `/etc/logrotate.d/`. For services with open file handles, logrotate
can send SIGHUP (`postrotate: kill -HUP PID`) to make the service
re-open the log file.

Key operational tasks: check disk usage (`du -sh /var/log/*`), view
error-rate trends (`journalctl -p err --since '24 hours ago' | wc -l`),
and verify logrotate ran (`ls -la /var/log/*.gz`)."

**Blank Mind Recovery:**

"journalctl -u service. journalctl -p err. journalctl --disk-usage.
rsyslog at /var/log/messages. logrotate /etc/logrotate.d/. postrotate
SIGHUP for live services. Watch disk usage."

---

### 📘 Concept Explanation

**What it is:**

The Linux log management stack: systemd-journald for structured binary
log collection from services and kernel; rsyslog/syslog for traditional
text-file logging with routing and filtering; logrotate for file-based
log lifecycle management (rotation, compression, retention).

**Why it exists:**

Without log management, long-running services fill `/var/log/` until
the disk is full, causing cascading failures. The structured journal
enables efficient queries by time, unit, and priority. The syslog
forwarding layer sends logs to centralized systems (Splunk, ELK) for
fleet-wide analysis.

**Core mental model:**

```
Service/Kernel Output
    |
    v (stdout/stderr + kernel ring buffer)
journald (binary, indexed, rate-limited)
    |              |
    v              v (via imjournal module)
journalctl      rsyslog -------> /var/log/messages
(query tool)       |              /var/log/secure
                   |              /var/log/nginx/access.log
                   v
           logrotate (daily cron)
           [rotate -> compress -> delete old]
```

> **Diagram walkthrough:** The Linux logging flow starts at service
> output (stdout/stderr) collected by journald, then optionally
> forwarded to rsyslog which routes messages to specific log files.
> logrotate sits at the bottom of the stack managing the files
> rsyslog creates. The KEY RELATIONSHIP: journald and rsyslog are
> parallel sinks - a message can exist in both the binary journal
> AND a text log file. The EDGE CASE: if journald fills up (controlled
> by `SystemMaxUse`), it deletes old entries; if rsyslog's log files
> fill up without logrotate running, the disk fills and services fail.
> INSIGHT: the binary journal is the preferred query interface for
> recent logs; log files are for long-term storage and external ingestion.

**Key terminology:**

- **Journal**: systemd-journald's binary log database, stored in
  `/var/log/journal/` (persistent) or `/run/log/journal/` (volatile)
- **Cursor**: a unique journal entry identifier for resuming reads
  (used by log forwarders to track position)
- **Syslog priority**: numeric 0-7 severity (0=emerg, 3=err, 7=debug)
- **Facility**: syslog category (kern, mail, daemon, auth, etc.)
- **Rotation**: renaming the current log file and creating a new one
  so the service writes fresh; old file is then compressed/deleted
- **copytruncate**: logrotate mode that copies the log, then truncates
  the original (for programs that cannot reopen the file on SIGHUP)

**How it works internally:**

journald uses a double-linked list structure for log entries with
field-level compression. Each entry stores: timestamp, PID, UID, GID,
boot ID, machine ID, unit name, syslog priority, and the message. The
binary format enables O(1) lookup by any indexed field.

logrotate checks modification time or size triggers, renames files
with date suffixes, calls `postrotate` scripts (typically SIGHUP to
the service), then gzip-compresses old files and deletes beyond the
retention count.

**Trade-offs:**

| Aspect | journald | rsyslog + files |
|--------|----------|-----------------|
| Query speed | Fast (indexed binary) | Slow (grep on text) |
| Human readable | No (requires journalctl) | Yes (cat, grep, tail) |
| Network forwarding | Via imjournal | Native TCP/UDP syslog |
| Storage efficiency | Binary + compression | Plain text (large) |
| Tool ecosystem | journalctl only | grep, awk, logwatch |
| Log loss on disk full | Old entries purged | Writes fail (disk full) |

**Real-world usage:**

On a production Java application: `journalctl -u myapp -p err --since
'1 hour ago'` finds all error-level messages in the last hour in
seconds. The same query on `/var/log/myapp.log` with grep takes longer
and requires knowing the timestamp format. For security auditing,
`journalctl _UID=0` shows all actions by root across all services.

---

### 💻 Code Example

**BAD: Log file fills disk, no rotation**

```bash
# BAD: application writes to a file that grows indefinitely
java -jar app.jar >> /var/log/app.log 2>&1 &
# 3 months later: /var/log/app.log is 80GB
# Disk is full, application stops writing logs silently
# Other services fail because /tmp and spool directories are also full
df -h /
# /dev/xvda1 100G 100G 0 100% /   <- FULL, services failing
```

> **Code walkthrough:** This shows the disk-full failure pattern from
> unmanaged log files. KEY MECHANISM: when the disk reaches 100%
> usage, `write()` system calls return ENOSPC (no space left on
> device); most applications log this error to the log file they
> cannot write to, causing a confusing failure. WHY IT MATTERS: a
> full disk causes cascading failures - systemd cannot write unit
> status, databases cannot write WAL files, sshd cannot write auth
> logs. WHAT BREAKS: applications often SILENTLY stop logging when
> the write fails rather than crashing; the service appears healthy
> but produces no logs. TAKEAWAY: always configure logrotate for
> any application that writes to files; disk-full from logs is one
> of the most common production outage causes.

**GOOD: Proper journald configuration and logrotate setup**

```bash
# Check current journal disk usage
journalctl --disk-usage
# Archived and active journals take up 512.0M on disk.

# Configure journald size limits (in /etc/systemd/journald.conf)
cat /etc/systemd/journald.conf
# [Journal]
# Storage=persistent         # write to /var/log/journal/
# SystemMaxUse=2G            # max 2GB total journal size
# SystemKeepFree=500M        # always keep 500MB free
# MaxRetentionSec=30day      # delete entries older than 30 days
# MaxFileSec=1week           # rotate journal files weekly
# RateLimitIntervalSec=30s
# RateLimitBurst=10000       # max 10000 messages per 30s per service

# Apply configuration
systemctl restart systemd-journald
```

> **Code walkthrough:** `SystemMaxUse=2G` and `SystemKeepFree=500M`
> work together: journald will not use more than 2GB AND will ensure
> at least 500MB remains free on the filesystem, whichever is smaller.
> KEY MECHANISM: when the size limit is reached, journald deletes the
> oldest journal files (not individual entries). WHY IT MATTERS:
> without these limits, a misbehaving service can fill the entire disk
> by generating millions of log entries per second. WHAT BREAKS:
> `RateLimitBurst=10000` per 30 seconds means a service generating
> more logs is rate-limited; rate-limited messages are dropped with a
> warning. TAKEAWAY: set `SystemMaxUse` to 10-20% of disk size and
> `SystemKeepFree` to at least the size of your largest log file.

**logrotate configuration for a Java application**

```bash
# /etc/logrotate.d/myapp
/var/log/myapp/*.log {
    daily                    # rotate daily
    rotate 30                # keep 30 days of logs
    compress                 # gzip compressed rotated files
    delaycompress            # compress previous log, not current
    missingok                # do not error if log file is missing
    notifempty               # do not rotate empty files
    create 0640 myapp myapp  # create new log file with these perms
    sharedscripts            # run postrotate once for all logs
    postrotate
        # Signal app to reopen log files after rotation
        systemctl reload myapp 2>/dev/null || true
    endscript
}
```

> **Code walkthrough:** `delaycompress` is the most important and
> least understood option: the file rotated TODAY is not compressed
> yet (so `tail -f` and running log watchers still work on it), while
> the file rotated YESTERDAY gets compressed now. KEY MECHANISM:
> logrotate renames `app.log` to `app.log.1`, creates a new `app.log`,
> and signals the service; on the NEXT rotation, `app.log.1` becomes
> `app.log.2.gz`. WHY IT MATTERS: `compress` without `delaycompress`
> compresses the file the service is still writing to, which either
> fails (file in use) or causes log loss. WHAT BREAKS: missing
> `postrotate` means the application keeps writing to the renamed
> file; the new `app.log` remains empty until the next service restart.
> TAKEAWAY: every logrotate config must have a `postrotate` block that
> signals the application to reopen its log file descriptors.

**Diagnosing log issues in production**

```bash
# Check log disk usage breakdown
du -sh /var/log/* | sort -hr | head -20
# 4.2G /var/log/journal     <- journal taking up 4.2GB
# 800M /var/log/nginx
# 200M /var/log/myapp

# Find rapidly growing log files (run twice, compare sizes)
find /var/log -name "*.log" -newer /tmp/marker -size +100M

# Check error rate trend
journalctl -p err --since '1 hour ago' | wc -l
# Compare to yesterday
journalctl -p err --since 'yesterday' --until '1 hour ago' | wc -l

# Find which service is producing the most logs
journalctl --since '10 min ago' | awk '{print $5}' | \
  sort | uniq -c | sort -rn | head -10
```

> **Code walkthrough:** `journalctl | awk '{print $5}'` extracts the
> systemd unit name field (column 5 in the default output format) and
> counts occurrences with `uniq -c | sort -rn`. KEY MECHANISM: this
> identifies the "log spammer" - the service generating excessive log
> volume that is consuming disk space and rate-limit budget. WHY IT
> MATTERS: a single service in a tight retry loop can generate
> thousands of identical error messages per second, filling the disk
> within minutes. WHAT BREAKS: `awk '{print $5}'` assumes the default
> journal output format; use `journalctl -o json` and `jq` for
> reliable field extraction. TAKEAWAY: identify log spammers first
> when diagnosing rapid disk fill; fix the root cause rather than
> just increasing retention limits.

---

### 🎓 Answers by Seniority

**Junior / Mid-level answer:**

"Logs are in `/var/log/` for text files and journalctl for systemd
services. logrotate rotates logs so they do not fill the disk. I use
`journalctl -u service -n 50` to check recent service logs."

*What's missing: no mention of journal disk limits, logrotate
postrotate signals, log forwarding to centralized systems, or
diagnosing disk-full scenarios.*

**Senior / Staff answer:**

"The logging stack has three layers. journald captures all service
output as structured binary; I configure `SystemMaxUse=2G` and
`MaxRetentionSec=30day` in `journald.conf` to prevent disk fill.
rsyslog forwards journal entries to text files (and optionally to
centralized logging like Splunk via TCP syslog). logrotate handles
file rotation with `postrotate` blocks that send SIGHUP to services.

For diagnosis: `du -sh /var/log/*` identifies which service is
consuming disk, `journalctl | awk '{print $5}' | sort | uniq -c`
finds log spammers, and `journalctl -p err --since '1 hour ago' | wc
-l` quantifies the error rate. For persistent disk-full prevention:
journal size limits are the first line of defense; logrotate is the
second. A service that logs 10,000 lines per second hits the journal
rate limit and those entries are DROPPED with a warning - important to
know so you are not relying on completeness during incident analysis."

---

### ⚠️ Common Misconceptions

**"journalctl logs are in /var/log/messages"**

journald writes to `/var/log/journal/` (binary, not readable by cat).
`/var/log/messages` is written by rsyslog from syslog() calls and
optionally from journal forwarding. Many minimal server images disable
rsyslog entirely, so `/var/log/messages` does not exist - all logs
are only in the journal. Always check `journalctl` first.

**"logrotate restarts the service after rotation"**

logrotate rotates the file (renames it) but does NOT restart the
service. The `postrotate` script must SIGNAL the service to reopen its
log file descriptors. The standard signal is SIGHUP (`systemctl reload`
or `kill -HUP PID`). Without this signal, the service continues writing
to the renamed file (the old inode), and the new log file stays empty.

**"journalctl -f is equivalent to tail -f on /var/log"**

`journalctl -f` follows the journal in real time, but it shows logs
from ALL systemd services, not just one file. `journalctl -f -u
myapp` follows a specific service. The output format also differs:
journal output includes unit name, PID, and priority metadata that
tail -f on a file does not.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Disk full from log overflow**

```bash
# Symptoms: services failing to start, database errors, SSH not working
df -h
# /dev/xvda1 50G 50G 0 100% /

# Identify largest log consumers
du -sh /var/log/* 2>/dev/null | sort -hr | head -10

# Emergency: vacuum old journal entries to free space immediately
journalctl --vacuum-size=500M    # keep only 500MB
journalctl --vacuum-time=7d      # delete older than 7 days

# Verify space freed
df -h && journalctl --disk-usage
```

> **Code walkthrough:** `journalctl --vacuum-size=500M` is the
> emergency disk-recovery command for journal-caused disk fill. KEY
> MECHANISM: it deletes the oldest archived journal files until the
> total size is at or below the specified limit; it cannot recover
> space from the ACTIVE journal file. WHY IT MATTERS: on a 100% full
> disk, even creating a temporary file to analyze the problem may
> fail; vacuum is the quickest path to freeing space. WHAT BREAKS:
> after vacuum, you lose historical logs that may be needed for
> incident post-mortem; vacuum BEFORE investigation is risky.
> TAKEAWAY: set `SystemMaxUse` in journald.conf to prevent disk fill
> proactively; use vacuum only for emergency recovery.

**Failure 2: Log file not being written after rotation**

```bash
# Symptom: /var/log/myapp.log exists but is empty after rotation
ls -la /var/log/myapp.log*
# -rw-r--r-- 1 myapp myapp 0 Jan 15 04:02 myapp.log    <- empty new file
# -rw-r--r-- 1 myapp myapp 2.1G Jan 15 04:01 myapp.log.1  <- old file

# Check if the app is still writing to the old file
lsof /var/log/myapp/myapp.log.1
# java 12345 myapp 3w REG ... /var/log/myapp.log.1
# The app is writing to .log.1 (renamed file), not the new .log

# Fix: signal the app to reopen log files
systemctl reload myapp  # or kill -HUP $(cat /var/run/myapp.pid)

# Then verify
lsof /var/log/myapp/myapp.log
# java 12345 myapp 3w REG ... /var/log/myapp.log  <- now writing to new file
```

> **Code walkthrough:** `lsof /var/log/myapp.log.1` confirms the
> application has an open file descriptor to the renamed (rotated)
> file by showing java's PID with 'w' (write) access. KEY MECHANISM:
> when logrotate renames `app.log` to `app.log.1`, the kernel inode
> stays the same; the application's file descriptor still points to
> the inode, not the name. WHY IT MATTERS: the application keeps
> writing to `app.log.1`, which will NOT be compressed or deleted
> since logrotate does not know about this file. WHAT BREAKS: if the
> `postrotate` SIGHUP handler is missing or broken, this continues
> indefinitely until the next service restart. TAKEAWAY: `lsof` is
> the definitive tool to confirm where an application is actually
> writing logs after rotation.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | journal vs syslog, logrotate mechanics |
| Debugging | 3 | disk full, rotation bugs, log forwarding |
| Production | 2 | retention policy, centralized logging |

---

**[JUNIOR] Q1 - What is the difference between journald and rsyslog, and why are both often installed?**

journald is the systemd log collector: it captures stdout/stderr from
all systemd services, kernel messages, and structured metadata (unit
name, PID, priority). It stores data as indexed binary in
`/var/log/journal/`. It is queried with `journalctl`.

rsyslog is the traditional syslog daemon: it accepts messages via the
syslog() system call, the syslog network protocol (UDP/TCP port 514),
and optionally from journald. It routes messages to text files based
on facility and priority (e.g., all auth messages to `/var/log/auth.log`,
all error+ messages to `/var/log/messages`).

Why both are installed:
1. Legacy applications use syslog() directly and expect text files
2. rsyslog forwards logs to centralized systems (Splunk, Elasticsearch)
   via its network output modules
3. Operations teams may rely on tools (logwatch, fail2ban) that read
   text log files
4. Compliance requirements often mandate text log files with specific
   formats

The two are connected via rsyslog's `imjournal` module, which reads
from the journal and writes to text files. This means a service that
logs to stdout gets captured by journald AND can be forwarded to text
files by rsyslog.

*What separates good from great:* understanding that journald is the
source of truth for recent logs (binary, structured, complete metadata)
while rsyslog is primarily a forwarding layer to text files and
centralized logging systems - they are complementary, not competing.

---

**[MID] Q2 - A log file is not growing after logrotate ran. How do you diagnose and fix it?**

This is the "rotated file inode" problem: the application holds an
open file descriptor to the old inode even after the file is renamed.

Diagnosis:
```bash
# Step 1: Confirm rotation happened
ls -la /var/log/myapp.log*
# app.log is present but empty; app.log.1 exists (the rotated file)

# Step 2: Check if app is writing to old file
lsof /var/log/myapp.log.1
# Shows app process with write descriptor on .log.1

# Step 3: Check logrotate ran and what postrotate did
cat /var/log/logrotate.log     # or: grep -i logrotate /var/log/messages
grep -A 5 "myapp" /etc/logrotate.d/myapp  # check postrotate config
```

> **Code walkthrough:** `lsof filename` lists all processes with open
> file descriptors to the specified file. KEY MECHANISM: the Linux
> kernel tracks file descriptors by inode number, not by filename;
> renaming the file changes the directory entry but NOT the inode, so
> open file descriptors continue to point to the same data. WHY IT
> MATTERS: this is why `postrotate` is critical - without it, the
> rotated file never gets the "close and reopen" that lets the app
> write to the new file. WHAT BREAKS: using `copytruncate` instead
> of `postrotate + SIGHUP` works by copying the log then truncating
> the original (preserving the inode), but risks log loss during
> the copy window. TAKEAWAY: prefer `postrotate + systemctl reload`
> over `copytruncate`; only use copytruncate for applications that
> cannot handle SIGHUP.

Fix: ensure postrotate block exists in the logrotate config and that
the signal correctly reaches the application. After adding, test with
`logrotate -f /etc/logrotate.d/myapp`.

*What separates good from great:* knowing that `logrotate -f -d
/etc/logrotate.d/myapp` runs logrotate in debug/dry-run mode, showing
exactly what it would do without actually rotating, which is the
correct way to test a new logrotate configuration.

---

**[SENIOR] Q3 - How do you configure centralized log shipping from a Linux server to a remote logging system?**

The standard approach uses rsyslog to forward logs to a centralized
logging system (ELK, Splunk, Datadog, etc.).

```bash
# /etc/rsyslog.d/99-forward.conf
# Forward all messages to centralized rsyslog server (TCP, with TLS)
*.* action(type="omfwd"
    target="logs.internal.example.com"
    port="514"
    protocol="tcp"
    action.resumeRetryCount="100"
    queue.type="LinkedList"
    queue.size="10000")

# OR: Forward journald entries specifically (using imjournal)
# Already handled by imjournal module which reads from journald
```

> **Code walkthrough:** `queue.type="LinkedList"` and `queue.size=
> "10000"` create an in-memory message queue that buffers log
> entries when the remote server is unavailable. KEY MECHANISM: when
> the remote connection fails, rsyslog continues to receive log
> entries and buffers up to 10000 of them; when the connection
> recovers, it flushes the queue in order. WHY IT MATTERS: without
> a queue, network hiccups cause log loss - messages generated while
> the connection is down are dropped. WHAT BREAKS: an in-memory queue
> is lost on rsyslog restart; for zero-loss requirements, use a
> disk-backed queue (`queue.type="LinkedList"` +
> `queue.fileName="/var/lib/rsyslog/fwdqueue"`). TAKEAWAY: always
> configure a queue for remote log forwarding; the default behavior
> is to drop messages when the remote is unavailable.

For JSON/structured forwarding to Elasticsearch:
```bash
# Ship journald as JSON directly via filebeat
# /etc/filebeat/filebeat.yml
# inputs:
#   - type: journald
#     id: journald
# output.elasticsearch:
#   hosts: ["https://es.internal:9200"]
```

> **Code walkthrough:** Filebeat's journald input uses systemd's
> journal API to read entries with full metadata (unit name, priority,
> PID) and ships them as structured JSON to Elasticsearch. KEY
> MECHANISM: filebeat tracks its journal read position using a cursor
> file, so it survives restarts without losing or duplicating entries.
> WHY IT MATTERS: this approach ships the full structured metadata
> that journald captures, not just the text message, enabling better
> search and aggregation in Elasticsearch. WHAT BREAKS: filebeat
> does not ship log files written by rsyslog, only journal entries;
> applications that log exclusively to files need a file input
> instead. TAKEAWAY: prefer the journald input for systemd services
> over file-based shipping; the structured metadata enables much
> better alerting and analysis.

*What separates good from great:* knowing that the journald cursor
(a position marker in the binary journal) allows log shippers like
filebeat and vector to resume after restarts without duplicate or
missing entries - this is a critical reliability property for
production log shipping.

---

**[SENIOR] Q4 - How do you implement log retention policies that comply with security audit requirements?**

Security audit requirements typically mandate log retention for
90-365 days and tamper-evident storage. Linux logging infrastructure
must be configured to satisfy these requirements.

```bash
# journald retention (in /etc/systemd/journald.conf)
[Journal]
SystemMaxUse=10G           # 10GB max journal size
SystemMaxFileSize=100M     # rotate journal files at 100MB
MaxRetentionSec=365day     # keep 1 year of logs
MaxFileSec=1week           # new journal file weekly (for rotation)
Compress=yes               # compress archived files

# logrotate retention (in /etc/logrotate.d/audit-logs)
/var/log/audit/*.log {
    daily
    rotate 365             # keep 365 rotated files (1 year)
    compress
    dateext                # use date suffix (not .1, .2, .3)
    dateformat -%Y%m%d
    sharedscripts
    postrotate
        systemctl reload auditd 2>/dev/null || true
    endscript
}
```

> **Code walkthrough:** `dateext` with `dateformat -%Y%m%d` names
> rotated files as `audit.log-20240115.gz` instead of `audit.log.1.gz`.
> KEY MECHANISM: date-suffixed filenames make it easy to identify and
> query logs from a specific date range without counting rotation
> numbers; `audit.log-20240101.gz` is unambiguous. WHY IT MATTERS:
> for security investigations requiring logs from a specific date,
> date-suffixed files are much faster to locate than counting
> `.1`, `.2`, `.3` numbered files. WHAT BREAKS: `rotate 365` without
> `dateext` creates `audit.log.365` through `audit.log.1`; beyond 365
> rotations (if logs are rotated more frequently), the oldest files
> are deleted. TAKEAWAY: always use `dateext` for security audit logs
> and retention periods exceeding 30 days.

For tamper-evident logging, forward logs to an immutable remote store:
- Write-once S3 bucket with Object Lock (AWS)
- Remote syslog to a dedicated security logging host with append-only
  filesystem
- Elasticsearch with index lifecycle management (ILM) that transitions
  to read-only after a retention period

*What separates good from great:* understanding that local log retention
is insufficient for compliance - security audit logs must be shipped to
a remote, tamper-evident store because root on the local server can
delete `/var/log/` files; only logs already forwarded to a separate
system cannot be retroactively altered.

---

**[SENIOR] Q5 - How does log rate limiting work in journald and what happens when a service hits the limit?**

journald implements per-service rate limiting to prevent a misbehaving
service from flooding the log store and causing disk fill.

```ini
# /etc/systemd/journald.conf
[Journal]
RateLimitIntervalSec=30s
RateLimitBurst=10000
```

> **Code walkthrough:** These two settings in `/etc/systemd/journald.conf`
> define the per-service rate limit window. KEY MECHANISM: the limit
> is per-service (per systemd unit), not system-wide; one noisy service
> is throttled without affecting other services' log throughput. WHY
> IT MATTERS: the default values (10000 messages in 30 seconds) allow
> about 333 messages/second per service - sufficient for normal
> operation but will throttle log storms from tight retry loops.
> WHAT BREAKS: setting `RateLimitBurst=0` disables rate limiting,
> allowing a misbehaving service to fill the disk in minutes. TAKEAWAY:
> never disable rate limiting; investigate and fix the log storm source.

When a service generates more than `RateLimitBurst` messages within
`RateLimitIntervalSec`:
1. journald logs: `systemd-journald[]: XX messages from process YY
   (myapp) suppressed.`
2. All subsequent messages from that service within the interval
   are DROPPED (not logged, not buffered)
3. After the interval resets, logging resumes

Diagnosis:
```bash
# Check if rate limiting has occurred
journalctl | grep -i "suppressed"
# systemd-journald[]: 50000 messages from process 12345 (java)
#   suppressed.

# Find the log storm source
journalctl --since '5 min ago' | cut -d' ' -f5 | \
  sort | uniq -c | sort -rn | head -5
```

> **Code walkthrough:** `cut -d' ' -f5` extracts the unit name field
> from journalctl's default output format (field 5 in the space-
> delimited format: `Jan 15 03:42:15 hostname unit[pid]: message`).
> KEY MECHANISM: counting occurrences per unit within a 5-minute window
> identifies log spammers; a service generating 50,000 messages in 5
> minutes is in a tight retry or error loop. WHY IT MATTERS: log
> storms cause rate limit suppression, meaning ERROR logs from OTHER
> services may also be dropped if they share the rate limit window.
> WHAT BREAKS: setting `RateLimitBurst=0` disables rate limiting
> entirely; this can cause disk fill within minutes from a
> misbehaving service. TAKEAWAY: investigate the ROOT CAUSE of a
> log storm (tight retry loop, missing null check, excessive DEBUG
> logging) rather than just increasing rate limits.

*What separates good from great:* understanding that when journald
rate-limits a service, the "suppressed" message itself counts as a
log entry, so the message `50000 messages suppressed` tells you the
service generated at least 50001 messages in 30 seconds - useful
for quantifying the severity of the log storm.

---

**[SENIOR] Q6 - How do you use auditd for security logging and what is the difference between audit logs and application logs?**

`auditd` is the Linux Audit subsystem: a kernel-level event recording
system that logs security-relevant events regardless of application
behavior.

```bash
# Install and enable audit daemon
systemctl enable --now auditd

# Add audit rule: track all writes to /etc/passwd
auditctl -w /etc/passwd -p wa -k passwd-change
# -w: watch this file
# -p wa: record write (w) and attribute change (a) events
# -k: key name for searching

# Track privilege escalation (all execve by root)
auditctl -a always,exit -F arch=b64 -F uid=0 \
  -S execve -k root-commands

# View audit log
ausearch -k passwd-change -ts today
# ----
# type=SYSCALL msg=audit(...): arch=c000003e syscall=2
#   success=yes exit=3 a0=... comm="passwd" exe="/usr/bin/passwd"
#   subj=... key="passwd-change"
```

> **Code walkthrough:** `auditctl -w /etc/passwd -p wa -k passwd-change`
> installs a file watch that generates an audit record for every
> write or attribute change on `/etc/passwd`, regardless of which
> process or user makes the change. KEY MECHANISM: the audit
> subsystem is implemented in the kernel; it intercepts syscalls
> before they complete, making it impossible to bypass by a compromised
> application. WHY IT MATTERS: application logs show what the
> application wants you to see; audit logs show what the KERNEL
> observed - every file open, network connection, privilege
> escalation, and process execution. WHAT BREAKS: audit rules are
> not persistent across reboots unless added to `/etc/audit/rules.d/`;
> `auditctl -l` shows current rules. TAKEAWAY: use auditd for
> compliance requirements that need immutable security event logging;
> application logs alone cannot prove a file was NOT modified.

Difference from application logs:
- Application logs: what the app chose to log (may miss events)
- Audit logs: kernel-level, complete, tamper-evident, cannot be
  bypassed by a compromised application
- Auditd is required for PCI-DSS, HIPAA, and SOC2 compliance

*What separates good from great:* understanding that auditd records
are generated by the KERNEL before the syscall returns, making them
forensically sound - a compromised process cannot prevent its own
audit trail from being recorded, unlike application-level logs which
the process controls.

---

**[JUNIOR] Q7 - How do you monitor a log file in real time and filter for specific patterns?**

For real-time log monitoring on Linux, three tools cover different use cases:

```bash
# Follow a specific service's journal in real time
journalctl -f -u myapp.service
# Shows new log entries as they are written

# Follow AND filter for errors only in real time
journalctl -f -u myapp.service -p err

# Follow a text log file
tail -f /var/log/nginx/access.log

# Follow AND filter for pattern
tail -f /var/log/nginx/access.log | grep '" 5[0-9][0-9] '
# Shows only 5xx error responses in real time

# Monitor multiple sources simultaneously
journalctl -f -u myapp -u nginx -u postgresql
# Interleaved real-time output from all three services
```

> **Code walkthrough:** `journalctl -f -u service1 -u service2`
> follows multiple service journals simultaneously, interleaving
> their output with timestamps in chronological order. KEY MECHANISM:
> journald writes to a binary file that journalctl polls with inotify;
> `tail -f` uses inotify on text files. WHY IT MATTERS: monitoring
> multiple related services (app + database + proxy) simultaneously
> reveals timing correlations during incident diagnosis that viewing
> services sequentially misses. WHAT BREAKS: `tail -f` stops working
> after logrotate renames the file; use `tail -F` (capital F) which
> reopens the file by name after rotation. TAKEAWAY: use `journalctl
> -f -u` for systemd services and `tail -F` (not `-f`) for text
> log files that rotate.

*What separates good from great:* using `journalctl -f -u app -u
dependency` to monitor multiple services simultaneously during
incident diagnosis, which reveals the temporal correlation between
events in different services that sequential viewing misses.

---

### ⚖️ Comparison Table

| Logging system | Storage | Query tool | Use case | Loss on failure |
|----------------|---------|------------|----------|-----------------|
| journald | Binary `/var/log/journal/` | journalctl | Service logs, kernel | Rate-limited drops |
| rsyslog files | Text `/var/log/*.log` | grep, tail | Legacy tools, compliance | Disk-full drops |
| auditd | Binary `/var/log/audit/` | ausearch, aureport | Security/compliance | Backpressure (blocks) |
| Application-to-file | Text, custom path | grep, awk | Custom log format | Disk-full drops |
| Centralized (ELK) | Remote indexed | Kibana/search API | Fleet-wide analysis | Queue buffers |

---

### 🏛️ System Design

*(Omit: ★★☆ log management operational keyword - centralized logging
architecture at fleet scale is covered in the observability and
distributed systems topics.)*

---

### 📊 Diagram

*(Omit: the logging stack flow is shown in the ASCII diagram in the
Concept Explanation section; an additional diagram would be redundant
for this operational reference topic.)*

---

---

# Linux Security: sudo, SELinux, and AppArmor

**Interview Weight:** High - Linux security controls appear in every
backend and DevOps interview; sudo misconfiguration is a top OWASP
privilege escalation vector; SELinux/AppArmor explain the "permission
denied" errors that confuse engineers on security-hardened systems.

---

### 🎯 Model Answer

**30-second answer:**

"Linux security has three layers: Discretionary Access Control (DAC) -
standard Unix permissions and ACLs; sudo - controlled privilege elevation
with logging; and Mandatory Access Control (MAC) - SELinux or AppArmor
enforcing security policies beyond what file permissions allow. SELinux
uses labels (contexts) on every file, process, and socket; AppArmor
uses file path-based profiles. Both operate in permissive (log only)
or enforcing (block and log) mode. When a service mysteriously fails
on RHEL: check SELinux with `ausearch -m avc` or `audit2why`."

**3-minute answer:**

"sudo provides controlled privilege elevation: the sudoers file defines
exactly which commands a user can run as root, with logging of every
sudo invocation. The security principles are: principle of least
privilege (grant only needed commands), command logging (every sudo
is audited), and no-password elevation only for genuinely automated
commands.

SELinux (Security-Enhanced Linux) is MAC enforced by the kernel: every
process runs with a security label (type), every file has a label, and
the policy defines which types can access which other types. A web
server process labeled `httpd_t` can access files labeled `httpd_sys_content_t`
but not files labeled `shadow_t` (password hashes) even if Unix
permissions allow it. This provides defense-in-depth.

AppArmor is an alternative MAC: path-based (not label-based), simpler
to configure but less granular. Ubuntu uses AppArmor; RHEL/CentOS use
SELinux.

The key diagnostic commands: `getenforce` (SELinux mode), `ausearch
-m avc` (SELinux denials), `aa-status` (AppArmor profiles). When a
service fails on a SELinux system: 99% of the time `ausearch -m avc
-ts recent` shows the denial that explains the failure."

**Blank Mind Recovery:**

"sudo: /etc/sudoers, NOPASSWD, logs to /var/log/secure. SELinux:
enforcing/permissive, contexts, ausearch -m avc, audit2allow. AppArmor:
aa-status, aa-complain for debug mode. getenforce to check mode."

---

### 📘 Concept Explanation

**What it is:**

Three complementary Linux security mechanisms: sudo (controlled
privilege delegation), SELinux (kernel-enforced mandatory access
control using type enforcement labels), and AppArmor (kernel-enforced
mandatory access control using path-based profiles). Together they
implement defense-in-depth beyond standard Unix file permissions.

**Why it exists:**

Unix permissions (DAC) are powerful but insufficient: a vulnerability
in nginx can use nginx's UID to read any file nginx is allowed to read,
including sensitive application data. SELinux and AppArmor limit what
a compromised service can do even if it is running as the correct user.
sudo prevents the "run everything as root" anti-pattern while enabling
necessary administrative operations.

**Core mental model:**

```
Linux Security Decision Tree (for any access attempt):

[Process tries to access resource]
         |
         v
[DAC check: Does UID/GID have permission?]
  DENY -> Access denied
  ALLOW -> Continue to MAC check
         |
         v
[MAC check (SELinux/AppArmor): Does security policy allow it?]
  DENY -> AVC denied + audited
  ALLOW -> Access granted
```

> **Diagram walkthrough:** Linux enforces security in layers: the
> DAC check (traditional Unix permissions) happens first; if denied,
> the operation fails without reaching MAC. If DAC allows it, MAC
> applies a second check based on labels or paths. KEY RELATIONSHIP:
> SELinux/AppArmor can only RESTRICT beyond what DAC allows - they
> cannot grant access that DAC denies. The EDGE CASE: some system
> calls bypass DAC for root (UID 0), but SELinux still applies to
> root processes via type enforcement. INSIGHT: a service failing
> with "permission denied" may be blocked by DAC (check file perms)
> OR by SELinux (check ausearch -m avc) - always check both.

**Key terminology:**

- **SELinux context**: `user:role:type:level` label on files and
  processes; the type component is the primary enforcement domain
- **AVC denial**: Access Vector Cache denial - the audit log entry
  created when SELinux blocks an operation
- **Enforcing mode**: SELinux/AppArmor blocks AND logs violations
- **Permissive mode**: logs violations but does NOT block; used for
  policy development and debugging
- **audit2allow**: converts AVC denials to allow rules (use with caution)
- **sudoers**: `/etc/sudoers` file (edit with `visudo` ONLY) defining
  privilege delegation rules

**How it works internally:**

SELinux intercepts system calls via Linux Security Modules (LSM) hooks.
Before any syscall completes, the LSM hook invokes the SELinux policy
engine, which checks the source type (process label) against the target
type (file/socket/process label) for the specific operation (read/write/
execute/connect). The AVC cache speeds this by caching recent allow/
deny decisions; cache misses require a full policy database lookup.

**Trade-offs:**

| Security layer | Strength | Operational cost |
|----------------|---------|-----------------|
| Unix permissions | Universal, simple | Coarse-grained, root bypass |
| sudo | Audited delegation | Requires sudoers maintenance |
| SELinux | Kernel-enforced, comprehensive | Complex policies, troublesome |
| AppArmor | Simpler than SELinux | Path-based, less granular |

---

### 💻 Code Example

**BAD: Insecure sudo configuration**

```bash
# BAD: /etc/sudoers entries that are security vulnerabilities
# NEVER do these:

# 1. Blanket NOPASSWD sudo (any command as root)
deploy   ALL=(ALL) NOPASSWD: ALL

# 2. Unrestricted shell via sudo (escalation via vim, less, etc.)
user1    ALL=(ALL) NOPASSWD: /usr/bin/vim

# 3. Writable script with sudo privilege
user2    ALL=(ALL) NOPASSWD: /opt/scripts/update.sh
# If user2 can WRITE /opt/scripts/update.sh, they have root access
```

> **Code walkthrough:** These three patterns are classic privilege
> escalation vectors. KEY MECHANISM: `NOPASSWD: ALL` gives unrestricted
> root; `NOPASSWD: /usr/bin/vim` allows `sudo vim` which has a shell
> escape (`:!bash`); `NOPASSWD: /opt/scripts/update.sh` on a writable
> script allows writing arbitrary commands to the script then executing
> them as root. WHY IT MATTERS: these patterns are in OWASP's
> privilege escalation category; a compromised user account with any
> of these sudoers entries gives full root. WHAT BREAKS: operators
> add NOPASSWD:ALL for convenience and forget it is equivalent to
> giving the account root password. TAKEAWAY: every sudo NOPASSWD
> entry is a potential privilege escalation path; audit `sudo -l -U
> username` for every non-root user with sudo access.

**GOOD: Principle of least privilege sudo configuration**

```bash
# /etc/sudoers.d/deploy-user
# Allow deploy user to restart specific services only
deploy  ALL=(ALL) NOPASSWD: /bin/systemctl restart myapp.service,\
                              /bin/systemctl start myapp.service,\
                              /bin/systemctl stop myapp.service,\
                              /bin/systemctl status myapp.service

# Allow database user to run pg_dump (backup) only
dbbackup ALL=(postgres) NOPASSWD: /usr/bin/pg_dump

# Allow log reader to read audit logs only
logread ALL=(root) NOPASSWD: /bin/journalctl -u myapp *
```

> **Code walkthrough:** Each sudo rule restricts to the exact commands
> needed. KEY MECHANISM: `(ALL)` means the command runs as root;
> `(postgres)` means it runs as the postgres user specifically - more
> restrictive. `NOPASSWD` entries should be limited to automated
> deployment and monitoring use cases. WHY IT MATTERS: if the `deploy`
> user account is compromised, the attacker can only restart myapp -
> not access other files or services. WHAT BREAKS: using wildcards
> like `/bin/systemctl * myapp.service` can allow `systemctl edit
> myapp.service` which could modify the unit file and introduce a
> malicious ExecStart. TAKEAWAY: explicitly list allowed arguments
> in sudoers entries; wildcards create unintended escalation paths.

**SELinux diagnosis workflow**

```bash
# Check current SELinux mode
getenforce
# Enforcing  <- actively blocking violations
# Permissive <- logging but not blocking
# Disabled   <- not running (requires reboot to change)

# Check AVC (Access Vector Cache) denials
ausearch -m avc -ts recent
# type=AVC msg=audit(1705299735.123:456): avc: denied { read }
#   for pid=12345 comm="java" name="secrets.conf"
#   scontext=system_u:system_r:java_t:s0
#   tcontext=system_u:object_r:etc_t:s0
#   tclass=file permissive=0

# Get human-readable explanation
audit2why < /var/log/audit/audit.log | grep -A 5 "java"
# Was caused by:
#   Missing type enforcement (TE) allow rule.
#   Allow rule: allow java_t etc_t:file { read };

# See what context a file has
ls -Z /etc/secrets.conf
# system_u:object_r:etc_t:s0 /etc/secrets.conf

# Change file context (correct way to fix SELinux for a custom file)
semanage fcontext -a -t java_content_t "/opt/myapp/conf(/.*)?"
restorecon -Rv /opt/myapp/conf/
```

> **Code walkthrough:** `semanage fcontext` + `restorecon` is the
> CORRECT fix for SELinux denials, not `audit2allow`. KEY MECHANISM:
> `semanage fcontext` adds a persistent context mapping for a path
> pattern to the policy database; `restorecon -Rv` applies the stored
> context to existing files. WHY IT MATTERS: directly running
> `chcon -t` changes the context on files but does NOT persist - the
> context reverts on the next `restorecon` or `autorelabel`. WHAT
> BREAKS: `audit2allow` generates broad allow rules that may
> weaken the security policy; prefer moving files to the correct
> location or relabeling with the correct context. TAKEAWAY: when
> SELinux denies access to a custom application file, use `semanage
> fcontext` to declare the correct type for the path, then `restorecon`
> to apply it - this is the correct, persistent solution.

**AppArmor profile management (Ubuntu)**

```bash
# Check AppArmor status
aa-status
# apparmor module is loaded.
# 29 profiles are loaded.
# 17 profiles are in enforce mode.

# Check if a service has a profile
aa-status | grep nginx
# /usr/sbin/nginx2 (enforce)

# Switch profile to complain mode (permissive equivalent)
aa-complain /usr/sbin/nginx
# Setting /usr/sbin/nginx to complain mode.

# View AppArmor denials
journalctl | grep "apparmor.*DENIED"
# kernel: audit: type=1400 audit(123.456:789): apparmor="DENIED"
#   operation="open" profile="/usr/sbin/nginx" name="/etc/secrets"
#   pid=12345 comm="nginx"

# Re-enable enforce mode after debugging
aa-enforce /usr/sbin/nginx
```

> **Code walkthrough:** `aa-complain` switches a profile from enforce
> to complain mode, equivalent to SELinux permissive mode - denials
> are logged but not blocked. KEY MECHANISM: AppArmor profiles define
> allowed file paths, capabilities, and network operations; switching
> to complain mode reveals all the access attempts that would be
> blocked in enforce mode. WHY IT MATTERS: this is the correct
> debugging approach when nginx fails after AppArmor changes - put
> in complain mode, test the failing operation, read the denial log,
> update the profile, return to enforce. WHAT BREAKS: leaving a
> profile in complain mode permanently defeats the security benefit;
> set a reminder to re-enable enforce mode after debugging.
> TAKEAWAY: `aa-complain` then test then `aa-enforce` is the correct
> AppArmor debugging cycle, equivalent to SELinux `setenforce 0`
> then `setenforce 1`.

---

### 🎓 Answers by Seniority

**Junior / Mid-level answer:**

"sudo lets users run commands as root. SELinux is a security system
on RHEL that can block services. To check: `getenforce`. If a service
is blocked by SELinux I set it to permissive mode temporarily. AppArmor
is similar but on Ubuntu."

*What's missing: no mention of AVC denial diagnosis, correct fix
procedure (semanage fcontext not setenforce 0), sudoers principle of
least privilege, or MAC vs DAC.*

**Senior / Staff answer:**

"Linux security is layered: DAC (Unix permissions) is necessary but
insufficient; SELinux/AppArmor provide MAC that limits what even
authorized processes can do. When a service fails mysteriously on a
RHEL system, `ausearch -m avc -ts recent` and `audit2why` identify
the SELinux denial within seconds. The fix is NEVER `setenforce 0`
in production - it is `semanage fcontext` to relabel files with the
correct type plus `restorecon -Rv`.

For sudo: audit sudoers entries quarterly. `sudo -l -U username` shows
what each user can do. NOPASSWD should only be granted for specific
commands needed for automation, never for shells, editors, or `ALL`.
Wildcard arguments in sudoers rules create unintended escalation paths.

SELinux vs AppArmor: SELinux is label-based (survives file moves,
more granular), required for RHEL/FIPS compliance. AppArmor is path-based
(simpler to write, easier to misuse with wildcards). Both are valid;
choose based on distribution and team expertise."

---

### ⚠️ Common Misconceptions

**"Setting setenforce 0 is an acceptable production fix for SELinux"**

`setenforce 0` puts SELinux in permissive mode globally, disabling
enforcement for ALL processes. It is appropriate for debugging only.
The correct fix is relabeling files (`semanage fcontext` + `restorecon`)
or updating the policy. Running `setenforce 0` in production removes
a kernel-level defense layer and makes the system non-compliant with
most security standards. Many "why is my service broken" posts resolve
with `setenforce 0` - this is a workaround, not a fix.

**"sudo logs are in /var/log/sudo.log"**

sudo logs are written to `auth.log` (Debian/Ubuntu) or `/var/log/
secure` (RHEL/CentOS) via syslog, not to a dedicated sudo log file
(by default). To search for sudo usage: `grep sudo /var/log/secure`
or `journalctl | grep sudo`. A dedicated sudo log requires configuring
`Defaults logfile=/var/log/sudo.log` in sudoers.

**"AppArmor profiles apply to files, not processes"**

AppArmor profiles are attached to EXECUTABLES and restrict what those
executables can do. The profile path in `aa-status` is the executable
path, not a file being protected. The profile says "when `/usr/sbin/
nginx` is running, it can only access these file paths and use these
capabilities." Confusion arises because profiles reference both the
executable AND the files it is allowed to access.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Service fails on RHEL/CentOS with "permission denied" despite correct Unix permissions**

```bash
# Symptom: nginx cannot read /opt/myapp/html despite correct ownership
# nginx error: (13: Permission denied) while reading...

# Step 1: Confirm it is SELinux, not permissions
ls -la /opt/myapp/html/
# drwxr-xr-x 2 nginx nginx 4096 ... <- correct ownership

getenforce
# Enforcing  <- SELinux is active

# Step 2: Find the AVC denial
ausearch -m avc -ts recent | grep nginx
# avc: denied { read } for pid=12345 comm="nginx" name="html"
#   scontext=system_u:system_r:httpd_t:s0
#   tcontext=unconfined_u:object_r:default_t:s0

# Step 3: Understand the denial
echo "avc: denied..." | audit2why
# Was caused by: Missing type enforcement allow rule.
# If you want to allow httpd_t to read default_t files:
#   semanage fcontext -a -t httpd_sys_content_t '/opt/myapp/html(/.*)?"
#   restorecon -Rv /opt/myapp/html/

# Step 4: Apply correct fix (NOT setenforce 0)
semanage fcontext -a -t httpd_sys_content_t '/opt/myapp/html(/.*)?'
restorecon -Rv /opt/myapp/html/
ls -Z /opt/myapp/html/
# system_u:object_r:httpd_sys_content_t:s0  <- correct type now
```

> **Code walkthrough:** `semanage fcontext` adds a persistent rule
> to the SELinux policy database; `restorecon -Rv` applies the new
> label to existing files matching the path pattern. KEY MECHANISM:
> the `/opt/myapp/html(/.*)?` pattern is a regex that matches the
> directory and all files within it recursively. WHY IT MATTERS:
> without this permanent fix, the context would be lost on `autorelabel`
> (which runs after a `touch /.autorelabel` reboot) or after an OS
> upgrade. WHAT BREAKS: using `chcon -R -t httpd_sys_content_t` alone
> changes the context but does not persist the mapping; the next
> autorelabel reverts it. TAKEAWAY: `semanage fcontext` + `restorecon`
> is the ONLY persistent way to relabel a custom path in SELinux.

**Failure 2: sudo command injection via unrestricted arguments**

```bash
# VULNERABLE sudoers rule:
deploy ALL=(root) NOPASSWD: /opt/scripts/*.sh
# An attacker who controls the deploy account can:
cp /bin/bash /opt/scripts/evil.sh
sudo /opt/scripts/evil.sh
# Now has a root shell

# SAFER approach: specific scripts with fixed paths, no wildcards
deploy ALL=(root) NOPASSWD: /opt/scripts/deploy.sh ""
# "" means: only allow deploy.sh with NO arguments
# Prevents: sudo /opt/scripts/deploy.sh; bash  (argument injection)
```

> **Code walkthrough:** Wildcards in sudoers paths match any file
> in the directory. KEY MECHANISM: `*.sh` in the path matches any
> `.sh` file including newly created ones; the deploy user can write
> any `.sh` file to `/opt/scripts/` and run it as root. WHY IT
> MATTERS: this is a documented privilege escalation pattern in
> penetration testing; even without writing new files, if any
> existing script in the wildcard path has a shell injection
> vulnerability, it becomes a root escalation. WHAT BREAKS: the
> `""` argument restriction only works in newer versions of sudo;
> verify with the sudo man page for your version. TAKEAWAY: never
> use wildcards in sudoers path components; use exact paths to
> specific, audited scripts.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | MAC vs DAC, SELinux contexts |
| Debugging | 3 | AVC denials, AppArmor, sudo audit |
| Security | 2 | sudoers hardening, privilege escalation |

---

**[JUNIOR] Q1 - What is the difference between Mandatory Access Control and Discretionary Access Control in Linux?**

DAC (Discretionary Access Control) is traditional Unix permissions: the
file OWNER decides who can access it. The owner can `chmod 777` a file
to allow anyone to read it. Access decisions are at the discretion of
the file owner.

MAC (Mandatory Access Control) is enforced by the kernel independent
of owner decisions: the security POLICY decides who can access what,
and even the root user is subject to the policy. A process running as
root with SELinux cannot read files it is not authorized to access by
the SELinux type enforcement policy.

Practical differences:
- DAC: nginx owns `/var/www/html` → can read/write anything in it
- MAC (SELinux): nginx process has type `httpd_t` → can only access
  files with type `httpd_sys_content_t`, nothing else, even if Unix
  permissions allow it

This means if nginx is compromised:
- DAC only: attacker can read all files nginx user can read (including
  application configs, database passwords if same user)
- MAC + DAC: attacker is confined to `httpd_t` domain; cannot read
  files outside that SELinux type even if they have nginx's UID

*What separates good from great:* knowing that root is not exempt from
SELinux type enforcement - a process running as root with type `httpd_t`
STILL cannot access files with type `shadow_t`, which is the core
security property that makes SELinux effective for containing breaches.

---

**[MID] Q2 - How do you diagnose and fix a SELinux AVC denial without disabling SELinux?**

The correct workflow: deny → diagnose → relabel or allow → verify.

```bash
# 1. Confirm SELinux is causing the issue (not Unix permissions)
ausearch -m avc -ts recent 2>/dev/null | tail -20
# If AVC entries match your service and timeframe: SELinux is the cause

# 2. Understand the denial context
ausearch -m avc | audit2why
# "Missing type enforcement allow rule."
# Suggested fix: semanage fcontext -a -t TYPE '/path/(.*)?'

# 3. Check what type the path SHOULD have
matchpathcon /opt/myapp/conf/
# /opt/myapp/conf  system_u:object_r:default_t:s0
# "default_t" means SELinux does not know about this custom path

# 4. Find the correct type for the expected access
semanage fcontext -l | grep "httpd\|app_config"
# Shows standard types for web content, config files, etc.

# 5. Apply the correct type
semanage fcontext -a -t httpd_sys_content_t '/opt/myapp/conf(/.*)?'
restorecon -Rv /opt/myapp/conf/

# 6. Verify (service should now work)
ls -Z /opt/myapp/conf/
systemctl restart nginx
```

> **Code walkthrough:** `matchpathcon` queries the policy database
> for what context SHOULD be applied to a path; `default_t` means
> no rule matches this custom path. KEY MECHANISM: SELinux contexts
> are determined by path patterns in the policy database; files in
> `/opt/myapp/` are `default_t` because no distribution policy covers
> custom application directories. WHY IT MATTERS: understanding that
> `default_t` means "not categorized yet" (not a security feature)
> guides you directly to the fix: add a fcontext rule. WHAT BREAKS:
> using `chcon` without `semanage fcontext` fixes the immediate
> problem but the context reverts after `restorecon` or relabeling
> operations. TAKEAWAY: `matchpathcon` + `semanage fcontext` +
> `restorecon` is the complete, persistent fix for SELinux custom
> path issues.

*What separates good from great:* using `audit2why` to get
human-readable explanations and suggested fix commands from the raw
AVC log entries - it translates cryptic type enforcement log entries
into actionable steps, making SELinux diagnosis accessible without
memorizing policy type names.

---

**[SENIOR] Q3 - How do you audit and harden sudoers configuration for a production system?**

Sudoers hardening involves three activities: auditing what exists,
removing unnecessary grants, and adding logging.

```bash
# 1. Audit all sudo grants
grep -r "NOPASSWD\|ALL=(ALL)" /etc/sudoers /etc/sudoers.d/
# Lists all permissive sudo grants

# 2. Check what a specific user can run
sudo -l -U deploy
# User deploy may run the following:
#   (ALL) NOPASSWD: /bin/systemctl restart myapp.service

# 3. Check sudo logs for recent usage
journalctl | grep sudo | grep -v "pam_unix"
# Or on RHEL: grep sudo /var/log/secure

# 4. Enable enhanced sudo logging
cat >> /etc/sudoers << 'EOF'
Defaults logfile=/var/log/sudo.log
Defaults log_input, log_output        # full session recording
Defaults iolog_dir=/var/log/sudo-io/  # session I/O logging
EOF
```

> **Code walkthrough:** `Defaults log_input, log_output` records every
> keystroke and output of every sudo session to `iolog_dir`. KEY
> MECHANISM: sudo records the full terminal session as a
> typescript-format file that can be replayed with `sudoreplay`.
> WHY IT MATTERS: this provides forensic evidence of what a user
> did with elevated privileges, which is required for many compliance
> frameworks. WHAT BREAKS: `log_output` requires the `sudoreplay`
> utility for reading recordings; the raw I/O log files are not
> human-readable. TAKEAWAY: enable `log_output` in sudoers for any
> production system where privileged access needs auditing; the
> sessions are replayable with `sudoreplay /var/log/sudo-io/`.

Hardening checklist:
- Remove `ALL=(ALL) NOPASSWD: ALL` (complete root access)
- Replace wildcard paths with explicit commands
- Add `requiretty` (prevents sudo via non-interactive scripts without
  a terminal, reducing automated attack surface)
- Review EVERY NOPASSWD entry for privilege escalation via shell escapes
  (`vim`, `less`, `more`, `python`, `awk`, `find` all have shell escapes)

*What separates good from great:* knowing that many common UNIX tools
have shell escapes (`:!bash` in vim, `!bash` in less, `-exec bash` in
find) that convert a "limited" sudo grant into full root - GTFOBins
(gtfobins.github.io) documents these for all common tools.

---

**[SENIOR] Q4 - What is the SELinux boolean system and when would you use booleans vs custom policy?**

SELinux booleans are pre-defined policy toggles that enable/disable
common optional behaviors without writing custom policy.

```bash
# List all booleans related to httpd
getsebool -a | grep httpd
# httpd_can_connect_ftp --> off
# httpd_can_network_connect --> off
# httpd_can_network_connect_db --> off
# httpd_can_sendmail --> off
# httpd_enable_cgi --> on

# Example: Allow nginx to make network connections (needed for proxying)
setsebool -P httpd_can_network_connect on
# -P: persistent (survives reboot)

# Allow web server to connect to databases
setsebool -P httpd_can_network_connect_db on
```

> **Code walkthrough:** `httpd_can_network_connect` is a boolean that
> enables/disables network connections for the `httpd_t` type. KEY
> MECHANISM: booleans modify conditional rules already in the base
> policy; enabling a boolean activates allow rules that are compiled
> into the policy but disabled by default. WHY IT MATTERS: without
> `httpd_can_network_connect=on`, nginx acting as a reverse proxy
> will be blocked from connecting to backend services, causing
> cryptic "connection refused" errors that look like network issues
> but are SELinux. WHAT BREAKS: `setsebool` without `-P` is not
> persistent; the boolean reverts to default on reboot. TAKEAWAY:
> always use `setsebool -P` for production boolean changes and
> document which booleans were changed and why.

Booleans vs custom policy:
- Use booleans first: many common use cases are covered by existing
  booleans; they are the intended way to configure SELinux for
  standard applications
- Use custom policy when: the application has unique access patterns
  not covered by existing booleans; use `audit2allow` with extreme
  caution to generate rules, then review them carefully before applying

*What separates good from great:* knowing that `getsebool -a | grep
servicename` is the first step when a service is blocked by SELinux
after a boolean check - many "write a custom policy" situations are
actually solvable with the correct boolean, which is safer and
maintained by the distribution.

---

**[SENIOR] Q5 - How do you use AppArmor to confine a custom application on Ubuntu?**

AppArmor profiles are written in a profile language defining allowed
file paths, capabilities, and network access.

```bash
# Check if AppArmor is active
aa-status | head -5

# Install AppArmor utilities
apt install apparmor-utils

# Generate a base profile for an application (interactive learning mode)
aa-genprof /opt/myapp/bin/server
# Run your application while aa-genprof captures access patterns
# It generates a profile from observed behavior
# Review and confirm each allow rule

# View the generated profile
cat /etc/apparmor.d/opt.myapp.bin.server

# Example profile snippet
# /etc/apparmor.d/opt.myapp.bin.server
#
# /opt/myapp/bin/server {
#   include <abstractions/base>
#   /opt/myapp/conf/** r,          <- read config files
#   /var/lib/myapp/** rw,          <- read/write data files
#   /var/log/myapp/** w,           <- write log files
#   capability net_bind_service,   <- bind ports < 1024
#   network tcp,                   <- TCP connections
# }

# Load the profile in enforce mode
apparmor_parser -r /etc/apparmor.d/opt.myapp.bin.server
```

> **Code walkthrough:** `aa-genprof` starts the application in
> "learning" mode and interactively asks whether each file access
> should be allowed, building a minimal profile. KEY MECHANISM:
> AppArmor profiles use glob patterns to define file paths; `/**`
> matches all files recursively; `r` is read, `rw` is read-write,
> `m` is mmap (needed for shared libraries). WHY IT MATTERS: an
> AppArmor profile generated from observed behavior is minimally
> permissive - it only allows what the application actually does,
> not what it could potentially do. WHAT BREAKS: missing `m` (mmap)
> permission on shared library paths causes SIGBUS when the dynamic
> linker tries to memory-map the library; this is a common
> AppArmor gotcha for new profiles. TAKEAWAY: always test AppArmor
> profiles in complain mode first (`aa-complain`) before switching
> to enforce; check `journalctl | grep apparmor` for any denials
> during testing.

*What separates good from great:* knowing that `aa-genprof` generates
profiles from actual application behavior, producing minimally
permissive profiles that allow exactly what was observed - this is
far more accurate and secure than manually writing a profile, and
much less error-prone than using `audit2allow` for SELinux.

---

**[MID] Q6 - What are the most dangerous sudoers misconfigurations and how do you audit for them?**

Sudoers misconfigurations are a top privilege escalation vector.
The most dangerous patterns:

1. `ALL=(ALL) NOPASSWD: ALL` - complete root access with no password
2. `NOPASSWD: /usr/bin/vim` - shell escape via `:!bash`
3. `NOPASSWD: /usr/bin/find` - arbitrary command via `-exec bash`
4. `NOPASSWD: /usr/bin/python3` - `import os; os.system('bash')`
5. `NOPASSWD: /opt/scripts/*.sh` - wildcard matches attacker-written scripts

```bash
# Audit all users with sudo access
getent group sudo wheel | cut -d: -f4 | tr , '\n'

# Show each user's exact sudo privileges
for user in $(getent group sudo | cut -d: -f4 | tr , ' '); do
  echo "=== $user ==="
  sudo -l -U $user 2>/dev/null
done

# Search for dangerous sudo grants
grep -r 'NOPASSWD.*ALL\|NOPASSWD.*/usr/bin/vim\
  \|NOPASSWD.*/usr/bin/python\|NOPASSWD.*\*' \
  /etc/sudoers /etc/sudoers.d/ 2>/dev/null
```

> **Code walkthrough:** `sudo -l -U username` lists all sudo grants
> for a specific user, showing which commands they can run and as
> which user. KEY MECHANISM: this reads the sudoers file and all
> files in `/etc/sudoers.d/` and resolves aliases and group
> memberships for the specified user. WHY IT MATTERS: a user may
> not know they have a dangerous sudo grant added by configuration
> management months ago; regular audits with `sudo -l -U` for
> all sudo-capable users reveal accumulated privilege grants.
> WHAT BREAKS: `sudo -l` without `-U username` shows only the
> current user's grants; you need `-U` to audit other users.
> TAKEAWAY: run quarterly sudo audits comparing current grants to
> approved grants in your configuration management system;
> unexplained grants should be removed immediately.

*What separates good from great:* knowing GTFOBins (gtfobins.github.io)
catalogues shell escape techniques for 150+ Unix tools - any of
these tools granted via NOPASSWD sudo becomes a root escalation
vector; security reviews should cross-reference every NOPASSWD grant
against the GTFOBins database.

---

**[JUNIOR] Q7 - How do you verify that SELinux or AppArmor is configured correctly for a service after deployment?**

Post-deployment verification ensures MAC is enforcing correctly
without blocking legitimate service operations.

```bash
# For SELinux (RHEL/CentOS)
# Step 1: Put in permissive mode, run service under load
setenforce 0   # permissive - logs but does not block
systemctl restart myapp
# Generate traffic / run functional tests

# Step 2: Check for any denials (would have been blocks in enforcing)
ausearch -m avc -ts recent
# If no AVC entries: ready for enforcing mode
# If AVC entries exist: fix them with semanage fcontext

# Step 3: Return to enforcing
setenforce 1
systemctl restart myapp
# Run functional tests again - should work without AVC denials

# For AppArmor (Ubuntu)
aa-complain /usr/sbin/myapp  # log but do not block
systemctl restart myapp
# Generate traffic
journalctl | grep 'apparmor.*DENIED'
# Fix any denials in the profile, then:
aa-enforce /usr/sbin/myapp
```

> **Code walkthrough:** `setenforce 0` then test then `setenforce 1`
> is the MAC verification cycle for SELinux. KEY MECHANISM: in
> permissive mode, AVC denials are logged exactly as they would be
> in enforcing mode but the access is allowed; this lets you
> discover ALL potential blocks before switching to enforcement.
> WHY IT MATTERS: switching directly to enforcing without testing
> may break the service if SELinux blocks a legitimate access;
> the permissive test phase reveals these issues safely. WHAT
> BREAKS: `setenforce 0` is global and affects ALL processes, not
> just the service under test; in production, use per-process
> permissive with `semanage permissive -a httpd_t` instead. TAKEAWAY:
> always test in permissive mode first, fix all AVC denials, then
> switch to enforcing and run a final functional test to confirm.

*What separates good from great:* using `semanage permissive -a
httpd_t` to put only the SERVICE'S type into permissive mode rather
than `setenforce 0` which puts the ENTIRE SYSTEM into permissive;
this tests the service in isolation without weakening SELinux for
every other running process.

---

### ⚖️ Comparison Table

| Aspect | SELinux | AppArmor | Neither |
|--------|---------|----------|---------|
| Access model | Label-based (survives moves) | Path-based (path must match) | DAC only |
| Default distro | RHEL, Fedora, CentOS | Ubuntu, Debian, SUSE | Some minimal images |
| Profile difficulty | Complex (types, contexts) | Simpler (file paths) | N/A |
| Granularity | Very high (type domains) | Medium (path patterns) | Low (UID/GID) |
| Root confinement | Yes (type enforcement) | Partial (capability model) | No |
| Profile tools | audit2allow, semanage | aa-genprof, aa-complain | N/A |
| Compliance | FIPS, DOD STIG required | Common PCI-DSS choice | Non-compliant |

---

### 🏛️ System Design

*(Omit: ★★☆ Linux security operational keyword - fleet-scale security
policy management and zero-trust architecture are covered in the
security and cloud infrastructure topics.)*

---

### 📊 Diagram

*(Omit: the access control decision tree is shown in the ASCII diagram
in the Concept Explanation section; an additional diagram would be
redundant for this security reference topic.)*
