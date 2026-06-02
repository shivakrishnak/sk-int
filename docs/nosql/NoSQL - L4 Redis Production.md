---
layout: default
title: "NoSQL - L4 Redis Production"
parent: "NoSQL"
nav_order: 11
permalink: /nosql/l4-redis-production/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Redis Production Patterns: Eviction, Memory, and Failures](#redis-production-patterns-eviction-memory-and-failures) | ★★★ |

---

# Redis Production Patterns: Eviction, Memory, and Failures

---

### 🎯 Model Answer

**30 seconds:**
> Production Redis must be configured with three critical settings: (1) `maxmemory` - sets
> the memory limit; without it, Redis consumes all available RAM until the OS kills the
> process. (2) `maxmemory-policy` - determines what Redis evicts when full; `allkeys-lru`
> for cache use cases, `volatile-lru` for mixed cache + session. (3) Persistence - `appendonly
> yes` with `appendfsync everysec` for durability; or RDB-only for pure cache. Production
> failures: memory fragmentation (RSS much larger than used memory), connection storms,
> and blocked commands causing latency spikes.

**3 minutes (Senior):**
> Redis production configuration matrix: (1) Pure cache (data is reproducible) - set
> `maxmemory` to 75% of RAM, `maxmemory-policy allkeys-lru`, disable persistence
> (`save ""`; `appendonly no`). (2) Session store (data must survive restarts) - set
> `maxmemory` with `volatile-lru` policy; enable AOF with `appendfsync everysec`;
> disable RDB to avoid fork latency. (3) Primary database (must not lose data) - enable
> both RDB + AOF; use Sentinel or Cluster for HA; set `maxmemory-policy noeviction`
> (fail writes rather than silently evict data).
>
> Critical failure modes: (1) OOM without maxmemory - Redis fills RAM, OS triggers OOM
> killer; Redis process killed; all data lost; no graceful degradation. (2) Memory
> fragmentation - internal fragmentation ratio (RSS/used_memory) > 1.5 means 50% more
> RAM used than logical data size; fix with `MEMORY PURGE` or restart. (3) SLOWLOG -
> use `SLOWLOG GET` to find commands exceeding `slowlog-log-slower-than` threshold;
> `KEYS *` and large `SMEMBERS` on huge sets are common offenders. (4) Connection pool
> exhaustion - Redis is single-threaded; maximum throughput is ~100K commands/second;
> connection overhead is significant; use connection pooling (redis-py's ConnectionPool,
> Lettuce for Java).

**Framework:** Configure -> Persist -> Evict -> Monitor -> Recover

**Blank Mind Recovery:**

**(1) Restate:** "Redis production: always set maxmemory (prevent OOM). Choose eviction
policy (allkeys-lru for cache). Persistence depends on use case (AOF for durability,
none for pure cache). Monitor: memory fragmentation, slowlog, connected clients."

**(2) First principles:** "Redis is in-memory. Unlike PostgreSQL which pages to disk,
Redis keeps everything in RAM. Without maxmemory, Redis uses all available RAM and the
OS kills the process. Every production Redis must answer: what happens when memory is
full? The maxmemory-policy is the answer."

**(3) Bridge:** "Redis maxmemory-policy is like a hotel booking rule. When the hotel
(Redis) is full, which guests (keys) are evicted? allkeys-lru evicts the guest who
checked in longest ago. volatile-lru evicts only guests with an expiry date (TTL).
noeviction refuses new guests rather than evicting existing ones. Each policy is correct
for a different use case."

---

### 📘 Concept Explanation

**Redis Memory and Eviction Architecture:**

```text
REDIS MEMORY CONFIGURATION:

  maxmemory 4gb         <- absolute RAM limit
  maxmemory-policy X    <- what to do when full

  EVICTION POLICIES (8 options):
  noeviction    <- DENY new writes (safe for primary DB)
  allkeys-lru   <- evict any key (LRU order)
                   best for: pure cache
  volatile-lru  <- evict only keys with TTL (LRU)
                   best for: mixed cache + sessions
  allkeys-lfu   <- evict any key (LFU order)
                   best for: access-frequency skewed
  volatile-lfu  <- evict TTL keys (LFU order)
  allkeys-random  <- evict random key (not recommended)
  volatile-random <- evict random TTL key
  volatile-ttl  <- evict key with shortest TTL

  LRU vs LFU:
  LRU: evict least recently USED
       Good when: every key is equally likely
                  to be needed again
       Bad when:  one hot key not accessed for
                  1 hour followed by 10M accesses
       -> LRU evicts the hot key, miss storm!

  LFU: evict least frequently USED
       Counter per key (0-255, log scale)
       Good when: some keys are always hot
       Bad when:  access pattern changes rapidly
                  (old hot keys accumulate counts)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Redis eviction policy taxonomy with
> recommendations for each use case and the LRU vs LFU trade-off. (2) HOW TO READ IT:
> the top shows the maxmemory configuration directives; the middle lists all 8 eviction
> policies with brief descriptions; the bottom shows the LRU vs LFU distinction with
> the specific failure mode for each. (3) KEY RELATIONSHIP: the eviction policy choice
> must match the Redis use case; a wrong policy causes either data loss (allkeys-lru
> evicting session data) or OOM errors (noeviction when memory fills). (4) EDGE CASE:
> `volatile-lru` is dangerous when all keys have TTL set - it behaves the same as
> `allkeys-lru`; and when no keys have TTL, it behaves like `noeviction` and returns
> errors when full. (5) INSIGHT: a senior engineer uses `allkeys-lfu` when the Redis
> cache has a power-law access distribution (a small number of keys are accessed far
> more than others); LFU prevents those hot keys from being evicted by less-popular
> but more-recently-accessed keys.

**Redis Memory Internals:**

```text
REDIS MEMORY CONCEPTS:

  used_memory:      <- logical data size
    (keys + values + metadata)

  used_memory_rss:  <- OS-allocated physical memory
    (includes fragmentation, jemalloc overhead)

  mem_fragmentation_ratio:
    = used_memory_rss / used_memory
    < 1.0: OS swapping (CRITICAL - fix immediately)
    1.0 - 1.5: healthy
    1.5 - 2.0: moderate fragmentation
    > 2.0: severe fragmentation

  FRAGMENTATION CAUSES:
  1. Many small string keys (hash overhead per key)
  2. Frequent key deletion/resizing leaves memory holes
  3. Long-running Redis without restart
     (jemalloc doesn't compact aggressively)

  FRAGMENTATION FIX OPTIONS:
  A. MEMORY PURGE (Redis 4+)     <- zero-downtime
     -> asks jemalloc to return freed pages to OS
     -> can take seconds on large instances
  B. CONFIG SET activedefrag yes <- background fix
     -> auto-defragmentation when ratio > 1.5
     -> slight CPU overhead
  C. Restart Redis               <- last resort
     -> zero fragmentation after restart
     -> requires data migration or empty cache
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Redis memory concepts (used_memory
> vs used_memory_rss), the fragmentation ratio calculation, and the three options for
> fixing excessive fragmentation. (2) HOW TO READ IT: the top shows the two key memory
> metrics; the middle shows the fragmentation ratio interpretation; the bottom shows the
> three mitigation strategies ordered by preference (least disruptive first). (3) KEY
> RELATIONSHIP: `used_memory_rss` is always >= `used_memory`; the gap is fragmentation
> overhead; a large gap means RAM is being wasted on internal allocation overhead rather
> than actual data. (4) EDGE CASE: a `mem_fragmentation_ratio < 1.0` is more dangerous
> than high fragmentation - it means Redis is using more virtual memory than physical;
> the OS is paging Redis data to disk; Redis latency will spike to milliseconds or
> seconds per command. (5) INSIGHT: a senior engineer sets `activedefrag yes` as a
> standard production configuration; it prevents fragmentation from accumulating over
> time; the CPU overhead is minimal (< 1%) and the benefit (predictable memory usage)
> is significant for long-running Redis instances.

---

### 💻 Code Example

```python
# BAD: Redis without maxmemory (production anti-pattern)
import redis

# No maxmemory configured -> Redis will consume all RAM
# When Redis fills available RAM:
# - Linux OOM killer terminates the process
# - All data lost instantly
# - No graceful degradation
r = redis.Redis(host="redis", port=6379)

# This will work until memory is exhausted
for i in range(10_000_000):
    r.set(f"session:{i}", "x" * 1024)  # 1KB each = 10GB

# At ~10GB Redis fills available RAM
# OOM killer terminates Redis
# ALL sessions lost
# Application auth fails for all users
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the consequence of running Redis without
> `maxmemory` configuration - when memory fills, the OS OOM killer terminates the process
> with no warning and no data is preserved. (2) KEY MECHANISM: Redis by default has no
> memory limit; it allocates memory from the OS until the OS cannot allocate more; Linux's
> OOM killer then selects a process to kill based on memory usage; Redis is often the
> target. (3) WHY IT MATTERS: this is a production anti-pattern that causes complete data
> loss and application downtime; all connected clients receive `ConnectionRefusedError`
> after the OOM kill. (4) WHAT BREAKS: the application receives no warning before the OOM
> kill; the first indication is connection errors from all application servers; the lack
> of graceful degradation means the incident is always severe. (5) TAKEAWAY: `maxmemory`
> is the single most important Redis production configuration; set it to 75-80% of
> available RAM; always set it, even for development environments.

```python
# GOOD: Redis with maxmemory and appropriate policy

# redis.conf settings (or CONFIG SET at runtime):
# maxmemory 4gb
# maxmemory-policy allkeys-lru
# maxmemory-samples 10 (sample size for LRU eviction)

r = redis.Redis(host="redis", port=6379)

# With allkeys-lru: when memory is full,
# Redis evicts the least recently used key
# The application continues running; old keys are
# removed to make room for new ones

# Monitor memory usage
def check_redis_memory(redis_client):
    info = redis_client.info("memory")
    used = info["used_memory"]
    rss  = info["used_memory_rss"]
    max_mem = info.get("maxmemory", 0)
    frag = info["mem_fragmentation_ratio"]

    print(f"Used:   {used / 1e9:.1f} GB")
    print(f"RSS:    {rss / 1e9:.1f} GB")
    if max_mem:
        pct = (used / max_mem) * 100
        print(f"Max:    {max_mem / 1e9:.1f} GB ({pct:.0f}% full)")
    print(f"Frag:   {frag:.2f}")

    if frag > 1.5:
        print("WARNING: high fragmentation")
    if max_mem and used > max_mem * 0.90:
        print("WARNING: memory > 90% - evictions accelerating")

check_redis_memory(r)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a Python function that reads Redis memory
> metrics from `INFO memory` and alerts on high fragmentation and memory pressure.
> (2) KEY MECHANISM: `redis_client.info("memory")` returns a dict with all memory
> metrics; `used_memory` is the logical data size; `used_memory_rss` is the OS
> allocation; `maxmemory` is the configured limit (0 = unlimited); `mem_fragmentation_ratio`
> is the pre-computed ratio. (3) WHY IT MATTERS: monitoring memory at 90% full allows
> proactive action before Redis reaches `maxmemory` and starts evicting aggressively;
> when Redis is evicting at high rates, cache hit rates drop suddenly. (4) WHAT BREAKS:
> `info.get("maxmemory", 0)` returns 0 when `maxmemory` is not configured; the percentage
> calculation is skipped - this is intentional; the absence of maxmemory is itself
> a warning condition that should be alerted separately. (5) TAKEAWAY: add this memory
> check to the application's health check endpoint or as a Prometheus metric; alert when
> fragmentation > 1.5 and when memory usage > 85%.

```python
# Redis production operations: SLOWLOG analysis
# and blocked command detection

import redis
from datetime import datetime

r = redis.Redis(host="redis", port=6379)

# Get slow commands (slower than slowlog-log-slower-than)
# Default: 10000 microseconds (10ms)
def analyze_slowlog(redis_client, count: int = 50):
    slowlog = redis_client.slowlog_get(count)
    if not slowlog:
        print("No slow commands in slowlog")
        return

    print(f"Top {len(slowlog)} slow commands:")
    for entry in slowlog:
        ts = datetime.fromtimestamp(entry["start_time"])
        duration_ms = entry["duration"] / 1000  # us -> ms
        cmd = " ".join(
            arg.decode() if isinstance(arg, bytes)
            else str(arg)
            for arg in entry["command"][:3]  # first 3 args
        )
        print(f"  [{ts}] {duration_ms:.0f}ms: {cmd}")

# Find blocked or long-running clients
def check_blocked_clients(redis_client):
    info = redis_client.info("clients")
    blocked = info["blocked_clients"]
    connected = info["connected_clients"]

    print(f"Connected clients: {connected}")
    if blocked > 0:
        print(f"WARNING: {blocked} blocked clients")
        # BLPOP / BRPOP / WAIT commands block clients
        # High blocked count -> command queue pressure

    # Get per-client details
    client_list = redis_client.client_list()
    slow_clients = [
        c for c in client_list
        if int(c.get("age", 0)) > 60  # older than 60s
    ]
    if slow_clients:
        print(f"Long-lived clients: {len(slow_clients)}")
        for c in slow_clients[:5]:
            print(f"  {c['addr']} age={c['age']}s "
                  f"cmd={c.get('cmd', '?')}")

analyze_slowlog(r, count=10)
check_blocked_clients(r)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: two diagnostic functions - one that reads
> Redis SLOWLOG to identify slow commands, and another that checks for blocked clients
> and long-lived connections. (2) KEY MECHANISM: `SLOWLOG GET N` returns the N most
> recent slow commands with their duration in microseconds, the command name, and the
> timestamp; this is the primary tool for identifying Redis performance bottlenecks.
> `CLIENT LIST` returns all connected clients with state, age, and last command. (3)
> WHY IT MATTERS: Redis is single-threaded; a single slow command (e.g., `KEYS *` on
> a database with 10 million keys) blocks all other commands for its duration; the
> SLOWLOG reveals these bottlenecks. (4) WHAT BREAKS: SLOWLOG is an in-memory ring
> buffer (default size: 128 entries); high-traffic Redis instances may rotate the log
> quickly; use a lower `slowlog-log-slower-than` threshold (1000us = 1ms) and a larger
> `slowlog-max-len` to catch more events. (5) TAKEAWAY: set `slowlog-log-slower-than 1000`
> (1ms) and `slowlog-max-len 1000` in production Redis; periodically drain the SLOWLOG
> with a background job and publish to Prometheus for trend analysis.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Three critical Redis production settings: `maxmemory` (limits RAM usage; prevents OOM
> kill), `maxmemory-policy` (what to evict when full; use `allkeys-lru` for caches),
> and persistence (AOF for durability; disable for pure caches). Monitor with
> `INFO memory` for fragmentation and `SLOWLOG GET` for slow commands. Avoid `KEYS *`
> in production (blocks all other commands); use `SCAN` instead.

---

**Senior / Staff (5+ years):**
> Redis production failures and their diagnosis: (1) OOM kill - `used_memory` approaching
> or exceeding `maxmemory`; no eviction policy set; fix: add `maxmemory` + policy before
> next Redis restart. (2) Fragmentation spiral - `mem_fragmentation_ratio > 2.0`; many
> small key deletions; fix: `CONFIG SET activedefrag yes`; or `MEMORY PURGE` during
> off-peak. (3) Latency spike every N seconds - RDB fork latency; `BGSAVE` command
> triggered periodically; disable RDB (`save ""`) for cache-only Redis; use AOF for
> persistence. (4) Connection pool exhaustion - `connected_clients` at max; application
> waiting for connections; fix: tune `maxclients` (default: 10000); use connection
> pooling with bounded pool size; use Redis pipelining to reduce round-trips. (5) Memory
> leak (used_memory grows indefinitely) - keys without TTL accumulate; fix: audit key
> creation patterns; ensure all cache keys have TTL; use `DEBUG SLEEP` + `MONITOR` to
> identify which application component is creating TTL-less keys.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Redis persistence (AOF/RDB) makes Redis safe for primary database use."**

Redis is an in-memory database first. Even with full AOF persistence, Redis has
characteristics that make it unsuitable as a primary database for critical data:
(1) Recovery time: replaying a large AOF file on startup can take minutes or hours;
during this time, Redis is unavailable. (2) Data loss window: with `appendfsync everysec`,
up to 1 second of writes can be lost on crash. With `appendfsync always`, write
throughput drops to the fsync rate (~1,000-10,000 writes/second vs. millions/second
without fsync). (3) No query language: Redis has no SQL; complex queries, aggregations,
and joins are not possible without application-level code. For data that requires ACID
guarantees, complex queries, and zero tolerance for data loss, use PostgreSQL as the
primary database and Redis as a caching layer.

**Misconception 2: "LRU eviction policy ensures the most useful data stays in cache."**

LRU (Least Recently Used) evicts keys that have not been accessed recently. It does
NOT account for access frequency. Example: a key accessed 10 million times over the
past week but not accessed in the last hour is a candidate for LRU eviction. A key
accessed once 5 minutes ago is NOT a candidate. If the 10-million-access key is evicted,
the next request for it causes a cache miss that hits the database (potentially under
high load). LFU (Least Frequently Used) is more appropriate when the access pattern
has a stable hot set. Use `maxmemory-policy allkeys-lfu` when the cache has a clear
Pareto distribution (20% of keys receive 80% of requests).

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Redis OOM kill - all data lost.**

Symptom: application receives `ConnectionRefusedError` from Redis; Redis process not
running; system logs show `Out of memory: Kill process [PID] (redis-server)`.
Root cause: `maxmemory` not configured; Redis consumed all available RAM; Linux OOM
killer terminated the Redis process.
Diagnosis:

{% raw %}
```bash
# Check if Redis is running
systemctl status redis-server
# or
docker inspect --format '{{.State.Status}}' redis

# Check system OOM events
dmesg | grep -i "out of memory" | tail -5
# "Out of memory: Kill process 12345 (redis-server) score 900"

# Check Redis memory config (if Redis is up)
redis-cli CONFIG GET maxmemory
# "maxmemory" "0" -> 0 = unlimited (the problem)
```
> **Code walkthrough:** (1) WHAT IT SHOWS: diagnosing a Redis OOM kill - checking the process status, system OOM logs, and the root cause configuration. (2) KEY MECHANISM: `dmesg | grep "out of memory"` shows the Linux OOM killer's decision log including the process killed and its "OOM score"; Redis typically has a high OOM score because it holds all its data in memory; `CONFIG GET maxmemory` returning "0" confirms `maxmemory` was not set. (3) WHY IT MATTERS: a Redis OOM kill is always preventable; it represents a configuration failure, not an unexpected system failure. (4) WHAT BREAKS: the `docker inspect --format` command contains Liquid-sensitive `{{ }}` patterns protected by the raw tags around this code block. (5) TAKEAWAY: add `maxmemory` verification to the deployment checklist; reject Redis deployments that do not specify `maxmemory`; this is a one-line configuration that prevents the most severe Redis failure mode.
{% endraw %}

Prevention: set `maxmemory` to 75-80% of available RAM; set an appropriate eviction
policy; set up CloudWatch/Prometheus alert when `used_memory > maxmemory * 0.85`.

**Failure Mode 2: Redis latency spikes every N seconds (RDB fork issue).**

Symptom: Redis commands have p99 latency of 1-5ms normally; every N seconds (matching
the `save` interval), p99 spikes to 100ms-1s.
Root cause: RDB `BGSAVE` fork operation; fork copies the process address space (even
with COW, this takes time proportional to dataset size; with THP enabled on Linux, the
first write after fork causes huge page splits adding to latency).

Diagnosis:

```bash
redis-cli LATENCY HISTORY fork
# Shows fork event durations over time
# Correlate with configured save interval

redis-cli CONFIG GET save
# "save" "900 1 300 10 60 10000"
# 60-second interval matches spike frequency

redis-cli INFO memory | grep mem_allocator
# "mem_allocator:jemalloc-5.3.0"

# Check Transparent Huge Pages (THP) status on host
cat /sys/kernel/mm/transparent_hugepage/enabled
# [always] madvise never <- "always" causes fork latency
```

> **Code walkthrough:** (1) WHAT IT SHOWS: diagnosing RDB fork latency by checking the Redis latency history for fork events, the save configuration, and the Linux THP setting. (2) KEY MECHANISM: `LATENCY HISTORY fork` shows the duration of each fork event; comparing with the `save` interval confirms the correlation; THP `[always]` means the OS uses 2MB huge pages; when the forked process writes to a huge page, the OS must split it into 4KB pages (a "huge page split"), adding CPU time to the COW mechanism. (3) WHY IT MATTERS: a 500ms fork latency spike every 60 seconds appears as a reliability issue to users (1% of requests with > 500ms latency); disabling RDB for cache-only Redis eliminates this entirely. (4) WHAT BREAKS: `CONFIG SET save ""` at runtime stops future RDB saves but does not remove the current scheduled save; verify with `CONFIG GET save` after the change. (5) TAKEAWAY: for cache-only Redis (data can be lost on restart), disable RDB with `save ""` and disable AOF; this eliminates fork latency spikes; the trade-off is losing all data on restart (acceptable for a pure cache).

Fix: for cache-only Redis: `CONFIG SET save ""` (disable RDB);
For persistent Redis: disable THP on the host: `echo never > /sys/kernel/mm/transparent_hugepage/enabled`;
add to `/etc/rc.local` for persistence across reboots.

---

### ⚖️ Comparison Table

| Configuration | Use Case | maxmemory-policy | Persistence | Risk |
|---|---|---|---|---|
| Pure cache | Sessions, hot data | allkeys-lru or allkeys-lfu | None | Data loss on restart (ok) |
| Session store | Auth tokens | volatile-lru | AOF everysec | 1-second data loss |
| Primary DB | Critical data | noeviction | AOF always + RDB | Write throughput reduced |
| Rate limiter | API limiting | volatile-ttl | None | Counter loss on restart (ok) |
| Message queue | Pub/Sub | noeviction | AOF everysec | Write failure when full |

---

### 🏛️ System Design

**High-Availability Redis for Session Management:**

Architecture: Redis Sentinel (3 nodes: 1 primary + 2 replicas) + 3 Sentinel processes.

Configuration for session store:
- `maxmemory 2gb` (session store; sized for max concurrent sessions).
- `maxmemory-policy volatile-lru` (evict expired sessions first).
- `appendonly yes`, `appendfsync everysec` (1-second data loss acceptable).
- `save ""` (disable RDB; AOF provides persistence without fork latency).
- `replica-priority` configured for replica preference during failover.

Sentinel configuration:
- `sentinel down-after-milliseconds mymaster 5000` (5s to detect failure).
- `sentinel failover-timeout mymaster 10000` (10s failover).
- `sentinel parallel-syncs mymaster 1` (one replica syncs at a time during failover).

Application connection (redis-py Sentinel):

```python
from redis.sentinel import Sentinel

sentinel = Sentinel([
    ("sentinel1", 26379),
    ("sentinel2", 26379),
    ("sentinel3", 26379)
], socket_timeout=0.5)

# Automatically routes to primary for writes
primary = sentinel.master_for(
    "mymaster",
    socket_timeout=0.5
)
# Routes to a replica for reads (read scaling)
replica = sentinel.slave_for(
    "mymaster",
    socket_timeout=0.5
)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a Redis Sentinel-aware Python connection that automatically routes to the current primary for writes and to replicas for reads. (2) KEY MECHANISM: the Sentinel client queries Sentinel processes to discover the current primary address; if the primary fails and Sentinel promotes a replica, the client automatically connects to the new primary on the next operation (after a brief `ConnectionError`). (3) WHY IT MATTERS: Sentinel provides HA without application code changes; the connection string points to Sentinel servers, not to Redis directly; the client handles primary discovery and failover transparently. (4) WHAT BREAKS: during failover (30-60 seconds), write operations fail with `ConnectionError`; the application must handle this with retry logic; `socket_timeout=0.5` ensures failed connections fail fast rather than hanging. (5) TAKEAWAY: always use a Sentinel-aware or Cluster-aware client library in production; never hardcode the Redis primary IP address in the application; the IP changes on failover.

---

### 📊 Diagram

```text
REDIS FAILURE MODES AND CAUSES:

  [Redis Process]
       |
  used_memory growing
       |
  +----+----+----------+
  |    |    |          |
  OOM  Frag  SLOWLOG  MaxMem
  Kill  Ratio  Issues  Policy

  OOM Kill:                Fragmentation:
  -> No maxmemory set      -> RSS/used_memory > 1.5
  -> OS kills Redis        -> Memory holes from
  -> All data lost            key deletions
  -> Fix: add maxmemory    -> Fix: activedefrag yes

  SLOWLOG Issues:          MaxMem Policy:
  -> KEYS * blocks all     -> Wrong policy evicts
  -> Large SMEMBERS           needed data
  -> Lua scripts           -> noeviction when full
  -> Fix: use SCAN,           rejects all writes
     bounded sets          -> Fix: match policy
                              to use case

  LATENCY CONTRIBUTORS:
  1. RDB fork (BGSAVE)     -> disable for cache
  2. AOF fsync (everysec)  -> 1-2ms per second
  3. Memory defrag         -> background CPU
  4. Large value serialize -> avoid >10MB values
  5. Replication backlog   -> sentinel/cluster lag
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the major Redis failure modes organized
> by root cause - OOM kill, memory fragmentation, SLOWLOG command issues, and maxmemory
> policy mismatches - with fixes for each. (2) HOW TO READ IT: start at the top with
> `[Redis Process]`; `used_memory growing` branches into four failure categories; each
> shows the symptom, cause, and fix. (3) KEY RELATIONSHIP: all four failure modes share
> the root cause of configuration mismatch - the Redis configuration was not aligned with
> the application's use case and traffic patterns. (4) EDGE CASE: the latency contributors
> at the bottom are additive; a Redis instance that has RDB enabled + AOF fsync + active
> defrag + large values can accumulate latency contributions from all five sources
> simultaneously; each must be diagnosed and addressed independently. (5) INSIGHT: a
> senior engineer configures Redis differently for each role (cache vs session store vs
> primary database) and uses configuration templates for each role; applying a "one size
> fits all" Redis configuration is the most common source of Redis production problems.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | maxmemory-policy options, eviction mechanisms |
| Mechanism | 2 | LRU vs LFU, fork latency |
| Debugging | 3 | SLOWLOG, OOM diagnosis, fragmentation |
| Trade-off | 2 | Persistence trade-offs, eviction policies |
| Application | 2 | Session HA, cache stampede |
| Scenario | 1 | Production OOM incident |

---

**[SENIOR] Q1 (Definition): Explain the Redis maxmemory-policy options and when to use each.**

Redis has 8 eviction policies:

`noeviction`: When memory is full, Redis returns an error for all write commands.
Reads and deletes still work. Use when: Redis is a primary database and data loss from
eviction is unacceptable; you prefer write failures over silent data loss. Risk: if
the application does not handle `OOM command not allowed` errors, it crashes.

`allkeys-lru`: Evict any key (regardless of TTL) using LRU approximation (not exact LRU).
Use when: all keys are cache entries; any key can be regenerated on miss; uniform
access distribution. Default for: general-purpose caches.

`volatile-lru`: Evict only keys with TTL set, using LRU approximation.
Use when: mixing persistent keys (no TTL) and cache entries (with TTL); want to protect
persistent keys from eviction. Risk: if no keys have TTL, behaves like `noeviction`.

`allkeys-lfu`: Evict any key based on access frequency (LFU). Redis 4.0+.
Use when: access pattern has a hot set (some keys accessed orders of magnitude more
often); LFU prevents hot keys from being evicted by recently-accessed but infrequent
keys.

`volatile-lfu`: Like `allkeys-lfu` but only for keys with TTL.

`allkeys-random`: Evict a random key. Not recommended for most use cases.
Use when: all keys have equal probability of future access (rare).

`volatile-random`: Evict a random key with TTL.

`volatile-ttl`: Evict the key with the shortest remaining TTL.
Use when: you want to aggressively remove soon-to-expire data first.

*What separates good from great:* The LRU approximation detail. Redis does not implement
exact LRU (which would require tracking access time for all keys, using O(N) memory).
Instead, Redis implements a probabilistic LRU: when eviction is needed, Redis samples
`maxmemory-samples` keys (default: 5) and evicts the least recently used among the sample.
With `maxmemory-samples = 10`, the approximation closely matches exact LRU. Setting
`maxmemory-samples = 5` (default) is faster but less accurate. Production tuning: set
`maxmemory-samples 10` for better eviction quality at a small CPU cost.

---

**[SENIOR] Q2 (Mechanism): Why does Redis experience latency spikes during RDB saves? How does Transparent Huge Pages (THP) make it worse?**

RDB save mechanism:
Redis uses `fork()` to create a child process. The child writes a snapshot to disk
while the parent continues serving requests. `fork()` is supposed to be fast (copy-on-
write semantics: memory pages are shared until one process writes to them).

Why fork causes latency:
1. Page table copy: `fork()` copies the parent's page table (metadata, not actual data).
   For a 64 GB Redis instance, the page table can be hundreds of MB; copying this takes
   50-200ms.
2. COW write latency: when the parent process writes to a memory page after fork,
   the OS must copy that page for the child process (copy-on-write). Each COW copy
   takes a page fault. Under write-heavy workloads, many pages are copied, adding
   CPU and memory latency.

Transparent Huge Pages (THP) makes it worse:
- Normal Linux pages: 4 KB each. For 64 GB Redis: 16 million pages. Fork copies
  16 million page table entries.
- THP pages: 2 MB each. For 64 GB Redis: 32,768 pages. Fork copies 32,768 entries
  (much faster page table copy).
- BUT: when the parent writes to a 2 MB huge page after fork, the OS must split the
  2 MB page into 512 x 4 KB pages before copy-on-write can work. This "huge page split"
  is expensive (interrupts, TLB invalidation) and causes significant latency spikes.
- Result: THP makes fork (page table copy) faster but makes COW latency much worse
  for write-heavy Redis.

Redis documentation: always disable THP on Redis hosts.
`echo never > /sys/kernel/mm/transparent_hugepage/enabled`

*What separates good from great:* The jemalloc huge page interaction. Redis uses jemalloc
as its memory allocator. jemalloc itself requests memory from the OS in large chunks
(often huge pages if THP is enabled). When Redis frees memory (key expiry, eviction),
jemalloc may not immediately return the memory to the OS, contributing to fragmentation.
`CONFIG SET activedefrag yes` enables background defragmentation that can help, but the
most reliable fix is disabling THP (prevents huge page fragmentation) and configuring
`jemalloc_bg_thread` (enables background jemalloc thread for memory management).

---

**[SENIOR] Q3 (Debugging): You see Redis p99 latency suddenly increase from 1ms to 50ms. Walk through the diagnostic process.**

Step 1 - Check SLOWLOG:

```bash
redis-cli SLOWLOG GET 20
# "1) 1) (integer) 12345
#     2) (integer) 1705344000  (timestamp)
#     3) (integer) 45000       (duration: 45ms)
#     4) 1) "KEYS"
#        2) "*"
#    "
# -> KEYS * is running in production!
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using SLOWLOG to identify that `KEYS *` is being executed in production, taking 45ms and blocking all other Redis commands. (2) KEY MECHANISM: `SLOWLOG GET 20` returns the 20 most recent commands that exceeded `slowlog-log-slower-than` (default: 10ms); the output shows the command name, arguments, duration, and timestamp; `KEYS *` with 45ms duration confirms it is the source of the latency spike. (3) WHY IT MATTERS: Redis is single-threaded; `KEYS *` on a database with millions of keys takes tens of milliseconds to complete; during this time, all other commands wait in the queue. (4) WHAT BREAKS: `SLOWLOG GET` itself is O(1); it is always safe to run even on a high-latency instance. (5) TAKEAWAY: the first diagnostic step for any Redis latency issue is `SLOWLOG GET 20`; it reveals the most common causes (KEYS *, large SMEMBERS, Lua scripts) immediately.

Step 2 - Check for blocking clients:

```bash
redis-cli CLIENT LIST | grep -v "cmd=ping" | \
  awk -F' ' '{for(i=1;i<=NF;i++) if($i~/age=/) print $i}' | \
  sort -t= -k2 -n | tail -5
# Find clients that have been connected longest
# Long-lived clients with BLPOP or WAIT block the server
```

> **Code walkthrough:** (1) WHAT IT SHOWS: filtering `CLIENT LIST` to find long-lived client connections that might be blocking Redis. (2) KEY MECHANISM: `CLIENT LIST` returns all connected clients with their age (seconds connected), current command, and state; sorting by `age=` descending reveals clients that have been connected longest, which may be holding blocking commands like `BLPOP`. (3) WHY IT MATTERS: a client issuing `BLPOP` with a long timeout holds a connection open; if many clients are blocking, the connection count rises; Redis handles connections with a thread but blocking commands wait in the event loop. (4) WHAT BREAKS: `CLIENT LIST` output format may vary across Redis versions; the awk filter is version-specific; consider using `CLIENT LIST TYPE normal` (Redis 6+) to filter by client type. (5) TAKEAWAY: investigate `CLIENT LIST` when `connected_clients` in `INFO clients` is high relative to expected connection pool size; unexpected long-lived connections indicate connection pool misconfiguration in the application.

Step 3 - Check RDB/AOF activity:

```bash
redis-cli INFO persistence
# "rdb_bgsave_in_progress:1" -> RDB save happening now
# "rdb_last_bgsave_status:ok"
# "aof_rewrite_in_progress:0"
# "rdb_current_bgsave_time_sec:45"
# -> RDB save has been running for 45 seconds!
# Large dataset or slow disk
```

> **Code walkthrough:** (1) WHAT IT SHOWS: checking Redis persistence status to see if an in-progress RDB save is causing the latency spike. (2) KEY MECHANISM: `rdb_bgsave_in_progress:1` confirms a BGSAVE is active; `rdb_current_bgsave_time_sec:45` shows it has been running for 45 seconds, which is abnormally long for a typical Redis instance; this confirms RDB fork and COW activity is contributing to the latency. (3) WHY IT MATTERS: an in-progress BGSAVE for 45+ seconds suggests either a very large dataset or a slow disk; the write operations during this time are all subject to COW overhead. (4) WHAT BREAKS: `redis-cli BGSAVE` triggers an additional BGSAVE; do not run this during diagnosis as it compounds the problem. (5) TAKEAWAY: `INFO persistence` should be part of every Redis latency diagnostic checklist; a long-running BGSAVE is a common and easily identifiable cause of sustained latency elevation.

*What separates good from great:* The `DEBUG SLEEP` test. To rule out Redis-internal
causes and confirm the latency is in Redis (not network or client), run `DEBUG SLEEP 0`
from the same host as the application. If `DEBUG SLEEP 0` returns in > 1ms, Redis
itself is slow (not the network). Then use `redis-cli --latency` or
`redis-cli --latency-history` to measure sustained latency. These tools run `PING`
in a loop and report min/max/avg latency, distinguishing network latency from Redis
execution latency.

---

**[SENIOR] Q4 (Trade-off): Compare AOF `appendfsync always` vs `appendfsync everysec` vs `appendfsync no` for persistence durability and write throughput.**

AOF (Append Only File) sync modes control when Redis calls `fsync()` on the AOF file
to persist data to disk:

`appendfsync always`:
- Every write operation is fsynced to disk before acknowledging the client.
- Durability: zero data loss; every acknowledged write is on disk.
- Throughput: limited by `fsync` latency; modern SSDs support 1,000-10,000 fsync/second;
  Redis write throughput drops to this rate (vs millions/second without fsync).
- Use when: financial data, audit logs, or any data where zero loss is required.
- Production implication: Redis latency p99 matches disk fsync latency (1-5ms on SSD).

`appendfsync everysec` (recommended default):
- Redis fsyncs the AOF file once per second in a background thread.
- Durability: up to 1 second of writes can be lost on crash.
- Throughput: near full Redis throughput; the background fsync does not block writes.
- Use when: session stores, general-purpose caching with persistence, any use case
  where 1-second data loss is acceptable.
- Production implication: if the AOF file is on a slow disk, the background fsync
  thread may fall behind, eventually causing write stalls.

`appendfsync no`:
- Redis never calls `fsync()`; the OS decides when to flush the buffer to disk.
- Durability: up to OS buffer interval of data can be lost (typically 30 seconds).
- Throughput: maximum Redis throughput; no fsync overhead.
- Use when: pure cache (data is reproducible from the source); Redis is used as an
  in-memory acceleration layer only.
- Production implication: on OS crash (not just Redis crash), all in-memory data
  that has not been flushed is lost.

*What separates good from great:* The AOF file growth management. With `everysec`,
the AOF file grows continuously as commands are appended. Without AOF rewrite, the
file grows indefinitely. Redis periodically rewrites the AOF file (`BGREWRITEAOF`) to
create a minimal representation of the current state (removes superseded SET commands,
merges INCR operations). The rewrite uses `fork()` and has the same fork latency
implications as RDB saves. For write-heavy Redis, schedule AOF rewrites during off-peak
hours using `auto-aof-rewrite-min-size` and `auto-aof-rewrite-percentage` configuration.

---

**[SENIOR] Q5 (Scenario): A production Redis instance serving sessions suddenly returns `OOM command not allowed when used memory > 'maxmemory'` errors. How do you diagnose and recover without user disruption?**

Immediate triage (first 5 minutes):

Step 1 - Assess current memory state:

```bash
redis-cli INFO memory | grep -E "used_memory|maxmemory|evicted"
# used_memory:4294967296       -> 4 GB used
# maxmemory:4294967296         -> 4 GB limit
# evicted_keys:0               -> no eviction policy!
# maxmemory_policy:noeviction  -> returns errors when full
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Redis memory state confirming the root cause - `maxmemory_policy:noeviction` means Redis returns errors rather than evicting keys, and `used_memory` has reached `maxmemory`. (2) KEY MECHANISM: `evicted_keys:0` combined with `noeviction` policy and `used_memory = maxmemory` confirms the configuration mismatch; the instance was likely configured for a "primary database" use case but is being used as a session cache. (3) WHY IT MATTERS: this confirms the fix: change the maxmemory policy to allow eviction; no data needs to be migrated. (4) WHAT BREAKS: changing to `volatile-lru` when no keys have TTL still results in errors (no keys can be evicted); must first add TTL to session keys OR change to `allkeys-lru`. (5) TAKEAWAY: always check `maxmemory_policy` first when debugging OOM errors; `noeviction` with `used_memory = maxmemory` is the clearest configuration mismatch diagnosis.

Step 2 - Immediate fix (runtime, no restart):

```bash
# For session cache: volatile-lru (evict LRU TTL keys)
redis-cli CONFIG SET maxmemory-policy volatile-lru
# OR for general cache: allkeys-lru
redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Verify change
redis-cli CONFIG GET maxmemory-policy
```

> **Code walkthrough:** (1) WHAT IT SHOWS: changing the maxmemory policy at runtime using `CONFIG SET` without restarting Redis. (2) KEY MECHANISM: `CONFIG SET maxmemory-policy volatile-lru` takes effect immediately; subsequent writes no longer return `OOM command not allowed`; Redis begins evicting LRU keys with TTL to make room. (3) WHY IT MATTERS: this is a zero-downtime fix; no restart required; existing sessions are not disturbed; the policy change resolves the error condition within seconds. (4) WHAT BREAKS: if `volatile-lru` is chosen but no session keys have TTL, the behavior reverts to `noeviction`; add TTL to session keys after the policy change. (5) TAKEAWAY: test all `CONFIG SET` changes in staging before applying to production; `CONFIG SET` at runtime does not persist across restarts; persist to `redis.conf` or run `CONFIG REWRITE` to make the change permanent.

Step 3 - Persist the configuration change:

```bash
# Persist to redis.conf (prevents regression after restart)
redis-cli CONFIG REWRITE
# Writes current CONFIG to redis.conf
```

> **Code walkthrough:** (1) WHAT IT SHOWS: persisting the runtime configuration change to `redis.conf` so the fix survives the next Redis restart. (2) KEY MECHANISM: `CONFIG REWRITE` reads the in-memory configuration and rewrites `redis.conf` to match; all `CONFIG SET` changes become permanent without manually editing the file. (3) WHY IT MATTERS: `CONFIG SET` changes are lost on Redis restart; `CONFIG REWRITE` is the last step of any emergency configuration change to prevent regression. (4) WHAT BREAKS: if `redis.conf` was not specified when Redis was started, `CONFIG REWRITE` fails with `ERR The server is running without a config file`; in that case, manually edit the startup configuration. (5) TAKEAWAY: always follow `CONFIG SET` with `CONFIG REWRITE`; create a standard runbook step for Redis configuration changes that includes both commands. After switching to
`volatile-lru`, sessions without TTL are still immune to eviction. If many sessions
were created without TTL, they will accumulate indefinitely, eventually filling Redis
again. After the immediate fix, audit session key TTL coverage: `redis-cli SCAN 0
COUNT 100 MATCH "session:*"` and check TTL for a sample of session keys with
`redis-cli DEBUG SLEEP 0; OBJECT IDLETIME session:example_key`. Establish a policy
that all session keys must have TTL at creation time; add a code review check for
Redis SET operations that omit EX (expiry) on session keys.

---

**[SENIOR] Q6 (Application): Design a Redis connection pool for a high-throughput Python application. What settings matter?**

Connection pool fundamentals:
A connection pool maintains a fixed set of pre-established TCP connections to Redis.
Instead of creating a new connection per request (expensive: TCP handshake, AUTH,
SELECT), requests borrow a connection from the pool and return it after use.

Critical settings:

`max_connections` (pool size): the maximum number of simultaneous connections to Redis.
Too small: requests queue waiting for a connection; latency increases; throughput drops.
Too large: Redis handles each connection with a TCP socket; at 10,000 connections, Redis
spends significant time context-switching; start with `max_connections = worker_threads * 2`.

`socket_timeout`: maximum time to wait for a Redis response. If Redis is slow (due to
a SLOWLOG event), the request waits up to `socket_timeout` seconds. Set to 100ms-500ms
to fail fast and let the application handle the error.

`socket_connect_timeout`: timeout for establishing the TCP connection. Set separately
from `socket_timeout` to allow faster detection of network failures.

```python
from redis import Redis, ConnectionPool

# Production connection pool configuration
pool = ConnectionPool(
    host="redis",
    port=6379,
    db=0,
    max_connections=50,      # 50 max connections
    socket_timeout=0.1,      # 100ms command timeout
    socket_connect_timeout=1.0,  # 1s connect timeout
    health_check_interval=30,    # 30s health check
    decode_responses=True,       # strings not bytes
    retry_on_error=[
        ConnectionError,
        TimeoutError
    ],
    retry=Retry(
        ExponentialBackoff(),
        retries=3
    )
)

r = Redis(connection_pool=pool)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a production-grade Redis connection pool configuration in Python with timeouts, health checks, and retry logic. (2) KEY MECHANISM: `max_connections=50` limits the pool; `socket_timeout=0.1` causes commands that take > 100ms to raise `TimeoutError`; `health_check_interval=30` sends a `PING` every 30 seconds on idle connections to detect stale connections before they are used; `retry_on_error` with exponential backoff retries transient errors without application-level retry code. (3) WHY IT MATTERS: without `max_connections`, each concurrent request creates a new Redis connection; under high concurrency, thousands of connections are created; Redis degrades; the pool enforces a hard ceiling. (4) WHAT BREAKS: setting `max_connections` too low causes `ConnectionError: max connections reached`; increase `max_connections` if this error appears frequently; balance with Redis's `maxclients` setting. (5) TAKEAWAY: `socket_timeout` is the most important connection pool setting after `max_connections`; a hanging Redis command (due to SLOWLOG event or network issue) blocks the thread/coroutine waiting for it; `socket_timeout` ensures the application fails fast and can retry or return a degraded response.

*What separates good from great:* The circuit breaker pattern for Redis. When Redis is
unavailable (failover, network partition), all connection pool borrows raise
`ConnectionError`. Without a circuit breaker, the application retries every request
against Redis, amplifying the load on Redis during recovery. With a circuit breaker
(e.g., pybreaker library), after N consecutive failures, the circuit opens and all
Redis operations immediately raise `CircuitBreakerError` without attempting Redis.
The application handles this by serving responses without cache (degraded mode). The
circuit breaker closes after a timeout, attempting Redis again. This pattern prevents
retry storms and allows Redis to recover without additional load.

---

**[SENIOR] Q7 (Mechanism): Explain Redis memory fragmentation in detail. What causes it and how does active defragmentation work?**

Memory fragmentation anatomy:
Redis uses jemalloc as its memory allocator. jemalloc manages memory in size classes.
When Redis allocates memory for a key-value pair, jemalloc rounds up to the nearest
size class. Example: a 33-byte string is allocated in the 40-byte size class (7 bytes
wasted per key). This internal fragmentation (within allocated blocks) is always present
but typically small (< 10%).

External fragmentation (the production concern):
1. Redis stores a 1 KB value.
2. Redis deletes the key. jemalloc marks the 1 KB block as free.
3. Redis stores a 2 KB value. jemalloc must allocate from a 2 KB size class (the
   free 1 KB block cannot be used for a 2 KB allocation).
4. The 1 KB free block remains in jemalloc's free list.
5. Repeat thousands of times: the jemalloc heap has many small free blocks that
   cannot be reused for larger allocations.
6. `used_memory` (logical) drops as keys are deleted.
7. `used_memory_rss` (OS-allocated) stays high (jemalloc does not return the free
   blocks to the OS).
8. `mem_fragmentation_ratio = rss / used = 1.8`.

Active defragmentation mechanism (Redis 4+):
Redis samples pages in the allocator and identifies pages with many free (unused)
blocks. For each such page, Redis moves the live data to a new allocation (in a less
fragmented page) and frees the old page. The old page can then be returned to the OS.
Configuration: `activedefrag yes`, `active-defrag-threshold-lower 10` (start when frag
ratio > 10% above 1.0 = 1.1), `active-defrag-threshold-upper 100` (aggressive when 100%
above = 2.0), `active-defrag-cycle-min 1` (min CPU % for defrag), `active-defrag-cycle-max 25`
(max CPU %).

*What separates good from great:* The defragmentation and eviction interaction. When
Redis is near `maxmemory` AND has high fragmentation, active defragmentation helps:
as defragmentation compacts live data, `used_memory` effectively decreases (the same
logical data occupies less physical memory); this provides headroom for new writes
without eviction. However, defragmentation takes time; if writes are arriving faster
than defragmentation can compact, the memory pressure remains. Monitor both
`active_defrag_running` (in `INFO stats`) and `used_memory` during a defragmentation
cycle to confirm the memory is actually decreasing.

---

**[STAFF] Q8 (Scenario): A Redis instance used for session storage starts showing `mem_fragmentation_ratio: 2.5`. The instance has been running for 6 months without a restart. How do you fix this without disrupting active sessions?**

Diagnosis confirmation:

```bash
redis-cli INFO memory | grep -E "frag|used_memory"
# used_memory:2147483648      -> 2 GB logical data
# used_memory_rss:5368709120  -> 5 GB OS allocated
# mem_fragmentation_ratio:2.5 -> 2.5x fragmentation
# active_defrag_running:0     -> defrag not enabled
```

> **Code walkthrough:** (1) WHAT IT SHOWS: confirming the fragmentation diagnosis - 2 GB of logical data occupying 5 GB of physical RAM (2.5x fragmentation); active defrag is not enabled. (2) KEY MECHANISM: `used_memory_rss = 5 GB` means the OS has allocated 5 GB for the Redis process; `used_memory = 2 GB` means only 2 GB is actual data; the 3 GB difference is fragmentation overhead from 6 months of key creation and deletion. (3) WHY IT MATTERS: a 5 GB RSS for 2 GB of actual data means 3 GB of RAM is wasted; on a server with 8 GB RAM, this limits the effective Redis capacity significantly. (4) WHAT BREAKS: `active_defrag_running:0` means defrag has never been enabled; simply enabling `activedefrag yes` starts the background defrag, which will reduce the fragmentation over hours. (5) TAKEAWAY: always enable `activedefrag yes` in production Redis from day one; preventing fragmentation accumulation is easier than compacting 3 GB of fragmentation after 6 months.

Step 1 - Enable active defragmentation (zero downtime):

```bash
redis-cli CONFIG SET activedefrag yes
redis-cli CONFIG SET active-defrag-threshold-lower 10
redis-cli CONFIG SET active-defrag-threshold-upper 100
redis-cli CONFIG SET active-defrag-cycle-min 5
redis-cli CONFIG SET active-defrag-cycle-max 25
redis-cli CONFIG REWRITE
# Defrag runs in background; monitor progress:
redis-cli --latency-history  # watch for latency impact
```

> **Code walkthrough:** (1) WHAT IT SHOWS: enabling active defragmentation at runtime and configuring it to be aggressive (5-25% CPU) for faster cleanup of 6 months of fragmentation. (2) KEY MECHANISM: `active-defrag-cycle-min 5` means defrag uses at least 5% CPU when the fragmentation ratio exceeds `active-defrag-threshold-lower`; `active-defrag-cycle-max 25` caps at 25% to avoid impacting Redis command throughput. (3) WHY IT MATTERS: this is a zero-downtime fix; existing sessions are not disrupted; defragmentation moves live data to compact pages without expiring or modifying the logical data. (4) WHAT BREAKS: defragmentation at 25% CPU reduces Redis command throughput by up to 25%; schedule the aggressive phase during off-peak hours by temporarily lowering `active-defrag-cycle-max` during peak traffic. (5) TAKEAWAY: `CONFIG REWRITE` persists the change to `redis.conf`; without this, the next Redis restart reverts to the default configuration (no active defrag).

Step 2 - Monitor defrag progress:

```bash
watch -n 5 "redis-cli INFO memory | grep -E 'frag|rss'"
# Monitor mem_fragmentation_ratio decreasing from 2.5
# Expect to return to 1.0-1.3 range within hours
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using `watch` to repeatedly run the Redis memory check every 5 seconds to monitor defragmentation progress. (2) KEY MECHANISM: `watch -n 5` runs the command every 5 seconds and shows the output with a timestamp; `mem_fragmentation_ratio` should decrease from 2.5 toward 1.0-1.3 as active defrag runs; `used_memory_rss` should also decrease as fragmented pages are returned to the OS. (3) WHY IT MATTERS: active defragmentation can take hours to complete for a 3 GB fragmentation backlog; monitoring confirms progress and detects if the defrag configuration is insufficient (no decrease after 30 minutes means `active-defrag-cycle-max` needs to be increased). (4) WHAT BREAKS: `watch` is not available on all systems; use a loop with `sleep 5` as an alternative. (5) TAKEAWAY: always monitor defragmentation progress after enabling `activedefrag`; if no improvement after 30 minutes, increase `active-defrag-cycle-max` temporarily.
Add `activedefrag yes` to `redis.conf` template.
Set a Prometheus alert when `mem_fragmentation_ratio > 1.5` to catch fragmentation
before it reaches 2.5.

*What separates good from great:* The defragmentation and persistence interaction. During
active defragmentation, Redis is moving live data between memory locations. If AOF
persistence is enabled, the AOF log records the logical operations (SET, DEL), not the
memory moves. Defragmentation does not generate AOF entries; it is invisible to
replication and persistence. However, defragmentation changes the physical layout of
data; during an RDB save triggered simultaneously with defragmentation, the forked child
sees the pre-defrag layout, while the parent is being defragmented. This is safe because
COW ensures both processes see a consistent view. No special handling is required; but
be aware that a simultaneous BGSAVE and active defrag will consume more memory
(COW pages during BGSAVE) and more CPU (defrag + BGSAVE compression).

---

**[STAFF] Q9 (Application): How do you safely rename or delete the `KEYS` command in a production Redis instance to prevent accidental misuse?**

The problem with `KEYS *`:
`KEYS *` is a blocking O(N) operation (N = number of keys). On a Redis instance with
10 million keys, `KEYS *` takes 100-500ms and blocks all other Redis commands during
that time. In production, `KEYS *` is almost never intentionally called; it is usually
a debugging artifact or a developer error.

Solution 1 - Rename KEYS to disabled:

```bash
# In redis.conf (CANNOT be done at runtime via CONFIG SET):
rename-command KEYS ""
# Empty string disables the command entirely
# redis-cli KEYS '*' -> ERR unknown command 'KEYS'

# Or rename to obscure name (accessible to ops, not apps):
rename-command KEYS "_ADMIN_KEYS_PRODUCTION"
# Only known to operations team; not in application code
```

> **Code walkthrough:** (1) WHAT IT SHOWS: disabling or renaming the `KEYS` command in `redis.conf` to prevent production misuse. (2) KEY MECHANISM: `rename-command KEYS ""` removes the KEYS command entirely; any application code that calls `KEYS` receives `ERR unknown command 'KEYS'` - a clear, actionable error vs a silent performance issue. (3) WHY IT MATTERS: the KEYS command should NEVER be called in production application code; an empty-string rename enforces this at the Redis level rather than relying on code reviews alone. (4) WHAT BREAKS: any monitoring, backup, or admin script that uses `KEYS` must be updated to use `SCAN`; audit all Redis usages before disabling. (5) TAKEAWAY: disable or rename `KEYS`, `DEBUG`, `CONFIG`, and `FLUSHALL`/`FLUSHDB` on production Redis instances; this prevents both accidental misuse by developers and malicious access.

Solution 2 - Replace KEYS with SCAN in application code:

```python
# BAD: KEYS blocks Redis
# def find_sessions(prefix: str):
#     return r.keys(f"{prefix}:*")

# GOOD: SCAN iterates without blocking
def find_sessions_safe(
    redis_client,
    prefix: str
) -> list:
    """Non-blocking key scan using SCAN cursor."""
    keys = []
    cursor = 0
    while True:
        cursor, batch = redis_client.scan(
            cursor=cursor,
            match=f"{prefix}:*",
            count=100  # 100 keys per iteration
        )
        keys.extend(batch)
        if cursor == 0:
            break
    return keys
```

> **Code walkthrough:** (1) WHAT IT SHOWS: replacing `KEYS` with the non-blocking `SCAN` iterator pattern; `SCAN` returns a cursor that must be iterated to completion. (2) KEY MECHANISM: `SCAN` processes 100 keys per call (the `count` hint); each call is O(1) and does not block; the full scan completes over many calls with a 0 cursor indicating the end; the total work is the same as `KEYS` but spread across many non-blocking operations. (3) WHY IT MATTERS: unlike `KEYS`, `SCAN` does not block Redis; other commands execute between SCAN iterations; the impact on other clients is negligible. (4) WHAT BREAKS: `SCAN` may return duplicate keys during the iteration (if the keyspace is modified during iteration); deduplicate results if uniqueness is required. (5) TAKEAWAY: any use of `KEYS` in production code should be replaced with `SCAN`; use `grep` to audit codebases for `r.keys(` or equivalent Redis client patterns.

*What separates good from great:* The Redis ACL (Access Control List) approach. Redis 6.0+
supports fine-grained ACL that allows restricting which commands specific users can call.
Instead of disabling KEYS globally, create two user roles: `app_user` (no KEYS, no
CONFIG, no DEBUG; can SET/GET/DEL and data commands only) and `admin_user` (full access
including KEYS, CONFIG, MONITOR). Application code uses `app_user`; operations team uses
`admin_user`. This provides defense in depth: even if an attacker compromises the
application Redis credentials, they cannot run destructive or diagnostic commands.

---

**[STAFF] Q10 (Trade-off): Redis Cluster vs Redis Sentinel - when would you choose each for a production deployment?**

Redis Sentinel:
- Architecture: 1 primary + N replicas + 3 Sentinel processes.
- Failover: Sentinels vote to promote a replica when the primary is unreachable
  (down-after-milliseconds; default 30 seconds).
- Data model: single shard (all data on one primary).
- Maximum dataset size: limited to one primary's RAM.
- Write throughput: limited to one primary's throughput.
- Client support: requires Sentinel-aware client; client queries Sentinels for current
  primary address.
- Failover time: 30-60 seconds (configurable, minimum ~5 seconds).

Redis Cluster:
- Architecture: multiple master shards (minimum 3 for quorum), each with 0-N replicas.
- Data: partitioned across shards using 16,384 hash slots.
- Dataset size: scales horizontally by adding shards.
- Write throughput: scales linearly with shard count.
- Client support: requires Cluster-aware client; client discovers topology and routes
  directly to the correct shard.
- Failover time: 10-30 seconds (per shard).
- Multi-key operations: only work if all keys are in the same hash slot.

Choose Sentinel when:
- Dataset fits in one primary's RAM (< 256 GB typically).
- The codebase uses multi-key operations (`MSET`, `MGET`, Lua scripts across keys)
  that are difficult to co-locate in a cluster.
- Team prefers operational simplicity; Sentinel is easier to configure and debug.
- Downtime tolerance: 30-60 second failover is acceptable.

Choose Cluster when:
- Dataset exceeds single-primary capacity (> 128 GB).
- Write throughput exceeds single-primary capacity (> 100K writes/second).
- Horizontal scalability is a requirement.
- Team has experience with distributed systems debugging.

*What separates good from great:* The Cluster multi-key constraint. Redis Cluster
requires all keys in a multi-key operation to be on the same hash slot. This constrains
application design: operations that span multiple entities (e.g., `MGET` for many
different user sessions) may fail with `CROSSSLOT Error`. The fix is to either use
hash tags to co-locate related keys (at the cost of creating hot slots) or to convert
multi-key operations to multiple single-key operations (at the cost of more round-trips).
For applications heavily reliant on multi-key operations, Sentinel (single shard) avoids
this constraint entirely. The decision should account for the application's multi-key
operation usage before choosing Cluster.

---

**[STAFF] Q11 (Mechanism): Explain Redis replication and the mechanisms that can cause replication lag or data loss.**

Redis replication architecture:
1. Initial sync: replica connects to primary; primary sends an RDB snapshot + buffered
   commands received during snapshot creation; replica loads RDB, then applies buffered
   commands.
2. Ongoing replication: primary streams all write commands to replicas asynchronously.
   Each write goes to the primary's memory first, then is propagated to replicas.

Replication lag sources:

Source 1 - Network bandwidth: if the primary receives 100 MB/s of write traffic,
the replication stream is 100 MB/s. If the network link to the replica is slower
than 100 MB/s, replication falls behind. Monitor with `INFO replication` ->
`slave_repl_offset` vs `master_repl_offset`.

Source 2 - Slow replica disk (during initial sync): initial sync writes the RDB file
to the replica's disk; if the disk is slow, the replica falls behind during the sync;
the primary's replication backlog (`repl-backlog-size`) must be large enough to buffer
the entire sync period.

Source 3 - Replica processing bottleneck: replicas apply write commands from the
primary in a single thread; if the replica is also serving read traffic, it may not
keep up with command application.

Data loss scenarios:

Scenario 1 - Async replication + failover: when the primary fails, any writes that
were in-flight (sent to primary but not yet replicated to any replica) are lost.
Risk: `min-replicas-to-write` and `min-replicas-max-lag` settings reduce this by
requiring N replicas to acknowledge writes before the primary acknowledges the client.

Scenario 2 - Network partition + split brain: during a network partition, both the
old primary and the new primary (promoted by Sentinel) accept writes. When the partition
heals, the old primary's writes are discarded. `min-replicas-to-write 1` prevents the
isolated primary from accepting writes (it cannot reach any replica).

*What separates good from great:* The `WAIT` command. For individual operations that
must be durable on at least one replica before acknowledging the client, use
`WAIT num_replicas timeout_ms`. `WAIT` blocks until N replicas have received all
preceding write commands (or timeout expires). This provides synchronous replication
for critical writes without configuring full synchronous replication for all writes.
Example: for a payment confirmation stored in Redis, issue `WAIT 1 1000` (wait for
1 replica within 1 second) after the write. If `WAIT` times out (replica not caught up),
the application can alert and potentially store the payment in PostgreSQL as a fallback.

---

**[STAFF] Q12 (Scenario): Design a Redis-backed rate limiting system for an API that handles 100,000 requests per second with per-user and per-IP limits. Walk through the implementation and failure modes.**

Requirements:
- 100K requests/second total.
- Per-user limit: 1,000 requests/minute.
- Per-IP limit: 100 requests/minute.
- Low latency overhead (< 1ms per request).
- Graceful degradation if Redis is unavailable.

Implementation using Redis atomic operations:

```python
import redis
import time

r = redis.Redis(host="redis", port=6379)

def check_rate_limit(
    user_id: str,
    ip: str,
    now: float = None
) -> tuple[bool, dict]:
    """
    Returns: (allowed: bool, info: dict)
    Uses fixed window counter pattern.
    """
    if now is None:
        now = time.time()
    minute_bucket = int(now / 60)

    user_key = f"rl:user:{user_id}:{minute_bucket}"
    ip_key   = f"rl:ip:{ip}:{minute_bucket}"

    # Atomic pipeline: INCR + EXPIRE in one round-trip
    pipe = r.pipeline()
    pipe.incr(user_key)
    pipe.expire(user_key, 120)  # TTL: 2 minutes
    pipe.incr(ip_key)
    pipe.expire(ip_key, 120)
    results = pipe.execute()

    user_count = results[0]
    ip_count   = results[2]

    allowed = user_count <= 1000 and ip_count <= 100
    return allowed, {
        "user_count": user_count,
        "ip_count":   ip_count,
        "user_limit": 1000,
        "ip_limit":   100
    }
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a Redis-based rate limiter using atomic pipeline (INCR + EXPIRE) to count requests per minute bucket without race conditions. (2) KEY MECHANISM: `minute_bucket = int(now / 60)` creates a key that changes every minute; `INCR` atomically increments the counter and returns the new value; `EXPIRE 120` ensures keys are cleaned up after 2 minutes; the pipeline groups INCR + EXPIRE into one Redis round-trip per key. (3) WHY IT MATTERS: the `INCR` is atomic; concurrent requests to the same user key all increment the same counter correctly without race conditions; at 100K requests/second, this pattern handles the load in Redis with < 0.5ms latency. (4) WHAT BREAKS: the fixed window has a "boundary burst" problem: 1,000 requests at 11:59:59 + 1,000 requests at 12:00:00 = 2,000 requests in 2 seconds (2x the intended rate); use a sliding window (Redis Sorted Set) for stricter enforcement at higher complexity. (5) TAKEAWAY: for most rate limiting use cases, the fixed window with minute buckets is sufficient; the boundary burst is a theoretical concern that rarely affects real users; use sliding windows only when the limit is safety-critical.

Failure mode handling:

```python
def check_rate_limit_safe(
    user_id: str,
    ip: str
) -> tuple[bool, dict]:
    """With Redis failure handling."""
    try:
        return check_rate_limit(user_id, ip)
    except redis.exceptions.ConnectionError:
        # Redis down: allow all requests (fail open)
        # or: deny all requests (fail closed)
        # Choice depends on business requirements
        # Fail open: prefer availability over rate limiting
        return True, {"degraded": True}
    except redis.exceptions.TimeoutError:
        # Redis slow: fail open to avoid blocking
        return True, {"degraded": True}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: graceful degradation when Redis is unavailable by catching connection and timeout errors and returning `True` (allow request) with a degraded flag. (2) KEY MECHANISM: "fail open" means when the rate limiter cannot function, requests are allowed through; this prioritizes availability over rate limit enforcement; "fail closed" (return `False`) prioritizes security. (3) WHY IT MATTERS: a rate limiter that blocks all traffic when Redis is unavailable turns a Redis outage into a full API outage; fail-open rate limiters are appropriate for performance rate limits; fail-closed is appropriate for security-critical limits. (4) WHAT BREAKS: fail-open creates a window during Redis outages where unlimited traffic is allowed; if an abuse event coincides with a Redis outage, the rate limiter provides no protection. (5) TAKEAWAY: document the fail-open vs fail-closed choice in the application design; security teams need to know; both are valid choices depending on the threat model and availability requirements.

*What separates good from great:* The sliding window with sorted sets. For stricter rate
limiting (no boundary burst), use a Redis Sorted Set per user: member = request ID (UUID),
score = timestamp. To check rate: `ZREMRANGEBYSCORE (now - 60) now` (remove old requests),
`ZCARD` (count remaining), `ZADD now request_id` (add current request), `EXPIRE 120`.
The sorted set contains all requests in the last 60 seconds; `ZCARD` is the exact count.
The cost: each request requires 4 Redis operations instead of 2; the sorted set is
larger (O(N) memory for N requests in the window vs O(1) for the counter). For 1,000
requests/minute per user, the sorted set holds 1,000 members = ~100 KB per active user.
At 100K concurrent users, this is 10 GB of sorted set data; the counter approach uses
200 bytes per user (counter + IP counter). Use counters for high-scale rate limiting;
use sorted sets only when boundary burst prevention is a hard requirement.
