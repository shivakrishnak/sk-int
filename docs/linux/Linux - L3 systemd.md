---
layout: default
title: "Linux - L3 systemd"
parent: "Linux"
nav_order: 6
permalink: /linux/l3-systemd/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Difficulty |
|---|---------|------------|
| 14 | [systemd: Units, Services, and Journal](#systemd-units-services-and-journal) | ★★☆ |
| 15 | [Service Management and Auto-restart Patterns](#service-management-and-auto-restart-patterns) | ★★☆ |

---

# systemd: Units, Services, and Journal

**Interview Weight:** High - systemd is the init system on every major
Linux distribution; service management, troubleshooting crashed services,
and reading structured logs are tested in every backend/DevOps interview
at mid-level and above.

---

### 🎯 Model Answer

**30-second answer:**

"systemd is the Linux init system and service manager. It uses unit
files to define services, timers, and dependencies. `systemctl` manages
services: start/stop/enable/disable/status. `journalctl` queries the
structured binary log. The key diagnostic workflow is: `systemctl status
unit` shows recent logs and exit code, `journalctl -u unit -n 50` shows
history, and `systemd-analyze blame` shows what is slowing boot."

**3-minute answer:**

"systemd replaced SysV init and Upstart as the standard Linux init
system. It offers parallel service startup, dependency declaration,
socket activation, and structured logging via journald.

**Unit files** are the fundamental configuration: a `.service` file
defines how to run a process. Key fields: `ExecStart=` (the command),
`User=` (run as this user), `Restart=on-failure` (auto-restart), and
`After=network.target` (dependency ordering).

`systemctl status myservice` is the first diagnostic command. It shows:
current state (active/inactive/failed), the main PID, recent journal
output (last 10 lines), and the exit code if it failed.

`journalctl` queries the binary journal. `journalctl -u myservice`
shows all logs for the unit. `journalctl -u myservice --since '10 min
ago'` narrows the time range. `journalctl -f` follows live output.
`journalctl -p err` shows only error-level messages.

`systemd-analyze` reveals boot performance. `systemd-analyze blame`
shows which services took the longest to start. `systemd-analyze
critical-chain` shows the critical path that determined total boot time.

The unit dependency model: `Wants=` means 'start this if possible but
do not fail if it does not start'; `Requires=` means 'must start or I
fail'; `After=` controls ORDER but not whether it starts."

**Blank Mind Recovery:**

"systemctl status/start/stop/enable/disable/restart. journalctl -u UNIT
-n 50. Unit file: ExecStart, Restart=on-failure, After=. Boot analysis:
systemd-analyze blame."

---

### 📘 Concept Explanation

**What it is:**

systemd is a system and service manager that runs as PID 1 on modern
Linux. It manages the full lifecycle of services from boot to shutdown,
handles dependencies between services, socket activation, timer-based
job scheduling, and structured log collection via journald.

**Why it exists:**

Traditional init systems (SysV) started services sequentially using
shell scripts, causing slow boot times. Dependencies were implicit and
error-prone. systemd enables parallel startup of independent services
by explicitly declaring dependencies, dramatically reducing boot time.

**Core mental model:**

```
Unit Files (describe WHAT to run)
    |
    v
Dependency Graph (defines ORDER and CONDITIONAL logic)
    |
    v
Activation (starts units based on triggers: boot, socket, timer, dbus)
    |
    v
Journal (captures structured logs from every unit with metadata)
```

> **Diagram walkthrough:** This depicts systemd's architecture from
> declaration to execution. Unit files describe services declaratively;
> the dependency graph resolves start order; activation handles the
> triggers (boot, socket connection, timer); the journal captures all
> output with timestamps and unit metadata. The key insight: systemd's
> job is to resolve the dependency graph in parallel while respecting
> ordering constraints - it does NOT simply start units one by one.

**Key terminology:**

- **Unit**: any managed entity (.service, .timer, .socket, .target,
  .mount, .path, .device)
- **Target**: a synchronization point (like SysV runlevels); e.g.,
  `multi-user.target` replaces runlevel 3
- **Socket activation**: systemd creates the socket before the service
  starts; the service is started on first connection, reducing boot time
- **Journal**: systemd-journald collects logs from services (stdout/
  stderr), kernel (dmesg), and syslog, storing them as binary with
  structured fields
- **Unit states**: active, inactive, activating, deactivating, failed,
  maintenance

**How it works internally:**

1. systemd reads all unit files from `/etc/systemd/system/`,
   `/lib/systemd/system/`, and `/run/systemd/system/`
2. It builds a dependency graph using `After=`, `Before=`, `Requires=`,
   `Wants=`, and `Conflicts=` fields
3. It starts units in parallel where possible, respecting `After=` and
   `Before=` ordering constraints
4. For each service, it forks and execs the `ExecStart=` command with
   the specified User/Group/Environment
5. journald captures all stdout/stderr from each unit's process tree

**Trade-offs:**

| Aspect | Benefit | Cost |
|--------|---------|------|
| Parallel startup | Faster boot (seconds vs minutes for SysV) | More complex troubleshooting |
| Binary journal | Structured queries, indexed search | Not human-readable without journalctl |
| Dependency declaration | Explicit, verifiable | Verbose unit files vs simple scripts |
| Socket activation | Services start on demand | Delayed first-connection latency |

**Common failure patterns:**

- `ExecStart=` path wrong or binary missing
- `User=` doesn't exist or lacks permissions
- `After=` dependency never reaches active state (circular dependency)
- Journal disk full: services still start but log collection fails
- Unit file syntax error: `systemctl daemon-reload` reveals the issue

**Real-world usage:**

Every production Linux service (nginx, postgresql, java, docker) runs
as a systemd service. When a container's JVM crashes at 3 AM, the
on-call engineer's first command is `systemctl status myservice` to
see the crash context, exit code, and recent logs - all in one output.

**Scale considerations:**

At fleet scale (1000+ servers), systemd unit files are managed by
configuration management (Ansible, Chef, Puppet). Unit file changes
require `systemctl daemon-reload && systemctl restart service` on
each host. Fleet-wide service status checking uses tools like
`ansible -m shell -a 'systemctl is-active myservice'`.

---

### 💻 Code Example

**BAD: SysV-style manual daemon management**

```bash
# BAD: old pattern - manual PID file, no auto-restart
cat /etc/init.d/myservice
#!/bin/bash
# start-stop-daemon --start --pidfile /var/run/myservice.pid \
#   --exec /usr/bin/myservice
# No dependency management, no auto-restart, no structured logging
# If it crashes: nobody knows until monitoring fires 5 minutes later
```

> **Code walkthrough:** This illustrates the SysV init approach:
> shell scripts that manually invoke `start-stop-daemon` with PID
> files. KEY MECHANISM: PID files are written by the daemon itself;
> if the daemon crashes without cleaning up the PID file, the init
> script thinks it is still running. WHY IT MATTERS: this pattern
> has no structured logging, no auto-restart, and no dependency
> ordering beyond sequential execution. WHAT BREAKS: a stale PID
> file after a crash prevents the service from restarting on the
> next `service start` call. TAKEAWAY: never use SysV init scripts
> for new services; systemd unit files handle all of this correctly.

**GOOD: Complete systemd service unit file**

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application Server
Documentation=https://github.com/myorg/myapp
After=network-online.target postgresql.service
Wants=network-online.target
Requires=postgresql.service

[Service]
Type=simple
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp
EnvironmentFile=/etc/myapp/environment
ExecStart=/opt/myapp/bin/server --config /etc/myapp/config.yaml
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5s
StartLimitIntervalSec=60s
StartLimitBurst=3

# Hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ReadWritePaths=/var/lib/myapp /var/log/myapp

[Install]
WantedBy=multi-user.target
```

> **Code walkthrough:** This unit file demonstrates production-quality
> service configuration. KEY MECHANISM: `After=postgresql.service`
> ensures ordering (myapp starts after postgres), while `Requires=`
> ensures postgres is running (if postgres stops, myapp stops too).
> `Restart=on-failure` with `StartLimitBurst=3` allows 3 rapid restart
> attempts within `StartLimitIntervalSec=60s` before systemd gives up
> and marks the service failed (preventing crash loops). WHY IT MATTERS:
> the hardening directives (`NoNewPrivileges`, `PrivateTmp`, `ProtectSystem`)
> sandbox the service at the kernel level. WHAT BREAKS: `Requires=`
> creates a hard dependency - if postgres is unavailable for maintenance,
> myapp will also be stopped. TAKEAWAY: use `Wants=` for soft dependencies
> and `Requires=` for hard ones; incorrect dependency type is a common
> cause of unexpected service shutdowns during infrastructure changes.

**Diagnosis workflow: service crash investigation**

```bash
# Step 1: Initial status check (shows state, PID, recent 10 log lines)
systemctl status myapp.service
# ● myapp.service - My Application Server
#    Loaded: loaded (/etc/systemd/system/myapp.service; enabled)
#    Active: failed (Result: exit-code) since 2024-01-15 03:42:15 UTC
#   Process: 12345 ExecStart=/opt/myapp/bin/server (code=exited, status=1)
#  Main PID: 12345 (code=exited, status=1)
#
# Jan 15 03:42:15 server1 server[12345]: ERROR: database connection refused

# Step 2: Full log history for the unit
journalctl -u myapp.service --since "1 hour ago" --no-pager

# Step 3: Find the crash signature
journalctl -u myapp.service -p err --since today

# Step 4: Check if it is in a crash loop (failed to start N times)
journalctl -u myapp.service | grep -c "Started\|Failed"

# Step 5: After fixing root cause, restart and reset failure counter
systemctl reset-failed myapp.service
systemctl start myapp.service
```

> **Code walkthrough:** This diagnosis workflow shows the correct
> sequence for investigating a crashed service. KEY MECHANISM:
> `systemctl status` combines current state, PID, and recent logs
> into a single command output, eliminating the need to manually
> find and tail log files. `journalctl -u unit -p err` filters to
> error-level messages only, reducing noise. WHY IT MATTERS: the
> exit status code in the status output (`status=1`, `status=2/SIGTERM`)
> immediately tells you whether it was a crash (non-zero exit) or
> a shutdown (SIGTERM). WHAT BREAKS: forgetting `systemctl
> reset-failed` after fixing the root cause leaves the service in
> failed state and prevents auto-restart from working. TAKEAWAY:
> `systemctl reset-failed unit` is required after manually fixing
> a crashed service to clear the failed state before `systemctl start`.

**Journal querying: production log analysis**

```bash
# Show logs since last boot
journalctl -b

# Show logs for specific service, last 50 lines, following
journalctl -u myapp.service -n 50 -f

# Show error+ messages from ALL services
journalctl -p err

# Show logs between two timestamps
journalctl --since "2024-01-15 03:00:00" --until "2024-01-15 04:00:00"

# Show logs for a specific PID (useful after tracing crash)
journalctl _PID=12345

# Show kernel messages (dmesg equivalent, but persistent)
journalctl -k --since "1 hour ago"

# Export logs for incident post-mortem
journalctl -u myapp --since "2024-01-15" --until "2024-01-16" \
  -o json-pretty > incident.json
```

> **Code walkthrough:** These journalctl commands demonstrate
> the structured log query capabilities. KEY MECHANISM: the journal
> stores metadata fields (unit name, PID, priority, timestamp) as
> structured data, enabling efficient indexed queries; unlike grep
> on text files, journal queries filter at the storage layer. WHY
> IT MATTERS: `journalctl _PID=12345` finds all logs from a specific
> process even if the unit name changed, which is critical when
> investigating processes spawned dynamically. WHAT BREAKS: journal
> disk fill (`journalctl --disk-usage` > /var/log/journal limit)
> causes log rotation to drop old entries - check with `journalctl
> --disk-usage`. TAKEAWAY: prefer `journalctl -u unit --since TIME`
> over `grep` on log files; structured queries are faster and
> provide metadata that text grep cannot.

---

### 🎓 Answers by Seniority

**Junior / Mid-level answer:**

"systemd manages services on Linux. I use `systemctl start/stop/status
unit` to manage services. Unit files live in `/etc/systemd/system/`.
`journalctl -u servicename` shows logs. When a service crashes, I check
`systemctl status` to see the error and restart it."

*What's missing: no mention of dependency ordering, restart policies,
journal querying by severity, or the difference between enable and start.*

**Senior / Staff answer:**

"systemd's unit files declare dependencies, restart policies, and
security sandboxing. For production services I write unit files with
`Restart=on-failure`, `StartLimitBurst=3`, and dependency ordering
using `After=` and `Wants=`. When diagnosing crashes: `systemctl status`
for current state and recent logs, then `journalctl -u unit -p err
--since '1 hour ago'` for error history. For persistent crash loops,
check `StartLimitIntervalSec` - the service may be throttled. Reset
with `systemctl reset-failed` after root cause is fixed.

For boot performance, `systemd-analyze critical-chain` reveals the
longest dependency path. For socket-activated services, the service
only starts on first connection, improving boot time by deferring
startup. In fleet management, unit file deployment uses configuration
management tools followed by `daemon-reload && restart`."

---

### ⚠️ Common Misconceptions

**"enable and start are the same thing"**

`systemctl enable unit` creates a symlink in the appropriate target
directory, making the service start automatically at boot. `systemctl
start unit` starts it NOW in the current session. A service can be
enabled (starts at boot) but currently stopped, or started but not
enabled (will not survive reboot). Production services should be
both enabled AND started.

**"journalctl logs are in /var/log/messages"**

Traditional syslog writes to `/var/log/messages` and similar files.
journald writes to `/var/log/journal/` (if the directory exists) or
`/run/log/journal/` (in-memory, lost on reboot) as binary files.
Services that write to stdout/stderr are captured by journald, not
syslog. To forward journal to syslog, install `rsyslog` with the
`imjournal` module.

**"After=X means X starts first"**

`After=X` only controls ordering: if both units are starting, X starts
before this unit. It does NOT cause X to start. To both require and
order, use `After=X` AND either `Requires=X` (hard) or `Wants=X` (soft).
A common mistake: adding `After=postgresql.service` without `Requires=`
means the app starts even if postgres is down.

**"Restart=always is the best restart policy"**

`Restart=always` restarts even when the service exits with code 0
(intentional shutdown). This prevents `systemctl stop` from working -
the service restarts immediately. For daemons that should restart only
after crashes, use `Restart=on-failure`. Use `Restart=always` only for
intentionally persistent services where any exit is an error.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Service in failed state, will not restart**

```bash
# Symptom: systemctl status shows "failed" and service won't start
systemctl status myapp.service
# Active: failed (Result: start-limit-hit) since ...
# systemd: myapp.service: Start request repeated too quickly.
# systemd: myapp.service: Failed with result 'start-limit-hit'.
```

> **Code walkthrough:** `start-limit-hit` means the service crashed
> and restarted faster than `StartLimitBurst` allows within
> `StartLimitIntervalSec`. KEY MECHANISM: after N restarts in T
> seconds, systemd stops trying and marks the service as failed to
> prevent rapid crash loops from consuming resources. WHY IT MATTERS:
> without this limit, a service with a startup bug would consume 100%
> CPU restarting thousands of times per minute. WHAT BREAKS: forgetting
> `systemctl reset-failed` after fixing the root cause leaves the
> service permanently in failed state. TAKEAWAY: `systemctl reset-failed
> unit` clears the start limit counter; investigate root cause FIRST,
> fix it, THEN reset and restart.

Diagnosis:
```bash
# See WHY it failed (the actual exit code and error)
journalctl -u myapp.service -n 100 | grep -i "error\|fatal\|exit\|failed"

# Check if it is a configuration issue
systemd-analyze verify /etc/systemd/system/myapp.service

# Reset failure state after fixing root cause
systemctl reset-failed myapp.service
systemctl start myapp.service
```

> **Code walkthrough:** `systemd-analyze verify` checks the unit file
> for syntax errors and missing dependencies without starting the service.
> KEY MECHANISM: it validates the unit file structure, checks that
> referenced executables exist, and verifies dependency unit names.
> WHY IT MATTERS: a syntax error in a unit file causes `systemctl
> daemon-reload` to silently accept the file but then fail to start
> the service. WHAT BREAKS: not running `daemon-reload` after editing
> a unit file means the old version is still loaded. TAKEAWAY: always
> run `systemctl daemon-reload` after editing unit files, and verify
> with `systemd-analyze verify` before restarting the service.

**Failure 2: Service starts but journald is not capturing logs**

Symptom: `journalctl -u myapp` shows only systemd messages, not
application output.

Cause: The service forks to background (`Type=forking`) but the
journald file descriptor is connected to the parent, not the daemon.

Fix: Use `Type=simple` and do NOT daemonize the process (remove
`--daemon` flags). Modern daemons should not fork; systemd provides
all the benefits of daemonization (service management, PID tracking)
without the process needing to fork.

**Failure 3: Circular dependency causing boot hang**

Symptom: boot hangs for 90 seconds then the service times out.

Diagnosis:
```bash
systemd-analyze plot > boot.svg
# Open boot.svg to see dependency graph visualization
systemd-analyze critical-chain myapp.service
```

> **Code walkthrough:** `systemd-analyze plot` generates an SVG
> showing the complete boot timeline as a Gantt chart with all
> service start/end times and dependencies. KEY MECHANISM: it reads
> the journal's boot timeline data and renders it graphically.
> WHY IT MATTERS: a 90-second timeout during boot is almost always
> a circular dependency or a `network-online.target` dependency that
> waits for DHCP/cloud metadata. WHAT BREAKS: `systemd-analyze plot`
> requires the journal to have data from the current boot.
> TAKEAWAY: use `systemd-analyze critical-chain unit` to find the
> longest dependency path; optimize the critical path, not random
> services.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | unit types, dependency model, journal |
| Debugging | 3 | crash loops, missing logs, boot issues |
| Trade-off | 2 | Requires vs Wants, enable vs start |
| Production | 1 | fleet management |

---

**[JUNIOR] Q1 - What is the difference between systemctl enable and systemctl start?**

`systemctl start unit` activates the unit immediately in the current
boot session. The unit runs now, but will NOT automatically start on
the next reboot unless it is also enabled.

`systemctl enable unit` creates the symlinks (or drop-in files) that
tell systemd to activate the unit at the appropriate target during boot.
The unit does NOT start immediately - it only takes effect on next boot.

Common patterns:
- `systemctl enable --now unit`: enables AND starts in one command
- `systemctl disable --now unit`: disables AND stops in one command
- `systemctl is-enabled unit`: check if set to start at boot
- `systemctl is-active unit`: check if currently running

A newly installed service must be both enabled AND started:
```bash
systemctl daemon-reload              # reload after unit file changes
systemctl enable myapp.service       # start at boot
systemctl start myapp.service        # start now
```

> **Code walkthrough:** This sequence shows the correct service
> deployment workflow. KEY MECHANISM: `daemon-reload` signals systemd
> to re-read unit files from disk; without it, systemd uses the cached
> version. `enable` creates a symlink in `multi-user.target.wants/`
> (or equivalent) that tells systemd to include this unit in the boot
> target. WHY IT MATTERS: `enable` without `start` means the service
> will not run until next reboot; `start` without `enable` means it
> will not survive a reboot. WHAT BREAKS: deploying a unit file
> without `daemon-reload` means systemctl uses the old definition.
> TAKEAWAY: the deployment sequence is always: edit unit file,
> `daemon-reload`, `enable --now` or `enable` + `restart`.

*What separates good from great:* understanding that `enable` creates
symlinks in target directories (e.g., `/etc/systemd/system/multi-user.
target.wants/myapp.service`) and that `daemon-reload` is required after
any unit file modification, not just new files.

---

**[JUNIOR] Q2 - What is the difference between Wants= and Requires= in a unit file?**

Both specify dependencies - units that should be active when this unit
is active. The difference is the failure behavior:

`Wants=other.service`: weak dependency. systemd starts `other.service`
when this unit starts, but if `other.service` fails to start or crashes,
THIS unit continues running. The dependency is "try to start this, but
continue anyway."

`Requires=other.service`: strong dependency. If `other.service` fails
to start or is stopped, THIS unit is also stopped. They are coupled.

`Wants=` is almost always the right choice because:
- Hard dependencies (Requires=) cause cascading failures during
  maintenance (stopping postgres stops your app)
- Soft dependencies (Wants=) allow the app to handle the missing
  service with a proper error message rather than being killed

Combined with `After=`:
- `After=postgresql.service Requires=postgresql.service`: app starts
  after postgres AND must stop if postgres stops
- `After=postgresql.service Wants=postgresql.service`: app starts
  after postgres when postgres is starting, but does not require it

*What separates good from great:* knowing that `After=` alone does NOT
start the dependency - it only affects order. A service with only
`After=postgresql.service` (no Wants= or Requires=) will start after
postgres IF postgres is being started for another reason, but will NOT
cause postgres to start if it is not already running.

---

**[MID] Q3 - A production service is failing with start-limit-hit. What is the correct diagnosis and fix procedure?**

`start-limit-hit` means the service crashed and was restarted more than
`StartLimitBurst` times within `StartLimitIntervalSec` seconds. systemd
stops retrying to prevent crash loops.

Correct procedure:

1. **Do NOT immediately reset and restart** - find the root cause first:
   ```bash
   journalctl -u myservice -n 200 --no-pager
   # Look for the error just before each crash:
   # "FATAL: ...", "OOM Killed", "permission denied", etc.
   ```

   > **Code walkthrough:** `journalctl -u myservice -n 200 --no-pager`
   > fetches the last 200 log entries without piping to a pager.
   > KEY MECHANISM: journald indexes by unit name, so this query is
   > O(log n) not O(file size). WHY IT MATTERS: the error message
   > immediately before the crash exit is the root cause; without
   > logs, you are guessing. WHAT BREAKS: if persistent journal is
   > not enabled, logs are lost on reboot; check `/var/log/journal/`
   > exists. TAKEAWAY: always check logs before resetting failure state.
  
  2. **Identify the failure pattern:**
     ```bash
     # Count how many times it started vs failed
     journalctl -u myservice | grep -c "Started\|Failed"
     # See the exit codes
     journalctl -u myservice | grep "exit-code\|killed"
     ```

   > **Code walkthrough:** Counting Start/Failed pairs reveals whether
   > this is a crash loop or a single failure. KEY MECHANISM: systemd
   > logs 'Started' and 'Failed' messages to journald for each
   > activation attempt. WHY IT MATTERS: a service that failed once
   > needs root cause fix; a service in a crash loop needs both fix
   > AND `StartLimitBurst` tuning. WHAT BREAKS: grepping only for
   > 'Failed' misses services that start then quickly crash (showing
   > as 'Started' then 'Failed' in rapid succession). TAKEAWAY: the
   > Started/Failed ratio reveals crash frequency at a glance.
  
  3. **Fix the root cause** (missing dependency, configuration error,
     OOM, permission issue)
  
  4. **Reset the failure counter** AFTER fixing:
     ```bash
     systemctl reset-failed myservice
     systemctl start myservice
     ```

   > **Code walkthrough:** `systemctl reset-failed` clears the
   > start-limit-hit state that prevents further restart attempts.
   > KEY MECHANISM: systemd tracks a start counter per unit; once
   > the limit is hit, the unit enters 'failed' state which blocks
   > automatic restarts. `reset-failed` zeroes the counter. WHY IT
   > MATTERS: without this, the service stays permanently in failed
   > state even after fixing the root cause. WHAT BREAKS: resetting
   > without fixing root cause just triggers another crash loop.
   > TAKEAWAY: reset-failed is the LAST step, not the first response.

5. **Tune restart limits** to allow recovery from transient spikes:
   ```ini
   StartLimitBurst=10
   RestartSec=30s
   ```

> **Code walkthrough:** Step 5's unit file additions increase the
> allowed crash frequency. KEY MECHANISM: systemd counts restarts
> within the `StartLimitIntervalSec` window; after `StartLimitBurst`
> restarts, it stops. `RestartSec=30s` adds a delay between restart
> attempts to prevent rapid loops. WHY IT MATTERS: a 30-second
> restart delay gives dependent services time to recover before the
> failing service retries. WHAT BREAKS: setting `StartLimitBurst=0`
> (unlimited) allows infinite crash loops that can consume all CPU.
> TAKEAWAY: the default limits (5 restarts in 10 seconds) are
> intentionally conservative; increase them only for services that
> have known transient startup issues like waiting for external
> resources.

*What separates good from great:* understanding that `systemctl
reset-failed` without fixing the root cause just triggers another
crash loop - the proper procedure is always root-cause analysis first,
then reset.

---

**[MID] Q4 - How do you view and query logs for a crashed service after it has restarted?**

journald persists logs across service restarts (and across reboots if
`/var/log/journal/` directory exists). This is the primary advantage
over stderr-only logging.

```bash
# All logs from this service ever (may be very long)
journalctl -u myapp.service

# Logs since last boot only
journalctl -u myapp.service -b

# Last 1 hour only
journalctl -u myapp.service --since "1 hour ago"

# Logs from a specific boot (use -b -1 for previous boot)
journalctl -u myapp.service -b -1

# Show logs with priority err and above (err, crit, alert, emerg)
journalctl -u myapp.service -p err

# Show what happened just before the crash
journalctl -u myapp.service -n 100 --no-pager | tail -50

# Find the exact crash time from journal
journalctl -u myapp.service | grep "Stopping\|Killed\|exit code"
```

> **Code walkthrough:** `journalctl -b -1` queries the previous boot's
> journal - critical for diagnosing crashes that caused a system reboot.
> KEY MECHANISM: journald uses sequence numbers to mark boot boundaries;
> `-b -1` means "previous boot session", `-b -2` is two boots ago.
> WHY IT MATTERS: without persistent journaling, crash logs disappear
> on reboot; with `/var/log/journal/` existing, all historical logs
> are preserved. WHAT BREAKS: if `/var/log/journal/` does not exist
> (the default on some distributions), logs are only stored in
> `/run/log/journal/` and lost on reboot. TAKEAWAY: create
> `/var/log/journal/` and run `systemctl restart systemd-journald`
> to enable persistent logging on systems where it is disabled by default.

*What separates good from great:* knowing that `journalctl -b -1`
queries the previous boot's logs, enabling post-reboot crash analysis
without needing to have set up separate log forwarding beforehand.

---

**[SENIOR] Q5 - How does socket activation work and when should you use it?**

Socket activation lets systemd create and hold a socket, then start
the service only when the first connection arrives. The service
receives the pre-created socket as a file descriptor at startup.

Benefits:
1. **Faster boot**: service binary is not started until first use
2. **Crash resilience**: if the service crashes, incoming connections
   queue in the kernel socket buffer; systemd automatically restarts
   the service and hands back the socket - NO connections are lost
3. **Parallel activation**: multiple services can start simultaneously
   since systemd creates all sockets before starting any services

Configuration:
```ini
# myapp.socket
[Unit]
Description=My App Socket

[Socket]
ListenStream=8080
Accept=no    # pass socket to service (not one process per connection)

[Install]
WantedBy=sockets.target
```

```ini
# myapp.service (activated by myapp.socket)
[Unit]
Description=My App Service
Requires=myapp.socket

[Service]
ExecStart=/opt/myapp/server
StandardInput=socket
```

> **Code walkthrough:** The `.socket` unit creates the listening socket;
> `Accept=no` means systemd passes the one socket FD to the service
> when any connection arrives. KEY MECHANISM: the service receives the
> pre-bound socket via `SD_LISTEN_FDS` environment variable (set to 1)
> and the actual file descriptor number (starts at 3). The service
> calls `sd_listen_fds()` to get the FD instead of calling `bind()`.
> WHY IT MATTERS: during a crash-and-restart, the socket stays open
> in systemd; clients see a brief connection delay but no connection
> refused. WHAT BREAKS: services that call `bind()` themselves cannot
> use socket activation; they must be modified to use the passed FD.
> TAKEAWAY: socket activation is the correct pattern for services
> where zero-downtime restart is required and crash resilience matters.

*What separates good from great:* understanding the crash resilience
property - connections queue in the kernel socket buffer while systemd
restarts the service, so clients see latency but not connection refusal,
which is a significant improvement over services that bind their own socket.

---

**[SENIOR] Q6 - What security hardening options does systemd provide in unit files?**

systemd provides kernel-level sandboxing options that apply syscall
filtering, filesystem isolation, and privilege restrictions without
requiring changes to the application code.

Key hardening directives:

```ini
[Service]
# Prevent gaining new privileges via setuid binaries
NoNewPrivileges=yes

# Private /tmp that is invisible to other services
PrivateTmp=yes

# Read-only access to most of the filesystem
ProtectSystem=strict
ReadWritePaths=/var/lib/myapp /var/log/myapp

# Hide /home from the service
ProtectHome=yes

# Prevent writing to /proc and /sys
ProtectKernelTunables=yes
ProtectKernelModules=yes

# Drop all capabilities not needed
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

# Restrict to specific syscalls (most restrictive)
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

# Run as non-root user
User=myapp
Group=myapp
DynamicUser=yes   # create ephemeral user automatically
```

> **Code walkthrough:** These directives use Linux kernel security
> mechanisms: `PrivateTmp` uses mount namespaces to give the process
> an isolated `/tmp`; `ProtectSystem=strict` mounts the root filesystem
> read-only; `SystemCallFilter` uses seccomp-bpf to block syscalls not
> in the `@system-service` set. KEY MECHANISM: these are applied using
> Linux namespaces and seccomp before the service's ExecStart executes,
> with no changes to the application. WHY IT MATTERS: a compromised
> service with these restrictions cannot access other services' temp
> files, write to system directories, or make kernel API calls beyond
> normal service operations. WHAT BREAKS: some applications call
> syscalls outside `@system-service`; verify with `systemd-analyze
> security myapp.service` before enabling syscall filtering.
> TAKEAWAY: run `systemd-analyze security unit` to get a security
> score and specific recommendations for any service; it is the fastest
> way to improve service isolation.

*What separates good from great:* knowing that `DynamicUser=yes`
creates an ephemeral user with a dynamically allocated UID that does
not appear in `/etc/passwd`, automatically enables `PrivateTmp`,
`RemoveIPC`, and `ProtectHome`, and provides excellent isolation
without requiring manual user management.

---

**[SENIOR] Q7 - How do you use systemd-analyze to diagnose and optimize boot performance?**

`systemd-analyze` provides multiple views of boot performance.

```bash
# Total boot time breakdown
systemd-analyze
# Startup finished in 2.891s (kernel) + 4.012s (initrd) + 8.421s (userspace)
# = 15.324s

# Which services took longest (sorted by elapsed time)
systemd-analyze blame
# 4.821s NetworkManager-wait-online.service
# 2.215s postgresql.service
# 1.984s docker.service

# The critical dependency chain (what actually blocked boot)
systemd-analyze critical-chain
# The time after the unit is active or started is printed after the "@" character.
# The time the unit takes to start is printed after the "+" character.
# multi-user.target @12.432s
# └─myapp.service @11.001s +1.431s
#   └─postgresql.service @8.785s +2.213s
#     └─network-online.target @8.784s

# Generate SVG boot timeline (comprehensive visualization)
systemd-analyze plot > /tmp/boot.svg
```

> **Code walkthrough:** `systemd-analyze blame` shows cumulative time,
> not real impact - a service taking 4 seconds that started in parallel
> with others may not be on the critical path. KEY MECHANISM:
> `critical-chain` shows the actual bottleneck by tracing the longest
> dependency chain from boot start to `multi-user.target`. WHY IT
> MATTERS: optimizing the longest service (by blame) is often
> irrelevant; optimizing what is on the critical chain gives actual
> boot time improvements. WHAT BREAKS: `NetworkManager-wait-online`
> at 4+ seconds is almost always the boot bottleneck on cloud VMs
> with DHCP; disabling it or switching to `network.target` (which
> does not wait for IP assignment) often cuts boot time in half.
> TAKEAWAY: always use `critical-chain` not `blame` for optimization;
> the critical chain is what must be made faster to reduce total boot time.

*What separates good from great:* recognizing that
`NetworkManager-wait-online.service` is the most common boot
bottleneck and that switching app dependencies from
`network-online.target` to `network.target` (which activates
immediately when interfaces come up, not when they get IPs) can
reduce cloud VM boot time by 5-10 seconds.

---

### ⚖️ Comparison Table

| Aspect | systemd | SysV init | Upstart |
|--------|---------|-----------|---------|
| Startup model | Parallel with dependencies | Sequential shell scripts | Event-based, partly parallel |
| Dependency declaration | Explicit in unit files | Numeric priority in script names | Events in Upstart jobs |
| Log collection | journald (structured binary) | Redirected to files | Redirected to files |
| Auto-restart | Built-in (Restart= field) | Manual (infinite loop in script) | Limited (respawn) |
| Resource control | cgroups via unit file | None (ulimit only) | None |
| Socket activation | Yes (native) | No | No |
| Security sandboxing | Yes (syscall, namespace, cap) | No | No |
| Status/diagnosis | systemctl + journalctl | Custom per-distro | initctl |

---

### 🏛️ System Design

*(Omit: ★★☆ systemd operational keyword - system design for service
orchestration at scale is covered at L4+ in the infrastructure
and Kubernetes topics.)*

---

### 📊 Diagram

*(Omit: the unit dependency and packet flow diagrams are provided
inline in the Code Example section; an additional architectural
diagram would be redundant for this command-reference topic.)*

---

---

# Service Management and Auto-restart Patterns

**Interview Weight:** High - restart policies and service dependencies
are daily operational knowledge; interviewers expect candidates to
correctly configure auto-restart without causing crash loops or
cascading failures.

---

### 🎯 Model Answer

**30-second answer:**

"systemd restart policies: `Restart=on-failure` restarts only on
non-zero exit or signal (not on clean exit). `RestartSec=` sets delay
between restarts. `StartLimitBurst=` limits restart attempts. For
zero-downtime restarts, use `systemctl reload` (SIGHUP for config
reload) or `systemctl restart` with `TimeoutStopSec` for graceful
shutdown. For dependencies, `After=` controls order, `Requires=` means
must-start-or-fail, `Wants=` means best-effort."

**3-minute answer:**

"Production service management involves three concerns: reliable
auto-restart after crashes, graceful shutdown to avoid dropping
connections, and dependency ordering to prevent start-before-ready
races.

For auto-restart, `Restart=on-failure` is the standard. Combined with
`RestartSec=5s` (wait 5 seconds before retrying) and `StartLimitBurst=3`
(give up after 3 rapid failures), this creates a crash loop protection
pattern. Without `RestartSec`, a service that fails immediately will
restart hundreds of times per minute.

For graceful shutdown, `ExecStop=/bin/kill -TERM $MAINPID` sends
SIGTERM to the main process. `TimeoutStopSec=30s` gives the service 30
seconds to shut down before systemd sends SIGKILL. Well-behaved services
handle SIGTERM by completing in-flight requests before exiting.

For live config reload without restart, `ExecReload=/bin/kill -HUP
$MAINPID` sends SIGHUP which most daemons interpret as 'reload config'.
This is faster and less risky than a full restart.

`Type=notify` is the production-grade service type where the service
calls `sd_notify(READY=1)` when it is ready to receive connections.
This prevents the race condition where systemd considers a service
active before it has actually finished initialization."

**Blank Mind Recovery:**

"Restart=on-failure. RestartSec=5s. StartLimitBurst=3.
ExecReload=kill -HUP $MAINPID. Type=notify for startup readiness.
TimeoutStopSec=30s for graceful shutdown. Wants=soft, Requires=hard."

---

### 📘 Concept Explanation

**What it is:**

The systemd restart and lifecycle management system: policies that
define when a failed service restarts, how long to wait between
attempts, how many attempts are allowed, and how to correctly signal
a service to reload configuration or shut down gracefully.

**Why it exists:**

Without automatic restart, a service crash at 3 AM requires manual
intervention. Without restart throttling, a misconfigured service
crash-loops at full speed, consuming CPU and potentially causing OOM.
Without graceful shutdown semantics, a service restart drops all
in-flight connections.

**Core mental model:**

```
Service Lifecycle:
                              crash
activating --[ExecStart]--> active --[Restart policy]---> restarting
                               |                               |
                          [ExecStop]                    [RestartSec delay]
                               |                               |
                          deactivating <-------- inactive <----+
                               |                   (start-limit check)
                           inactive
```

> **Diagram walkthrough:** This state machine shows how systemd
> manages a service's lifecycle. A service moves from `activating`
> to `active` after `ExecStart` succeeds. On crash, the restart
> policy determines whether to move to `restarting` (with a
> `RestartSec` delay) or to `failed` (if start-limit is exceeded).
> The key relationship: `RestartSec` governs the delay between
> `restarting` and back to `activating`. When `StartLimitBurst` is
> exceeded within `StartLimitIntervalSec`, the service enters `failed`
> state and stops attempting. The senior insight: `failed` is NOT a
> terminal state - `systemctl reset-failed` clears it and allows
> future restarts.

**Key terminology:**

- **Restart=on-failure**: restart when exit code != 0 or terminated
  by signal; does NOT restart on clean exit (code 0)
- **Restart=always**: restart on any exit including clean (code 0);
  prevents `systemctl stop` from working permanently
- **RestartSec**: wait time between restart attempts (default: 100ms)
- **StartLimitIntervalSec**: time window for counting restart attempts
- **StartLimitBurst**: maximum restarts within `StartLimitIntervalSec`
- **Type=notify**: service calls `sd_notify(READY=1)` when truly ready
- **Type=oneshot**: runs a command once and exits (for cron-like tasks)

**How it works internally:**

When a service exits with a non-zero code and `Restart=on-failure`:
1. systemd waits `RestartSec` seconds
2. Checks the start limit counter; if exceeded, marks service `failed`
3. If within limit, increments the restart counter and starts
   `ExecStart=` again
4. If the service runs for more than `RestartSec * StartLimitBurst`,
   the counter resets (indicating a successful run)

**Trade-offs:**

| Restart policy | When to use | Risk |
|----------------|-------------|------|
| `Restart=no` | Dev/test; manual restart preferred | No auto-recovery |
| `Restart=on-failure` | Production services | May mask bad bugs |
| `Restart=always` | Services that must never stop | Cannot `systemctl stop` |
| `Restart=on-abnormal` | Crash only (not timeout) | May miss some failures |

**Real-world usage:**

A Spring Boot application with a database connection pool: at startup,
it tries to connect to the database. If the database is not ready yet,
the app exits with code 1. `Restart=on-failure` with `RestartSec=10s`
retries every 10 seconds, waiting for the database. This is the correct
pattern for services that can fail at startup due to dependencies not
yet being ready.

---

### 💻 Code Example

**BAD: No restart policy, no graceful shutdown**

```ini
[Unit]
Description=My App (bad configuration)

[Service]
ExecStart=/opt/myapp/server

[Install]
WantedBy=multi-user.target
```

> **Code walkthrough:** This minimal unit file has no restart policy
> (defaults to `Restart=no`), no timeout for graceful shutdown, and
> no startup type declaration. KEY MECHANISM: if the server crashes,
> it stays down forever; if stopped, systemd sends SIGTERM immediately
> without waiting; if startup is slow, systemd may consider it failed
> before it is ready. WHY IT MATTERS: production services require at
> minimum `Restart=on-failure` and a `TimeoutStopSec` to prevent
> connection drops on restart. WHAT BREAKS: without `TimeoutStopSec`,
> the default 90-second timeout may kill the service mid-request.
> TAKEAWAY: never deploy a unit file without at minimum `Restart=`,
> `RestartSec=`, and `TimeoutStopSec=` for production services.

**GOOD: Complete restart and lifecycle configuration**

```ini
[Unit]
Description=My App (production configuration)
After=network-online.target postgresql.service
Wants=network-online.target
Requires=postgresql.service

[Service]
Type=notify          # service calls sd_notify(READY=1) when ready
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp
EnvironmentFile=/etc/myapp/environment

ExecStart=/opt/myapp/bin/server
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -TERM $MAINPID

# Restart policy: retry on crash, limit rapid restart loops
Restart=on-failure
RestartSec=10s
StartLimitIntervalSec=120s
StartLimitBurst=5

# Graceful shutdown: wait up to 30 seconds before SIGKILL
TimeoutStopSec=30s
TimeoutStartSec=60s   # startup must complete in 60s

# Resource limits
LimitNOFILE=65536     # increase file descriptor limit

[Install]
WantedBy=multi-user.target
```

> **Code walkthrough:** `Type=notify` prevents the race condition
> where systemd considers the service active before it has finished
> initialization - the service binary must call `sd_notify("READY=1")`
> when it is genuinely ready to serve requests. KEY MECHANISM:
> `StartLimitBurst=5` within `StartLimitIntervalSec=120s` means the
> service can restart up to 5 times in 2 minutes before systemd
> gives up; `RestartSec=10s` ensures 10 seconds between attempts,
> so 5 attempts = minimum 40 seconds before giving up, allowing
> transient issues (like a slow database startup) to resolve.
> WHY IT MATTERS: `TimeoutStopSec=30s` gives in-flight requests
> up to 30 seconds to complete before SIGKILL forces termination.
> WHAT BREAKS: `Type=notify` requires the application to implement
> sd_notify; if it does not, the service will timeout waiting for
> READY=1. TAKEAWAY: use `Type=notify` for stateful services that
> have a real initialization phase; fall back to `Type=simple` for
> services that are ready immediately on process start.

**Implementing sd_notify in a Spring Boot application**

```java
// Add dependency: com.github.jnr:jnr-posix or use systemd-java
// Or the simplest approach: use the /run/systemd/notify socket directly

// pom.xml dependency
// <dependency>
//   <groupId>com.github.jkugiya</groupId>
//   <artifactId>systemd-java</artifactId>
//   <version>1.0.4</version>
// </dependency>

@SpringBootApplication
public class Application implements CommandLineRunner {
    @Override
    public void run(String... args) throws Exception {
        // Application startup logic...
        initializeConnectionPools();
        registerWithServiceDiscovery();
        // Only AFTER all initialization is complete:
        SystemDaemon.notify("READY=1");
    }
}
```

> **Code walkthrough:** `sd_notify("READY=1")` writes to the
> `NOTIFY_SOCKET` environment variable path, which is set by
> systemd to a Unix socket that it is listening on. KEY MECHANISM:
> systemd blocks the service activation until it receives the
> READY=1 message, ensuring that any service with `Requires=myapp`
> does not start until myapp has truly finished initialization.
> WHY IT MATTERS: without notify, dependent services may start
> while myapp is still warming up its connection pools, causing
> connection refused errors. WHAT BREAKS: if `NOTIFY_SOCKET` is
> not set (not running under systemd), `sd_notify` silently
> does nothing - it is safe to call unconditionally. TAKEAWAY:
> implement `sd_notify("READY=1")` in any service that has a
> non-trivial startup phase to prevent dependent service race
> conditions.

**Zero-downtime configuration reload**

```bash
# Reload nginx configuration without dropping connections
systemctl reload nginx
# nginx receives SIGHUP, re-reads config, gracefully replaces workers
# All existing connections finish on old workers
# New connections go to new workers with new config

# For Java apps that support hot reload via JMX or custom signal:
systemctl reload myapp  # sends SIGHUP, app reloads config

# Check if reload succeeded
systemctl status myapp
```

> **Code walkthrough:** `systemctl reload unit` sends the signal
> specified in `ExecReload=` (SIGHUP by default). KEY MECHANISM:
> SIGHUP was historically the "hangup" signal for terminal disconnect
> but daemons repurposed it as a "reload configuration" convention.
> The service handles SIGHUP by re-reading its config file while
> keeping the main process running and all connections open. WHY IT
> MATTERS: `systemctl restart` causes a brief period where no
> process is listening; reload avoids this window entirely. WHAT
> BREAKS: not all applications handle SIGHUP; Java applications
> without explicit SIGHUP handler will terminate on SIGHUP. TAKEAWAY:
> check the application documentation for SIGHUP support before
> using `ExecReload=kill -HUP $MAINPID`; for Java, use JMX or an
> application-level reload endpoint instead.

---

### 🎓 Answers by Seniority

**Junior / Mid-level answer:**

"I use `Restart=on-failure` to auto-restart services that crash. I
set a `RestartSec` to avoid crash loops. `systemctl restart` restarts
a service and `systemctl reload` sends SIGHUP for config reload."

*What's missing: no mention of `Type=notify`, `StartLimitBurst`,
graceful shutdown semantics, or preventing cascading failures.*

**Senior / Staff answer:**

"Auto-restart configuration has three components: the trigger
(`Restart=on-failure`), the delay (`RestartSec=10s`), and the
circuit breaker (`StartLimitBurst=5` within `StartLimitIntervalSec=120s`).
Without the circuit breaker, a persistent failure causes infinite
rapid restarts. With it, systemd gives up after 5 attempts in 2
minutes, preventing crash loops from consuming resources.

`Type=notify` is the correct type for services with real initialization
phases - the service calls `sd_notify(READY=1)` when ready, preventing
dependent services from starting too early. `TimeoutStopSec=30s` allows
30 seconds for graceful shutdown before SIGKILL.

For zero-downtime deployment, the pattern is: deploy new binary, then
`systemctl restart --wait myapp` which waits for the new process to
send `READY=1` before returning. If the new version fails to start,
the restart fails and the old process was already stopped - this is why
blue-green deployment is safer than in-place restart for critical services."

---

### ⚠️ Common Misconceptions

**"Restart=always ensures the service is always running"**

`Restart=always` prevents `systemctl stop` from stopping the service
permanently - systemd will restart it. But `StartLimitBurst` still
applies: after too many rapid restarts, systemd gives up and marks it
`failed`. `Restart=always` is appropriate for services where ANY exit
is unexpected and should trigger a restart. For services with legitimate
clean exit paths (like batch jobs), use `Restart=on-failure`.

**"Type=simple is the same as Type=forking"**

`Type=simple` (default) tells systemd the process launched by
`ExecStart=` IS the main service process; its PID is tracked directly.
`Type=forking` tells systemd the process will fork to background and
the parent exits; systemd reads the PID from `PIDFile=`. If your
service daemonizes (forks) and you use `Type=simple`, systemd tracks
the wrong PID and considers the service dead when the parent exits.
Never daemonize; use `Type=simple` and let systemd manage the process.

**"TimeoutStopSec is for graceful shutdown - just set it high"**

`TimeoutStopSec` is a MAXIMUM wait, not a signal delay. systemd sends
SIGTERM immediately when you call `systemctl stop`, then waits
`TimeoutStopSec` for the service to exit. If it does not exit in time,
SIGKILL is sent. Setting it high does not make shutdown more graceful;
the service must implement SIGTERM handling to finish in-flight requests
and exit cleanly.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Service restarts but fails to connect to database**

Pattern: app exits with code 1 immediately after restart because the
database connection fails at startup.

```bash
# Check restart timing
journalctl -u myapp --since "1 hour ago" | grep "Started\|Failed"
# If start-stop cycles are every 10 seconds: RestartSec=10s working correctly
# Root cause: app tries database connection at startup, fails, exits

# Fix Option 1: make the app retry internally (better)
# Application should retry database connection with backoff

# Fix Option 2: use ExecStartPre to wait for database
# In unit file:
# ExecStartPre=/bin/sh -c 'until pg_isready -h db -p 5432; do sleep 2; done'
```

> **Code walkthrough:** `ExecStartPre=` runs a command before
> `ExecStart=`; if it fails, the service does not start. Using
> `until pg_isready` loops until PostgreSQL responds on the specified
> host and port. KEY MECHANISM: this converts a crash-restart loop
> into a controlled wait in the pre-start phase. WHY IT MATTERS:
> without pre-start wait, each crash consumes one `StartLimitBurst`
> counter, eventually hitting the limit. WHAT BREAKS: if the database
> is permanently down, the pre-start loop runs forever, keeping the
> service in `activating` state indefinitely. TAKEAWAY: add a timeout
> to the loop: `timeout 60 sh -c 'until pg_isready ...; do sleep 2;
> done'` to limit the wait.

**Failure 2: Service crash-loops on startup due to resource limits**

```bash
# Symptom: service fails immediately with SIGKILL (code=killed, status=9)
systemctl status myapp
# Process: 12345 (code=killed, status=9/KILL)

# Check if OOM killer killed it
journalctl -k | grep -i "oom\|killed process"
# kernel: Out of memory: Killed process 12345 (java) ...

# Or: insufficient file descriptors
journalctl -u myapp | grep "Too many open files"
# Fix: add to [Service]:
# LimitNOFILE=65536
```

> **Code walkthrough:** `LimitNOFILE=65536` sets the per-process
> file descriptor limit to 65536 (the Linux soft default is 1024).
> KEY MECHANISM: `LimitNOFILE` sets both soft and hard limits in the
> systemd-managed cgroup; it overrides `/etc/security/limits.conf`
> for systemd-managed services. WHY IT MATTERS: Java and Node.js
> applications in production typically open thousands of sockets and
> file handles; the default 1024 limit causes "too many open files"
> errors under load. WHAT BREAKS: setting `LimitNOFILE` too high
> (e.g., 1048576) on systems with many services can exhaust the
> system-wide file descriptor table. TAKEAWAY: set `LimitNOFILE=65536`
> (or `LimitNOFILE=infinity` for high-connection services) in any
> production unit file for Java, Node.js, or Go services.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | restart policies, Type=notify, dependencies |
| Debugging | 3 | crash loops, dependency ordering, graceful shutdown |
| Production | 2 | zero-downtime, resource limits |

---

**[JUNIOR] Q1 - What restart policies does systemd provide and when do you use each?**

systemd provides five restart conditions:

- `Restart=no` (default): never restart. Use for dev/test.
- `Restart=on-failure`: restart when exit code != 0 or killed by
  signal. The standard for production services. Does NOT restart on
  clean exit (code 0).
- `Restart=always`: restart on ANY exit, including clean. Use for
  services where any exit is an error. Note: prevents `systemctl stop`
  from working permanently.
- `Restart=on-abnormal`: restart on signal or watchdog timeout only.
- `Restart=on-abort`: restart only on unhandled signal.

Combined with `RestartSec`:
```ini
Restart=on-failure
RestartSec=10s            # wait 10s before retry
StartLimitIntervalSec=120s  # count restarts within 2 min window
StartLimitBurst=5          # max 5 restarts before giving up
```

> **Code walkthrough:** This combination creates a circuit breaker
> pattern: `on-failure` triggers on crashes; `RestartSec=10s` spaces
> out attempts; `StartLimitBurst=5` within 120 seconds means the
> service can restart at most 5 times in 2 minutes. KEY MECHANISM:
> the restart counter resets when the service runs successfully for
> longer than `StartLimitIntervalSec`. WHY IT MATTERS: without
> `RestartSec`, a service that fails immediately restarts dozens of
> times per second. WHAT BREAKS: `Restart=always` combined with
> `systemctl stop` only stops the service until systemd restarts it
> automatically - you must `systemctl disable` AND `systemctl stop`
> to permanently stop it. TAKEAWAY: `Restart=on-failure` with
> `RestartSec=10s` and `StartLimitBurst=5` is the production standard
> configuration for long-running services.

*What separates good from great:* knowing that `Restart=on-failure`
combined with `RestartSec=10s` and `StartLimitBurst=5` within 120
seconds creates a production-safe configuration that recovers from
transient failures while preventing crash loops from consuming resources.

---

**[MID] Q2 - How do you achieve zero-downtime service restart with systemd?**

True zero-downtime requires application-level support: the new process
must be ready before the old one stops handling traffic.

For socket-activated services (most reliable approach):
1. systemd holds the socket; old process handles existing connections
2. `systemctl restart unit` starts the new process
3. New process calls `sd_notify(READY=1)`
4. Old process receives SIGTERM, finishes in-flight requests
5. New process takes over the socket

For non-socket-activated services:
```bash
# Reload (in-process, zero downtime if supported)
systemctl reload myapp    # sends SIGHUP; app reloads config in place

# Restart with graceful shutdown window
systemctl restart --wait myapp
# --wait: blocks until new instance signals READY=1
```

> **Code walkthrough:** `systemctl restart --wait` blocks the calling
> shell until the restarted service signals READY=1 (for Type=notify)
> or until ExecStart succeeds (for Type=simple). KEY MECHANISM: this
> makes restart synchronous, allowing scripts to verify the new
> instance is healthy before proceeding. WHY IT MATTERS: without
> `--wait`, the calling script continues while the service is still
> starting, causing race conditions in deployment automation. WHAT
> BREAKS: if the service does not implement sd_notify, --wait times
> out after `TimeoutStartSec`. TAKEAWAY: use `systemctl restart
> --wait` in deployment scripts to ensure the service is ready
> before declaring the deployment successful.

For critical services, use blue-green deployment:
- Start new instance on a different port
- Health check the new instance
- Switch load balancer to new instance
- Stop old instance
- This is NOT a systemd feature but the correct operational pattern

`TimeoutStopSec` controls how long systemd waits for graceful shutdown.
A value of 30s means: send SIGTERM, wait 30s for clean exit, then SIGKILL.

*What separates good from great:* understanding that socket activation
is the only mechanism that provides truly zero-downtime restart within
systemd itself (the socket stays open across the restart, queueing
connections in the kernel buffer), versus config reload (which avoids
restart entirely but requires application support).

---

**[SENIOR] Q3 - A service fails 2 minutes after startup, not at startup. How does this affect restart policy configuration?**

Services that fail after an initial successful period should be treated
differently from services that fail immediately at startup.

The key: if the service runs for longer than `StartLimitIntervalSec`
before failing, the restart counter RESETS. So `StartLimitBurst=5`
in a 120-second window means: 5 failures in any 2-minute period. If
the service runs for 10 minutes before failing, the counter is already
reset and will allow another 5 rapid failures.

For services with delayed failures:
```ini
[Service]
# Standard restart with longer backoff for stability
Restart=on-failure
RestartSec=30s            # longer delay for services that usually run OK
StartLimitIntervalSec=600s  # 10-minute window
StartLimitBurst=3           # only 3 failures in 10 minutes before giving up

# Add watchdog for services that hang (become unresponsive without crashing)
WatchdogSec=30s
# Service must call sd_notify("WATCHDOG=1") every 30s or systemd restarts it
```

> **Code walkthrough:** `WatchdogSec=30s` enables the systemd watchdog
> mechanism. KEY MECHANISM: the service must call `sd_notify("WATCHDOG=1")`
> at least once every `WatchdogSec` seconds; if it fails to do so,
> systemd kills and restarts the service. WHY IT MATTERS: a service
> that deadlocks or enters an infinite loop without crashing is
> indistinguishable from a healthy service without a watchdog; the
> watchdog catches hanging services that the restart policy cannot.
> WHAT BREAKS: a service under extreme GC pressure may not ping the
> watchdog in time, causing false restarts; tune `WatchdogSec` to
> allow for the longest expected GC pause. TAKEAWAY: add `WatchdogSec`
> to any long-running service that could deadlock; implement the
> watchdog ping in a separate health-check goroutine/thread.

*What separates good from great:* implementing the systemd watchdog
for services that can deadlock without crashing - this is one of the
most underused systemd features and catches an entire class of failures
that simple crash detection misses.

---

**[SENIOR] Q4 - How do you configure systemd to handle service dependencies when the dependency service restarts?**

When a dependency restarts, services that declared `Requires=` are
also restarted. This can cause cascading restarts that are
unnecessary or harmful.

```ini
# SCENARIO: myapp Requires=postgresql.service
# If postgres restarts (e.g., for a config reload),
# myapp will ALSO be stopped and restarted.
# This is often undesirable for a brief postgres restart.

# Solution 1: Use BindsTo= instead of Requires= for tighter coupling
# BindsTo= is like Requires= but also stops this unit when the
# bound unit is deactivated (not just when it fails to start)

# Solution 2: Use Wants= (soft dependency) and handle
# reconnection in the application code
[Unit]
After=postgresql.service
Wants=postgresql.service    # start postgres if possible, but don't
                             # stop myapp if postgres restarts

[Service]
# Application handles database reconnection with retry logic
Restart=on-failure
RestartSec=10s
```

> **Code walkthrough:** `Wants=postgresql.service` in combination
> with `After=postgresql.service` means: if postgres is starting,
> wait for it; if it is not starting, proceed anyway. KEY MECHANISM:
> the application's internal retry logic handles the case where
> postgres is not ready - it retries the database connection with
> exponential backoff rather than crashing and relying on systemd.
> WHY IT MATTERS: `Requires=` hard dependency means a planned
> postgres restart (for configuration change) also stops myapp,
> causing unnecessary downtime. WHAT BREAKS: `Wants=` without
> application-level reconnection means myapp starts, fails to
> connect, and crashes repeatedly. TAKEAWAY: use `Wants=` only when
> the application implements database reconnection with retry;
> use `Requires=` when the application will crash without the
> dependency and reconnection is not implemented.

The production pattern for stateful dependencies:
- `Wants=` + `After=`: for services that should start after
  postgres is up but handle reconnection themselves
- `Requires=` + `After=`: for services that truly cannot function
  without the dependency and should be restarted when it restarts
- Database connection pool with health checks + reconnection: the
  application-level solution that makes Wants= work correctly

*What separates good from great:* recommending application-level
reconnection logic over systemd-level hard dependencies - a service
with `Requires=postgresql` that handles reconnection internally is
more resilient than one that requires systemd to restart it every
time postgres has a brief outage.

---

**[SENIOR] Q5 - How do you use systemd's ConditionX and AssertX directives for conditional service activation?**

Condition and Assert directives check system state before starting
a service. The difference: `ConditionX=` failure skips the service
(marks it inactive), while `AssertX=` failure marks it FAILED.

```ini
[Unit]
# Only start on this specific host (useful for fleet config management)
ConditionHostname=production-db-01

# Only start if file exists (feature flag pattern)
ConditionFileNotEmpty=/etc/myapp/feature-flags.conf

# Only start if kernel version supports a feature
ConditionKernelVersion=>=5.10

# Only start if this is a virtual machine
ConditionVirtualization=vm

# Assert: fail (not just skip) if this is not met
AssertPathExists=/opt/myapp/bin/server
```

> **Code walkthrough:** `ConditionHostname=` is used in shared unit
> file configurations deployed to all hosts - only the specific
> hostname activates the service. KEY MECHANISM: conditions are
> evaluated before the service starts; if any condition is false,
> systemd marks the unit as `skipped` (not failed), which allows
> other units with `Wants=` dependencies to proceed normally.
> WHY IT MATTERS: this enables a single unit file to handle
> hostname-specific, environment-specific, and feature-flag-driven
> activation without needing separate unit files per environment.
> WHAT BREAKS: `Assert=` failure marks the service FAILED, triggering
> restarts and alarms; use `Condition=` for expected skips. TAKEAWAY:
> prefer `ConditionFileNotEmpty=/etc/myapp/enabled` as a simple
> on/off feature flag for services that should be easy to disable
> in production.

*What separates good from great:* using `ConditionFileNotEmpty=` as
a feature flag file - creating the file enables the service, deleting
it disables it (after `daemon-reload + restart`) - this is a simple,
audit-friendly service activation mechanism that does not require
code changes.

---

**[STAFF] Q6 - Describe the full lifecycle of a systemd-managed service from boot to crash to recovery at fleet scale.**

This integrates all aspects of systemd service management:

**Boot sequence:**
1. systemd starts as PID 1 after kernel initialization
2. Reads all unit files from `/lib/systemd/system/` (distribution),
   `/etc/systemd/system/` (admin overrides), `/run/systemd/system/`
   (runtime)
3. Builds the dependency graph resolving After/Before/Requires/Wants
4. Starts units in parallel respecting ordering constraints
5. Units with `After=network-online.target` wait for network IP
6. Service reaches `active` state when `Type=notify` sends READY=1
   (or when ExecStart succeeds for `Type=simple`)

**Crash scenario:**
1. JVM OutOfMemoryError causes exit with code 1
2. systemd detects exit, checks `Restart=on-failure` → restart
3. Waits `RestartSec=10s`
4. Increments restart counter (now 1 of StartLimitBurst=5)
5. Starts ExecStart again
6. Service logs the restart with reason to journald
7. Monitoring system detects via `systemctl is-active myapp` returning
   non-zero or alerting on restart rate

**Fleet-scale recovery:**
```bash
# Check service health across all nodes
ansible app_servers -m shell -a 'systemctl is-active myapp'

# Identify nodes with restart loops
ansible app_servers -m shell -a \
  "journalctl -u myapp --since '1 hour ago' | grep -c 'Started'"

# Deploy unit file change
ansible app_servers -m copy \
  -a 'src=myapp.service dest=/etc/systemd/system/myapp.service'
ansible app_servers -m shell \
  -a 'systemctl daemon-reload && systemctl restart myapp'

# Verify recovery
ansible app_servers -m shell \
  -a 'systemctl status myapp --no-pager | grep Active'
```

> **Code walkthrough:** The Ansible fleet management pattern shows
> idiomatic systemd deployment at scale. KEY MECHANISM: `daemon-reload`
> before `restart` ensures the new unit file is used; without it, the
> old definition stays in memory. WHY IT MATTERS: at 1000 servers,
> a systemd configuration bug can take down a fleet; staged rollouts
> (deploy to 5% of servers, verify, then proceed) are essential.
> WHAT BREAKS: running `daemon-reload` without `restart` activates
> the new config only for the NEXT restart; running `restart` without
> `daemon-reload` uses the old config. TAKEAWAY: always `daemon-reload
> && restart` as an atomic pair; consider using `--force-restart` in
> Ansible to ensure the reload-restart is atomic.

*What separates good from great:* knowing that systemd unit file
changes require the atomic `daemon-reload && restart` pair - not just
`restart` alone - and that the order matters: `daemon-reload` first
to reload from disk, then `restart` to apply the new configuration.

---

**[JUNIOR] Q7 - How do you check which services are enabled to start at boot?**

`systemctl list-unit-files` shows all installed units and their enable/disable
state. Enabled means a symlink exists in `/etc/systemd/system/multi-user.target.wants/`
(or other target directory) pointing to the unit file.

```bash
# List all units and their boot-enable state:
systemctl list-unit-files --type=service
# UNIT                    STATE
# ssh.service             enabled   <- starts at boot
# docker.service          enabled
# cups.service            disabled  <- not at boot
# snapd.service           enabled

# Check a specific service:
systemctl is-enabled nginx.service
# enabled  <- exits 0 (active at boot)
# disabled <- exits 1 (not at boot)

# Enable and immediate start:
systemctl enable --now nginx.service
# Equivalent to: enable + start in one command

# Disable and immediate stop:
systemctl disable --now nginx.service
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the three tools for managing
> boot-time service activation: `list-unit-files` for an overview,
> `is-enabled` for scripting checks, and `enable --now` for the
> common enable+start operation. (2) KEY MECHANISM: `enable` creates
> a symlink in the target wants directory; on boot, systemd reads all
> symlinks in wants directories to build the dependency graph; a
> missing symlink means the service does not start. (3) WHY IT MATTERS:
> `systemctl start` starts a service NOW but does not persist across
> reboots; forgetting `enable` means the service is running until the
> next reboot then silently absent. (4) WHAT BREAKS: `enable` without
> `start` leaves a service enabled at boot but not running now;
> monitor scripts checking the running service may pass while the
> next-boot state is unconfigured. (5) TAKEAWAY: use `enable --now`
> as the default enable command; it starts immediately AND persists
> across reboots; use plain `enable` only when you explicitly want to
> defer the first start to reboot.

*What separates good from great:* distinguishing `enabled` from `active` -
a service can be enabled (starts at boot) but currently stopped, or active
(currently running) but not enabled (will not start at boot after a reboot).
Always verify both states after configuring a new service:
`systemctl is-enabled myservice && systemctl is-active myservice`.

---

### ⚖️ Comparison Table

| Restart scenario | Recommended policy | Why |
|-----------------|---------------------|-----|
| Crash on startup (e.g., DB not ready) | `Restart=on-failure` + `RestartSec=10s` | Retries with backoff until DB available |
| Service hangs without crashing | `WatchdogSec=30s` + app ping | Detects liveness not just exit code |
| Service that must never stop | `Restart=always` + `StartLimitBurst=10` | Aggressive restart, high limit |
| Config reload without restart | `ExecReload=kill -HUP $MAINPID` | Zero-downtime config update |
| Zero-downtime restart | Socket activation + `Type=notify` | Socket stays open across restart |
| Batch job, once per boot | `Type=oneshot` + `RemainAfterExit=yes` | Runs once, shows as active |

---

### 🏛️ System Design

*(Omit: ★★☆ service management operational keyword - system design
for high-availability service orchestration at scale is covered in
the Kubernetes and distributed systems L4+ topics.)*

---

### 📊 Diagram

*(Omit: the service lifecycle state machine is shown in the Concept
Explanation section; an additional diagram would be redundant for
this configuration-reference topic.)*
