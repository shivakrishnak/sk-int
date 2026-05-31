---
layout: default
title: "Database SQL - L2 Performance Basics"
parent: "Database SQL"
grand_parent: "SK Interview"
nav_order: 9
permalink: /database-sql/l2-performance-basics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [EXPLAIN and Query Execution Plans](#explain-and-query-execution-plans) | medium |
| 2 | [N+1 Query Anti-Pattern](#n1-query-anti-pattern) | medium |

---

# EXPLAIN and Query Execution Plans

**TL;DR:** EXPLAIN shows how the database plans to execute a query:
which tables it will scan, which indexes it will use, join algorithms,
and estimated costs. EXPLAIN ANALYZE actually runs the query and shows
real execution times and row counts. Reading execution plans is the
primary skill for diagnosing slow queries.

---

### 🎯 Model Answer

**30 seconds:**
> `EXPLAIN query` shows the query execution plan: which tables are scanned,
> which indexes are used, which join algorithm is chosen, and the estimated
> cost. `EXPLAIN ANALYZE query` runs the query and shows actual execution
> time and row counts. Use EXPLAIN ANALYZE to diagnose slow queries:
> look for Seq Scans on large tables, wrong row estimates, and expensive
> sort steps.

**3 minutes:**
> The execution plan is a tree of nodes. Each node represents an operation:
> Seq Scan (read all rows), Index Scan (use an index), Hash Join, Nested Loop,
> Sort, Aggregate. Each node shows cost=(startup..total) rows=N width=B.
> The actual output adds: actual time=ms rows=N loops=1.
>
> Key things to look for: (1) Seq Scan on a large table with a small rows
> estimate - indicates a missing index. (2) rows= estimate far off from
> actual rows= - indicates stale statistics; fix with `ANALYZE tablename`.
> (3) Sort nodes for large result sets - can the ORDER BY be served by an index?
> (4) Hash Join with large "Batches" count - hash table exceeded memory,
> spilled to disk.
>
> The cost unit is in arbitrary units (8K page reads). Cost is used only
> for comparing plan options. Total cost includes all descendants. Compare
> relative costs between plan alternatives, not absolute values.

**Blank Mind Recovery:**

**(1) Restate:** "EXPLAIN: shows plan. ANALYZE: runs + shows real times.
Look for: Seq Scan (missing index), wrong row estimates (stale stats),
Sort (missing sort index), hash spill (low work_mem)."

**(2) First principles:** "The optimizer generates multiple possible plans
and picks the lowest estimated cost. EXPLAIN shows what it chose. EXPLAIN ANALYZE
verifies whether the estimates were correct."

**(3) Bridge:** "Like a GPS navigation plan. EXPLAIN shows the planned route.
EXPLAIN ANALYZE shows the actual time taken on each road segment.
Discrepancies (estimated 10 minutes, actual 60 minutes) indicate bad assumptions."

---

### 📘 Concept Explanation

**Reading EXPLAIN output:**

```
EXPLAIN ANALYZE
SELECT c.name, COUNT(o.id)
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.name;

Sample output:
HashAggregate (cost=... rows=5000) (actual time=45.2..47.8 rows=4993)
  Group Key: c.name
  -> Hash Join (cost=... rows=50000) (actual time=5.1..39.2 rows=50000)
       Hash Cond: (o.customer_id = c.id)
       -> Seq Scan on orders (cost=...) (actual time=0.1..12.3 rows=50000)
       -> Hash (cost=...) (actual time=2.1..2.1 rows=5000)
             Buckets: 8192
             -> Seq Scan on customers (cost=...) (actual time=0.1..1.8 rows=5000)

Reading:
  - Execution is bottom-up: leaf nodes execute first.
  - "Seq Scan on orders": reads all 50k rows (no index).
  - "Hash": builds a hash table from customers.
  - "Hash Join": for each orders row, probe the customers hash.
  - "HashAggregate": group by name, count.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Plan nodes quick reference:**

```
Scan nodes:
  Seq Scan:         read all pages (full table scan)
  Index Scan:       read index, fetch heap for each match
  Index Only Scan:  read index only (no heap access)
  Bitmap Heap Scan: collect index matches, sort by page, read heap

Join nodes:
  Nested Loop:  outer rows * inner index lookups
  Hash Join:    build hash from one side, scan other
  Merge Join:   merge two pre-sorted inputs

Other:
  Sort:         explicit sort (look for this - can be avoided)
  HashAggregate: hash-based GROUP BY
  GroupAggregate: sort-based GROUP BY (input pre-sorted)
  Limit:        stop after N rows
  Gather:       collect parallel workers' results
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```sql
-- DIAGNOSING A SLOW QUERY: step-by-step

-- The slow query:
SELECT c.name, SUM(o.total_cents) AS total
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'US'
  AND o.created_at >= '2024-01-01'
GROUP BY c.name
ORDER BY total DESC
LIMIT 10;

-- Step 1: EXPLAIN ANALYZE to see the plan
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT c.name, SUM(o.total_cents) AS total
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'US'
  AND o.created_at >= '2024-01-01'
GROUP BY c.name
ORDER BY total DESC
LIMIT 10;

-- BAD plan output (before optimization):
-- Sort (cost=98234.56..98235.06 rows=200)
--   -> HashAggregate (rows=200)
--      -> Hash Join (rows=200000)
--           Hash Cond: (o.customer_id = c.id)
--           -> Seq Scan on orders
--                Filter: (created_at >= '2024-01-01')
--                Rows Removed by Filter: 8500000
--                ** 8.5M rows scanned, 1.5M kept **
--           -> Seq Scan on customers
--                Filter: (country = 'US')
--                Rows Removed by Filter: 90000
--                ** 100k rows scanned, 10k kept **
--
-- Problems identified:
-- 1. Seq Scan on orders: missing index on created_at
-- 2. Seq Scan on customers: missing index on country
-- 3. Sort step: no index for ORDER BY total

-- Step 2: Add missing indexes
CREATE INDEX CONCURRENTLY idx_orders_created_at
    ON orders (created_at);
CREATE INDEX CONCURRENTLY idx_customers_country
    ON customers (country);

-- Step 3: Re-run EXPLAIN ANALYZE
-- GOOD plan output (after optimization):
-- Limit (actual time=12.3..12.3 rows=10)
--   -> Sort (actual time=12.2..12.2 rows=10)
--        Sort Key: (SUM(total_cents)) DESC
--        -> HashAggregate (actual time=11.8..11.9 rows=200)
--             -> Hash Join (actual time=4.5..10.2 rows=25000)
--                  -> Index Scan on orders using idx_...
--                       Index Cond: (created_at >= '2024-01-01')
--                       actual rows=1500000 (1.5M, down from 10M)
--                  -> Bitmap Heap Scan on customers
--                       Recheck Cond: (country = 'US')
--                       actual rows=10000
-- Total time: 12ms (was 890ms). 75x improvement.
```

> **Code walkthrough:** EXPLAIN BUFFERS shows how many disk blocks were
> read. The BAD plan has two Seq Scans - each reads the entire table.
> `Rows Removed by Filter: 8,500,000` means 85% of orders were scanned
> and discarded. Adding indexes on `created_at` and `country` converts
> these to Index Scans, which read only matching rows. The Sort step
> for ORDER BY total remains (total is a computed aggregate, not indexable),
> but with 10 rows after LIMIT this is trivial. Total execution time
> drops from 890ms to 12ms.

```sql
-- ROW ESTIMATE ERRORS: stale statistics

-- Check when a table was last analyzed:
SELECT relname, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE relname = 'orders';

-- If last_analyze is NULL or old:
ANALYZE orders;  -- refresh statistics

-- Check row estimate accuracy in the plan:
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 42;
-- Output shows:
--   (cost=..rows=100..)  <-- estimate
--   (actual rows=4502..) <-- reality
-- Estimate was 100, actual was 4502.
-- This leads to bad join choices (wrong algorithm selected).

-- After ANALYZE:
ANALYZE orders;
EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
-- (cost=..rows=4500..) (actual rows=4502..)
-- Estimates are now accurate. Better plan chosen.
```

> **Code walkthrough:** Statistics are the optimizer's input. If statistics
> are stale (loaded from old data or not yet collected): the optimizer
> makes wrong choices. A row estimate of 100 when reality is 4,500 causes
> the optimizer to choose Nested Loop (suitable for small sets) when
> Hash Join (suitable for large sets) would be faster. `ANALYZE table`
> refreshes statistics by sampling the table. PostgreSQL's autovacuum
> also runs ANALYZE automatically, but immediately after a large data load:
> manual `ANALYZE` ensures fresh statistics before the first query.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> EXPLAIN shows the database's execution plan for a query: which tables
> are scanned, which indexes are used, and estimated costs. EXPLAIN ANALYZE
> actually runs the query and shows real times and row counts. Key red flags:
> Seq Scan on a large table (missing index), estimate vs. actual rows
> mismatch (stale statistics - run ANALYZE), Sort step (consider adding
> an index for the ORDER BY column).

---

**Senior / Staff:**
> The most impactful EXPLAIN skill: comparing estimated vs. actual rows.
> When these differ by more than 2-3x, the optimizer chose the plan based
> on wrong assumptions. The fix is usually `ANALYZE`. The second skill:
> reading the Buffers output (`EXPLAIN (ANALYZE, BUFFERS)`). Buffers shows
> how many 8KB pages were read from shared_buffers (hit=N) and from disk
> (read=N). A high `read=N` means the working set doesn't fit in cache.
> For production queries: the target is mostly `hit` with minimal `read`.

---

### ⚠️ Common Misconceptions

**"Lower cost= number means faster query"**

Reality: cost units are arbitrary (roughly 8KB page reads). They are
used only to compare plan options internally. You cannot compare the
cost of a query on table A with a query on table B. You cannot compare
costs between database versions. Only actual time= (from EXPLAIN ANALYZE)
gives real performance information.

**"EXPLAIN ANALYZE is safe to run on any query"**

Reality: EXPLAIN ANALYZE actually executes the query. For DML queries
(INSERT, UPDATE, DELETE): EXPLAIN ANALYZE runs the mutation and then
rolls it back. This is generally safe but: (1) it takes the same time
as actually running the query; (2) for very long-running queries, you
pay the execution cost just to see the plan; (3) if there are side effects
(triggers, sequences): they fire and their effects on sequences persist
even after rollback.

---

### ⚖️ Comparison Table

| Command | Runs Query? | Shows Real Time? | Shows Row Counts? | Safe for DML? |
|---|---|---|---|---|
| EXPLAIN | No | No (estimated only) | No (estimated) | Yes |
| EXPLAIN ANALYZE | Yes | Yes | Yes (actual) | Yes (rolled back) |
| EXPLAIN (ANALYZE, BUFFERS) | Yes | Yes | Yes | Yes |
| EXPLAIN (ANALYZE, FORMAT JSON) | Yes | Yes | Yes | Yes |

---

### 🏛️ System Design

*(Omit: L2 keyword - query plan analysis at system level is covered in L3 Query Optimization)*

---

### 📊 Diagram

*(Omit: execution plan tree illustrated in ASCII in Concept Explanation above)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Query plan changes unexpectedly after data load**

Symptom: a query that was fast (using Index Scan) is now slow (using
Seq Scan) after inserting 10 million rows.

Cause: statistics are stale. The optimizer estimated 1,000 rows matching
the predicate (based on old statistics). With 10M new rows, 100,000
match the predicate. The optimizer would have chosen Seq Scan if it
knew the actual row count.

Fix:
```sql
ANALYZE orders;  -- refresh statistics
-- Then re-run EXPLAIN ANALYZE to verify the plan changed.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Set `autovacuum_analyze_scale_factor = 0.05` for high-churn tables.

---

### 🎯 Interview Deep-Dive

**Q1: What does the cost= field in EXPLAIN output mean?**

🗣️ "Cost is a relative number in arbitrary units (roughly proportional
to the number of sequential 8KB page reads). `cost=startup..total`.
Startup cost: the work needed before the first row can be returned
(e.g., sorting must complete before returning sorted rows; startup cost is high).
Total cost: complete plan execution cost. The optimizer minimizes total cost
for queries without LIMIT; for queries with LIMIT, it may optimize for
startup cost (return first rows quickly). Units are NOT milliseconds.
They are comparable only within the same query (e.g., Index Scan cost=5
vs Seq Scan cost=2345 means Index Scan is far cheaper). Do not compare
costs across different databases or versions."

**Q2: What is the difference between Index Scan and Index Only Scan?**

🗣️ "Index Scan: use the index to find matching rows, then fetch the
actual heap pages for each match. Two levels of I/O: index read + heap
page read. Good for selective queries (few matching rows).
Index Only Scan: all columns needed by the query are in the index.
No heap access. EXPLAIN shows 'Index Only Scan'. This is the fastest
possible scan for selective queries on appropriately designed indexes.
PostgreSQL caveat: the visibility map must be current. If the heap page
has not been VACUUMed recently, PostgreSQL must check the heap to verify
visibility even for an Index Only Scan. EXPLAIN shows 'Heap Fetches: N'
for these checks. High Heap Fetches on an Index Only Scan: run VACUUM
to update the visibility map."

**Q3: How do you diagnose a slow query in production PostgreSQL?**

🗣️ "Four-step process: (1) Identify slow queries: `pg_stat_statements`
(requires the extension) shows total time, call count, and mean time per
query. Sort by total_time to find the most expensive queries.
(2) Run `EXPLAIN (ANALYZE, BUFFERS)` on the problematic query with
representative parameters. (3) Look for: Seq Scan on large tables (missing
index), high `Buffers: read` (cache miss), Sort or HashAggregate nodes
with large working set, big estimate-vs-actual row discrepancies.
(4) Fix: add missing indexes, run ANALYZE for stale stats, increase
`work_mem` for sort/hash spills, rewrite the query if the logic is
inherently inefficient."

**Q4: What does 'loops=N' mean in EXPLAIN ANALYZE output?**

🗣️ "'loops=N' means the plan node executed N times. For a Nested Loop join:
the inner side executes once per outer row. If the outer side returns
1,000 rows and the inner side does an index seek per row: loops=1000 for
the inner node. The actual time shown is per loop (not total). Total time
for that node = actual time * loops. EXPLAIN calculates the total in the
buffers output. High loops with a non-trivial actual time per loop:
indicates an expensive inner node executing many times (the N+1 problem in
SQL: many small queries, each fast individually but expensive in aggregate).
For correlated subplans: `SubPlan 1 (loops=1000000)` is a warning sign."

**Q5: What is parallel query execution and when does PostgreSQL use it?**

🗣️ "PostgreSQL can split a sequential scan, aggregate, or hash join across
multiple CPU cores. `EXPLAIN` shows 'Gather Merge' or 'Gather' nodes,
which collect results from parallel workers. Conditions for parallel query:
`max_parallel_workers_per_gather > 0`, `parallel_tuple_cost` and
`min_parallel_table_scan_size` settings allow it, and the query meets
minimum size thresholds. Parallel query helps for: large analytical
queries (full table scans, large aggregations), batch processing.
It does NOT help for: OLTP queries (already using indexes, small result sets),
queries with index scans (index scans do not parallelize). Check
EXPLAIN for 'Workers Planned/Launched' to see parallelism in action."

**Q6: How do hints work in PostgreSQL and when should you use them?**

🗣️ "PostgreSQL does not have SQL hints (unlike Oracle's `/*+ INDEX(t idx) */`).
Instead, use GUC settings to disable plan options: `SET enable_seqscan = off`
forces index use (never in production; debugging only). More controlled:
set `join_collapse_limit = 1` to prevent the optimizer from reordering JOINs.
Or use CTEs as optimization fences (`WITH x AS MATERIALIZED`). pg_hint_plan
extension adds Oracle-style hints. When to force a plan: (1) during debugging
to test if a plan change would help; (2) a verified case where the optimizer
consistently makes a wrong choice due to statistics limitations. Never
use hints as a permanent fix without understanding why the optimizer makes
the wrong choice - the hint will break when data distribution changes."

**Q7: What is the pg_stat_statements extension and how do you use it for performance tuning?**

🗣️ "`pg_stat_statements` tracks execution statistics for every unique query
pattern. `SELECT query, calls, total_exec_time, mean_exec_time, rows
FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 20`.
This shows: the top 20 queries by total execution time. `total_exec_time`:
cumulative CPU time since last reset. `calls`: how many times the query ran.
`mean_exec_time = total_exec_time / calls`. Pattern: find queries with
high mean time (expensive per call) and queries with high total time
(frequently called, even if fast per call). Both are targets for optimization.
Reset with `pg_stat_statements_reset()`. Enable with `shared_preload_libraries = pg_stat_statements`."

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


# N+1 Query Anti-Pattern

**TL;DR:** The N+1 query problem occurs when code executes 1 query to
fetch N parent records, then executes N additional queries (one per
parent) to fetch their children. Total: N+1 queries instead of 2.
For N=1000: 1001 database round trips where 2 would suffice. This is
the most common ORM-related performance bug in production Java applications.

---

### 🎯 Model Answer

**30 seconds:**
> N+1: fetch N customers in one query, then fetch each customer's orders
> in N separate queries = N+1 total queries. For 1,000 customers:
> 1,001 round trips. Fix: use a JOIN to fetch both in one query, or use
> an eager-loading batch (e.g., JPA's `JOIN FETCH`). This is the most
> common ORM performance bug.

**3 minutes:**
> N+1 happens when your code iterates over a collection of parent objects
> and accesses a lazy-loaded child collection for each. In JPA/Hibernate:
> accessing `customer.getOrders()` on a lazily-loaded association triggers
> a SELECT for that customer's orders. If you loop over 1,000 customers:
> 1,000 individual order SELECT queries. Each is fast (milliseconds), but
> 1,000 round trips add up to seconds.
>
> Detection: SQL logging. Count the SELECT statements. If you see the same
> SELECT pattern repeated N times with different parameter values: N+1.
> Hibernate's `show_sql=true` or `p6spy` for detailed per-query logging.
>
> Solutions: (1) JOIN FETCH in JPQL: `SELECT c FROM Customer c JOIN FETCH c.orders`.
> One query. (2) EntityGraph: `@EntityGraph(attributePaths = "orders")`.
> (3) Batch fetching: `@BatchSize(size=50)` tells Hibernate to load 50
> collections at a time with `WHERE id IN (...)`. (4) DTO projection:
> write a native JOIN query and map to a DTO - no ORM lazy loading involved.

**Blank Mind Recovery:**

**(1) Restate:** "N+1: 1 query for N parents + N queries for children = N+1 total.
Fix: JOIN FETCH, EntityGraph, BatchSize, or native query."

**(2) First principles:** "Lazy loading is correct for single entity access.
It is destructive when applied to collections: each collection access
is a separate database round trip."

**(3) Bridge:** "Like sending a courier to each of 1,000 offices to pick up
one document (1,000 trips). N+1 in SQL. The fix: send one truck to all offices
at once (one JOIN query)."

---

### 📘 Concept Explanation

**N+1 in JPA/Hibernate:**

```java
// BAD: N+1 query pattern (lazy loading in loop)
List<Customer> customers =
    em.createQuery("SELECT c FROM Customer c", Customer.class)
      .getResultList();
// 1 query: SELECT * FROM customers

for (Customer c : customers) {
    // Each call triggers a lazy load:
    c.getOrders().size();
    // SELECT * FROM orders WHERE customer_id = ?
}
// Total: 1 + N queries (1 for customers, N for orders)
// For 1000 customers: 1001 round trips.

// GOOD: JOIN FETCH (eager load with join)
List<Customer> customers =
    em.createQuery(
        "SELECT c FROM Customer c JOIN FETCH c.orders",
        Customer.class)
      .getResultList();
// 1 query: SELECT c.*, o.* FROM customers c
//          JOIN orders o ON o.customer_id = c.id
// c.getOrders() is populated - no lazy load.
// Total: 1 round trip.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Batch fetching as an alternative:**

```java
// BatchSize: load collections in batches of N
@Entity
public class Customer {
    @OneToMany(mappedBy = "customer", fetch = LAZY)
    @BatchSize(size = 50)  // Hibernate-specific
    private List<Order> orders;
}

// When first customer.getOrders() is accessed:
// Hibernate loads orders for 50 customers at once:
// SELECT * FROM orders WHERE customer_id IN (1,2,...50)
// Instead of 1000 queries: ceil(1000/50) = 20 queries.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```sql
-- DETECTING N+1 IN SQL LOGS (p6spy or show_sql=true)

-- N+1 looks like this in logs:
-- [Query 1]:
-- SELECT c.id, c.name FROM customers c

-- [Query 2]:
-- SELECT o.id, o.total FROM orders o
-- WHERE o.customer_id = 1

-- [Query 3]:
-- SELECT o.id, o.total FROM orders o
-- WHERE o.customer_id = 2

-- [Query 4]:
-- SELECT o.id, o.total FROM orders o
-- WHERE o.customer_id = 3

-- ... repeats 997 more times ...

-- The fix in SQL: one JOIN query
-- GOOD: load customers + orders in one query
SELECT
    c.id        AS customer_id,
    c.name      AS customer_name,
    o.id        AS order_id,
    o.total_cents,
    o.created_at
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE c.country = 'US'
ORDER BY c.id, o.created_at DESC;

-- Alternatively: batch approach for large result sets
-- Query 1: fetch customers
SELECT id, name FROM customers WHERE country = 'US';
-- Returns: [1, 2, 3, ..., 1000]

-- Query 2: fetch ALL orders for those customers in one IN
SELECT customer_id, id, total_cents
FROM orders
WHERE customer_id IN (1, 2, 3, ..., 1000)
ORDER BY customer_id;
-- Application-side: group orders by customer_id.
-- 2 queries total. Efficient.
```

> **Code walkthrough:** The N+1 log shows a SELECT for each customer
> individually - the classic N+1 signature. The JOIN solution combines
> both tables in one query. LEFT JOIN ensures customers with no orders
> are included. The application receives a flat result set and assembles
> the customer -> orders hierarchy in memory. The batch approach (two
> queries + application-side grouping) is useful when JOIN would produce
> too many columns or when the customer list comes from a complex query.

```java
// JAVA FIX: JPQL JOIN FETCH vs DTO projection

// Option 1: JOIN FETCH (eager load ORM entities)
@Query("SELECT c FROM Customer c " +
       "JOIN FETCH c.orders o " +
       "WHERE c.country = :country")
List<Customer> findWithOrdersByCountry(
    @Param("country") String country);
// Returns Customer objects with orders pre-populated.
// No lazy loading needed.

// Option 2: DTO projection (native SQL, best performance)
@Query(value = """
    SELECT c.id,
           c.name,
           COUNT(o.id)        AS order_count,
           SUM(o.total_cents) AS total_cents
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.id
    WHERE c.country = :country
    GROUP BY c.id, c.name
    """, nativeQuery = true)
List<CustomerSummaryDto> findCustomerSummaries(
    @Param("country") String country);
// No entity graph loading. Returns only needed columns.
// Most efficient for read-only display/reporting use cases.
```

> **Code walkthrough:** JOIN FETCH loads Customer entities with their
> orders collections pre-populated. The SQL includes a JOIN that brings
> all data in one round trip. DTO projection is the most efficient approach
> for read-only queries: write a specific SQL query that returns only the
> needed aggregated data, map to a simple DTO. No entity tracking overhead,
> no unnecessary column fetching, no lazy loading. For reporting and API
> responses: DTO projection is always preferable to loading full entity graphs.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> N+1: one query fetches N parent records, then N queries fetch children
> (one per parent) = N+1 total. Fix: use JOIN to fetch both in one query,
> or use `JOIN FETCH` in JPQL, or `@EntityGraph` in Spring Data JPA.
> Detection: enable SQL logging (`spring.jpa.show-sql=true`) and count
> SELECT statements - repeated selects with different IDs are N+1.

---

**Senior / Staff:**
> N+1 is fundamentally a lazy-loading-in-a-loop problem. Three mitigations
> in order of preference: (1) DTO projection with a native query - sidesteps
> the ORM entirely for read-only use cases; (2) JOIN FETCH or EntityGraph
> for entity loading; (3) @BatchSize as a fallback for deep associations.
> The production diagnostic: `pg_stat_statements` shows a query pattern
> with high `calls` count and fast `mean_exec_time` - thousands of fast
> individual queries is the N+1 signature. Single-query fixes are always
> better than batching N queries into N/50 batches.

---

### ⚠️ Common Misconceptions

**"Eager loading always fixes N+1"**

Reality: global eager loading (`fetch = EAGER`) loads the association
for every query, even when you do not need it. Loading Customer entities
for a list of names now also loads all orders for each customer.
The fix is selective: use JOIN FETCH or EntityGraph only in queries
that actually need the related data.

**"N+1 is only an ORM problem"**

Reality: N+1 can occur in raw SQL code too. A loop in application code
that executes a query per iteration has the same problem. ORMs make it
easy to cause accidentally (via lazy loading). Application code loops
with per-row queries are equally problematic. The pattern to avoid:
any database query inside a loop over a collection.

---

### ⚖️ Comparison Table

| Solution | Queries | Complexity | When to Use |
|---|---|---|---|
| JOIN FETCH | 1 | Low | Entity loading, moderate size |
| EntityGraph | 1 | Low | Same as JOIN FETCH, Spring Data |
| BatchSize(n) | ceil(N/n) | Low | Deep associations, large N |
| DTO projection | 1 | Medium | Read-only, reporting |
| Application-side batch | 2 | Medium | Large N, complex query |
| Eager FetchType | 1 | Low risk | ALWAYS wrong (over-fetching) |

---

### 🏛️ System Design

*(Omit: L2 keyword - N+1 at scale is covered in L4 Production Diagnostics)*

---

### 📊 Diagram

*(Omit: N+1 pattern illustrated clearly in code examples above)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: N+1 hidden by fast individual queries**

Symptom: page load takes 3 seconds despite each SQL query completing
in <1ms.

Diagnosis: enable p6spy or log SQL with timing.
```
# application.properties (Spring Boot):
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE
# Or use p6spy for per-query timing
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Count the number of queries for one page load. 1,000 queries * 1ms each
= 1 second of pure database time, plus 1-2 seconds of network latency
for 1,000 round trips = 3 second page load.

**Fix checklist:**
1. Identify the N+1 association (which entity triggers the lazy loads)
2. Add `JOIN FETCH` or `@EntityGraph` to the repository query
3. Verify with SQL logs: one query after the fix
4. Add an integration test that counts SQL queries to prevent regression

---

### 🎯 Interview Deep-Dive

**Q1: How do you detect N+1 in a Java application in production?**

🗣️ "Three approaches: (1) SQL logging in development: `spring.jpa.show-sql=true`
and count SELECT patterns. Multiple selects with different IDs = N+1.
(2) Datasource-proxy or p6spy in staging: intercepts all JDBC calls,
logs each query with timing and call stack. Total queries per request
visible. (3) Production APM (Application Performance Monitoring): tools
like Datadog, New Relic, or Dynatrace trace database calls per HTTP request.
A high 'DB call count' per request with fast individual calls is the
N+1 signature. Additionally: `pg_stat_statements` shows high `calls` for
a parameterized query pattern - thousands of identical queries with different
parameters."

**Q2: What is the difference between JOIN FETCH and @EntityGraph in Spring Data JPA?**

🗣️ "JOIN FETCH: written in JPQL query directly. `SELECT c FROM Customer c JOIN FETCH c.orders WHERE c.id = :id`.
The association is eager-loaded in the query. Works per-query basis.
EntityGraph: annotation-based. `@EntityGraph(attributePaths = {'orders'})` on a repository method.
Spring translates this to a JOIN FETCH. Cleaner: keeps query logic in the
method signature, not in the JPQL string. Both produce equivalent SQL.
EntityGraph advantage: named entity graphs can be defined on the entity
and reused: `@NamedEntityGraph(name='Customer.orders', attributeNodes=...)`.
Disadvantage: can become complex for deep nested associations. For complex
data needs: a native SQL DTO projection is often cleaner."

**Q3: What is the Cartesian product problem with JOIN FETCH and multiple collections?**

🗣️ "JOIN FETCH on two parallel collections produces a Cartesian product.
`SELECT c FROM Customer c JOIN FETCH c.orders JOIN FETCH c.addresses`:
if a customer has 5 orders and 3 addresses: 5 * 3 = 15 rows in the result.
Hibernate deduplicates: `DISTINCT` or `@QueryHints` to return unique customers.
But the data transfer is 15 rows instead of 8 (5 + 3). For large collections:
this multiplies data significantly. Fix: use a Set instead of List for
the collections (Hibernate automatically deduplicates Sets) or use
separate queries with BatchSize - one query for orders, one for addresses.
In Spring Data: `@EntityGraph` with multiple paths has the same problem."

**Q4: How does Hibernate's @BatchSize work to mitigate N+1?**

🗣️ "`@BatchSize(size=50)` on a collection tells Hibernate: when any instance
in this collection is first accessed, load collections for up to 50 entities
at once using a `WHERE id IN (...)` query. For 1,000 customers and BatchSize=50:
ceil(1000/50) = 20 queries instead of 1,000. Each query loads orders for
50 customers. Trade-off: still multiple queries (20 vs 1 for JOIN FETCH),
but avoids the Cartesian product risk. Useful when: (1) the collection is
only accessed for some entities in the list; (2) deep nesting where JOIN FETCH
would produce too many levels of JOINs. Configure globally in persistence.xml:
`<property name='hibernate.default_batch_fetch_size' value='50'>`."

**Q5: Can you write a query that detects N+1 patterns in pg_stat_statements?**

🗣️ "`SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
WHERE query ILIKE '%WHERE%id%=%' AND calls > 1000
ORDER BY calls DESC LIMIT 20`.
This finds parameterized queries that ran more than 1,000 times -
a sign of N+1 (same query, different ID, called once per parent record).
A query with `calls = 5,000` and `mean_exec_time = 0.5ms` = 2.5 seconds
total. If this corresponds to one HTTP request type: it is doing 5,000
individual lookups. Cross-reference with your endpoint performance metrics
to identify which endpoint triggers the pattern."

**Q6: What is the open-session-in-view anti-pattern and how does it relate to N+1?**

🗣️ "Open Session in View (OSIV): Spring Boot enables this by default for web apps.
The JPA EntityManager (Hibernate Session) is opened at the start of the HTTP
request and closed at the end - spanning the controller, service, and view layer.
This allows lazy loading anywhere in the request, including in the view template.
Problem: it encourages lazy loading in view templates (JSP, Thymeleaf), which
triggers N+1 far from the service layer where it is hard to detect.
The view renders a list of customers: each `customer.orders` access triggers
a lazy load. In a template: each template variable access that touches a lazy
collection causes a database query. Disable OSIV in production:
`spring.jpa.open-in-view=false`. This forces developers to load all needed
data in the service layer (where it is visible and controllable)."

**Q7: How do you write tests to prevent N+1 regressions?**

🗣️ "Use a SQL counter test helper. With datasource-proxy:
wrap the DataSource to count queries per test. Assert the query count.
```java
@Test
void shouldLoadCustomersWithoutNPlusOne() {
    // Arrange: insert 10 customers with 3 orders each
    // Act: call the service method
    long queriesBefore = sqlCounter.getCount();
    service.findCustomersWithOrders('US');
    long queriesAfter = sqlCounter.getCount();

    // Assert: should be 1 query (or 2 with batch), not 11
    assertThat(queriesAfter - queriesBefore).isLessThan(3);
}
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Libraries: db-util (Vlad Mihalcea), datasource-proxy-assert.
This prevents regression: if someone adds a lazy association later,
the test fails with 'Expected < 3 queries, got 12.'
Run these tests in your CI pipeline."

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



