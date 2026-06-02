---
layout: default
title: "NoSQL - L4 Cassandra Production"
parent: "NoSQL"
nav_order: 12
permalink: /nosql/l4-cassandra-production/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Cassandra Production Tuning and Tombstone Management](#cassandra-production-tuning-and-tombstone-management) | ★★★ |

---

# Cassandra Production Tuning and Tombstone Management

---

### 🎯 Model Answer

**30 seconds:**
> Cassandra production failures center on tombstones. A tombstone is a deletion marker
> in Cassandra's LSM-tree storage. Tombstones accumulate when data is deleted or TTL-
> expired; during reads, Cassandra must scan past tombstones to find live data. When a
> single read encounters more tombstones than `tombstone_warn_threshold` (1,000 default),
> Cassandra logs a warning; beyond `tombstone_failure_threshold` (100,000), the read
> fails with `TombstoneOverwhelmingException`. In production this manifests as sudden
> read failures for specific partition keys.

**3 minutes (Senior):**
> Cassandra production configuration across four critical areas: (1) Compaction - the
> background process that merges SSTables and removes tombstones. STCS (SizeTieredCompaction)
> has low write amplification but high space amplification (2x disk during compaction);
> TWCS (TimeWindowCompactionStrategy) for time-series data is far more efficient; LEVELED
> (LCS) has high write amplification but predictable read performance. (2) Tombstone
> management - each DELETE, TTL expiry, and null value INSERT creates a tombstone; tombstones
> are garbage-collected only after `gc_grace_seconds` (default: 864000 = 10 days). (3) Repair
> - `nodetool repair` synchronizes SSTables across replicas; must run within `gc_grace_seconds`
> to prevent zombie data resurrection (deleted data re-appearing when a repaired node misses
> a tombstone). (4) JVM tuning - Cassandra runs on the JVM; default G1GC settings cause
> GC pauses; production tuning: disable `ByteOrderedPartitioner`, use G1GC with
> `-XX:G1RSetUpdatingPauseTimePercent=5`, set heap to 50% of RAM (max 8-16 GB; rest for
> page cache).

**Framework:** Data Model -> Compaction Strategy -> Tombstone Budget -> Repair Schedule

**Blank Mind Recovery:**

**(1) Restate:** "Cassandra production: tombstones = deletion markers. Too many tombstones
in a partition causes read failure (TombstoneOverwhelmingException). Fix: avoid wide
partition deletes; use TTL carefully; choose TWCS for time-series; run repair before
gc_grace_seconds expires."

**(2) First principles:** "Cassandra uses LSM trees (no in-place updates). A DELETE
doesn't remove data - it inserts a tombstone marker. The marker hides the original data
during reads. Compaction eventually removes tombstones + the original data together. But
until compaction runs, both tombstone and original data consume disk. During reads,
Cassandra scans all versions including tombstones to find the latest non-tombstoned value."

**(3) Bridge:** "Tombstones in Cassandra are like sticky notes on filing cabinet drawers
saying 'this document is deleted.' When you search the cabinet, you must read every sticky
note to know what to skip. If 100,000 drawers have 'deleted' notes, finding the 1 live
document takes reading all 100,000 notes first - that's the TombstoneOverwhelmingException."

---

### 📘 Concept Explanation

**Cassandra Tombstone Internals:**

```text
CASSANDRA TOMBSTONE LIFECYCLE:

  Time 0:  INSERT INTO sessions (id, data) VALUES (1, 'x')
           -> SSTable 1: [{id:1, data:'x', ts:100}]

  Time 1:  DELETE FROM sessions WHERE id = 1
           -> SSTable 2: [{id:1, TOMBSTONE, ts:200}]
           -> Both SSTables exist on disk

  Time 2:  SELECT * FROM sessions WHERE id = 1
           -> Read SSTable 1 + SSTable 2
           -> Tombstone (ts:200) > data (ts:100)
           -> Return empty result (tombstone wins)
           -> BUT: Cassandra scanned BOTH SSTables

  Time 3:  Compaction merges SSTable 1 + 2:
           -> IF ts_now > tombstone_ts + gc_grace_seconds:
              -> Tombstone + original data REMOVED
           -> ELSE: tombstone kept in merged SSTable

  TOMBSTONE SOURCES:
  1. DELETE ... WHERE pk = x       <- explicit delete
  2. INSERT ... WITH TTL = N       <- TTL expiry
  3. INSERT null value             <- cell tombstone
  4. DELETE from list/map element  <- collection tombstone
  5. UPDATE to null                <- cell tombstone

  ACCUMULATION RISK:
  Wide partition (pk with many rows) + bulk delete
  = many tombstones in ONE partition key
  = single read must scan ALL of them
  = TombstoneOverwhelmingException at 100,000
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Cassandra tombstone lifecycle from
> insertion through compaction, showing why tombstones accumulate and when they are
> actually removed. (2) HOW TO READ IT: follow the timeline from Time 0 to Time 3;
> at Time 2 the SELECT must read both SSTables to determine that the tombstone wins;
> at Time 3 compaction only removes the tombstone if `gc_grace_seconds` has elapsed.
> (3) KEY RELATIONSHIP: tombstones are never removed immediately; they must survive
> `gc_grace_seconds` (default 10 days) to ensure all replicas have seen the deletion
> before the tombstone is garbage-collected. (4) EDGE CASE: if a node is offline during
> the delete and comes back online after `gc_grace_seconds`, it will serve the original
> deleted data as if it were live - this is zombie data resurrection; prevent with
> regular `nodetool repair`. (5) INSIGHT: a senior engineer understands that tombstones
> are a data model problem first; data models that generate bulk deletes (deleting rows
> by timestamp in a time-series partition) accumulate tombstones faster than compaction
> can clean them; TWCS solves this by ensuring tombstones and their data are always
> in the same time-window compaction group.

**Cassandra Compaction Strategy Comparison:**

```text
COMPACTION STRATEGY DECISION:

  STCS (SizeTieredCompactionStrategy):
  DEFAULT - merges SSTables of similar size
  Write amplification: LOW (1-2x)
  Space amplification: HIGH (2x during compaction)
  Read amplification: HIGH (many SSTables to check)
  Best for: write-heavy, random access
  Worst for: time-series with deletes (tombstones
             accumulate across all size tiers)

  LCS (LeveledCompactionStrategy):
  SSTables organized in levels (L0=10MB, L1=100MB...)
  Write amplification: HIGH (10-15x)
  Space amplification: LOW (10% overhead)
  Read amplification: LOW (guaranteed <= 1 SSTable
                          per partition at L1+)
  Best for: read-heavy, mixed read/write
  Worst for: write-heavy (disk I/O from compaction)

  TWCS (TimeWindowCompactionStrategy):
  Groups SSTables by time window (e.g., 1-hour windows)
  Write amplification: VERY LOW
  Space amplification: VERY LOW
  Tombstone handling: EXCELLENT (expired window
                      compacted and deleted together)
  Best for: time-series data with TTL (IoT, metrics)
  CRITICAL REQUIREMENT: insert order = time order
  (TWCS breaks with out-of-order writes > 1 window)

  DTCS (DateTieredCompactionStrategy):
  DEPRECATED - use TWCS instead
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the three main Cassandra compaction
> strategies with their write/read/space amplification trade-offs and use case recommendations.
> (2) HOW TO READ IT: each strategy block shows the amplification metrics and the ideal
> use case; the three-way trade-off is that reducing one amplification type increases another.
> (3) KEY RELATIONSHIP: tombstone handling is where the strategies diverge most significantly
> - TWCS's time-window grouping means an entire expired time window can be dropped at once
> without reading individual tombstones; STCS scatters tombstones across size tiers making
> them hard to compact away. (4) EDGE CASE: TWCS with out-of-order writes is dangerous;
> if writes for "yesterday's" time window arrive today, TWCS places them in the current
> window; the "yesterday" window compaction runs without them; zombie data appears after
> compaction removes what it thinks are all records in the window. (5) INSIGHT: a senior
> engineer chooses compaction strategy during data model design, not after a production
> incident; changing compaction strategy on a live table requires full table rewrite and
> is disruptive.

---

### 💻 Code Example

```java
// BAD: Data model that generates excessive tombstones
// (anti-pattern: deleting rows in a wide partition)

// Schema with STCS (default) and bulk deletes
// CREATE TABLE events (
//   user_id UUID,
//   event_time TIMESTAMP,
//   data TEXT,
//   PRIMARY KEY (user_id, event_time)
// );

// Application: delete events older than 30 days
public void deleteOldEvents(
    CqlSession session,
    UUID userId,
    Instant cutoff
) {
    // BAD: SELECT all old events, then DELETE each
    // Creates N tombstones for N deleted rows
    // Wide partition: user with 10M events = 10M tombstones
    ResultSet results = session.execute(
        "SELECT event_time FROM events "
        + "WHERE user_id = ? AND event_time < ?",
        userId, cutoff
    );
    for (Row row : results) {
        session.execute(
            "DELETE FROM events WHERE user_id = ? "
            + "AND event_time = ?",
            userId, row.getInstant("event_time")
        );
    }
    // After 30 days: partition has 10M tombstones + 10M live rows
    // Read any recent event requires scanning 10M tombstones first
    // TombstoneOverwhelmingException when tombstones > 100,000
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the tombstone accumulation anti-pattern -
> iterating over old rows and deleting them individually, creating one tombstone per
> deleted row in a potentially wide partition. (2) KEY MECHANISM: each `DELETE FROM
> events WHERE user_id = ? AND event_time = ?` creates an individual cell tombstone in
> the partition; after 30 days of this deletion pattern, a partition with 300K rows
> per day accumulates 9 million tombstones per user; the next read for that user must
> scan all tombstones. (3) WHY IT MATTERS: a single read hitting 100,001 tombstones
> throws `TombstoneOverwhelmingException`; the read fails; the application receives an
> error; users cannot access their data. (4) WHAT BREAKS: the partition-level delete
> `DELETE FROM events WHERE user_id = ?` (without `event_time` predicate) deletes the
> entire partition in one operation; but this still creates one partition tombstone that
> takes `gc_grace_seconds` to be removed; during that window, reads for the user hit the
> tombstone before finding live data from subsequent inserts. (5) TAKEAWAY: never design
> a Cassandra table that requires bulk deletes from a wide partition; use TTL at insert
> time instead; let Cassandra's TTL expiry mechanism manage the lifecycle.

```java
// GOOD: Use TTL at insert time instead of explicit deletes
// and TWCS for time-series compaction

// Schema with TWCS and TTL (no explicit deletes needed)
// CREATE TABLE events (
//   user_id UUID,
//   event_time TIMESTAMP,
//   data TEXT,
//   PRIMARY KEY (user_id, event_time)
// ) WITH compaction = {
//     'class': 'TimeWindowCompactionStrategy',
//     'compaction_window_unit': 'HOURS',
//     'compaction_window_size': 1
//   }
//   AND default_time_to_live = 2592000; -- 30 days in seconds

public void insertEvent(
    CqlSession session,
    UUID userId,
    Instant eventTime,
    String data
) {
    // TTL set at insert time: row auto-expires after 30 days
    // No explicit DELETE needed; no tombstone accumulation
    session.execute(
        SimpleStatement.newInstance(
            "INSERT INTO events (user_id, event_time, data) "
            + "VALUES (?, ?, ?) USING TTL ?",
            userId, eventTime, data, 2_592_000 // 30 days
        )
    );
    // TWCS groups rows by hour window
    // When 30-day TTL expires, entire hour windows drop at once
    // No tombstone scanning during reads within active window
}

// Monitor tombstone counts before they become a problem
public void checkTombstones(CqlSession session) {
    // Use nodetool cfstats to check SSTable tombstone ratios
    // Run: nodetool cfstats keyspace.events
    // Look for: "SSTable Tombstones" vs "SSTable Columns"
    // Alert if tombstone ratio > 10%

    // Per-query: track TombstoneWarnings in driver metrics
    session.execute(
        SimpleStatement.newInstance(
            "SELECT * FROM events WHERE user_id = ?",
            UUID.randomUUID()
        ).setTracing(true)  // Enable request tracing
    );
    // Check trace for tombstone warning in Cassandra system logs
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the correct Cassandra time-series pattern:
> use TTL at insert time instead of explicit deletes; use TWCS for compaction; no
> tombstone accumulation at scale. (2) KEY MECHANISM: `USING TTL 2592000` marks the
> inserted row to automatically expire after 30 days; Cassandra creates a TTL tombstone
> only when the row actually expires; TWCS groups expired rows into the same time-window
> SSTable which can be dropped as a unit; no per-row tombstone scanning. (3) WHY IT
> MATTERS: this data model has zero tombstone accumulation during normal operation;
> reads within the active time window never encounter expired tombstones. (4) WHAT
> BREAKS: TWCS requires writes to arrive in time order; if data arrives > 1 window late
> (e.g., 2-hour-late IoT data with a 1-hour window), TWCS places it in the wrong window
> and compaction becomes incorrect; use a wider window (24 hours) to accommodate late
> data. (5) TAKEAWAY: every Cassandra time-series table should use TWCS + TTL; the
> combination eliminates the most common production Cassandra failure (tombstone
> accumulation); design for it at table creation time.

```bash
# Production Cassandra diagnosis: tombstone and compaction analysis

# 1. Check for tombstone warnings in system logs
grep "Tombstone" /var/log/cassandra/system.log | tail -20
# "WARN  [ReadStage-2] TombstoneOverwhelmingException:
#  106434 tombstones queried in ks.table for key=USER123"

# 2. Check SSTable statistics for tombstone ratio
nodetool cfstats keyspace.events | grep -A5 "SSTable"
# SSTable count: 45
# SSTable Tombstones: 3,245,000
# SSTable Columns: 1,200,000
# -> More tombstones than live data! Problem confirmed.

# 3. Force compaction to remove tombstones
# (only after verifying gc_grace_seconds has elapsed
#  and repair has been run on all nodes)
nodetool compact keyspace events

# 4. Check compaction status while running
nodetool compactionstats
# pending tasks: 23
# id       type          keyspace table  completed total  unit
# ... shows active compaction progress

# 5. Increase tombstone warning threshold temporarily
# while fixing the data model (emergency measure)
# ALTER TABLE keyspace.events WITH gc_grace_seconds = 43200;
# (reduce gc_grace = 12 hours instead of 10 days)
# DANGER: ONLY if repair runs more frequently than gc_grace
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the production diagnosis workflow for Cassandra tombstone problems - from identifying the symptom in logs, to measuring the tombstone ratio, to forcing compaction to clean up. (2) KEY MECHANISM: `nodetool cfstats` shows SSTable-level statistics including tombstone counts; when tombstones exceed live columns, compaction is falling behind tombstone accumulation; `nodetool compact` forces an immediate compaction; note: this is CPU and I/O intensive. (3) WHY IT MATTERS: `TombstoneOverwhelmingException` causes read failures for specific users (those whose partition keys have excessive tombstones); the impact is asymmetric - only affected users receive errors; other users are unaffected. (4) WHAT BREAKS: forcing compaction on a large table during peak traffic causes high I/O and CPU load; schedule `nodetool compact` during maintenance windows; use `nodetool setcompactionthroughput` to throttle compaction I/O. (5) TAKEAWAY: add tombstone monitoring to the Cassandra operations dashboard; alert when tombstone ratio > 10% for any table; this provides lead time to fix the data model before read failures occur.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Cassandra tombstones are deletion markers. When data is deleted or TTL-expired,
> Cassandra inserts a tombstone instead of removing the data immediately. Tombstones
> are cleaned up during compaction after `gc_grace_seconds` (10 days by default).
> Production problem: if a partition accumulates more than 100,000 tombstones, reads
> fail with `TombstoneOverwhelmingException`. Prevention: use TTL at insert time instead
> of explicit deletes; use TWCS for time-series data.

---

**Senior / Staff (5+ years):**
> Four production Cassandra failure modes and root causes: (1) Tombstone
> overflow - bulk deletes or TTL expiry in wide partitions; root cause is data model;
> fix with TWCS + TTL-at-insert. (2) Zombie data resurrection - a node missed a delete
> (was offline during `gc_grace_seconds`); tombstone expired before the node came back;
> deleted data re-appears; prevention: `nodetool repair` before `gc_grace_seconds` expires.
> (3) Compaction falling behind - write rate exceeds compaction throughput; SSTables
> accumulate; reads slow (more SSTables to check); fix: increase compaction throughput
> (`nodetool setcompactionthroughput 128`); switch to LCS for read-heavy tables. (4) GC
> pauses - large Cassandra heap triggers GC pauses causing cluster-wide timeout storms;
> fix: limit JVM heap to 8-16 GB; rely on page cache for larger datasets; use G1GC with
> production-tuned flags; set `cassandra.yaml`: `max_heap_size: 8G`, `heap_newsize: 2G`.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Setting gc_grace_seconds to 0 removes tombstones immediately."**

Setting `gc_grace_seconds = 0` causes tombstones to be eligible for garbage collection
immediately after compaction runs. This removes the tombstone quickly but creates a
severe risk: if any replica was offline during the delete (even briefly due to a
maintenance restart), that node still has the original data. When the node comes back
online, it serves the "deleted" data because there is no tombstone anymore (it was
garbage-collected). The resurrected data appears as if the delete never happened.
`gc_grace_seconds` exists specifically to allow all replicas to receive the deletion
tombstone before it is removed. Setting it to 0 should only be done when: (1) all
replicas are guaranteed to be online continuously during the `gc_grace_seconds` window,
(2) `nodetool repair` has been run on all nodes, and (3) the data loss from zombie
resurrection is acceptable. For most production use cases, leave `gc_grace_seconds` at
864000 (10 days) and run repair at least weekly.

**Misconception 2: "nodetool compact immediately removes tombstones."**

`nodetool compact` triggers a major compaction that merges all SSTables for a table.
However, tombstones are only removed during compaction if `gc_grace_seconds` has elapsed
since the tombstone was created. If `gc_grace_seconds` is 10 days and the delete
happened 2 days ago, `nodetool compact` does NOT remove the tombstone - it merges the
SSTables but preserves the tombstone because it is still within the grace period.
To verify when tombstones will be eligible for removal:
`nodetool getendpoints keyspace table partition_key` and check the tombstone timestamp
against the `gc_grace_seconds` configuration. For emergency tombstone cleanup when
read failures are occurring, the only options are: (1) reduce `gc_grace_seconds` (risky),
(2) increase `tombstone_failure_threshold` as a temporary measure while fixing the data
model, (3) accept read failures for the affected partition and drop + recreate the data.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: TombstoneOverwhelmingException causing read failures.**

Symptom: intermittent read failures for specific users/entities; `ERROR` in Cassandra
logs: `TombstoneOverwhelmingException: X tombstones queried in keyspace.table for key=Y`.
The failure affects only partitions with high tombstone counts; other partitions work
normally.

Diagnosis:

```bash
# 1. Find affected partitions in Cassandra logs
grep "TombstoneOverwhelm" /var/log/cassandra/system.log \
  | awk '{print $NF}' | sort | uniq -c | sort -rn | head -10
# Shows: count of failures per partition key
# "1523 key=user:abc123" -> most affected user

# 2. Count tombstones in specific partition using sstableutil
nodetool flush keyspace events
sstableutil -t keyspace events
# Lists SSTable files; use sstabledump on each to count tombstones

# 3. Check overall tombstone ratio
nodetool cfstats keyspace.events | \
  grep -E "Tombstones|Columns|SSTables"

# 4. Check compaction lag
nodetool compactionstats
# If "pending tasks" is high (> 100), compaction is falling behind
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the full diagnostic workflow for TombstoneOverwhelmingException - identifying affected partitions, quantifying the tombstone count, and checking compaction status. (2) KEY MECHANISM: the grep + awk command extracts the partition key from the log message and counts occurrences; high counts for specific keys confirm that a few "hot delete" partitions are causing the failures; `nodetool cfstats` provides aggregate tombstone statistics at the table level. (3) WHY IT MATTERS: the affected partitions need immediate mitigation (increase `tombstone_failure_threshold` as an emergency measure, then fix the data model); unaffected partitions can continue normally. (4) WHAT BREAKS: `sstableutil` and `sstabledump` require root access and are not available on all Cassandra installations; use `nodetool cfstats` as the primary tool; it is always available. (5) TAKEAWAY: add a Cassandra metric alert for `ClientRequest/Read/TombstoneScanned` in JMX or Prometheus metrics; alert when tombstones scanned per read exceeds 1,000 (the warning threshold); this provides advance warning days before the 100,000 failure threshold is reached.

Fix (emergency - increase thresholds while fixing data model):

```bash
# Increase failure threshold to prevent read failures while
# fixing the data model (emergency measure only)
# In cassandra.yaml:
# tombstone_warn_threshold: 1000     (default)
# tombstone_failure_threshold: 100000 (default)

# Temporary increase to allow reads to proceed:
# tombstone_failure_threshold: 500000
# Requires Cassandra restart; not a permanent solution

# Long-term fix: ALTER TABLE to add TWCS + TTL
# ALTER TABLE keyspace.events
# WITH default_time_to_live = 2592000
# AND compaction = {'class': 'TimeWindowCompactionStrategy',
#   'compaction_window_unit': 'HOURS',
#   'compaction_window_size': 1};

# After ALTER TABLE: data in old SSTables still has old schema
# Full repair needed to trigger compaction with new settings:
nodetool repair keyspace events
nodetool compact keyspace events
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the emergency mitigation (raising the tombstone failure threshold) and the long-term fix (ALTER TABLE to TWCS + TTL followed by repair and compaction). (2) KEY MECHANISM: raising `tombstone_failure_threshold` to 500,000 prevents read failures while the data model is fixed; this is not a solution - reads still scan 500,000 tombstones and are very slow; the long-term fix changes the compaction strategy so tombstones are cleared efficiently. (3) WHY IT MATTERS: the ALTER TABLE + nodetool compact is the canonical fix; but it requires a repair first to ensure all nodes are synchronized before compaction changes the SSTable layout. (4) WHAT BREAKS: ALTER TABLE on a large live table can fail if the Cassandra cluster is under heavy load; the schema change requires consensus across all nodes; execute during maintenance windows. (5) TAKEAWAY: the correct fix is always the data model (TWCS + TTL); threshold increases and compaction triggers are emergency measures only; add the data model review to the post-incident review for the team.

---

### ⚖️ Comparison Table

| Compaction Strategy | Write Amp | Read Amp | Space Amp | Best For | Worst For |
|---|---|---|---|---|---|
| STCS (default) | Low | High | High | Write-heavy | Time-series with deletes |
| LCS | High | Low | Low | Read-heavy | Write-heavy |
| TWCS | Very Low | Low (in window) | Very Low | Time-series + TTL | Out-of-order writes |

---

### 🏛️ System Design

**Multi-Datacenter Cassandra for High Availability:**

Architecture: 3-datacenter deployment (2 active DCs + 1 DR DC).
- DC1 (us-east-1): 6 nodes (RF=3).
- DC2 (eu-west-1): 6 nodes (RF=3).
- DC3 (ap-southeast-1): 3 nodes (RF=3, DR only).

Keyspace replication:

```sql
CREATE KEYSPACE events_ks
WITH replication = {
  'class': 'NetworkTopologyStrategy',
  'us-east-1': '3',
  'eu-west-1': '3',
  'ap-southeast-1': '3'
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the `NetworkTopologyStrategy` keyspace configuration for a 3-datacenter Cassandra deployment with RF=3 per datacenter. (2) KEY MECHANISM: `NetworkTopologyStrategy` distributes replicas across racks within each datacenter; RF=3 means 3 copies of each partition in each DC; reads and writes route to the nearest DC first. (3) WHY IT MATTERS: 3 replicas per DC means any single node failure is transparent; with QUORUM consistency, reads and writes require 2 out of 3 nodes per DC; the cluster tolerates a single node failure without any degradation. (4) WHAT BREAKS: if `us-east-1` loses 2 of 3 nodes, QUORUM consistency fails; the application must fall back to LOCAL_ONE or accept failures; design the application error handling to handle Cassandra NoHostAvailableException. (5) TAKEAWAY: always use `NetworkTopologyStrategy` for production; `SimpleStrategy` does not respect rack placement and is only for single-datacenter development; add rack awareness configuration to ensure replicas are placed on different physical racks.

Read/write consistency levels:
- Writes: `LOCAL_QUORUM` (writes acknowledged when 2/3 nodes in local DC confirm).
- Reads: `LOCAL_QUORUM` (read from 2/3 nodes in local DC for consistency).
- DR reads: `LOCAL_ONE` (read from 1 node in DR DC; eventual consistency acceptable).

Repair schedule: run `nodetool repair` weekly on each node (within `gc_grace_seconds`
10-day window). Use Reaper (https://cassandra-reaper.io) for automated incremental repair.

---

### 📊 Diagram

```text
CASSANDRA TOMBSTONE ACCUMULATION VS TWCS:

  STCS (default) - Wide partition deletes:
  Partition: user:abc123
  SSTable1: [row1][row2]...[row10M]  <- 10M rows
  SSTable2: [tomb][tomb]...[tomb]    <- 10M tombstones
  SSTable3: [tomb][tomb]...[tomb]    <- more tombstones
  Read user:abc123:
  -> Must scan ALL SSTables
  -> 10M tombstones encountered
  -> TombstoneOverwhelmingException at 100,000!

  TWCS + TTL - Time-window compaction:
  Window 1 (Hour 1): [row1][row2]...[rowN] + TTL=30d
  Window 2 (Hour 2): [row1][row2]...[rowN] + TTL=30d
  ...
  Window 720 (Hour 720 = 30 days later):
  Window 1 all TTLs expired -> ENTIRE SSTable DROPPED
  No tombstone scanning required
  Read any partition: touches only active windows

  REPAIR CADENCE:
  [Node A] [Node B] [Node C]   RF=3
    |         |         |
    +--sync---+--sync---+  <- weekly repair
    |                   |
    gc_grace=10d window:
    ALL nodes must receive DELETE within 10 days
    Run repair weekly < 10 days
    -> prevents zombie data resurrection
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: a comparison of tombstone accumulation
> under STCS (default, problematic) vs TWCS (correct for time-series), and the repair
> cadence requirement for safe tombstone garbage collection. (2) HOW TO READ IT: the top
> section shows STCS with multiple SSTables all containing tombstones for the same wide
> partition; the middle shows TWCS where each window's SSTable expires as a unit; the
> bottom shows the repair requirement for all nodes to synchronize within `gc_grace_seconds`.
> (3) KEY RELATIONSHIP: the STCS tombstone accumulation and the TombstoneOverwhelmingException
> are directly linked; TWCS eliminates the problem at the compaction level rather than
> requiring application-level workarounds. (4) EDGE CASE: TWCS with out-of-order writes
> (more than one window late) causes the "wrong window" problem; data inserted into
> the "Hour 1" window after Hour 1's SSTable has been compacted and dropped leads to
> data appearing in reads and then disappearing after the next compaction. (5) INSIGHT:
> a senior engineer reads the compaction strategy implications before finalizing the data
> model; changing from STCS to TWCS after a production incident requires full table
> rewrite + repair + compaction; it is a 2-4 hour operation on a large cluster.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | tombstone mechanics, compaction strategies |
| Mechanism | 2 | gc_grace_seconds, repair cycle |
| Debugging | 3 | tombstone diagnosis, compaction lag, GC pauses |
| Trade-off | 2 | STCS vs TWCS vs LCS, consistency vs availability |
| Application | 2 | multi-DC design, repair scheduling |
| Scenario | 1 | production tombstone incident |

---

**[SENIOR] Q1 (Definition): What is a Cassandra tombstone and why does it exist?**

A tombstone is a special record in Cassandra that marks data as deleted. Unlike
relational databases that physically remove rows on DELETE, Cassandra cannot modify
SSTables in place (they are immutable). Instead, a DELETE inserts a tombstone record
with a timestamp into the current memtable; the tombstone is eventually flushed to an
SSTable and merged with the original data during compaction.

Tombstones exist because of Cassandra's replication model. In a distributed system,
a replica node may be temporarily unavailable during a delete. If the delete were
physically applied immediately, the unavailable replica would still have the original
data. When it came back online, it would serve stale data. By retaining the tombstone
for `gc_grace_seconds` (default: 10 days), Cassandra ensures the tombstone outlasts
any normal node downtime; when the node reconnects, repair propagates the tombstone,
and the original data on that node is properly hidden.

Types of tombstones:
(1) Partition tombstone: DELETE FROM table WHERE pk = x (marks entire partition deleted).
(2) Row tombstone: DELETE FROM table WHERE pk = x AND ck = y (marks single row deleted).
(3) Cell tombstone: UPDATE table SET col = null WHERE ... (marks single cell deleted).
(4) Range tombstone: DELETE FROM table WHERE pk = x AND ck > y (marks a range deleted).
(5) TTL tombstone: automatically created when a row's TTL expires.

Each tombstone type has different performance implications; partition tombstones are
resolved quickly; individual cell tombstones in wide partitions accumulate the most.

*What separates good from great:* The `gc_grace_seconds` and consistency level
interaction. `gc_grace_seconds` is set per table, not globally. For tables that are
never deleted from (insert-only, like append-only event logs), setting
`gc_grace_seconds = 0` is safe and allows tombstones from TTL expiry to be cleaned up
immediately. The reasoning: if no explicit deletes occur, there are no tombstones that
need to be propagated to offline replicas. Only TTL tombstones exist, and they are
generated locally by each node when the TTL expires; no cross-node propagation is needed.

---

**[SENIOR] Q2 (Mechanism): Explain how `gc_grace_seconds` and `nodetool repair` interact. What happens if repair does not run within the grace period?**

`gc_grace_seconds` is the tombstone garbage collection grace period. Tombstones in
Cassandra are eligible for removal by compaction only after `gc_grace_seconds` has
elapsed since the tombstone was written. The default is 864,000 seconds (10 days).

The purpose of the grace period:
When data is deleted, the tombstone is written to the primary replica and replicated
to all other replicas synchronously (during the write). However, if a replica is
offline, it misses the tombstone. The grace period provides a 10-day window for:
(1) The offline node to come back online.
(2) `nodetool repair` to synchronize the tombstone to the recovered node.
(3) Compaction to run on all nodes, marking the original data as superseded.

If repair does NOT run within `gc_grace_seconds`:
1. Tombstone is removed by compaction after the grace period expires.
2. The original data on the offline node is no longer hidden by the tombstone.
3. When the node comes back online, it still has the original (deleted) data.
4. Reads that route to this node see the data as live (zombie resurrection).
5. The data appears to "come back from the dead" - a correctness violation.

Prevention: run `nodetool repair` on all nodes at least once within `gc_grace_seconds`.
For a 10-day grace period, weekly repair is the standard practice. Tools: Apache
Cassandra's `nodetool repair` (full repair, expensive), Reaper (incremental repair,
production-recommended).

*What separates good from great:* The asymmetry in consequences. Zombie data resurrection
(a deleted user's data reappearing) is often worse than a read failure. Read failures
cause visible errors that are immediately reported and investigated. Zombie data
silently serves incorrect data; it may not be detected for weeks or months. Financial
applications, HIPAA-regulated data, and GDPR-subject data have regulatory consequences
for zombie data. Production Cassandra operations require a strictly enforced repair
schedule; the repair schedule is as important as backups.

---

**[SENIOR] Q3 (Debugging): How do you diagnose Cassandra performance degradation due to compaction lag?**

Compaction lag occurs when the rate of SSTable creation (from memtable flushes) exceeds
the rate of SSTable compaction (merging). This results in a large number of SSTables
per partition, causing reads to scan multiple SSTables for each query.

Diagnosis:

```bash
# 1. Check number of SSTables per table
nodetool cfstats keyspace.table | grep "SSTable count"
# SSTable count: 245  <- should be < 20 for STCS
# High SSTable count = compaction lagging

# 2. Check pending compaction tasks
nodetool compactionstats
# pending tasks: 523  <- large backlog
# compactions completed: 12
# bytes compacted: 14,567,012

# 3. Check compaction throughput setting
nodetool getcompactionthroughput
# Current compaction throughput: 16 MB/s  <- default, often too low

# 4. Increase compaction throughput
nodetool setcompactionthroughput 128
# Now compaction can consume up to 128 MB/s disk I/O

# 5. Monitor SSTable count after adjustment
watch -n 30 "nodetool cfstats ks.events | grep 'SSTable count'"
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the full compaction lag diagnosis workflow - checking SSTable count, pending tasks, current throughput, and applying a fix. (2) KEY MECHANISM: `nodetool cfstats` shows per-table SSTable counts; high counts (> 50 for STCS) confirm compaction lag; `nodetool compactionstats` shows the backlog; `setcompactionthroughput 128` increases the I/O budget for compaction from 16 MB/s to 128 MB/s. (3) WHY IT MATTERS: each additional SSTable adds a disk seek to every read; at 245 SSTables, a single read may require 245 disk seeks (mitigated by Bloom filters but not eliminated); read latency p99 increases significantly. (4) WHAT BREAKS: increasing compaction throughput to 128 MB/s consumes significant disk I/O and may impact write throughput; schedule aggressive compaction during off-peak hours; use `0` to disable the throttle during emergency catchup. (5) TAKEAWAY: add `pending_compactions` as a Cassandra dashboard metric; alert when it exceeds 100; this provides early warning before read performance degrades; the fix (increase throughput) is quick and reversible.

*What separates good from great:* The L0 SSTable problem in LCS. Leveled Compaction
Strategy organizes SSTables in levels (L0 files are unsorted, L1+ are sorted). During
write bursts, L0 fills with many small SSTables before compaction can promote them to
L1. While in L0, reads must check ALL L0 SSTables plus L1+ - defeating LCS's main
advantage of guaranteed single-SSTable reads at L1+. Monitor L0 SSTable count:
`nodetool cfstats keyspace.table | grep "L0"`. More than 12 L0 SSTables in LCS
indicates a write burst overwhelming compaction. Response: temporarily increase
compaction throughput and reduce write rates.

---

**[SENIOR] Q4 (Trade-off): Compare QUORUM vs LOCAL_QUORUM consistency levels in a multi-datacenter Cassandra deployment. When does the choice matter?**

QUORUM: a write is acknowledged when `floor(total_replicas_across_all_DCs / 2) + 1`
replicas confirm the write.
Example: 2 DCs, RF=3 each, total 6 replicas: QUORUM = 4 replicas (must span both DCs).

LOCAL_QUORUM: a write is acknowledged when `floor(DC_replicas / 2) + 1` replicas in
the LOCAL datacenter confirm the write.
Example: 2 DCs, RF=3 each: LOCAL_QUORUM = 2 replicas in the local DC only.

Performance difference:
- QUORUM: requires cross-DC coordination; adds inter-DC network latency (typically
  50-200ms between regions); write latency p99 = DC1 write time + DC2 confirmation time.
- LOCAL_QUORUM: no cross-DC coordination for confirmation; write latency = local DC only.

Consistency difference:
- QUORUM: reads and writes see a globally consistent view across all DCs; a read in DC2
  always sees the latest write from DC1 (because both must be at majority).
- LOCAL_QUORUM: reads in DC2 may see data that has not yet replicated from DC1 (async
  replication lag); eventual consistency within each DC.

Use QUORUM when:
- Financial data: a payment confirmed in DC1 must be immediately visible in DC2.
- Global user sessions: a user logged in via DC1 must be authenticated in DC2 without
  re-login.
- Configuration changes: schema or settings that must be consistent globally.

Use LOCAL_QUORUM when:
- User content: a post created in DC1 can be visible in DC2 within seconds (not ms).
- Analytics data: time-series metrics where slight lag is acceptable.
- Any data where eventual consistency is acceptable (most application data).

*What separates good from great:* The EACH consistency level. `EACH` requires a quorum
from EVERY datacenter. In a 3-DC deployment, `EACH` requires majority in DC1 AND DC2
AND DC3. This provides the strongest consistency guarantee but requires all DCs to be
available; a single DC outage causes all writes with `EACH` to fail. Never use `EACH`
for production application writes; it is only appropriate for schema migration scripts
that must propagate to all DCs before the application reads the new schema.

---

**[SENIOR] Q5 (Scenario): You are on-call. A Cassandra cluster alert fires: read latency p99 has increased from 5ms to 800ms over the past 30 minutes. Walk through the diagnosis.**

Step 1 - Check for ongoing compaction:

```bash
nodetool compactionstats
# pending tasks: 1,247
# -> 1,247 pending compactions; disk I/O saturated by compaction
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using `nodetool compactionstats` as the first diagnostic step for Cassandra latency spikes. (2) KEY MECHANISM: when compaction is running, it consumes disk I/O; Cassandra reads also require disk I/O; if compaction saturates the disk, reads are queued behind compaction I/O; the 1,247 pending compaction tasks explain the 800ms p99. (3) WHY IT MATTERS: compaction-driven latency spikes are the most common Cassandra performance issue; the fix (throttle or pause compaction) provides immediate relief. (4) WHAT BREAKS: pausing compaction (`nodetool stop COMPACTION`) is a temporary measure; SSTable count will continue to grow during the pause; unpause compaction during off-peak hours. (5) TAKEAWAY: add `pending_compactions` as the first Cassandra alert; investigate compaction before exploring other causes.

Step 2 - Check for GC pressure:

```bash
# Check JVM GC pause duration
grep "GCInspector" /var/log/cassandra/system.log | tail -10
# "GCInspector.java:... GC for G1 Young Generation:
#  1,234 ms for 3 collections"
# -> 1.2 second GC pause! Explains the latency spike

# Check heap usage
nodetool gcstats
# Total number of GCs: 47
# Max GC duration: 1,234 ms  <- critical
# Total time used: 45,678 ms
# Stdev: 234 ms
```

> **Code walkthrough:** (1) WHAT IT SHOWS: diagnosing JVM GC pauses as a cause of Cassandra latency - checking system logs for GCInspector warnings and `nodetool gcstats` for GC duration. (2) KEY MECHANISM: Cassandra runs on the JVM; during GC, the JVM pauses all application threads ("stop-the-world"); while paused, Cassandra cannot respond to read requests; the coordinator node's read timeout fires; the client receives a `ReadTimeoutException`. (3) WHY IT MATTERS: 1.2 second GC pauses are catastrophic for Cassandra; read timeouts fire at 5 seconds by default but the coordinator retries; during a GC pause, all in-flight reads stack up. (4) WHAT BREAKS: GC pauses cascade; a 1.2 second pause on one node causes the coordinator to retry on another node; that node may also be experiencing GC; the cumulative latency can exceed the 5-second timeout causing read failures. (5) TAKEAWAY: set Cassandra heap correctly (8-16 GB max; 50% of RAM for page cache); large heaps (> 16 GB) cause long G1 GC pauses; if the dataset is > 32 GB, use page cache (not heap) for the excess data.

Step 3 - Check for hot partitions:

```bash
# Enable read tracing on the slow table
# In cqlsh:
# TRACING ON;
# SELECT * FROM keyspace.table WHERE pk = 'hotkey';
# Check trace output for latency per operation

# Check for uneven partition sizes
nodetool tablehistograms keyspace events
# Partition size (bytes): p50=1KB, p75=2KB,
#   p95=500KB, p99=50MB <- HUGE p99!
# -> Some partitions are 50 MB (hot, wide partitions)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using `nodetool tablehistograms` to identify hot partitions by detecting extremely large partition sizes at the p99 percentile. (2) KEY MECHANISM: `tablehistograms` shows the distribution of partition sizes, SSTable cells per read, and tombstones per read; a p99 of 50 MB with a p50 of 1 KB indicates a massive hot partition (e.g., all events for one user in a table without proper bucketing). (3) WHY IT MATTERS: a 50 MB read is 50,000x larger than the average read; reads for the hot partition take orders of magnitude longer; they saturate I/O and create read queue backlog. (4) WHAT BREAKS: TRACING ON generates one trace row per read in `system_traces.sessions`; under high traffic, tracing data overwhelms the `system_traces` table; use `TRACING ON` only briefly for diagnosis. (5) TAKEAWAY: a partition size p99 > 1 MB indicates a data modeling problem; redesign the partition key to bucket data more granularly (e.g., `(user_id, date)` instead of `(user_id)` for daily event data).

*What separates good from great:* The node-level vs cluster-level distinction. All three
diagnostics above (compaction, GC, hot partition) should be checked per node, not just
for the cluster aggregate. If only one node shows GC pressure, it may be failing;
Cassandra's snitches will route traffic to it until it is detected as down. Use
`nodetool status` to check each node's status; a `DN` (Down Normal) status indicates
the node is not responding; traffic is being redistributed to remaining nodes. If only
one node is under pressure, the cluster coordinator may be routing most requests there
if it is the token owner for the hot partition; use `nodetool getendpoints` to confirm.

---

**[SENIOR] Q6 (Application): How do you implement a Cassandra repair schedule for production? What is the risk of using full repair vs incremental repair?**

Repair is the process of synchronizing SSTables across all replicas for a given token
range. It ensures all replicas have identical data, which is critical for correctness
(tombstone propagation, consistency after node recovery).

Full repair (`nodetool repair --full`):
- Compares ALL SSTables across all replicas for the entire token range.
- Every SSTable is read and its Merkle tree hash is compared with replicas.
- Differences are synchronized.
- Time: can take hours to days on a large cluster.
- I/O cost: very high; reads all SSTables, generates repair traffic between nodes.
- Risk: overlapping full repairs on adjacent nodes create compaction storms; the
  repaired data triggers compaction; multiple nodes repairing simultaneously causes
  cluster-wide I/O saturation.

Incremental repair (`nodetool repair` without `--full`, Cassandra 2.1+):
- Only compares SSTables that have NOT been previously repaired (unrepaired SSTables).
- Previously repaired SSTables are marked as "repaired" and skipped in future incremental
  repairs.
- Time: much faster than full repair after the first run.
- Risk: repaired SSTables skip consistency checks; data in "repaired" SSTables may still
  diverge if a node was offline during the initial repair.
- Best practice: run incremental repair weekly; run full repair monthly.

Production implementation with Reaper:
- Reaper (cassandra-reaper.io) is the production standard for Cassandra repair scheduling.
- Supports incremental repair with controlled parallelism.
- Segments repair across token ranges, throttling I/O.
- Handles node failures during repair gracefully.

*What separates good from great:* The anticompaction issue. In Cassandra 2.2-4.0,
incremental repair runs "anticompaction" to split SSTables into "repaired" and
"unrepaired" sections. This anticompaction causes write amplification: every repaired
SSTable is rewritten. On a large cluster, this can double disk I/O for hours. Cassandra
4.0 introduced "zero-copy streaming" and improved incremental repair to avoid
anticompaction; if running Cassandra < 4.0, schedule incremental repair during off-peak
hours and monitor disk I/O. Cassandra 4.0+ incremental repair is far more efficient.

---

**[STAFF] Q7 (Trade-off): Compare read repair vs hinted handoff vs full repair in Cassandra. When does each mechanism correct data?**

Cassandra has three mechanisms for propagating consistency:

Hinted handoff:
- When a write is sent to a node that is temporarily down, the coordinator stores a
  "hint" (the write data + target node address).
- When the target node comes back online, the coordinator sends it all pending hints.
- Time window: hints are stored for `max_hint_window_in_ms` (3 hours default).
- Limitation: if the node is down for > 3 hours, hints are discarded; the node is
  permanently inconsistent until repair.
- Use case: short transient failures (network blip, rolling restart).

Read repair:
- When a read uses consistency level `QUORUM` or higher, Cassandra reads from multiple
  replicas and compares the responses.
- If replicas differ, the node with the most recent data wins (latest timestamp).
- The stale replica is updated with the correct data in the background.
- `read_repair_chance`: probability of triggering a read repair on any random read
  (default: varies by CL).
- Use case: gradual background consistency correction; low cost per read.
- Limitation: only corrects inconsistencies that are discovered during reads; not a
  substitute for scheduled repair.

Full/Incremental repair:
- Proactive: compares all data across replicas regardless of whether it is read.
- Necessary for: tombstone propagation, data correction after long node outages,
  and ensuring deleted data is actually deleted everywhere.
- Use case: correctness guarantee, regulatory compliance, GDPR deletion verification.

*What separates good from great:* The `DCLOCAL_SERIAL` consistency for conditional
operations. Cassandra Lightweight Transactions (LWT) use the Paxos protocol to provide
compare-and-swap semantics (`IF NOT EXISTS`, `IF col = val`). LWT with `LOCAL_SERIAL`
consistency uses Paxos only within the local DC; it does not coordinate with other DCs.
For operations that require global uniqueness (e.g., username registration), use `SERIAL`
consistency (global Paxos) - but accept higher latency (cross-DC Paxos round-trips).
For operations where local consistency is sufficient, `LOCAL_SERIAL` is faster. LWT
should be used sparingly; it has 4x the latency and 4x the coordination overhead of
regular reads/writes.

---

**[STAFF] Q8 (Mechanism): Explain Cassandra's virtual nodes (vnodes) and how they affect repair and rebalancing.**

In Cassandra, data is partitioned across the ring using a token-based hash. Each node
owns a range of the token ring. In older Cassandra deployments, each node owned one
large contiguous token range. Adding a new node required splitting a single node's range
in two - a manual, error-prone process.

Virtual nodes (vnodes), introduced in Cassandra 1.2:
Instead of one large token range, each physical node is assigned many small token ranges
(default: 256 vnodes per node). The token ring has 256 * N token positions for N nodes.

Rebalancing benefits:
- Adding a node: the new node "claims" a fraction of vnodes from all existing nodes
  simultaneously. Data streams in from multiple sources in parallel. Rebalancing is
  faster (parallelized) and more even (no single hot source node).
- Removing a node: its 256 vnodes are redistributed across all remaining nodes.

Repair implications:
- With 1 token range per node: repair of 1 node = repair 1 range = quick.
- With 256 vnodes per node: repair of 1 node = repair 256 ranges = slower.
- Each vnode range must be repaired independently; more repair segments = longer total
  repair time; BUT: repair can be parallelized across vnodes using Reaper.
- `nodetool repair` without vnodes: repairs 1 token range. With vnodes: repairs all
  256 token ranges for that node sequentially.

*What separates good from great:* The `num_tokens` tuning for heterogeneous clusters.
In a cluster with nodes of different capacities (some nodes with more disk), larger
capacity nodes can be assigned more vnodes (`num_tokens = 512`) while smaller nodes
get fewer (`num_tokens = 128`). This proportionally allocates more data to larger nodes.
However, this optimization requires manual coordination and is only relevant for
heterogeneous clusters; most production clusters use uniform hardware and the default
256 vnodes.

---

**[STAFF] Q9 (Application): Design a Cassandra table schema for a social media feed. Handle 100M users, 10K writes/second, and feed reads requiring the 50 most recent posts.**

Requirements:
- 100M users, each with up to 10K followers.
- 10K post writes/second globally.
- Read: user's feed (50 most recent posts from followed users).
- Low latency: feed reads < 50ms p99.

Option A - Fan-out on write (write to each follower's feed):

```sql
CREATE TABLE user_feed (
  user_id    UUID,
  post_time  TIMESTAMP,
  poster_id  UUID,
  post_id    UUID,
  content    TEXT,
  PRIMARY KEY (user_id, post_time, post_id)
) WITH CLUSTERING ORDER BY (post_time DESC)
  AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_unit': 'HOURS',
    'compaction_window_size': 24
  }
  AND default_time_to_live = 604800; -- 7 days
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a Cassandra schema for a per-user feed using fan-out on write; each post is inserted into the `user_feed` table for every follower of the poster. (2) KEY MECHANISM: `PRIMARY KEY (user_id, post_time, post_id)` partitions by `user_id` for reads (all posts for a user are in one partition); clusters by `post_time DESC` so the 50 most recent posts are at the start of the partition; `TWCS` with 24-hour windows + 7-day TTL ensures clean compaction without tombstone accumulation. (3) WHY IT MATTERS: feed reads are a single `SELECT LIMIT 50` query for the user's partition; no multi-partition scatter is needed; reads are O(1) partition lookups returning the first 50 rows. (4) WHAT BREAKS: a celebrity with 10M followers creates 10M insert operations per post; 10K posts/second * 10M fans = 100 billion inserts/second; fan-out on write does not scale for celebrities. (5) TAKEAWAY: fan-out on write with Cassandra works for social media up to moderate follower counts (< 100K); for celebrity accounts, use fan-out on read (store posts centrally, merge feeds at read time); implement a hybrid model that fan-outs for regular users and reads from source for high-follower accounts.

Trade-offs: fan-out on write (user_feed table) has O(followers) write amplification
but O(1) read complexity. For an influencer with 10M followers, a single post creates
10M writes. Solution: hybrid model - fan-out for users with < 10K followers; on-read
merge for celebrity accounts. Celebrity posts fetched from a `celebrity_posts` table
at read time; merged in the application layer.

*What separates good from great:* The `post_time + post_id` composite clustering key.
Using only `post_time` as the clustering key causes issues when two posts occur at the
same millisecond (both have the same timestamp, one overwrites the other). Adding
`post_id` (a UUID) to the clustering key ensures uniqueness while maintaining sort order.
The partition key `user_id` must be chosen to avoid hot partitions: high-activity users
receive many feed inserts; if a celebrity's user_id is the partition key for their own
feed, that partition is significantly larger than average. Monitor partition sizes with
`nodetool tablehistograms`; bucket by `(user_id, date)` if needed.

---

**[STAFF] Q10 (Debugging): How do you identify and resolve Cassandra "uneven load" across the cluster?**

Uneven load in Cassandra occurs when some nodes receive significantly more read or write
requests than others. This can be caused by: (1) token imbalance (non-uniform vnode
distribution), (2) hot partitions (a few partition keys receive disproportionate traffic),
(3) rack-awareness misconfiguration (one rack receives all reads for a consistency level).

Diagnosis:

```bash
# 1. Check per-node load (disk and request rate)
nodetool tpstats
# Shows thread pool statistics including:
# Read Stage: active, pending, completed, blocked
# Write Stage: active, pending, completed, blocked
# High "Blocked" count = node under pressure

# 2. Check data distribution
nodetool ring
# Shows token ranges and ownership percentage per node
# Even distribution: each node owns ~25% for 4-node cluster
# "Node 1: 25.1%, Node 2: 24.9%, Node 3: 25.0%, Node 4: 25.0%"
# Bad: "Node 1: 60%, Node 2: 15%, ..."
# -> Bad distribution caused by vnodes with num_tokens mismatch

# 3. Check per-node request rates via JMX
# Use nodetool metrics or Prometheus JMX exporter:
# cassandra_client_requests_total{type="read"} per node
# Plot per-node; identify outliers
```

> **Code walkthrough:** (1) WHAT IT SHOWS: diagnosing Cassandra uneven load using `nodetool tpstats` for thread pool pressure, `nodetool ring` for token distribution, and JMX metrics for per-node request rates. (2) KEY MECHANISM: `tpstats` shows thread pool queues; "Blocked" means tasks are waiting because the pool is saturated; this is the first sign of node overload. `nodetool ring` shows the token ring ownership percentages; imbalanced ownership means some nodes handle more data than others. (3) WHY IT MATTERS: in a 4-node cluster, if one node owns 60% of the token range, it receives 60% of all writes and reads; it is always the bottleneck; adding more nodes helps only if tokens are rebalanced. (4) WHAT BREAKS: `nodetool ring` with vnodes shows only a summary; the 256 vnodes per node are averaged; individual vnode range sizes are hidden; use `nodetool describering keyspace` for detailed token distribution. (5) TAKEAWAY: monitor per-node read and write request rates as a standard dashboard metric; the coefficient of variation across nodes should be < 20%; higher variation indicates a hot partition or token imbalance.

*What separates good from great:* The hot partition vs hot node distinction. A hot
partition sends all traffic for a specific partition key to the subset of nodes that
own that key's token range. A hot node sends all traffic for the node's portion of the
ring to that node regardless of partition. They require different fixes: hot partition -
redesign the partition key (add a bucket or sharding suffix); hot node - run
`nodetool move` to redistribute tokens, or use `num_tokens` to rebalance. In production,
hot partitions are far more common; monitor `cassandra_table_read_latency` per table
and cross-reference with `nodetool tablehistograms` to identify large partitions.

---

**[STAFF] Q11 (Scenario): A GDPR deletion request requires deleting all data for user_id X from Cassandra. How do you implement and verify the deletion?**

GDPR Article 17 (Right to Erasure) requires deleting all personal data for a user on
request. In Cassandra, this requires:

Step 1 - Identify all tables containing user data:

```bash
# Check schema for all tables using user_id as partition key
# or as a clustering/non-key column (data may be in multiple tables)
cqlsh -e "DESCRIBE SCHEMA" | grep -A10 "user_id"
# List all tables: user_profiles, user_feeds, user_events, audit_logs
```

> **Code walkthrough:** (1) WHAT IT SHOWS: discovering all Cassandra tables that contain data for a specific user by examining the schema for `user_id` references. (2) KEY MECHANISM: `DESCRIBE SCHEMA` outputs the full CQL schema; `grep -A10 "user_id"` shows 10 lines of context around each occurrence; this maps which tables use `user_id` as a partition key, clustering key, or regular column. (3) WHY IT MATTERS: GDPR deletion must be complete; missing a table leaves personal data accessible; the schema audit ensures all tables are identified. (4) WHAT BREAKS: non-key columns with `user_id` require full table scans to find related rows (extremely expensive in Cassandra); redesign schemas to always use `user_id` as the partition key for user data. (5) TAKEAWAY: GDPR readiness requires data modeling decisions at schema design time; every table that stores user data should be queryable by user_id (user_id as partition key) to enable efficient deletion.

Step 2 - Delete user data from all tables:

```bash
# For tables where user_id is the partition key:
cqlsh -e "DELETE FROM user_profiles WHERE user_id = 'abc123';"
cqlsh -e "DELETE FROM user_feed WHERE user_id = 'abc123';"
cqlsh -e "DELETE FROM user_events WHERE user_id = 'abc123';"
# Uses consistency QUORUM to ensure deletion reaches all replicas
```

> **Code walkthrough:** (1) WHAT IT SHOWS: issuing DELETE statements for user data across all tables that partition by `user_id`. (2) KEY MECHANISM: a partition-level DELETE creates a single partition tombstone that hides all rows for that partition; the consistency level `QUORUM` ensures the tombstone is written to a majority of replicas before acknowledging; this guarantees at least one alive replica has the tombstone. (3) WHY IT MATTERS: using `QUORUM` (not `ONE`) for GDPR deletions ensures the deletion is durable; a `ONE` write might acknowledge before replication, and if the single node receiving it crashes, the deletion is lost. (4) WHAT BREAKS: if `user_id` is a clustering column (not the partition key) in some tables, a partition-level DELETE is not possible; a full table scan with `ALLOW FILTERING` is required, which is expensive; redesign the schema to use `user_id` as partition key. (5) TAKEAWAY: always use `QUORUM` or `LOCAL_QUORUM` for GDPR deletion operations; never use `ONE`; the consistency level difference is the gap between "data may still be visible somewhere" and "data is reliably deleted."

Step 3 - Verify deletion (after gc_grace_seconds):

```bash
# Immediately after deletion: tombstone exists, data hidden
cqlsh -e "SELECT * FROM user_profiles WHERE user_id = 'abc123';"
# Returns empty (tombstone hides data) - GOOD

# After gc_grace_seconds (10 days): data should be physically removed
# Run nodetool repair first to ensure tombstone reaches all replicas
nodetool repair -full keyspace user_profiles
nodetool compact keyspace user_profiles
# Then verify:
cqlsh -e "SELECT * FROM user_profiles WHERE user_id = 'abc123';"
# Must return empty
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the GDPR deletion verification process - immediate deletion (tombstone), waiting for gc_grace_seconds, and post-compaction verification. (2) KEY MECHANISM: immediately after DELETE, `SELECT` returns empty because the tombstone hides the data; the physical data is still on disk; after gc_grace_seconds + compaction, the physical data is removed. (3) WHY IT MATTERS: GDPR requires physical deletion of data, not just logical deletion; Cassandra's tombstone mechanism provides logical deletion immediately; physical deletion requires gc_grace_seconds + compaction; document this timeline in the GDPR compliance report. (4) WHAT BREAKS: if the verification is performed before gc_grace_seconds has elapsed and before repair + compact are run, the data is NOT yet physically deleted; running `sstabledump` on the SSTables would still show the original data. (5) TAKEAWAY: for GDPR compliance, create a deletion verification runbook that includes: (a) immediate SELECT returns empty, (b) full repair within gc_grace_seconds, (c) forced compaction, (d) SELECT returns empty again, (e) document completion timestamp.

*What separates good from great:* The secondary index and materialized view complication.
If Cassandra secondary indexes or materialized views exist for user data, deletions to
the base table are automatically propagated to secondary indexes and materialized views.
However, the propagation is asynchronous; between the base table deletion and the
secondary index deletion, a search using the secondary index may still return the
deleted user's data. For GDPR compliance, disable secondary indexes on personal data
columns, or ensure the GDPR deletion runbook includes verifying the deletion via all
query patterns (partition key, secondary index, materialized view) before closing the
deletion request.

---

**[STAFF] Q12 (Scenario): Design a Cassandra monitoring strategy that would have prevented the tombstone overflow incident in Q5. What metrics, alerts, and runbooks would you implement?**

A mature Cassandra monitoring strategy covers four categories:

Category 1 - Tombstone Metrics:

Metric: `cassandra_table_tombstones_scanned` (per read, per table).
Alert: p99 tombstones scanned > 1,000 (warn threshold); > 50,000 (critical, 50% of
failure threshold).
Runbook on alert: (1) Identify partition keys with high tombstone counts using
`grep TombstoneWarn /var/log/cassandra/system.log`. (2) Check compaction strategy for
the table. (3) If STCS with deletes: schedule TWCS migration. (4) If TTL-based: verify
TWCS is configured. (5) Verify `nodetool compact` is not needed.

Category 2 - Compaction Metrics:

Metric: `pending_compactions` (per node, per table).
Alert: pending > 100 (warn); > 500 (critical).
Metric: `SSTable count` per table.
Alert: count > 50 for STCS; count > 12 L0 files for LCS.
Runbook on alert: increase `compaction_throughput`, check for write burst.

Category 3 - Repair Metrics:

Metric: days since last successful repair per table (track in Reaper).
Alert: > 7 days since last repair (warn, gc_grace = 10 days).
Alert: > 10 days since last repair (critical, zombie data risk).
Runbook on alert: trigger incremental repair via Reaper; verify completion.

Category 4 - JVM GC Metrics:

Metric: GC pause duration (G1GC young + old gen pause).
Alert: max pause > 500ms (warn); > 2,000ms (critical, read timeouts firing).
Runbook on alert: check heap utilization; if heap > 85%, check for memory leak (large
reads, cross-partition scans); reduce heap size and increase page cache allocation.

*What separates good from great:* The proactive data model review. A monitoring strategy
catches problems after they are developing. A design review process prevents the problems
from starting. Implement a "Cassandra Schema Review" checklist for all new tables:
(1) Is the partition key chosen to avoid hot partitions? (2) Does the table use explicit
deletes? If yes, require TWCS + TTL-at-insert. (3) What is the expected partition size
after 30 days of data? Size must not exceed 100 MB. (4) What is the maximum expected
tombstones per read? Must be < 1,000. Tables that fail this review require a data model
redesign before the schema is approved for production. A tombstone overflow incident
post-mortem always traces back to a schema approved without this review; institutionalizing
the review prevents recurrence.
