---
layout: default
title: "NoSQL - L3 Advanced Redis"
parent: "NoSQL"
nav_order: 7
permalink: /nosql/l3-advanced-redis/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Redis Persistence: RDB vs AOF](#redis-persistence-rdb-vs-aof) | ★★☆ |
| 2 | [Redis Cluster and High Availability](#redis-cluster-and-high-availability) | ★★☆ |

---

# Redis Persistence: RDB vs AOF

---

### 🎯 Model Answer

**30 seconds:**
> Redis offers two persistence mechanisms: RDB (snapshot) saves a point-in-time
> snapshot of all data to disk at intervals; AOF (Append-Only File) logs every write
> command as it executes. RDB is compact and restores fast but can lose minutes of
> data. AOF is durable (configurable to lose at most 1 second) but the file grows large
> and recovery is slower. Most production systems use both: AOF for durability, RDB for
> fast restarts.

**3 minutes (Senior):**
> RDB: a fork-based snapshot. Redis calls `fork()` to create a copy-on-write child
> process; the child writes the entire dataset to disk; the parent continues serving
> requests. The `fork()` can cause a latency spike (100ms-seconds on large datasets) and
> temporarily doubles memory usage (COW pages). Configured with `save 900 1` (save every
> 900 seconds if at least 1 key changed). RDB file is compact (binary, compressed); full
> dataset restoration is faster than AOF replay. Weakness: if Redis crashes between
> snapshots, all writes since the last snapshot are lost.
>
> AOF: every write command (`SET`, `HSET`, `LPUSH`, etc.) is appended to the AOF file.
> `fsync` policy: `always` (fsync after every command, slowest, most durable), `everysec`
> (fsync once per second, at most 1 second of data loss - the standard choice), `no`
> (OS decides when to flush, fastest, most data can be lost). AOF Rewrite: periodically
> compacts the AOF by replaying current state (no historical commands needed); configured
> with `auto-aof-rewrite-percentage 100` (rewrite when file doubles in size).

**Framework:** RDB (periodic snapshot, fast recovery, potential data loss) vs AOF (every write, slow recovery, configurable durability) -> Use both (AOF=durability, RDB=recovery speed)

**Blank Mind Recovery:**

**(1) Restate:** "Redis persistence: RDB=snapshot at intervals (fast restore, loses
minutes). AOF=log every write (durable, 1s loss, slow restore). Production: use both.
RDB for backup/restart speed, AOF for durability."

**(2) First principles:** "Redis is in-memory. Without persistence, a crash loses all
data. RDB saves state periodically (cheap, periodic). AOF saves every change (expensive,
continuous). Both are persistence strategies with different durability-performance
trade-offs."

**(3) Bridge:** "RDB is like a daily photo of your whiteboard. AOF is like recording
every pen stroke in a video. The photo is faster to restore from; the video loses
nothing but takes longer to replay. Using both gives you a recent photo and only a
few seconds of video to replay on top."

---

### 📘 Concept Explanation

**RDB Persistence Mechanics:**

```text
RDB SNAPSHOT FLOW:

  Parent Process (serving requests)
          |
          | fork()
          |
     +----+----+
     |         |
  Parent    Child (copy-on-write)
  continues  |
  writes     | writes full dataset
             | to temp file
             |
             v
         dump.rdb
             |
         atomic rename
             |
         final dump.rdb

  FORK COST:
    1 GB dataset -> ~10ms fork
    10 GB dataset -> ~100-500ms fork
    50 GB dataset -> can cause second-long
      pause (kernel copies page tables)

  COPY-ON-WRITE:
    Parent modifies key -> new page allocated
    Both parent and child have correct view
    Peak memory: up to 2x dataset size
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the RDB snapshot flow using `fork()` with
> copy-on-write, showing the parent and child process relationship and the fork cost. (2)
> HOW TO READ IT: left-to-right; the parent calls `fork()`; the child inherits all memory
> pages marked copy-on-write; the child writes the snapshot while the parent continues
> serving requests; modified pages cause new physical memory allocation. (3) KEY
> RELATIONSHIP: the fork creates an instantaneous consistent point-in-time view without
> locking; this is the key insight - Redis can take a snapshot of its entire dataset
> without pausing request serving. (4) EDGE CASE: on a large dataset with high write rate,
> copy-on-write page copying can consume nearly 2x the normal memory; if the server runs
> near 50% memory utilization, the fork can trigger OOM; ensure Redis servers have at
> least 2x the dataset size available as RAM. (5) INSIGHT: a senior engineer notices that
> the fork latency scales with the page table size, not just the dataset size; modern Linux
> uses Transparent Huge Pages (THP) which can dramatically increase fork time; always
> disable THP on Redis servers (`echo never > /sys/kernel/mm/transparent_hugepage/enabled`).

**AOF Durability Levels:**

```text
AOF FSYNC POLICY COMPARISON:

  Policy      Frequency    Max Data Loss  Throughput
  always      per command  0              Very low
  everysec    1/second     1 second       High (default)
  no          OS decides   up to minutes  Maximum

  AOF FILE GROWTH:
  Commands: SET a 1, SET a 2, SET a 3
  AOF:  *3\r\n$3\r\nSET\r\n$1\r\na\r\n$1\r\n1\r\n
        *3\r\n$3\r\nSET\r\n$1\r\na\r\n$1\r\n2\r\n
        *3\r\n$3\r\nSET\r\n$1\r\na\r\n$1\r\n3\r\n
  -> All 3 commands stored (only last matters)

  AOF REWRITE (compaction):
  After rewrite: only SET a 3 stored
  File size drastically reduced
  Triggered when file doubles in size

  AOF RECOVERY:
  Redis replays each command sequentially
  Large AOF -> slow startup (vs RDB snapshot)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the three AOF fsync policies, AOF file
> growth with redundant commands, and AOF rewrite compaction. (2) HOW TO READ IT: the
> table at top shows the trade-off between durability and throughput; the AOF file example
> shows how multiple SETs to the same key accumulate redundant commands; the rewrite
> section shows how compaction reduces the file to current state only. (3) KEY
> RELATIONSHIP: AOF durability is controlled by fsync frequency; `everysec` is the
> standard because it limits data loss to 1 second while maintaining good throughput;
> `always` is only for systems where zero data loss is required and throughput is
> acceptable at lower levels. (4) EDGE CASE: AOF rewrite also uses `fork()` and has
> the same memory/latency implications as RDB snapshots; configuring both auto RDB
> snapshots and auto AOF rewrite can cause two concurrent forks, doubling the memory
> pressure. (5) INSIGHT: a senior engineer configures AOF rewrite to run during off-peak
> hours using a manual `BGREWRITEAOF` command via cron rather than relying on auto-rewrite
> during peak traffic.

---

### 💻 Code Example

```bash
# Redis persistence configuration (redis.conf)

# --- RDB Configuration ---
# Save every 900 sec if at least 1 key changed
save 900 1
# Save every 300 sec if at least 10 keys changed
save 300 10
# Save every 60 sec if at least 10000 keys changed
save 60 10000

# Disable RDB (cache-only mode):
# save ""

# RDB file name and directory
dbfilename dump.rdb
dir /var/lib/redis/

# --- AOF Configuration ---
appendonly yes
appendfilename "appendonly.aof"
# everysec = lose at most 1 second of data
appendfsync everysec

# AOF rewrite: rewrite when file is 100% larger
# than last rewrite
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# --- Combined (recommended production) ---
# Both RDB and AOF enabled:
# - AOF ensures durability (1-second window)
# - RDB provides fast restart (load from RDB,
#   replay only recent AOF on top)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a production Redis persistence configuration
> using both RDB and AOF, the recommended production setup. (2) KEY MECHANISM: `save`
> directives trigger background RDB snapshots when the conditions are met; `appendonly yes`
> enables AOF; `appendfsync everysec` limits data loss to 1 second; when Redis starts, it
> prefers the AOF file if both exist (AOF is more complete). (3) WHY IT MATTERS: using
> both gives the best of both worlds: AOF for durability (at most 1 second of data loss),
> RDB for fast restarts (load the snapshot, then replay only the small AOF diff since
> the last snapshot). (4) WHAT BREAKS: `auto-aof-rewrite-percentage 100` triggers a
> rewrite every time the AOF doubles; on a write-heavy system, this can trigger rewrites
> frequently; each rewrite uses a fork with the associated memory cost. (5) TAKEAWAY:
> always enable both RDB and AOF in production; use `appendfsync everysec` as the
> standard durability level; monitor AOF file size and rewrite triggers.

```python
import redis

r = redis.Redis(host="redis", port=6379, db=0)

# Force RDB snapshot (BGSAVE)
result = r.execute_command("BGSAVE")
print(result)  # "Background saving started"

# Check if save is in progress
info = r.info("persistence")
print("RDB saving:", info["rdb_bgsave_in_progress"])
print("Last save:", info["rdb_last_save_time"])
print("AOF enabled:", info["aof_enabled"])
print("AOF size:", info["aof_current_size"], "bytes")

# Force AOF rewrite
r.execute_command("BGREWRITEAOF")

# Check last save success
print("Last save status:", info["rdb_last_bgsave_status"])
# "ok" = success; "err" = failure

# MONITOR persistence health (production check)
def check_redis_persistence(redis_client):
    info = redis_client.info("persistence")
    checks = {
        "aof_enabled": info.get("aof_enabled") == 1,
        "rdb_ok": (
            info.get("rdb_last_bgsave_status") == "ok"
        ),
        "aof_ok": (
            info.get("aof_last_write_status") == "ok"
        ),
    }
    failed = [k for k, v in checks.items() if not v]
    if failed:
        raise RuntimeError(
            f"Redis persistence issue: {failed}"
        )
    return checks
```

> **Code walkthrough:** (1) WHAT IT SHOWS: programmatic monitoring of Redis persistence
> health using the `INFO persistence` command and a health check function. (2) KEY
> MECHANISM: `INFO persistence` returns real-time persistence status; `rdb_bgsave_in_progress`
> shows if a snapshot is running; `rdb_last_bgsave_status` shows the result of the last
> snapshot; `aof_last_write_status` shows if AOF writes are succeeding. (3) WHY IT
> MATTERS: RDB save failures are silent by default (Redis continues serving but does
> not retry the save); `rdb_last_bgsave_status: err` indicates the snapshot is failing
> (typically a disk full or permissions issue); without monitoring, the operator does
> not know until a crash results in complete data loss. (4) WHAT BREAKS: if AOF
> `aof_last_write_status` is `err`, Redis has stopped appending to the AOF file; if
> `aof-use-rdb-preamble` is enabled and the RDB prefix is corrupt, the AOF file is
> unrecoverable; always have a backup of the last known-good RDB file. (5) TAKEAWAY:
> include `rdb_last_bgsave_status` and `aof_last_write_status` in your Redis
> monitoring dashboard; alert on any non-ok status immediately.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Redis has two persistence options: RDB takes a snapshot of all data at intervals
> (configurable with `save`). AOF logs every write command. RDB can lose up to minutes
> of data if Redis crashes. AOF can be configured to lose at most 1 second of data
> (`appendfsync everysec`). Most production Redis deployments use both: AOF for
> durability, RDB for faster restarts. For a pure cache (data can be reconstructed),
> disable both to maximize performance. For a session store, enable AOF.

---

**Senior / Staff (5+ years):**
> Redis persistence decisions with production consequences: (1) RDB fork latency - on
> large datasets (> 10 GB), `fork()` can pause Redis for hundreds of milliseconds;
> monitor `latest_fork_usec` in `INFO stats`; if it exceeds 100ms, the dataset is too
> large for reliable RDB snapshots; consider Redis Cluster to split the dataset. (2)
> AOF rewrite triggers - disable auto-rewrite during peak hours; trigger `BGREWRITEAOF`
> manually during off-peak via cron; concurrent RDB and AOF rewrites can double memory
> and cause OOM. (3) Disable THP (Transparent Huge Pages) on Linux - THP increases fork
> copy-on-write overhead significantly; always add `echo never >
> /sys/kernel/mm/transparent_hugepage/enabled` to server startup scripts. (4) Replication
> persistence interaction - a replica with `appendonly yes` saves an AOF independently;
> if a replica is promoted after a primary failure, the AOF ensures the new primary does
> not lose writes; always enable AOF on replicas in high-availability setups.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Enabling AOF makes Redis as durable as a traditional database."**

Redis AOF with `appendfsync everysec` loses at most 1 second of data. This is not the
same as PostgreSQL's WAL which is synchronous (zero data loss on commit). For
`appendfsync always`, Redis is byte-level durable, but the throughput drops significantly
(Redis becomes I/O-bound). Redis is fundamentally an in-memory database; persistence
is a durability enhancement, not the primary storage mechanism. For workloads requiring
strong ACID guarantees (financial transactions, medical records), Redis is not the right
primary database regardless of persistence configuration.

**Misconception 2: "Disabling persistence makes Redis a pure in-memory database."**

With persistence disabled, Redis still writes nothing to disk - this is true. However,
disabling persistence also means the process's virtual memory (via `mmap` or similar)
may still interact with the OS swap space. More importantly, Redis can operate as a
cache with `maxmemory` policy (e.g., `allkeys-lru`) without any persistence; data
eviction handles capacity limits. The misconception is that "in-memory" means "never
touches disk"; in reality, the OS can swap Redis process memory to disk even with
persistence disabled; configure `vm.overcommit_memory = 1` and sufficient swap space
or use `noeviction` policy to prevent swap usage.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Slow Redis response during RDB snapshot (fork latency spike).**

Symptom: Redis has periodic latency spikes (100ms-seconds) every `save` interval;
`SLOWLOG GET` shows commands during these intervals are slow.
Root cause: `fork()` call for RDB snapshot; on large datasets, the kernel takes time
to copy page tables; Linux Transparent Huge Pages amplifies this.
Diagnosis: `redis-cli INFO stats | grep latest_fork_usec`; values above 200,000
(200ms) indicate a problem.
Fix: disable THP (`echo never > /sys/kernel/mm/transparent_hugepage/enabled`); reduce
dataset size with Redis Cluster; increase `save` intervals to reduce fork frequency.

**Failure Mode 2: AOF file grows unboundedly, disk fills up.**

Symptom: Redis AOF file grows continuously; disk fills up; Redis stops writing and
returns errors.
Root cause: AOF rewrite is disabled or the minimum size threshold is too high; a
write-heavy workload generates thousands of commands per second.
Diagnosis: `redis-cli INFO persistence | grep aof_current_size`; high values with
`aof_rewrite_in_progress: 0` for extended periods indicate rewrite is not running.
Fix: lower `auto-aof-rewrite-min-size` and `auto-aof-rewrite-percentage`; trigger
a manual `BGREWRITEAOF` immediately to compact the current file; monitor AOF file
size with alerting.

---

### ⚖️ Comparison Table

| Aspect | RDB | AOF (everysec) |
|---|---|---|
| **Data loss on crash** | Up to last save interval (minutes) | At most 1 second |
| **File size** | Compact (binary, compressed) | Large (grows with writes) |
| **Restart speed** | Fast (binary load) | Slow (replay all commands) |
| **Fork impact** | Yes (each save) | Yes (rewrite only) |
| **Best for** | Backups, fast restarts | Durability-sensitive data |

---

### 🏛️ System Design

*(Omit: L3 keyword; Redis persistence in HA architecture in L4 Redis Production entry.)*

---

### 📊 Diagram

```text
RDB + AOF COMBINED RECOVERY:

  Time: T0           T1       T2 (crash)
         |            |        |
  Events: [save RDB]  writes   crash

  Recovery:
  1. Load dump.rdb (state at T0, fast)
  2. Replay AOF commands T0..T2 (few seconds)
  3. Redis ready with state at T2

  vs RDB ONLY:
  1. Load dump.rdb (state at T0)
  2. Lost: all writes T0..T2

  vs AOF ONLY:
  1. Replay ALL commands since beginning
     (or last rewrite) -> slow for large datasets

  COMBINED ADVANTAGE:
  - Near-zero data loss (AOF: at most 1 second)
  - Fast restart (RDB base + small AOF diff)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the data recovery behavior using RDB
> only, AOF only, and the combined RDB+AOF approach after a crash. (2) HOW TO READ IT:
> the timeline shows the last RDB save at T0, subsequent writes, and a crash at T2; each
> persistence strategy is then compared for how much data is recovered and how fast. (3)
> KEY RELATIONSHIP: the combined approach gets the best of both: AOF ensures near-zero
> data loss; RDB provides a fast starting point so AOF replay is short (only T0..T2
> instead of the entire history). (4) EDGE CASE: if the AOF file is corrupted (partial
> write at crash time), `redis-check-aof --fix appendonly.aof` can repair the file by
> truncating the last partial command; most AOF corruption is at the tail and is
> recoverable. (5) INSIGHT: a senior engineer ensures the RDB snapshot interval is
> aligned with the AOF rewrite interval; if the last RDB is 24 hours old but the AOF
> is large (many rewrites skipped), startup can be slow; keep RDB snapshots frequent
> enough that the AOF diff from the last snapshot to the current time is small.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | RDB mechanics, AOF fsync policies |
| Mechanism | 2 | Fork COW, AOF rewrite |
| Application | 2 | Production config, recovery |
| Trade-off | 2 | RDB vs AOF, durability vs performance |
| Scenario | 1 | Latency spikes |

---

**[MID] Q1 (Definition): Explain the difference between RDB and AOF in Redis. Which should you use?**

RDB: point-in-time snapshots. Redis forks a child process that writes all data to
a binary file (`dump.rdb`). Configured with `save` directives. The child inherits
memory via copy-on-write; only pages modified after the fork require physical memory
allocation.

Benefits: compact file, fast load time on restart, useful as backup/disaster recovery.
Drawbacks: data written after the last snapshot is lost on crash; fork has latency cost.

AOF: append-only log. Every write command is appended to the AOF file. On restart,
Redis replays all commands to reconstruct the dataset. Three fsync policies:
- `always`: fsync per command (highest durability, lowest throughput).
- `everysec`: fsync once per second (at most 1 second of data loss - standard).
- `no`: OS handles fsync timing (fastest, least durable).

Benefits: near-zero data loss with `everysec`; human-readable log.
Drawbacks: large file grows over time (requires periodic rewrite); slow restart for
large datasets (replaying millions of commands).

Recommendation: use both. AOF for durability; RDB for fast restart and backup. For
pure caches where data can be reconstructed, disable both to maximize throughput.

*What separates good from great:* The Redis `aof-use-rdb-preamble yes` option. This
modern feature (Redis 4.0+) stores an RDB snapshot at the beginning of the AOF file,
then appends AOF commands after it. On restart: load the RDB preamble (fast), then
replay only the incremental AOF commands since the last rewrite. This effectively
gives RDB-speed restarts with AOF durability without needing to maintain two separate
files. Enable this in production; it is enabled by default in Redis 7.0+.

---

**[MID] Q2 (Mechanism): How does Redis RDB snapshot avoid blocking the server?**

Redis uses `fork()` to create a child process that is an exact copy of the parent.
The child performs the disk write while the parent continues serving requests.

Copy-on-write (COW): after `fork()`, the parent and child share all memory pages.
The OS marks all pages as read-only (copy-on-write). When either the parent or the
child modifies a page, the OS creates a private copy for the modifying process; the
other process retains the original page.

Effect: the child sees an instantaneous consistent snapshot (the state at fork time).
The parent can continue writing; modified pages create new physical memory. Neither
process blocks the other.

Latency impact: `fork()` itself is not instantaneous. For a 10 GB dataset, the OS
must copy the page table (a tree of pointers to physical pages). On modern Linux with
Huge Pages, the page table is large and the copy takes longer. Typical fork times:
1 GB = ~10ms, 10 GB = ~100ms, 50 GB = up to seconds.

*What separates good from great:* The memory sizing implication. After `fork()`, write-
heavy workloads can cause COW to allocate nearly 2x the dataset size in physical memory.
If the server has exactly enough RAM for the dataset, a fork will trigger OOM. The safe
rule: provision Redis servers with at least 1.5x the expected dataset size as available
RAM to accommodate fork COW overhead. Monitor `mem_allocator_stats` and
`used_memory_peak_perc` in Redis `INFO memory` to track peak memory usage during
snapshots.

---

**[SENIOR] Q3 (Application): A Redis server has a 50 GB dataset. What are the persistence implications and how do you handle them?**

Challenges with a 50 GB Redis dataset:

1. Fork latency for RDB: fork() with 50 GB can pause Redis for several seconds;
   `save` intervals every 60 seconds cause regular second-long latency spikes.
   Solution: reduce RDB save frequency or disable RDB saves; rely primarily on AOF
   for durability; take manual `BGSAVE` only during off-peak hours.

2. AOF rewrite: AOF rewrite also forks; with 50 GB, the rewrite fork has the same
   latency implications; disable auto-rewrite and trigger manually during off-peak.

3. Restart time: replaying a 50 GB AOF from scratch can take minutes to hours.
   Solution: use `aof-use-rdb-preamble yes`; the RDB preamble loads fast (binary);
   only the incremental AOF commands since the last rewrite need replay.

4. Memory: a 50 GB dataset means provisioning at least 75 GB of RAM to accommodate
   COW overhead during fork; a 128 GB server is appropriate.

5. Recommended approach: use Redis Cluster to split the 50 GB across 5 nodes of 10 GB
   each; each node's fork is fast (10 GB); the cluster handles sharding automatically.

*What separates good from great:* The COW overhead monitoring. Track `INFO memory`
`mem_allocator_active` vs `mem_allocator_resident` during RDB saves. A large gap
indicates heavy COW copying. If the gap approaches the free RAM, the system is at
risk of OOM. Use `latency-monitor-threshold 100` in Redis to log latency events;
`LATENCY HISTORY fork` shows a timeline of all fork latency events; this data helps
correlate latency spikes with RDB save events and quantify the impact.

---

**[SENIOR] Q4 (Trade-off): When is it appropriate to disable Redis persistence entirely?**

Appropriate scenarios:
1. Pure cache tier: Redis is in front of a durable database (e.g., PostgreSQL); all
   data in Redis can be reloaded from the primary database on Redis restart; no
   data is exclusively in Redis.
2. Session cache: session tokens expire in minutes to hours; a Redis restart resets
   sessions; users log in again; acceptable in many applications.
3. Ephemeral rate limiting: rate limit counters in Redis; if Redis restarts, the
   counters reset; this is a brief window of unprotected requests, acceptable for
   most rate limits.
4. Pre-computation results: machine learning predictions, recommendation results,
   rendered HTML fragments; all can be recomputed from the primary database.

When NOT to disable persistence:
1. Primary data store: any data stored only in Redis must be persisted.
2. Pub/Sub message queue: messages that must be delivered cannot be lost.
3. Leaderboards/session state that cannot be easily reconstructed.
4. Distributed locks: if the lock holder dies and Redis restarts without persistence,
   the lock is lost; another instance can acquire it; if the original holder is still
   running, two instances hold the lock simultaneously.

*What separates good from great:* The Redlock distributed lock concern. The Redlock
algorithm (Redis-based distributed lock) requires persistence to be safe. If Redis
restarts without persistence while a lock is held, the lock is lost. The restarted
instance has no record of the lock. If the lock holder is still alive, it still
believes it holds the lock; a second client acquires the lock; two clients hold the
lock simultaneously - the distributed lock's core safety guarantee is violated. For
distributed locking with Redis, always enable AOF with `appendfsync always` (or use
a dedicated ZooKeeper/etcd cluster for critical locks).

---

**[SENIOR] Q5 (Scenario): Redis production server has periodic 200-500ms latency spikes every 60 seconds. Diagnose and fix.**

This pattern is the RDB snapshot fork latency signature.

Diagnosis:

Step 1 - Confirm the periodic pattern:

```bash
redis-cli LATENCY HISTORY fork
# Shows timestamp and duration of each fork event
# If spikes correlate with fork events -> RDB save
```

> **Code walkthrough:** (1) WHAT IT SHOWS: checking the Redis latency event history for `fork` events to correlate periodic latency spikes with RDB snapshot operations. (2) KEY MECHANISM: Redis latency monitoring records events exceeding `latency-monitor-threshold` (default: 0 = disabled); enable with `CONFIG SET latency-monitor-threshold 50`; `LATENCY HISTORY fork` shows timestamps and durations of all fork events. (3) WHY IT MATTERS: without this data, periodic latency spikes are mysterious; with it, the correlation to RDB save intervals is immediately visible. (4) WHAT BREAKS: if `latency-monitor-threshold` is 0 (disabled), `LATENCY HISTORY` returns nothing; always configure a threshold in production monitoring. (5) TAKEAWAY: add `latency-monitor-threshold 50` and `latency-tracking yes` to the Redis configuration; this is a zero-cost observability feature.

Step 2 - Check `save` configuration:

```bash
redis-cli CONFIG GET save
# "900 1 300 10 60 10000"
# "60 10000" -> save every 60 sec if 10000 keys changed
# Matches the 60-second spike pattern
```

> **Code walkthrough:** (1) WHAT IT SHOWS: retrieving the `save` configuration to confirm the RDB save intervals that match the latency spike pattern. (2) KEY MECHANISM: the `save 60 10000` directive triggers an RDB snapshot every 60 seconds if at least 10,000 keys have changed; the 60-second interval matches the observed spike frequency. (3) WHY IT MATTERS: directly correlating the save interval with the spike frequency confirms the RDB fork as the root cause, not a GC pause or external factor. (4) WHAT BREAKS: if the save string is empty (`""`), RDB is disabled; the latency spikes must have another cause. (5) TAKEAWAY: always verify the `save` config when diagnosing periodic Redis latency; it is the most common cause of 30-60 second latency cycles.

Step 3 - Check dataset size and fork time:

```bash
redis-cli INFO memory | grep used_memory_human
# "used_memory_human: 45.00G"
# 45 GB dataset -> fork can take 500ms+ on HDD
# or with THP enabled

redis-cli INFO stats | grep latest_fork_usec
# "latest_fork_usec: 450000"
# 450ms = 0.45 seconds per fork
```

> **Code walkthrough:** (1) WHAT IT SHOWS: diagnostic commands to confirm that Redis latency spikes are caused by RDB snapshot fork events, including latency history, save configuration, and fork duration. (2) KEY MECHANISM: `LATENCY HISTORY fork` correlates fork events with latency spikes; `CONFIG GET save` confirms the interval; `latest_fork_usec` shows the actual fork duration in microseconds. (3) WHY IT MATTERS: RDB fork is one of the most common causes of Redis latency spikes; it is easily diagnosable and fixable; the fix does not require changing the application. (4) WHAT BREAKS: if `latest_fork_usec` is 0, RDB snapshots are not running; check `rdb_bgsave_in_progress` and `rdb_last_bgsave_status` to confirm. (5) TAKEAWAY: always configure Redis latency monitoring (`latency-monitor-threshold 50`) in production; `LATENCY HISTORY fork` is the first command to run when investigating periodic latency spikes.

Fix:
- Disable THP immediately: `echo never > /sys/kernel/mm/transparent_hugepage/enabled`
- Reduce `save` frequency: `CONFIG SET save "900 1 300 10"`
- If dataset is very large: consider disabling RDB saves, relying on AOF + manual
  off-peak `BGSAVE`
- Long-term: use Redis Cluster to split the dataset into smaller shards where each
  node's fork is fast

*What separates good from great:* The THP impact magnitude. A 45 GB dataset on Linux
with THP enabled can fork in 500ms; with THP disabled, the same dataset forks in
80-100ms. THP causes huge (2 MB) pages to be used instead of standard 4 KB pages; when
a fork modifies one byte of a 2 MB page, the entire 2 MB page must be copied (vs 4 KB
without THP); COW overhead is 512x larger per modified byte. Disabling THP is the
single most impactful change for large Redis datasets and should be in every Redis
production server's initialization script.

---

**[SENIOR] Q6 (Application): What is AOF rewrite and why is it necessary?**

The AOF file grows continuously because every write command is appended. A key that
is SET 10,000 times has 10,000 lines in the AOF; only the last SET matters for the
current state, but the file retains all historical commands.

AOF rewrite: Redis creates a new AOF file containing only the commands needed to
reconstruct the current state. For a key SET 10,000 times, the rewrite writes one SET
(or the equivalent RESTORE command). The old AOF is replaced by the compact new AOF.

Rewrite mechanics: like RDB, the rewrite uses fork(); the child writes the new AOF
while the parent continues serving requests; new commands during the rewrite are
buffered in memory (the rewrite buffer) and appended to the new AOF file when the child
finishes; the parent atomically replaces the old AOF with the new one.

Configuration:
- `auto-aof-rewrite-percentage 100`: trigger when AOF is 100% larger than after the
  last rewrite (doubles in size).
- `auto-aof-rewrite-min-size 64mb`: do not trigger if AOF is smaller than 64 MB.

Why necessary:
1. Disk space: without rewrite, the AOF grows without bound.
2. Startup time: replaying a 100 GB AOF on restart takes hours; the rewritten 5 GB
   file takes minutes.
3. Performance: searching or verifying a large AOF is slow.

*What separates good from great:* The rewrite buffer memory pressure. During a rewrite,
new commands are accumulated in the rewrite buffer (in memory). If the write rate is
high and the rewrite takes a long time (large dataset), the rewrite buffer can grow
to gigabytes; if it exceeds available memory, the rewrite fails; Redis retries on the
next trigger. Monitor `aof_rewrite_buffer_length` in `INFO persistence`; if it grows
beyond 1-2 GB during rewrites, the dataset is too large for in-memory AOF rewrites;
use Redis Cluster to reduce per-node dataset size.

---

**[MID] Q7 (Application): What Redis persistence configuration would you recommend for a session store vs a cache?**

Session store (sessions must survive Redis restart):
- Enable AOF: `appendonly yes`
- Use `appendfsync everysec` (at most 1 second of session loss on crash)
- Enable `aof-use-rdb-preamble yes` for fast restarts
- Set `save` for periodic RDB backup (backup, not durability)
- Result: sessions persist across Redis restarts; users do not need to re-login
  after a Redis crash

Cache (all data is reconstructable from the primary database):
- Disable RDB: `save ""`
- Disable AOF: `appendonly no`
- Set `maxmemory` policy: `maxmemory-policy allkeys-lru` (evict least-recently-used)
- Result: no disk I/O overhead; maximum throughput; Redis loses all data on restart
  (acceptable because the cache warms up from the primary database on startup)

Hybrid (some data must persist, some is ephemeral):
- Use Redis namespacing or separate Redis instances: one persistence instance (with
  AOF) for durable data; one cache instance (no persistence) for ephemeral data
- Do not mix persistent and ephemeral data in one Redis instance with one persistence
  config; the entire instance has one persistence policy

*What separates good from great:* The `maxmemory` and persistence interaction. If
`maxmemory` is set and `maxmemory-policy` evicts keys, the evicted keys are gone from
memory but may still be in the AOF file (they were written before eviction). On restart,
Redis replays the AOF, reloads all written keys, then eviction runs again to bring
memory under the limit. The startup sequence: load data -> AOF replay -> eviction to
enforce maxmemory. For a large cache with high eviction rates, startup can be slow
because the AOF contains evicted keys that must be loaded and then immediately evicted.
For cache instances, disable persistence entirely to avoid this overhead.

---

---

# Redis Cluster and High Availability

---

### 🎯 Model Answer

**30 seconds:**
> Redis Cluster is the built-in horizontal scaling solution. It shards data across
> multiple nodes using 16,384 hash slots; each node owns a range of slots. Every node
> maintains connections to all other nodes via gossip protocol. Clients route requests
> to the correct node using MOVED/ASK redirects. Redis Sentinel is the HA solution for
> single-shard deployments: it monitors a primary and replicas, and promotes a replica
> automatically on primary failure.

**3 minutes (Senior):**
> Redis Cluster: 16,384 hash slots distributed across N master nodes. Each key hashes
> to a slot (`CRC16(key) % 16384`); the slot maps to a node; the driver routes directly
> to that node. Each master has 1+ replicas for redundancy. On master failure, cluster
> elects the replica with the most up-to-date replication offset as the new master.
> Multi-key operations (MSET, pipelines, Lua scripts) only work when all keys hash to
> the same slot; use hash tags `{user:123}:session` and `{user:123}:cart` to force
> co-location on the same slot. Cluster requires at least 6 nodes for production (3
> masters + 3 replicas) to maintain quorum and fail-tolerance.
>
> Redis Sentinel: 3+ Sentinel processes monitor the primary; on primary failure, Sentinels
> vote for a new primary; majority vote required to prevent split-brain. Sentinel provides
> automatic failover and service discovery (clients ask Sentinel for the current primary
> address). No sharding; the entire dataset is on one primary + replicas.

**Framework:** Single Instance -> Sentinel (HA, no sharding) -> Cluster (HA + sharding) -> Cluster + replicas (HA + sharding + redundancy)

**Blank Mind Recovery:**

**(1) Restate:** "Redis Cluster: 16,384 slots, distributed across master nodes. Key ->
slot (CRC16), slot -> node. Each master has replicas. Sentinel: HA for single shard,
monitors primary, auto-failover. Cluster: HA + horizontal scaling."

**(2) First principles:** "A single Redis server is a SPOF. Add replicas for redundancy.
Add multiple masters for capacity. Sentinel handles the 'what if master fails' problem.
Cluster handles both the 'too much data for one node' and 'too much traffic for one node'
problems."

**(3) Bridge:** "Redis Sentinel is a bank with one vault and 3 security guards who
vote on whether to replace the head vault manager. Redis Cluster is a bank with 6 vaults,
each guard holding some safety deposit boxes, and the security camera system routing
customers to the right vault."

---

### 📘 Concept Explanation

**Redis Cluster Hash Slot Distribution:**

```text
REDIS CLUSTER (6 nodes: 3 masters + 3 replicas):

  HASH SLOTS: 0 - 16383

  Node A (master): slots  0    - 5460
  Node B (master): slots  5461 - 10922
  Node C (master): slots  10923 - 16383

  Node D (replica of A)
  Node E (replica of B)
  Node F (replica of C)

  Key routing:
    key "user:123" -> CRC16("user:123") % 16384
    -> slot 8765 -> Node B
    -> Client connects to Node B directly

  MOVED redirect (when client has stale slot map):
    Client -> Node A -> MOVED 8765 <Node B IP>
    Client caches the new slot map
    Client -> Node B -> result

  HASH TAGS (force same slot):
    "{order:456}:items" and "{order:456}:meta"
    Both hash on "order:456" -> same slot -> same node
    Enables multi-key operations on these keys
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Redis Cluster hash slot distribution
> across 3 masters, routing a key to the correct node, the MOVED redirect mechanism,
> and hash tags for co-location. (2) HOW TO READ IT: the top shows 16,384 slots divided
> across 3 masters; the middle shows how a specific key is routed via CRC16 hashing to
> its slot owner; the bottom shows hash tags forcing two different keys to the same slot.
> (3) KEY RELATIONSHIP: every key in Redis Cluster maps to exactly one of 16,384 slots;
> every slot belongs to exactly one master; the cluster maintains a globally consistent
> slot-to-node map; clients cache this map to route directly without redirects. (4) EDGE
> CASE: during slot rebalancing (adding/removing nodes), some slots are migrating; keys
> in migrating slots return ASK redirects (not MOVED); the client follows ASK once without
> updating its slot map cache. (5) INSIGHT: a senior engineer recognizes that the choice
> of 16,384 hash slots (not a power of 2) is deliberate; 16,384 is the maximum number of
> nodes in a Redis Cluster; the gossip protocol heartbeat payload is limited to 16,384
> bits (2 KB bitmap); this design limits cluster size.

---

### 💻 Code Example

```python
from redis.cluster import RedisCluster
from redis.cluster import ClusterNode

# Connect to Redis Cluster
startup_nodes = [
    ClusterNode("redis-node1", 6379),
    ClusterNode("redis-node2", 6380),
    ClusterNode("redis-node3", 6381),
]
redis_cluster = RedisCluster(
    startup_nodes=startup_nodes,
    decode_responses=True,
    skip_full_coverage_check=False,
    # Read from replicas for read-heavy workloads
    read_from_replicas=True,
)

# Basic operations: driver routes to correct node
redis_cluster.set("user:123:session", "token_abc")
value = redis_cluster.get("user:123:session")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: connecting to Redis Cluster with `RedisCluster`
> client, specifying startup nodes and enabling replica reads. (2) KEY MECHANISM: the
> client connects to any cluster node on startup; that node returns the full cluster
> topology (slot map); the client caches the slot map and routes subsequent requests
> directly to the correct node without going through a coordinator. (3) WHY IT MATTERS:
> `read_from_replicas=True` distributes read traffic across masters and replicas; for
> read-heavy workloads, this can effectively 2-3x the read throughput. (4) WHAT BREAKS:
> reading from replicas introduces potential stale reads (Redis replication is asynchronous);
> for operations requiring the latest value, use the default `read_from_replicas=False`
> or target specific operations to the master. (5) TAKEAWAY: use `read_from_replicas=True`
> for read-heavy workloads where slight staleness is acceptable; use the default (primary
> only) for consistency-sensitive operations.

{% raw %}
```python
# HASH TAGS: co-locate related keys on same node
# Use case: user shopping cart (must be on same node
# for atomic multi-key operations)

user_id = "456"

# All keys hash on "{user:456}" -> same slot -> same node
session_key = f"{{user:{user_id}}}:session"
cart_key    = f"{{user:{user_id}}}:cart"
prefs_key   = f"{{user:{user_id}}}:prefs"

# Multi-key operation works because all on same node
redis_cluster.mset({
    session_key: "token_xyz",
    cart_key: "[{product:1, qty:2}]",
    prefs_key: "theme:dark"
})

# Pipeline also works for same-slot keys
pipe = redis_cluster.pipeline()
pipe.get(session_key)
pipe.get(cart_key)
pipe.get(prefs_key)
results = pipe.execute()

# BAD: multi-key ops on different slots FAIL
# redis_cluster.mset({
#   "user:1:session": "a",   # different slots
#   "user:2:session": "b",   # different slots
# })
# -> CrossSlotError
```
{% endraw %}

> **Code walkthrough:** (1) WHAT IT SHOWS: the hash tag pattern `{user:456}` in the key
> name to force related keys to the same hash slot, enabling multi-key operations in
> Redis Cluster. (2) KEY MECHANISM: Redis Cluster computes the hash slot only on the
> portion of the key inside `{}` if a hash tag is present; `{user:456}:session` and
> `{user:456}:cart` both hash on `user:456` -> same slot -> same node. (3) WHY IT MATTERS:
> without hash tags, `MSET` with multiple keys fails with `CrossSlotError` because the
> keys may be on different nodes; hash tags are the only way to guarantee multi-key
> atomicity in Redis Cluster. (4) WHAT BREAKS: using too broad a hash tag (e.g., `{user}:456`
> and `{user}:789` both hash on `user`) co-locates all user keys on one node; this is the
> same hot partition problem as Cassandra; choose hash tags that distribute across nodes.
> (5) TAKEAWAY: use entity-specific hash tags (`{user:456}`) not type-level hash tags
> (`{user}`); entity-level tags allow multi-key operations per entity while maintaining
> distribution across nodes.

```python
# Redis Sentinel: HA for single-shard deployments
import redis
from redis.sentinel import Sentinel

sentinels = [
    ("sentinel1", 26379),
    ("sentinel2", 26379),
    ("sentinel3", 26379),
]
sentinel = Sentinel(sentinels, socket_timeout=0.1)

# Get master connection (auto-discovers current primary)
master = sentinel.master_for(
    "mymaster",
    socket_timeout=0.1
)

# Get replica connection (for read-only queries)
replica = sentinel.slave_for(
    "mymaster",
    socket_timeout=0.1
)

# Write to master
master.set("key", "value")

# Read from replica (may be slightly stale)
value = replica.get("key")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: connecting to Redis via Sentinel for automatic
> failover; the Sentinel client handles primary discovery and reconnection on failover.
> (2) KEY MECHANISM: `sentinel.master_for("mymaster")` asks any Sentinel for the current
> primary address; the Sentinel responds with the current primary's host:port; the client
> connects directly to the primary for writes; on primary failure, the Sentinel client
> detects the connection error, asks Sentinels for the new primary, and reconnects. (3)
> WHY IT MATTERS: without Sentinel, the application hardcodes the primary address; if
> the primary fails and a replica is promoted, the application must be manually
> reconfigured; Sentinel automates this. (4) WHAT BREAKS: if fewer than the majority of
> Sentinels are reachable, Sentinel cannot complete failover (split-brain prevention);
> always deploy 3 Sentinels in separate availability zones; never deploy fewer than 3.
> (5) TAKEAWAY: Sentinel is the correct choice for Redis HA when the dataset fits on one
> node; Cluster is the correct choice when the dataset exceeds one node's capacity or
> when write throughput exceeds one node's capability.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Redis Sentinel monitors a primary Redis node and its replicas. If the primary fails,
> Sentinel automatically promotes a replica to primary. Your application connects to
> Sentinel instead of directly to Redis; Sentinel tells your application where the
> current primary is. Redis Cluster is different: it shards data across multiple primary
> nodes. Each node holds a portion of the data. Use Sentinel when all your data fits on
> one node. Use Cluster when you need more data capacity or write throughput than one
> node provides.

---

**Senior / Staff (5+ years):**
> Redis HA decision framework: (1) Single node vs Sentinel vs Cluster - single node
> is fine for development and small workloads; Sentinel adds HA without sharding (same
> data on all nodes); Cluster adds sharding with HA but adds operational complexity.
> (2) Cluster minimum nodes - at least 3 masters + 3 replicas (6 nodes) for fault
> tolerance; 3 masters are needed for majority quorum during failover; fewer than 3
> masters means a single master failure loses quorum. (3) Hash tag design - plan hash
> tags before deployment; hash tags cannot be changed after data is written without
> migration; the wrong hash tag design causes hotspots. (4) Cluster vs Sentinel
> operational complexity - Cluster requires cluster-aware clients (most modern drivers
> support this); multi-key operations are restricted to same-slot keys; Lua scripts
> must use keys on the same slot; these restrictions affect application design.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Redis Cluster automatically handles all multi-key operations."**

Redis Cluster supports multi-key operations (MSET, MGET, pipelines, Lua scripts, MULTI/
EXEC transactions) ONLY when all involved keys are in the same hash slot. If the keys
hash to different slots (on different nodes), the operation fails with `CrossSlotError`.
The solution is to use hash tags to ensure related keys are on the same slot. This
is a fundamental design constraint of Redis Cluster that must be accounted for in the
application data model before deploying.

**Misconception 2: "Redis replication guarantees no data loss on failover."**

Redis replication is asynchronous. The primary sends write commands to replicas after
acknowledging to the client. If the primary crashes between the client acknowledgment
and the replication, those writes are lost. The replica promoted to primary does not
have the missing writes. This is a known trade-off in Redis. To minimize data loss,
use `min-replicas-to-write 1` and `min-replicas-max-lag 10` to refuse writes if no
replica is caught up within 10 seconds; this prevents write acknowledgment without
replication, at the cost of availability when replicas are lagging.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: CrossSlotError on multi-key operations in Redis Cluster.**

Symptom: `redis.exceptions.ResponseError: CROSSSLOT Keys in request don't hash to
the same slot` when executing multi-key operations.
Root cause: two or more keys in the operation hash to different hash slots; different
slots are owned by different nodes; Redis Cluster cannot execute cross-node operations
atomically.
Fix: redesign keys with hash tags to co-locate related keys; `{entity_id}:field1` and
`{entity_id}:field2` will always be on the same slot.

**Failure Mode 2: Cluster split-brain during network partition.**

Symptom: some clients can write to what they think is the primary; other clients get
`CLUSTERDOWN` errors.
Root cause: a network partition splits the cluster; the minority partition still has
a node that was the primary; the majority partition elects a new primary; both partitions
accept writes to the same slots.
Diagnosis: `redis-cli cluster info` on nodes in both partitions; check `cluster_state`
and `cluster_known_nodes` count.
Fix: Redis Cluster uses majority quorum; after the partition heals, the minority
partition's writes are discarded in favor of the majority partition's new primary; the
`min-replicas-to-write` setting can prevent the minority partition from accepting writes.

---

### ⚖️ Comparison Table

| Feature | Single Instance | Sentinel | Cluster |
|---|---|---|---|
| **Data sharding** | No | No | Yes (16,384 slots) |
| **Horizontal scaling** | No | No (replicas read-only) | Yes |
| **Auto failover** | No | Yes | Yes |
| **Multi-key ops** | Yes | Yes | Same slot only |
| **Min nodes (production)** | 1 | 1 primary + 2 Sentinel | 6 (3M+3R) |
| **Operational complexity** | Low | Medium | High |

---

### 🏛️ System Design

*(Omit: L3 keyword; full Redis HA architecture in L4 Redis Production entry.)*

---

### 📊 Diagram

```text
REDIS SENTINEL FAILOVER:

  NORMAL STATE:
  Sentinel1  Sentinel2  Sentinel3
      \          |          /
       +----[Primary]----+
                |
          [Replica A]  [Replica B]

  PRIMARY FAILURE:
  1. Primary unreachable (SDOWN)
  2. Sentinels gossip: "is it really down?"
  3. Majority vote (2 of 3): ODOWN confirmed
  4. Elect leader Sentinel (Raft-like vote)
  5. Leader selects replica with highest
     replication offset (least data loss)
  6. SLAVEOF NO ONE on Replica A
     (Replica A -> new Primary)
  7. Replica B replicates from new Primary
  8. Sentinels update primary address
  9. Clients reconnect to new Primary

  FAILOVER TIME: typically 30-60 seconds
  (configurable: down-after-milliseconds)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Redis Sentinel failover process from
> primary failure detection through replica promotion and client reconnection. (2) HOW
> TO READ IT: follow the numbered steps; SDOWN is subjectively-down (one Sentinel sees
> failure); ODOWN is objectively-down (majority of Sentinels confirm); the leader Sentinel
> orchestrates the actual failover. (3) KEY RELATIONSHIP: the majority vote requirement
> for ODOWN prevents false failovers due to network partitions between Sentinel and the
> primary; 3 Sentinels with at least 2 required for quorum is the standard deployment.
> (4) EDGE CASE: if the failed primary comes back online after the failover, Sentinel
> reconfigures it as a replica of the new primary; it does not become the primary again;
> this prevents data divergence from split-brain. (5) INSIGHT: a senior engineer notices
> that `down-after-milliseconds` (default: 30,000 ms = 30 seconds) determines the
> minimum failover time; reducing this to 1,000 ms enables faster failover but increases
> false-positive failure detection; tune this based on acceptable RTO (recovery time
> objective) vs stability trade-off.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Sentinel vs Cluster, hash slots |
| Mechanism | 2 | Cluster routing, Sentinel failover |
| Application | 2 | Hash tag design, failover config |
| Trade-off | 2 | Cluster vs Sentinel, read replicas |
| Scenario | 1 | CrossSlotError diagnosis |

---

**[MID] Q1 (Definition): What is the difference between Redis Sentinel and Redis Cluster? When do you use each?**

Redis Sentinel:
- Purpose: high availability (HA) for a single Redis shard.
- Architecture: 3+ Sentinel processes monitor one primary + 1+ replicas; on primary
  failure, Sentinels vote and promote a replica.
- Data model: all data on one primary; replicas are read-only copies.
- Scaling: vertical only (bigger server); replicas add read throughput.
- Operations: all multi-key operations work (single node).
- Use when: dataset fits on one server; write throughput fits on one server.

Redis Cluster:
- Purpose: horizontal scaling (sharding) + HA.
- Architecture: N master nodes each owning a range of 16,384 hash slots; each master
  has 1+ replicas.
- Data model: data distributed across masters by hash slot.
- Scaling: horizontal; add masters to increase capacity and write throughput.
- Operations: multi-key operations only work for same-slot keys.
- Use when: dataset exceeds one server's capacity; write throughput exceeds one server's
  capability; need horizontal scalability.

Decision rule: start with Sentinel; migrate to Cluster when the dataset approaches
50-60% of one server's RAM or when write throughput saturates one CPU core.

*What separates good from great:* The operational complexity comparison. Redis Cluster
requires cluster-aware clients (most modern drivers support this but require explicit
configuration). Cluster resharding (moving slots between nodes) requires careful
planning; the `redis-cli --cluster rebalance` command helps but does not always
distribute evenly. Lua scripts must have all keys in the same slot (use hash tags).
These constraints mean Cluster is not a drop-in replacement for a single instance;
application code must be written with Cluster in mind. Sentinel has none of these
constraints; the only change is connection configuration.

---

**[MID] Q2 (Mechanism): How does Redis Cluster route a request to the correct node?**

Routing process:
1. Client calculates the hash slot for the key: `slot = CRC16(key) % 16384`.
   If the key has a hash tag (substring in `{}`), only the hash tag is hashed.
2. Client looks up its cached slot map: slot -> node mapping.
3. Client sends the command directly to the node that owns the slot.

If the client has a stale slot map (slot has moved since last update):
- The node responds with `MOVED slot IP:PORT` redirect.
- The client sends the command to the redirected node.
- The client updates its slot map cache with the new slot-to-node mapping.

If the slot is currently migrating (during resharding):
- The node responds with `ASK slot IP:PORT` redirect.
- The client sends `ASKING` then the original command to the redirected node.
- The client does NOT update its slot map cache (migration is temporary).

*What separates good from great:* The zero-downtime resharding implication. During
slot migration (adding a new node), keys are migrated one by one from the source node
to the destination node. During this time, each key is either at the source or the
destination. The `ASK` redirect handles this gracefully: if the key has not yet
migrated, the source handles it; if it has migrated, the source returns ASK and the
client retries at the destination. The migration is invisible to clients; no client
code changes are needed for resharding. This is the key operational advantage of
Redis Cluster's slot-based design.

---

**[SENIOR] Q3 (Application): How do you design hash tags for a multi-tenant application using Redis Cluster?**

Multi-tenant scenario: users have sessions, carts, and preferences. The application
needs atomic operations on a user's data (e.g., update cart and session in one pipeline).

Hash tag design:
- Use the user's ID as the hash tag: `{user:123}:session`, `{user:123}:cart`
- All user-specific keys co-locate on the same slot -> same node -> multi-key ops work

Pattern:

{% raw %}
```python
def user_key(user_id, key_type):
    # All user keys hash on user:ID -> same slot
    return f"{{user:{user_id}}}:{key_type}"

session_key = user_key("123", "session")  # {user:123}:session
cart_key    = user_key("123", "cart")     # {user:123}:cart
prefs_key   = user_key("123", "prefs")   # {user:123}:prefs
```
{% endraw %}

> **Code walkthrough:** (1) WHAT IT SHOWS: a helper function that generates Redis keys with entity-specific hash tags to co-locate all keys for a user on the same hash slot. (2) KEY MECHANISM: `{user:123}` is the hash tag; CRC16 is computed only on `user:123`; all keys with the same hash tag land on the same slot and therefore the same node. (3) WHY IT MATTERS: atomic pipelines and MULTI/EXEC transactions require all keys to be on the same slot; the hash tag design ensures user-level atomicity. (4) WHAT BREAKS: using a generic hash tag like `{user}` (without the ID) causes all user data to hash to the same slot; one node receives all user data - a hot partition. (5) TAKEAWAY: hash tags must be specific enough to distribute load while keeping related keys together; entity-specific IDs are the right granularity.

Distribution considerations:
- Each user's data is on one slot; users are distributed across slots by their ID.
- With millions of users, distribution is statistically uniform (CRC16 distributes well).
- "Celebrity" users with large amounts of data (large carts, many sessions) can create
  large partitions; but the keys themselves (session, cart, prefs) are small; the
  partition size concern is usually not relevant for user data.

When hash tags create hotspots: rate limit buckets. A time-based rate limit key
`ratelimit:2024-01-15T10:00` concentrates all rate-limit writes for one minute to one
slot; if the rate limit applies to millions of users per minute, this is a hot slot.
Solution: add a user-specific component to the rate limit key.

*What separates good from great:* The hash tag design for Lua scripts. Lua scripts in
Redis Cluster must specify all keys they will access in the `KEYS` array; all keys must
be on the same slot. If a Lua script accesses `user:123:session` and `user:123:cart`,
both must be in `KEYS` and both must have the same hash tag. If a script dynamically
determines additional keys based on data in Redis, those keys must also be on the same
slot; this requires careful design of the Lua script and the key naming scheme before
any Cluster migration.

---

**[SENIOR] Q4 (Trade-off): What happens to writes during a Redis Sentinel failover? How do you minimize data loss?**

During Sentinel failover:
1. Primary becomes unreachable (crash, network partition).
2. Sentinels detect the failure (after `down-after-milliseconds` - default 30 seconds).
3. Sentinels vote for the replica with the highest `replication_offset` (most up-to-date).
4. The selected replica is promoted to primary.
5. Other replicas start replicating from the new primary.
6. Clients get connection errors; Sentinel-aware clients reconnect after discovering
   new primary address.

Data loss window: writes acknowledged by the old primary AFTER the last replication
to the new primary are lost. With async replication, this is typically the last
hundreds of milliseconds to seconds of writes.

Minimizing data loss:

`min-replicas-to-write 1`: the primary rejects writes if fewer than 1 replica is
connected and within the replication lag threshold. This prevents isolated primaries
from accepting writes that cannot be replicated.

`min-replicas-max-lag 10`: the replica must have acknowledged replication within the
last 10 seconds; if no replica has acknowledged recently, writes are rejected.

`WAIT numreplicas timeout`: a write command that waits for N replicas to acknowledge;
returns the number of replicas that confirmed; if fewer than N confirm within timeout,
the client knows the write may be lost.

*What separates good from great:* The `WAIT` command limitations. `WAIT` waits for
replication acknowledgment but does not guarantee the write survives failover; if the
primary crashes between `WAIT` returning and the replica persisting to disk, the write
can still be lost. For truly durable writes, use `WAIT 1 0` (wait forever for at least
1 replica) and enable AOF on replicas with `appendfsync everysec`; this combination
makes Redis writes as durable as a database with `w:majority` write concern; the cost
is write latency roughly equal to the round-trip time to the replica.

---

**[SENIOR] Q5 (Scenario): A Redis Cluster node fails. Walk through what happens and how you recover.**

Scenario: master node B (owning slots 5461-10922) fails.

Step 1 - Automatic detection:
- Replica E (replica of B) detects that it has not received a PING from master B in
  `cluster-node-timeout` milliseconds (default: 15,000 ms).
- Other nodes also mark B as PFAIL (possibly failed).
- When a majority of master nodes mark B as PFAIL, it becomes FAIL (confirmed failure).

Step 2 - Automatic failover:
- Replica E starts an election: it asks other masters for votes.
- Masters vote for the replica with the highest replication offset.
- Replica E (or whichever replica has the most data) wins the election.
- Replica E becomes the new master for slots 5461-10922.
- The cluster updates the slot map.

Step 3 - Client impact:
- During detection + election (up to 30-60 seconds total), requests to slots 5461-10922
  return `CLUSTERDOWN` errors.
- After election, clients receive `MOVED` redirects and update their slot maps.
- Normal operation resumes.

Step 4 - Recovery of the failed node:
- Fix the hardware/software issue.
- Start the node: it detects it is no longer the master (cluster has moved on).
- It replicates from the new master (Replica E, now master) and becomes a replica.
- The cluster has the original RF restored (1 master + 1 replica for those slots).

Step 5 - Verify:

```bash
redis-cli -h any-cluster-node -p 6379 CLUSTER INFO
# cluster_state: ok
# cluster_slots_fail: 0
redis-cli CLUSTER NODES
# Verify B is now a replica of E
```

> **Code walkthrough:** (1) WHAT IT SHOWS: diagnostic commands to verify cluster state after a node failure and recovery. (2) KEY MECHANISM: `CLUSTER INFO` shows the overall cluster state; `cluster_state: ok` confirms all slots are assigned; `cluster_slots_fail: 0` confirms no slots are in failed state. (3) WHY IT MATTERS: after a failover, always verify cluster state before declaring recovery complete; a cluster with a failed slot (no master for that slot) silently rejects all operations on that slot's keys. (4) WHAT BREAKS: if the failed node was the only replica of another master, that master now has no replica; the cluster is running with reduced fault tolerance; add a new replica immediately. (5) TAKEAWAY: after any node failure, check `CLUSTER NODES` for any master nodes with 0 replicas and add replicas to restore fault tolerance.

*What separates good from great:* The minimum cluster size for N fault tolerance. For
a Redis Cluster to tolerate F simultaneous master failures: you need at least F+1 masters
in each "availability group" (AZ). For 1-failure tolerance: 3 masters minimum (simple
majority for quorum). For 2-failure tolerance: 5 masters minimum. Additionally, replicas
must be distributed across AZs such that no single AZ failure takes out both a master
and all its replicas simultaneously. For production: deploy 3 masters in 3 AZs, with
each master's replica in a different AZ; this tolerates one full AZ failure without
data loss.

---

**[MID] Q6 (Application): How do you perform a zero-downtime Redis Cluster expansion (add 2 new nodes)?**

Steps for zero-downtime cluster expansion:

Step 1 - Start new nodes:

```bash
redis-server --port 6382 --cluster-enabled yes \
  --cluster-config-file nodes-6382.conf \
  --cluster-node-timeout 5000
redis-server --port 6383 --cluster-enabled yes \
  --cluster-config-file nodes-6383.conf \
  --cluster-node-timeout 5000
```

> **Code walkthrough:** (1) WHAT IT SHOWS: starting two new Redis Cluster nodes with `cluster-enabled yes`; they start as standalone cluster nodes, not yet part of the cluster. (2) KEY MECHANISM: new nodes must be started with `cluster-enabled yes` to participate in cluster gossip; `cluster-config-file` stores the node's cluster state (slots, neighbors); the file is managed by Redis, not manually. (3) WHY IT MATTERS: the new nodes have no slots assigned yet; they accept no key operations until slots are migrated to them. (4) WHAT BREAKS: starting with wrong port or missing `cluster-config-file` causes nodes to not join the cluster properly. (5) TAKEAWAY: always use unique ports and config files for each cluster node.

Step 2 - Add nodes to cluster:

```bash
redis-cli --cluster add-node 127.0.0.1:6382 \
  127.0.0.1:6379
redis-cli --cluster add-node 127.0.0.1:6383 \
  127.0.0.1:6379 \
  --cluster-slave \
  --cluster-master-id <node-6382-id>
```

> **Code walkthrough:** (1) WHAT IT SHOWS: adding the new node as a master to the existing cluster, then adding a second node as its replica. (2) KEY MECHANISM: `add-node` tells an existing cluster node about the new node; the cluster gossip protocol propagates the new member to all nodes; `--cluster-slave` makes the second node a replica of the first new node. (3) WHY IT MATTERS: adding the replica before slot migration ensures the new master already has fault tolerance when it starts receiving traffic. (4) WHAT BREAKS: adding a master without an immediate replica leaves it without fault tolerance during the migration window; always add the replica before starting migration. (5) TAKEAWAY: add master then replica before migrating slots; never run production with an unreplicated master node.

Step 3 - Rebalance slots:

```bash
redis-cli --cluster rebalance 127.0.0.1:6379 \
  --cluster-use-empty-masters
# Migrates slots from existing masters to new master
# Live migration: no downtime; keys served during move
# via ASK redirects
```

> **Code walkthrough:** (1) WHAT IT SHOWS: rebalancing slots across all masters including the new node, which redistributes approximately 25% of the 16,384 slots to the new master. (2) KEY MECHANISM: `rebalance` uses the `CLUSTER SETSLOT` and `MIGRATE` commands to move keys slot-by-slot; during migration, a key can return an ASK redirect; the client follows ASK transparently; no keys are unavailable during migration. (3) WHY IT MATTERS: live migration means zero downtime for the cluster expansion; clients experience slightly higher latency during migration (extra ASK redirect) but do not receive errors. (4) WHAT BREAKS: if `rebalance` is interrupted mid-migration, some slots may be in a `MIGRATING` or `IMPORTING` state; run `redis-cli --cluster fix` to complete the migration. (5) TAKEAWAY: always run `redis-cli --cluster check` before and after rebalancing to verify cluster health and confirm all slots are properly assigned.

*What separates good from great:* The migration bandwidth throttle. Slot migration
moves keys from source to destination using the `MIGRATE` command; large keys (hundreds
of MB) and many small keys can saturate network bandwidth during migration, impacting
normal traffic. Use `redis-cli --cluster rebalance --cluster-pipeline 10` to control
parallelism; schedule rebalancing during off-peak hours; monitor network I/O during
migration. For very large clusters, consider migrating one slot at a time manually
with `CLUSTER SETSLOT` and `MIGRATE` to fully control migration bandwidth.

---

**[SENIOR] Q7 (Trade-off): When should you use Redis read replicas and what are the consistency implications?**

Read replicas: Redis replicas can serve read requests. Benefits: distributes read load
across replica nodes; increases total read throughput; replicas in the same datacenter
as the client have low latency.

Redis replication is asynchronous: the primary sends commands to replicas after
acknowledging to the client. The replica processes commands in order but may lag
behind the primary by milliseconds to seconds.

Consistency implications:
- A read from a replica may return the pre-write value for milliseconds after a write.
- `WAIT` can confirm replication but adds write latency.
- Replicas can be used for read-your-old-writes if stale data is acceptable.

Safe use cases for replica reads:
- Leaderboard data (top N users): a 1-second lag is acceptable.
- Product catalog: prices and descriptions can be slightly stale.
- User profile for display (not authentication).
- Analytics queries: aggregations over data where recent writes are not critical.

Unsafe use cases for replica reads:
- Session token validation (must be current).
- Inventory availability check before checkout (must be current).
- Distributed lock status (must be current).
- Any read-then-write pattern where the write depends on the read value.

*What separates good from great:* The Replica Reads in Redis Cluster with `read_from_replicas`.
When `read_from_replicas=True` in the cluster client, read commands are load-balanced
across masters and replicas. The client cannot distinguish which node serves each read.
This means the same logical operation (read a value just written) can read from the
primary (fresh) or a replica (stale). Applications using replica reads must be designed
to tolerate stale data on every single read operation. The correct pattern: enable
replica reads globally; for critical reads, add `READONLY` target or use the primary
connection explicitly; document which operations require primary reads.
