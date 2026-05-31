---
layout: default
title: "Database SQL - L2 Advanced Queries"
parent: "Database SQL"
grand_parent: "SK Interview"
nav_order: 6
permalink: /database-sql/l2-advanced-queries/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Subqueries and Correlated Subqueries](#subqueries-and-correlated-subqueries) | medium |
| 2 | [CTEs (Common Table Expressions)](#ctes-common-table-expressions) | medium |

---

# Subqueries and Correlated Subqueries

**TL;DR:** A subquery is a SELECT inside another SQL statement. It can
appear in WHERE, FROM, or SELECT. A correlated subquery references a column
from the outer query and re-executes once per outer row - making it O(n)
in the outer row count. Correlated subqueries are powerful but dangerous
at scale; a JOIN or window function is usually faster.

---

### 🎯 Model Answer

**30 seconds:**
> A subquery is a query nested inside another query. Non-correlated:
> executes once, result is reused. Correlated: references the outer query's
> columns and re-executes for each outer row (O(n) cost). Use subqueries
> for: filtering with aggregates, deriving intermediate result sets,
> scalar lookups. Replace correlated subqueries with JOINs or window
> functions when performance matters.

**3 minutes:**
> Subqueries fall into three positions: (1) Scalar subquery in SELECT -
> returns exactly one value, evaluated for each output row (effectively
> correlated). (2) Subquery in WHERE - filters outer rows based on a
> derived set (EXISTS, IN, comparison operators). (3) Derived table in FROM -
> acts as a table; non-correlated (executes once). CTEs replace derived
> tables for readability.
>
> Correlated subquery: `SELECT id FROM orders o WHERE total > (SELECT AVG(total) FROM orders WHERE customer_id = o.customer_id)`.
> The inner query references `o.customer_id` from the outer query. It
> executes once per outer row. For 1 million rows: 1 million inner queries.
> Rewrite as a JOIN to a pre-aggregated subquery: the average is computed
> once per customer, then joined.
>
> EXISTS vs IN: EXISTS short-circuits on the first match. IN evaluates
> all values. For large subqueries: EXISTS is usually faster. For small
> subqueries: IN is often more readable with comparable performance.

**Blank Mind Recovery:**

**(1) Restate:** "Subquery = query within query. Correlated = references outer row.
Non-correlated = executes once. Correlated + large table = O(n^2). Fix: JOIN."

**(2) First principles:** "A correlated subquery creates a dependency
between inner and outer loops. Each outer row causes one inner query:
N * inner_cost = O(N * log M). If inner is not indexed: O(N * M)."

**(3) Bridge:** "Like a salary review process. For each employee (outer row):
calculate the average salary in their department (inner query). Done manually:
re-calculate the department average for every employee. Done with a spreadsheet
(pre-aggregate): calculate each department average once, look up for each employee."

---

### 📘 Concept Explanation

**Subquery positions:**

```sql
-- 1. Scalar subquery in SELECT
--    Executes once per output row (effectively correlated)
SELECT id,
    (SELECT COUNT(*) FROM orders
     WHERE customer_id = c.id) AS order_count
FROM customers c;

-- 2. Subquery in WHERE with IN
SELECT id FROM customers
WHERE id IN (SELECT DISTINCT customer_id FROM orders
             WHERE total_cents > 100000);

-- 3. Subquery in WHERE with EXISTS
SELECT id FROM customers c
WHERE EXISTS (SELECT 1 FROM orders
              WHERE customer_id = c.id);

-- 4. Derived table in FROM
SELECT customer_id, total_orders
FROM (SELECT customer_id, COUNT(*) AS total_orders
      FROM orders GROUP BY customer_id) AS agg
WHERE total_orders > 5;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**EXISTS vs IN:**

```
EXISTS:
  - Short-circuits on first match
  - Safe with NULLs
  - Returns TRUE/FALSE
  - Optimal for "does any row match?"

IN:
  - Evaluates all subquery rows
  - Dangerous with NULLs in subquery
    (NOT IN + NULL = 0 rows returned)
  - Returns TRUE/FALSE/UNKNOWN
  - Readable for small value sets
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```sql
-- CORRELATED SUBQUERY: the performance trap

-- BAD: scalar subquery in SELECT (correlated, O(n))
SELECT
    c.id,
    c.name,
    (SELECT SUM(total_cents)
     FROM orders
     WHERE customer_id = c.id) AS lifetime_value
FROM customers c;
-- Executes the subquery once per customer.
-- 100k customers = 100k inner queries.
-- EXPLAIN: "SubPlan 1" with "Rows Removed by Filter"
-- per outer row.

-- GOOD: rewrite as LEFT JOIN (one pass)
SELECT
    c.id,
    c.name,
    COALESCE(o.lifetime_value, 0) AS lifetime_value
FROM customers c
LEFT JOIN (
    SELECT customer_id, SUM(total_cents) AS lifetime_value
    FROM orders
    GROUP BY customer_id
) AS o ON o.customer_id = c.id;
-- Pre-aggregate orders once.
-- Join to customers once.
-- O(n log n) total, not O(n * m).
```

> **Code walkthrough:** The correlated scalar subquery in SELECT
> executes the inner SUM query once per customer row. With 100,000
> customers this is 100,000 separate aggregation queries. The JOIN
> version pre-aggregates all customers' order totals in one pass,
> then joins the result to customers. The total work goes from
> O(customers * log(orders)) to O(orders + customers) - a 100x or
> greater improvement for large tables. EXPLAIN ANALYZE shows the
> difference: the correlated version shows "SubPlan 1" executed N times;
> the JOIN version shows a single Hash Aggregate node.

```sql
-- EXISTS: the correct "does any match exist?" pattern

-- BAD: IN with potential NULL values
SELECT c.id FROM customers c
WHERE c.id NOT IN (
    SELECT customer_id FROM orders
);
-- If ANY row in orders has customer_id = NULL:
-- NOT IN returns 0 rows for ALL customers.
-- Silent data bug.

-- GOOD: NOT EXISTS (safe with NULLs, short-circuits)
SELECT c.id FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id
);
-- Safely finds customers with no orders.
-- Executes correctly regardless of NULL values.
-- Short-circuits: stops after first match.

-- EXISTS for conditional check (semi-join):
SELECT DISTINCT c.id, c.name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id
      AND o.created_at > now() - INTERVAL '30 days'
);
-- Customers who ordered in the last 30 days.
-- EXISTS stops at first recent order per customer.
-- No duplicates (vs JOIN which multiplies rows).
```

> **Code walkthrough:** The NOT IN danger: `NOT IN (subquery)` is
> equivalent to `id != subquery_row1 AND id != subquery_row2 AND ...`.
> If any subquery row is NULL: the comparison is UNKNOWN, making the
> entire AND chain UNKNOWN, so WHERE excludes the row. Result: 0 rows.
> `NOT EXISTS` is semantically correct: "return this customer if no
> row in orders has this customer_id." NULL in orders.customer_id is
> never equal to any customer's id, so it is correctly excluded.
> The EXISTS semi-join avoids duplicates from one-to-many relationships
> (a customer with 5 orders appears once in EXISTS, 5 times in INNER JOIN).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> A subquery is a SELECT inside another SQL statement. Scalar subquery:
> returns one value. IN/EXISTS subquery: checks membership. Derived table
> in FROM: treated as a table. Correlated subqueries reference the outer
> query's row and execute once per outer row - use JOIN instead for
> large tables. Use NOT EXISTS instead of NOT IN when the subquery might
> contain NULLs.

---

**Senior / Staff:**
> Correlated subqueries are the most common source of O(n^2) query
> behavior in production SQL. Pattern recognition: any scalar subquery
> in SELECT or any WHERE subquery that references an outer column should
> be evaluated for rewrite as a JOIN or window function. EXISTS is the
> right tool for semi-join (does a matching row exist); a JOIN produces
> duplicate rows for one-to-many relationships. The optimizer sometimes
> rewrites IN subqueries as hash semi-joins automatically - but correlated
> subqueries with outer column references are harder to optimize.

---

### ⚠️ Common Misconceptions

**"The optimizer always optimizes correlated subqueries"**

Reality: modern optimizers (PostgreSQL, SQL Server) can unnest some
correlated subqueries and rewrite them as joins. But not all: complex
correlated subqueries with aggregates and multiple references to the
outer query often remain correlated. Verify with EXPLAIN - if you see
"SubPlan" with multiple executions: the optimizer did not unnest it.

**"EXISTS is always slower than IN because it does more work"**

Reality: EXISTS short-circuits on first match. IN must evaluate all
subquery rows (or the optimizer rewrites it). For large subqueries:
EXISTS is typically faster. For a list of literal values (`IN (1, 2, 3)`):
IN is simpler and the optimizer handles it efficiently.

---

### ⚖️ Comparison Table

| Pattern | Execution | NULL-safe | Duplicates | Best for |
|---|---|---|---|---|
| IN (subquery) | Full scan | No (NOT IN breaks) | Possible | Small result sets |
| EXISTS | Short-circuit | Yes | No | Existence check |
| JOIN | Single pass | No (INNER) / Yes (LEFT) | Yes (1:many) | Data retrieval |
| Window function | Single pass | N/A | Preserves rows | Per-group aggregates |
| Correlated subquery | Per-row | Context-dependent | Depends | Avoid at scale |

---

### 🏛️ System Design

*(Omit: L2 keyword - subqueries are a query pattern, not a system-level concern)*

---

### 📊 Diagram

*(Omit: subquery execution flow is better explained in code examples than a diagram)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: NOT IN with NULL returns 0 rows**

Symptom: `SELECT * FROM a WHERE id NOT IN (SELECT fk FROM b)` returns
0 rows even though table a has many rows with no match.

Diagnosis: `SELECT fk FROM b WHERE fk IS NULL` returns rows.
The NOT IN subquery contains NULLs, making every row's NOT IN evaluation UNKNOWN.

Fix:
```sql
-- Option 1: filter NULLs in subquery
WHERE id NOT IN (SELECT fk FROM b WHERE fk IS NOT NULL)

-- Option 2: use NOT EXISTS (correct and safe)
WHERE NOT EXISTS (SELECT 1 FROM b WHERE b.fk = a.id)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Failure: Correlated subquery causes query to time out**

Symptom: query runs in seconds on 1,000 rows; times out on 1,000,000 rows.

Diagnosis: `EXPLAIN ANALYZE` shows SubPlan executing millions of times.

Fix: rewrite as a JOIN with pre-aggregation or as a window function.

---

### 🎯 Interview Deep-Dive

**Q1: What is the difference between a correlated and non-correlated subquery?**

🗣️ "Non-correlated subquery: the inner query has no reference to the outer
query. It executes once, and the result is reused. Example: `WHERE id IN
(SELECT id FROM premium_customers)` - the inner SELECT runs once, result is
a fixed set. Correlated subquery: the inner query references a column from
the outer query. It re-executes for each outer row. Example:
`WHERE total > (SELECT AVG(total) FROM orders WHERE customer_id = o.customer_id)` -
the inner query uses `o.customer_id` from the outer row; it runs once per
outer row. For 1 million orders: 1 million inner queries. Performance:
non-correlated is O(1) inner executions; correlated is O(n) inner executions."

**Q2: When would you use a derived table vs. a CTE?**

🗣️ "Derived table: subquery in FROM clause. Must be named with an alias.
Cannot be referenced more than once. CTE (WITH clause): named subquery,
defined before the main query. Can be referenced multiple times in the
main query. Readability: CTEs are much more readable for complex multi-step
queries. Performance: in PostgreSQL, CTEs are optimization fences by default
(the optimizer may not push predicates into the CTE). In PostgreSQL 12+:
`WITH ... AS (NOT MATERIALIZED)` allows predicate pushdown. For single-use
intermediate results: either works. For multiple references to the same
intermediate result: CTE is cleaner."

**Q3: How does the database optimize an IN subquery?**

🗣️ "The optimizer rewrites `x IN (SELECT y FROM t WHERE ...)` as a
semi-join: either a hash semi-join (build a hash set of subquery results,
probe for each outer row) or a nested loop semi-join (use an index on
the subquery table). PostgreSQL rewrites non-correlated IN subqueries
as hash semi-joins automatically. Correlated IN subqueries (referencing
the outer query) are harder to unnest - the optimizer tries to unnest
but may fall back to row-by-row evaluation. The key: `EXISTS` gives the
optimizer explicit permission to short-circuit; `IN` requires the optimizer
to infer this. Both produce the same plan in most cases for simple subqueries."

**Q4: How would you rewrite a correlated subquery as a JOIN?**

🗣️ "Pattern: identify what the correlated subquery is computing per outer row,
then pre-compute it as a subquery or CTE, and join the result.
Before: `SELECT c.id, (SELECT MAX(created_at) FROM orders WHERE customer_id = c.id) AS last_order FROM customers c`.
After: pre-aggregate last order per customer:
`SELECT c.id, o.last_order FROM customers c
LEFT JOIN (SELECT customer_id, MAX(created_at) AS last_order FROM orders GROUP BY customer_id) o ON o.customer_id = c.id`.
The subquery runs once (not once per customer). JOIN connects the pre-aggregated
result. Alternative: window function `MAX(created_at) OVER (PARTITION BY customer_id)` in a CTE."

**Q5: What is a lateral join and how does it relate to correlated subqueries?**

🗣️ "LATERAL JOIN is an explicit correlated subquery in the FROM clause.
Without LATERAL: a subquery in FROM cannot reference other FROM tables.
With LATERAL: `FROM customers c CROSS JOIN LATERAL (SELECT * FROM orders WHERE customer_id = c.id ORDER BY created_at DESC LIMIT 3) o`.
The LATERAL subquery can reference `c.id` from the left side. This executes
the inner query once per outer row - similar to a correlated subquery but
as a table join. Use when: you need the top-N rows per group (top 3 orders
per customer). Without LATERAL: you would need a window function and then filter.
LATERAL is more expressive for per-row computations with LIMIT."

**Q6: How do you detect correlated subquery performance problems in production?**

🗣️ "Three indicators: (1) EXPLAIN ANALYZE: look for 'SubPlan N' nodes with
loops > 1. If loops = 1,000,000: that subquery executed a million times.
(2) Query runtime scales linearly with outer table size: 1,000 rows = 100ms,
100,000 rows = 10s. Linear scaling indicates O(n) inner queries.
(3) `pg_stat_statements` shows high total execution time for the query;
the plan shows sequential scans inside the SubPlan.
Remediation: (1) Add an index on the correlated column in the inner table.
(2) Rewrite as a JOIN with pre-aggregation. (3) Use a window function.
(4) Use EXISTS instead of correlated scalar subquery for existence checks."

**Q7: What are common use cases where a subquery is the best approach?**

🗣️ "Three genuine use cases: (1) Aggregate in WHERE: `WHERE amount > (SELECT AVG(amount) FROM orders)`. You cannot use aggregate functions in WHERE; the subquery pre-computes the aggregate. (2) Anti-join: `WHERE NOT EXISTS (SELECT 1 FROM b WHERE ...)` - finds rows with no match, cleaner than outer join. (3) Row-level comparisons in upsert/update: `UPDATE a SET val = b.val FROM (SELECT id, val FROM b WHERE condition) b WHERE a.id = b.id` - the derived table filters b once before the update. When to use JOIN instead: whenever you need columns from both sides, or the subquery is correlated. Window function instead: when you need per-group aggregates alongside individual rows."

**Q8: How does PostgreSQL's CTE materialization affect performance?**

🗣️ "In PostgreSQL 11 and earlier: CTEs are always materialized. The result
is computed once and stored. Predicates from outside the CTE are NOT pushed
into the CTE query. This is the 'optimization fence.' For a CTE with 1M rows
and a WHERE on the outer query that selects 10: PostgreSQL scans all 1M CTE
rows regardless. In PostgreSQL 12+: non-recursive CTEs can be inlined
(the optimizer treats them like derived tables and pushes predicates in).
Control: `WITH data AS MATERIALIZED (...)` forces materialization;
`WITH data AS NOT MATERIALIZED (...)` forces inlining. In production:
if a CTE-using query is slow after upgrading to PG12+, the inlining
optimization may change the plan. Use EXPLAIN to verify."

**Q9: What is the difference between a semi-join and an anti-join?**

🗣️ "Semi-join: return rows from table A where at least one matching row
exists in table B. Implemented by EXISTS or IN. The row from B is not
included in the output. `SELECT a.* FROM a WHERE EXISTS (SELECT 1 FROM b WHERE b.a_id = a.id)`.
Anti-join: return rows from table A where NO matching row exists in table B.
Implemented by NOT EXISTS or LEFT JOIN + IS NULL.
`SELECT a.* FROM a WHERE NOT EXISTS (SELECT 1 FROM b WHERE b.a_id = a.id)`.
Both are optimized by the database as specialized join algorithms:
hash semi-join (build hash of B, scan A, emit A rows found/not found in hash).
Semi-join and anti-join are more efficient than INNER JOIN for existence checks
because they avoid outputting and deduplicating join results."

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


# CTEs (Common Table Expressions)

**TL;DR:** A CTE (WITH clause) is a named temporary result set defined
before the main query. It improves readability by breaking complex queries
into named steps. In PostgreSQL 12+, CTEs are inlined by default (treated
like views), allowing predicate pushdown. CTEs can be recursive (for
hierarchical data queries).

---

### 🎯 Model Answer

**30 seconds:**
> A CTE uses `WITH name AS (SELECT ...)` to define a named temporary
> result before the main query. It is referenced by name in the main query.
> Benefits: readability (complex queries become a series of named steps),
> reusability (can be referenced multiple times in the same query),
> recursive queries (for hierarchies). In PostgreSQL 12+: inlined by
> default unless `MATERIALIZED` is specified.

**3 minutes:**
> CTEs shine for multi-step transformations: filter, aggregate, rank,
> then join - each step named and readable. A complex query with five
> nested subqueries becomes five named CTEs and a clean main SELECT.
>
> Recursive CTEs: `WITH RECURSIVE` enables self-referencing queries.
> The structure: an anchor member (base case) UNION ALL a recursive member
> (references the CTE itself). Used for: traversing trees (org charts,
> file system paths), graphs (shortest path), sequences (generating date
> ranges). The recursive member executes until no new rows are produced.
>
> Performance trap (PostgreSQL 11 and earlier): CTEs were optimization fences.
> The result was always materialized; predicates from outside were never
> pushed in. In PostgreSQL 12+: CTEs are inlined by default. Use
> `AS MATERIALIZED` to force the old behavior (useful when the CTE result
> is referenced multiple times and you want to compute it once).

**Blank Mind Recovery:**

**(1) Restate:** "CTE = WITH name AS (query). Named temp result. Readable.
Recursive CTE = WITH RECURSIVE. PG12+: inlined by default."

**(2) First principles:** "A CTE is syntactic structure: it rearranges
where subqueries are written. Non-recursive: equivalent to derived table.
Recursive: enables iterative computation SQL otherwise cannot express."

**(3) Bridge:** "Like writing a function in code. Instead of one
700-character one-liner, you define named intermediate steps. The database
processes them in order. Recursive CTE = a loop with a base case and a step."

---

### 📘 Concept Explanation

**CTE syntax:**

```sql
WITH
  step1 AS (
      SELECT id, customer_id, total_cents
      FROM orders WHERE status = 'DELIVERED'
  ),
  step2 AS (
      SELECT customer_id, SUM(total_cents) AS total
      FROM step1 GROUP BY customer_id
  ),
  step3 AS (
      SELECT customer_id, total,
             RANK() OVER (ORDER BY total DESC) AS rank
      FROM step2
  )
SELECT c.name, s.total, s.rank
FROM step3 s
JOIN customers c ON c.id = s.customer_id
WHERE s.rank <= 10;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Recursive CTE structure:**

```sql
WITH RECURSIVE cte_name AS (
    -- Anchor: base case (starting rows)
    SELECT id, parent_id, name, 1 AS depth
    FROM categories
    WHERE parent_id IS NULL    -- root nodes

    UNION ALL

    -- Recursive: join CTE to itself
    SELECT c.id, c.parent_id, c.name, r.depth + 1
    FROM categories c
    JOIN cte_name r ON c.parent_id = r.id
    WHERE r.depth < 10    -- safety: prevent infinite loops
)
SELECT * FROM cte_name ORDER BY depth, name;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```sql
-- CTEs FOR READABLE MULTI-STEP QUERIES

-- BAD: deeply nested subqueries (unreadable)
SELECT c.name, ranked.total, ranked.rank
FROM customers c
JOIN (
    SELECT customer_id, total,
           RANK() OVER (ORDER BY total DESC) AS rank
    FROM (
        SELECT customer_id, SUM(total_cents) AS total
        FROM (
            SELECT customer_id, total_cents
            FROM orders
            WHERE status = 'DELIVERED'
        ) delivered
        GROUP BY customer_id
    ) agg
) ranked ON ranked.customer_id = c.id
WHERE ranked.rank <= 10;
-- 5 levels of nesting. Hard to read.
-- Hard to debug (no step-by-step testing).

-- GOOD: same logic with CTEs (readable steps)
WITH
delivered_orders AS (
    SELECT customer_id, total_cents
    FROM orders
    WHERE status = 'DELIVERED'
),
customer_totals AS (
    SELECT customer_id,
           SUM(total_cents) AS total_cents
    FROM delivered_orders
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT customer_id,
           total_cents,
           RANK() OVER (
               ORDER BY total_cents DESC
           ) AS revenue_rank
    FROM customer_totals
)
SELECT
    c.name,
    r.total_cents / 100.0  AS total_dollars,
    r.revenue_rank
FROM ranked_customers r
JOIN customers c ON c.id = r.customer_id
WHERE r.revenue_rank <= 10
ORDER BY r.revenue_rank;
```

> **Code walkthrough:** The BAD version is 5 levels of nested subqueries.
> You cannot test step 3 independently; any syntax error requires tracing
> through all levels. The GOOD version: each step is named and independent.
> During development: test `SELECT * FROM delivered_orders` (just the first
> CTE), then progressively add steps. Each CTE acts as a named view for
> the duration of the query. The optimizer in PostgreSQL 12+ will inline
> these CTEs (treating them as derived tables), so performance is equivalent
> to the nested version.

```sql
-- RECURSIVE CTE: hierarchical category tree

-- Category table:
-- id | parent_id | name
--  1 | NULL      | Electronics
--  2 | 1         | Computers
--  3 | 2         | Laptops
--  4 | 2         | Desktops
--  5 | 1         | Phones

-- GOOD: recursive CTE to get full path
WITH RECURSIVE category_path AS (
    -- Anchor: root categories
    SELECT
        id,
        parent_id,
        name,
        name            AS full_path,
        0               AS depth
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    -- Recursive: join to children
    SELECT
        c.id,
        c.parent_id,
        c.name,
        cp.full_path || ' > ' || c.name AS full_path,
        cp.depth + 1
    FROM categories c
    JOIN category_path cp ON c.parent_id = cp.id
)
SELECT id, depth, full_path
FROM category_path
ORDER BY full_path;

-- Result:
-- id=1, depth=0, full_path='Electronics'
-- id=2, depth=1, full_path='Electronics > Computers'
-- id=3, depth=2, full_path='Electronics > Computers > Laptops'
-- id=4, depth=2, full_path='Electronics > Computers > Desktops'
-- id=5, depth=1, full_path='Electronics > Phones'
```

> **Code walkthrough:** The anchor member selects root categories
> (`parent_id IS NULL`). The recursive member joins `categories` to the
> current CTE result (`cp`) to find children. Each iteration adds one
> level of the hierarchy. `full_path` builds the breadcrumb string by
> appending the current name. `depth + 1` tracks how deep we are.
> The `WHERE r.depth < 10` guard (not shown here but critical) prevents
> infinite loops if the data has cycles (a child pointing back to an ancestor).
> Always include a depth limit in recursive CTEs on user-generated data.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> CTEs use `WITH name AS (SELECT ...)` to name an intermediate result.
> They make complex queries readable by breaking them into named steps.
> Recursive CTEs (`WITH RECURSIVE`) process hierarchical data: org charts,
> category trees, bill-of-materials. Always include a depth limit in
> recursive CTEs to prevent infinite loops.

---

**Senior / Staff:**
> In PostgreSQL 12+, CTEs are inlined by default. This means the optimizer
> can push predicates from the outer query into the CTE - a major
> performance improvement over PostgreSQL 11. If you are migrating from PG11
> and notice plan changes after upgrade: check CTE-heavy queries with
> EXPLAIN. Add `AS MATERIALIZED` if a CTE is referenced multiple times
> and you want to compute it once (avoids re-execution). Use `AS NOT MATERIALIZED`
> explicitly in PG11-compatible code to document intent.

---

### ⚠️ Common Misconceptions

**"CTEs are faster than subqueries because they cache results"**

Reality: in PostgreSQL 12+, CTEs are NOT automatically materialized
(they are inlined). They do not cache by default. In PostgreSQL 11 and
earlier: they were always materialized (computed once, stored). Adding
`AS MATERIALIZED` in PG12+ forces the cache behavior. Without it: the
CTE is re-evaluated where referenced.

**"Recursive CTEs can handle arbitrarily deep hierarchies"**

Reality: recursive CTEs have a recursion limit (default 100 in many databases).
PostgreSQL: `max_recursion_depth` (default 1000). For very deep hierarchies
(>1000 levels): either increase the limit or use a different technique
(closure table, materialized path, nested sets).

---

### ⚖️ Comparison Table

| Technique | Readable | Reusable | Recursive | Optimizer can inline | Best for |
|---|---|---|---|---|---|
| Nested subquery | No | No | No | Yes | Simple one-off |
| Derived table | Medium | No | No | Yes | Single-use intermediate |
| CTE (PG12+) | Yes | Yes (in query) | Yes (RECURSIVE) | Yes | Complex multi-step |
| CTE MATERIALIZED | Yes | Yes | Yes | No | Computed once, multi-use |
| View | Yes | Yes (cross-query) | Limited | Yes | Reused across queries |

---

### 🏛️ System Design

*(Omit: L2 keyword - CTEs are a query pattern, not a system-level design concern)*

---

### 📊 Diagram

*(Omit: CTE structure is best illustrated in code examples above)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Recursive CTE causes infinite loop**

Symptom: query runs indefinitely; eventually fails with "maximum
recursion depth exceeded."

Cause: circular reference in the data (node A -> node B -> node A).

Fix:
```sql
-- Add a depth limit to the recursive member
WHERE cp.depth < 50   -- stop at 50 levels

-- Or detect cycles (PostgreSQL):
WITH RECURSIVE tree AS (
    SELECT id, parent_id, ARRAY[id] AS path
    FROM nodes WHERE parent_id IS NULL
    UNION ALL
    SELECT n.id, n.parent_id, t.path || n.id
    FROM nodes n
    JOIN tree t ON n.parent_id = t.id
    WHERE NOT n.id = ANY(t.path)  -- cycle detection
)
SELECT * FROM tree;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Failure: CTE is slow after PostgreSQL 11 -> 12 upgrade**

Symptom: a query using CTEs is suddenly much slower after upgrade.

Cause: in PG12+, CTEs are inlined by default. The optimizer now pushes
predicates into the CTE, which changes the plan (usually for the better,
but sometimes worse if the CTE result was small and should have been
computed once).

Fix: add `AS MATERIALIZED` to CTEs that should be computed once.

---

### 🎯 Interview Deep-Dive

**Q1: What is the difference between a CTE and a view?**

🗣️ "A CTE exists for the duration of one query. A view is a stored query
accessible from any query. CTE: defined in the WITH clause, referenced
by name in the same statement. View: `CREATE VIEW name AS SELECT ...`,
then `SELECT * FROM name` in any query. Both can be inlined (optimizer
sees through to the base tables). CTEs are useful for: complex single queries,
recursive queries, intermediate named steps. Views are useful for: frequently
reused query logic, access control (grant access to the view, not the table),
abstracting complex schema into a simpler interface."

**Q2: When would you use a recursive CTE vs. a closure table?**

🗣️ "Recursive CTE: simple to set up, queries traverse the tree at runtime.
Good for: data with a tree structure that is already in the adjacency list
format (parent_id FK). Performance degrades with depth: each level requires
one recursive pass. Closure table: a separate table storing all ancestor-descendant
pairs. Pre-computed. Queries are O(1) (a single join to the closure table).
Good for: frequent reads with depth queries, large hierarchies.
Overhead: writes are more complex (insert/update to closure table on
hierarchy changes). Rule: use recursive CTE for moderate-depth trees (< 100 levels)
with infrequent traversal. Use closure table for large, frequently-queried hierarchies."

**Q3: How does a recursive CTE work internally?**

🗣️ "The database executes a recursive CTE as a loop: (1) Execute the
anchor member. Load the result into a working table. (2) Execute the
recursive member, joining the CTE name to the working table. Append the
result to the CTE. (3) Repeat step 2 using only the newly added rows
as the 'working set' (not the entire CTE). (4) Stop when the recursive
member produces 0 new rows. This is a breadth-first traversal (each
iteration adds one level of children). Total work: proportional to the
total number of rows in the result tree. For a tree with 1 million nodes:
1 million row insertions into the working table, one per node."

**Q4: What is a data-modifying CTE?**

🗣️ "PostgreSQL supports INSERT, UPDATE, and DELETE in CTEs.
`WITH deleted AS (DELETE FROM sessions WHERE expires_at < now() RETURNING *)
SELECT COUNT(*) FROM deleted`.
The DELETE runs as part of the query; the RETURNING clause makes the
affected rows available to the outer SELECT. Use cases: (1) delete rows
and log them in one statement; (2) insert a row and use its generated ID
in a subsequent INSERT; (3) multi-table updates in one atomic operation.
Data-modifying CTEs execute exactly once, in parallel, within the same
transaction snapshot. Changes from one CTE are not visible to other CTEs
in the same statement (they see the pre-modification snapshot)."

**Q5: How do you debug a complex multi-CTE query?**

🗣️ "Step-by-step testing: the key advantage of CTEs over nested subqueries.
(1) Run just the first CTE as a standalone SELECT. Verify its output.
(2) Add the second CTE. Run `SELECT * FROM second_cte_name`. (3) Continue
adding CTEs and verifying each result. (4) Write the final SELECT.
For performance debugging: `EXPLAIN ANALYZE` on the full query shows each
CTE step as a named node (in PG11, materialized CTEs show as 'CTE Scan').
If a CTE is materialized: its plan shows as a sub-plan. If inlined: the
optimizer merges it into the main plan. Use `AS MATERIALIZED` to isolate
a slow CTE and optimize it independently."

**Q6: When should you use a window function inside a CTE?**

🗣️ "Window functions must execute after WHERE and GROUP BY. They cannot
be referenced in WHERE or HAVING of the same query. The pattern: compute
the window function in a CTE, then filter in the outer query.
`WITH ranked AS (SELECT id, status, RANK() OVER (PARTITION BY customer_id ORDER BY created_at DESC) AS rn FROM orders)
SELECT * FROM ranked WHERE rn = 1` - gets the most recent order per customer.
Without the CTE: `SELECT * FROM (SELECT ..., RANK() OVER (...) AS rn FROM orders) sub WHERE rn = 1`.
CTEs make this readable. Window functions in CTEs are common for:
deduplication (keep first/last), ranking (top N per group), running totals."

**Q7: What are the limitations of recursive CTEs?**

🗣️ "Four key limitations: (1) Recursion depth limit: PostgreSQL default
1000 iterations. Override with `SET max_recursion_depth = 10000` or `RECURSIVE ... LIMIT`.
(2) Cycles: the recursive member must terminate. Data with cycles
(graph edges with loops) requires explicit cycle detection using an
array of visited IDs. (3) No aggregation in recursive member: you cannot
use GROUP BY, DISTINCT, or LIMIT in the recursive branch. (4) Performance:
recursive CTEs are always materialized; each level is a separate scan.
For very deep or wide trees: performance degrades. Alternative: closure
table (pre-compute ancestry), or application-side graph traversal."

**Q8: How does CTE inlining in PostgreSQL 12+ affect query planning?**

🗣️ "Before PG12: CTEs were always materialized (computed once, result stored).
Any WHERE condition in the outer query was NOT pushed into the CTE.
Example: `WITH recent AS (SELECT * FROM orders) SELECT * FROM recent WHERE id = 5`.
In PG11: the CTE scanned all orders, stored the result, then filtered by id.
In PG12+: the CTE is inlined - the optimizer pushes `id = 5` into the CTE
and uses the index. Result: the CTE effectively becomes a named derived table.
When to force materialization: if the CTE is referenced multiple times and
recomputing it would be expensive. Add `AS MATERIALIZED` to get PG11 behavior.
When to force inlining: `AS NOT MATERIALIZED` (default in PG12+)."

**Q9: What is the performance difference between a CTE and a temporary table?**

🗣️ "CTE: in-memory, scoped to one query. The result is not stored on disk
(unless it spills due to large size). No schema, no indexes, no persistence
beyond the statement. Temporary table: a real table stored in the session-scoped
temp schema. Has full table properties: can be indexed, can be analyzed,
can be written to multiple times, persists for the session. Use temporary
table when: (1) the intermediate result is very large and needs an index for
subsequent queries; (2) the same intermediate result is used in multiple queries;
(3) you need to run ANALYZE on the intermediate result to give the optimizer
correct statistics. Use CTE when: the result is used in one query and is
small to medium size. Temporary tables have write overhead (WAL in some modes)
but are more flexible."

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



