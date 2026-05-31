---
layout: default
title: "Database SQL - L1 Joins and Aggregates"
parent: "Database SQL"
grand_parent: "SK Interview"
nav_order: 5
permalink: /database-sql/l1-joins-aggregates/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [INNER JOIN - Combining Tables on Matching Rows](#inner-join---combining-tables-on-matching-rows) | medium |
| 2 | [LEFT JOIN and RIGHT JOIN - Including Unmatched Rows](#left-join-and-right-join---including-unmatched-rows) | medium |
| 3 | [Aggregate Functions - COUNT, SUM, AVG, GROUP BY, HAVING](#aggregate-functions---count-sum-avg-group-by-having) | medium |

---

# INNER JOIN - Combining Tables on Matching Rows

**TL;DR:** INNER JOIN returns only rows where the join condition matches
in both tables. It is the most common join type. The join condition
is almost always `ON table_a.foreign_key = table_b.primary_key`.
INNER JOIN excludes rows that have no match in the other table.

---

### 🎯 Model Answer

**30 seconds:**
> INNER JOIN returns rows from two tables where the join condition
> matches in both. `SELECT ... FROM orders o INNER JOIN customers c
> ON o.customer_id = c.id`. Orders with no matching customer are excluded.
> Customers with no orders are excluded. Both sides must match.

**3 minutes:**
> A join is a cross product (every row in A with every row in B) filtered
> by a condition. The optimizer does not literally compute the cross product -
> it chooses between nested loop join (one table indexed), hash join
> (both tables large), or merge join (both tables pre-sorted). Understanding
> the chosen strategy helps explain performance.
>
> The ON clause specifies the join condition. For `ON a.id = b.a_id`:
> if `a.id` is the primary key and `b.a_id` is a foreign key with an index,
> the optimizer will often choose a nested loop: probe the foreign key index
> for each row in a. If both sides have millions of rows with no index:
> hash join builds a hash table from the smaller side and probes it.
>
> Multiple joins: chain them in logical order. Each join adds columns
> from the joined table. Join order matters for performance (optimizer
> chooses, but you can hint with CTEs or query structure).

**Blank Mind Recovery:**

**(1) Restate:** "INNER JOIN: rows where both sides match. No match = excluded.
ON clause: join condition (usually FK = PK)."

**(2) First principles:** "A join is a filtered Cartesian product. The filter
(ON condition) keeps only row combinations where the condition is true."

**(3) Bridge:** "Like matching two lists. Customer list + order list.
Matching on customer_id: only customers who have orders appear.
Customers with zero orders and orders with missing customers are both excluded."

---

### 📘 Concept Explanation

**Join types overview:**

```
INNER JOIN:    rows where BOTH sides match
LEFT JOIN:     ALL rows from left + matched rows from right
               (NULL for right-side columns when no match)
RIGHT JOIN:    ALL rows from right + matched rows from left
FULL OUTER:    ALL rows from both, NULLs where no match
CROSS JOIN:    Cartesian product (every row x every row)
SELF JOIN:     table joined to itself
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Equi-join vs. non-equi-join:**

```sql
-- Equi-join (most common): join on equality
ON a.id = b.a_id

-- Non-equi-join (ranges, conditions):
ON a.created_at BETWEEN b.starts_at AND b.ends_at
ON a.price >= b.min_price AND a.price < b.max_price
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```sql
-- INNER JOIN: the essential pattern

-- BAD: implicit (old-style) join with WHERE
SELECT o.id, c.name, o.total_cents
FROM orders o, customers c
WHERE o.customer_id = c.id  -- join condition in WHERE
  AND o.status = 'PLACED';  -- filter condition mixed in
-- Problematic: join and filter conditions are mixed.
-- If you accidentally omit the WHERE join condition:
-- Cartesian product (orders * customers).
-- Not readable.

-- GOOD: explicit INNER JOIN
SELECT
    o.id            AS order_id,
    c.name          AS customer_name,
    o.total_cents,
    o.status
FROM orders o
INNER JOIN customers c ON c.id = o.customer_id
WHERE o.status = 'PLACED'
ORDER BY o.created_at DESC;
-- Join condition in ON clause (clear intent).
-- Filter condition in WHERE (separate concern).
-- Readable: "orders joined to their customers".

-- MULTIPLE JOINS
SELECT
    o.id            AS order_id,
    c.name          AS customer_name,
    p.name          AS product_name,
    oi.quantity,
    oi.unit_price_cents
FROM orders o
INNER JOIN customers c  ON c.id = o.customer_id
INNER JOIN order_items oi ON oi.order_id = o.id
INNER JOIN products p   ON p.id = oi.product_id
WHERE o.id = :order_id;
```

> **Code walkthrough:** The BAD implicit join uses the old comma-separated
> table list with join conditions in WHERE. This style mixes join logic
> and filter logic, making it easy to accidentally write a Cartesian
> product (forgetting the join condition). The GOOD explicit INNER JOIN
> separates: ON clause = how tables relate, WHERE clause = which rows
> to include. The multi-join example shows the chaining pattern: each
> INNER JOIN adds a new related table. If any join has no match: that
> order-item-product combination is excluded from results.

```sql
-- JOIN ORDER AND PERFORMANCE

-- The optimizer chooses the join order, but
-- your table references influence it.
-- For a query known to start with a small result set:

-- GOOD: start with the most selective filter
SELECT c.name, COUNT(o.id) AS order_count
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id
WHERE c.segment = 'ENTERPRISE'  -- very few customers
GROUP BY c.name;

-- The optimizer will likely do:
-- 1. Filter customers WHERE segment='ENTERPRISE' (small set)
-- 2. For each matching customer: index-seek orders
--    by customer_id (nested loop with index)
-- Total: small scan * O(log n) per customer

-- Alternatively with a hint via CTE:
WITH enterprise AS (
    SELECT id, name
    FROM customers WHERE segment = 'ENTERPRISE'
)
SELECT e.name, COUNT(o.id)
FROM enterprise e
INNER JOIN orders o ON o.customer_id = e.id
GROUP BY e.name;
-- The CTE forces customers to be filtered first.
```

> **Code walkthrough:** The optimizer estimates the best join order by
> comparing row counts. Starting with `customers WHERE segment='ENTERPRISE'`
> (perhaps 50 customers) and then looking up orders per customer via index
> is much faster than starting with all orders and looking up their customers.
> The CTE version makes the intent explicit: filter customers first, then
> join orders. For complex queries where the optimizer makes a poor choice:
> CTEs and subqueries can guide the join order.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> INNER JOIN returns rows where both tables have a match on the join
> condition. Write: `FROM table_a a INNER JOIN table_b b ON b.fk = a.id`.
> Rows in table_a with no matching rows in table_b are excluded.
> Multiple INNER JOINs chain together. Use explicit ON clause,
> not the old comma-separated implicit join style.

---

**Senior / Staff:**
> INNER JOIN performance is determined by the join algorithm the optimizer
> chooses: nested loop (one side has an index, small outer row count),
> hash join (large tables, no useful index on the inner side), or merge
> join (both sides sorted, usually via index). EXPLAIN shows which algorithm
> is used and the estimated/actual row counts. Mismatched row count estimates
> are the most common cause of bad join plans - stale statistics cause the
> optimizer to underestimate row counts and choose wrong algorithms.

---

### ⚠️ Common Misconceptions

**"INNER JOIN is faster than LEFT JOIN"**

Reality: the join algorithm (nested loop, hash, merge) determines
performance, not the join type. A LEFT JOIN with an index on the FK
can be faster than an INNER JOIN doing a sequential scan.
The join type determines which rows are included, not the access method.

**"Joining on unindexed columns is always slow"**

Reality: for small tables (a few thousand rows): a sequential scan on
both sides is fine. The overhead of an index (I/O to read index pages)
can exceed the sequential scan for small tables. The optimizer knows this
and chooses sequential scan for small tables even when an index exists.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Cartesian product from missing join condition**

Symptom: query returns rows * orders_of_magnitude more rows than expected.
`100,000 orders x 500 products = 50,000,000 rows` returned by mistake.

Diagnosis: a join is missing its ON condition (or the condition is always
true). `EXPLAIN` shows "Nested Loop / Hash Join" with row estimate in
the billions.

Fix: add the missing ON condition.

---

### 🎯 Interview Deep-Dive

**Q1: What are the three join algorithms and when does the optimizer choose each?**

🗣️ "Nested loop join: iterate over the outer table; for each row, probe the
inner table using an index. Best when: outer table is small (few rows after
filtering), and the inner table has an index on the join column. Cost: O(outer_rows * log(inner_rows)).
Hash join: build a hash table from the smaller table; scan the larger table
and probe the hash. Best when: both tables are large, no useful index, enough
memory for the hash table. Cost: O(n + m). Memory: hash table size.
Merge join: sort both sides on the join column, then merge. Best when: both
sides are already sorted (via index) or when DISTINCT/ORDER BY is also needed.
The optimizer chooses based on estimated row counts and available indexes."

**Q2: How does join order affect query performance?**

🗣️ "Join order determines how many intermediate rows are passed to subsequent
join steps. For N tables: there are N! possible join orders. The optimizer
uses statistics (row count estimates, correlation) to find the lowest-cost
order. The key insight: performing the most selective filter earliest reduces
intermediate row counts and makes subsequent joins cheaper.
For a query with 5 tables and one very selective filter (returns 10 rows):
doing that filter first means subsequent joins process 10 rows, not 10M.
Bad estimates cause bad join orders: `ANALYZE table` refreshes statistics
and gives the optimizer accurate row counts."

**Q3: What is the difference between ON and WHERE for join filtering?**

🗣️ "For INNER JOIN: ON and WHERE produce the same result. Both filter rows.
`INNER JOIN b ON b.id = a.b_id AND b.active = true` is equivalent to
`INNER JOIN b ON b.id = a.b_id WHERE b.active = true`.
For LEFT JOIN: the difference is critical. A condition in ON: applied before
the LEFT JOIN - it limits which right-side rows are matched, but still
returns all left-side rows (with NULL if no match). A condition in WHERE:
applied after the LEFT JOIN - it excludes left-side rows where the condition
is false (including rows where the right side was NULL). `LEFT JOIN ... ON ...
WHERE b.col = 'x'` effectively becomes an INNER JOIN. Use ON conditions
to filter the right side in a LEFT JOIN; use WHERE for final row filtering."

**Q4: What is a self-join and give a practical use case?**

🗣️ "A self-join joins a table to itself - the table appears twice with
different aliases. Use case: hierarchical data. An employees table where
`manager_id` references another employee's `id`.
`SELECT e.name AS employee, m.name AS manager
FROM employees e LEFT JOIN employees m ON m.id = e.manager_id`.
This reads one row as the employee and another row from the same table
as the manager. Other use cases: finding duplicate rows, finding rows
that differ by one attribute (before/after comparison), adjacency list
traversal (though recursive CTEs are usually better for deep hierarchies)."

**Q5: How do you diagnose a slow join query?**

🗣️ "Step 1: `EXPLAIN ANALYZE` the query. Look for: (1) Seq Scan on large
tables (missing index). (2) Rows estimate vs. actual rows - if actual is
10x the estimate, statistics are stale (run `ANALYZE`). (3) Wrong join
algorithm: Hash Join with huge hash table (memory pressure), Nested Loop
without index (O(n*m)). Step 2: check indexes on join columns. Every FK
column should have an index for joins. Step 3: check if intermediate
result sets are huge (a join that multiplies rows before filtering).
Restructure: add a tighter WHERE before the join, or use a CTE to filter
first."

**Q6: What is a covering index for a join and how does it help?**

🗣️ "A covering index for a join contains the join column plus all selected
columns. For `SELECT o.id, o.status FROM orders o JOIN customers c ON c.id=o.customer_id WHERE c.segment='ENTERPRISE'`:
if the index on `orders(customer_id, id, status)` exists: the join can
be satisfied entirely from the index (index-only scan). No heap access.
If the join also filters on an orders column: include that column in the
index. The trade-off: wider indexes take more space and slow down writes.
Use covering indexes for the highest-frequency join queries in your hot path."

**Q7: When should you use a subquery instead of a JOIN?**

🗣️ "Subquery in WHERE (semi-join): `WHERE id IN (SELECT order_id FROM ...)`.
Equivalent to INNER JOIN but can be more readable when you only care
about existence. The optimizer often rewrites subqueries as joins. Prefer
EXISTS over IN for large subqueries (EXISTS short-circuits on first match).
Subquery in FROM (derived table): when you need to aggregate before joining.
`FROM (SELECT customer_id, SUM(amount) AS total FROM orders GROUP BY customer_id) AS totals
JOIN customers c ON c.id = totals.customer_id`. This pre-aggregates
orders before the join, reducing the row count in the join.
CTE is the modern, readable alternative to derived table subqueries."

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


# LEFT JOIN and RIGHT JOIN - Including Unmatched Rows

**TL;DR:** LEFT JOIN returns all rows from the left table, plus matching
rows from the right table (NULL for right-side columns when no match).
RIGHT JOIN is the mirror: all rows from the right side. LEFT JOIN is
far more commonly used. Use LEFT JOIN to find entities with optional
related data, or to detect records with no matches.

---

### 🎯 Model Answer

**30 seconds:**
> LEFT JOIN returns every row from the left table. If the right side has
> a matching row: it is included. If not: the right side columns are NULL.
> Use LEFT JOIN when you want all records from the main entity table
> regardless of whether they have related records. Common pattern: find
> customers who have no orders (WHERE o.id IS NULL after LEFT JOIN to orders).

**3 minutes:**
> The critical mental model: LEFT JOIN = "include all left rows, attach
> right data when available, NULL when not." The key difference from
> INNER JOIN: rows from the left table always appear, even with no match.
>
> Finding records with no match: the "anti-join" pattern. LEFT JOIN then
> filter WHERE right_table.id IS NULL. This finds left-side rows that
> had no match in the right side. Example: `SELECT c.id FROM customers c
> LEFT JOIN orders o ON o.customer_id = c.id WHERE o.id IS NULL` finds
> customers with no orders.
>
> Performance: LEFT JOIN is typically comparable to INNER JOIN. The optimizer
> cannot prune left-side rows based on the right side (every left row must
> appear). This means the left table's size and selectivity are important.
> Put the larger or more selective table on the left if you need all its rows.

**Blank Mind Recovery:**

**(1) Restate:** "LEFT JOIN: all left rows, matched right or NULL. Anti-join:
LEFT JOIN + WHERE right.id IS NULL finds left rows with no match."

**(2) First principles:** "LEFT JOIN is a superset of INNER JOIN: it includes
all INNER JOIN rows plus non-matching left rows with NULLs on the right."

**(3) Bridge:** "Like a class attendance sheet. INNER JOIN: only students
who attended. LEFT JOIN: all students listed, attendance data if present
(or 'absent' marker if not)."

---

### 📘 Concept Explanation

**LEFT JOIN result structure:**

```
Table A: [1, 2, 3, 4]
Table B: [2, 3, 5]  (linked to A)

INNER JOIN result: [2, 3]      (only matches)
LEFT JOIN result:  [1-null, 2-B, 3-B, 4-null]
                   (all A, B where matched, null where not)
RIGHT JOIN result: [2-B, 3-B, 5-null_A]
                   (all B, A where matched, null where not)
FULL OUTER:        [1-null, 2-B, 3-B, 4-null, null-5]
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Anti-join pattern:**

```sql
-- Find A rows that have no match in B
SELECT a.*
FROM a LEFT JOIN b ON b.a_id = a.id
WHERE b.id IS NULL;

-- Equivalent using NOT EXISTS (often faster):
SELECT a.*
FROM a
WHERE NOT EXISTS (SELECT 1 FROM b WHERE b.a_id = a.id);

-- Equivalent using NOT IN (dangerous if b.a_id has NULLs):
SELECT a.*
FROM a
WHERE a.id NOT IN (SELECT a_id FROM b WHERE a_id IS NOT NULL);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```sql
-- LEFT JOIN: the optional relationship pattern

-- BAD: INNER JOIN excludes records with no related data
SELECT c.id, c.name, o.total_cents
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id;
-- Customers with zero orders: EXCLUDED.
-- Report is missing some customers.

-- GOOD: LEFT JOIN includes customers with no orders
SELECT
    c.id,
    c.name,
    COALESCE(SUM(o.total_cents), 0) AS lifetime_value,
    COUNT(o.id)                     AS order_count
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY lifetime_value DESC;
-- Customers with no orders: included with 0 lifetime value.
-- COALESCE converts NULL SUM to 0.
-- COUNT(o.id) is 0 for customers with no orders
--   (COUNT(column) ignores NULLs; COUNT(*) would count the row).

-- ANTI-JOIN: customers who have NEVER ordered
SELECT c.id, c.name, c.email
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;
-- All customers are included via LEFT JOIN.
-- WHERE o.id IS NULL: keep only those with no match.
-- = customers with no orders.
```

> **Code walkthrough:** The INNER JOIN version excludes any customer who
> has never placed an order, producing an incomplete report. The LEFT JOIN
> version includes every customer. `COALESCE(SUM(o.total_cents), 0)` handles
> the case where a customer has no orders: `SUM(NULL)` returns NULL,
> COALESCE converts it to 0. `COUNT(o.id)` (not `COUNT(*)`) correctly
> returns 0 for customers with no orders because COUNT ignores NULL values.
> The anti-join pattern (`WHERE o.id IS NULL`) uses the LEFT JOIN result
> to find non-matching rows.

```sql
-- FILTER IN ON vs WHERE: the critical LEFT JOIN distinction

-- BAD: filter in WHERE converts LEFT JOIN to INNER JOIN
SELECT c.id, c.name, o.id AS order_id
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.status = 'PLACED';
-- o.status = 'PLACED' is NULL for customers with no orders.
-- NULL = 'PLACED' is UNKNOWN (not TRUE).
-- WHERE excludes UNKNOWN rows.
-- Result: same as INNER JOIN. Customers with no orders excluded.

-- GOOD: filter in ON clause keeps unmatched left rows
SELECT c.id, c.name, o.id AS order_id
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.id
    AND o.status = 'PLACED';
-- The filter is applied BEFORE the LEFT JOIN.
-- Only PLACED orders are matched.
-- Customers with no PLACED orders: included, o.id IS NULL.
-- Result: all customers, with PLACED order ID if they have one.
```

> **Code walkthrough:** This is one of the most common LEFT JOIN mistakes.
> A WHERE filter on the right-table column converts the LEFT JOIN to an
> INNER JOIN because NULL comparisons are UNKNOWN, and WHERE excludes
> UNKNOWN rows. Moving the filter to the ON clause means: "join to orders
> only if they are PLACED and have the right customer_id." Non-PLACED
> orders are not matched (not joined), but the customer row still appears
> with NULL right-side values. Different queries - one answers "customers
> who have placed orders" (WHERE version), the other answers "all customers
> and their latest placed order if any" (ON version).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> LEFT JOIN includes all rows from the left table. If no matching row
> in the right table: right-side columns are NULL. Use for optional
> relationships: all customers even if they have no orders. Use the
> anti-join pattern (WHERE right.id IS NULL) to find records with no
> match. Remember: putting a filter on the right table in WHERE converts
> LEFT JOIN to INNER JOIN - put such filters in the ON clause instead.

---

**Senior / Staff:**
> The filter placement rule is the most common LEFT JOIN bug in production
> code. Any WHERE condition on a right-side column silently converts a
> LEFT JOIN to an INNER JOIN via NULL exclusion. In code review: always
> check LEFT JOINs for WHERE conditions that reference the right table.
> They should almost always be ON conditions.
> Performance: for the anti-join pattern (find unmatched rows): `NOT EXISTS`
> is often more efficient than LEFT JOIN + IS NULL, because the database
> can short-circuit on the first match in the subquery.

---

### ⚠️ Common Misconceptions

**"RIGHT JOIN is the mirror of LEFT JOIN and used equally often"**

Reality: RIGHT JOIN is used rarely in practice. Any RIGHT JOIN can be
rewritten as a LEFT JOIN by swapping the table order. Most developers
always write LEFT JOIN and rearrange the FROM clause instead.

**"FULL OUTER JOIN returns all combinations"**

Reality: FULL OUTER JOIN (not all databases support it - MySQL does not)
returns all rows from both sides: matched rows with data from both,
unmatched left rows with NULLs on the right, unmatched right rows with
NULLs on the left. It is not a Cartesian product (which is CROSS JOIN).

---

### 🚨 Failure Modes and Diagnosis

**Failure: LEFT JOIN returns unexpected duplicate rows**

Symptom: a customer appears twice in the result even though they have
one order.

Cause: the joined table has multiple rows matching the join condition
(one-to-many relationship). `orders` has multiple rows per customer.
The LEFT JOIN produces one result row per matched order, not per customer.

Fix: aggregate (GROUP BY + COUNT/SUM) or use a subquery to pre-aggregate
the one-to-many side before joining.

---

### 🎯 Interview Deep-Dive

**Q1: What is the anti-join pattern and when do you use it?**

🗣️ "Anti-join: find rows in table A that have no matching row in table B.
Three equivalent approaches: (1) LEFT JOIN + IS NULL: `LEFT JOIN b ON b.a_id = a.id WHERE b.id IS NULL`.
(2) NOT EXISTS: `WHERE NOT EXISTS (SELECT 1 FROM b WHERE b.a_id = a.id)`.
(3) NOT IN: `WHERE a.id NOT IN (SELECT a_id FROM b)` - dangerous if b.a_id
has NULLs (NOT IN with a NULL in the subquery returns 0 rows for any value).
Use cases: find customers with no orders (targeting campaigns), find orders
with no invoice (billing gap detection), find orphaned records (data quality).
`NOT EXISTS` is generally safest and often fastest."

**Q2: How does NULL propagation affect aggregation after a LEFT JOIN?**

🗣️ "After a LEFT JOIN: unmatched right-side rows have NULL for all right-table
columns. Aggregate functions treat NULLs differently: `COUNT(column)` ignores
NULLs (returns 0 for customers with no orders when counting order ID).
`COUNT(*)` counts every row including those with NULLs. `SUM(column)` returns
NULL if all values are NULL (customers with no orders). `AVG(column)` returns
NULL if all values are NULL. Use COALESCE to convert NULLs to defaults:
`COALESCE(SUM(o.amount_cents), 0)` returns 0 for customers with no orders.
This is why `COUNT(o.id)` not `COUNT(*)` is the correct pattern for counting
related records in a LEFT JOIN."

**Q3: How does the database optimize a LEFT JOIN?**

🗣️ "The optimizer treats a LEFT JOIN like an INNER JOIN with the additional
constraint that left-side rows are always returned. For the inner side:
if there is an index on the join column: nested loop lookup (fast for each
left row). If not: hash join (build hash from the smaller table). The
optimizer cannot eliminate left-side rows based on the right side (unlike
INNER JOIN). This means: if the left table is large and unfiltered: the
LEFT JOIN must process every row. A WHERE condition on the left table reduces
work. Anti-join optimization: `NOT EXISTS` can be rewritten as a hash
anti-join (build hash of B, scan A, exclude A rows found in hash) -
often more efficient than LEFT JOIN + IS NULL."

**Q4: What is a lateral join and when do you need one?**

🗣️ "LATERAL JOIN (PostgreSQL, also in MySQL 8.0+ as LATERAL) allows
the subquery on the right side to reference columns from the left side.
Normal subqueries cannot reference outer table columns. Example:
for each customer, get their 3 most recent orders:
`SELECT c.id, o.id FROM customers c
CROSS JOIN LATERAL (SELECT id FROM orders WHERE customer_id = c.id
ORDER BY created_at DESC LIMIT 3) o`.
Without LATERAL: you cannot parameterize the subquery on `c.id`.
With LATERAL: the subquery executes once per left-side row with the
current row's values. Use for: top-N per group queries, row-by-row
computations, function calls that take row values as input."

**Q5: How does FULL OUTER JOIN work and when is it useful?**

🗣️ "FULL OUTER JOIN returns: all INNER JOIN rows (matching on both sides),
all left-side rows with no match (right side is NULL), all right-side
rows with no match (left side is NULL). MySQL does not support FULL OUTER JOIN
natively - simulate with `LEFT JOIN UNION ALL RIGHT JOIN WHERE left.id IS NULL`.
Use case: reconciliation. Compare two tables and find: rows in A not in B,
rows in B not in A, rows in both. Example: comparing yesterday's and today's
product prices. FULL OUTER JOIN gives you the complete picture.
Not commonly needed; use LEFT JOIN or NOT EXISTS for most practical cases."

**Q6: What happens when you join on a column with NULLs?**

🗣️ "NULL = NULL is UNKNOWN in SQL. A join condition `ON a.key = b.key`
will never match NULL values on either side. Rows where the join column
is NULL are excluded from the INNER JOIN result. For a LEFT JOIN: rows
where the left join column is NULL will appear with NULLs on the right
(no match is attempted). For a RIGHT JOIN: same for right-side NULLs.
This means: if you have orphaned foreign keys stored as NULL (nullable FK):
the INNER JOIN silently excludes those rows. Use `IS NOT DISTINCT FROM`
in PostgreSQL to match NULLs: `ON a.key IS NOT DISTINCT FROM b.key`
(NULL IS NOT DISTINCT FROM NULL is TRUE). Rarely needed in practice;
FKs should generally be non-null."

**Q7: When would you choose EXISTS over a JOIN for performance?**

🗣️ "EXISTS is a semi-join: it returns rows from the outer query where
the subquery returns at least one row. It short-circuits on the first match.
INNER JOIN returns one output row per match (may multiply rows if one-to-many).
Use EXISTS when: (1) you only need to check existence, not retrieve right-side
columns; (2) the right side is a one-to-many relationship and you do not want
duplicate outer rows; (3) the subquery is expensive but often matches early.
`SELECT c.* FROM customers c WHERE EXISTS (SELECT 1 FROM orders WHERE customer_id = c.id)`:
the EXISTS stops at the first order found per customer. An INNER JOIN would
return one row per order per customer (requires DISTINCT or GROUP BY to
deduplicate). EXISTS is cleaner and avoids the deduplication step."

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


# Aggregate Functions - COUNT, SUM, AVG, GROUP BY, HAVING

**TL;DR:** Aggregate functions compute a single value from a group of rows.
GROUP BY defines the groups. HAVING filters groups (like WHERE but for
aggregated data). The golden rule: every column in SELECT that is not
inside an aggregate function must appear in GROUP BY.

---

### 🎯 Model Answer

**30 seconds:**
> Aggregate functions: COUNT (how many), SUM (total), AVG (average),
> MIN/MAX (extremes). GROUP BY groups rows with the same value and
> applies the aggregate per group. HAVING filters groups after aggregation.
> The rule: non-aggregated columns in SELECT must be in GROUP BY.

**3 minutes:**
> Aggregation reduces many rows to fewer rows. `SELECT customer_id, COUNT(*),
> SUM(amount) FROM orders GROUP BY customer_id` returns one row per customer
> with their order count and total. Without GROUP BY: aggregate functions
> operate on the entire table (one result row).
>
> NULL in aggregates: COUNT(*) counts all rows. COUNT(column) counts
> non-NULL values. SUM, AVG, MIN, MAX ignore NULL values. This means
> `AVG(discount_pct)` divides by the number of non-NULL rows, not the
> total rows - might surprise you.
>
> HAVING vs WHERE: WHERE filters rows before aggregation (cannot reference
> aggregate functions). HAVING filters groups after aggregation (can
> reference aggregate functions). `HAVING COUNT(*) > 5` keeps only groups
> with more than 5 rows.

**Blank Mind Recovery:**

**(1) Restate:** "GROUP BY groups rows. Aggregate per group.
HAVING filters groups. Non-aggregate columns must be in GROUP BY."

**(2) First principles:** "Aggregation is reduction. Many rows with
same key -> one summary row. The aggregate function defines the reduction
(sum, count, max)."

**(3) Bridge:** "Like a spreadsheet pivot table. 'Summarize sales by
region': GROUP BY region, SUM(sales). 'Only show regions with >$1M':
HAVING SUM(sales) > 1000000."

---

### 📘 Concept Explanation

**Execution order with GROUP BY:**

```
1. FROM        - identify tables
2. JOIN        - combine tables
3. WHERE       - filter rows (before grouping)
4. GROUP BY    - partition remaining rows into groups
5. HAVING      - filter groups (after aggregation)
6. SELECT      - apply aggregates, compute columns
7. ORDER BY    - sort result
8. LIMIT       - cap output rows

Key: WHERE runs BEFORE grouping (can't use aggregate results).
     HAVING runs AFTER grouping (can use aggregate results).
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Aggregate function behavior with NULLs:**

```
COUNT(*)        - counts every row including NULLs
COUNT(column)   - counts non-NULL values only
SUM(column)     - sum of non-NULL values; NULL if all NULL
AVG(column)     - avg of non-NULL values (denominator = non-NULL count)
MIN(column)     - minimum non-NULL value
MAX(column)     - maximum non-NULL value
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```sql
-- GROUP BY AND AGGREGATE FUNCTIONS

-- BAD: aggregate without GROUP BY (wrong result)
SELECT customer_id, COUNT(*), SUM(total_cents)
FROM orders;
-- SQL ERROR: customer_id is not in an aggregate function
-- or GROUP BY clause.
-- (Some databases like MySQL allow this but return
-- a random customer_id - very wrong behavior.)

-- GOOD: GROUP BY all non-aggregated columns
SELECT
    customer_id,
    COUNT(*)            AS order_count,
    COUNT(coupon_id)    AS orders_with_coupon,
    SUM(total_cents)    AS lifetime_value_cents,
    AVG(total_cents)    AS avg_order_cents,
    MIN(created_at)     AS first_order_at,
    MAX(created_at)     AS last_order_at
FROM orders
WHERE status != 'CANCELLED'      -- filter BEFORE grouping
GROUP BY customer_id
HAVING COUNT(*) >= 2             -- filter AFTER grouping
ORDER BY lifetime_value_cents DESC
LIMIT 100;

-- COUNT(*) vs COUNT(column):
-- COUNT(*): 5 (all rows)
-- COUNT(coupon_id): 2 (only rows where coupon_id is not NULL)
```

> **Code walkthrough:** The BAD query includes `customer_id` in SELECT
> without either aggregating it or putting it in GROUP BY - this is a
> SQL error in standard-compliant databases (PostgreSQL, SQL Server).
> MySQL's `ONLY_FULL_GROUP_BY` mode makes it an error too. The GOOD query:
> `COUNT(*)` counts all orders; `COUNT(coupon_id)` counts only orders
> that had a coupon (non-NULL). The `WHERE status != 'CANCELLED'` runs
> before grouping (cheaper - filters rows first). `HAVING COUNT(*) >= 2`
> keeps only customers with at least 2 orders - this must be HAVING because
> it references an aggregate.

```sql
-- HAVING vs WHERE: the filter placement distinction

-- BAD: trying to use aggregate in WHERE (SQL error)
SELECT customer_id, SUM(total_cents) AS total
FROM orders
WHERE SUM(total_cents) > 100000  -- ERROR: aggregate in WHERE
GROUP BY customer_id;

-- GOOD: aggregate filter goes in HAVING
SELECT customer_id, SUM(total_cents) AS total
FROM orders
GROUP BY customer_id
HAVING SUM(total_cents) > 100000;

-- COMBINING WHERE AND HAVING (each for its purpose)
SELECT
    customer_id,
    COUNT(*)            AS order_count,
    SUM(total_cents)    AS total_cents
FROM orders
WHERE status = 'DELIVERED'       -- pre-filter: only delivered
GROUP BY customer_id
HAVING SUM(total_cents) > 100000 -- post-filter: high-value only
   AND COUNT(*) >= 3             -- with at least 3 orders
ORDER BY total_cents DESC;
```

> **Code walkthrough:** WHERE and HAVING serve different purposes: WHERE
> filters individual rows before grouping (efficient - fewer rows to
> aggregate), HAVING filters groups after aggregation. `WHERE status = 'DELIVERED'`
> runs first - only DELIVERED orders are included in the groups.
> `HAVING SUM(total_cents) > 100000` runs after grouping - only customer
> groups with total > $1,000 are in the final result. The combined pattern
> is very common: filter noise with WHERE, then filter groups with HAVING.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> GROUP BY groups rows with the same column value. Aggregate functions
> (COUNT, SUM, AVG, MIN, MAX) compute one value per group. Every column
> in SELECT that is not aggregated must be in GROUP BY. HAVING filters
> groups after aggregation (WHERE filters rows before aggregation).
> COUNT(*) counts all rows including NULLs; COUNT(column) ignores NULLs.

---

**Senior / Staff:**
> The WHERE-HAVING distinction is a performance lever: WHERE filters rows
> before the GROUP BY operation, reducing the data that must be aggregated.
> For large tables: a selective WHERE clause is crucial. HAVING filters
> after aggregation - the database must aggregate all groups even if most
> are filtered by HAVING. If you can express a filter as WHERE (without
> referencing aggregates): always use WHERE. Use HAVING only for conditions
> that require aggregate values.

---

### ⚠️ Common Misconceptions

**"HAVING is just WHERE for grouped results - interchangeable"**

Reality: WHERE executes before GROUP BY (can use base columns, cannot
use aggregate results). HAVING executes after GROUP BY (can use aggregate
results, cannot reference aliases defined in SELECT on all databases).
Filters possible in WHERE should always be in WHERE for performance.

**"AVG(column) = SUM(column) / COUNT(*)"**

Reality: `AVG(column) = SUM(column) / COUNT(column)` (denominator is
non-NULL count). If 3 of 10 rows have NULL in the column:
`COUNT(*) = 10`, `COUNT(column) = 7`. `AVG = SUM / 7`, not SUM / 10.
The difference matters when NULLs represent "absent" vs. "zero".

---

### 🚨 Failure Modes and Diagnosis

**Failure: GROUP BY on high-cardinality column causes sort + hash memory pressure**

Symptom: GROUP BY query on 10 million rows with 9 million unique values
takes 10x longer than expected. EXPLAIN shows "HashAggregate Batches: 4".

Diagnosis: the hash aggregation exceeds `work_mem`. The database spills
to disk (batches).

Fix: increase `work_mem` for the session, add a WHERE filter to reduce
rows before grouping, or use a streaming aggregation (add an index for
sorted input to avoid hash aggregation).

---

### 🎯 Interview Deep-Dive

**Q1: What is the difference between COUNT(*) and COUNT(column)?**

🗣️ "COUNT(*): counts every row in the group, including rows with NULL
values. COUNT(column): counts only rows where the column value is not NULL.
Practical difference: if you have 100 orders and 30 of them have a coupon_id
(the rest are NULL): `COUNT(*) = 100`, `COUNT(coupon_id) = 30`.
Use COUNT(*) for: total rows. Use COUNT(column) for: non-null occurrences.
Use COUNT(DISTINCT column) for: unique non-null values.
Common mistake: using COUNT(*) when you want to count related records
in a LEFT JOIN (always use COUNT(right_table.id) to get 0 for unmatched
rows, not 1)."

**Q2: What are window functions and how do they differ from GROUP BY?**

🗣️ "GROUP BY reduces many rows to fewer rows (one per group). Window functions
compute aggregate values for each row without reducing the row count.
`SELECT id, amount, SUM(amount) OVER (PARTITION BY customer_id) AS customer_total FROM orders`:
each row retains its identity but gains a `customer_total` column with
the sum for that customer. GROUP BY would return one row per customer.
Window functions use `OVER (PARTITION BY ... ORDER BY ...)`. Partition BY
is like GROUP BY within the window. ORDER BY within OVER defines the frame
order (critical for running totals, LAG/LEAD). Window functions are ideal
for: running totals, ranking within groups, comparing a row to its group
aggregate, row-by-row calculations that need context."

**Q3: How does the database implement GROUP BY internally?**

🗣️ "Two strategies: (1) Hash aggregation: build a hash table keyed by
GROUP BY columns, accumulate aggregate values. Final pass: iterate the
hash table. Memory: proportional to the number of unique group values.
If it exceeds `work_mem`: spill to disk (PostgreSQL 'Batches' in EXPLAIN).
(2) Sort aggregation: sort the input by GROUP BY columns (using an index
or an explicit sort), then scan sequentially - when the key changes, emit
the group. Memory: only needs to hold the current group's accumulator.
Best when the input is already sorted (via index). The optimizer chooses
based on row count estimates and available indexes."

**Q4: What is a ROLLUP and when would you use it?**

🗣️ "ROLLUP generates subtotals at multiple levels of aggregation.
`GROUP BY ROLLUP(year, quarter, month)` produces: rows grouped by
(year, quarter, month), subtotals for (year, quarter), subtotals for (year),
and a grand total (all NULL group keys). Use for: sales reports with
subtotals, Excel-like hierarchical summaries.
`CUBE` generates all possible combinations of GROUP BY columns (2^n groupings).
`GROUPING SETS` lets you specify exactly which combinations you want.
All three are part of SQL standard and supported in PostgreSQL, SQL Server,
Oracle. MySQL supports ROLLUP but not CUBE. Performance: equivalent to
multiple GROUP BY queries combined with UNION ALL."

**Q5: What is filter clause in aggregate functions?**

🗣️ "`FILTER (WHERE condition)` is a SQL standard syntax (PostgreSQL 9.4+)
for applying a condition inside an aggregate function.
`SELECT COUNT(*) FILTER (WHERE status = 'PLACED') AS placed_count,
COUNT(*) FILTER (WHERE status = 'DELIVERED') AS delivered_count
FROM orders GROUP BY customer_id`.
This is equivalent to multiple CASE expressions:
`SUM(CASE WHEN status='PLACED' THEN 1 ELSE 0 END)`.
But FILTER is more readable and often faster (no CASE evaluation overhead).
Use for: pivot-style aggregations (multiple filtered counts in one query),
conditional summation. Alternative: `CASE WHEN ... THEN value END` inside
aggregate works in all databases."

**Q6: How does GROUP BY work with indexes?**

🗣️ "If there is an index on the GROUP BY column(s): the optimizer may
choose sort-based aggregation: scan the index in order, accumulate
aggregates per key, emit when key changes. No sort step needed (index
provides the order). This is faster than hash aggregation for large
result sets because: (1) no memory needed for the hash table; (2) no
disk spill risk. For `GROUP BY customer_id` with an index on `customer_id`:
the optimizer scans the index in customer_id order, groups are contiguous,
no sort/hash needed. Result: GROUP BY becomes a streaming aggregation -
very efficient for large tables."

**Q7: What is the performance impact of DISTINCT vs GROUP BY?**

🗣️ "DISTINCT and GROUP BY (without aggregates) are semantically equivalent
for deduplication: `SELECT DISTINCT col FROM table` = `SELECT col FROM table GROUP BY col`.
The optimizer often produces the same plan for both. Key difference:
GROUP BY is required when you want aggregates. DISTINCT cannot have
aggregate functions. Performance: both require sorting or hashing to
find duplicates. For very large tables: if there is an index on the column:
an index scan with duplicate skipping may be available (index-only scan
with distinct). Rule of thumb: use DISTINCT for simple deduplication,
GROUP BY when you need aggregates. Do NOT use DISTINCT as a lazy fix
for a JOIN that produces duplicate rows - fix the join logic."

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



