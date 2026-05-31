---
layout: default
title: "Database SQL - L4 MVCC Internals"
parent: "Database SQL"
grand_parent: "SK Interview"
nav_order: 15
permalink: /database-sql/l4-mvcc-internals/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [MVCC (Multi-Version Concurrency Control) Internals](#mvcc-multi-version-concurrency-control-internals) | medium |

---

# MVCC (Multi-Version Concurrency Control) Internals

**TL;DR:** MVCC maintains multiple versions of every row. Each row version has
xmin (the transaction that created it) and xmax (the transaction that deleted or
updated it). A transaction's snapshot determines which versions are visible.
This allows readers and writers to never block each other. The cost: dead row
versions accumulate until VACUUM reclaims them. MVCC is the foundation of PostgreSQL's
concurrency model.

---

### 🎯 Model Answer

**30 seconds:**
> MVCC: every row change creates a new row version, not an in-place update.
> Each version has xmin (creator transaction) and xmax (deleting transaction).
> A reader's snapshot filters: see only rows where xmin is committed and before
> my snapshot, and xmax is either not committed or after my snapshot.
> Result: readers never block writers, writers never block readers.

**3 minutes:**
> How a row update works: instead of modifying the row in place, PostgreSQL:
> (1) creates a new row version on a heap page with xmin=current_txid;
> (2) marks the old version with xmax=current_txid (making it logically deleted).
> Both versions coexist on disk. Concurrent readers see the old version
> (their snapshot is before the transaction). After the transaction commits:
> new readers see only the new version.
>
> Snapshot: a set of active transaction IDs at the moment the snapshot was taken.
> A row version is visible if: xmin is committed AND not in the snapshot's active
> set AND before the snapshot's xmax horizon; AND (xmax is null OR xmax is not
> committed OR xmax is in the snapshot's active set OR xmax is after the horizon).
>
> VACUUM: dead row versions accumulate. `pg_dead_tup` tracks them. VACUUM traverses
> the heap, identifies dead versions (all snapshots have advanced past the xmax),
> and marks their space as reusable. Without VACUUM: tables bloat indefinitely.
>
> Transaction ID wraparound: transaction IDs are 32-bit integers. At 2^31
> transactions ahead: the new XID appears "in the past." PostgreSQL performs
> emergency VACUUM (aggressive) to prevent this from corrupting the visibility
> system. Monitoring: `age(datfrozenxid)` in `pg_database`.

**Blank Mind Recovery:**

**(1) Restate:** "MVCC: each row change = new version. xmin=creator, xmax=deleter.
Snapshot = filter. Readers see consistent past. VACUUM = cleanup dead versions."

**(2) First principles:** "Readers and writers in conflict: one must wait.
MVCC solution: give each transaction its own view of the data.
Writers create new versions. Readers see old versions. No conflict."

**(3) Bridge:** "Like a wiki edit history. When you edit a page: the old version
stays in history. Someone reading the old version sees it unchanged. The editor
and the reader work simultaneously. VACUUM periodically deletes old versions
no one needs anymore."

---

### 📘 Concept Explanation

**Row version header fields:**

```
Each heap tuple (row version) has a header:
  t_xmin:  XID of the transaction that inserted this version
  t_xmax:  XID of the transaction that deleted/updated this
           version (0 = not deleted)
  t_ctid:  (page, offset) of the latest version of this row
           If updated: points to the new version's location
  t_infomask: flags (committed/aborted/frozen/hints)

Physical layout example for UPDATE:

Heap page:
  Slot 1: xmin=100 xmax=105 data={name:"Alice",age:30}
           ctid=(page5, slot3)  <- old version
  [on page 5, slot 3:]
  Slot 3: xmin=105 xmax=0   data={name:"Alice",age:31}
           ctid=(page5, slot3)  <- new version (current)

TX 103 snapshot (before TX 105 committed):
  -> sees Slot 1 (xmin=100 committed, xmax=105 not committed)
  -> does NOT see Slot 3 (xmin=105 not committed)

TX 110 snapshot (after TX 105 committed):
  -> does NOT see Slot 1 (xmax=105 committed = deleted)
  -> sees Slot 3 (xmin=105 committed, xmax=0 = alive)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Snapshot structure:**

```
Snapshot at TX 110:
  xmin:    oldest active XID (all below are committed/aborted)
  xmax:    first assigned XID after snapshot (invisible)
  xip:     array of active XIDs between xmin and xmax
           (in-progress when snapshot was taken)

Visibility rule for a row version (xmin_ver, xmax_ver):
  Visible if ALL of:
  1. xmin_ver is committed:
     (not in xip AND xmin_ver < snapshot.xmax)
  2. xmin_ver < snapshot.xmax (not a future TX)
  3. xmax_ver is NOT committed, OR:
     xmax_ver is in xip (still active), OR
     xmax_ver >= snapshot.xmax (future TX)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```sql
-- MVCC VISIBILITY: observe row versions

-- Session 1: long-running transaction
BEGIN;
SELECT txid_current();  -- e.g., 1005

-- Another session updates a row concurrently:
-- UPDATE orders SET status='SHIPPED' WHERE id=1;
-- COMMIT; (from TX 1006)

-- Session 1 (still in its original transaction):
SELECT status FROM orders WHERE id = 1;
-- Returns: 'PROCESSING' (the old version)
-- TX 1005 snapshot was taken before TX 1006.
-- TX 1006's version has xmin=1006, which is after
-- the snapshot's xmax horizon.
COMMIT;

-- After Session 1 commits:
SELECT status FROM orders WHERE id = 1;
-- Returns: 'SHIPPED' (the new version)
-- New statement, new snapshot, sees TX 1006's commit.
```

> **Code walkthrough:** Transaction 1005 takes a snapshot when it begins.
> The snapshot records the "present" as the state at TX 1005. When TX 1006
> updates and commits: it creates a new row version with xmin=1006. TX 1005's
> snapshot says: xmax_horizon = 1005 (approximately). TX 1006 > 1005:
> the new version is "in the future" relative to TX 1005's snapshot.
> TX 1005 sees the old version (xmin=100_something, xmax=1006 not yet committed).
> After TX 1005 commits: a new statement takes a fresh snapshot that includes
> TX 1006's commit. The new version is now visible.

```sql
-- DEAD TUPLE ACCUMULATION: observe and fix bloat

-- Check dead tuples per table:
SELECT
    relname,
    n_live_tup,
    n_dead_tup,
    ROUND(
        100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0),
        2
    ) AS dead_pct,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 10;

-- A table with 30% dead tuples is bloated.
-- Queries scan dead versions (wasted I/O).
-- Indexes contain entries for dead versions (wasted space).

-- MANUAL VACUUM: reclaim dead tuple space
VACUUM ANALYZE orders;
-- VACUUM:
--   1. Scan heap: identify dead versions
--      (xmax committed AND no snapshot can see it)
--   2. Mark their slots as available (FSM = free space map)
--   3. Remove index entries pointing to dead tuples
-- Result: space reusable for new rows, indexes smaller.

-- VACUUM FULL: compacts the table (exclusive lock!)
-- VACUUM FULL orders;
-- Use only in maintenance windows. Rewrites entire table.
-- Reclaims disk space (returns to OS). Bloat fully removed.
-- DO NOT run on large tables without a maintenance window.

-- FREEZE: prevent transaction ID wraparound
VACUUM FREEZE orders;
-- Sets xmin to FrozenTransactionId (2) for old enough rows.
-- Frozen rows are visible to all transactions regardless of XID.
-- Prevents wraparound catastrophe.
```

> **Code walkthrough:** Every `UPDATE` and `DELETE` leaves a dead row version.
> These are only removed by VACUUM, not automatically. The `pg_stat_user_tables`
> query shows `n_dead_tup`: if this is 30%+ of `n_live_tup`, the table is bloated.
> Bloat degrades performance: queries scan more heap pages (including dead tuples),
> and indexes contain entries for dead rows (false lookups). Manual VACUUM
> marks dead tuple slots as reusable (space stays within the table file).
> VACUUM FULL rewrites the table into a new file without dead tuples
> (returns space to OS) but requires an exclusive lock. Use VACUUM FULL only
> in maintenance windows with confirmed write downtime.

```sql
-- TRANSACTION ID WRAPAROUND: detect and prevent

-- XID is a 32-bit integer. Max usable: ~2 billion.
-- PostgreSQL uses "circular" comparison.
-- A new XID that wraps past 2B: appears older than everything.
-- Result: rows suddenly become invisible (looks like they're
-- from the "future" which is treated as invisible).
-- This is catastrophic data corruption.

-- DETECT wraparound risk:
SELECT
    datname,
    age(datfrozenxid)         AS xid_age,
    2147483648 - age(datfrozenxid) AS xids_remaining
FROM pg_database
ORDER BY xid_age DESC;
-- age(datfrozenxid): how many XIDs have elapsed since
-- the oldest unfrozen row.
-- If age > 200M: autovacuum starts aggressive freezing.
-- If age > 1B: urgent manual VACUUM FREEZE needed.
-- If age > 2B: PostgreSQL goes into read-only mode (emergency).

-- Check oldest unfrozen XID per table:
SELECT relname, age(relfrozenxid) AS table_xid_age
FROM pg_class
WHERE relkind = 'r'
ORDER BY age(relfrozenxid) DESC
LIMIT 5;
-- Tables with age > 500M need urgent VACUUM FREEZE.

-- FREEZE old transactions:
VACUUM FREEZE ANALYZE orders;
-- Marks old enough rows as "frozen"
-- (visible to all transactions permanently).
-- Resets relfrozenxid to current XID.
-- Prevents wraparound for these rows.
```

> **Code walkthrough:** XID wraparound is one of the most catastrophic events
> in PostgreSQL operations. The XID counter is 32-bit: after ~4 billion transactions,
> it wraps to 0. PostgreSQL uses a circular comparison: XIDs more than 2^31 behind
> the current XID are "in the past" (visible). If a row's xmin is behind the
> wraparound point: it suddenly appears as from the "future" (invisible) and
> the data appears to vanish. The `age(datfrozenxid)` monitor shows how close
> you are. Autovacuum starts aggressive freezing at 200M XIDs of age. Manual
> VACUUM FREEZE is needed for tables that autovacuum misses (very large, or
> autovacuum disabled). A standard operational alert: alarm at age > 500M.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> MVCC keeps multiple versions of each row. An update creates a new version instead
> of modifying in place. Readers see the version consistent with their transaction
> start time. VACUUM removes old versions no longer needed by any transaction.
> Key benefit: readers and writers don't block each other.

---

**Senior / Staff:**
> MVCC's operational implications: (1) Heavy writes create dead tuples that bloat
> tables unless VACUUM keeps up. Monitor `n_dead_tup / n_live_tup`. Tune autovacuum
> aggressiveness for high-churn tables. (2) Long-running transactions hold back
> the xmin horizon: dead tuples cannot be reclaimed as long as the oldest transaction
> can still see them. A transaction open for 1 hour prevents 1 hour of VACUUM
> progress. Monitor `pg_stat_activity` for idle-in-transaction connections.
> (3) XID wraparound: monitor `age(datfrozenxid)`. Alert at 500M age. Run periodic
> VACUUM FREEZE on all tables in the database.

---

### ⚠️ Common Misconceptions

**"VACUUM is optional if autovacuum is running"**

Reality: autovacuum runs continuously but can fall behind on high-churn tables.
Autovacuum is throttled (vacuum_cost_delay) to avoid impacting production workloads.
For tables with millions of updates per hour: autovacuum may not keep pace.
Monitor `n_dead_tup` and `last_autovacuum`. If dead tuples grow despite autovacuum:
lower the threshold (`autovacuum_vacuum_scale_factor`) or disable cost throttling
for critical tables.

**"MVCC means updates are never blocked"**

Reality: MVCC ensures readers are never blocked by writers. But writers CAN block
other writers: row-level locks. An `UPDATE` on row X acquires an exclusive lock.
Another transaction trying to UPDATE row X blocks until the first commits or
rolls back. MVCC solves the reader-writer contention problem, not the
writer-writer contention problem.

---

### ⚖️ Comparison Table

| Aspect | MVCC (PostgreSQL) | Lock-based (MySQL 2PL Serializable) | Notes |
|---|---|---|---|
| Reader-writer conflict | Never blocks | Readers block writers | MVCC big advantage |
| Write-write conflict | Row locks block | Row locks block | Same |
| Read consistency | Per-snapshot | Latest committed | MVCC enables repeatable reads |
| Dead tuple cleanup | VACUUM (async) | None (in-place update) | MVCC has overhead |
| Transaction isolation | MVCC + SSI | 2PL | Different mechanisms |
| Bloat risk | Yes (requires VACUUM) | No | MVCC operational cost |

---

### 🏛️ System Design

**MVCC in a high-throughput system:**

```
High-write OLTP system (10K writes/second):
  - Each write creates a dead tuple.
  - 10,000 dead tuples/second = 36M/hour.
  - Without adequate VACUUM: table grows 36M rows/hour.
  - A 10-minute VACUUM lag = 6M dead tuples outstanding.

Autovacuum tuning for high-churn:
  autovacuum_vacuum_scale_factor  = 0.01 (1%)
  autovacuum_vacuum_threshold     = 1000
  autovacuum_vacuum_cost_delay    = 0    (no throttle)
  autovacuum_vacuum_cost_limit    = 800  (default 200)
  autovacuum_max_workers          = 5    (default 3)

Connection pool and long transactions:
  - Long idle-in-transaction = xmin horizon held open.
  - Dead tuples accumulate faster than VACUUM reclaims.
  - Set: idle_in_transaction_session_timeout = '30s'
  - Monitor: SELECT max(now() - xact_start) FROM
             pg_stat_activity WHERE state = 'idle in transaction'
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**XID wraparound protection in production:**

```
Monitoring stack:
  1. Alert: age(datfrozenxid) > 500,000,000
  2. Alert: age(relfrozenxid) per table > 200,000,000
  3. Dashboard: pg_stat_user_tables for n_dead_tup
  4. Alert: n_dead_tup > 20% of n_live_tup

Preventive maintenance:
  - Weekly: VACUUM ANALYZE on all tables
  - Monthly: VACUUM FREEZE on tables with old XIDs
  - pg_cron extension: schedule from within PostgreSQL
    SELECT cron.schedule('0 2 * * 0',
           $$VACUUM FREEZE ANALYZE orders$$);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 📊 Diagram

**MVCC row version lifecycle:**

```
Time ---------> TX 100 TX 103 TX 105 TX 110

INSERT (TX 100):
  [xmin=100, xmax=0, data={age:30}]  <- alive

UPDATE (TX 105):
  [xmin=100, xmax=105, data={age:30}] <- dead after TX105
  [xmin=105, xmax=0,   data={age:31}] <- new version

TX 103 snapshot (before TX 105):
  sees: [xmin=100] (alive at snapshot time)
  does NOT see: [xmin=105] (TX 105 not yet committed)

TX 110 snapshot (after TX 105):
  does NOT see: [xmin=100, xmax=105] (deleted by TX 105)
  sees: [xmin=105, xmax=0] (committed, alive)

After all TX > 105 commit:
  [xmin=100, xmax=105] is dead (no snapshot can see it)
  VACUUM: marks the slot as free
```

```mermaid
sequenceDiagram
    participant TX100 as TX 100 (INSERT)
    participant TX103 as TX 103 (Reader)
    participant TX105 as TX 105 (UPDATE)
    participant TX110 as TX 110 (Reader)
    participant VACUUM as VACUUM

    TX100->>+Heap: INSERT row: xmin=100, xmax=0
    TX100-->>-Heap: COMMIT

    TX103->>Heap: BEGIN (snapshot taken)
    TX105->>Heap: UPDATE: new row xmin=105, xmax=0
    TX105->>Heap: old row: xmax=105
    TX103->>Heap: SELECT -> sees xmin=100 (xmax=105 not committed)
    TX103-->>Heap: COMMIT

    TX105-->>Heap: COMMIT
    TX110->>Heap: BEGIN (snapshot after TX105)
    TX110->>Heap: SELECT -> sees xmin=105, not xmin=100

    VACUUM->>Heap: identifies xmin=100 as dead (no active snapshot)
    VACUUM->>Heap: reclaims slot, removes index entry
```

> **Diagram walkthrough:** The sequence diagram shows three concurrent operations
> on the same row. TX100 inserts the row (xmin=100). TX103 starts a reader;
> while it's running, TX105 updates the row. The heap now has two versions:
> old (xmax=105) and new (xmin=105). TX103's snapshot was taken before TX105
> committed: it sees the old version. TX110 starts after TX105 commits:
> it sees only the new version. Finally, VACUUM identifies the old version as
> dead (all transactions that could see it have completed) and reclaims the space.
> The key insight: at no point did any reader block any writer or vice versa.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Table bloat from high UPDATE volume**

Symptom: table size grows much faster than row count. Queries slow down over time
as more heap pages must be scanned. `pg_relation_size('orders')` grows despite
no new rows.

Diagnosis:
```sql
SELECT
    relname,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    n_dead_tup,
    n_live_tup,
    ROUND(100.0 * n_dead_tup /
          NULLIF(n_live_tup + n_dead_tup, 0), 1) AS dead_pct
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 10;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Resolution: increase autovacuum aggressiveness. Run `VACUUM ANALYZE` manually
during low-traffic period. For severe bloat: `VACUUM FULL` during maintenance
window (requires exclusive lock, compacts the file).

**Failure 2: XID wraparound emergency**

Symptom: `pg_database_size` monitoring alert fires. PostgreSQL log: "database is
approaching XID wraparound". Or catastrophically: tables suddenly appear empty
or READ ONLY mode is enforced.

Diagnosis:
```sql
SELECT datname, age(datfrozenxid)
FROM pg_database ORDER BY age(datfrozenxid) DESC;
-- age > 2,000,000,000 = critical
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Emergency resolution:
```sql
-- Run VACUUM FREEZE on all tables in the affected database:
-- (connect to each database and run:)
VACUUM FREEZE;  -- without table name: all tables
-- Monitor progress: pg_stat_progress_vacuum
SELECT phase, heap_blks_scanned, heap_blks_total
FROM pg_stat_progress_vacuum WHERE relid = 'orders'::regclass;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Failure 3: Long idle-in-transaction blocks VACUUM progress**

Symptom: `n_dead_tup` grows despite autovacuum running. Dead tuples are not
being reclaimed.

Diagnosis:
```sql
SELECT pid, usename, state, xact_start, query
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND xact_start < NOW() - INTERVAL '5 minutes'
ORDER BY xact_start;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

A transaction open for 5+ minutes holds the xmin horizon. VACUUM cannot reclaim
any tuple newer than this transaction's start.

Fix: kill the idle transaction: `SELECT pg_terminate_backend(pid)`.
Prevention: `SET idle_in_transaction_session_timeout = '60s'` in `postgresql.conf`.

---

### 🎯 Interview Deep-Dive

**Q1: Walk me through exactly what happens when an UPDATE is executed in PostgreSQL.**

🗣️ "PostgreSQL UPDATE does NOT modify the row in place. The process:
(1) The UPDATE statement acquires a row-level exclusive lock on the existing row version.
(2) A new row version is written to a free slot on a heap page (possibly the same
page if there is room, or a new page). The new version has xmin=current_txid, xmax=0.
(3) The old row version's xmax field is set to current_txid (marks it as deleted by this transaction). The old version's ctid is updated to point to the new version's location.
(4) The index entries are updated: for any indexed column that changed: a new index entry is added (pointing to the new row version); the old index entry is NOT immediately removed (it will be cleaned by VACUUM). For HOT updates (no indexed column changed, new version on same heap page): no new index entry is created; the old index entry follows the ctid chain.
(5) On COMMIT: xmin becomes visible to other transactions.
(6) On ROLLBACK: xmin is never committed; the new version is invisible; the old version's xmax is cleared."

**Q2: What is a HOT update and why is it important for performance?**

🗣️ "HOT (Heap Only Tuple) update: an optimization for updates that do not change any indexed column. Conditions for a HOT update: (1) no indexed column is changed; (2) the new row version fits on the same heap page as the old version.
When both conditions are met: PostgreSQL writes the new version on the same page.
No new index entry is created (savings: no index write). The old index entry's pointer is followed to the old heap tuple, then the ctid chain (old->new version) is followed to find the live version. Benefits: (1) no index write (significant for tables with many indexes); (2) the old version and all index pruning are handled lazily (heap-only pruning during access or VACUUM). Cost: the page must have free space for the new version. If the page is full: HOT is not possible; the update proceeds normally. Monitor: `n_hot_upd / n_upd` ratio in `pg_stat_user_tables`. Low ratio: either pages are full or indexed columns are frequently updated."

**Q3: How does the visibility map work with MVCC?**

🗣️ "The visibility map is a bitmap with one bit per heap page. A bit is set if ALL rows on that page are visible to all active transactions (no dead tuples, all tuples frozen or committed and visible). When the visibility map bit is set for a page: (1) Index Only Scans can skip the heap check for that page (all rows are visible; no need to verify with the heap). (2) VACUUM can skip the page (no cleanup needed). The visibility map bit is set by VACUUM after it processes a page and finds all tuples visible. The bit is cleared when: a DELETE or UPDATE adds a dead tuple to the page, or a tuple's xmax becomes committed (new dead tuple). For Index Only Scans: `EXPLAIN ANALYZE` shows `Heap Fetches: N` - this is the count of pages where the visibility map bit was NOT set, requiring a heap check. High Heap Fetches = infrequent VACUUM."

**Q4: How does MVCC implement Repeatable Read without holding locks?**

🗣️ "Repeatable Read in PostgreSQL: the snapshot is taken at the start of the transaction (first statement). The snapshot records: xmax_horizon (all transactions committed before this point) and xip (active transactions at snapshot time). Every row version check uses this fixed snapshot. When another transaction commits an UPDATE: it creates a new row version with xmin = its XID. This XID is after xmax_horizon or is in xip: the version is NOT visible to the Repeatable Read transaction. The transaction's view of the data does not change. No locks are held on read rows (unlike 2PL Repeatable Read which holds S-locks on all read rows). No contention. The snapshot is the mechanism, not the lock."

**Q5: What is the difference between VACUUM and VACUUM FULL?**

🗣️ "VACUUM: marks dead tuple slots as reusable. Does NOT return disk space to the OS; the space remains in the table's file (used by future inserts). Does NOT compact the table. Runs concurrently (no exclusive lock; reads and writes proceed normally). Essential for: (1) reclaiming slots for new rows; (2) updating the visibility map; (3) advancing the freeze horizon.
VACUUM FULL: rewrites the entire table into a new file, excluding dead tuples. Returns space to the OS (actual file size reduction). Requires an exclusive lock: no reads or writes during the operation. Duration: proportional to table size (potentially hours for large tables). Use: when disk space is genuinely critical AND a maintenance window is available. Never in production without a planned outage window. The compacted table has better cache efficiency (fewer heap pages to scan) after FULL. But the cost is availability during the operation."

**Q6: How does PostgreSQL handle MVCC visibility for system catalogs?**

🗣️ "System catalogs (pg_class, pg_attribute, pg_index, etc.) use MVCC like user tables.
A DDL statement (CREATE TABLE, ALTER TABLE): creates or modifies catalog rows.
The new catalog row has xmin=current_txid. It's not visible until the DDL transaction commits. This is how DDL atomicity works: a partial CREATE TABLE (if it errors mid-way) does not leave a partially-visible catalog state. The DDL transaction rolls back: the catalog rows are never committed. After commit: the schema change is visible to all new transactions. MVCC on system catalogs also means: a long-running transaction takes a snapshot of the catalogs. If a DDL drops a table while the transaction is running: the transaction still sees the table in its catalog snapshot. It can still access the dropped table's data until it commits (or until VACUUM cleans it up)."

**Q7: How do you diagnose and fix table bloat without a maintenance window?**

🗣️ "Without exclusive lock: pg_repack extension. pg_repack creates a new compact copy of the table while the original is live. It tracks changes during the copy using triggers. After the copy is complete: swaps the old and new table atomically (very brief lock). Steps: (1) Install extension: `CREATE EXTENSION pg_repack`. (2) Run: `pg_repack -t orders --no-kill-on-error`. Duration: proportional to table size (reads all rows, inserts into new table). Brief exclusive lock only at the final swap (milliseconds). Alternative: VACUUM FULL equivalent without the long lock. When to use: table is 50%+ dead tuples, autovacuum cannot keep up, disk space is running low, no maintenance window available. Monitor progress: pg_repack outputs progress. The original table remains fully readable and writable throughout."

**Q8: What is the freeze age mechanism and how does it prevent XID wraparound?**

🗣️ "XID wraparound: 32-bit XID counter wraps after ~4B transactions. When new_xid - row_xmin > 2^31: the row appears 'in the future' (invisible). Data corruption. The freeze mechanism: when a row's xmin is old enough (more than `vacuum_freeze_min_age` transactions old, default 50M): VACUUM marks it as frozen. Frozen rows have xmin replaced with FrozenTransactionId (a special value = 2). Frozen rows are visible to ALL transactions regardless of their snapshot. Effectively: frozen rows are "immortally old" (always visible). The freeze horizon advances when VACUUM runs. `relfrozenxid` per table: the oldest non-frozen XID. `age(relfrozenxid)` = how many transactions have elapsed since the oldest non-frozen row. Autovacuum starts freezing aggressively at `autovacuum_freeze_max_age` (default 200M). Manual emergency: `VACUUM FREEZE ANALYZE` runs freeze unconditionally."

**Q9: How does MVCC interact with SERIALIZABLE isolation in PostgreSQL?**

🗣️ "PostgreSQL Serializable uses SSI (Serializable Snapshot Isolation) built on top of MVCC. MVCC provides the snapshot mechanism (each transaction sees a consistent snapshot). SSI adds rw-dependency tracking: a structure called `pg_serial` (not a user-visible table) tracks which transactions read data that other transactions wrote. When T1 reads data that T2 will write (or writes data T2 already read): a rw-anti-dependency is recorded. At commit time: SSI checks if the accumulated dependencies form a cycle (T1 depends on T2 depends on T1 = cycle). If a cycle is found: one transaction is aborted (serialization failure, SQLSTATE 40001). No locks on read rows (unlike 2PL). Readers are never blocked. The overhead: in-memory tracking of rw-dependencies. For read-only transactions: no abort possible (they contribute no writes to the cycle). High read volume does not cause serialization failures. Only read-write transactions can form cycles."

**Q10: How do you handle a bloated index after heavy updates?**

🗣️ "Index bloat: indexes accumulate dead entries for deleted/updated row versions, similar to heap bloat. Index dead entries are not immediately removed by VACUUM (VACUUM marks them for reuse but does not compact). Detection: `pgstattuple` extension:
`SELECT * FROM pgstattuple('idx_orders_customer')`. Shows: `dead_leaf_percent` (dead index entries as % of total). High dead_leaf_percent: index scans are slower (more pages to traverse). Fix: (1) REINDEX INDEX CONCURRENTLY idx_orders_customer (PG12+). Rebuilds the index from scratch while reads proceed normally. Brief lock only at the swap. Duration: proportional to index size. (2) In older PostgreSQL: REINDEX INDEX (requires exclusive lock). (3) pg_repack also rebuilds indexes. Preventive: ensure autovacuum runs frequently enough that index entries are cleaned lazily. The `VACUUM` (not VACUUM FULL) marks index dead entries for reuse during the next access. Over time, index bloat stabilizes if VACUUM runs frequently."

**Q11: What happens to MVCC visibility for rows in a failed transaction?**

🗣️ "When a transaction is aborted (ROLLBACK or error): its row versions remain on disk (PostgreSQL does not immediately undo the writes). The row versions have xmin=aborted_txid. The abort is recorded in the commit log (pg_xact): a 2-bit record per transaction (committed/aborted/in-progress/subxact-committed). When another transaction evaluates visibility: if xmin is in pg_xact as aborted: the row version is invisible (treated as if it never existed). The 'hint bits' optimization: after checking pg_xact and finding the transaction aborted: the row's infomask is updated to mark xmin as 'aborted'. Subsequent visibility checks use the hint bit directly (no pg_xact lookup). VACUUM eventually removes rows with aborted xmin (they are dead, no transaction can see them)."

**Q12: How do you size and monitor shared_buffers and its interaction with MVCC?**

🗣️ "shared_buffers: PostgreSQL's in-memory buffer pool. All heap and index page reads go through shared_buffers. For MVCC: when VACUUM processes dead tuples, it reads heap pages into shared_buffers. When active transactions read data, they read from shared_buffers (if cached) or disk (if not). Sizing: typically 25% of total RAM for dedicated PostgreSQL servers. For a 32GB server: shared_buffers=8GB. Check hit ratio: `SELECT sum(blks_hit) / (sum(blks_hit) + sum(blks_read)) AS cache_hit_ratio FROM pg_stat_database`. Target: > 95% hit ratio. For MVCC specifically: if shared_buffers is too small: VACUUM must constantly re-read pages from disk (slow VACUUM). And active queries read more disk I/Os (stale data not cached). Monitor: `pg_statio_user_tables` - `heap_blks_hit` vs `heap_blks_read`. High `heap_blks_read` on a hot table: increase shared_buffers or reduce table bloat."

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*



