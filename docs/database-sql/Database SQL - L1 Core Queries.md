---
layout: default
title: "Database SQL - L1 Core Queries"
parent: "Database SQL"
grand_parent: "SK Interview"
nav_order: 3
permalink: /database-sql/l1-core-queries/
render_with_liquid: false
---

# SELECT Statement - Reading Rows from Tables

**TL;DR:** SELECT is the most-used SQL statement. It retrieves rows
from one or more tables. The key clauses: FROM (which table), WHERE
(which rows), ORDER BY (in what order). SELECT is declarative - you
describe the result set, and the optimizer decides how to retrieve it.

---

### 🎯 Model Answer

**30 seconds:**
> SELECT retrieves rows from a table. The minimum form: `SELECT columns FROM table`.
> Add WHERE to filter rows. Add ORDER BY to sort. Add LIMIT to cap results.
> SELECT is declarative: you describe the result, and the optimizer plans
> the retrieval. The execution order is FROM first, WHERE second,
> SELECT last.

**3 minutes:**
> SELECT has a written order and an execution order that differ.
> Written: SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY.
> Executed: FROM, WHERE, GROUP BY, HAVING, SELECT, ORDER BY.
>
> The practical implication: column aliases defined in SELECT are not
> visible in WHERE. A function applied to a column in WHERE prevents
> index use. `SELECT *` fetches all columns, which prevents covering
> indexes and over-fetches data.
>
> Projecting only the columns you need is important for three reasons:
> (1) reduces data transferred over the network; (2) allows covering
> index scans (the index satisfies the query without touching the table);
> (3) makes the query's intent explicit to both the optimizer and readers.

**Blank Mind Recovery:**

**(1) Restate:** "SELECT columns FROM table WHERE condition ORDER BY
col LIMIT n. Execution: FROM, WHERE, SELECT, ORDER BY."

**(2) First principles:** "A SELECT is a filter + projection + ordering
over a set of rows. Filter = WHERE. Projection = column list.
Ordering = ORDER BY."

**(3) Bridge:** "Like asking a library for books. 'Bring me (SELECT)
the titles and authors (projection) from the fiction section (FROM table)
where the author is Tolkien (WHERE) sorted by year (ORDER BY).' The
librarian decides how to find them (optimizer)."

---

### 📘 Concept Explanation

**Basic SELECT anatomy:**

```sql
SELECT  column1, column2, expression AS alias
FROM    schema_name.table_name  -- fully qualified
WHERE   condition
ORDER BY column1 ASC, column2 DESC
LIMIT   n
OFFSET  m;
```

**Column expressions in SELECT:**

- Simple column: `first_name`
- Aliased column: `first_name AS name`
- Expression: `price * quantity AS line_total`
- Function: `UPPER(email) AS email_upper`
- Conditional: `CASE WHEN status = 'A' THEN 'Active' ELSE 'Inactive' END`

**NULL in SELECT:**

NULL comparisons require `IS NULL` or `IS NOT NULL`, not `= NULL`.
NULL in expressions propagates: `100 + NULL = NULL`, `'name' || NULL = NULL`.

---

### 💻 Code Example

```sql
-- SELECT FUNDAMENTALS

-- BAD: select star in production code
SELECT * FROM orders WHERE customer_id = 123;
-- Fetches all 20 columns including blob fields.
-- Prevents covering index scans.
-- Breaks if columns are added/reordered.

-- GOOD: name only the columns you need
SELECT id, status, total_cents, created_at
FROM orders
WHERE customer_id = 123
ORDER BY created_at DESC
LIMIT 20;
-- Only 4 columns transferred.
-- If an index covers (customer_id, created_at, id,
--   status, total_cents): index-only scan, no heap access.

-- EXPRESSIONS AND ALIASES
SELECT
    id,
    total_cents / 100.0     AS total_dollars,
    UPPER(status)           AS status_display,
    DATE(created_at)        AS order_date,
    CASE
        WHEN total_cents > 100000 THEN 'large'
        WHEN total_cents > 10000  THEN 'medium'
        ELSE 'small'
    END                     AS order_size
FROM orders
WHERE customer_id = :customer_id;
```

> **Code walkthrough:** The BAD query fetches `*` - 20 columns including
> any large TEXT or BYTEA fields, even though only 4 are needed. The
> GOOD query names columns explicitly. `total_cents / 100.0` converts
> integer cents to decimal dollars (divide by an integer would truncate).
> `UPPER(status)` is for display only; do not use function calls in WHERE
> as they prevent index use. The `CASE` expression categorizes order
> size inline without requiring a join to a categories table.

```sql
-- NULL HANDLING IN SELECT

-- BAD: comparing with = NULL (always false)
SELECT id FROM customers WHERE phone = NULL;
-- Returns 0 rows. phone = NULL is always false.
-- Even rows where phone IS NULL are excluded.

-- GOOD: use IS NULL / IS NOT NULL
SELECT id FROM customers WHERE phone IS NULL;

-- NULL in expressions
SELECT
    id,
    COALESCE(phone, 'N/A')  AS phone_display,
    NULLIF(discount_pct, 0) AS discount_pct_or_null
FROM customers;
-- COALESCE: return first non-null value
-- NULLIF: return null if first = second (useful for 0/null)
```

> **Code walkthrough:** `phone = NULL` always evaluates to NULL (unknown),
> not FALSE - SQL three-valued logic: TRUE, FALSE, UNKNOWN. WHERE
> requires TRUE to include the row; UNKNOWN excludes it. `IS NULL` is
> the correct predicate. `COALESCE(phone, 'N/A')` returns the phone if
> not NULL, else 'N/A'. `NULLIF(discount_pct, 0)` returns NULL when
> discount is 0 (useful when you want to treat zero as absent).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> SELECT reads rows from a table. Minimum: `SELECT columns FROM table`.
> WHERE filters which rows are returned. ORDER BY sorts them.
> LIMIT caps the count. NULL requires `IS NULL`, not `= NULL`.
> Always name specific columns in production code instead of `SELECT *`.

---

**Senior / Staff:**
> The columns you SELECT affect the query plan. If an index covers all
> selected columns: the database does an index-only scan (never touches
> the heap/table). Adding one non-indexed column to SELECT forces the
> database to also read the heap pages. For high-frequency queries on
> large tables: designing the SELECT list to match a covering index is
> a significant performance optimization. This is why "name your columns"
> is not just style - it enables covering index scans.

---

### ⚠️ Common Misconceptions

**"SELECT 1 vs SELECT * for existence checks"**

Reality: `SELECT 1 FROM table WHERE ...` and `SELECT * FROM table WHERE ...`
both work for existence checks, but `SELECT 1` is clearer (no columns
needed). However, `EXISTS (SELECT 1 FROM ...)` is the proper idiom -
EXISTS short-circuits on the first matching row, unlike a COUNT query.

**"LIMIT without ORDER BY is fine for performance"**

Reality: LIMIT without ORDER BY returns an arbitrary subset of rows.
The set is not stable: running the same query twice may return different
rows. Additionally, without an ORDER BY that matches an index, the
database may still scan a large portion of the table before finding
`n` matching rows (especially with a WHERE clause that filters heavily).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Function on column prevents index use**

```sql
-- BAD (full table scan):
WHERE LOWER(email) = 'user@example.com'

-- FIX 1: store emails lowercased (enforce at insert)
WHERE email = LOWER(:input_email)

-- FIX 2: functional index
CREATE INDEX idx_customers_email_lower
    ON customers (LOWER(email));
WHERE LOWER(email) = 'user@example.com'  -- uses index
```

---

### 🎯 Interview Deep-Dive

**Q1: Why does SELECT * prevent covering index scans?**

🗣️ "A covering index contains all columns needed to answer a query.
If `SELECT id, status FROM orders WHERE customer_id = ?` and there's
an index on `(customer_id, id, status)`: the database reads only the
index, never touching the table data pages (index-only scan). With
`SELECT *`: the query needs all 20 columns; the index only has 3.
The database must also read the heap pages for the remaining 17 columns.
This doubles (or more) the I/O. For high-frequency queries: designing
SELECT to match a covering index is a primary performance optimization."

**Q2: What is the three-valued logic in SQL and why does it matter?**

🗣️ "SQL has three truth values: TRUE, FALSE, and UNKNOWN. UNKNOWN occurs
when NULL is involved in a comparison. `NULL = NULL` is UNKNOWN (not TRUE).
`NULL != 5` is UNKNOWN. WHERE includes rows where the condition is TRUE;
it excludes rows where the condition is FALSE or UNKNOWN. This is why
`WHERE phone = NULL` returns no rows - the condition is UNKNOWN for
every row. The correct predicate is `IS NULL`. UNKNOWN also propagates
through AND/OR, following specific rules (TRUE AND UNKNOWN = UNKNOWN,
FALSE AND UNKNOWN = FALSE, TRUE OR UNKNOWN = TRUE)."

**Q3: When should you use DISTINCT and what is the performance cost?**

🗣️ "DISTINCT eliminates duplicate rows. The database sorts or hashes
the entire result to find and remove duplicates - O(n log n) or O(n)
plus memory. Use DISTINCT when: the query naturally produces duplicates
(a join that multiplies rows) and you genuinely need unique values.
Do NOT use DISTINCT as a lazy fix for a join that produces duplicates -
fix the join. Alternative: if you are grouping anyway (`GROUP BY`),
grouping already eliminates duplicates. For existence checks: `EXISTS`
is faster than `DISTINCT COUNT`. Check DISTINCT in query profiles -
it is often a performance red flag."

**Q4: What is a derived table and when would you use one?**

🗣️ "A derived table is a subquery in the FROM clause, used as a table:
`SELECT * FROM (SELECT id, SUM(amount) FROM orders GROUP BY id) AS t`.
Use when: you need to filter or join on an aggregate result but cannot
use HAVING. Example: find customers whose total order value is in the
top 10% of all customers - compute the aggregate first (derived table),
then join or filter on it. CTEs (`WITH`) are the modern alternative -
more readable and sometimes the optimizer can refer to them multiple times."

**Q5: How does EXPLAIN help diagnose slow SELECT queries?**

🗣️ "EXPLAIN shows the query execution plan: which tables are accessed,
which indexes are used, the join order, and estimated row counts.
`EXPLAIN ANALYZE` actually executes the query and shows real row counts
and timing. Key things to look for: (1) Seq Scan on a large table with
a small WHERE result = missing index; (2) Rows= estimate far off from
actual rows = stale statistics (run ANALYZE); (3) Hash Join vs. Nested
Loop - hash joins are efficient for large row counts; nested loop is
efficient when the inner side is small. The cost= estimate is in arbitrary
units; compare relative costs between plan nodes."

**Q6: What is predicate pushdown and why does it matter?**

🗣️ "Predicate pushdown: the optimizer moves WHERE conditions as close
to the data source as possible. Instead of fetching all rows and then
filtering: filter at the storage layer. For partitioned tables:
a WHERE on the partition key causes the optimizer to scan only
matching partitions (partition pruning). For views and CTEs: predicates
from the outer query may be pushed into the view. If pushdown works:
far fewer rows are read. If pushdown fails (e.g., the WHERE condition
references a function that the optimizer cannot simplify): more rows
are fetched and filtered later in the plan, which is slower."

**Q7: What does LIMIT with OFFSET do and why is it problematic at large offsets?**

🗣️ "LIMIT n OFFSET m tells the database to skip the first m rows and
return the next n. For page 1 (offset 0): fast. For page 100 with
20 rows/page (offset 2000): the database must retrieve and discard
2,000 rows before returning the 20 you want. Cost scales with offset.
For large tables with high page numbers: this becomes a performance
problem. The fix: keyset pagination. Instead of page number, pass the
last-seen ID: `WHERE id > :last_id ORDER BY id LIMIT 20`. The index
jumps directly to `:last_id`, returns the next 20, O(log n) regardless
of position. Works for most pagination UIs; does not work for random
page access."

---

# WHERE Clause - Filtering Rows with Conditions

**TL;DR:** WHERE filters rows before they reach SELECT. Every WHERE
predicate is evaluated for each candidate row. Predicates on indexed
columns enable fast lookups. Predicates that wrap columns in functions
or use leading wildcards defeat indexes. Writing WHERE correctly is
the single biggest factor in query performance.

---

### 🎯 Model Answer

**30 seconds:**
> WHERE filters which rows are returned. Conditions use comparison
> operators (=, !=, <, >, <=, >=), logical operators (AND, OR, NOT),
> range predicates (BETWEEN, IN), NULL checks (IS NULL, IS NOT NULL),
> and pattern matching (LIKE). The critical performance rule: predicates
> on indexed columns must be written without wrapping the column in a
> function or expression, or the index cannot be used.

**3 minutes:**
> The most important WHERE performance rule: a predicate is sargable
> (Search ARGument ABLE) if the database can use an index to satisfy it.
> `WHERE created_at >= '2024-01-01'` is sargable: the index on created_at
> can be range-scanned. `WHERE YEAR(created_at) = 2024` is not sargable:
> the YEAR() function is applied to every row, and the index cannot be
> used because the index stores the raw column value, not the YEAR()
> result.
>
> Complex WHERE conditions: AND is efficient (each condition reduces the
> row count; with multiple indexed columns, composite indexes help).
> OR is expensive: the optimizer may need to scan two index ranges and
> union the results, or fall back to a sequential scan. `IN (value1, value2, ...)`
> is typically rewritten by the optimizer as an OR with index seeks.
>
> WHERE with correlated subqueries: a subquery that references the outer
> query executes once per outer row. For large tables: O(n) subquery
> executions = O(n^2) total work.

**Blank Mind Recovery:**

**(1) Restate:** "WHERE filters rows. Sargable = index can be used.
Avoid functions on columns. AND reduces rows; OR is expensive."

**(2) First principles:** "A WHERE predicate is a function from a row to
boolean. If the database can use an index to skip most rows without
evaluating the predicate: fast. If it must evaluate the predicate on
every row: slow."

**(3) Bridge:** "Like searching a phone book. Looking up 'Smith' uses
the alphabetical index (sargable). Looking for 'everyone whose name
has 7 letters' requires scanning every name (not sargable)."

---

### 📘 Concept Explanation

**Sargability rules:**

```
SARGABLE (uses index):
  WHERE col = :value
  WHERE col > :value
  WHERE col BETWEEN :low AND :high
  WHERE col IN (:v1, :v2, :v3)
  WHERE col LIKE 'prefix%'   -- leading chars known

NOT SARGABLE (full scan):
  WHERE FUNCTION(col) = :value
    e.g. WHERE YEAR(created_at) = 2024
    e.g. WHERE LOWER(email) = 'x@y.com'
  WHERE col LIKE '%suffix'   -- leading wildcard
  WHERE col != :value        -- range scan entire index
  WHERE col IS NULL          -- depends on index type
```

**AND vs OR performance:**

```
AND: optimizer can use the most selective predicate first.
  WHERE country = 'US' AND status = 'ACTIVE'
  Both conditions in a composite index: one index scan.
  One condition indexed: scan index, evaluate second.

OR: must satisfy either branch. Optimizer options:
  1. Bitmap OR: scan both indexes, combine bitmaps.
  2. UNION ALL: execute each branch separately, union.
  3. Full scan if OR conditions are not well indexed.
  Often slower than AND predicates.
```

**NULL handling in WHERE:**

```sql
-- NULL comparisons are UNKNOWN, not FALSE:
WHERE col = NULL     -- always returns 0 rows (UNKNOWN)
WHERE col != NULL    -- always returns 0 rows (UNKNOWN)

-- Correct:
WHERE col IS NULL
WHERE col IS NOT NULL

-- COALESCE to treat NULL as a value:
WHERE COALESCE(discount_pct, 0) > 10
-- Note: this is NOT sargable (COALESCE wraps the column)
-- Better: WHERE discount_pct > 10 OR discount_pct IS NULL
```

---

### 💻 Code Example

```sql
-- SARGABILITY: writing index-friendly predicates

-- BAD: function on column (full table scan)
WHERE YEAR(order_date) = 2024
WHERE DATE_FORMAT(created_at, '%Y-%m') = '2024-01'
WHERE LOWER(email) = 'user@example.com'

-- GOOD: range predicates (index range scan)
WHERE order_date >= '2024-01-01'
  AND order_date <  '2025-01-01'

WHERE created_at >= '2024-01-01'
  AND created_at <  '2024-02-01'

-- For case-insensitive email: store lowercase,
-- compare lowercase
WHERE email = LOWER(:input_email)
-- Or use a functional index:
-- CREATE INDEX ON customers (LOWER(email));
-- Then: WHERE LOWER(email) = LOWER(:input)
```

> **Code walkthrough:** `YEAR(order_date) = 2024` requires evaluating
> the YEAR() function on every row - full table scan. The equivalent
> `order_date >= '2024-01-01' AND order_date < '2025-01-01'` is a range
> predicate: the B-tree index on `order_date` can seek to the first
> 2024 date and scan forward until the 2025 boundary. For a table with
> 10 million orders over 10 years, the range scan reads 1/10 of the
> index; the function-on-column approach reads all of it.

```sql
-- IN CLAUSE vs OR vs BETWEEN

-- BAD: many ORs (readable but verbose)
WHERE status = 'PENDING'
  OR  status = 'PLACED'
  OR  status = 'PROCESSING'

-- GOOD: IN clause (same plan, cleaner)
WHERE status IN ('PENDING', 'PLACED', 'PROCESSING')
-- Optimizer rewrites as OR internally; same plan.
-- More readable and maintainable.

-- BAD: IN with many values (1000+) - causes plan issues
WHERE id IN (1, 2, 3, ... 10000 values)
-- PostgreSQL: becomes a hash semi-join. Generally OK.
-- MySQL: may hit expression limit. Consider temp table.

-- GOOD for large IN sets: temp table join
CREATE TEMP TABLE ids_to_process (id BIGINT);
INSERT INTO ids_to_process VALUES (1), (2), ...;
SELECT o.* FROM orders o
JOIN ids_to_process t ON t.id = o.id;
-- Index join instead of large IN clause.
```

> **Code walkthrough:** `IN ('a', 'b', 'c')` is equivalent to three OR
> conditions. The optimizer recognizes this and uses the index on `status`
> (if one exists). For very large IN lists (thousands of values):
> the optimizer may struggle with planning. The temp table join approach
> creates a small table of target IDs and joins it - the optimizer can
> use a hash join or merge join, which is more efficient than a large
> IN predicate.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> WHERE filters rows. Use comparison operators (=, !=, <, >), BETWEEN
> for ranges, IN for multiple values, LIKE for patterns, IS NULL for
> null checks. The most important performance rule: avoid wrapping indexed
> columns in functions - this forces a full table scan. Write range
> predicates instead of date function predicates.

---

**Senior / Staff:**
> Every WHERE predicate is either sargable (can use an index) or not.
> Non-sargable predicates are full-table scans waiting to happen.
> The WHERE clause writing style I enforce in code review: (1) never
> wrap indexed columns in functions; (2) use explicit range predicates
> for date filters; (3) ensure OR conditions are covered by indexes.
> The EXPLAIN plan always validates: look for Seq Scan where you expect
> Index Scan.

---

### ⚠️ Common Misconceptions

**"BETWEEN is inclusive on both ends"**

Reality: `BETWEEN low AND high` is inclusive on both sides: `col >= low AND col <= high`.
For datetime ranges, this causes an off-by-one: `BETWEEN '2024-01-01' AND '2024-01-31'`
includes rows at `2024-01-31 23:59:59`. Use explicit `>= AND <` for clarity:
`created_at >= '2024-01-01' AND created_at < '2024-02-01'`.

**"NOT IN with NULL in the list always returns 0 rows"**

Reality: `WHERE id NOT IN (1, 2, NULL)` returns 0 rows for any id.
`x NOT IN (1, 2, NULL)` is equivalent to `x != 1 AND x != 2 AND x != NULL`.
The last condition is UNKNOWN, making the entire AND UNKNOWN. Use
`NOT EXISTS` instead of `NOT IN` when the subquery might return NULLs.

---

### 🚨 Failure Modes and Diagnosis

**Failure: OR condition causes sequential scan on large table**

```sql
-- Slow: OR on two columns from different indexes
WHERE status = 'PENDING' OR user_id = 123
-- May not use either index efficiently.

-- Fix: UNION ALL with two index-friendly queries
SELECT * FROM orders WHERE status = 'PENDING'
UNION ALL
SELECT * FROM orders WHERE user_id = 123
  AND status != 'PENDING';
-- Each branch uses its own index.
```

---

### 🎯 Interview Deep-Dive

**Q1: What does sargable mean and why does it matter?**

🗣️ "Sargable: Search ARGument ABLE. A predicate is sargable if the
database engine can use an index to satisfy it directly, without scanning
all rows. Rules: (1) the column must appear alone on one side of the
comparison (no function wrapping it); (2) comparison must be =, >, <,
>=, <=, BETWEEN, IN, or LIKE with a non-wildcard prefix. Non-sargable:
function on column (`YEAR(date) = 2024`), leading wildcard (`LIKE '%suffix'`),
expression on column (`col * 2 > 100` - rewrite as `col > 50`).
Non-sargable = full table scan on large tables = slow queries."

**Q2: Why is OR in WHERE slower than AND?**

🗣️ "AND: each condition reduces the candidate rows. The optimizer picks
the most selective predicate and evaluates others as a post-filter.
With a composite index: both conditions may be satisfied in one index scan.
OR: the result is the union of rows satisfying either condition. The
optimizer must: (1) use a bitmap index OR (scan both indexes, combine
bitmaps); (2) execute two separate scans and union them. Neither is as
efficient as a single index scan. For `WHERE a = 1 OR b = 2`: if both
`a` and `b` are indexed, PostgreSQL may do a bitmap OR. If neither or
only one is indexed: sequential scan. UNION ALL is often the manual
optimization: two queries each using their own index."

**Q3: How does a composite index affect WHERE clause planning?**

🗣️ "A composite index on (a, b, c) supports queries that filter on: `a`,
`a AND b`, `a AND b AND c`. It does NOT support queries that filter on
`b` alone, `c` alone, or `b AND c` (the leading column must be present).
The leftmost prefix rule. For `WHERE a = 1 AND b = 2`: a composite
index `(a, b)` narrows to all rows with `a=1` (equality on first column),
then filters to `b=2` within that range. For `WHERE a = 1 AND c = 3`:
the index can be used for `a=1` but `c=3` is a post-filter (the index
has `b` between `a` and `c`). Column order matters for index effectiveness."

**Q4: What is an index skip scan?**

🗣️ "An index skip scan (Oracle term, also called 'loose index scan'
in MySQL, 'index skip scan' in Oracle, partially supported in PostgreSQL 14+):
when the leading column of a composite index has low cardinality (few
distinct values), the optimizer can 'skip' to each distinct leading value
and scan the rest of the index, enabling use of the composite index even
when the leading column is not in the WHERE clause. Example: index on
(gender, age) with 2 distinct gender values. Query `WHERE age > 30`:
normally not sargable (leading column not filtered). With skip scan:
the optimizer tries both 'M+age>30' and 'F+age>30'. Works when the
number of distinct leading values is very low."

**Q5: How do you handle dynamic WHERE clauses in application code safely?**

🗣️ "Dynamic WHERE (different filter combinations per request) must always
use parameterized queries, never string concatenation. In Java/JDBC:
build the query with conditional clauses, always using `?` or named
parameters for values. In JPA Criteria API or QueryDSL: add predicates
conditionally, compile to parameterized SQL. In MyBatis: `<if test='...'>` 
tags within `<where>` block. Never: `WHERE name = '\" + userInput + \"'`
(SQL injection). Parameterized queries: (1) prevent SQL injection;
(2) allow the database to cache and reuse the execution plan for different
parameter values (plan cache hit)."

**Q6: What is index selectivity and how does it affect WHERE performance?**

🗣️ "Selectivity: the fraction of rows a predicate returns. High selectivity:
`WHERE id = 12345` returns 1 row / 10M rows = 0.00001%. Low selectivity:
`WHERE status = 'ACTIVE'` returns 9M rows / 10M rows = 90%.
The optimizer uses selectivity to decide whether to use an index.
If the index predicate returns > 10-20% of rows: a sequential scan is
cheaper than an index scan (indexes have per-row overhead for heap
fetches). Low-selectivity predicates on large tables should either be
combined with high-selectivity predicates (AND) or redesigned.
`status = 'ACTIVE'` with no other filter: index may not help."

**Q7: What are parameterized queries and why are they essential?**

🗣️ "Parameterized queries (also called prepared statements) separate
SQL structure from data values. The SQL template is compiled once; values
are bound at execution time as typed parameters. Benefits: (1) SQL
injection prevention - the value is never interpreted as SQL syntax,
only as data; (2) plan caching - the database compiles the plan once
and reuses it for different parameter values; (3) type safety - the
driver validates the parameter type before sending.
Never use string formatting or concatenation to build SQL with user
input. Even 'safe' inputs like integers should be parameterized for
clarity and consistency. In Java: JDBC PreparedStatement, Spring JdbcTemplate
named parameters, JPA JPQL named parameters (:name) - all safe.
Raw string concatenation in any SQL-building code is always wrong."

---

# ORDER BY and LIMIT - Sorting and Pagination

**TL;DR:** ORDER BY specifies the result order. LIMIT caps the number
of rows returned. Together they implement pagination. For correctness:
ORDER BY must include a unique column as a tiebreaker. For performance:
OFFSET pagination degrades at large page numbers; keyset pagination
(cursor-based) scales.

---

### 🎯 Model Answer

**30 seconds:**
> ORDER BY sorts the result. LIMIT caps the row count. For stable
> pagination: always include a unique column in ORDER BY (otherwise ties
> produce non-deterministic order between pages). For high-performance
> pagination: use keyset pagination (WHERE id > :last_seen_id) instead
> of OFFSET, which requires the database to skip and discard rows.

**3 minutes:**
> ORDER BY performance: if the query sorts by an indexed column, the
> database can use the index order and avoid an explicit sort. An index
> on `created_at DESC` means `ORDER BY created_at DESC` is "free" -
> no sort step in the plan. Without matching index: the database fetches
> all qualifying rows, sorts them in memory (or spills to disk for large
> sorts), then returns the top n. Expensive.
>
> OFFSET pagination: page 1 with LIMIT 20 OFFSET 0 is fast. Page 50
> with OFFSET 1000: the database fetches 1,020 rows and discards the
> first 1,000. For page 500 with OFFSET 10,000: 10,020 rows fetched,
> 10,000 discarded. Cost scales linearly with offset.
>
> Keyset pagination (cursor-based): `WHERE id > :last_seen_id ORDER BY id LIMIT 20`.
> The WHERE clause jumps to the last seen position using the index.
> Cost is O(log n) regardless of page depth. This is how production
> APIs implement infinite scroll and deep pagination.

**Blank Mind Recovery:**

**(1) Restate:** "ORDER BY sorts. LIMIT caps. OFFSET pagination is O(offset).
Keyset pagination is O(log n). Always add unique column to ORDER BY."

**(2) First principles:** "Sorting requires seeing all candidates.
An index pre-sorts data. OFFSET discards sorted rows. Keyset pagination
uses the index to skip discarded rows."

**(3) Bridge:** "Like page-turning a book. Offset: start from page 1,
turn pages until you reach page 50 (discarding all pages in between).
Keyset: use the bookmark at page 49 and go directly to page 50."

---

### 📘 Concept Explanation

**ORDER BY:**

```sql
-- Single column
ORDER BY created_at DESC

-- Multiple columns (primary sort, then tiebreaker)
ORDER BY status ASC, created_at DESC

-- Expression
ORDER BY total_cents * -1  -- effectively DESC

-- NULLs in ORDER BY:
-- Standard SQL: NULLs sort LAST in ASC (lowest = last)
-- PostgreSQL: NULLS FIRST / NULLS LAST explicit control
ORDER BY updated_at DESC NULLS LAST
```

**LIMIT / OFFSET vs keyset pagination:**

```
OFFSET pagination:
  Page 1: LIMIT 20 OFFSET 0    -- reads rows 1-20
  Page 2: LIMIT 20 OFFSET 20   -- reads rows 1-40, returns 21-40
  Page N: LIMIT 20 OFFSET N*20 -- reads rows 1 to (N+1)*20

Keyset pagination:
  Page 1: WHERE id > 0 ORDER BY id LIMIT 20
          -- returns ids 1-20, last_seen = 20
  Page 2: WHERE id > 20 ORDER BY id LIMIT 20
          -- index seek to id=20, returns 21-40
  Page N: WHERE id > :last_seen ORDER BY id LIMIT 20
          -- always O(log n)
```

---

### 💻 Code Example

```sql
-- ORDER BY STABILITY: adding a tiebreaker

-- BAD: ORDER BY on non-unique column (unstable)
SELECT id, name, status
FROM   products
ORDER BY status ASC
LIMIT  20;
-- If 1000 products have status='ACTIVE':
-- which 20 are returned? Undefined.
-- Page 1 and Page 2 might return overlapping rows.

-- GOOD: unique tiebreaker (stable pagination)
SELECT id, name, status
FROM   products
ORDER BY status ASC, id ASC  -- id is unique
LIMIT  20;
-- Stable: same rows on every run for the same data.

-- KEYSET PAGINATION (performance solution)

-- Page 1
SELECT id, name, status
FROM   products
ORDER BY id ASC
LIMIT  20;
-- Returns rows with id 1-20. Client stores last_id = 20.

-- Page 2 (keyset, not offset)
SELECT id, name, status
FROM   products
WHERE  id > 20        -- cursor from previous page
ORDER BY id ASC
LIMIT  20;
-- Index seek to id=20, returns 21-40. O(log n).
-- No rows wasted scanning and discarding.
```

> **Code walkthrough:** The BAD ORDER BY lacks a tiebreaker. For
> multi-page pagination: without a unique tiebreaker, rows with equal
> `status` values may appear on different pages in different runs
> (or the same row may appear on two pages). The GOOD query adds `id ASC`
> as a tiebreaker - id is unique, so the order is fully deterministic.
> Keyset pagination: `WHERE id > 20` uses the primary key index to jump
> directly to id=20 and scan forward. For page 1,000 with OFFSET: the
> database must scan and discard 20,000 rows. Keyset: always reads
> exactly 20 rows regardless of depth.

```sql
-- SORTING WITHOUT MATCHING INDEX: when sorts are expensive

-- EXPLAIN ANALYZE this query:
SELECT id, name, created_at
FROM products
ORDER BY created_at DESC
LIMIT 20;

-- Without index on created_at:
-- Sort (actual time=450.123..450.456 rows=20)
--   -> Seq Scan on products (rows=1000000)
-- Sorts 1M rows to return top 20.

-- With index: CREATE INDEX ON products(created_at DESC);
-- Limit (actual time=0.089..0.095 rows=20)
--   -> Index Scan using idx_products_created_at
--      on products (rows=20)
-- Reads 20 rows directly from index. No sort.

-- Sort performance matters most for:
-- "Get the latest N" queries (ORDER BY timestamp DESC LIMIT N)
-- These are extremely common; index them.
```

> **Code walkthrough:** Without an index on `created_at`: the database
> does a sequential scan of all 1 million rows, sorts them (in memory
> or on disk), and returns the top 20. Execution time: hundreds of
> milliseconds. With a `DESC` index on `created_at`: the index stores
> rows in descending timestamp order. The database reads the first 20
> entries from the index - no sort, no full scan. Sub-millisecond.
> "Latest N records" is one of the most common query patterns; always
> index the sort column for these queries.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> ORDER BY sorts results; LIMIT caps the row count. For pagination:
> add a unique column to ORDER BY as a tiebreaker for stable results.
> OFFSET pagination (page 50 = skip 1000 rows) degrades at large page
> numbers because the database still reads all the skipped rows.
> Keyset pagination uses `WHERE id > :last_id` to jump directly to
> the next page position using the index - much faster.

---

**Senior / Staff:**
> The ORDER BY and LIMIT combination has two performance dimensions:
> (1) whether the sort is served by an index (free) or requires a
> sort step (expensive for large result sets); (2) whether pagination
> uses OFFSET (O(offset)) or keyset (O(log n)). In practice:
> "get the latest N" queries need a DESC index on the sort column.
> API pagination endpoints need keyset pagination to scale beyond
> a few hundred pages. These two are among the most common query
> patterns and the most commonly missed optimizations.

---

### ⚠️ Common Misconceptions

**"ORDER BY is optional for consistent results"**

Reality: without ORDER BY, SQL makes no ordering guarantee. The same
query may return rows in different orders on different runs due to
buffer pool state, parallel worker assignment, or index reorganization.
Any application that relies on unspecified order is a latent bug.

**"LIMIT without ORDER BY is a performance optimization"**

Reality: `LIMIT 1` without ORDER BY returns an arbitrary row. The
database may still perform a full table scan if it cannot use an index
to satisfy the query. LIMIT reduces the output rows but does not
necessarily reduce the input scan rows.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Duplicate rows across pages with OFFSET pagination**

Symptom: page 2 returns a row already seen on page 1. This happens
when ORDER BY is non-unique and new rows are inserted between page
fetches, shifting the offset.

Fix: add a unique tiebreaker to ORDER BY. Use keyset pagination.

**Failure: Sort spilling to disk for large result sets**

Symptom: `EXPLAIN ANALYZE` shows "Sort Method: external merge Disk".
Query is 10-100x slower than expected.

Diagnosis: `work_mem` (PostgreSQL) is insufficient for the sort.

Fix: either increase `work_mem` for the session (`SET work_mem = '256MB'`),
add an index to avoid the sort, or reduce the rows before sorting
with a tighter WHERE clause.

---

### 🎯 Interview Deep-Dive

**Q1: Why must ORDER BY include a unique column for stable pagination?**

🗣️ "SQL rows have no inherent physical order. For a result with ties
on the ORDER BY columns: the database is free to return tied rows in
any order. On subsequent runs (or between pages of a paginated result):
the tie-breaking order may change due to buffer pool state or query plan
changes. If page 1 uses LIMIT 20 OFFSET 0 and page 2 uses LIMIT 20
OFFSET 20: if two rows with equal sort values straddle the page boundary,
they might both appear on page 2 (or neither). Adding a unique tiebreaker
(typically id) makes the order fully deterministic and the pagination stable."

**Q2: How does the database sort rows that do not fit in memory?**

🗣️ "External sort (external merge sort): (1) Sort phase: divide the input
into chunks that fit in `work_mem`. Sort each chunk. Write sorted chunks
to temp files on disk. (2) Merge phase: merge-sort the sorted chunks.
For n chunks: up to log(n) passes through the temp files. The cost:
disk I/O for writing and reading temp files, which is 10-100x slower
than in-memory sort. `EXPLAIN ANALYZE` shows 'Sort Method: external
merge Disk: 42MB'. Fix: increase `work_mem`, add an index to avoid
the sort, or reduce the rows with a more selective WHERE."

**Q3: What is the difference between stable and unstable sorts in databases?**

🗣️ "A stable sort preserves the original order of equal elements.
An unstable sort may reorder elements with equal sort keys.
PostgreSQL uses an unstable sort (quicksort variant) for in-memory sorts.
For stable pagination: this means equal elements may be ordered differently
between runs. The fix is the same: add a unique tiebreaker to ORDER BY.
The term 'stable' is important when ORDER BY includes expressions or
derived columns that may produce ties - the application must add a
unique tiebreaker to get stable results, regardless of the sort algorithm."

**Q4: How does a partial index improve ORDER BY LIMIT queries?**

🗣️ "A partial index covers only rows matching a WHERE condition.
Example: `CREATE INDEX idx_orders_pending ON orders(created_at) WHERE status = 'PENDING'`.
For `SELECT * FROM orders WHERE status = 'PENDING' ORDER BY created_at LIMIT 10`:
the partial index is smaller (contains only PENDING rows), the scan reads
only PENDING rows in created_at order, and LIMIT 10 stops after 10 rows.
Compared to a full index on `(status, created_at)`: the partial index
is smaller (fewer index pages to read), and reads fewer rows in the scan.
Useful for frequent queries that filter on a low-cardinality status column."

**Q5: What is a covering index for ORDER BY and how does it work?**

🗣️ "A covering index includes all columns needed by the query: the WHERE
columns, the ORDER BY columns, and the SELECT columns. For a query
`SELECT id, name WHERE status = 'A' ORDER BY created_at`:
an index on `(status, created_at, id, name)` covers it entirely.
The database reads only the index (no heap access), the ORDER BY is
served by the index order, and LIMIT stops the scan early. This is the
'index-only scan with early termination' pattern - the fastest possible
execution for sorted pagination. Design high-frequency pagination queries
around covering indexes."

**Q6: When should you avoid LIMIT for correctness reasons?**

🗣️ "LIMIT without ORDER BY is incorrect for anything requiring
deterministic results. Additionally: LIMIT with OFFSET for batch
processing is incorrect if the underlying data changes between batches.
Example: delete rows in batches using `DELETE FROM ... WHERE id IN
(SELECT id FROM ... LIMIT 1000)`. If other transactions insert rows
during the delete: the same rows may appear in the next batch's LIMIT.
The correct pattern for batch processing: use a cursor or WHERE id > :last
to advance deterministically. For reporting that requires all rows:
do not use LIMIT (or use it only for UI pagination, not data processing)."

**Q7: What happens to ORDER BY and LIMIT in parallel query execution?**

🗣️ "PostgreSQL parallel query: multiple worker processes each scan a
partition of the table. Each worker produces a partial sorted result.
A Gather Merge node merges the sorted outputs from workers. LIMIT is
applied after the merge. Challenge: each worker must sort its partition,
which requires `work_mem` per worker. For 4 parallel workers and 256MB
work_mem: up to 1GB total memory for the sort. The Gather Merge overhead
is significant for small result sets - parallel query is not always faster.
PostgreSQL disables parallel query for very small LIMIT values (< 1000)
because the coordination overhead exceeds the sorting benefit."
