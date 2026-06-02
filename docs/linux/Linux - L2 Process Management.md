---
layout: default
title: "Linux - L2 Process Management"
parent: "Linux"
nav_order: 4
permalink: /linux/l2-process-management/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Difficulty |
|---|---------|------------|
| 10 | [Process Management: ps, top, kill, and jobs](#process-management-ps-top-kill-and-jobs) | ★★☆ |
| 11 | [Cron Jobs and Scheduled Tasks](#cron-jobs-and-scheduled-tasks) | ★★☆ |

---

# Process Management: ps, top, kill, and jobs

**Interview Weight:** Medium - process management is a daily
operational skill tested in backend/DevOps roles; candidates
expected to diagnose process issues without help.

---

### 🎯 Model Answer

**30-second answer:**

"ps shows a snapshot of running processes. top shows live process
resource usage. kill sends signals to processes (SIGTERM for graceful
stop, SIGKILL for force). jobs tracks background processes in the
current shell. Together they provide the ability to observe, control,
and diagnose processes - essential for production debugging."

**3-minute answer:**

"Linux process management centers on understanding process states and
signals.

`ps aux` gives a full process snapshot: user, PID, CPU%, MEM%, VSZ
(virtual), RSS (resident), state (R/S/D/Z), start time, command line.
`ps -ef` is the System V format with PPID (parent PID) which is useful
for process trees. `pgrep nginx` finds PIDs by name.

`top` (or the better `htop`) shows live CPU, memory, load average, and
per-process stats updating every second. The load average represents
the number of processes competing for CPU - on a 4-core system, load
of 4 means fully utilized, load of 8 means overloaded.

`kill` sends signals: `kill PID` defaults to SIGTERM (15) - graceful
shutdown that the process can handle. `kill -9 PID` sends SIGKILL -
unblockable, process is forcibly terminated by the kernel. Always try
SIGTERM first; SIGKILL leaves no chance for cleanup (no connection
close, no data flush).

`jobs` tracks background jobs in the current shell (`cmd &` runs in
background). `fg %1` brings job 1 to foreground. `bg %1` resumes
a stopped job in background.

The crucial signal: SIGHUP (1) - traditionally 'terminal hangup' but
used by most daemons as a 'reload config without restart' signal."

**Blank Mind Recovery:**

"ps aux = process snapshot; top = live CPU/memory; kill PID = SIGTERM
(graceful); kill -9 = SIGKILL (force). Load average = processes
competing for CPU. SIGHUP = reload config. SIGTERM = graceful stop.
SIGKILL = force stop (last resort)."

---

### 📘 Concept Explanation

**What it is:**

The set of Linux tools and signals for observing, controlling, and
diagnosing running processes: ps (snapshot), top (live), kill (signal
sending), and jobs/fg/bg (shell job control).

**The problem it solves:**

Production systems run hundreds of processes. When a service is slow,
hung, consuming excessive resources, or needs a graceful restart,
engineers need to observe process state, resource consumption, and
control process lifecycle.

**How it works:**

Process hierarchy: every process has a PID and a PPID (parent PID).
Process 1 (init/systemd) is the ancestor of all user processes.
When a parent process dies before its children, orphaned children are
re-parented to init (PID 1).

Signals are asynchronous notifications to processes:
| Signal | Number | Default Action | Common Use |
|---|---|---|---|
| SIGTERM | 15 | Terminate | Graceful shutdown |
| SIGKILL | 9 | Force kill | Cannot be caught/ignored |
| SIGHUP | 1 | Terminate (daemons: reload) | Config reload |
| SIGINT | 2 | Terminate | Ctrl+C |
| SIGSTOP | 19 | Pause | Cannot be caught |
| SIGCONT | 18 | Resume | Resume after SIGSTOP |
| SIGUSR1/2 | 30/31 | App-defined | Custom app signals |

Process states (from `ps` S column):
- R: Running or runnable (in run queue)
- S: Interruptible sleep (waiting for event)
- D: Uninterruptible sleep (disk I/O wait - cannot be killed!)
- Z: Zombie (finished but parent hasn't called wait())
- T: Stopped (SIGSTOP or Ctrl+Z)

**The key insight:**

D-state processes cannot be killed with any signal including SIGKILL.
A process stuck in D-state means it's waiting for kernel I/O that
has not completed (disk hang, NFS timeout, device driver bug). The
fix is resolving the underlying I/O issue, not sending more signals.

**When to use SIGKILL:**

Only after SIGTERM has failed and the process hasn't stopped after
30+ seconds. SIGKILL prevents cleanup: database transactions may be
left open, log buffers may be lost, temp files may not be cleaned up.

**When to use SIGHUP:**

For services that re-read config on SIGHUP without restarting (nginx,
syslogd). Check the service's documentation first - some services
use SIGHUP as shutdown (any POSIX program that doesn't override it).

**Alternatives:**

`htop`: interactive, color-coded top with mouse support.
`atop`: records historical system activity.
`glances`: comprehensive real-time monitoring.

**First-principles derivation:**

"Process management needs: observation (what's running, what's consuming),
control (start, stop, signal), and prioritization (nice/renice for
CPU priority). ps/top/kill implement exactly these three capabilities."

---

### 💻 Code Example

```bash
# ps: process inspection
ps aux
# USER    PID  %CPU %MEM    VSZ   RSS TTY   STAT START  TIME COMMAND
# root      1   0.0  0.0  22524  1956 ?     Ss   Jan01  0:05 /sbin/init

# Find a process by name
pgrep -a java           # PIDs + command line
pgrep -u appuser java   # filter by user

# Process tree (shows parent-child)
pstree -p 1234         # tree from PID 1234
ps --forest -eo pid,ppid,comm,args | grep -A5 nginx

# top: live monitoring
top -b -n 1            # single snapshot (for scripts)
top -u appuser         # filter by user
top -p 1234,5678       # watch specific PIDs

# Key top columns:
# PID   PR  NI    VIRT    RES    SHR  S  %CPU  %MEM  TIME+ COMMAND
# 1234  20   0  4096m   512m    64m  S  45.3   3.2  5:23.45 java
# VIRT=virtual memory, RES=resident (actual RAM), SHR=shared

# Signals
kill -15 1234      # SIGTERM (graceful)
kill -TERM 1234    # same
kill 1234          # default SIGTERM

kill -9 1234       # SIGKILL (force - last resort)
kill -KILL 1234    # same

kill -HUP 1234     # reload config
kill -HUP $(pgrep nginx)  # common nginx config reload pattern

# Send to all processes with name
pkill -TERM nginx   # send SIGTERM to all nginx processes
killall -9 java     # SIGKILL all java processes (dangerous in prod)
```

> **Code walkthrough:** `kill -HUP $(pgrep nginx)` sends SIGHUP to
all nginx master processes, causing nginx to reload its configuration
without stopping. KEY MECHANISM: nginx's signal handlers catch SIGHUP
and re-read nginx.conf, then gradually replace worker processes -
in-flight requests complete before workers are replaced. WHY IT
MATTERS: reloading without restart avoids connection disruption; a
restart would cause new connections to fail during the restart window.
WHAT BREAKS: using `killall -9 java` in production force-kills ALL
java processes including JVM management agents, build tools, and
other services - always target by PID or use `pgrep -f "appname"` to
identify specific processes. TAKEAWAY: `pgrep -a` shows the full
command line to verify you're targeting the right process before
sending a signal.

```bash
# Jobs: background process control
# Start command in background
long_running_command &
# [1] 12345   <- job number and PID

# Suspend foreground command
# (Press Ctrl+Z)
# [1]+  Stopped    long_running_command

# List background jobs
jobs -l
# [1]+  12345 Stopped    long_running_command
# [2]-  12346 Running    another_command &

# Resume in background
bg %1    # %1 = job 1, or just bg (most recent)

# Bring to foreground
fg %1

# Disown a job (detach from shell - survives shell exit)
command &
disown %1
# Now it survives terminal close (similar to nohup)

# nohup: run immune to hangup signal
nohup long_job.sh > /tmp/job.log 2>&1 &
```

> **Code walkthrough:** `disown %1` removes the job from the shell's
job table, preventing the shell from sending SIGHUP to the background
process when the terminal closes. KEY MECHANISM: when a terminal
closes, the shell sends SIGHUP to all its process group members;
`disown` removes the job from the group and `nohup` installs a SIGHUP
handler that ignores the signal. WHY IT MATTERS: running a long job
in background without `nohup` or `disown` causes it to be killed when
the SSH session disconnects - a classic mistake. WHAT BREAKS: `nohup`
alone does not guarantee the process runs after shell exit if it's a
shell builtin or a function; use it with external commands only.
TAKEAWAY: for long-running jobs launched over SSH, use `tmux`/`screen`
for interactive access or `nohup cmd &` for fire-and-forget background jobs.

---

### 🎓 Answers by Seniority

**Junior/Mid:**

"I use ps aux to see all processes, top for live monitoring, and kill
PID to stop processes. Kill -9 force-kills if the process doesn't
respond to regular kill. For background tasks I use & and jobs. SIGHUP
is used to reload nginx config without restarting."

**Senior/Staff:**

"Process management in production requires understanding signals and
states. My diagnostic flow for a hung process: first check its state
with `ps -o state,wchan=WAIT -p PID` - if it's D-state, check what
kernel wait channel it's in (NFS, disk, lock). If it's S-state (just
sleeping), check `/proc/PID/status` for voluntary context switches
(high count = lock contention), and `ls /proc/PID/fd | wc -l` for
resource leaks. SIGTERM before SIGKILL, always - SIGKILL leaves no
audit trail (no app shutdown log, no connection closure, no buffer
flush). For config reloads, I verify the service handles SIGHUP before
using it - some services treat it as terminate. I use `systemctl reload`
rather than `kill -HUP` for systemd services because systemd knows
whether the service supports reload and handles the signal correctly."

---

### ⚠️ Common Misconceptions

**Misconception 1: "kill -9 is the reliable way to stop a process."**

SIGKILL cannot be caught but has dangerous consequences: no
connection cleanup (TCP connections left in CLOSE_WAIT), no data
flush (in-memory buffers lost), no temp file cleanup, no locks
released. For database processes, SIGKILL can leave the database in
an inconsistent state requiring crash recovery. Always try SIGTERM
first and wait 30 seconds.

**Misconception 2: "A zombie process is consuming CPU."**

Zombie processes (Z state) are not running - they have exited but
their entry remains in the process table waiting for their parent to
call `wait()`. They consume no CPU, no memory (only a process table
entry). The fix is not killing the zombie (impossible - it's already
dead) but fixing the parent process to call `wait()`.

**Misconception 3: "High load average means high CPU usage."**

Load average counts processes in R (running/runnable) AND D
(uninterruptible sleep) states. A load average of 8 on a 4-core
system could mean 8 processes waiting for disk I/O, not 8 processes
consuming CPU. Check `vmstat 1 5` to see the split between CPU-bound
(us/sy columns) and I/O-bound (wa column).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Zombie process accumulation causing table exhaustion**

```bash
# Detect zombies
ps aux | awk '$8 == "Z" {print $1, $2, $11}'
# root  1234  [nginx] <defunct>  <- zombie nginx process

# Find the zombie's parent
ps -o ppid= -p 1234
# 5678  <- parent PID

# What is the parent?
ps -o comm= -p 5678
# supervisord  <- supervisor not handling child exit

# Check parent's open file descriptors
ls /proc/5678/fd | wc -l

# Diagnostic: send SIGCHLD to parent (prompts it to wait())
kill -SIGCHLD 5678
# If parent handles SIGCHLD, zombies will be cleaned up

# If parent won't clean up: restart the parent process
systemctl restart supervisord  # or the parent service

# Nuclear option: if parent is PID 1 (init), zombies are
# normal and periodically reaped by init automatically
```

> **Code walkthrough:** Zombies accumulate when a parent process creates
children but never calls `wait()` to collect their exit status. KEY
MECHANISM: the kernel keeps the process table entry until the parent
calls `wait()`; if the parent is itself broken (memory leak, hung), it
never reaps its children. WHY IT MATTERS: each zombie occupies a process
table entry; Linux has a per-system limit (~32768 PIDs); massive zombie
accumulation causes `fork()` to fail with "no child processes" which
prevents any new processes from starting. WHAT BREAKS: `kill -9` cannot
kill a zombie - it's already dead. The fix is always fixing or restarting
the parent. TAKEAWAY: regular zombie accumulation is a bug in the parent
process's child lifecycle management.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | signals, process states, load average |
| Debugging | 3 | zombie, D-state, high CPU |
| Trade-off | 3 | SIGTERM vs SIGKILL, process isolation |

---

**[JUNIOR] Q1 - What is the difference between SIGTERM and SIGKILL and when do you use each?**

SIGTERM (signal 15) is a "request to terminate." The process receives
it, can catch it, and has the opportunity to:
- Flush write buffers
- Close database connections
- Finish in-flight requests
- Remove lock files and PID files
- Log a clean shutdown message
- Deregister from service discovery

SIGKILL (signal 9) is not a signal in the traditional sense - it is
a kernel directive. The process cannot catch, ignore, or block it.
The kernel forcibly terminates the process without giving it any
cleanup opportunity. There is no application-level shutdown log, no
connection close, no buffer flush.

The correct procedure for stopping a process:
1. `kill PID` (SIGTERM) - request graceful shutdown
2. Wait 15-30 seconds
3. Check if still running: `ps -p PID`
4. If still running, investigate WHY (is it stuck in D-state? hanging on cleanup?)
5. Only then: `kill -9 PID`

When SIGKILL is appropriate: a process that is stuck in user-space
(not D-state) and is not responding to SIGTERM after a reasonable
wait. Never use it as a first resort.

*What separates good from great:* specifically naming what SIGTERM
allows (flush buffers, close connections, log shutdown) and what SIGKILL
prevents - not just "graceful vs force."

---

**[JUNIOR] Q2 - A production Java service is consuming 100% CPU but doing no useful work. How do you diagnose it?**

This is typically thread contention, infinite loop, or GC thrashing.
Systematic diagnosis:

```bash
# Step 1: identify the JVM process
PID=$(pgrep -f "myservice")
top -b -n 1 -p $PID
# Confirm it's the right process and CPU usage level

# Step 2: check thread-level CPU with top
top -b -n 1 -H -p $PID | head -20
# -H shows individual threads
# TID    PR  NI   %CPU   TIME+ COMMAND
# 12345  20   0  99.9   5:23  myservice  <- hot thread

# Step 3: convert TID to hex for JVM stack match
printf '%x\n' 12345   # -> 3039

# Step 4: get JVM thread dump and find the thread
jstack $PID | grep -A 30 "nid=0x3039"
# "pool-1-thread-42" #42 prio=5 os_prio=0 tid=... nid=0x3039
#  at java.lang.Thread.sleep(Native Method)
#  at com.myapp.BusyLoop.run(BusyLoop.java:45)  <- culprit

# Step 5: check GC activity (might be GC thrashing)
jstat -gcutil $PID 1000 5
# If FGC (full GC) is happening frequently: OOM approaching
# S0     S1     E      O      M    CCS  YGC   YGCT  FGC  FGCT   GCT
# 0.00   0.00  98.45  99.87  93.45 ... 123   8.456  45  120.12 ...
# 45 full GCs and 120 seconds of GC time = GC thrashing
```

> **Code walkthrough:** `jstat -gcutil` samples JVM garbage collection metrics at intervals, reporting heap section fill percentages (S0/S1 survivor, E=eden, O=old gen, M=metaspace) alongside GC counts and cumulative time. The critical columns are `FGC` (full GC count) and `FGCT` (full GC wall-time): 45 full GCs consuming 120 seconds total means the JVM spent most of its runtime collecting rather than executing application code. When `O` reaches 99.87% and full GC keeps climbing, the heap is exhausted and `OutOfMemoryError` is imminent. WHAT BREAKS: any FGC rate above 1-2 per hour warrants investigation; GC time above 10% of wall clock is a production emergency. TAKEAWAY: always check `jstat` before assuming CPU is a code problem; GC thrashing mimics 100% CPU.


Common causes:
1. GC thrashing (heap full, spending all time on GC)
2. Infinite loop with no sleep or yield
3. Tight lock spinning (futex busy-wait)
4. Regex catastrophic backtracking

*What separates good from great:* the TID-to-hex conversion for
matching `top -H` thread IDs to `jstack` output - this is the exact
technique for identifying the hot thread in a Java process.

---

**[JUNIOR] Q3 - What is load average and what does a load average of 8 on a 4-core system mean?**

Load average is the running average count of processes in R (runnable)
or D (uninterruptible sleep) state. Linux reports three values: 1-minute,
5-minute, and 15-minute averages.

The key metric is `load average / CPU count`:
- < 1.0: system is underutilized, plenty of headroom
- = 1.0: system is at exact capacity (every CPU has exactly one waiting process)
- > 1.0: system is overloaded (processes waiting for CPU)

On a 4-core system:
- Load 4.0: 4 processes competing for 4 CPUs - fully utilized but no queuing
- Load 8.0: 8 processes competing for 4 CPUs - every core has a waiting process
- Load 16.0: 4 cores with 3 processes waiting per core - severely overloaded

Critical: load includes D-state (I/O waiting) processes. `vmstat 1`
distinguishes:
```
procs: r b
# r = runnable (CPU-bound)
# b = blocked (D-state, I/O-bound)
```

> **Code walkthrough:** `vmstat` process counters show two critical queue depths: `r` (runnable processes waiting for CPU) and `b` (processes blocked in uninterruptible D-state, typically waiting for I/O). KEY MECHANISM: the kernel scheduler keeps runnable processes in the run queue (r); I/O-blocked processes exit the run queue into D-state (b). WHY IT MATTERS: on a 4-core machine, r > 4 means every CPU has a waiting task and the system is CPU-saturated. WHAT BREAKS: a persistent non-zero b during normal operations means I/O saturation, often an NFS hang or dying disk. TAKEAWAY: r > CPU count means add cores or optimize code; b > 0 means I/O subsystem problem requiring storage diagnosis.


If load = 8 with r=1, b=7: 7 processes waiting on disk I/O, not CPU.
Adding more CPU cores would not help - need faster disk or less I/O.

*What separates good from great:* explaining the load-per-CPU ratio
AND distinguishing CPU-bound (r column) from I/O-bound (b column) load
from `vmstat`.

---

**[MID] Q4 - What is a process group and why does it matter for killing a group of related processes?**

A process group is a collection of processes that share a PGID (Process
Group ID). When you run a shell pipeline, all processes in the pipeline
share a process group.

Signals sent to a process group (negative PID) go to all members:

```bash
# Start a pipeline
cat /dev/urandom | gzip | wc -c &
# [1] 12345  <- PGID of the pipeline

# Kill the entire process group
kill -- -12345   # negative PID = PGID

# Or with pkill (by name):
pkill -g 12345   # kill all in process group 12345

# Find a process's PGID
ps -o pid,pgid,cmd -p 12345
# PID   PGID  COMMAND
# 12345 12345  cat /dev/urandom
# 12346 12345  gzip
# 12347 12345  wc -c
```

> **Code walkthrough:** This `ps` output shows three processes sharing the same parent PID (12345), revealing a shell pipeline: `cat | gzip | wc -c`. KEY MECHANISM: the shell forks each pipeline stage as a sibling process under the same parent, not as nested children. WHY IT MATTERS: killing PID 12345 (cat) leaves gzip and wc running as orphans. WHAT BREAKS: orphaned pipeline stages consume resources silently; `ps aux | grep Z` will not show them as zombies until their parent collects them. TAKEAWAY: kill the entire process group with `kill -TERM -$(ps -o pgid= -p 12345 | tr -d " ")` to terminate all pipeline stages.


Process groups matter for scripts that launch child processes: if the
script is killed with SIGTERM, child processes may survive as orphans
(re-parented to PID 1) and continue running. To ensure all children
are killed, trap EXIT and kill the entire process group:

```bash
#!/bin/bash
trap 'kill -- -$$' EXIT  # kill our process group on exit
./start-server.sh &
./run-load.sh &
wait
```

> **Code walkthrough:** The `wait` builtin blocks until all background jobs (`&`) started in the current shell complete. KEY MECHANISM: each `&` job runs in a child process; `wait` calls `waitpid()` in a loop until all children exit and collects their exit codes. WHY IT MATTERS: without `wait`, the script exits while background jobs are still running, causing resource cleanup races or half-finished work. WHAT BREAKS: if the shell exits before `wait`, background jobs become orphans (re-parented to init/PID 1). TAKEAWAY: always use `wait` after parallel `&` jobs; use `wait $PID` to wait for a specific job and capture its exit code.


*What separates good from great:* the practical pattern of using
`kill -- -$$` in an EXIT trap to kill the entire script's process
group - preventing orphan child processes.

---

**[MID] Q5 - What is the difference between ps -ef and ps aux and when do you use each?**

The two formats present similar information with different column layouts:

`ps aux` (BSD format):
```
USER       PID %CPU %MEM    VSZ   RSS TTY  STAT START   TIME COMMAND
appuser  12345 45.3  3.2 4194304 524288 ?  Sl   10:00   5:23 java ...
```

> **Code walkthrough:** `ps aux` output for a Java process shows large `VSZ` (virtual size, ~4 GB) versus moderate `RSS` (resident set, ~512 MB). KEY MECHANISM: Java pre-allocates virtual address space for heap, off-heap, and shared libraries; only pages actually accessed become resident (RSS). WHY IT MATTERS: VSZ is misleading for memory budgeting; RSS is the actual physical memory consumed. WHAT BREAKS: beginners alert on high VSZ and mistakenly kill a healthy JVM; the real OOM risk is high RSS approaching the cgroup memory limit. TAKEAWAY: always use RSS for memory consumption analysis; high VSZ with low RSS is normal Java behavior, not a leak.

Key columns: `%CPU`, `%MEM`, `VSZ`, `RSS`, `STAT`. Good for resource-
focused queries.

`ps -ef` (System V format):
```
UID        PID  PPID  C STIME TTY   TIME CMD
appuser  12345 12340  0 10:00 ?  00:05:23 java ...
```

> **Code walkthrough:** `ps -ef` System V format adds a dedicated `PPID` (parent PID) column absent in `ps aux`. KEY MECHANISM: the `-f` flag enables full format including PPID, start time (STIME), and cumulative CPU (TIME); `-e` selects all processes. WHY IT MATTERS: PPID is essential for tracing process lineage - which service, shell, or cron job spawned this process. WHAT BREAKS: using `ps aux` when you need hierarchy loses the parent context, making it hard to determine if a rogue process was started by an attacker or a legitimate service. TAKEAWAY: use `ps aux` for resource monitoring; use `ps -ef` for process ownership and parent-child relationship analysis.

Key difference: `PPID` (parent PID) column. Good for process hierarchy.

Practical use:
- Resource consumption: `ps aux | sort -k3 -rn | head -10`
  (sort by CPU%, highest first)
- Process hierarchy: `ps -ef | grep nginx`
  (see master + worker relationships via PPID)
- Full command line: both show command, but `ps auxwww` (with `w`
  flags) removes the truncation limit

For process trees, `pstree -p` is more readable than parsing PPID from
`ps -ef`.

*What separates good from great:* knowing PPID is the key differentiator
for `ps -ef` and using `pstree` for hierarchical display rather than
manually processing PPID columns.

---

**[MID] Q6 - How do you change process priority and when is it useful?**

Linux process scheduling priority is controlled by "nice" values
(range -20 to 19, where -20 is highest priority and 19 is lowest).

```bash
# Start with nice value 10 (lower priority)
nice -n 10 backup-script.sh

# Renice a running process
renice -n 15 -p 12345    # set nice to 15 (lower priority)
renice -n -5 -p 12345    # increase priority (requires root for negative)

# View current nice values
ps -eo pid,ni,comm | grep -E "java|nginx"
# 12345  0  java   <- normal priority
# 12346  0  nginx

# Set I/O priority (ionice)
ionice -c 3 -p 12345        # idle I/O class (lowest)
ionice -c 2 -n 0 -p 12345   # best-effort, highest within class

# Start a backup with both CPU and I/O lowest priority
nice -n 19 ionice -c 3 tar czf backup.tar.gz /var/data/
```

> **Code walkthrough:** Combining `nice -n 19` (lowest CPU priority, range -20 highest to 19 lowest) with `ionice -c 3` (idle I/O class) ensures the tar backup process only gets CPU and I/O bandwidth when no other process needs them. KEY MECHANISM: the CFS scheduler and I/O scheduler honor the nice and ionice values when making scheduling decisions. WHY IT MATTERS: an un-niced backup on a production host can raise load average and introduce I/O wait, degrading application latency by 20-50% on spinning disks. WHAT BREAKS: forgetting ionice still allows the backup to saturate I/O even at low CPU priority. TAKEAWAY: any batch job running on a production host MUST use both `nice -n 19` AND `ionice -c 3`.


Production use cases:
1. **Batch jobs:** Run nightly backups and ETL jobs at `nice -n 15` to
   prevent them from impacting latency-sensitive services
2. **Background indexing:** Database VACUUM, search indexing at high
   nice value during peak hours
3. **Emergency priority:** Temporarily increase priority (`renice -n -5`)
   for a critical process that needs to complete before others

The important caveat: nice values only affect CPU scheduling competition
between runnable processes. If the system is I/O-bound, nice has little
effect. Use `ionice` for I/O-bound processes.

*What separates good from great:* knowing `ionice` for I/O priority
(separate from CPU nice) and explaining that nice is ineffective for
I/O-bound workloads.

---

**[SENIOR] Q7 - What are zombie processes and how do you eliminate them without rebooting?**

A zombie (defunct) process has finished executing but remains in the
process table because its parent has not called `wait()` to retrieve
its exit status. The zombie holds no memory or CPU - only a process
table slot.

Zombies are normal in short-lived form: a process finishes, becomes
a zombie briefly, the parent calls `wait()`, the zombie disappears.
Long-lived zombies indicate a parent bug.

Eliminating zombies without reboot:

```bash
# Find zombie processes and their parents
ps axo pid,ppid,state,comm | awk '$3 == "Z" {print}'
# PID   PPID  S  COMMAND
# 12345 5678  Z  defunct_worker

# Option 1: Send SIGCHLD to parent (trigger wait() in parent)
kill -SIGCHLD 5678
ps -p 12345 2>/dev/null && echo "still zombie" || echo "cleaned up"

# Option 2: Restart the parent process
# If parent is a service:
systemctl restart my-parent-service

# Option 3: If parent is unresponsive
kill -9 5678  # kill parent - kernel reparents zombie to init
# init periodically calls wait() for all orphaned processes
# zombie disappears within seconds

# Monitor zombie count
ps aux | awk '$8 == "Z"' | wc -l
```

> **Code walkthrough:** This pipeline counts zombie processes (STAT=Z) from `ps aux` output. KEY MECHANISM: a zombie is a process that has exited but whose entry in the process table has not been removed because its parent has not called `wait()`. WHY IT MATTERS: zombies consume process table entries; at ~32768 total entries on most systems, enough zombies prevent `fork()` from succeeding. WHAT BREAKS: `kill -9` cannot kill a zombie - it is already dead. Fix is to restart or fix the parent. TAKEAWAY: monitor zombie count as a health metric; a growing count signals a bug in the parent's child lifecycle management.


When the parent is killed, orphaned children (including zombies) are
reparented to init (PID 1). Init always calls `wait()` for its children,
so the zombie is cleaned up. This is why rebooting always clears zombies.

*What separates good from great:* knowing that orphaned processes go to
PID 1 (not root or the killer's PID) and that init always reaps them -
explaining WHY rebooting fixes zombies and why killing the parent is the
right non-reboot fix.

---

**[SENIOR] Q8 - How do you reliably find the PID of a specific running process instance?**

```bash
# pgrep: find by name (safest for simple cases)
pgrep nginx        # all nginx pids
pgrep -f "nginx -g 'daemon off'"  # match against full command line

# ps + grep (but avoid grepping ps - see below)
ps aux | grep '[n]ginx'
# The [n] trick: matches "nginx" but not the grep process itself
# because grep searches for "[n]ginx" which matches "nginx"
# but the ps line shows "[n]ginx" which doesn't match "[n]ginx"

# pidof: only for exact binary name
pidof nginx

# From a PID file (most reliable for managed services)
cat /var/run/nginx.pid
# 1234

# Find by port (reverse lookup)
ss -tlnp sport 80
# LISTEN  0  128  *:80  *:*  users:(("nginx",pid=1234,fd=6))

# Verify process identity before sending signals
ls -la /proc/$(pgrep nginx)/exe
# /proc/1234/exe -> /usr/sbin/nginx   <- verify it's the right binary
```

> **Code walkthrough:** Reading `/proc/PID/exe` via `ls -la` reveals the actual binary path being executed, not just the command name. KEY MECHANISM: the kernel maintains a symlink in `/proc/PID/exe` pointing to the inode of the executable opened at execve() time. WHY IT MATTERS: after `apt upgrade`, a running process still uses the old binary until restarted; the symlink shows `(deleted)` in that case. WHAT BREAKS: relying on the command name from `ps` in security contexts is unsafe - a process can change its argv[0]. TAKEAWAY: verify process identity with `/proc/PID/exe` when security matters; `(deleted)` suffix means the binary was updated and the service needs a restart.


The PID file (`/var/run/service.pid`) is the most reliable approach for
managed services because it's written by the service itself at startup
and reflects the exact PID, unlike name-based searches which can match
multiple processes.

*What separates good from great:* the `[n]ginx` grep trick to avoid
matching the grep process itself in ps output - a common source of
off-by-one errors when scripting process detection.

---

**[SENIOR] Q9 - What happens when you send SIGTERM to a process that is in D state?**

Nothing immediately. D-state (uninterruptible sleep) means the process
is waiting for kernel I/O to complete and cannot be interrupted by
signals. The signal is queued by the kernel but not delivered until
the process wakes from the D state.

If the I/O completes:
- The process wakes from D-state
- The queued SIGTERM is delivered
- The process handles it (terminates gracefully or ignores it)

If the I/O never completes (disk hang, NFS timeout, bug in driver):
- The process stays in D-state indefinitely
- SIGTERM stays queued but is never delivered
- SIGKILL is also ineffective - the kernel won't kill a process mid-I/O
  (to prevent filesystem corruption)

```bash
# Check what a D-state process is waiting on
ps -o pid,state,wchan -p 1234
# PID   S  WCHAN
# 1234  D  nfs4_wait_for_lease  <- waiting on NFS!

# Or from /proc
cat /proc/1234/wchan
# nfs4_wait_for_lease
```

> **Code walkthrough:** `/proc/PID/wchan` contains the name of the kernel function a process is currently blocked in. KEY MECHANISM: when a process enters uninterruptible sleep (D-state), the kernel records the wait channel (wchan) in the process descriptor. WHY IT MATTERS: `nfs4_wait_for_lease` points directly to an NFS connectivity problem, enabling targeted remediation rather than generic "process is hung" investigation. WHAT BREAKS: without wchan, D-state diagnosis requires kernel tracing tools; with it, a single `cat` command identifies the subsystem. TAKEAWAY: always check `cat /proc/PID/wchan` for D-state processes before escalating; the function name usually identifies the exact subsystem (nfs, ext4, dm for device-mapper).


The fix is always resolving the underlying I/O issue:
- NFS hang: force-unmount the NFS mount (`umount -f -l`)
- Disk hang: check `dmesg` for I/O errors, `iostat -x` for device issues
- After I/O resolves, the process wakes and can be killed normally

*What separates good from great:* reading the `wchan` column to identify
WHAT kernel function the process is stuck in - showing the diagnostic
depth needed to resolve D-state hangs.

---

### ⚖️ Comparison Table

| Tool | Type | Best Use Case | Limitation |
|------|------|---------------|------------|
| `ps aux` | Snapshot | Script parsing, PID lookup | No live updates |
| `top` | Live TUI | Interactive CPU/memory view | Hard to script |
| `htop` | Live TUI | Mouse support, process trees | Not always installed |
| `pgrep`/`pkill` | Pattern match | Find/kill by name pattern | Needs exact name match |
| `systemctl status` | Service state | Systemd service inspection | Systemd only |
| `jstack`/`jmap` | JVM-specific | Java thread/heap dumps | JVM only |

---

### 🏛️ System Design

*(Omit: ★★☆ process management command reference - system design integration applies at infrastructure architecture level, not individual command usage.)*

---

### 📊 Diagram

*(Omit: command-reference topic - the concepts are demonstrated through code examples and output annotations rather than architectural diagrams.)*

---

---

# Cron Jobs and Scheduled Tasks

**Interview Weight:** Medium - scheduled tasks are universal in
backend systems; understanding cron failure modes and alternatives
is expected at mid-level and above.

---

### 🎯 Model Answer

**30-second answer:**

"Cron is the Unix time-based job scheduler. The crontab format is five
time fields plus a command: minute, hour, day of month, month, day of
week. systemd timers are the modern alternative with better logging,
dependency management, and missed-execution handling. The key production
concern is: what happens when a cron job fails silently or overlaps
with the next scheduled run?"

**3-minute answer:**

"Cron has been the Unix scheduler since the 1970s. The crontab syntax:
`* * * * * command` - five asterisks mean 'every minute'. Fields are
minute (0-59), hour (0-23), day-of-month (1-31), month (1-12), day-of-
week (0-7 where both 0 and 7 are Sunday).

Common patterns: `0 2 * * *` = daily at 2am; `*/5 * * * *` = every
5 minutes; `0 0 * * 0` = weekly on Sunday.

Production problems with cron:
1. Silent failures: cron mails stderr to root by default; if mail isn't
   configured, failures disappear. Fix: always redirect output and use
   exit code monitoring.
2. Overlapping jobs: if a job runs longer than its interval, the next
   run starts a second instance. Fix: use file locking (`flock`) or
   single-instance guards.
3. Environment: cron has a minimal environment (see Shell Basics section).
4. Missed executions: if the system is down at the scheduled time, cron
   skips the job. Fix: use `anacron` for daily/weekly jobs that must
   run even if the system was off during the scheduled time.

systemd timers solve most of these: they log to journald (searchable),
support `OnBootSec`/`OnActiveSec` for missed execution catchup, and
can depend on other units."

**Blank Mind Recovery:**

"Cron syntax: minute hour day-of-month month day-of-week command.
`0 2 * * *` = daily 2am. Problems: silent failures, overlapping runs,
minimal environment. systemd timers = modern alternative with better
logging and dependency handling."

---

### 📘 Concept Explanation

**What it is:**

Cron is a Unix daemon that executes scheduled commands at specified
times. The cron daemon reads crontab (cron table) files and executes
commands at the specified intervals. systemd timers are the systemd-
native alternative.

**The problem it solves:**

Production systems need recurring tasks: database backups, log rotation,
cache warming, health checks, report generation, certificate renewal.
Without a scheduler, these require custom daemon processes or manual
execution.

**How it works:**

Crontab format:
```
# m  h  dom  mon  dow  command
  0  2  *    *    *    /opt/scripts/backup.sh
# ↑  ↑   ↑    ↑    ↑
# min hr  day  month  weekday
```

> **Code walkthrough:** The cron field comments show the five-field time specification: minute (0-59), hour (0-23), day-of-month (1-31), month (1-12), day-of-week (0-7, both 0 and 7 = Sunday). `0 2 * * *` means "at minute 0 of hour 2, every day" = 2:00 AM daily. KEY MECHANISM: `*` is a wildcard matching any value. WHY IT MATTERS: when BOTH day-of-month AND day-of-week are non-`*`, cron uses OR logic (runs when EITHER matches). WHAT BREAKS: `0 2 1 * 1` means "2 AM on the 1st of the month OR every Monday" - not "2 AM on the first Monday". TAKEAWAY: always test cron expressions with `crontab.guru`; the OR semantics for day fields is the most common source of unintended executions.


Special strings: `@reboot`, `@daily`, `@hourly`, `@weekly`, `@monthly`
as shortcuts.

The cron daemon wakes every minute, checks all crontab files, and
executes commands whose time expression matches the current time. The
command runs in a new subshell with a minimal environment.

systemd timer structure (two files):
1. `myjob.service` - what to run
2. `myjob.timer` - when to run it (using systemd time syntax)

**The key insight:**

Cron provides no built-in protection against overlapping executions.
If a backup job starts at 2:00 AM and takes 3 hours, the 2:00 AM job
is still running when the (hypothetical) 3:00 AM run starts. Without
a lock, two instances run simultaneously, potentially corrupting the
backup.

**When to use systemd timers vs cron:**

systemd timers: when you need logging, dependency management, better
failure handling, or missed-execution catchup. On any systemd system.

cron: for compatibility, for user-level cron jobs without root access,
or on non-systemd systems (Alpine, some containers).

**When NOT to use cron for critical tasks:**

For tasks that must complete reliably and with guaranteed single
execution, use a proper job scheduler (Celery Beat, Quartz, Kubernetes
CronJob) with locking, retry, and distributed coordination support.

**Alternatives:**

- systemd timers: better cron for systemd systems
- Kubernetes CronJob: for containerized scheduled tasks
- Celery Beat: for Python application-integrated scheduling
- Airflow: for DAG-based complex workflows
- AWS EventBridge: for cloud-native scheduling

**First-principles derivation:**

"Scheduled tasks need: a time expression format (when to run), an
execution environment (what to run), failure notification, and
idempotency guarantees (what if two instances overlap). Cron provides
the first two; the others require additional patterns."

---

### 💻 Code Example

```bash
# crontab operations
crontab -l           # list current user's crontab
crontab -e           # edit crontab (opens in $EDITOR)
crontab -r           # remove crontab (careful!)
crontab -u root -l   # view root's crontab

# System-wide cron locations
ls /etc/cron.d/      # per-package/service cron files
ls /etc/cron.daily/  # scripts run daily by run-parts
ls /etc/cron.hourly/ # scripts run hourly

# Example crontab entries
# Daily backup at 2:30 AM
30 2 * * * /opt/scripts/backup.sh >> /var/log/backup.log 2>&1

# Every 5 minutes health check
*/5 * * * * /opt/scripts/healthcheck.sh > /dev/null 2>&1

# First Monday of each month at 6 AM
0 6 1-7 * 1 /opt/scripts/monthly-report.sh

# Only run on weekdays
0 8 * * 1-5 /opt/scripts/daily-report.sh

# Prevent overlapping with flock
*/10 * * * * flock -n /var/run/myjob.lock /opt/scripts/myjob.sh
# -n: non-blocking (skip run if already locked)
```

> **Code walkthrough:** `flock -n /var/run/myjob.lock cmd` acquires
an exclusive lock on the lock file before executing the command. KEY
MECHANISM: if another instance already holds the lock (a previous run
still going), `flock -n` returns immediately with exit code 1 rather
than waiting; the cron job is skipped for this interval. WHY IT MATTERS:
without this guard, a slow nightly backup that takes 2 hours would spawn
a second backup instance at the next run, doubling disk and CPU load.
WHAT BREAKS: if the script crashes and the lock file persists, the next
run is blocked - but `flock` uses kernel file locking which is
automatically released when the process dies, even on crash. TAKEAWAY:
`flock -n /tmp/myjob.lock cmd` is the correct single-instance guard for
cron jobs - the lock is always released automatically even on crash.

```bash
# systemd timer: modern alternative

# Create the service unit
cat > /etc/systemd/system/cleanup.service <<'EOF'
[Unit]
Description=Daily cleanup job
After=network.target

[Service]
Type=oneshot
User=appuser
ExecStart=/opt/scripts/cleanup.sh
StandardOutput=journal
StandardError=journal
EOF

# Create the timer unit
cat > /etc/systemd/system/cleanup.timer <<'EOF'
[Unit]
Description=Run cleanup daily at 2 AM

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true     # run if last trigger was missed
AccuracySec=1min    # run within 1 minute of scheduled time

[Install]
WantedBy=timers.target
EOF

# Enable and start
systemctl daemon-reload
systemctl enable --now cleanup.timer

# Monitor
systemctl list-timers --all
journalctl -u cleanup.service -n 50
```

> **Code walkthrough:** `Persistent=true` in the timer unit makes
systemd run the job immediately on next boot if the last scheduled
run was missed (system was down). KEY MECHANISM: systemd stores the
last activation time in the unit's state; on boot, it compares the
current time to the last activation and runs the service if the
interval passed. WHY IT MATTERS: a cron job scheduled for 2 AM is
simply skipped if the machine is down at 2 AM; with `Persistent=true`,
the systemd timer catches up on the next boot - critical for backup
jobs. WHAT BREAKS: `Persistent=true` runs the job immediately on boot
which can overload startup if many timers have Persistent=true and the
system was down for a long period. TAKEAWAY: use `Persistent=true`
for backup and maintenance jobs, not for polling jobs that should run
on their regular schedule only.

---

### 🎓 Answers by Seniority

**Junior/Mid:**

"Cron jobs use a 5-field time expression (minute hour day month weekday)
to schedule commands. I redirect output to log files and stderr to the
same file with 2>&1. Common issues: cron has a minimal PATH so I use
absolute paths, and failures can be silent if mail isn't configured."

**Senior/Staff:**

"Cron is a 50-year-old tool with known production issues. My approach:
always use `flock` for single-instance guarantees, always log both
stdout and stderr with timestamps, and use a wrapper that sends failures
to Slack/PagerDuty. For new systems, I use systemd timers: they log
to journald (searchable, retained), support `Persistent=true` for
missed-execution catchup, and have proper dependency management.
For distributed scheduled jobs (multiple application instances), I use
Kubernetes CronJobs or a distributed lock-aware scheduler like Celery
Beat - cron has no awareness of multiple instances, so a bare cron
job on 3 application servers runs 3x. The biggest production cron
anti-pattern is silent failure: a backup job that silently fails for
weeks because nobody checked the output."

---

### ⚠️ Common Misconceptions

**Misconception 1: "Cron runs the full user environment."**

Cron runs with a minimal environment: no `.bashrc`, `.profile`, or
`.bash_profile` sourced. `PATH` is usually just `/usr/bin:/bin`.
HOME is set to the user's home directory. This is the most common
cause of "works manually but fails in cron."

**Misconception 2: "*/5 * * * * runs every 5 minutes of every hour."**

`*/5` means "every value divisible by 5" - so minutes 0, 5, 10, 15,
20, 25, 30, 35, 40, 45, 50, 55. This is every 5 minutes, which is
correct. `0,5,10,15,20,25,30,35,40,45,50,55 * * * *` is equivalent.
The confusion is `1-5` (range) vs `*/5` (step) vs `1,5` (list).

**Misconception 3: "Cron jobs run as root by default."**

User crontabs (`crontab -e`) run as that user. `/etc/crontab` and
`/etc/cron.d/` files specify the user in an additional column:
`0 2 * * * root /opt/backup.sh`. Scripts in `/etc/cron.daily/` are
run by `run-parts` as root. The user context matters for file access,
environment variables, and security auditing.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Cron job silently fails - no logs, no alerts**

```bash
# Common symptom: backup not created, no error visible

# Step 1: verify cron ran at all
grep CRON /var/log/syslog | grep backup | tail -10
# Jan 15 02:00:01 host CRON[1234]: (appuser) CMD (/opt/backup.sh)
# Cron ran - but what happened?

# Step 2: check for email (cron's default output mechanism)
mail -u appuser   # check for cron output mail
# Or: /var/mail/appuser

# Step 3: crontab had no logging - fix by adding logging to job
# BAD (no output):
0 2 * * * /opt/backup.sh

# GOOD (captures all output):
0 2 * * * /opt/backup.sh >> /var/log/backup.log 2>&1

# BETTER (with timestamp):
0 2 * * * echo "$(date): starting backup" >> /var/log/backup.log && \
  /opt/backup.sh >> /var/log/backup.log 2>&1; \
  echo "$(date): exit code $?" >> /var/log/backup.log

# Step 4: test the command manually as the cron user
# Use the exact environment cron uses
sudo -u appuser bash -c 'source /etc/environment; /opt/backup.sh'

# Step 5: check if cron daemon is running
systemctl status cron.service  # Debian/Ubuntu
systemctl status crond.service # RHEL
```

> **Code walkthrough:** The test command `sudo -u appuser bash -c
'source /etc/environment; /opt/backup.sh'` simulates cron's environment
by switching user and using a non-login, non-interactive shell. KEY
MECHANISM: cron starts a non-login shell with only `/etc/environment`
and the user's explicitly set environment - not `.bashrc` or `.profile`.
WHY IT MATTERS: most cron failures are environment issues (missing
PATH, unset variables) that only manifest in cron's minimal environment.
WHAT BREAKS: even with this test, the exact cron environment differs
slightly; the most reliable test is adding a debug cron entry that
runs `env > /tmp/cron_env.txt` to capture the exact environment.
TAKEAWAY: always add `>> /var/log/myjob.log 2>&1` to every cron entry
and add startup/exit log lines - silent failure is not an option in
production scheduled jobs.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | cron syntax, systemd timers, scheduling |
| Debugging | 3 | silent failures, overlapping, env |
| Trade-off | 3 | cron vs systemd, distributed scheduling |

---

**[JUNIOR] Q1 - Write a cron job that runs a backup script daily at 3 AM and sends an alert if it fails.**

```bash
# crontab entry
0 3 * * * /opt/scripts/backup_wrapper.sh

# Wrapper script: /opt/scripts/backup_wrapper.sh
#!/bin/bash
set -euo pipefail

LOG="/var/log/backup/backup-$(date +%Y%m%d).log"
ALERT_ENDPOINT="https://hooks.slack.com/services/..."
mkdir -p "$(dirname "$LOG")"

echo "=== Backup started at $(date) ===" >> "$LOG"

if /opt/scripts/backup.sh >> "$LOG" 2>&1; then
    echo "=== Backup completed at $(date) ===" >> "$LOG"
else
    EXIT_CODE=$?
    echo "=== Backup FAILED at $(date), exit: $EXIT_CODE ===" >> "$LOG"

    # Alert: send to Slack
    curl --silent --fail --max-time 10 \
      -X POST "$ALERT_ENDPOINT" \
      -H 'Content-type: application/json' \
      --data "{\"text\": \"Backup failed on $(hostname) at $(date).
Check: $LOG\"}" || true
    # 'true' prevents curl failure from masking backup failure

    exit $EXIT_CODE
fi
```

> **Code walkthrough:** Capturing `EXIT_CODE=$?` immediately after the critical command preserves it before any subsequent command overwrites `$?`. KEY MECHANISM: in bash, `$?` holds only the exit code of the most recently completed command; an `if` statement or `echo` will overwrite it. WHY IT MATTERS: the cleanup runs unconditionally (ensuring resources are freed even on failure), then the script exits with the original job's status code so monitoring systems can detect failures. WHAT BREAKS: checking `if [ $? -ne 0 ]` AFTER running cleanup is a bug because cleanup itself changes `$?`. TAKEAWAY: always capture `$?` immediately; deferred capture is one of the most common bash scripting bugs in cron jobs.


The wrapper pattern: separate the scheduling concern (crontab) from
the monitoring concern (wrapper script). The wrapper adds logging,
exit code handling, and alerting without touching the backup script.
This is the production standard.

*What separates good from great:* using a daily-named log file
(not a single overwritten log) and adding start/end timestamps that
make runtime duration visible.

---

**[JUNIOR] Q2 - How do you prevent a cron job from running multiple instances simultaneously?**

```bash
# Method 1: flock (kernel file locking)
*/5 * * * * flock -n /var/run/myjob.lock /opt/scripts/myjob.sh
# -n: don't wait, exit immediately if locked
# Lock is released automatically when process exits (even on crash)

# Method 2: PID file check (manual, less safe)
#!/bin/bash
PIDFILE=/var/run/myjob.pid
if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
    echo "Already running, exiting"
    exit 0
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT
# ... rest of script ...

# Method 3: flock with wait (queue instead of skip)
*/5 * * * * flock -w 0 /var/run/myjob.lock /opt/scripts/myjob.sh
# -w 0: wait up to 0 seconds (same as -n)
# -w 300: wait up to 300 seconds (next run waits for current)

# Method 4: systemd service with ExecStart= (systemd handles overlap)
# In service unit:
[Service]
Type=oneshot
ExecStart=/opt/scripts/myjob.sh
# systemd will NOT start a new instance if one is already running
```

> **Code walkthrough:** `Type=oneshot` tells systemd this service runs a short process that exits normally when complete, unlike `Type=simple` which expects the process to stay running. KEY MECHANISM: systemd will not start a new instance if the previous run is still in progress (by default), providing free overlap prevention unlike cron. WHY IT MATTERS: a cron job running longer than its schedule interval creates overlapping instances that corrupt state; systemd timers prevent this automatically. WHAT BREAKS: using `Type=simple` for a batch job causes systemd to consider it failed when it exits normally. TAKEAWAY: use `Type=oneshot` for batch jobs; add `RemainAfterExit=yes` if you need the service to show as active after completion for dependency ordering.


`flock` is the safest method because the kernel releases the lock
automatically when the process dies for any reason (crash, SIGKILL,
OOM kill). PID file methods have race conditions if the script exits
abnormally without running the cleanup trap.

*What separates good from great:* explaining WHY `flock` is safer than
PID files - the kernel file lock release guarantee vs the trap-based
PID file cleanup that can fail on abnormal exit.

---

**[JUNIOR] Q3 - What are systemd timers and what advantages do they have over cron?**

systemd timers are two-file constructs: a `.timer` unit defines when
to run, and a corresponding `.service` unit defines what to run. They
replace cron on modern Linux systems.

Key advantages over cron:

1. **Logging:** Output goes to journald, searchable with `journalctl
   -u myservice.service`. Cron mails output to root by default.

2. **Missed execution handling:** `Persistent=true` runs the job at
   next boot if the scheduled time was missed (system was off).
   Cron simply skips missed runs.

3. **Dependency management:** `After=network.target` waits for
   network before running. Cron has no concept of dependencies.

4. **Status visibility:** `systemctl list-timers` shows next run
   time, last run time, and whether the last run succeeded.

5. **Single instance:** systemd won't start a new service instance
   if the previous one is still running (with `Type=oneshot`).

6. **Randomized delay:** `RandomizedDelaySec=30min` prevents
   "thundering herd" when many nodes schedule the same job.

Trade-offs:
- More verbose (two files vs one crontab line)
- Not portable outside systemd (not available in containers,
  Alpine, BSD, macOS)
- Learning curve for systemd unit syntax

*What separates good from great:* mentioning `RandomizedDelaySec` for
distributed systems where all nodes run the same cron job simultaneously
(thundering herd effect on shared resources).

---

**[MID] Q4 - How do you debug a cron job that works when run manually but fails in cron?**

This is the most common cron debugging scenario. The root cause is
almost always the environment difference.

Systematic debugging:

```bash
# Step 1: capture exact cron environment
# Add temporary cron entry:
* * * * * env > /tmp/cron_environment.txt

# Compare with manual environment
env | sort > /tmp/manual_environment.txt
diff /tmp/manual_environment.txt /tmp/cron_environment.txt

# Common differences:
# - PATH: cron has /usr/bin:/bin; manual has many more directories
# - HOME: may differ
# - LANG/LC_ALL: locale settings often missing in cron
# - Credential env vars: AWS_PROFILE, JAVA_HOME, etc.

# Step 2: run the script simulating cron's environment
env -i HOME=/home/appuser PATH=/usr/bin:/bin \
  USER=appuser \
  bash -c '/opt/scripts/myjob.sh > /tmp/cron_test.log 2>&1'

# Step 3: add PATH and env setup to the crontab entry
0 3 * * * PATH=/usr/local/bin:/usr/bin:/bin \
           JAVA_HOME=/opt/java-21 \
           /opt/scripts/backup.sh >> /var/log/backup.log 2>&1

# Step 4: add MAILTO to suppress mail and capture in log
MAILTO=""    # disable email (put at top of crontab)
```

> **Code walkthrough:** Setting `MAILTO=""` at the top of a crontab suppresses all email output, which is the correct default for production jobs. KEY MECHANISM: cron sends any stdout/stderr output to the system mail account unless MAILTO is set; empty string disables delivery entirely. WHY IT MATTERS: most production servers and containers have no working MTA; undelivered mail accumulates in the mail queue and eventually fills the spool directory. WHAT BREAKS: omitting MAILTO on a verbose job running every minute can produce thousands of queued mails per day. TAKEAWAY: always set `MAILTO=""` and redirect job output to a log file with `>>/var/log/job.log 2>&1` for durable, reviewable logging.


The environment debug approach (`env -i`) is the most reliable method:
it creates the exact minimal environment and runs the script within it,
reproducing the cron failure mode interactively.

*What separates good from great:* using `env -i` to simulate cron's
stripped environment (not just `sudo -u appuser`) - the `-i` flag
discards the current environment entirely, matching cron's behavior.

---

**[MID] Q5 - How do you schedule a task to run on multiple servers without duplicate execution?**

Running cron on multiple servers without coordination causes duplicate
execution - all servers run the job simultaneously. This creates race
conditions for shared resources (databases, S3 buckets, external APIs).

Approaches:

1. **Designate a single cron host:** Only one server in the fleet has
   the cron entry. Simple but not fault-tolerant (job is lost if that
   server is down).

2. **Distributed lock via Redis:**

```bash
#!/bin/bash
LOCK_KEY="myjob:lock:$(date +%Y-%m-%d)"
LOCK_TTL=86400  # 24 hours - prevents re-run same day

# Acquire distributed lock via Redis
ACQUIRED=$(redis-cli SET "$LOCK_KEY" 1 NX EX $LOCK_TTL)
if [[ "$ACQUIRED" != "OK" ]]; then
    echo "Another server is running this job, exiting"
    exit 0
fi

# Run the job
/opt/scripts/the_actual_job.sh
```

> **Code walkthrough:** `env -i /bin/bash --login` starts a minimal login shell stripped of all inherited environment variables, closely simulating the environment cron provides. KEY MECHANISM: cron runs jobs with only HOME, LOGNAME, USER, and a minimal PATH set; all other variables (JAVA_HOME, AWS_PROFILE, PYTHONPATH, etc.) are absent. WHY IT MATTERS: "works manually, fails in cron" is almost always an environment variable dependency issue. WHAT BREAKS: not using `env -i` when testing means the test environment inherits your full shell environment, masking the problem. TAKEAWAY: always test cron jobs with `env -i /bin/bash --login -c 'your-job'` to catch environment dependency issues before they cause production failures.


3. **Kubernetes CronJob:** Creates exactly one Job pod per schedule
   with configurable `concurrencyPolicy` (Forbid, Replace, Allow).

4. **Celery Beat with database backend:** One Beat scheduler per
   environment, reads schedule from a shared database.

5. **AWS EventBridge + Lambda:** Cloud-native scheduling with exactly-
   once delivery semantics.

*What separates good from great:* knowing that Redis `SET ... NX EX`
(set if not exists, with expiry) is the correct distributed lock
pattern - using NX for atomic lock acquisition and EX for automatic
lock expiry to prevent deadlock if the holder crashes.

---

**[MID] Q6 - What is anacron and when should you use it instead of cron?**

`anacron` (anakronos = not in time) is a cron variant that guarantees
jobs run even if the system was powered off at the scheduled time. Unlike
cron (which skips jobs that were missed), anacron stores the last
execution time and runs the job on the next system start if the
scheduled interval has passed.

anacron limitations:
- Only supports daily/weekly/monthly granularity (not hourly or minutes)
- Designed for laptops and systems that are not always on
- Typically runs as root (user-level anacron is not standard)
- Runs jobs with configurable delay after startup (to avoid boot overload)

When to use anacron:
- Developer laptops or workstations that are not always on
- Daily/weekly maintenance tasks (package cleanup, log rotation) that
  should not be permanently skipped if the machine was off
- VMs or spot instances that are frequently stopped and started

When NOT to use anacron:
- Always-on servers: use cron or systemd timers instead
- Jobs with sub-daily precision requirements
- Production services requiring exact scheduling

```bash
# /etc/anacrontab format:
# period  delay  job-id  command
1         5      daily-backup  /opt/scripts/backup.sh
7         10     weekly-report /opt/scripts/report.sh
# period=1 -> daily; delay=5 -> 5 minutes after anacron starts
```

> **Code walkthrough:** The anacron configuration shows three fields: period (1=daily, 7=weekly), startup delay in minutes, identifier, then command. KEY MECHANISM: unlike cron's absolute time scheduling, anacron checks when each job last ran (via /var/spool/anacron/JOB-ID timestamp) and runs it if the period has elapsed. WHY IT MATTERS: on laptops or systems with maintenance windows, cron jobs at 2 AM never run if the system is off; anacron runs them at the next startup. WHAT BREAKS: the delay field prevents all jobs from running simultaneously at startup - removing it causes a boot storm of parallel jobs. TAKEAWAY: use anacron for "must run at least once per day/week" jobs; use cron when exact execution time matters.


*What separates good from great:* explaining that systemd timers with
`Persistent=true` are the modern replacement for anacron on systemd
systems - providing the same missed-execution guarantee with better
integration.

---

**[SENIOR] Q7 - A cron job runs fine in testing but fails silently in production with no error in syslog. How do you diagnose it?**

Silent cron failures have three common causes: environment variables
missing, output suppression hiding errors, or the job exits with code
0 despite failing.

Diagnosis workflow:

1. Check the cron daemon log first:
   `grep CRON /var/log/syslog | tail -50`
   or `journalctl -u cron -n 50`
   Cron logs whether it attempted to run the job and whether it found
   errors parsing the crontab.

2. Reproduce the exact cron environment:
   `env -i HOME=/root USER=root /bin/bash --login -c '/your/job.sh'`
   This reveals missing JAVA_HOME, PATH, AWS credentials, etc.

3. Enable explicit logging in the job:
   ```bash
   #!/bin/bash
   exec >> /var/log/myjob.log 2>&1
   set -x   # trace all commands
   date
   # ... job commands ...
   ```

> **Code walkthrough:** This bash script redirects all stdout/stderr to a log file with `exec >>` before any command runs, then enables `set -x` trace mode which prints every command to stderr before executing it. KEY MECHANISM: the `exec >>` redirect applies to the entire script's file descriptor table, capturing output from every subsequent command including subshells. WHY IT MATTERS: cron jobs fail silently without this - no output means no evidence. WHAT BREAKS: omitting `2>&1` captures stdout but misses stderr where most error messages go. TAKEAWAY: prefix every cron job script with `exec >> /var/log/job.log 2>&1` and add `set -x` during active debugging.

4. Check exit code handling:
   ```bash
   # BAD: masks failures
   do_work || true   # always exits 0

   # GOOD: explicit failure propagation
   do_work
   EXIT=$?
   echo "Exit: $EXIT"
   exit $EXIT
   ```

> **Code walkthrough:** The BAD pattern `do_work || true` converts any non-zero exit code to 0, silently discarding failure information. KEY MECHANISM: `||` evaluates the right side only when the left side fails; `true` always succeeds, making the composite exit code always 0. WHY IT MATTERS: monitoring systems and cron mail triggering depend on non-zero exit codes to detect failures; swallowing them makes all runs look successful. WHAT BREAKS: entire categories of production failures go undetected when `|| true` is used as a blanket error suppressor. TAKEAWAY: always capture and propagate exit codes; use explicit error handling instead of `|| true`.

5. Verify crontab parsing with `crontab -l` and
   `crontab -e` (edit; save without changes to trigger syntax check).

*What separates good from great:* the insight that cron jobs
"fail silently" is almost always caused by `|| true` or similar
patterns masking real failures combined with `MAILTO=""` suppressing
the evidence - senior engineers always add explicit logging and
meaningful exit codes before trusting "no news is good news."

---

**[SENIOR] Q8 - How do you prevent multiple instances of a cron job from running simultaneously when the job takes longer than its schedule interval?**

Cron has no built-in concurrency control. If a job scheduled every
5 minutes takes 10 minutes, you get two overlapping instances.

Common approaches ranked by reliability:

1. **flock (kernel-level exclusive lock):**
   ```bash
   #!/bin/bash
   exec 9>/var/lock/myjob.lock
   flock -n 9 || { echo "Already running"; exit 1; }
   # ... job body ...
   ```

> **Code walkthrough:** `exec 9>/var/lock/myjob.lock` opens the lock file on file descriptor 9; `flock -n 9` attempts a non-blocking exclusive lock, returning non-zero immediately if another process holds it. KEY MECHANISM: the lock is an advisory kernel-level exclusive lock on the file inode, automatically released when the process exits - including crashes and SIGKILL - because the kernel closes all file descriptors on process termination. WHY IT MATTERS: unlike PID files, flock requires zero cleanup code and is crash-safe by design. WHAT BREAKS: using PID files instead requires cleanup code that may not run on crash, leading to stale locks that prevent the job from ever running again. TAKEAWAY: prefer `flock` over PID files for all cron job overlap prevention.

   `flock -n 9` acquires an exclusive lock on FD 9 non-blocking.
   If another instance holds the lock, exits immediately.
   Lock is automatically released when the process exits
   (even on crash) - no stale lock files.

2. **run-one (Ubuntu/Debian package):**
   `* * * * * run-one /opt/scripts/job.sh`
   Wrapper that uses flock internally.

3. **Systemd timer with Type=oneshot (prevents overlap natively):**
   Systemd will not start a new instance if the previous unit
   is still active - zero code required.

4. **PID files (fragile - avoid in production):**
   PID files go stale when a process crashes; they require
   manual cleanup and are race-prone. Prefer flock.

The correct pattern in production:
- Use `flock` for cron-based jobs (simple, reliable)
- Migrate to systemd timers for new jobs (no code needed)
- Never use sleep loops or manual PID files

*What separates good from great:* knowing that `flock` uses a
kernel advisory lock that is atomically released on process exit
(no cleanup code needed, crash-safe), versus PID files which require
careful cleanup and are vulnerable to stale state after crashes.

---

**[STAFF] Q9 - When should you migrate from cron to systemd timers, and what are the production tradeoffs?**

Cron and systemd timers serve overlapping but distinct use cases.
The migration decision depends on what you gain versus what you lose.

**Systemd timer advantages:**

1. **Built-in overlap prevention** - Type=oneshot prevents a new
   instance from starting while the previous is active (no flock code)
2. **Structured logging** - all output goes to journald:
   `journalctl -u myjob.service --since "1 hour ago"`
3. **Dependency ordering** - `After=postgresql.service` ensures
   the job waits for the database before running
4. **Activation modes** - `OnBootSec=15min`, `OnCalendar=weekly`,
   `OnActiveSec=1h` (after each run, not calendar) for flexible scheduling
5. **Resource controls** - `CPUQuota=20%`, `MemoryMax=512M` in the
   unit file without manual nice/ulimit

**Cron advantages:**

1. **Universal availability** - works on every Unix system including
   containers without systemd
2. **Per-user crontabs** - non-root users can schedule jobs without
   admin privileges or writing unit files
3. **Simpler syntax** - five fields versus writing two files
   (.service + .timer)
4. **Lower adoption barrier** - every sysadmin knows crontab syntax

**Migration guideline:**
- Keep cron for: simple one-liners, per-user scheduled tasks,
  containers without systemd, scripts running on heterogeneous OS mix
- Migrate to systemd timers for: long-running jobs, jobs with
  system dependencies, jobs needing resource controls, jobs where
  overlap is a real risk

*What separates good from great:* recognizing that "OnActiveSec=1h"
(1 hour after the previous run completes) versus "OnCalendar=hourly"
(at the top of every hour) is fundamentally different - the former
prevents backlog accumulation when jobs run long, while the latter
can create a queue of waiting runs during incidents.

---

### ⚖️ Comparison Table

| Feature | cron | systemd timers | `at` | anacron |
|---------|------|----------------|------|---------|
| Missed run recovery | No | Persistent option | No | Yes |
| Overlap prevention | Manual (`flock`) | Yes (`Type=oneshot`) | N/A | No |
| Environment control | Minimal PATH | Full unit env | Inherited | Like cron |
| Logging | Email only | journald | Email | journald |
| Per-user scheduling | Yes | Root only | Yes | Root only |
| Granularity | Minute | Second | Once | Day/week/month |

---

### 🏛️ System Design

*(Omit: ★★☆ scheduled tasks command reference - system design for job orchestration at scale is covered in the L4+ Kubernetes and distributed systems topics.)*

---

### 📊 Diagram

*(Omit: non-visual concept - cron and systemd timer interactions are better illustrated through configuration examples than architectural diagrams.)*
