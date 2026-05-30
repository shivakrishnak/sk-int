---
layout: default
title: "Database SQL - L2 Indexing Basics"
parent: "Database SQL"
grand_parent: "SK Interview"
nav_order: 7
permalink: /database-sql/l2-indexing-basics/
render_with_liquid: false
---

# Database Indexes - How They Speed Up Queries

**TL;DR:** An index is a separate data structure that enables fast row
lookup without scanning every row. The default B-tree index stores
column values in sorted order. Reads are O(log n). Without an index:
a WHERE query on a large table does a full sequential scan O(n).
The trade-off: indexes make reads faster but slow down writes.

---

### 🎯 Model Answer

**30 seconds:**
> An index is a pre-sorted lookup structure on one or more columns.
> Instead of scanning every row to find matches: the database jumps
> directly to the matching rows using the index. Reads become O(log n)
> instead of O(n). Cost: every INSERT, UPDATE, DELETE must also update
> all indexes on the table. More indexes = slower writes.

**3 minutes:**
> The B-tree index (default in PostgreSQL, MySQL, SQL Server) stores
> column values in a balanced tree. Each node has pointers to child nodes
> and to heap page locations where the actual rows are stored. For an equality
> query `WHERE id = 42`: the database traverses the B-tree from root to leaf
> (3-4 levels for millions of rows), finds the leaf entry for id=42, and
> reads the heap page. Total: 3-4 I/O operations instead of potentially
> millions for a full table scan.
>
> Index selectivity determines whether the optimizer uses it. High
> selectivity (few rows match): index is used. Low selectivity (many rows
> match): sequential scan may be faster because reading index pages plus
> scattered heap pages has higher overhead than reading the heap sequentially.
>
> When to add an index: columns in WHERE clauses on large tables, JOIN
> columns (foreign keys especially), ORDER BY columns for sorted queries,
> columns used in UNIQUE constraints (automatically indexed).
> When NOT to add: small tables (full scan is fast), heavily written tables
> where write overhead matters, low-selectivity columns (status with 2 values).

**Blank Mind Recovery:**

**(1) Restate:** "Index = sorted lookup structure. B-tree default.
Reads O(log n). Writes slower (must update index). Selectivity determines if used."

**(2) First principles:** "An index trades write cost for read speed.
It stores pre-sorted references to rows. The database uses it to skip
most rows and find matches directly."

**(3) Bridge:** "Like a book's index. Instead of reading every page to
find 'transactions': look up 'transactions' in the index, get page numbers,
jump directly. The book index is maintained by the publisher (write overhead),
but saves you hours of reading (read benefit)."

---

### 📘 Concept Explanation

**How a B-tree index is structured:**

```
Table: orders (10 million rows)
Index on: customer_id

B-tree structure (simplified):
           [5000000]
          /         \
    [2500000]     [7500000]
    /       \     /       \
  [1M]   [3M] [6M]    [9M]
  ...

Leaf nodes: sorted entries with heap page pointers
  (cust_id=1001, page=3421, slot=5)
  (cust_id=1002, page=8834, slot=2)
  ...

Query: WHERE customer_id = 1001
  1. Traverse tree from root: 3-4 comparisons
  2. Land on leaf entry for 1001
  3. Follow pointer to heap page 3421, slot 5
  Total: 3-4 I/O, not 10,000,000 row scan
```

**Index types:**

- B-tree: default, supports =, <, >, BETWEEN, LIKE 'prefix%', ORDER BY
- Hash: only equality (=), not ranges. Faster for equality in theory,
  but B-tree is usually preferred (supports more operations)
- GIN: Generalized Inverted Index, for arrays, JSONB, full-text search
- GiST: Generalized Search Tree, for geometric data, range types
- BRIN: Block Range Index, very small, for monotonically increasing columns
  (timestamps on append-only tables)
- Partial index: index only rows matching a WHERE condition

---

### 💻 Code Example

```sql
-- INDEX CREATION: basic patterns

-- Basic single-column index
CREATE INDEX idx_orders_customer_id
    ON orders (customer_id);
-- Speeds up: WHERE customer_id = ?
-- Speeds up: JOIN ... ON orders.customer_id = customers.id

-- Composite index (multi-column)
CREATE INDEX idx_orders_customer_status
    ON orders (customer_id, status);
-- Speeds up: WHERE customer_id = ? AND status = ?
-- Also speeds up: WHERE customer_id = ?
--   (leftmost prefix rule: can use first column alone)
-- Does NOT speed up: WHERE status = ? alone

-- Partial index: only PENDING orders
CREATE INDEX idx_orders_pending
    ON orders (created_at)
    WHERE status = 'PENDING';
-- Smaller index. Only covers PENDING rows.
-- Query must have: WHERE status = 'PENDING'
--   for the partial index to be used.

-- Unique index (also enforces constraint)
CREATE UNIQUE INDEX idx_customers_email
    ON customers (email);
-- Prevents duplicate emails AND speeds up:
-- WHERE email = ?

-- Concurrent index creation (no table lock)
CREATE INDEX CONCURRENTLY idx_orders_created
    ON orders (created_at DESC);
-- Takes longer, but does not block writes.
-- ALWAYS use CONCURRENTLY in production.
```

> **Code walkthrough:** `CREATE INDEX` (without CONCURRENTLY) acquires
> a SHARE lock that blocks concurrent writes for the duration of the build.
> For a 100M-row table this can take minutes - unacceptable in production.
> `CREATE INDEX CONCURRENTLY` builds the index in the background: it takes
> 2-3x longer but allows concurrent inserts/updates/deletes. Always use
> CONCURRENTLY for production index creation. Partial indexes are an
> optimization tool: an index on only 10% of rows (the PENDING orders)
> is 10x smaller, faster to scan, and fits better in the buffer cache.

```sql
-- CHECKING IF AN INDEX IS USED

-- Run EXPLAIN ANALYZE to see the plan:
EXPLAIN ANALYZE
SELECT id, total_cents FROM orders
WHERE customer_id = 42
ORDER BY created_at DESC
LIMIT 10;

-- GOOD output (index used):
-- Index Scan using idx_orders_customer_id on orders
--   (cost=0.56..8.71 rows=10)
--   Index Cond: (customer_id = 42)
--   actual time=0.053..0.089 rows=10 loops=1

-- BAD output (full scan, index NOT used):
-- Seq Scan on orders
--   (cost=0.00..245678.00 rows=10)
--   Filter: (customer_id = 42)
--   Rows Removed by Filter: 9999990
--   actual time=145.23..892.34 rows=10 loops=1

-- WHY the index might not be used:
-- 1. Low selectivity (customer has 50% of all orders)
-- 2. Function on column: WHERE LOWER(email) = ?
-- 3. Table is small (seq scan is faster)
-- 4. Statistics are stale: run ANALYZE orders;
```

> **Code walkthrough:** EXPLAIN ANALYZE is the diagnostic tool for index
> usage. The GOOD output shows "Index Scan using idx_..." - the index was
> used. The BAD output shows "Seq Scan" with "Rows Removed by Filter: 9,999,990"
> meaning the database read 10 million rows to find 10. The execution times
> (0.089ms vs 892ms) show the 10,000x performance difference. After creating
> or modifying data: run `ANALYZE tablename` to update statistics so the
> optimizer has accurate row count estimates.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> An index is a sorted data structure that enables fast lookups without
> scanning every row. The default B-tree index supports =, <, >, BETWEEN,
> and LIKE with a prefix. Create indexes on: foreign key columns, WHERE
> clause columns on large tables, ORDER BY columns. Use CREATE INDEX
> CONCURRENTLY in production to avoid blocking writes. Check if an index
> is being used with EXPLAIN ANALYZE.

---

**Senior / Staff:**
> Index design is a balance: more indexes speed reads but slow writes.
> For high-write tables: every additional index adds overhead to INSERT,
> UPDATE, DELETE (each must update all indexes). My heuristics: (1) every
> foreign key needs an index (join and ON DELETE CASCADE both need it);
> (2) high-cardinality WHERE columns need indexes; (3) partial indexes for
> selective status filters (only PENDING orders); (4) always CONCURRENTLY
> in production. After adding indexes: run `ANALYZE` to refresh statistics.
> Unused indexes should be dropped (they cost write overhead with no read benefit).

---

### ⚠️ Common Misconceptions

**"More indexes are always better"**

Reality: every index adds overhead to writes. An INSERT must update
every index on the table. For a table with 10 indexes, an INSERT is
10x more expensive than for a table with 1 index (for the index update
portion). Unused indexes are purely overhead. PostgreSQL: `pg_stat_user_indexes`
shows index usage counts; drop indexes with 0 scans.

**"An index on a boolean column is useful"**

Reality: a boolean column has 2 values. An index on it has near-zero
selectivity for most queries: `WHERE is_active = true` might return 90%
of rows. The optimizer will prefer a sequential scan. Exception: partial
index. `CREATE INDEX ON orders (id) WHERE is_deleted = false` is useful
when most rows are deleted and you frequently query non-deleted rows.

---

### ⚖️ Comparison Table

| Index Type | Supported Ops | Size | Use Case |
|---|---|---|---|
| B-tree (default) | =, <, >, BETWEEN, LIKE prefix | Medium | Most queries |
| Hash | = only | Small | Equality lookups only |
| GIN | Array/JSONB containment, full-text | Large | JSONB, array, text search |
| GiST | Geometric, range types | Medium | PostGIS, range queries |
| BRIN | Range over blocks | Very small | Monotonic columns (timestamps) |
| Partial | B-tree on subset of rows | Smaller | Filtered queries |

---

### 🏛️ System Design

*(Omit: L2 keyword - index design at system level is covered in L3 Indexing Strategy)*

---

### 📊 Diagram

*(Omit: B-tree structure illustrated in ASCII in Concept Explanation above)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Index is not used after creating it**

Symptom: created an index; EXPLAIN still shows Seq Scan.

Causes:
1. Statistics stale - fix: `ANALYZE tablename`
2. Low selectivity (optimizer chose seq scan intentionally)
3. Function on column: `WHERE LOWER(col) = ?` - create a functional index
4. Index not matching the query pattern (wrong column order)

Diagnosis:
```sql
-- Check if statistics are fresh
SELECT last_analyze FROM pg_stat_user_tables WHERE relname = 'orders';

-- Force index use to verify it works (debugging only):
SET enable_seqscan = off;  -- session only
EXPLAIN SELECT ... WHERE customer_id = 42;
SET enable_seqscan = on;
```

---

### 🎯 Interview Deep-Dive

**Q1: How does a B-tree index handle range queries?**

🗣️ "A B-tree stores values in sorted order. Leaf nodes are linked as a
doubly-linked list. For a range query `WHERE created_at BETWEEN '2024-01-01' AND '2024-01-31'`:
(1) traverse the B-tree to find the first entry >= '2024-01-01'; (2) scan
leaf nodes forward (following the linked list) until > '2024-01-31'.
This is called a range scan. Total I/O: one tree traversal (3-4 levels)
plus the range length in index pages. Much faster than a full table scan.
Hash indexes do NOT support range queries (hash values are randomly
distributed; you cannot find 'all values greater than X' efficiently)."

**Q2: What is the leading column rule for composite indexes?**

🗣️ "A composite index `(a, b, c)` stores rows sorted by a first, then b,
then c. It can be used for: `WHERE a = ?`, `WHERE a = ? AND b = ?`,
`WHERE a = ? AND b = ? AND c = ?`. It CANNOT be used for: `WHERE b = ?`
alone (a must be present to leverage the sort order). This is the leftmost
prefix rule. Example: index `(customer_id, status)`. Works: `WHERE customer_id = 5`,
`WHERE customer_id = 5 AND status = 'PLACED'`. Does not work:
`WHERE status = 'PLACED'` alone. Design composite indexes starting with
the most frequently used equality column."

**Q3: What is an index-only scan and how does it improve performance?**

🗣️ "A regular index scan: (1) scan the index to find matching entries;
(2) for each entry, fetch the heap page to read the full row. Index-only scan:
all selected columns are in the index - no heap access needed. For `SELECT id, email FROM customers WHERE email = ?` with an index on `(email, id)`:
the index contains both `email` (for the lookup) and `id` (for the SELECT).
No heap page reads. Index-only scans are dramatically faster for:
high-frequency queries where the selected columns are small, tables
with wide rows (reading the heap would fetch a large page for 2 columns).
Design: for your hottest SELECT queries, ensure the index covers all
projected columns."

**Q4: What is index bloat and how do you detect and fix it?**

🗣️ "Index bloat: wasted space in an index due to dead tuples. In PostgreSQL
MVCC: UPDATE creates a new row version. The old version becomes a dead tuple.
The index has an entry for the old version (dead) and the new version (live).
VACUUM removes dead heap tuples and also cleans up dead index entries.
Between VACUUM runs: the index is bloated. Detection: `SELECT * FROM
pgstattuple('index_name')` shows dead tuple ratio. Fix: (1) ensure AUTOVACUUM
is running and keeping up; (2) for heavily updated tables: decrease
`autovacuum_vacuum_scale_factor`; (3) for severe bloat: `REINDEX CONCURRENTLY index_name`
rebuilds the index without bloat."

**Q5: What is a covering index and how do you design one?**

🗣️ "A covering index contains all columns needed by a specific query:
WHERE columns, JOIN columns, and SELECT columns. The index 'covers' the query.
For `SELECT order_id, status, total_cents FROM orders WHERE customer_id = ? ORDER BY created_at DESC`:
a covering index `(customer_id, created_at DESC, order_id, status, total_cents)`.
The database uses the index for: (1) the WHERE lookup (customer_id),
(2) the ORDER BY (created_at is the second column), (3) the SELECT projection
(all other selected columns are in the index). Zero heap accesses.
Design process: start with the equality columns in WHERE, then the range/sort
columns, then the selected columns. Keep the index focused on the most
critical queries."

**Q6: What happens to indexes during bulk INSERT operations?**

🗣️ "Every row inserted into a table must be added to every index on the table.
For a table with 5 indexes and 10 million rows to insert: 10 million * 5
index insertions. Each index insertion may cause B-tree page splits (when
a leaf node is full). Optimization for bulk loading: (1) drop indexes
before bulk load, then recreate them. Rebuilding is faster than incremental
insertions. (2) Use `COPY` command (PostgreSQL) or `LOAD DATA INFILE` (MySQL)
instead of INSERT loops - bulk load utilities bypass some overhead.
(3) Set `maintenance_work_mem` high for index creation to allow larger
sort batches. After bulk load: `ANALYZE tablename` to refresh statistics."

**Q7: How do indexes work with NULL values?**

🗣️ "B-tree indexes: PostgreSQL indexes NULL values. A query `WHERE col IS NULL`
can use a B-tree index on `col` (NULLs are stored at the end of the index
by default, or beginning with `NULLS FIRST` option). Oracle and some other
databases do NOT index NULLs in B-tree indexes. Hash indexes: NULL values
are not hashed (no index entry). Practical implication: if you frequently
query `WHERE col IS NULL` on a large table in PostgreSQL: a B-tree index
helps. In databases that do not index NULLs: a partial index `WHERE col IS NULL`
won't work, and you may need a sentinel value instead."

---

# Index Types - B-Tree, Hash, and Composite Indexes

**TL;DR:** B-tree is the default and most versatile index: supports
equality, range, ordering, and LIKE prefix searches. Hash indexes are
optimal for equality-only lookups but rarely preferred. Composite indexes
serve multi-column queries but require careful column ordering (leftmost
prefix rule). Understanding which index type fits the query pattern is
essential for performance tuning.

---

### 🎯 Model Answer

**30 seconds:**
> B-tree: sorted tree, supports all comparison operators. Default choice.
> Hash: equality-only, faster per-lookup but not useful for range/sort.
> Composite: multiple columns, leftmost prefix rule applies.
> GIN: JSONB, arrays, full-text. Choose the index type by the query pattern:
> what operator does the WHERE clause use?

**3 minutes:**
> B-tree is the right choice for 90% of index needs. It supports: =, !=,
> <, >, <=, >=, BETWEEN, IN, LIKE 'prefix%', ORDER BY, and NULL checks.
> It handles both equality and range queries efficiently.
>
> Hash indexes: in PostgreSQL (WAL-logged since version 10), hash indexes
> are physically smaller and faster for equality lookups (O(1) vs O(log n)).
> But: no range support, no ordering support, not widely used in practice.
> The practical question: do you need a hash index over B-tree? Only if
> the table is very large and you need pure equality performance. In most
> cases, B-tree's O(log n) is fast enough.
>
> Composite indexes: column order matters for the leftmost prefix rule.
> Put equality columns first, then range columns, then sort columns.
> `(status, created_at)` supports `WHERE status = ? ORDER BY created_at`.
> `(created_at, status)` does NOT support `WHERE status = ?` efficiently
> (created_at must be constrained for status to benefit).

**Blank Mind Recovery:**

**(1) Restate:** "B-tree: default, all ops. Hash: equality only. Composite:
leftmost prefix rule. GIN: JSONB/arrays."

**(2) First principles:** "Index type determines which query operations
the index supports. Match the index to the operator the query uses."

**(3) Bridge:** "Like different types of filing systems. Alphabetical (B-tree):
find by name range. Hash bins (Hash): find by exact code. Multi-drawer cabinet
(composite): find by first drawer then subdivider."

---

### 📘 Concept Explanation

**Index type - query operator mapping:**

```
B-tree:
  Supported: =, <, >, <=, >=, BETWEEN, IS NULL,
             IN, LIKE 'prefix%', ORDER BY
  Not: LIKE '%suffix', array containment, full-text

Hash:
  Supported: = (equality only)
  Not: range queries, ORDER BY, LIKE

GIN (Generalized Inverted Index):
  Supported: @> (containment), <@ (contained by),
             && (overlap), @@ (full-text match)
  Use for: JSONB, arrays, tsvector (full-text)
  Large size, slower writes, fast for containment

GiST (Generalized Search Tree):
  Supported: geometric operators, range types,
             nearest-neighbor search
  Use for: PostGIS geometry, tsrange, int4range

BRIN (Block Range Index):
  Tiny size (a few KB for 100M rows).
  Only effective for correlated physical order.
  Use for: insert-ordered timestamps, sequential IDs.
  Not: randomly ordered data.
```

**Composite index design pattern:**

```
Pattern: (equality1, equality2, range_or_sort)

Query: WHERE tenant_id = ? AND status = ? ORDER BY created_at
Index: (tenant_id, status, created_at)
  - tenant_id: equality (high selectivity first)
  - status: equality (secondary filter)
  - created_at: ordering (serves ORDER BY without sort step)

NOT:
Index: (created_at, tenant_id, status)
  - created_at is first: range/sort column first
  - Cannot satisfy WHERE tenant_id = ? efficiently alone
```

---

### 💻 Code Example

```sql
-- COMPOSITE INDEX: the equality-first pattern

-- Query to optimize:
-- Find active orders for a customer, newest first
SELECT id, status, total_cents, created_at
FROM orders
WHERE customer_id = 42
  AND status = 'ACTIVE'
ORDER BY created_at DESC
LIMIT 20;

-- BAD index: wrong column order
CREATE INDEX idx_bad
    ON orders (created_at, customer_id, status);
-- created_at is first: range column first.
-- WHERE customer_id = 42 cannot use the index
-- efficiently (created_at is not constrained).
-- Plan: likely Seq Scan or inefficient index scan.

-- GOOD index: equality columns first, sort last
CREATE INDEX idx_orders_cust_status_created
    ON orders (customer_id, status, created_at DESC);
-- 1. customer_id: equality (jumps to customer's rows)
-- 2. status: equality (jumps to ACTIVE rows)
-- 3. created_at DESC: serves ORDER BY (no sort needed)
-- Also covers: LIMIT 20 = reads exactly 20 leaf entries

-- Verify with EXPLAIN ANALYZE:
EXPLAIN ANALYZE
SELECT id, status, total_cents, created_at
FROM orders
WHERE customer_id = 42
  AND status = 'ACTIVE'
ORDER BY created_at DESC
LIMIT 20;
-- Should show: Index Scan Backward using idx_...
-- No "Sort" step in the plan.
```

> **Code walkthrough:** The BAD index puts `created_at` first. The B-tree
> is sorted by `created_at` first. To use it for `WHERE customer_id = 42`:
> the database would need to scan the entire `created_at` range to find
> customer 42's rows - not helpful. The GOOD index: `customer_id` first
> means all rows for customer 42 are contiguous in the index. `status`
> second narrows to ACTIVE orders. `created_at DESC` third means those
> ACTIVE orders are already sorted newest-first. The LIMIT 20 stops after
> 20 index entries. Zero heap page reads per entry if the index covers all
> selected columns.

```sql
-- PARTIAL INDEX: focused index for selective conditions

-- Scenario: 99% of orders have status != 'PENDING'.
-- You frequently query pending orders.
-- A full index on status has poor selectivity.

-- BAD: full index (low selectivity for PENDING)
CREATE INDEX idx_orders_status ON orders (status);
-- status has ~5 values; selectivity ~20% per value.
-- Optimizer may prefer seq scan for non-rare values.

-- GOOD: partial index on just PENDING orders
CREATE INDEX idx_orders_pending_created
    ON orders (created_at DESC)
    WHERE status = 'PENDING';
-- Contains only 1% of rows (the PENDING ones).
-- Small index: fits entirely in buffer cache.
-- Fast: the database reads only the tiny PENDING index.

-- Only this query pattern uses the partial index:
SELECT id, customer_id, total_cents
FROM orders
WHERE status = 'PENDING'          -- must match WHERE clause
ORDER BY created_at DESC
LIMIT 50;
-- Plan: Index Scan on idx_orders_pending_created
--   (reads 50 entries from a 1% subset index)
```

> **Code walkthrough:** The partial index contains only rows where
> `status = 'PENDING'`. For a 100M row table with 1M PENDING orders:
> the partial index has 1 million entries vs. 100 million in a full index.
> It is 100x smaller, fits in the buffer cache more easily, and is read
> 100x faster. The trade-off: only queries that include `WHERE status = 'PENDING'`
> in their WHERE clause can use this index. The partial index is a powerful
> optimization for the common pattern of querying a small subset of rows
> (active users, pending orders, unprocessed events).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> B-tree is the default index type and works for most queries (=, <, >,
> BETWEEN, ORDER BY). Hash indexes work only for equality. Composite indexes
> cover multiple columns: list equality columns first, then range or sort
> columns (leftmost prefix rule). GIN indexes are for JSONB, arrays, and
> full-text search. Choose the index type based on the operator in the
> WHERE clause.

---

**Senior / Staff:**
> Composite index design is the most impactful indexing skill. The column
> order determines which queries benefit. My design process: (1) identify
> the hottest queries; (2) extract their equality predicates - these are
> the leading columns; (3) add the range or sort column last; (4) if the
> query also selects from the table: consider covering the selected columns.
> The result is a composite covering index that eliminates heap access.
> Partial indexes are underused: any time you have a selective status filter
> on a large table, a partial index dramatically outperforms a full one.

---

### ⚠️ Common Misconceptions

**"A composite index (a, b) contains two separate indexes"**

Reality: a composite index is a single B-tree structure sorted primarily
by `a`, then by `b` within each `a` group. It can satisfy queries on `a`
alone (prefix match). It cannot efficiently satisfy queries on `b` alone
(no leading sort on `b`). You need a separate index on `b` to serve
`WHERE b = ?` independently.

**"Adding DESC to an index column is just cosmetic"**

Reality: `CREATE INDEX ON orders (created_at DESC)` creates an index
stored in descending order. For `ORDER BY created_at DESC`: this index
is read forward (which is efficient). For `ORDER BY created_at ASC`:
this index is read backward (also efficient, B-trees support bidirectional
scanning). In most cases: `ASC` and `DESC` variants have equivalent
performance. Exception: for mixed-direction composite sorts
(`ORDER BY a ASC, b DESC`): you need an index `(a ASC, b DESC)` to
avoid a sort step.

---

### ⚖️ Comparison Table

| Index | Operators | Range? | Order? | Size | Write Cost |
|---|---|---|---|---|---|
| B-tree | All comparison | Yes | Yes | Medium | Medium |
| Hash | = only | No | No | Small | Low |
| GIN | @>, &&, @@ | Depends | No | Large | High |
| GiST | Geometric, range | Yes | No | Medium | Medium |
| BRIN | Range (correlated) | Yes (coarse) | No | Tiny | Very low |
| Partial B-tree | All (on subset) | Yes | Yes | Smaller | Lower |

---

### 🏛️ System Design

*(Omit: L2 keyword - index selection at system scale is covered in L3 Indexing Strategy)*

---

### 📊 Diagram

*(Omit: B-tree illustrated in ASCII in Concept Explanation above)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Composite index not used due to column order**

Symptom: `WHERE a = ? AND b = ?` is slow. Index on `(b, a)` exists.

Diagnosis: `EXPLAIN ANALYZE` shows Seq Scan. Query filters on `a` first
but the index leading column is `b`.

Fix: create index `(a, b)` - equality-first column order matching the query.
Check if the old `(b, a)` index is still needed for other queries.

**Failure: Index too large, causing buffer cache churn**

Symptom: index scans are slower than expected; `EXPLAIN ANALYZE` shows
high "Buffers hit=N miss=M" with large miss ratio.

Diagnosis: the index is larger than `shared_buffers`; it causes constant
cache eviction.

Fix: (1) partial index to reduce index size; (2) increase `shared_buffers`
if hardware allows; (3) covering index (replace separate indexes with one
covering index that serves multiple queries).

---

### 🎯 Interview Deep-Dive

**Q1: When would you use a BRIN index over a B-tree?**

🗣️ "BRIN (Block Range INdex) stores the minimum and maximum values for
each range of physical pages. It is extremely small (a few KB for a table
with hundreds of millions of rows). For a query `WHERE created_at > '2024-01-01'`:
BRIN says 'skip blocks 1-900 (max timestamp is 2023-12-31), scan blocks 901+.'
Requirements: the column must be physically correlated with the insert order.
For a timestamp column on an append-only events table: rows are inserted
in roughly ascending time order, so BRIN works perfectly. For a randomly
distributed column: BRIN provides no benefit (every block has overlapping
ranges). Use case: very large (100M+ row) append-only tables with time-based
range queries."

**Q2: How does PostgreSQL decide between index scan and bitmap index scan?**

🗣️ "Index scan: fetches heap pages one by one as it scans the index. Good
for: small result sets where heap pages are fetched in near-index-order.
Bitmap index scan: (1) scan the index and collect all matching page locations;
(2) sort the page locations by physical page number; (3) read heap pages in
physical order. Good for: larger result sets where index-order heap access
would cause random I/O; or when combining two indexes with a Bitmap OR or
AND. The optimizer switches to bitmap when the estimated number of matching
rows exceeds a threshold (related to `random_page_cost` vs `seq_page_cost`).
Both are better than Seq Scan for selective queries."

**Q3: How do partial indexes interact with query planning?**

🗣️ "The optimizer uses a partial index only if the query's WHERE clause
implies the index's condition. `CREATE INDEX idx ON orders(created_at) WHERE status='PENDING'`.
For `WHERE status = 'PENDING' AND created_at > ?`: the query's `status = 'PENDING'`
implies the index condition - the index is eligible. For `WHERE created_at > ?`
(without the status filter): the query does not guarantee `status = 'PENDING'`
so the partial index is not eligible. For OR conditions: `WHERE status = 'PENDING' OR created_at > ?`:
the partial index might not be used (the OR branch doesn't guarantee PENDING).
Partial index conditions must be simple enough for the optimizer to recognize
the implication."

**Q4: What is an expression index and when do you need one?**

🗣️ "An expression index (also called functional index) stores the result
of an expression. `CREATE INDEX ON customers (LOWER(email))`. This index
stores the lowercased email for each row. Query `WHERE LOWER(email) = 'user@example.com'`
uses this index (the expression matches). Without it: `WHERE LOWER(email) = ?`
is not sargable (the function wraps the column). Other uses: `EXTRACT(YEAR FROM created_at)`,
`(first_name || ' ' || last_name)`, `(jsonb_col -> 'field')`. Overhead:
the expression is evaluated at insert/update time and the result is stored.
The index grows with the full expression result, not just the base column."

**Q5: How do you find unused indexes in production PostgreSQL?**

🗣️ "`pg_stat_user_indexes` tracks index scan counts since the last statistics
reset. `SELECT indexrelname, idx_scan FROM pg_stat_user_indexes
WHERE schemaname = 'public' ORDER BY idx_scan` - indexes with idx_scan = 0
have never been used. These are candidates for dropping. Caveat:
statistics reset on server restart; check `pg_stat_bgwriter.stats_reset`
to see when stats were last reset. Also check `idx_tup_read` and `idx_tup_fetch`:
an index scanned many times but with few tuples fetched per scan may be
inefficient. Before dropping: check if the index serves a constraint (UNIQUE)
or a foreign key (required for ON DELETE CASCADE efficiency)."

**Q6: What is the difference between a unique index and a unique constraint?**

🗣️ "A UNIQUE constraint is implemented as a unique index. `ALTER TABLE
customers ADD CONSTRAINT uq_email UNIQUE (email)` creates a unique index
named `uq_email`. `CREATE UNIQUE INDEX uq_email ON customers (email)` does
the same thing. Functional difference: none. The UNIQUE constraint is part
of the table definition (visible in schema introspection, enforced by the
database). The unique index is more directly a performance artifact that
also enforces uniqueness. In practice: use `UNIQUE` in `CREATE TABLE` for
natural unique constraints (email, SKU). Use `CREATE UNIQUE INDEX CONCURRENTLY`
to add unique constraints to existing tables without locking writes."

**Q7: How does the fill factor setting affect index performance?**

🗣️ "Fill factor controls how full each B-tree leaf page is when initially
built or after VACUUM. Default: 90% for indexes (10% reserved for updates).
For read-only tables: use fill factor 100% (no space wasted). For frequently
updated tables: use fill factor 70-80%. Why: when an index page is updated
and there is no room: a page split occurs (one page becomes two). Splits
cause index bloat and fragmentation. With 80% fill factor: there is 20%
slack for updates before a split is needed. HOT (Heap-Only Tuple) updates
avoid index updates entirely when no indexed column changes - reducing the
need for lower fill factors on MVCC tables."
