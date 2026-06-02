---
layout: default
title: "Linux - L1 File System and Commands"
parent: "Linux"
nav_order: 2
permalink: /linux/l1-file-system-commands/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Difficulty |
|---|---------|------------|
| 4 | [File System Hierarchy Standard](#file-system-hierarchy-standard) | ★☆☆ |
| 5 | [Essential Commands: find, grep, awk, and sed](#essential-commands-find-grep-awk-and-sed) | ★☆☆ |
| 6 | [File Permissions and Ownership: chmod and chown](#file-permissions-and-ownership-chmod-and-chown) | ★☆☆ |

---

# File System Hierarchy Standard

**Interview Weight:** Moderate - asked during operations screening;
tests whether candidate can navigate production Linux systems without
guidance; expected at mid-level and above.

---

### 🎯 Model Answer

**30-second answer:**

"The Filesystem Hierarchy Standard (FHS) defines where specific files
belong on Linux: /etc for configuration, /var for variable data like
logs, /usr for user-installed programs, /tmp for temporary files, /home
for user directories. Knowing the standard means finding any config
file, log, or binary on any Linux system without searching."

**3-minute answer:**

"The FHS is a specification maintained by the Linux Foundation that
defines the directory structure and content of Linux systems. The key
directories every backend engineer should know by heart:

`/etc` - System-wide configuration files. If a service has config, it
lives here (`/etc/nginx/`, `/etc/postgresql/`, `/etc/systemd/`).

`/var` - Variable data that changes at runtime: logs (`/var/log/`),
spool files, databases, PID files (`/var/run/`). On production servers,
`/var/log` is often on a separate partition to prevent log growth from
filling the root filesystem.

`/usr` - User-space programs. Binaries in `/usr/bin` (standard
commands), `/usr/local/bin` (locally compiled/installed), libraries
in `/usr/lib`.

`/opt` - Optional third-party software that doesn't follow standard
packaging (Oracle JDK, custom deployments, vendor software).

`/tmp` - Temporary files, cleared at reboot. `/var/tmp` is
similar but persists across reboots.

`/proc` and `/sys` - Virtual filesystems, not on disk (covered
separately in the philosophy section).

The practical value: on any unfamiliar Linux server, you know where to
find service configs (/etc), logs (/var/log), running process IDs
(/var/run), and installed binaries (/usr/bin or /usr/local/bin) without
asking anyone."

**Blank Mind Recovery:**

"/etc = config, /var = variable data (logs, pid files), /usr = programs,
/home = user dirs, /tmp = temp (cleared on reboot), /proc = kernel
state, /sys = hardware state."

---

### 📘 Concept Explanation

**What it is:**

The Filesystem Hierarchy Standard is a specification defining the
directory tree structure of Unix and Linux operating systems. It
defines what each top-level directory contains so that software can
be installed, users can find files, and system administrators can
predict where things are.

**The problem it solves:**

Without a standard, each Linux distribution would organize files
differently. Package managers, monitoring agents, backup systems, and
automation tools would all need distribution-specific logic. FHS gives
all of them a common map.

**How it works:**

Key directory purposes:

| Directory | Contents | Examples |
|---|---|---|
| `/etc` | System config | `/etc/nginx/`, `/etc/hosts`, `/etc/sysctl.conf` |
| `/var/log` | System logs | `/var/log/syslog`, `/var/log/auth.log`, `/var/log/nginx/` |
| `/var/run` | Runtime files | `/var/run/nginx.pid`, `/var/run/docker.sock` |
| `/var/lib` | Application state | `/var/lib/postgresql/`, `/var/lib/docker/` |
| `/usr/bin` | User binaries | `/usr/bin/python3`, `/usr/bin/java` |
| `/usr/local/bin` | Local binaries | Locally compiled or installed tools |
| `/opt` | Optional packages | `/opt/oracle/`, `/opt/myapp/` |
| `/tmp` | Temporary (cleared at reboot) | Scratch space |
| `/var/tmp` | Temporary (persists) | Long-lived temp files |
| `/home` | User home dirs | `/home/ubuntu`, `/home/appuser` |
| `/root` | Root user home | Separate from /home |

**The key insight:**

The distinction between `/usr` (static, shared programs) and `/var`
(variable, changing data) is the most important for production: putting
application data in `/usr` breaks with immutable OS patterns;
putting logs or database files in `/tmp` risks losing them on reboot.

**When to use /opt vs /usr/local:**

`/opt` is for self-contained third-party packages that install into
a single directory tree (Oracle JDK at `/opt/java/`). `/usr/local` is
for tools installed following the standard hierarchy convention
(`/usr/local/bin`, `/usr/local/lib`).

**When NOT to put application data in /tmp:**

`/tmp` is cleared on reboot by `systemd-tmpfiles-clean`. Applications
that use `/tmp` for session state, upload staging, or database working
files lose that data on reboot - a critical production bug.

**Alternatives:**

None - FHS is the Linux standard. BSD systems use a similar but not
identical hierarchy (e.g., `/usr/local` has different conventions).

**First-principles derivation:**

"Given a filesystem that multiple programs, users, and daemons share,
the organizing principle is: separate data by change frequency and
ownership. Static shared data goes under /usr (changes only on package
upgrade). Dynamic per-host data goes under /var (changes at runtime).
User data goes under /home (changes by user actions). Config goes
under /etc (changes by administrator action)."

---

### 💻 Code Example

```bash
# Standard log file locations
tail -f /var/log/syslog           # Debian/Ubuntu system log
tail -f /var/log/messages         # RHEL/CentOS system log
tail -f /var/log/auth.log         # Authentication events
tail -f /var/log/nginx/access.log # Nginx access log

# Find a service's config
ls /etc/nginx/                    # Nginx config
ls /etc/postgresql/               # PostgreSQL config
find /etc -name "*.conf" -newer /etc/hosts 2>/dev/null

# Find where a binary is installed
which java          # /usr/bin/java (usually a symlink)
readlink -f $(which java)
# /usr/lib/jvm/java-21-openjdk-amd64/bin/java  <- actual path

# Runtime state files
cat /var/run/nginx.pid            # Nginx process ID
ls /var/run/                      # All running service PIDs

# Application data directories
du -sh /var/lib/postgresql/       # PostgreSQL database files
du -sh /var/lib/docker/           # Docker images and containers
```

> **Code walkthrough:** `readlink -f $(which java)` follows the full
symlink chain to the actual binary location, revealing the JDK
installation directory. KEY MECHANISM: many distros use update-
alternatives to manage multiple installed JDK versions through a
chain of symlinks in `/usr/bin`; `readlink -f` resolves the final
target. WHY IT MATTERS: package upgrades can change symlink targets;
knowing the real JDK path confirms which version a running service
uses. WHAT BREAKS: hardcoding `/usr/lib/jvm/java-21-...` in scripts
fails when the JDK is upgraded; use `$(which java)` instead.
TAKEAWAY: the combination of `/var/run/service.pid` and `kill -0
$(cat /var/run/service.pid)` is the standard pattern for checking
if a service is running in init scripts.

---

### 🎓 Answers by Seniority

**Junior/Mid:**

"FHS is the standard directory layout for Linux. The main ones are:
/etc for config, /var/log for logs, /var/run for PID files, /usr/bin
for programs, and /tmp for temp files. Knowing this means I can find
service configs and logs on any Linux system without having to search."

**Senior/Staff:**

"FHS is critical for automation reliability. Any Ansible playbook,
Dockerfile, or deployment script that hardcodes non-standard paths
fails on different distributions or configurations. The principle I
follow: put application config in /etc (managed by config management),
application state in /var/lib (backed up and persistent), application
logs in /var/log (or stdout for containers), and runtime files
(PID, sockets) in /var/run (ephemeral). The architecture implication:
in containers, /var/lib should typically be a mounted volume for
anything you need to survive container replacement, and the container
image root should be read-only (immutable containers). This maps
exactly to the FHS intent of separating static from dynamic data."

---

### ⚠️ Common Misconceptions

**Misconception 1: "Application data can go anywhere."**

Placing application data outside FHS-standard locations (e.g., in
`/opt/myapp/data/` instead of `/var/lib/myapp/`) causes: backup
tools miss it, log rotation tools miss it, monitoring agents expect
standard paths. Always map application roles to FHS directories.

**Misconception 2: "/tmp is safe for session data."**

`systemd-tmpfiles-clean.timer` runs periodically and clears files
in `/tmp` older than 10 days by default, and clears everything on
reboot. Applications using `/tmp` for session data, upload staging,
or locks lose them unexpectedly. Use `/var/tmp` for persistence across
reboots (cleared much less frequently).

**Misconception 3: "/usr/local is for user software."**

`/usr/local` is for software installed outside the package manager,
not for user-specific software. It follows the same bin/lib/share
convention as `/usr` but is excluded from package manager management.
User-specific software goes in `~/.local/`.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Root filesystem fills up causing service crashes**

```bash
# Diagnose filesystem usage
df -h
# /dev/sda1        50G   49G  100M   100% /  <- FULL!

# Find the culprit directory
du -sh /* 2>/dev/null | sort -h | tail -10
# 45G  /var  <- most usage here

du -sh /var/* 2>/dev/null | sort -h | tail -5
# 44G  /var/log  <- log directory

# Find the specific large files
find /var/log -type f -size +1G -ls 2>/dev/null
# -rw-r--r-- 1 root root 44G /var/log/myapp/debug.log

# Immediate relief: truncate without losing the file handle
# (don't rm if the service has the file open)
> /var/log/myapp/debug.log   # or: truncate -s 0 file

# Check if a deleted file is still held open (hidden disk usage)
lsof +L1 | grep "deleted\|DEL"
# java  1234  appuser  12u  REG  deleted  35G  /var/log/...
# If found: restart the service to release the deleted file handle
```

> **Code walkthrough:** `lsof +L1` shows files with link count < 1
(deleted files still held open by a process). KEY MECHANISM: when a
file is deleted with `rm`, Linux removes the directory entry but the
disk blocks remain allocated as long as any process has the file open;
`df` shows the disk as full while the file is invisible to `ls`. WHY
IT MATTERS: this is one of the most confusing production scenarios -
"disk full but I can't find the large file." WHAT BREAKS: truncating
the file without checking `lsof` first loses the ability to identify
what was writing it. TAKEAWAY: after `df` shows full disk, always run
`lsof +L1` to check for deleted-but-open file handles before spending
time searching for large files.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | FHS purpose, key directories |
| Debugging | 3 | disk full, missing files, log growth |
| Trade-off | 2 | /tmp vs /var/tmp, /opt vs /usr/local |

---

**[JUNIOR] Q1 - What is the purpose of the FHS and why does it matter for automation?**

The Filesystem Hierarchy Standard creates a predictable directory
layout that allows tools, scripts, and humans to find files without
configuration. Every distribution following FHS puts Nginx configs at
`/etc/nginx/`, system logs at `/var/log/`, and service binaries at
`/usr/bin/` or `/usr/sbin/`.

For automation, predictability eliminates hardcoded paths. An Ansible
role that manages Nginx can use `/etc/nginx/` without knowing whether
it's running on Ubuntu, RHEL, or Debian. A monitoring agent that reads
`/var/log/syslog` (Debian) or `/var/log/messages` (RHEL) can handle
the naming variation, but the location convention (/var/log/) is
universal.

The separation FHS enforces is architecturally significant for
containers and immutable infrastructure: `/usr` and `/etc` contain the
static configuration (part of the image), while `/var` contains runtime
state (should be a volume or ephemeral). A Dockerfile that puts
application state in `/usr` creates a mutable, hard-to-upgrade image.

*What separates good from great:* connecting FHS directories to container
image design (static vs mutable layers) and explaining why `/var/lib`
is the right place for database files that need to persist.

---

**[MID] Q2 - Your disk is showing 100% usage but du cannot find large files. What is happening?**

This is the "deleted file still open" scenario. When a process opens
a file and another process deletes it (or the log rotator renames it),
Linux removes the directory entry but the inode and disk blocks remain
allocated until the file descriptor is closed.

`df` counts allocated disk blocks (includes deleted-but-open files).
`du` walks directory entries (which exclude the deleted file). The
discrepancy can be tens of gigabytes.

Diagnosis and fix:
```bash
# Find deleted files still held open
lsof +L1
# java 1234 appuser 23u REG 8,1 35000000000 (deleted)
# /var/log/myapp.log.1  <- log rotated but process still writing

# Solution 1: restart the process to release the fd
systemctl restart myapp

# Solution 2: if restart is not possible, truncate via /proc
# Find the fd number from lsof output (23u = fd 23)
> /proc/1234/fd/23
# This truncates the file without closing it
```

> **Code walkthrough:** `find` traverses the filesystem checking each entry against criteria. KEY MECHANISM: `-mtime +N` matches files modified more than N days ago; `-exec cmd {} +` batches matched files to one invocation (faster than `\;`). WHY IT MATTERS: `find / -name pattern -delete` is safe for bulk deletion even when glob expansion would exceed ARG_MAX. WHAT BREAKS: `find /` without `-maxdepth` and path scoping traverses virtual filesystems under `/proc`, `/sys` causing errors or hangs. TAKEAWAY: always scope `find` with a target directory and use `-maxdepth` to limit traversal when searching large trees.

This typically happens with logging: the application opens a log file,
logrotate renames or deletes it, and the application keeps writing to
the old file descriptor (which now points to a deleted file). Proper
log rotation either uses `copytruncate` (truncates in place) or sends
`SIGHUP` to the application (which re-opens its log files).

*What separates good from great:* knowing the `/proc/PID/fd/N`
truncation trick to reclaim disk without restarting the service.

---

**[JUNIOR] Q3 - What is the difference between /tmp and /var/tmp?**

Both directories store temporary files, but their lifetime guarantees
differ fundamentally:

`/tmp` - Cleared on reboot. Many distributions (using `systemd-tmpfiles`)
also periodically delete files older than 10 days. Never store anything
that must persist across a reboot here.

`/var/tmp` - Persists across reboots. Files are kept for 30 days by
default (configurable in `/etc/tmpfiles.d/`). Use for files that must
survive a reboot but are not permanently needed.

For backend services:
- Socket files, lock files, and IPC pipes: `/tmp` or `/var/run`
  (depending on whether they need to survive reboot)
- Upload staging areas: `/var/tmp` if uploads can span a maintenance
  reboot window
- Build artifacts and scratch space: `/tmp` (ephemeral)

A critical mistake: applications that use `/tmp` for database working
files (PostgreSQL sort spill, MySQL tmp_dir) can have queries fail
after reboot if they depend on files that were written to `/tmp`
before the reboot. Configure database temp directories to `/var/tmp`
or a dedicated tmpfs mount.

*What separates good from great:* knowing that systemd-tmpfiles
periodically cleans `/tmp` (not just at reboot) and that the retention
period is configurable.

---

**[MID] Q4 - How do you find which process is writing to a specific log file?**

```bash
# Method 1: lsof (lists open files by process)
lsof /var/log/myapp/application.log
# COMMAND   PID     USER  FD   TYPE DEVICE SIZE/OFF NODE NAME
# java     1234  appuser  23w  REG  8,1  45000000  123  /var/log/...

# Method 2: fuser (simpler output)
fuser /var/log/myapp/application.log
# /var/log/myapp/application.log: 1234

# Method 3: via /proc (no extra tools required)
grep -l "application.log" /proc/*/fd 2>/dev/null
# /proc/1234/fd/23 -> /var/log/myapp/application.log

# Find all files a specific process is writing
lsof -p 1234 | grep "REG.*w"
# Lists all regular files opened for writing by PID 1234
```

> **Code walkthrough:** `find` traverses the filesystem checking each entry against criteria. KEY MECHANISM: `-mtime +N` matches files modified more than N days ago; `-exec cmd {} +` batches matched files to one invocation (faster than `\;`). WHY IT MATTERS: `find / -name pattern -delete` is safe for bulk deletion even when glob expansion would exceed ARG_MAX. WHAT BREAKS: `find /` without `-maxdepth` and path scoping traverses virtual filesystems under `/proc`, `/sys` causing errors or hangs. TAKEAWAY: always scope `find` with a target directory and use `-maxdepth` to limit traversal when searching large trees.

`lsof` is the standard tool for this. The `FD` column shows the fd
type: `r` = read, `w` = write, `u` = read+write. The `SIZE/OFF` column
shows current file position (the current write offset, useful for
confirming the process is actively writing).

*What separates good from great:* using `/proc/PID/fd` as a fallback
when `lsof` is not installed, and knowing the fd type column meanings.

---

**[JUNIOR] Q5 - Where should a systemd service's socket and PID files go and why?**

Socket files and PID files are runtime state - they exist only while
the process is running and must be cleaned up on process exit. The
correct location is:

**PID files:** `/var/run/myservice.pid` or (on modern systems)
`/run/myservice.pid`. `/run` is a tmpfs (in-memory) that is always
empty on boot. `/var/run` is typically a symlink to `/run`.

**Socket files:** `/var/run/myservice.sock` or `/run/myservice.sock`
for single-service sockets. For services requiring ACL control,
`/var/run/myservice/` (a directory with restricted permissions).

Why not `/tmp`? `/tmp` has the wrong permission model (world-writable
with sticky bit), making socket files accessible to any local user.
For security, service sockets should be in `/run/myservice/` with
permissions matching the service user.

systemd handles this cleanly via `RuntimeDirectory=myservice` in the
unit file, which creates `/run/myservice/` with correct ownership and
cleans it up on service stop.

```ini
[Service]
RuntimeDirectory=myservice
# Creates /run/myservice/, owned by the service user
# Deleted on service stop
```

> **Code walkthrough:** This illustrates the key concept in action. KEY MECHANISM: the runtime evaluates the pattern and applies the transformation according to the language semantics. WHY IT MATTERS: understanding execution order and side effects prevents subtle bugs. WHAT BREAKS: incorrect assumptions about evaluation order cause intermittent failures. TAKEAWAY: verify behavior with a minimal reproducing case before applying to production code.

*What separates good from great:* knowing the `RuntimeDirectory`
directive in systemd unit files and why socket security requires
restricted paths, not `/tmp`.

---

**[MID] Q6 - How do you find all configuration files modified in the last 24 hours on a production server?**

```bash
# Files modified in last 24 hours under /etc
find /etc -type f -mtime -1 -ls 2>/dev/null
# -rw-r--r-- 1 root root  234 /etc/nginx/sites-enabled/myapp.conf
# Modified 3 hours ago <- recent change

# More specific: changed in last hour, sort by time
find /etc -type f -newer /tmp/marker 2>/dev/null
# Create marker: touch -t $(date -d "1 hour ago" +%Y%m%d%H%M) /tmp/marker

# Check git-tracked config (if using etckeeper)
git -C /etc log --oneline --since "24 hours ago" 2>/dev/null

# Check systemd unit file changes
find /etc/systemd /lib/systemd -name "*.service" -mtime -1

# Check what changed vs package baseline (Debian/Ubuntu)
debsums -c 2>/dev/null | head -20
# Lists files that differ from their installed package checksum
```

> **Code walkthrough:** `find` traverses the filesystem checking each entry against criteria. KEY MECHANISM: `-mtime +N` matches files modified more than N days ago; `-exec cmd {} +` batches matched files to one invocation (faster than `\;`). WHY IT MATTERS: `find / -name pattern -delete` is safe for bulk deletion even when glob expansion would exceed ARG_MAX. WHAT BREAKS: `find /` without `-maxdepth` and path scoping traverses virtual filesystems under `/proc`, `/sys` causing errors or hangs. TAKEAWAY: always scope `find` with a target directory and use `-maxdepth` to limit traversal when searching large trees.

This is a critical security and incident response pattern. Unexpected
changes to `/etc/nginx/nginx.conf`, `/etc/ssh/sshd_config`, or cron
files indicate either unauthorized access or a configuration management
drift.

*What separates good from great:* mentioning `etckeeper` (git-tracking
for /etc) as a best practice and `debsums`/`rpm -V` for comparing
against package baselines.

---

**[JUNIOR] Q7 - What is the purpose of /proc/sys vs /etc/sysctl.d and how do they interact?**

This is covered in depth in the "Philosophy: Everything Is a File"
section. In brief: `/proc/sys/` is the live kernel parameter
interface (immediate but ephemeral), while `/etc/sysctl.d/` provides
persistent configuration applied at boot by systemd-sysctl.

The practical workflow:
1. Make emergency fix: `sysctl -w net.ipv4.tcp_max_syn_backlog=1024`
   (writes to `/proc/sys` immediately)
2. Persist: `echo "net.ipv4.tcp_max_syn_backlog = 1024" > /etc/sysctl.d/99-tcp.conf`
3. Verify persistence: `sysctl -p /etc/sysctl.d/99-tcp.conf`
4. Confirm active value: `sysctl net.ipv4.tcp_max_syn_backlog`

The separation enforces a clear operational discipline: immediate fixes
go through `/proc/sys`, persistent configuration through `/etc/sysctl.d/`.
Any one-step "fix" that only writes to `/proc/sys` is incomplete.

*What separates good from great:* explaining the two-step pattern
(immediate + persist) as a production discipline, not just a technical
fact.

---

---

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ difficulty - single foundational concept; comparison table not required at this level.)*


---

### 🏛️ System Design

*(Omit: non-★★★ keyword - system design integration not applicable at this difficulty level.)*


---

### 📊 Diagram

*(Omit: command-reference topic - the concepts are demonstrated through code examples rather than visual diagrams.)*


# Essential Commands: find, grep, awk, and sed

**Interview Weight:** Moderate - core Linux tool fluency is tested in
operations and full-stack roles; inability to use these tools
competently signals a gap in production debugging capability.

---

### 🎯 Model Answer

**30-second answer:**

"find locates files by attributes (name, size, date, permissions).
grep searches file content for patterns. awk processes text line by
line with field splitting. sed applies streaming edits (substitutions,
deletions). Together they form the core text processing pipeline for
log analysis, data extraction, and system automation."

**3-minute answer:**

"These four tools are the foundation of Linux text processing. I use
them daily in production for log analysis, configuration management,
and system monitoring.

`find` is for locating files: `find /var/log -name '*.log' -mtime -7`
finds logs modified in the last week. The `-exec` flag runs commands
on results: `find /tmp -type f -older /tmp/marker -delete` cleans
old temp files.

`grep` searches content: `grep -r 'NullPointerException' /var/log/myapp/`
recursively searches logs for Java errors. `grep -c` counts matches,
`grep -l` lists matching files, `grep -v` inverts (exclude lines).

`awk` is a full field-processing language: `awk '{print $4}' access.log`
extracts the 4th field (HTTP status code) from Nginx logs. Aggregation:
`awk '{sum[$9]++} END {for(k in sum) print k, sum[k]}' access.log`
counts requests by status code.

`sed` is for streaming substitutions: `sed 's/password=.*/password=REDACTED/'`
sanitizes config files for debugging output. `sed -n '100,200p'` prints
lines 100-200.

The power is in pipes: `grep 'ERROR' app.log | awk '{print $1}' | sort | uniq -c`
counts errors by timestamp minute."

**Blank Mind Recovery:**

"find = locate files by attributes. grep = search file content. awk =
field processing and aggregation. sed = streaming text substitution.
Combine with pipes for log analysis."

---

### 📘 Concept Explanation

**What it is:**

Four POSIX standard Unix tools for file location, text search, text
transformation, and stream editing. They work on text streams, enabling
pipelines for log analysis, data extraction, and automation.

**The problem it solves:**

Before these tools, processing log files, extracting specific fields,
or searching a million-line log required writing programs. grep/awk/sed
make ad-hoc analysis of any text data interactive and instant.

**How it works:**

```
find   -> traverses filesystem tree, applies tests, outputs paths
grep   -> reads line by line, outputs matching lines
awk    -> splits each line into fields ($1, $2...),
          applies pattern-action rules, builds aggregates
sed    -> reads input, applies substitution/delete/print commands,
          outputs modified stream
```

> **Code walkthrough:** `find` traverses the filesystem checking each entry against criteria. KEY MECHANISM: `-mtime +N` matches files modified more than N days ago; `-exec cmd {} +` batches matched files to one invocation (faster than `\;`). WHY IT MATTERS: `find / -name pattern -delete` is safe for bulk deletion even when glob expansion would exceed ARG_MAX. WHAT BREAKS: `find /` without `-maxdepth` and path scoping traverses virtual filesystems under `/proc`, `/sys` causing errors or hangs. TAKEAWAY: always scope `find` with a target directory and use `-maxdepth` to limit traversal when searching large trees.

**The key insight:**

These tools are designed to be chained: `find` produces file lists,
`grep` filters content, `awk` extracts and aggregates fields, and `sed`
transforms. A three-command pipeline can answer production questions
that would require 50 lines of application code.

**When to use each:**

- `find`: when you need to locate files by attribute (not content)
- `grep`: when you need to find lines matching a pattern
- `awk`: when you need to process structured text with columns/fields
- `sed`: when you need to do in-place text substitution (config changes,
  log sanitization)

**When NOT to use these tools:**

For structured data (JSON, XML, binary), use `jq`, `xmllint`, or
language-specific parsers. `grep` on JSON is fragile; `jq` is correct.
For large-scale log analysis (billions of lines), use streaming systems
(Kafka, Flink) or log management platforms.

**Alternatives:**

- `ripgrep (rg)`: modern, faster grep with better default behavior
- `fd`: modern find replacement with simpler syntax
- `perl -ne`: when awk/sed become complex (perl is more expressive)
- `python3 -c`: when logic exceeds what awk handles cleanly

**First-principles derivation:**

"Text processing needs: (1) a way to locate files, (2) a way to filter
lines by content, (3) a way to extract and aggregate fields, (4) a way
to transform text. find, grep, awk, and sed each solve exactly one of
these, composable via pipes."

---

### 💻 Code Example

```bash
# find: locate files by various criteria
find /var/log -name "*.log" -mtime -7 -size +10M
# Files ending in .log, modified in last 7 days, larger than 10MB

find /etc -type f -perm /go+w 2>/dev/null
# Config files world/group-writable (security audit)

find /var/log -name "*.log" -exec gzip {} \;
# Compress all matching files

# grep: search content with context
grep -n "OutOfMemoryError" /var/log/myapp/app.log
# -n: show line numbers

grep -B 5 -A 10 "Exception in thread" /var/log/app.log | head -50
# -B5: 5 lines before match, -A10: 10 lines after

grep -c "ERROR" /var/log/app.log  # count of matching lines
grep -l "ERROR" /var/log/*.log    # which files match

# awk: field extraction and aggregation
# Extract the 4th field (status code) from Nginx access log
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn
# 245123 200
#  12345 304
#    234 500  <- these are errors

# Sum response sizes by status code
awk '{sum[$9]+=$10; count[$9]++}
     END {for(s in sum)
          printf "%s: %d requests, %.2fMB avg\n",
          s, count[s], sum[s]/count[s]/1024/1024}' \
  /var/log/nginx/access.log
```

> **Code walkthrough:** The awk aggregation example uses an associative
array (`sum[$9]`) keyed by HTTP status code, accumulating response
sizes - standard awk pattern for group-by aggregation. KEY MECHANISM:
awk processes each line, splits by whitespace (or custom FS), and
makes each field available as `$1`, `$2`... `$9` is the status code
and `$10` is bytes sent in Nginx log format. WHY IT MATTERS: this
produces a performance summary from millions of Nginx log lines in
seconds without loading the data into any database. WHAT BREAKS: if
the log format has spaces in quoted strings (user agents), `$9` may
not be the status code; verify with `head -1 access.log | awk '{print $9}'`.
TAKEAWAY: awk's `END` block runs after all lines are processed - use
it for summaries and aggregations that need all data before printing.

```bash
# sed: streaming substitution and extraction
# Redact passwords in config output
grep -v "^#" /etc/myapp.conf | \
  sed 's/password=.*/password=REDACTED/g'

# Extract lines 500-600 from a large log
sed -n '500,600p' /var/log/app.log

# Delete blank lines and comment lines
sed '/^#/d; /^$/d' /etc/myapp.conf

# In-place substitution (edit file directly)
sed -i 's/localhost/10.0.0.1/g' /etc/myapp/database.conf
# WARNING: always backup before -i in production
cp /etc/myapp/database.conf{,.bak}
sed -i 's/localhost/10.0.0.1/g' /etc/myapp/database.conf
```

> **Code walkthrough:** `sed -i` (in-place edit) modifies the file
directly without a temporary file redirect. KEY MECHANISM: sed creates
a temp file, writes the modified content, then renames it to the
original - but this replaces the inode, potentially breaking hard links
and file-open handles. WHY IT MATTERS: backing up before `sed -i` on
production config files is non-negotiable; a regex typo that corrupts
nginx.conf causes service outage on next reload. WHAT BREAKS: on macOS,
`sed -i` requires an argument (`sed -i '' 's/old/new/'`); GNU sed on
Linux does not - scripts written on macOS often fail on Linux. TAKEAWAY:
always backup before `sed -i` in production; use `sed -i.bak` which
creates a backup automatically.

---

### 🎓 Answers by Seniority

**Junior/Mid:**

"I use find to locate files, grep to search for patterns in files,
awk to extract fields from structured text, and sed for text
substitution. A typical workflow for log analysis: `grep 'ERROR'
app.log | awk '{print $1}' | sort | uniq -c` to count errors by
timestamp."

**Senior/Staff:**

"These tools are my first response to any production question that
needs data extraction. Key patterns I use: `find /proc -name 'fd' -maxdepth 4 2>/dev/null | xargs -I{} ls {} 2>/dev/null | grep 'socket' | wc -l` to count all open sockets across processes without
lsof. `awk '{sum+=$NF; count++} END {print sum/count}' response_times.log`
for average calculation. `sed -n '/2024-01-15 03:/,/2024-01-15 04:/p'
app.log` to extract a time window from logs. At staff level, I also
invest in knowing when NOT to use these tools: for JSON logs, `jq`
is correct and grep is fragile; for real-time analysis at scale,
these tools read the file sequentially and cannot handle streaming
or distributed logs."

---

### ⚠️ Common Misconceptions

**Misconception 1: "grep -r can search compressed logs."**

`grep -r` reads raw files; it cannot search `.gz` or `.bz2` compressed
logs. Use `zgrep` for gzip-compressed files or `bzgrep` for bzip2.
`find /var/log -name '*.gz' -exec zgrep 'ERROR' {} \;` searches
compressed archives.

**Misconception 2: "awk and sed are interchangeable."**

`awk` is for field-based processing, aggregation, and conditional logic.
`sed` is for line-by-line text transformation. Using awk for simple
`s/old/new/` substitutions works but is verbose; using sed to
aggregate fields requires complex syntax. Use each for its purpose.

**Misconception 3: "find -mtime -1 means the last 24 hours."**

`find -mtime -1` means files whose modification time is less than 1
day ago, counted from the start of the current day, not from "24
hours ago." For exact 24-hour windows, use `find -newer` with a
timestamp reference file.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Grepping for a pattern that exists but returns no results**

```bash
# Problem: grep finds nothing for a known pattern
grep "OutOfMemoryError" /var/log/app.log
# (no output)

# Diagnosis 1: file encoding issue
file /var/log/app.log
# /var/log/app.log: UTF-16 Unicode text  <- grep needs -i flag for UTF-16

# Fix for UTF-16
iconv -f UTF-16 -t UTF-8 /var/log/app.log | grep "OutOfMemoryError"

# Diagnosis 2: file is a symlink pointing nowhere
ls -la /var/log/app.log
# lrwxrwxrwx 1 root root /var/log/app.log -> /data/logs/app.log
file /data/logs/app.log
# cannot open (No such file or directory)  <- broken symlink

# Diagnosis 3: searching in wrong log file
# Logs may have rotated - check all related files
ls -lt /var/log/app/
grep "OutOfMemoryError" /var/log/app/app.log.1
```

> **Code walkthrough:** File encoding mismatches are a common but
silent failure - UTF-16 encoded files (common from Windows-generated
or Java XML logs) contain null bytes that cause grep to treat the
file as binary. KEY MECHANISM: `file` command reads the file header
to identify encoding; `iconv` converts between encodings. WHY IT
MATTERS: Java applications logging to XML-format appenders (log4j)
can produce UTF-16 files on some configurations. WHAT BREAKS: `grep
-a` treats binary as text but produces garbled output on UTF-16.
TAKEAWAY: when grep returns nothing for a known pattern, check file
encoding and verify the symlink target exists before spending time
on pattern debugging.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | tool selection, pipeline design |
| Debugging | 2 | log analysis, pattern matching |
| Trade-off | 3 | performance, tool selection |

---

**[JUNIOR] Q1 - How do you count unique IP addresses in an Nginx access log?**

```bash
# Nginx default combined log format:
# IP - - [date] "METHOD /path HTTP/1.1" status bytes

# Method 1: awk (most efficient)
awk '{print $1}' /var/log/nginx/access.log | sort -u | wc -l
# awk extracts field 1 (IP), sort -u removes duplicates, wc -l counts

# Method 2: awk with counts (top 10 IPs)
awk '{count[$1]++} END {for(ip in count) print count[ip], ip}' \
  /var/log/nginx/access.log | sort -rn | head -10

# Method 3: for time-windowed analysis (today only)
grep "$(date +%d/%b/%Y)" /var/log/nginx/access.log | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -10
```

> **Code walkthrough:** Text processing pipeline for log analysis. KEY MECHANISM: `grep` filters lines; `awk '{print $N}'` extracts fields; `sed 's/old/new/'` substitutes patterns; piped they form a streaming transformation. WHY IT MATTERS: processing log files too large for editors requires streaming tools. WHAT BREAKS: using `grep -r /var/log/` on binary files causes garbage output; use `grep -r --include='*.log'` to limit to text files. TAKEAWAY: `awk -F: '{print $1}' /etc/passwd` and `sed -i 's/old/new/g' file` are the two most common production usage patterns.

The method 2 awk approach is the production-grade one: it does the
aggregation in a single pass, avoiding the cost of sorting the full
IP list before counting. For a 10GB log file, method 1 (sort | uniq)
requires sorting the entire file; method 2 (awk associative array)
uses O(unique IPs) memory and O(n) time.

*What separates good from great:* choosing awk's associative array
over `sort | uniq -c | sort -rn` for large files because it's a
single pass vs multiple passes.

---

**[MID] Q2 - You need to find all Java processes that have been running for more than 24 hours. How?**

```bash
# ps output with elapsed time
ps -eo pid,etime,comm | grep java
# PID    ELAPSED COMMAND
# 1234  25:00:00 java   <- 25 hours
# 5678   1:30:00 java   <- 1.5 hours (under threshold)

# awk to filter by elapsed time > 24 hours
# ELAPSED format: [[dd-]hh:]mm:ss
ps -eo pid,etime,comm | grep java | awk '
{
  # field $2 = elapsed, $3 = command
  split($2, t, "[-:]")
  # Handle different etime formats
  if (length(t) == 4) days = t[1]  # dd-hh:mm:ss
  else if (length(t) == 3) days = 0 # hh:mm:ss
  else days = 0                      # mm:ss
  if (days >= 1) print $1, $2, $3   # 1+ days old
}'

# Simpler: use find on /proc (ctime approximation)
find /proc -maxdepth 1 -type d -name '[0-9]*' \
  -mtime +1 2>/dev/null | while read procdir; do
    comm=$(cat "$procdir/comm" 2>/dev/null)
    [[ "$comm" == "java" ]] && echo "$procdir $comm"
done
```

> **Code walkthrough:** `find` traverses the filesystem checking each entry against criteria. KEY MECHANISM: `-mtime +N` matches files modified more than N days ago; `-exec cmd {} +` batches matched files to one invocation (faster than `\;`). WHY IT MATTERS: `find / -name pattern -delete` is safe for bulk deletion even when glob expansion would exceed ARG_MAX. WHAT BREAKS: `find /` without `-maxdepth` and path scoping traverses virtual filesystems under `/proc`, `/sys` causing errors or hangs. TAKEAWAY: always scope `find` with a target directory and use `-maxdepth` to limit traversal when searching large trees.

For production use, I prefer `ps -eo pid,etime,comm` because it shows
elapsed time directly. The awk parsing of etime format handles the
`dd-HH:MM:SS` format correctly for processes running multiple days.

*What separates good from great:* knowing the `etime` format in ps
output changes from `MM:SS` to `HH:MM:SS` to `DD-HH:MM:SS` as the
process ages, requiring format-aware parsing.

---

**[JUNIOR] Q3 - How do you use sed to safely edit production configuration files?**

Safe production config editing with sed:

```bash
# Step 1: validate the current file is what you expect
grep "max_connections = 100" /etc/postgresql/14/main/postgresql.conf
# Confirm the value is there before modifying

# Step 2: backup with timestamp
cp /etc/postgresql/14/main/postgresql.conf{,.$(date +%Y%m%d%H%M%S).bak}

# Step 3: test the substitution with dry run (no -i)
sed 's/max_connections = 100/max_connections = 200/' \
  /etc/postgresql/14/main/postgresql.conf | \
  grep max_connections
# max_connections = 200  <- verify output looks right

# Step 4: apply with sed -i.bak (creates .bak automatically)
sed -i.bak 's/max_connections = 100/max_connections = 200/' \
  /etc/postgresql/14/main/postgresql.conf

# Step 5: verify
grep max_connections /etc/postgresql/14/main/postgresql.conf
# max_connections = 200

# Step 6: validate config before reload
postgresql --config-file=/etc/postgresql/14/main/postgresql.conf --check
```

> **Code walkthrough:** Text processing pipeline for log analysis. KEY MECHANISM: `grep` filters lines; `awk '{print $N}'` extracts fields; `sed 's/old/new/'` substitutes patterns; piped they form a streaming transformation. WHY IT MATTERS: processing log files too large for editors requires streaming tools. WHAT BREAKS: using `grep -r /var/log/` on binary files causes garbage output; use `grep -r --include='*.log'` to limit to text files. TAKEAWAY: `awk -F: '{print $1}' /etc/passwd` and `sed -i 's/old/new/g' file` are the two most common production usage patterns.

Key safety rules: (1) always test without `-i` first, (2) use a
specific enough pattern to avoid accidental matches (not just
`s/100/200/`), (3) use `-i.bak` not bare `-i` to preserve the original.

*What separates good from great:* the dry run pattern (test without
`-i`, then apply) and using specific enough patterns to avoid
accidental substitutions in other parts of the config file.

---

**[MID] Q4 - What does find -exec {} \; do and how does it differ from find ... | xargs?**

`find -exec cmd {} \;` runs the command once for each file found.
`find ... | xargs cmd` passes multiple file names as arguments to
a single command invocation (or batches of arguments).

```bash
# -exec: one command per file (slower)
find /var/log -name "*.log" -exec gzip {} \;
# Runs: gzip /var/log/app.log
# Runs: gzip /var/log/syslog
# ... N separate gzip processes

# xargs: multiple files per command (faster)
find /var/log -name "*.log" | xargs gzip
# Runs: gzip /var/log/app.log /var/log/syslog ...
# One gzip process with all files

# xargs -P: parallel execution
find /var/log -name "*.log" | xargs -P4 gzip
# 4 parallel gzip processes

# Handle filenames with spaces (critical!)
find /var/log -name "*.log" -print0 | xargs -0 gzip
# -print0 uses null delimiter, -0 reads null-delimited input
# Prevents filenames with spaces from being split
```

> **Code walkthrough:** `find` traverses the filesystem checking each entry against criteria. KEY MECHANISM: `-mtime +N` matches files modified more than N days ago; `-exec cmd {} +` batches matched files to one invocation (faster than `\;`). WHY IT MATTERS: `find / -name pattern -delete` is safe for bulk deletion even when glob expansion would exceed ARG_MAX. WHAT BREAKS: `find /` without `-maxdepth` and path scoping traverses virtual filesystems under `/proc`, `/sys` causing errors or hangs. TAKEAWAY: always scope `find` with a target directory and use `-maxdepth` to limit traversal when searching large trees.

`-exec ... +` is a hybrid: passes multiple files to one invocation
(like xargs) but without the pipe (better error handling):
```bash
find /var/log -name "*.log" -exec gzip {} +
# Equivalent to xargs but handles errors better
```

> **Code walkthrough:** `find` traverses the filesystem checking each entry against criteria. KEY MECHANISM: `-mtime +N` matches files modified more than N days ago; `-exec cmd {} +` batches matched files to one invocation (faster than `\;`). WHY IT MATTERS: `find / -name pattern -delete` is safe for bulk deletion even when glob expansion would exceed ARG_MAX. WHAT BREAKS: `find /` without `-maxdepth` and path scoping traverses virtual filesystems under `/proc`, `/sys` causing errors or hangs. TAKEAWAY: always scope `find` with a target directory and use `-maxdepth` to limit traversal when searching large trees.

*What separates good from great:* knowing `-print0 | xargs -0` for
filename safety and `-exec {} +` as the safer xargs equivalent.

---

**[JUNIOR] Q5 - How do you extract error statistics from multi-line Java stack traces in a log?**

Multi-line stack traces are the hard case for grep because a single
exception spans many lines:

```bash
# Count total exception occurrences (by first line)
grep -c "^.*Exception" /var/log/app.log
# (counts lines starting with XxxException)

# Extract exception class names and count
grep -oP '(?<=: )[A-Za-z.]+Exception' /var/log/app.log | \
  sort | uniq -c | sort -rn | head -10
# 1234 java.lang.NullPointerException
#  456 java.io.IOException
#   12 com.myapp.ServiceException

# Extract full stack traces using awk (multi-line aware)
awk '/Exception in thread|Caused by:/{
       found=1; lines=""
     }
     found{
       lines=lines "\n" $0
       if(/^\s*at / && ++count > 5){
         print lines; found=0; count=0
       }
     }' /var/log/app.log | head -100

# Count exceptions per minute for incident timeline
grep "Exception" /var/log/app.log | \
  awk '{print substr($1, 1, 16)}' | \
  sort | uniq -c
# 2024-01-15 03:0    3
# 2024-01-15 03:1  156  <- spike at 03:10
```

> **Code walkthrough:** Text processing pipeline for log analysis. KEY MECHANISM: `grep` filters lines; `awk '{print $N}'` extracts fields; `sed 's/old/new/'` substitutes patterns; piped they form a streaming transformation. WHY IT MATTERS: processing log files too large for editors requires streaming tools. WHAT BREAKS: using `grep -r /var/log/` on binary files causes garbage output; use `grep -r --include='*.log'` to limit to text files. TAKEAWAY: `awk -F: '{print $1}' /etc/passwd` and `sed -i 's/old/new/g' file` are the two most common production usage patterns.

The per-minute histogram (`substr($1, 1, 16)` truncates to minute
precision) is the most useful pattern for incident timeline reconstruction.

*What separates good from great:* the per-minute error rate histogram
to identify the onset of an incident - standard first response to
"when did errors start?"

---

**[MID] Q6 - How do you use find to perform a security audit of file permissions?**

```bash
# Find SUID/SGID binaries (potential privilege escalation)
find / -perm /4000 -type f -ls 2>/dev/null
# -rws--x--x  1 root root   123456 /usr/bin/sudo
# -rwsr-sr-x  1 root root   123456 /usr/bin/passwd

# Find world-writable files in sensitive directories
find /etc /usr/bin /usr/sbin -perm /o+w -type f 2>/dev/null
# World-writable files here = serious security issue

# Find files with no owner (orphaned after user deletion)
find /home /var -nouser -o -nogroup 2>/dev/null

# Find recently modified SUID binaries (potential tampering)
find / -perm /4000 -mtime -7 -type f 2>/dev/null

# Find .ssh directories with wrong permissions
find /home -name ".ssh" -type d ! -perm 700 2>/dev/null
find /home -name "authorized_keys" ! -perm 600 2>/dev/null
```

> **Code walkthrough:** `find` traverses the filesystem checking each entry against criteria. KEY MECHANISM: `-mtime +N` matches files modified more than N days ago; `-exec cmd {} +` batches matched files to one invocation (faster than `\;`). WHY IT MATTERS: `find / -name pattern -delete` is safe for bulk deletion even when glob expansion would exceed ARG_MAX. WHAT BREAKS: `find /` without `-maxdepth` and path scoping traverses virtual filesystems under `/proc`, `/sys` causing errors or hangs. TAKEAWAY: always scope `find` with a target directory and use `-maxdepth` to limit traversal when searching large trees.

SUID bit (`-perm /4000`) is a critical security concern: SUID binaries
run as their owner (often root) regardless of who invokes them. A
world-writable SUID binary is a guaranteed privilege escalation path.

*What separates good from great:* knowing that `-perm /4000` finds any
SUID bit (owner, group, or sticky) and explaining WHY unexpected SUID
files are a critical finding, not just listing the command.

---

**[JUNIOR] Q7 - When would you use perl or python over awk for text processing?**

The transition point is complexity. Use awk when: single file input,
field-based processing, simple aggregations, less than 10 lines of awk.

Switch to Python or Perl when:
1. **Multiple file processing with cross-reference:** joining two files
   (awk handles `NR==FNR` but it's fragile)
2. **Complex data structures:** nested groupings, hash of arrays
3. **Regular expressions beyond basic:** lookaheads, backreferences
4. **Structured formats:** JSON, XML, CSV with quoting (awk misparses
   quoted commas in CSV)
5. **Error handling:** awk silently skips malformed input; Python raises
6. **Unicode:** awk has poor Unicode handling; Python handles it natively

```python
# Python equivalent of complex awk (errors by hour from JSON logs)
import sys
from collections import defaultdict
import json

errors_by_hour = defaultdict(int)
for line in sys.stdin:
    try:
        log = json.loads(line)
        if log.get("level") == "ERROR":
            hour = log["timestamp"][:13]  # "2024-01-15T03"
            errors_by_hour[hour] += 1
    except (json.JSONDecodeError, KeyError):
        pass  # skip malformed lines

for hour, count in sorted(errors_by_hour.items()):
    print(f"{hour}: {count}")
```

> **Code walkthrough:** Text processing pipeline for log analysis. KEY MECHANISM: `grep` filters lines; `awk '{print $N}'` extracts fields; `sed 's/old/new/'` substitutes patterns; piped they form a streaming transformation. WHY IT MATTERS: processing log files too large for editors requires streaming tools. WHAT BREAKS: using `grep -r /var/log/` on binary files causes garbage output; use `grep -r --include='*.log'` to limit to text files. TAKEAWAY: `awk -F: '{print $1}' /etc/passwd` and `sed -i 's/old/new/g' file` are the two most common production usage patterns.

*What separates good from great:* specifically naming JSON log
processing as the concrete trigger for switching from awk to Python,
since most modern services emit structured JSON logs.

---

---

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ difficulty - single foundational concept; comparison table not required at this level.)*


---

### 🏛️ System Design

*(Omit: non-★★★ keyword - system design integration not applicable at this difficulty level.)*


---

### 📊 Diagram

*(Omit: command-reference topic - the concepts are demonstrated through code examples rather than visual diagrams.)*


# File Permissions and Ownership: chmod and chown

**Interview Weight:** Moderate - operational security questions about
file permissions appear in DevOps and backend engineering screens;
tests whether candidate understands security model, not just syntax.

---

### 🎯 Model Answer

**30-second answer:**

"Linux file permissions use a three-level model: owner, group, and
others. Each level gets read (4), write (2), and execute (1) bits.
chmod sets permissions, chown sets ownership. The most important
production rules: config files should be 640 or 600, scripts 750 or
755, and never 777. SUID bit allows a binary to run as its owner
regardless of the caller."

**3-minute answer:**

"Linux file permissions are a discretionary access control system.
Every file and directory has an owner (user), an owning group, and
permission bits for three categories: owner, group, and others.

Permission bits: read=4, write=2, execute=1. Combined: 7 = rwx,
6 = rw-, 5 = r-x, 4 = r--. chmod 750 means owner=rwx, group=r-x,
others=no access.

For directories, execute means 'traverse' (cd into). A directory
with 444 (no execute) cannot be entered even though all files are
readable.

The special bits: SUID (4000) makes a binary run as its owner user
regardless of who executes it. SGID (2000) makes files in a directory
inherit the directory's group. Sticky bit (1000) on a directory means
only the owner can delete their files (used on /tmp).

Production security rules I follow:
- Private keys: 600 (owner read/write only)
- Config with credentials: 640 (owner rw, group r)
- Web served files: 644 (readable by web server user)
- Scripts: 755 or 750
- Never 777 in production (world writable = security risk)
- Never 666 on config files (world writable config)"

**Blank Mind Recovery:**

"Permissions = user/group/others, each with read=4/write=2/execute=1.
chmod 755 = owner rwx, group rx, others rx. chown user:group file.
Never 777. Private keys = 600. Config = 640."

---

### 📘 Concept Explanation

**What it is:**

Linux Discretionary Access Control (DAC) via POSIX permissions: every
file and directory has an owner, an owning group, and nine permission
bits (three each for owner, group, others) controlling read, write,
and execute access.

**The problem it solves:**

On a multi-user system, processes must not be able to read each other's
sensitive files (private keys, credentials), and system files must not
be writable by unprivileged users.

**How it works:**

Permission representation:
```
-rwxr-xr--
│└──┴──┴──
│ owner │ group │ others
│ r=4   │ r=4   │ r=4
│ w=2   │       │
│ x=1   │ x=1   │
│ =7    │ =5    │ =4
    rwx       r-x       r--
    chmod 754
```

> **Code walkthrough:** File permission management commands. KEY MECHANISM: `chmod u+x` adds execute for owner without changing other bits; `chmod 640` (octal) sets rw-r----- in one operation. WHY IT MATTERS: world-writable files (`o+w`) are security vulnerabilities; SUID files (`chmod u+s`) run as the file owner, not the caller. WHAT BREAKS: `chmod -R 777 /var/data` on shared servers exposes all files to all users. TAKEAWAY: `stat -c '%a %n'` file shows current octal permissions; prefer symbolic notation (`u+x`) to modify specific bits without clobbering others.

Special permission bits (prefix digit in octal):
- SUID (4): file runs as owner; on directory, inherits owner
- SGID (2): file runs as group; on directory, new files inherit group
- Sticky (1): on directory, only owner can delete their files

**The key insight:**

`chmod 777` is not "permissive" - it is a security vulnerability. Any
user on the system can modify or replace a world-writable executable
or config file, enabling privilege escalation or data exfiltration.

**When to use specific permissions:**

| File type | Recommended | Why |
|---|---|---|
| Private key | 600 | Only owner should read |
| Config with password | 640 | Owner rw, group r (service user) |
| Public web file | 644 | Readable by web server |
| Script | 755 | Executable by all |
| Directory (sensitive) | 750 | Group can traverse |
| /tmp style dir | 1777 | Sticky bit + world write |

**When NOT to use 777:**

Never in production. World-writable files allow any local user or
compromised process to modify them. World-writable directories allow
symlink attacks.

**Alternatives:**

- ACLs (setfacl/getfacl): per-user permissions beyond owner/group/other
- SELinux/AppArmor: mandatory access control that enforces policy
  regardless of POSIX permissions

**First-principles derivation:**

"Given N users sharing a system, the minimum necessary access control
is: (1) owners control their files (DAC), (2) a group abstraction for
shared access, (3) a default-deny for everyone else. The nine POSIX
bits implement exactly this three-level model."

---

### 💻 Code Example

```bash
# View permissions in detail
ls -la /etc/nginx/
# drwxr-xr-x  2 root root 4096 /etc/nginx/
# -rw-r--r--  1 root root 1234 /etc/nginx/nginx.conf
# -rw-r-----  1 root root  234 /etc/nginx/htpasswd  <- group-only read

# Set permissions (octal notation - preferred in scripts)
chmod 600 ~/.ssh/id_rsa        # Private key: owner read-write only
chmod 644 ~/.ssh/id_rsa.pub    # Public key: readable by all
chmod 700 ~/.ssh               # .ssh dir: owner only

# Set permissions (symbolic notation - readable in scripts)
chmod u=rw,g=r,o= /etc/myapp/database.conf
# u=rw: user read+write
# g=r:  group read only
# o=:   others no access (= 640)

# Add execute bit without changing other permissions
chmod +x /usr/local/bin/myscript.sh   # add for all
chmod u+x deploy.sh                    # add for owner only

# chown: change ownership
chown appuser:appgroup /var/lib/myapp/
chown -R appuser:appgroup /var/lib/myapp/  # recursive
chown appuser /etc/myapp/config.json   # change user only
chown :appgroup /etc/myapp/config.json # change group only
```

> **Code walkthrough:** `chmod u=rw,g=r,o=` uses symbolic notation
which is safer than octal because it sets exactly the specified bits
without needing to calculate the number. KEY MECHANISM: `o=` with an
empty right side removes ALL bits for others - read, write, and
execute - regardless of current state. WHY IT MATTERS: `chmod o-r`
removes only read from others but preserves other bits; `chmod o=`
removes all bits - correct for sensitive config files. WHAT BREAKS:
using `chmod 640 -R /etc/myapp/` recursively sets all files to 640,
but directories need execute (traverse) bit to be usable - directories
should be 750. TAKEAWAY: never apply the same permission recursively
to files and directories; separate them with `find -type f` and
`find -type d`.

```bash
# SUID and special bits
# View with ls (s = SUID/SGID, t = sticky)
ls -la /usr/bin/sudo
# -rwsr-xr-x 1 root root 166056 /usr/bin/sudo
#    ^--- s = SUID bit: runs as root regardless of caller

# Set SUID (use with extreme caution)
chmod u+s /usr/local/bin/mysetuid     # symbolic
chmod 4755 /usr/local/bin/mysetuid    # octal (4=SUID prefix)

# Sticky bit on shared directory
chmod 1777 /shared/uploads            # octal
chmod +t /shared/uploads              # symbolic
# Now: any user can create files, but only file owner can delete them

# Find all SUID files (security audit)
find / -perm /4000 -type f -ls 2>/dev/null | head -20
```

> **Code walkthrough:** The `s` in `rwsr-xr-x` (lowercase) means both
the execute bit AND SUID are set. KEY MECHANISM: when an SUID binary
executes, the kernel sets the process's effective UID to the file's
owner (root for sudo) rather than the caller's UID; this is how sudo
gains root privileges for the duration of the command. WHY IT MATTERS:
any newly discovered SUID binary that wasn't there before is a critical
security indicator - attackers create SUID binaries as persistence
mechanisms. WHAT BREAKS: setting SUID on a script (shell script with
`s` bit) has no effect on most modern Linux systems - SUID is ignored
for interpreted scripts for security reasons. TAKEAWAY: regularly
audit SUID binaries with `find / -perm /4000` and compare against
a known-good baseline.

---

### 🎓 Answers by Seniority

**Junior/Mid:**

"File permissions in Linux are controlled with chmod (permissions) and
chown (ownership). Permissions are read=4, write=2, execute=1. 755
means owner rwx, group and others r-x. 600 means owner read-write
only. For production files: private keys are 600, config files 640 or
644, scripts 755. Never use 777 - that makes files writable by anyone."

**Senior/Staff:**

"Permissions are the first line of process isolation. My production
standards: application config with credentials at 640, owned by
root:appgroup (root owns it so the app can't modify its own config,
but the app's group can read it). SSH keys at 600, .ssh directory at
700. Scripts at 750 (no world-execute for scripts that shouldn't be
publicly executable). I also audit for SUID bits on deployment: `find
/ -perm /4000 -newer /tmp/deploy-marker` shows any new SUID files
created during deployment. In Kubernetes, security contexts enforce
Unix permissions at the container level: `runAsUser`, `fsGroup`, and
`readOnlyRootFilesystem` map directly to these Linux permission concepts.
ACLs (setfacl) handle the cases where owner/group/other isn't granular
enough - for example, giving a monitoring user read access to a config
file without adding it to the app group."

---

### ⚠️ Common Misconceptions

**Misconception 1: "755 on a config file is fine since it's read-only."**

World-readable config files (`r--` for others) expose credentials,
API keys, database passwords, and internal service hostnames to any
local user or compromised process. Config files with credentials should
be at most 640 (owner rw, group r, others nothing).

**Misconception 2: "chown -R root:root /etc/myapp/ is the safest choice."**

If the application runs as `appuser` and all files are owned by root,
the application cannot read its own config. The correct pattern:
root owns the file (preventing the app from modifying it), but the
app's group has read access: `chown root:appgroup config.conf` +
`chmod 640 config.conf`.

**Misconception 3: "execute bit on a directory means the directory is executable."**

On directories, the execute bit means "traverse" - permission to `cd`
into the directory and access its contents. Without execute permission
on a directory, even if you have read permission (to list contents),
you cannot access the files inside.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Service fails to start due to permission error**

```bash
# Symptom: service exits immediately with "Permission denied"

# Check service user
systemctl show myservice -p User
# User=appuser

# Check what files the service needs
strace -e trace=open,openat -p $(pgrep myservice) 2>&1 | \
  grep "EACCES\|EPERM" | head -20
# openat(AT_FDCWD, "/etc/myapp/config.conf", O_RDONLY) = -1 EACCES

# Check the permission issue
ls -la /etc/myapp/config.conf
# -rw------- 1 root root 234 config.conf
# Owner only! appuser cannot read it.

# Fix: give appuser's group read access
chown root:appuser /etc/myapp/config.conf
chmod 640 /etc/myapp/config.conf

# Verify appuser's groups
id appuser
# uid=1001(appuser) gid=1001(appuser) groups=1001(appuser)
# If appuser is not in the group, add it:
usermod -aG appuser appuser  # add appuser to appuser group
# Restart service for group membership to take effect
systemctl restart myservice
```

> **Code walkthrough:** `strace -e trace=open,openat` filters syscalls
to only file open operations, and EACCES in the return value pinpoints
permission failures. KEY MECHANISM: every file access by a process
goes through a kernel permission check comparing the process's
effective UID/GID against the file's owner/group/other bits. WHY IT
MATTERS: "permission denied" without knowing which file is denied
wastes debugging time; strace narrows it to the exact file path in
seconds. WHAT BREAKS: the service user may have the correct group but
needs to log out and back in (or restart) for group changes to take
effect - groups are resolved at login time. TAKEAWAY: the correct
production pattern for service config is `root:servicegroup` ownership
with 640 permissions - root owns (service can't modify its own config),
service group can read.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | permission model, SUID, directory execute |
| Debugging | 2 | permission denied, misconfigured perms |
| Trade-off | 2 | DAC vs ACL, permission strategies |

---

**[JUNIOR] Q1 - What does the execute bit mean for a directory versus a file?**

For a regular file, execute permission means the kernel can load and
execute the file as a program. For shell scripts, it means the
interpreter specified in the shebang line (`#!/bin/bash`) can be
invoked with the script as input.

For a directory, execute permission means "traverse" - permission to
enter the directory (change to it with `cd`) and access its contents
by name. Without execute on a directory:
- `ls /path/to/dir` works if you have read permission (shows names)
- `cat /path/to/dir/file.txt` fails with "Permission denied" even if
  the file itself is readable

This means: to access a file, you need execute permission on every
directory in the path. A file at `/home/user/project/config.conf` that
is mode 644 but in a directory that is mode 700 (no group/other access)
is inaccessible to other users.

The common confusion: `chmod -x` on a directory removes the ability
to enter it, which is a stronger restriction than `chmod -r`. Read
without execute on a directory lets you see filenames but not access
the files - useful for directory listing monitoring without file access.

*What separates good from great:* explaining that traverse permission
applies to every directory in a path - a file buried deep in a
restricted hierarchy is effectively inaccessible even if the file
itself has permissive settings.

---

**[MID] Q2 - What is the SUID bit, when is it legitimate, and what makes it dangerous?**

The SUID (Set User ID) bit causes a binary to execute with the
privileges of its owner rather than the privileges of the user who
invokes it. When set on a root-owned binary (the common case), any
user who executes the file gains root privileges for the duration of
the execution.

Legitimate uses:
- `passwd`: needs to write `/etc/shadow` (root-owned) to change passwords
- `sudo`: needs to execute commands as root
- `ping` (on older systems): needs `CAP_NET_RAW` for raw sockets
- `mount`, `su`: similar privilege requirements

The danger: a world-executable SUID root binary that has a buffer
overflow, command injection, or path traversal vulnerability is a
direct privilege escalation path for any local user.

An attacker with shell access will immediately run `find / -perm /4000`
to locate SUID binaries and check them against known exploits. Any
unexpected SUID binary (not in the original package list) is an
indicator of compromise.

Production practice: audit SUID binaries on every system and maintain
a whitelist. Alert on any new SUID file appearing outside of package
management. Modern Linux reduces SUID use via capabilities
(`CAP_NET_RAW` for ping instead of full SUID root).

*What separates good from great:* mentioning Linux capabilities as the
modern replacement for many SUID use cases - showing awareness of
the security evolution beyond basic POSIX.

---

**[JUNIOR] Q3 - How do ACLs extend the standard Unix permission model and when do you need them?**

POSIX ACLs (Access Control Lists) allow per-user and per-group
permissions beyond the owner/group/other model.

Standard Unix permissions have a key limitation: only one group can
have explicit permissions on a file. If you need:
- User Alice: read
- User Bob: read + write
- Group ops: read
- Group dev: no access

The standard model cannot express this. ACLs can.

```bash
# View ACLs
getfacl /var/lib/myapp/config.json
# file: config.json
# owner: root
# group: appgroup
# user::rw-       <- owner
# user:alice:r--  <- alice specifically
# group::r--      <- group
# group:ops:r--   <- ops group specifically
# mask::r--       <- effective permission ceiling
# other::---      <- others

# Set ACLs
setfacl -m u:alice:r /var/lib/myapp/config.json
setfacl -m g:ops:rw /var/lib/myapp/data/
setfacl -R -m g:monitoring:r /var/log/myapp/  # recursive
```

> **Code walkthrough:** This command sequence demonstrates a production diagnostic technique. KEY MECHANISM: shell pipelines connect command stdout to stdin via in-memory buffers; each command runs concurrently. WHY IT MATTERS: these patterns are immediately applicable to production debugging without installing additional tools. WHAT BREAKS: unquoted variables with spaces cause word-splitting and unexpected argument boundaries. TAKEAWAY: test commands interactively first, then wrap in scripts with `set -euo pipefail` at the top.

Production use cases:
1. Monitoring agent needs read access to application logs without
   joining the application group
2. CI/CD user needs write access to deploy directories without
   full group membership
3. Compliance requirement for specific user audit access to logs

*What separates good from great:* knowing the ACL `mask` field -
the effective permission ceiling that limits ACL entries regardless
of what they specify, and how `chmod` on a file with ACLs affects
the mask.

---

**[MID] Q4 - What is the sticky bit and where is it appropriate to use?**

The sticky bit (mode bit 1000, represented as `t` in `ls` output) on
a directory means: any user can create files in the directory, but
only the file's owner (or root) can delete it, even if others have
write permission to the directory.

Without sticky bit:
- `/tmp` is world-writable (mode 1777 → 777 = world-writable + sticky)
- Without sticky: any user could delete any other user's temp files
- With sticky: each user can only delete their own files

Where to use:
- `/tmp`: standard use case (world-writable shared space)
- Shared upload directories where multiple users/services write
- Group collaboration directories where members shouldn't delete each
  other's work

```bash
ls -la / | grep tmp
# drwxrwxrwt  1 root root   ... /tmp  <- 't' = sticky bit set

# Set sticky bit
chmod +t /shared/uploads     # symbolic
chmod 1775 /shared/uploads   # octal (1 = sticky prefix)
```

> **Code walkthrough:** Text processing pipeline for log analysis. KEY MECHANISM: `grep` filters lines; `awk '{print $N}'` extracts fields; `sed 's/old/new/'` substitutes patterns; piped they form a streaming transformation. WHY IT MATTERS: processing log files too large for editors requires streaming tools. WHAT BREAKS: using `grep -r /var/log/` on binary files causes garbage output; use `grep -r --include='*.log'` to limit to text files. TAKEAWAY: `awk -F: '{print $1}' /etc/passwd` and `sed -i 's/old/new/g' file` are the two most common production usage patterns.

An important edge case: the sticky bit on an executable file (the
original UNIX purpose) had a different meaning (keep in swap) that
is now obsolete and has no effect on modern Linux.

*What separates good from great:* knowing the historical use (keep
in swap, now obsolete) vs current use (directory deletion restriction)
and mentioning that root can always delete any file regardless of
sticky bit.

---

**[JUNIOR] Q5 - A service runs as 'appuser' but cannot read its own config file. Walk through your diagnosis.**

Systematic permission diagnosis:

```bash
# Step 1: confirm what user the process runs as
ps aux | grep myservice | grep -v grep
# appuser  1234  ... /usr/bin/myservice

# Step 2: check what file it can't read (from error log or strace)
grep -i "permission denied\|EACCES" /var/log/myservice/error.log
# [ERROR] Cannot open /etc/myservice/config.json: Permission denied

# Step 3: check file permissions
ls -la /etc/myservice/config.json
# -rw------- 1 root root 234 config.json
# Only root can read it.

# Step 4: check appuser's identity and groups
id appuser
# uid=1001(appuser) gid=1001(appuser) groups=1001(appuser),1002(svcgroup)

# Step 5: fix options
# Option A: add group ownership
chown root:appuser /etc/myservice/config.json
chmod 640 /etc/myservice/config.json

# Option B: ACL (if you can't change group ownership)
setfacl -m u:appuser:r /etc/myservice/config.json

# Option C: add appuser to the file's existing group
usermod -aG svcgroup appuser
# (requires service restart to pick up new group)

# Verify
sudo -u appuser cat /etc/myservice/config.json
# Confirm it works as the service user
```

> **Code walkthrough:** `ps` output format showing process resource consumption columns. KEY MECHANISM: `VSZ` = virtual memory (mapped pages, not all allocated physically); `RSS` = resident set (actual RAM). WHY IT MATTERS: a Java process with VSZ=4GB but RSS=512MB is using normal JVM memory mapping; the RSS is what matters for OOM pressure. WHAT BREAKS: sorting by VSZ shows misleading 'high memory' processes that are using mmap'd files. TAKEAWAY: always compare RSS, not VSZ, when diagnosing memory issues.

The best production solution depends on context: Option A (group
ownership) is simplest and follows least-privilege. Option C
(group membership) is appropriate if multiple services share config.
Option B (ACL) is for exceptions when group ownership is already used
for a different purpose.

*What separates good from great:* testing the fix with `sudo -u appuser`
to validate it before restarting the service in production.

---

**[MID] Q6 - What permissions should application config files, private keys, and log directories have?**

Production-grade permission standards:

```bash
# Application config (no credentials)
chmod 644 /etc/myapp/app.conf     # world-readable, fine
chown root:root /etc/myapp/app.conf

# Application config (WITH credentials)
chmod 640 /etc/myapp/secrets.conf  # ONLY group can read
chown root:appgroup /etc/myapp/secrets.conf
# root owns it (app can't modify its own secrets)
# appgroup can read it (service user is in appgroup)

# Private SSH/TLS keys
chmod 600 /etc/myapp/server.key   # owner read-write ONLY
chown root:root /etc/myapp/server.key
# or if service reads it directly:
chmod 640 /etc/myapp/server.key
chown root:appgroup /etc/myapp/server.key

# Certificates (public, not secret)
chmod 644 /etc/myapp/server.crt

# Log directory
chmod 755 /var/log/myapp/         # traversable
chown appuser:appgroup /var/log/myapp/
# Service writes logs, ops team reads them via group membership

# Data directory (service read-write)
chmod 750 /var/lib/myapp/
chown appuser:appgroup /var/lib/myapp/
```

> **Code walkthrough:** File permission management commands. KEY MECHANISM: `chmod u+x` adds execute for owner without changing other bits; `chmod 640` (octal) sets rw-r----- in one operation. WHY IT MATTERS: world-writable files (`o+w`) are security vulnerabilities; SUID files (`chmod u+s`) run as the file owner, not the caller. WHAT BREAKS: `chmod -R 777 /var/data` on shared servers exposes all files to all users. TAKEAWAY: `stat -c '%a %n'` file shows current octal permissions; prefer symbolic notation (`u+x`) to modify specific bits without clobbering others.

The critical rule: files with secrets should never be group-writable
or world-readable. The owner should be root (not the app user), with
the app user's group having read-only access. This prevents a
compromised app process from modifying its own credentials.

*What separates good from great:* explaining WHY root should own
secret files (not the app user) - because a compromised app process
running as appuser can't modify root-owned files, preventing credential
rotation attacks.

---

**[JUNIOR] Q7 - What is umask and how does it affect file creation?**

`umask` (user file creation mask) is the bitmask subtracted from the
default permissions when a file or directory is created. It specifies
which permission bits to remove by default.

Default creation permissions:
- Files: 666 (rw-rw-rw-)
- Directories: 777 (rwxrwxrwx)

Umask removes bits. Common umask values:
- `022` (default for most systems): removes group-write and others-write
  - Files: 666 - 022 = 644 (rw-r--r--)
  - Dirs:  777 - 022 = 755 (rwxr-xr-x)
- `027`: removes group-write and all others access
  - Files: 666 - 027 = 640 (rw-r-----)
  - Dirs:  777 - 027 = 750 (rwxr-x---)
- `077`: owner only
  - Files: 666 - 077 = 600 (rw-------)
  - Dirs:  777 - 077 = 700 (rwx------)

```bash
# View current umask
umask        # 0022 (octal)
umask -S     # u=rwx,g=rx,o=rx (symbolic)

# Set umask for a service (tighten permissions)
# In systemd unit file:
[Service]
UMask=0027   # service files will be 640/750
```

> **Code walkthrough:** This command sequence demonstrates a production diagnostic technique. KEY MECHANISM: shell pipelines connect command stdout to stdin via in-memory buffers; each command runs concurrently. WHY IT MATTERS: these patterns are immediately applicable to production debugging without installing additional tools. WHAT BREAKS: unquoted variables with spaces cause word-splitting and unexpected argument boundaries. TAKEAWAY: test commands interactively first, then wrap in scripts with `set -euo pipefail` at the top.

For security-sensitive services (handling PII, credentials), set
`UMask=0027` in the systemd unit to prevent world-readable file
creation by default.

*What separates good from great:* knowing the `UMask=` directive in
systemd unit files to set per-service umask without affecting the
system default.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ difficulty - single foundational concept; comparison table not required at this level.)*


---

### 🏛️ System Design

*(Omit: non-★★★ keyword - system design integration not applicable at this difficulty level.)*


---

### 📊 Diagram

*(Omit: command-reference topic - the concepts are demonstrated through code examples rather than visual diagrams.)*

