---
layout: default
title: "Database SQL - L3 Query Optimization"
parent: "Database SQL"
grand_parent: "SK Interview"
nav_order: 14
permalink: /database-sql/l3-query-optimization/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Query Optimizer - Statistics, Cardinality, and Plan Selection](#query-optimizer---statistics-cardinality-and-plan-selection) | medium |
| 2 | [Partitioning Strategies - Range, List, and Hash Partitioning](#partitioning-strategies---range-list-and-hash-partitioning) | medium |

---

# Query Optimizer - Statistics, Cardinality, and Plan Selection

**TL;DR:** The query optimizer is a cost-based planner. It uses statistics
(column value distributions, table sizes, index presence) to estimate the
cost of different execution plans and chooses the cheapest one. Wrong statistics
(stale ANALYZE, low sample rate) cause bad plans. Cardinality estimation errors
compound through JOINs. EXPLAIN ANALYZE reveals the planned vs. actual row counts.

---

### 🎯 Model Answer

**30 seconds:**
> The optimizer estimates the cost of every possible plan using statistics about
> table and column distributions. It picks the cheapest estimated plan. Bad plans
> come from stale or insufficient statistics. Fix with `ANALYZE tablename` or
> increase `default_statistics_target`. EXPLAIN ANALYZE shows the actual vs.
> estimated row counts - a large discrepancy means wrong statistics.

**3 minutes:**
> The query optimizer follows these steps:
> (1) Parse the SQL into an abstract syntax tree.
> (2) Rewrite: apply transformations (e.g., convert subqueries to JOINs).
> (3) Planning: generate multiple possible execution plans. For each plan:
> estimate the cost using statistics from `pg_statistic`.
> (4) Select the plan with the lowest estimated cost.
>
> Statistics: `pg_statistic` stores, per column: the number of distinct values
> (n_distinct), most common values (MCVs) and their frequencies, and a histogram
> for the rest. The optimizer uses these to estimate selectivity: what fraction
> of rows will a given predicate match?
>
> Cardinality estimation: the estimated row count at each step. If `WHERE status = 'ACTIVE'`
> is estimated to match 10 rows but actually matches 100,000: the optimizer
> chose a plan optimized for 10 rows. For 10 rows: Nested Loop Join is optimal.
> For 100,000 rows: Hash Join is optimal. The wrong plan is chosen.

**Blank Mind Recovery:**

**(1) Restate:** "Optimizer: cost-based planner. Uses pg_statistic (column distributions)
to estimate rows. Wrong estimate -> wrong plan. Fix: ANALYZE. Diagnose: EXPLAIN ANALYZE."

**(2) First principles:** "SQL is declarative. The optimizer decides HOW to execute it.
Good optimizer = fast queries. Bad statistics = wrong decisions."

**(3) Bridge:** "Like GPS route planning. The GPS estimates travel time using traffic data.
Stale traffic data (statistics not updated) -> GPS estimates 10 minutes but it takes 1 hour.
It chose the 'fastest' route based on wrong information."

---

### 📘 Concept Explanation

**Statistics objects in PostgreSQL:**

```sql
-- View statistics for a table:
SELECT
    attname,
    n_distinct,      -- distinct values (-1 = unique)
    correlation,     -- physical vs logical order (1=perfect)
    most_common_vals,
    most_common_freqs,
    histogram_bounds
FROM pg_stats
WHERE tablename = 'orders';

-- Key fields:
-- n_distinct:   number of distinct values in column
--               -1 = approximately unique (like id)
--               positive int = count of distinct values
-- correlation:  how well physical order matches logical order
--               1.0 = perfectly correlated (sorted on disk)
--               0.0 = random order
--               affects index scan efficiency
-- most_common_vals: top-N values (N = statistics_target)
-- histogram_bounds: bucket boundaries for the rest
```

> **Code walkthrough:** This Statistics, Cardinality, and Plan Selection example demonstrates query execution using SQL. **KEY MECHANISM:** the query planner builds an execution plan based on table statistics and indexes. **WHY IT MATTERS:** SELECT * reads all columns even if only 2 are needed - widens rows, increases I/O. **TAKEAWAY: always SELECT only the columns you need; index the columns in WHERE and JOIN clauses.**

**Statistics target:**

```sql
-- Default statistics target: 100 (controls histogram buckets
-- and MCV count collected by ANALYZE)
-- Higher target = better estimates, slower ANALYZE

-- For a column with very uneven distribution:
ALTER TABLE orders
    ALTER COLUMN status
    SET STATISTICS 500;  -- more detail for status column

ANALYZE orders;  -- recompute with higher target
-- Now the optimizer has better cardinality estimates for
-- WHERE status = 'PENDING' (rare) vs 'COMPLETED' (common)
```

> **Code walkthrough:** This Statistics, Cardinality, and Plan Selection example demonstrates SQL pattern. **KEY MECHANISM:** the database parses, plans, and executes the query; EXPLAIN ANALYZE shows the actual plan. **WHY IT MATTERS:** missing WHERE clause on UPDATE/DELETE affects all rows - no undo without a transaction rollback. **TAKEAWAY: always test destructive SQL in a transaction; use EXPLAIN ANALYZE before deploying.**

---

### 💻 Code Example

```sql
-- DIAGNOSING: EXPLAIN ANALYZE rows mismatch

-- The problem query (slow at certain times)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT COUNT(*) FROM orders
WHERE tenant_id = 42
  AND status = 'PENDING'
  AND created_at > NOW() - INTERVAL '7 days';

-- BAD output (statistics stale):
-- Index Scan using idx_orders_tenant
--   (cost=0.43..12.33 rows=3 width=0)
--   (actual time=0.154..45.823 rows=98432)
-- ^^^^^^^^^^^^                 ^^^^^^^^^^^
-- Estimated: 3 rows            Actual: 98,432 rows
-- The optimizer thinks 3 rows. Chose index scan.
-- For 98,432 rows: should use a different plan.

-- DIAGNOSE: check statistics age
SELECT last_analyze, last_autoanalyze, n_live_tup, n_dead_tup
FROM pg_stat_user_tables
WHERE relname = 'orders';
-- If last_analyze was 2 weeks ago and n_live_tup is 10M:
-- Statistics are stale.

-- FIX: update statistics
ANALYZE orders;
-- Or: vacuum analyze orders (also cleans dead tuples)
VACUUM ANALYZE orders;

-- VERIFY: re-run EXPLAIN ANALYZE
-- Good output (fresh statistics):
-- Bitmap Heap Scan on orders
--   (cost=1243.82..8842.33 rows=95000 width=0)
--   (actual time=8.452..42.123 rows=98432)
-- Estimated: 95,000  Actual: 98,432  -> close enough
-- Optimizer chose Bitmap Heap Scan (correct for large result)
```

> **Code walkthrough:** The `rows=3` estimate vs `rows=98432` actual is aice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> 32,000x estimation error. The optimizer chose an Index Scan, which is
> optimal for 3 rows (few random I/Os) but terrible for 98,432 rows (98,432
> random I/Os - much worse than a sequential scan). After `ANALYZE`:
> the statistics accurately reflect the distribution. The optimizer now
> estimates ~95,000 rows and correctly chooses a Bitmap Heap Scan (sorts
> the row locations, then reads heap pages in order - better I/O efficiency
> for large result sets). The fix requires no query or index changes - just
> fresh statistics.

```sql
-- MULTI-COLUMN STATISTICS: correlated column distributions

-- Problem: status and priority are correlated.
-- Almost all 'URGENT' orders have status = 'PENDING'.
-- Optimizer treats them as independent.
-- Estimates: p(status='PENDING') * p(priority='URGENT')
--          = 0.30 * 0.05 = 0.015 (1.5%)
-- Actual: status='PENDING' AND priority='URGENT' = 0.04 (4%)
-- -> Optimizer underestimates by 3x

-- FIX: create extended statistics (PostgreSQL 10+)
CREATE STATISTICS stat_orders_status_priority
    (dependencies, ndistinct)
    ON status, priority
    FROM orders;

ANALYZE orders;
-- Now the optimizer knows about the correlation between
-- status and priority. Better joint estimates.

-- Verify:
SELECT * FROM pg_stats_ext
WHERE statistics_name = 'stat_orders_status_priority';
```

> **Code walkthrough:** The optimizer assumes columns are statisticallyice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> independent when computing multi-predicate selectivity. In reality:
> `status` and `priority` are correlated (URGENT orders are almost always
> PENDING). The optimizer multiplies the individual selectivities, underestimating
> the combined result. `CREATE STATISTICS ... (dependencies)` tells PostgreSQL
> to track column correlations. After ANALYZE: the optimizer uses the actual
> joint distribution for queries with both predicates. For plans where this
> estimate is the tipping point between a Seq Scan and Index Scan: correct
> statistics make the difference between a 5ms and a 5-second query.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> The query optimizer uses statistics about table and column distributions to
> estimate the cost of different execution plans and picks the cheapest. Stale
> statistics (from infrequent ANALYZE) cause the optimizer to choose wrong plans.
> Diagnose with EXPLAIN ANALYZE: compare estimated rows vs. actual rows. Fix
> with `ANALYZE tablename`.

---

**Senior / Staff:**
> Statistics quality is the most impactful optimizer tuning lever. For high-cardinality
> columns with skewed distributions: increase `statistics_target` for that column.
> For correlated columns in compound predicates: create extended statistics
> (`CREATE STATISTICS ... (dependencies, ndistinct)`). For very large tables
> where ANALYZE is too slow: use table sampling (`ANALYZE tablename (column1, column2)`
> or increase `default_statistics_target` selectively). Monitor `pg_stat_user_tables`
> for `last_autoanalyze` - if it's days old for a frequently-updated table:
> autovacuum configuration needs tuning.

---

### ⚠️ Common Misconceptions

**"EXPLAIN and EXPLAIN ANALYZE show the same plan"**

Reality: `EXPLAIN` shows the estimated plan based on statistics without executing
the query. `EXPLAIN ANALYZE` actually executes the query and shows both the
estimated and actual row counts. The actual numbers are the only way to detect
statistics problems. `EXPLAIN` alone can be misleading: a plan that looks
reasonable based on estimates might be wrong.

**"Higher statistics_target is always better"**

Reality: higher statistics_target means more samples during ANALYZE
(slower ANALYZE) and a larger `pg_statistic` entry per column
(more memory for planning). Only increase for columns that are:
(a) used in WHERE predicates, (b) have skewed distributions, (c) causing
bad plan choices. The overhead of global statistics_target=1000 is significant.
Increase selectively per-column.

---

### ⚖️ Comparison Table

| Issue | Symptom in EXPLAIN ANALYZE | Fix |
|---|---|---|
| Stale statistics | Large rows estimate vs actual gap | ANALYZE table |
| Correlated columns | Estimate too low for multi-predicate | CREATE STATISTICS (dependencies) |
| Low statistics_target | Histogram too coarse for rare values | ALTER COLUMN ... SET STATISTICS 500 |
| Index not used | Seq Scan despite index on filtered column | ANALYZE; check index vs table size ratio |
| Wrong join order | Nested Loop on large tables | ANALYZE; consider join_collapse_limit |

---

### 🏛️ System Design

*(Omit: L3 keyword - optimizer tuning strategy at production scale covered in L4)*

---

### 📊 Diagram

*(Omit: optimizer pipeline illustrated clearly in code examples)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Autovacuum not keeping statistics current on high-insert tables**

Symptom: `last_autoanalyze` in `pg_stat_user_tables` is hours or days old.
Queries have large rows estimate vs actual gaps.

Cause: default autovacuum thresholds are relative (autovacuum triggers when
20% of rows have changed). For a 100M-row table: 20% = 20M changes needed.
Statistics may be days old during high-insert periods.

Fix: lower the threshold for important tables:
```sql
ALTER TABLE orders SET (
    autovacuum_analyze_scale_factor = 0.01,  -- 1% (not 20%)
    autovacuum_analyze_threshold = 1000
);
```

> **Code walkthrough:** This Unknown example demonstrates SQL pattern. **KEY MECHANISM:** the database parses, plans, and executes the query; EXPLAIN ANALYZE shows the actual plan. **WHY IT MATTERS:** missing WHERE clause on UPDATE/DELETE affects all rows - no undo without a transaction rollback. **TAKEAWAY: always test destructive SQL in a transaction; use EXPLAIN ANALYZE before deploying.**

---

### 🎯 Interview Deep-Dive

**[JUNIOR] Q1 - [MECHANISM] How does the query optimizer use column histograms?**

🗣️ "Histogram: a bucket representation of column value distribution. For a
`created_at` column with values spanning 1 year: the histogram divides
values into N buckets (N = statistics_target). Each bucket boundary is stored.
For a predicate `WHERE created_at > '2024-06-01'`: the optimizer counts how
many histogram buckets fall above the threshold. Fraction of buckets above
threshold * table row count = estimated rows. The histogram is most accurate
for uniformly distributed data. For highly skewed data (most values in one
bucket): the histogram coarsely estimates. MCVs (most common values) handle
the skewed case: the top-N values and their exact frequencies are stored
separately. The optimizer checks MCVs first, then falls back to histogram
for non-MCV values."

**[JUNIOR] Q2 - [MECHANISM] What are plan-affecting PostgreSQL configuration settings?**

🗣️ "Key settings: `enable_seqscan` (bool, default on): enables sequential scans.
`enable_indexscan`, `enable_bitmapscan`: enable respective scan types.
`enable_hashjoin`, `enable_mergejoin`, `enable_nestloop`: enable join types.
Turning off a method: cost is set to infinity (effectively disables it).
Use for debugging only. `random_page_cost` (default 4.0): relative cost of
a random disk read vs. sequential read (1.0). For SSDs: set to 1.1-1.5 (random
reads are nearly as fast as sequential). Lower `random_page_cost` makes the
optimizer more likely to choose index scans. `effective_cache_size`: optimizer's
estimate of how much of the working set fits in OS page cache. Larger value:
index scans are cheaper (cached I/Os). Correct setting: OS RAM minus database
RAM: often `0.5 * total_RAM`. `work_mem`: memory per sort/hash operation.
More work_mem: optimizer chooses in-memory Hash Join over disk-spilling Merge Join."

**[JUNIOR] Q3 - [MECHANISM] How does PostgreSQL handle the join order selection for 4+ table queries?**

🗣️ "For up to `join_collapse_limit` (default 8) tables: the optimizer uses dynamic
programming to evaluate join orders. For N tables: O(N!) possible orderings.
For 8 tables: 40,320 orderings. Dynamic programming uses memoization to compute
the optimal order in O(N^2 * 2^N) time. For more than `join_collapse_limit` tables:
the optimizer switches to a genetic algorithm (GEQO) that samples possible plans
rather than exhaustively evaluating all. The optimizer may not find the globally
optimal plan for complex queries. Interventions: (1) reduce `join_collapse_limit`
to restrict reordering (trust the query order); (2) use CTEs to force intermediate
results (PostgreSQL pre-13 always materialized CTEs as barriers); (3) explicit
`SET join_collapse_limit = 1` to test the written query order."

**[MID] Q4 - [DEBUGGING] How do you diagnose a case where EXPLAIN shows a good plan but actual execution is slow?**

🗣️ "Four causes: (1) Statistics are stale: EXPLAIN uses statistics; actual execution
uses real data. If statistics are days old, EXPLAIN's cost estimates are wrong.
EXPLAIN ANALYZE would show the actual rows. Fix: ANALYZE. (2) Lock contention:
the plan is correct, but the query waits for a lock. EXPLAIN ANALYZE shows
actual time includes wait time. Check `pg_locks` and `pg_stat_activity` for blocking.
(3) Disk I/O: EXPLAIN ANALYZE with BUFFERS shows actual blocks read. If Buffers:
read (from disk) is high and hit (from cache) is low: the data is not cached.
Fix: increase `shared_buffers` or `effective_cache_size`. (4) Data skew:
the query plan is optimal for typical data but the specific parameter value
is an outlier. Check if the query is fast with different parameters.
Fix: extended statistics, increased statistics_target, or a custom plan per parameter
value (disable plan caching for that query: `SET plan_cache_mode = force_custom_plan`)."

**[MID] Q5 - [MECHANISM] What is a generic plan vs. a custom plan in PostgreSQL?**

🗣️ "For prepared statements (parameterized queries): PostgreSQL first executes 5 times
using a custom plan (plan generated for the specific parameter values). On the 6th
execution: if the generic plan (plan without substituting parameters) is not much more
expensive than the average custom plan cost: PostgreSQL switches to the generic plan
and caches it. Subsequent executions use the cached generic plan without re-planning.
Problem: for a column with extreme skew (e.g., 99% of rows have status='COMPLETED',
1% have status='PENDING'): the generic plan uses average statistics. A query for
status='PENDING' (rare) gets the same plan as status='COMPLETED' (common). The wrong
plan for 1% of queries. Fix: `SET plan_cache_mode = force_custom_plan` for that
session, or use `EXECUTE` (instead of prepared statements) to always re-plan."

**[SENIOR] Q6 - [MECHANISM] How do query hints in pg_hint_plan work?**

🗣️ "`pg_hint_plan` extension (not built-in): allows SQL-comment-based hints.
`/*+ IndexScan(orders idx_orders_customer) */` forces an index scan on orders
using the specified index. `/*+ HashJoin(orders customers) */` forces hash join.
Available hints: scan methods (SeqScan, IndexScan, BitmapScan), join methods
(NestLoop, HashJoin, MergeJoin), join order (Leading(t1 t2 t3)), row count
(Rows(t1 #1000000)). Use cases: (1) temporary fix while the root cause
(statistics, missing index) is being diagnosed; (2) a single high-value query
where the optimizer consistently makes the wrong choice despite correct statistics.
Never use hints as permanent solutions: they become stale when data distribution
or indexes change. Always investigate why the optimizer made the wrong choice."

**[SENIOR] Q7 - [MECHANISM] How do you tune autovacuum to keep statistics fresh for a high-churn table?**

🗣️ "Default autovacuum thresholds: `autovacuum_analyze_scale_factor=0.20` (trigger
after 20% of rows changed). For a 10M-row table: 2M changes trigger ANALYZE.
For 1,000 inserts/second: ANALYZE runs every ~33 minutes. For faster tables:
tune per-table settings:
`ALTER TABLE orders SET (autovacuum_analyze_scale_factor = 0.01, autovacuum_analyze_threshold = 10000)`.
This triggers ANALYZE after 1% changes or 10,000 changes, whichever is more.
Also check: `autovacuum_vacuum_cost_delay` - default 2ms pause between cost units.
High vacuum cost delay = ANALYZE takes longer, runs less frequently.
Set lower for critical tables: `autovacuum_vacuum_cost_delay = 0` (no throttle).
Monitor with: `pg_stat_user_tables`: `n_live_tup`, `n_dead_tup`, `last_autoanalyze`."

---

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


# Partitioning Strategies - Range, List, and Hash Partitioning

**TL;DR:** Table partitioning divides a large table into smaller physical partitions
based on a partition key. Range partitioning: by date range (common for time-series).
List partitioning: by discrete values (region, status). Hash partitioning: by hash
of the key (even distribution). Benefits: partition pruning (queries touch only
relevant partitions), faster maintenance, smaller indexes.

---

### 🎯 Model Answer

**30 seconds:**
> Partitioning splits a large table into smaller partitions based on a key.
> Range: by date ranges. List: by discrete values. Hash: by hash of the key.
> The planner uses partition pruning to scan only relevant partitions.
> Best use case: large tables with time-based queries where only recent data
> is accessed (range partition by date -> prune old partitions).

**3 minutes:**
> The three partitioning types and their strengths:
> (1) Range: partition by date (monthly, yearly). Each partition contains rows
> where the partition key falls in a range. Query `WHERE created_at > '2024-01-01'`
> prunes all partitions before 2024. Old partitions can be dropped (DROP TABLE on
> partition, not DELETE: instant).
> (2) List: partition by discrete value (country='US', country='EU').
> Query `WHERE country = 'US'` scans only the US partition.
> (3) Hash: compute `hash(partition_key) % N`. Distributes rows evenly across N
> partitions. No specific partition is targeted by queries (hash partitioning
> does not prune by value); purpose is to split the table into equal physical pieces
> for better parallelism and maintenance.
>
> Key benefits: (1) Partition pruning: the planner skips irrelevant partitions.
> (2) Partition management: drop old partitions (instant) instead of DELETE
> (expensive). (3) Smaller indexes per partition (faster builds and lookups).

**Blank Mind Recovery:**

**(1) Restate:** "3 types: Range (date range), List (discrete values), Hash (even split).
Benefit: pruning (only relevant partition scanned). DROP old partitions for data retention."

**(2) First principles:** "Large table has too many rows to scan efficiently.
Partitioning: physically separate rows by a key. Queries that filter on the key:
only scan the relevant partition(s). Like filing cabinets: January to December."

**(3) Bridge:** "Like a library sorted by year published. Need books from 2020:
go directly to the 2020 shelf. Don't scan all books. That's range partition pruning."

---

### 📘 Concept Explanation

**PostgreSQL declarative partitioning syntax:**

```sql
-- Parent (partitioned) table:
CREATE TABLE orders (
    id          BIGSERIAL,
    tenant_id   INTEGER NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL,
    status      TEXT NOT NULL,
    total_cents BIGINT NOT NULL
) PARTITION BY RANGE (created_at);

-- Range partitions (one per month/year):
CREATE TABLE orders_2024_01
    PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02
    PARTITION OF orders
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Default partition (catches unmatched rows):
CREATE TABLE orders_default
    PARTITION OF orders DEFAULT;

-- Each partition is a real table:
-- Has its own indexes, statistics, storage settings.
-- Can be analyzed/vacuumed independently.
```

> **Code walkthrough:** This Range, List, and Hash Partitioning example demonstrates index structure. **KEY MECHANISM:** B-tree indexes support equality and range queries; partial indexes reduce index size. **WHY IT MATTERS:** index on low-cardinality column (e.g., boolean) is often slower than sequential scan. **TAKEAWAY: add indexes based on EXPLAIN ANALYZE output, not guesses - unused indexes waste write I/O.**

---

### 💻 Code Example

```sql
-- RANGE PARTITIONING: time-series orders

-- BAD: single table with 500M rows (all time)
-- WHERE created_at > NOW() - INTERVAL '30 days'
-- -> Seq Scan or Bitmap Heap Scan on 500M rows
-- -> Maintenance: DELETE old rows is slow (each has a MVCC version)
-- -> VACUUM must process all 500M rows

-- GOOD: range-partitioned table
CREATE TABLE orders (
    id          BIGSERIAL,
    tenant_id   INTEGER NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL,
    status      TEXT NOT NULL,
    total_cents BIGINT NOT NULL
) PARTITION BY RANGE (created_at);

-- Create partitions for each quarter:
CREATE TABLE orders_q1_2024 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE orders_q2_2024 PARTITION OF orders
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');
CREATE TABLE orders_q3_2024 PARTITION OF orders
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');
CREATE TABLE orders_q4_2024 PARTITION OF orders
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

-- Create index ON each partition (or globally):
CREATE INDEX ON orders (tenant_id, created_at);
-- PostgreSQL auto-creates idx on all partitions.

-- Query - EXPLAIN shows partition pruning:
EXPLAIN SELECT * FROM orders
WHERE created_at >= '2024-07-01'
  AND created_at < '2024-10-01';
-- Output:
-- Append
--   -> Seq Scan on orders_q3_2024
-- ONLY the Q3 partition is scanned.
-- Q1, Q2, Q4 are pruned.

-- Retention: drop the oldest partition instantly
ALTER TABLE orders DETACH PARTITION orders_q1_2024;
DROP TABLE orders_q1_2024;
-- Instant: no row-by-row DELETE, no VACUUM needed.
```

> **Code walkthrough:** Without partitioning: `WHERE created_at >= '2024-07-01'`ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> on a 500M-row table scans the entire table even with an index (the index range
> scan still reads 500M index entries to find the matching 10M). With range
> partitioning: the planner evaluates the partition bounds at plan time.
> `'2024-07-01' TO '2024-10-01'` exactly matches Q3_2024. EXPLAIN shows
> only `orders_q3_2024` in the plan - the other partitions are pruned.
> Retention: `DETACH PARTITION` removes the partition from the parent table
> (instant metadata change). `DROP TABLE` deletes the physical file (instant
> at the OS level for most filesystems). A traditional `DELETE WHERE created_at < '2024-04-01'`
> on 10M rows: slow, generates dead tuples, requires VACUUM.

```sql
-- LIST PARTITIONING: by region for data locality

CREATE TABLE customers (
    id        BIGSERIAL,
    region    TEXT NOT NULL,
    name      TEXT NOT NULL,
    email     TEXT NOT NULL
) PARTITION BY LIST (region);

CREATE TABLE customers_us
    PARTITION OF customers FOR VALUES IN ('US', 'CA', 'MX');
CREATE TABLE customers_eu
    PARTITION OF customers FOR VALUES IN ('DE', 'FR', 'UK');
CREATE TABLE customers_apac
    PARTITION OF customers FOR VALUES IN ('JP', 'AU', 'SG');
CREATE TABLE customers_default
    PARTITION OF customers DEFAULT;

-- Query for US customers:
SELECT * FROM customers WHERE region = 'US';
-- EXPLAIN: Seq Scan on customers_us only.
-- EU and APAC partitions pruned.

-- Move each partition to a different tablespace
-- (on different disks, for physical data locality):
ALTER TABLE customers_eu
    SET TABLESPACE eu_storage;
-- EU customer data physically on EU storage node.
-- GDPR compliance: EU data stays in EU tablespace.
```

> **Code walkthrough:** List partitioning by `region` enables two things:ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> (1) Query pruning: a query for US customers only touches `customers_us`.
> (2) Physical data placement: each partition can be on a different tablespace
> (different disks or storage locations). For GDPR compliance: EU customer data
> on EU-region storage. The `DEFAULT` partition catches any regions not listed
> (e.g., a new region added before a partition is created). Without a DEFAULT:
> an INSERT with an unlisted region value fails.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Partitioning splits a large table into physical sub-tables based on a key.
> Three types: Range (dates), List (discrete values), Hash (even distribution).
> Key benefit: partition pruning - queries that filter on the partition key
> scan only the relevant partition. Also enables fast data retention (drop old
> partitions instead of DELETE).

---

**Senior / Staff:**
> Partitioning is justified when a table exceeds ~100-200M rows and queries have
> selective time or category filters. The partition key must be in the WHERE clause
> of most queries (otherwise: no pruning, just overhead). Partition management:
> create future partitions in advance (pg_partman automates this). Watch for
> cross-partition queries (no pruning): e.g., `WHERE tenant_id = ?` on a date-partitioned
> table scans all partitions. If both tenant_id and date are in most queries: consider
> sub-partitioning or composite partition key. The hidden cost: global indexes
> across all partitions are not supported; each partition has its own indexes.

---

### ⚠️ Common Misconceptions

**"Partitioning always speeds up queries"**

Reality: partitioning speeds up queries ONLY when the query filters on the
partition key (partition pruning). A query with no filter on the partition key:
scans all partitions (actually slower than a single-table scan due to planning
overhead for many partitions). For a date-partitioned table: a query without
a date filter scans all date partitions. More overhead, not less.

**"Hash partitioning enables partition pruning"**

Reality: hash partitioning does NOT enable query-level pruning by value.
Hash partitioning is for even distribution (load balancing) and parallelism,
not for pruning. A query `WHERE id = 42` with a hash partition on id:
the planner computes `hash(42) % N = partition_index` and scans only that
partition - this IS partition pruning. But for range queries or LIKE: hash
provides no pruning.

---

### ⚖️ Comparison Table

| Strategy | Partition By | Pruning For | Use Case |
|---|---|---|---|
| Range | Date or numeric range | WHERE date > '2024-01-01' | Time-series, logs, events |
| List | Discrete values | WHERE region = 'US' | Categorical, regional data |
| Hash | Hash(key) % N | WHERE key = exact value | Even distribution, parallelism |
| Sub-partitioning | Two keys | WHERE date=? AND region=? | Both time and category filters |

---

### 🏛️ System Design

*(Omit: L3 keyword - partitioning at distributed scale covered in L5 Scalability)*

---

### 📊 Diagram

*(Omit: partition structure illustrated clearly in code examples)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Queries suddenly become slow after adding partitions**

Symptom: a query that was fast on a 5-partition table is slow on a 100-partition table.

Cause: PostgreSQL's planner evaluates each partition's constraints at plan time.
For 100 partitions: the planner performs 100 constraint evaluations even for
pruned queries. Planning time increases with partition count.

Diagnosis:
```sql
EXPLAIN (ANALYZE, TIMING) SELECT * FROM orders WHERE created_at > '2024-01-01';
-- Look at "Planning time" vs "Execution time".
-- High planning time with many partitions = constraint evaluation overhead.
```

> **Code walkthrough:** This Unknown example demonstrates query execution using SQL. **KEY MECHANISM:** the query planner builds an execution plan based on table statistics and indexes. **WHY IT MATTERS:** SELECT * reads all columns even if only 2 are needed - widens rows, increases I/O. **TAKEAWAY: always SELECT only the columns you need; index the columns in WHERE and JOIN clauses.**

Fix: PostgreSQL 12+ has improved partition pruning. Keep partition count under 1000.
For time-series: monthly or quarterly partitions (not daily).

---

### 🎯 Interview Deep-Dive

**[JUNIOR] Q1 - [MECHANISM] What is partition pruning and when does it NOT work?**

🗣️ "Partition pruning: the planner removes irrelevant partitions from the execution plan.
For range partition on `created_at`: `WHERE created_at > '2024-01-01'` - planner
checks each partition's bounds: partitions with max bound <= '2024-01-01' are excluded.
When pruning does NOT work: (1) no filter on the partition key (query without date filter);
(2) function applied to partition key: `WHERE EXTRACT(YEAR FROM created_at) = 2024`
is not prunable (function wraps the key). Use `WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01'` instead; (3) dynamic value that the planner cannot evaluate at plan time:
prepared statements with parameters may disable pruning at plan time (but enable
at execution time - `enable_partition_pruning=on` for runtime pruning). PostgreSQL 12+:
`enable_partition_pruning=on` enables both plan-time and execution-time pruning."

**[JUNIOR] Q2 - [MECHANISM] How do you manage partition creation for ongoing time-series data?**

🗣️ "Manual partition creation: create future partitions in advance. For a monthly
partition scheme: create the next 3 months at the beginning of each month.
If a partition for the current month does not exist: INSERTs fail (no DEFAULT
partition) or go to DEFAULT (then must be moved). Automated: pg_partman extension.
Defines a partition interval (daily, monthly, yearly). Auto-creates future partitions
and auto-drops old ones past the retention period. Commands:
`SELECT partman.create_parent('public.orders', 'created_at', 'native', 'monthly')` - sets up management.
`SELECT partman.run_maintenance()` - run periodically (cron) to create new partitions.
For production: set up pg_partman at table creation time, before data arrives.
Monitoring: alert if the partition for the next period does not exist (inserts
would fail or go to DEFAULT)."

**[JUNIOR] Q3 - [MECHANISM] How does partitioning interact with foreign keys?**

🗣️ "PostgreSQL supports foreign key references TO a partitioned table (the FK
references the parent). Rows are stored in the correct partition.
Constraint: each partition enforces its portion of the FK constraint.
Foreign key references FROM a partitioned table TO another table: supported.
The constraint is on the partition, but references the parent.
One IMPORTANT limitation: a partitioned table cannot have a foreign key that
references a non-partitioned table if the foreign key column is the partition key.
Use case impact: if orders are partitioned by date and reference customers(id):
the FK is on customer_id, not on created_at - this is fine. If orders reference
a partitioned products table: both sides can be partitioned. Practical limitation:
ON DELETE CASCADE on a large partitioned table can be very slow (cascades through
all partitions). Consider using application-level soft-delete instead."

**[MID] Q4 - [TRADE-OFF] What is the difference between declarative partitioning and inheritance partitioning?**

🗣️ "Inheritance partitioning (pre-PG10): manual. Define a parent table, child tables
inherit columns. Manually add CHECK constraints and exclusion constraints for pruning.
The planner uses constraint exclusion (not partition pruning) to skip children.
Must manually maintain insert rules or triggers to route rows. Complex and error-prone.
Declarative partitioning (PG10+): `PARTITION BY RANGE/LIST/HASH`. PostgreSQL manages
routing, constraint enforcement, and partition pruning automatically. INSERT into
the parent: automatically routed to the correct partition. Global indexes: not supported
in declarative (each partition has its own index). Inheritance: can have global indexes
(but they are slower). Recommendation: always use declarative partitioning for new tables.
Migrate inheritance partitions to declarative when possible."

**[MID] Q5 - [SCENARIO] How do sub-partitioning work and when should you use it?**

🗣️ "Sub-partitioning: a partition is itself partitioned. Example: orders partitioned
by year (range), each year partition sub-partitioned by region (list).
`CREATE TABLE orders_2024 PARTITION OF orders FOR VALUES FROM ('2024-01-01') TO ('2025-01-01') PARTITION BY LIST (region)`.
Then: `CREATE TABLE orders_2024_us PARTITION OF orders_2024 FOR VALUES IN ('US')`.
Query `WHERE created_at >= '2024-01-01' AND region = 'US'` prunes to `orders_2024_us` only.
Use sub-partitioning when: (1) the table has two high-selectivity filter dimensions
that are both present in most queries; (2) data retention is by date but
data isolation is by region (GDPR: each partition in its own tablespace).
Overhead: planning time increases with depth. Keep the partition tree flat
(max 2 levels) for practical use."

**[SENIOR] Q6 - [MECHANISM] How does parallel query work with partitioned tables?**

🗣️ "PostgreSQL can execute partition scans in parallel (PG11+ parallel append).
For `SELECT COUNT(*) FROM orders WHERE status = 'PENDING'` with no partition key filter:
all partitions are scanned. With parallel query: each partition is assigned to a
worker. `max_parallel_workers_per_gather` workers each scan a partition.
Speedup: proportional to min(partition count, max_parallel_workers_per_gather).
For 12 monthly partitions and 4 workers: each worker handles 3 partitions.
4x parallelism.
Also: `VACUUM` on a partitioned table can run in parallel (each partition is a
separate VACUUM job). Maintenance parallelism is a key operational benefit for
large partitioned tables. Configure: `max_parallel_maintenance_workers` for vacuum."

**[SENIOR] Q7 - [MECHANISM] How do you migrate an existing large unpartitioned table to a partitioned scheme?**

🗣️ "Step 1: create the new partitioned table with a different name:
`CREATE TABLE orders_new (...) PARTITION BY RANGE (created_at)`.
Step 2: create partitions for the historical data range.
Step 3: migrate data in batches (avoid long locks):
`INSERT INTO orders_new SELECT * FROM orders WHERE created_at >= '2024-01-01' AND created_at < '2024-02-01'` for each month.
Step 4: for new incoming rows: use a trigger on `orders` to also write to `orders_new`.
Step 5: after all historical data is migrated: switch the application to read from `orders_new`.
Step 6: rename: `ALTER TABLE orders RENAME TO orders_old; ALTER TABLE orders_new RENAME TO orders`.
Step 7: validate row counts match. Drop `orders_old`.
This is the expand-contract / dual-write migration pattern. Zero-downtime.
Alternative for zero-downtime: `pg_partman` has a migration mode that wraps the old table."

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



