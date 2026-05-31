---
layout: default
title: "Database SQL - L3 Advanced SQL"
parent: "Database SQL"
grand_parent: "SK Interview"
nav_order: 10
permalink: /database-sql/l3-advanced-sql/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Window Functions - ROW_NUMBER, RANK, LAG, LEAD](#window-functions---rownumber-rank-lag-lead) | medium |
| 2 | [Recursive CTEs - Hierarchical Data Queries](#recursive-ctes---hierarchical-data-queries) | medium |

---

# Window Functions - ROW_NUMBER, RANK, LAG, LEAD

**TL;DR:** Window functions compute aggregate or positional values for
each row relative to a "window" of related rows, without collapsing the
row set. Unlike GROUP BY: the original rows are preserved. Key functions:
ROW_NUMBER (unique row number), RANK (with gaps for ties), LAG/LEAD
(access previous/next row's value). Window functions are indispensable
for ranking, running totals, and time-series comparisons.

---

### 🎯 Model Answer

**30 seconds:**
> Window functions compute values across a partition of rows while keeping
> each row in the result. `OVER (PARTITION BY col ORDER BY col)` defines
> the window. ROW_NUMBER: unique sequential number. RANK: rank with gaps
> for ties. LAG: access the previous row's value. LEAD: access the next
> row's value. Used for: top-N per group, running totals, period-over-period
> comparisons.

**3 minutes:**
> The key distinction from GROUP BY: GROUP BY reduces N rows to M rows
> (one per group). Window functions return N rows, each with an additional
> computed column based on the window context.
>
> Window definition: `PARTITION BY col` divides rows into groups (like
> GROUP BY but without collapsing). `ORDER BY col` within OVER defines
> the processing order within the partition. The frame clause (`ROWS BETWEEN`)
> defines which rows are included in the window (relevant for running totals).
>
> Practical use cases: (1) Pagination/top-N per group: `ROW_NUMBER() OVER
> (PARTITION BY customer_id ORDER BY created_at DESC)` - number orders per
> customer by recency. Filter `WHERE rn = 1` to get the latest order per
> customer. (2) Running total: `SUM(amount) OVER (ORDER BY date ROWS BETWEEN
> UNBOUNDED PRECEDING AND CURRENT ROW)`. (3) Month-over-month comparison:
> `LAG(revenue, 1) OVER (PARTITION BY product_id ORDER BY month)` to access
> the previous month's revenue.

**Blank Mind Recovery:**

**(1) Restate:** "Window function: aggregate per row's context without collapsing.
OVER (PARTITION BY ... ORDER BY ...). ROW_NUMBER, RANK, LAG, LEAD, SUM, AVG."

**(2) First principles:** "A window function evaluates for each row using
a set of 'neighboring' rows defined by the window. It augments each row
rather than replacing it."

**(3) Bridge:** "Like a spreadsheet where column F = SUM of previous 3 rows
in column E. Each row still exists; column F adds context about the running
total. That's a window function."

---

### 📘 Concept Explanation

**Window function syntax:**

```sql
function_name() OVER (
    [PARTITION BY col1, col2, ...]   -- groups (optional)
    [ORDER BY col3 ASC/DESC, ...]   -- order within group
    [ROWS BETWEEN frame_start AND frame_end]  -- frame
)

Frame options:
  UNBOUNDED PRECEDING: from the start of the partition
  n PRECEDING:         n rows before current
  CURRENT ROW:         current row
  n FOLLOWING:         n rows after current
  UNBOUNDED FOLLOWING: to the end of the partition

Default frame (when ORDER BY is specified):
  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  (This is why SUM with ORDER BY gives a running total)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Function reference:**

```
Ranking:
  ROW_NUMBER()     unique sequential integer per partition
  RANK()           rank with gaps for ties
                   (1, 2, 2, 4 for values A, B, B, C)
  DENSE_RANK()     rank without gaps
                   (1, 2, 2, 3 for values A, B, B, C)
  NTILE(n)         divide partition into n equal buckets

Navigation:
  LAG(col, n)      value of col n rows before current
  LEAD(col, n)     value of col n rows after current
  FIRST_VALUE(col) first value in the window frame
  LAST_VALUE(col)  last value in the window frame
  NTH_VALUE(col,n) Nth value in the window frame

Aggregate (as window):
  SUM, AVG, COUNT, MIN, MAX applied over the window
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```sql
-- RANKING: top-N per group (the killer window function use case)

-- BAD: correlated subquery (O(n) per row)
SELECT *
FROM orders o
WHERE (
    SELECT COUNT(*)
    FROM orders o2
    WHERE o2.customer_id = o.customer_id
      AND o2.created_at > o.created_at
) < 3;
-- Get the 3 most recent orders per customer.
-- Correlated subquery executes once per order.
-- O(N) subquery executions. Slow at scale.

-- GOOD: window function (single pass)
WITH ranked AS (
    SELECT
        id,
        customer_id,
        total_cents,
        created_at,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY created_at DESC
        ) AS rn
    FROM orders
)
SELECT id, customer_id, total_cents, created_at
FROM ranked
WHERE rn <= 3;
-- Single pass: each order gets its rank within its customer.
-- Filter rn <= 3: keeps top 3 per customer.
-- No correlated subquery. O(n log n) total.
```

> **Code walkthrough:** The BAD correlated subquery computes the rank of
> each order by counting how many orders for the same customer are newer -
> this requires a full index scan per order, O(N) total inner queries.
> The GOOD window function computes `ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at DESC)`:
> it partitions orders by customer, sorts each customer's orders by date
> (newest first), and assigns 1, 2, 3... The CTE wrapper is needed because
> window functions cannot be filtered in the same WHERE clause where they
> are defined. Filtering `WHERE rn <= 3` in the outer query gets the top 3.

```sql
-- LAG AND LEAD: period-over-period comparisons

-- Monthly revenue per product
WITH monthly AS (
    SELECT
        product_id,
        DATE_TRUNC('month', created_at) AS month,
        SUM(total_cents)                AS revenue
    FROM orders
    GROUP BY product_id, DATE_TRUNC('month', created_at)
),
with_comparison AS (
    SELECT
        product_id,
        month,
        revenue,
        LAG(revenue, 1)  OVER (
            PARTITION BY product_id
            ORDER BY month
        ) AS prev_month_revenue,
        LEAD(revenue, 1) OVER (
            PARTITION BY product_id
            ORDER BY month
        ) AS next_month_revenue
    FROM monthly
)
SELECT
    product_id,
    month,
    revenue,
    prev_month_revenue,
    revenue - prev_month_revenue          AS mom_change,
    ROUND(
        100.0 * (revenue - prev_month_revenue)
               / NULLIF(prev_month_revenue, 0),
        2
    )                                     AS mom_pct_change
FROM with_comparison
WHERE month >= '2024-01-01'
ORDER BY product_id, month;
```

> **Code walkthrough:** `LAG(revenue, 1) OVER (PARTITION BY product_id ORDER BY month)`:
> for each row, look 1 row backward within the same product's time series.
> January's row gets December's revenue. The `mom_pct_change` calculation:
> `(current - previous) / previous * 100`. `NULLIF(prev_month_revenue, 0)`
> prevents division by zero if the previous month had zero revenue (returns
> NULL instead of an error). `LEAD` looks forward: January's row gets
> February's planned revenue. Without window functions: this would require
> a self-join on the same table with date manipulation - complex and slow.

```sql
-- RUNNING TOTALS AND MOVING AVERAGES

SELECT
    id,
    created_at,
    total_cents,
    -- Running total for the day
    SUM(total_cents) OVER (
        PARTITION BY DATE(created_at)
        ORDER BY created_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS daily_running_total,
    -- 7-row moving average
    AVG(total_cents) OVER (
        ORDER BY created_at
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7,
    -- Percentage of daily total
    ROUND(
        100.0 * total_cents
             / SUM(total_cents) OVER (
                   PARTITION BY DATE(created_at)),
        2
    ) AS pct_of_daily_total
FROM orders
ORDER BY created_at;
```

> **Code walkthrough:** Three different OVER clauses in one SELECT. The
> running total partitions by date (resets to 0 each day) and orders by
> time (accumulates through the day). `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`
> makes the SUM cumulative up to the current row. The 7-row moving average
> uses `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` - the current row plus
> the 6 rows before it (7 total). The percentage share uses a window
> without ORDER BY - it calculates the total for the whole day partition
> and divides each row's value by that total.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Window functions compute values relative to the current row's context
> without collapsing rows. `OVER (PARTITION BY group ORDER BY sort)` defines
> the window. ROW_NUMBER for unique sequence, RANK for ranking (with gaps),
> LAG for the previous row's value, LEAD for the next row's value.
> Common use: top-N per group (ROW_NUMBER + CTE + WHERE rn <= N).

---

**Senior / Staff:**
> Window functions are the tool of choice for three categories:
> (1) per-group ranking (top-N, deduplication by row number);
> (2) time-series calculations (LAG/LEAD for period comparisons,
> running totals with frame specification); (3) percentage and proportion
> calculations (each row / partition total). The alternative for any of
> these is correlated subqueries or self-joins - both O(n^2) or O(n*m).
> Window functions are single-pass O(n log n). They execute after WHERE
> and GROUP BY - you cannot filter on window function results in WHERE;
> use a CTE wrapper.

---

### ⚠️ Common Misconceptions

**"RANK() and DENSE_RANK() are interchangeable"**

Reality: for values A, A, B: `RANK()` gives 1, 1, 3 (gap at position 2).
`DENSE_RANK()` gives 1, 1, 2 (no gap). For pagination queries: if you
say "top 5 customers by revenue" using `RANK() <= 5` but the 5th position
has 3 ties: you may get 7 customers (tied 5th through 7th all have rank 5).
Use `ROW_NUMBER()` for strict "exactly N results" pagination (non-deterministic
for ties). Use `DENSE_RANK()` for "top 5 positions with ties."

**"Window functions can be used in WHERE clauses"**

Reality: window functions execute after WHERE, GROUP BY, and HAVING.
They cannot be referenced in WHERE. Wrap in a CTE or subquery and
filter in the outer query.

---

### ⚖️ Comparison Table

| Requirement | Window Function | Alternative | Why WF wins |
|---|---|---|---|
| Top N per group | ROW_NUMBER + CTE | Correlated subquery | O(n log n) vs O(n^2) |
| Running total | SUM OVER ORDER BY | Self-join | Single pass |
| Month-over-month | LAG/LEAD | Self-join on shifted date | No join needed |
| Rank within group | RANK/DENSE_RANK | Subquery COUNT | Single pass |
| Moving average | AVG OVER frame | Manual aggregation | Declarative |

---

### 🏛️ System Design

*(Omit: L3 keyword - window functions are a query pattern, not a system design concern)*

---

### 📊 Diagram

*(Omit: window function behavior well-illustrated in code examples)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Incorrect moving average due to wrong frame clause**

Symptom: moving average does not match expected values.

Cause: default frame is `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`
when ORDER BY is specified. `RANGE` frame includes all rows with equal
ORDER BY values in the "current" group (ties), not just physically adjacent rows.

Fix: use `ROWS BETWEEN n PRECEDING AND CURRENT ROW` for physical row count:
```sql
AVG(amount) OVER (
    ORDER BY date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Failure: Partition too large for memory in window function execution**

Symptom: query is very slow or fails with out-of-memory for large result sets.

Cause: window functions process one partition at a time. A single partition
of 10 million rows may exceed `work_mem`.

Fix: increase `work_mem` for the session, or add a WHERE filter to reduce
the working set, or partition the data by an additional column.

---

### 🎯 Interview Deep-Dive

**Q1: What is the execution order of window functions relative to other clauses?**

🗣️ "Execution order: FROM -> JOIN -> WHERE -> GROUP BY -> HAVING -> window functions
-> SELECT -> DISTINCT -> ORDER BY -> LIMIT. Key: window functions execute
after WHERE and GROUP BY. This means: (1) window functions see only the rows
that survived WHERE filtering; (2) if GROUP BY is used, window functions
operate on grouped rows; (3) you cannot filter on a window function result
in WHERE - the window function has not been evaluated yet. The workaround:
place the window function in a CTE or subquery, then filter in the outer query."

**Q2: What is the difference between ROWS and RANGE frame modes?**

🗣️ "ROWS: physical rows. `ROWS BETWEEN 3 PRECEDING AND CURRENT ROW` includes
exactly the 3 rows before the current row plus the current row (4 rows total).
RANGE: logical range based on ORDER BY values. `RANGE BETWEEN 3 PRECEDING AND CURRENT ROW`
includes all rows whose ORDER BY value is within 3 of the current row's value.
If the ORDER BY column is a date: `RANGE BETWEEN INTERVAL '3 days' PRECEDING AND CURRENT ROW`.
The default frame (when ORDER BY is present): `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.
For equal ORDER BY values: RANGE includes all tied rows in the 'current' window.
For numerical calculations like moving averages: ROWS is usually what you want
(precise row count). For time-based windows: RANGE (or GROUPS in PG11+) is appropriate."

**Q3: How does FILTER clause work with window functions?**

🗣️ "`FILTER (WHERE condition)` can be applied to aggregate window functions:
`SUM(amount) FILTER (WHERE status = 'PAID') OVER (PARTITION BY customer_id)`.
This computes a running sum but only counting paid orders. Each row gets
the sum of paid orders for its customer partition. Without FILTER: you would
need a CASE expression: `SUM(CASE WHEN status='PAID' THEN amount END)`. FILTER
is more readable. Applicable to: SUM, COUNT, AVG, MIN, MAX in window context.
Not applicable to: ranking functions (ROW_NUMBER, RANK) - they do not take
a value argument."

**Q4: How do you deduplicate rows using ROW_NUMBER?**

🗣️ "Classic deduplication pattern: assign ROW_NUMBER over a partition by
the key columns, ordered by the preferred row (e.g., most recent update).
Filter to keep only rn=1.
`WITH deduped AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY updated_at DESC) AS rn
FROM customer_events)
SELECT * FROM deduped WHERE rn = 1`.
This keeps the most recently updated row per customer_id. Alternative:
`DISTINCT ON (customer_id) ... ORDER BY customer_id, updated_at DESC` (PostgreSQL-specific,
simpler but less flexible). ROW_NUMBER approach: portable, explicit, allows
filtering multiple results per group."

**Q5: How would you compute a 30-day rolling revenue for each day?**

🗣️ "`SELECT date, revenue,
SUM(revenue) OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
AS rolling_30d_revenue FROM daily_revenue`.
`ROWS BETWEEN 29 PRECEDING AND CURRENT ROW`: today plus the 29 days before it
= 30 days. The SUM computes the total for that 30-row window. Key: this is
correct only if there is one row per day with no gaps. For gaps (missing days):
use `RANGE BETWEEN INTERVAL '29 days' PRECEDING AND CURRENT ROW` to include
all rows within the 30-day date range regardless of row count.
For a moving average: `AVG(revenue) OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)`."

**Q6: What is the difference between FIRST_VALUE and LAG for getting the previous value?**

🗣️ "`LAG(col, n)`: accesses the value n rows before the current row in the window order. Simple, efficient.
`FIRST_VALUE(col) OVER (PARTITION BY group ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`:
always returns the first value in the partition up to the current row.
For 'previous row': LAG(col, 1) is simpler. For 'first value of the period':
FIRST_VALUE. Example: each monthly row showing the revenue for the first month
of the year: `FIRST_VALUE(revenue) OVER (PARTITION BY EXTRACT(YEAR FROM month) ORDER BY month)`.
LAG with n=1 accesses only the immediately preceding row. FIRST_VALUE accesses
the beginning of the frame."

**Q7: How do window functions perform compared to self-joins for time-series comparisons?**

🗣️ "Self-join: `FROM sales s1 JOIN sales s2 ON s1.product_id = s2.product_id AND s2.month = s1.month - INTERVAL '1 month'`.
Both tables are scanned/indexed, joined. Cost: O(n log n) with indexes, O(n^2) without.
Window function: `LAG(revenue, 1) OVER (PARTITION BY product_id ORDER BY month)`.
Single pass over the sorted data. No join. The window function is almost always
faster for this pattern. EXPLAIN comparison: self-join shows a Hash Join or
Merge Join node (two table accesses). Window function shows a WindowAgg node
(one pass). The window function does require the data to be sorted (by the
OVER ORDER BY) - the sort is O(n log n). For already-sorted data (index on
(product_id, month)): window function can use an index scan with no explicit sort."

**Q8: What are named windows and when are they useful?**

🗣️ "Named windows: define a window specification once and reference it by name.
`SELECT ..., ROW_NUMBER() OVER w, RANK() OVER w, SUM(amount) OVER w
FROM orders
WINDOW w AS (PARTITION BY customer_id ORDER BY created_at DESC)`.
The `WINDOW w AS (...)` clause defines the window. Multiple window functions
can reference the same window without repeating the definition. Benefits:
DRY (no repeated OVER clauses), easier to modify (change partition once),
readable (the window logic is named). Useful when: three or more window
functions use the same partition/order. Note: named windows cannot extend
other named windows (you cannot `WINDOW w2 AS (w ORDER BY col2)`)."

**Q9: How do you handle NULL values in LAG and LEAD?**

🗣️ "`LAG(col, 1, default_value)`: the third argument is the default to return
when there is no preceding row (i.e., the first row in the partition has no
LAG). Without default: returns NULL for rows with no preceding row.
`LAG(revenue, 1, 0) OVER (PARTITION BY product_id ORDER BY month)`: for the
first month of each product, returns 0 instead of NULL. Useful for calculations:
`revenue - LAG(revenue, 1, revenue)` (no change if first month, not NULL).
For NULLs within the data: `LAG(col, 1) IGNORE NULLS` (Oracle/BigQuery syntax;
not PostgreSQL standard) skips NULL values and returns the last non-NULL value.
PostgreSQL workaround: `LAST_VALUE(col) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` with NULLs manually handled via COALESCE."

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


# Recursive CTEs - Hierarchical Data Queries

**TL;DR:** A recursive CTE (`WITH RECURSIVE`) enables SQL to traverse
hierarchical or graph-like data: org charts, category trees, file paths,
bill-of-materials. It uses an anchor member (base case) and a recursive
member (extends the result by joining the CTE to itself). Always include
a depth limit or cycle detection to prevent infinite loops.

---

### 🎯 Model Answer

**30 seconds:**
> `WITH RECURSIVE` defines a CTE that references itself. Structure: an anchor
> member (base rows) UNION ALL a recursive member (joins CTE to itself to
> find children). Repeats until no new rows. Use for: org charts, category
> trees, path finding, bill-of-materials. Always add a depth limit to prevent
> infinite loops on cyclic data.

**3 minutes:**
> A recursive CTE executes in rounds. Round 1: execute the anchor member
> (base case - root nodes). Round 2: join the source table to round 1's
> result to find their children. Round 3: find children of round 2's result.
> Continue until no new rows are produced.
>
> Common patterns: (1) Subtree traversal - given a root node, find all
> descendants. (2) Path reconstruction - build the full path string
> from root to each node. (3) Level depth - track how deep each node is.
> (4) Cycle detection - track visited IDs in an array.
>
> Performance: recursive CTEs are always materialized. Each round's result
> is stored. For deep trees (100+ levels) or wide trees (millions of nodes):
> performance can degrade. Alternatives: closure table (precomputed ancestor
> pairs) for read-heavy hierarchies, or Nested Set model.

**Blank Mind Recovery:**

**(1) Restate:** "WITH RECURSIVE: anchor (roots) UNION ALL recursive (find children).
Repeats until no new rows. Add depth limit. Always."

**(2) First principles:** "Recursion in SQL: the CTE is defined in terms of itself.
Each recursion level extends the result by one level of children. SQL has no
loops; recursive CTE simulates a loop."

**(3) Bridge:** "Like a family tree. Start with grandparents (anchor).
Find their children (round 2). Find grandchildren (round 3). Stop when
no more children. The recursive CTE builds the family tree one generation
at a time."

---

### 📘 Concept Explanation

**Recursive CTE structure:**

```sql
WITH RECURSIVE cte_name AS (
    -- ANCHOR: the base case (non-recursive part)
    SELECT ... FROM table WHERE parent_id IS NULL

    UNION ALL  -- MUST be UNION ALL, not UNION

    -- RECURSIVE MEMBER: extends the result
    -- References cte_name to find the "current level"
    SELECT t.* FROM table t
    JOIN cte_name r ON t.parent_id = r.id
    -- WHERE r.depth < 100  -- ALWAYS add depth limit
)
SELECT * FROM cte_name;

Rules:
  - UNION ALL is required (UNION would deduplicate each level,
    which is costly and usually wrong)
  - The recursive member cannot use:
    GROUP BY, HAVING, DISTINCT, LIMIT, aggregate functions
  - Add WHERE depth < N to prevent infinite loops on cyclic data
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Termination:**

```
Terminates when the recursive member returns 0 rows.
For a finite tree: terminates at the leaf level.
For cyclic graphs: DOES NOT terminate without a cycle guard.
Cycle guard pattern:
  Track visited IDs in an array:
  WHERE NOT (child.id = ANY(visited_path))
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```sql
-- HIERARCHICAL CATEGORY TREE

-- Schema:
-- categories: id, parent_id, name, sort_order

-- GOOD: recursive CTE to get full tree with path and depth
WITH RECURSIVE cat_tree AS (
    -- Anchor: top-level categories (no parent)
    SELECT
        id,
        parent_id,
        name,
        CAST(name AS TEXT)   AS full_path,
        0                    AS depth,
        ARRAY[id]            AS path_ids
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    -- Recursive: find children of current level
    SELECT
        c.id,
        c.parent_id,
        c.name,
        ct.full_path || ' > ' || c.name AS full_path,
        ct.depth + 1,
        ct.path_ids || c.id
    FROM categories c
    JOIN cat_tree ct ON c.parent_id = ct.id
    WHERE ct.depth < 20           -- max depth guard
      AND NOT c.id = ANY(ct.path_ids)  -- cycle guard
)
SELECT
    LPAD('', depth * 2, ' ') || name AS indented_name,
    full_path,
    depth
FROM cat_tree
ORDER BY full_path;

-- Result:
-- Electronics
--   Computers
--     Laptops
--     Desktops
--   Phones
--     Smartphones
```

> **Code walkthrough:** The anchor selects root categories (`parent_id IS NULL`).
> Each recursive pass joins `categories c` to the current CTE result `ct`
> on `c.parent_id = ct.id` - finding children of the current level.
> `full_path` builds the breadcrumb string by concatenating parent path
> with the current node's name. `depth + 1` tracks the level.
> `path_ids || c.id` appends the current ID to the visited path array -
> this is the cycle guard: `NOT c.id = ANY(ct.path_ids)` prevents revisiting
> a node. `LPAD('', depth * 2, ' ')` indents by 2 spaces per level for display.

```sql
-- ORG CHART: find all reports under a manager

WITH RECURSIVE reports AS (
    -- Anchor: the specified manager
    SELECT id, manager_id, name, title, 0 AS depth
    FROM employees
    WHERE id = :manager_id

    UNION ALL

    -- Recursive: find direct reports
    SELECT e.id, e.manager_id, e.name, e.title,
           r.depth + 1
    FROM employees e
    JOIN reports r ON e.manager_id = r.id
    WHERE r.depth < 10  -- limit to 10 levels deep
)
SELECT
    depth,
    LPAD('', depth * 4, '-') || name AS org_chart,
    title
FROM reports
ORDER BY depth, name;

-- Find path from employee to CEO (upward traversal):
WITH RECURSIVE upward AS (
    SELECT id, manager_id, name, 0 AS level
    FROM employees WHERE id = :employee_id

    UNION ALL

    SELECT e.id, e.manager_id, e.name, u.level + 1
    FROM employees e
    JOIN upward u ON e.id = u.manager_id
    WHERE u.level < 20
)
SELECT name, level FROM upward ORDER BY level;
```

> **Code walkthrough:** The downward traversal (find all reports) starts
> from a specific manager (anchor = `WHERE id = :manager_id`) and recursively
> finds all employees whose `manager_id` matches the current level's IDs.
> The upward traversal (find the management chain to CEO) works in reverse:
> the anchor is the specific employee, the recursive member follows `manager_id`
> upward. Both include a depth guard. The result gives the org chart from
> any starting point - upward or downward. This query replaces application-side
> tree traversal loops.

```sql
-- BILL OF MATERIALS: total quantity including sub-components

-- Schema:
-- components: id, name
-- component_parts: parent_id, child_id, quantity

WITH RECURSIVE bom AS (
    -- Anchor: the top-level component
    SELECT child_id AS component_id, quantity, 1 AS level
    FROM component_parts
    WHERE parent_id = :top_level_id

    UNION ALL

    -- Recursive: find sub-components
    SELECT cp.child_id, bom.quantity * cp.quantity,
           bom.level + 1
    FROM component_parts cp
    JOIN bom ON cp.parent_id = bom.component_id
    WHERE bom.level < 10
)
SELECT
    c.name,
    SUM(bom.quantity) AS total_quantity
FROM bom
JOIN components c ON c.id = bom.component_id
GROUP BY c.name
ORDER BY c.name;
```

> **Code walkthrough:** Bill of materials traversal accumulates quantities
> multiplicatively: `bom.quantity * cp.quantity`. If the top component needs
> 2 of sub-component A, and sub-component A needs 3 of part X: the total
> is 2 * 3 = 6 of part X. The GROUP BY aggregates across all paths to the
> same component (a component might appear in multiple branches; GROUP BY
> sums their quantities). This query replaces a complex application-side BOM
> traversal that would require multiple round trips.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> `WITH RECURSIVE` allows a CTE to reference itself. Structure: anchor
> (base case, usually root nodes) UNION ALL recursive member (join CTE
> to source table to find next level). Repeats until no new rows.
> Use for: org charts, category trees, path finding. Always include a
> depth limit (`WHERE depth < 20`) to prevent infinite loops.

---

**Senior / Staff:**
> Recursive CTEs are powerful but have performance limits. For a tree with
> millions of nodes: the recursive CTE materializes each level, which can
> be expensive. The alternatives: (1) Closure table - a separate table
> of all ancestor-descendant pairs (pre-computed, O(1) lookup but expensive
> to maintain); (2) Ltree (PostgreSQL extension) - store the path as a
> label path, enables fast subtree queries and ancestor checks with GiST
> indexes. For frequently-traversed large hierarchies: choose the right
> storage model, not just recursive CTEs.

---

### ⚠️ Common Misconceptions

**"UNION and UNION ALL are equivalent in recursive CTEs"**

Reality: recursive CTEs require UNION ALL. UNION would deduplicate
after each recursive step - this is O(n log n) overhead per level and
can cause incorrect results for graphs with multiple paths to the same node.
UNION ALL is correct: let the recursive member produce all rows; handle
deduplication in the outer query if needed.

**"Recursive CTEs work on any graph, including cycles"**

Reality: recursive CTEs terminate when the recursive member returns
0 rows. In a cyclic graph (A -> B -> A): the recursive member never
returns 0 rows without a cycle guard. The query runs until it hits
the `max_recursion_depth` limit and errors. Always add cycle detection
for user-provided data (arrays of visited IDs, depth limit, or both).

---

### ⚖️ Comparison Table

| Approach | Setup Complexity | Query Speed | Write Performance | Best For |
|---|---|---|---|---|
| Recursive CTE | None | O(depth) per query | Normal | Simple hierarchies |
| Closure Table | High (maintain table) | O(1) | High (update on write) | Frequent reads |
| Ltree (PostgreSQL) | Medium (extension) | O(log n) with GiST | Normal | Large tree path queries |
| Nested Set | Medium | O(1) range | Very high | Read-only or rare writes |
| Adjacency List | None | O(depth) | Normal | Default (pairs with recursive CTE) |

---

### 🏛️ System Design

*(Omit: L3 keyword - recursive CTE is a query technique, not a system design topic)*

---

### 📊 Diagram

*(Omit: tree traversal behavior illustrated clearly in code examples)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Recursive CTE returns wrong row count (UNION vs UNION ALL)**

Symptom: query returns far fewer rows than the actual tree size. Some branches missing.

Cause: using `UNION` instead of `UNION ALL`. UNION deduplicates across
the entire CTE after each recursive step, discarding nodes that appear
in multiple paths.

Fix: change `UNION` to `UNION ALL`. Handle deduplication in the outer
query if needed.

**Failure: Recursive CTE times out on large graph**

Symptom: query runs for minutes on a hierarchy with 10,000+ nodes.

Cause: each recursive level materializes and scans the previous level.
For wide trees, this is expensive.

Fix: (1) add a tighter WHERE filter in the anchor to reduce the starting set;
(2) add an index on the parent_id column (critical for the recursive JOIN);
(3) consider a closure table for production use.

```sql
-- Essential index for recursive CTE performance:
CREATE INDEX CONCURRENTLY idx_categories_parent_id
    ON categories (parent_id);
-- Without this: each recursive level does a Seq Scan.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

**Q1: What is the difference between recursion in recursive CTEs and application-side recursion?**

🗣️ "Application-side recursion: query the database for each level separately
(N+1 per level). For a 10-level tree: 10 round trips. Each round trip
has network latency (1-5ms). For deep trees: 50-100ms just in latency.
Recursive CTE: all levels processed in a single database operation.
One round trip. The database uses a working table to track the current
frontier; each recursive step extends it. Benefits of SQL recursion:
(1) single round trip; (2) database can use indexes for the JOIN in each
step; (3) result set returned atomically (consistent snapshot).
Use application-side recursion only when: the graph is very large and only
a small portion needs to be traversed (stop condition based on application logic)."

**Q2: How does PostgreSQL implement recursive CTE execution internally?**

🗣️ "PostgreSQL uses a working table (a temporary buffer). Step 1: execute the
anchor member, store results in the working table and the final result table.
Step 2: execute the recursive member, joining to the working table. Copy
results to both the working table (next iteration's input) and the final
result. Replace the old working table with only the new rows. Step 3: repeat
until the working table is empty (recursive member returned 0 new rows).
Step 4: return the accumulated final result. Memory: the working table is
in-memory if it fits; spills to disk for large results. The recursive CTE
is always materialized - no inlining or predicate pushdown into it."

**Q3: How do you find the shortest path between two nodes using a recursive CTE?**

🗣️ "For an unweighted graph: BFS (breadth-first search) finds the shortest path.
A recursive CTE does breadth-first traversal naturally.
`WITH RECURSIVE bfs AS (
SELECT start_node AS id, ARRAY[start_node] AS path, 0 AS hops
FROM nodes WHERE id = :start
UNION ALL
SELECT n.id, bfs.path || n.id, bfs.hops + 1
FROM edges e JOIN nodes n ON n.id = e.to_id
JOIN bfs ON e.from_id = bfs.id
WHERE NOT n.id = ANY(bfs.path) AND bfs.hops < 20)
SELECT path, hops FROM bfs WHERE id = :end ORDER BY hops LIMIT 1`.
First row returned (ORDER BY hops LIMIT 1) is the shortest path.
For weighted graphs: Dijkstra's algorithm needs specific ordering within
the recursion, which recursive CTEs cannot efficiently enforce."

**Q4: What is a closure table and when would you use it over a recursive CTE?**

🗣️ "A closure table stores all ancestor-descendant pairs.
`CREATE TABLE category_closure (ancestor_id, descendant_id, depth)`.
For category 3 (child of 2, which is child of 1):
rows: (1,3,2), (2,3,1), (3,3,0).
Query 'all descendants of category 1': `WHERE ancestor_id = 1`.
O(1) - one index lookup. No recursion. Insert/update: when a new node
is added: insert closure rows for the new node and all its ancestors.
O(depth) writes per insert. Use closure table when: (1) frequent
subtree queries, (2) large hierarchies (10,000+ nodes), (3) low write
frequency relative to reads. Use recursive CTE when: (4) simple setup,
(5) infrequent tree queries, (6) hierarchy depth is shallow."

**Q5: How do you implement a path enumeration alternative to recursive CTEs?**

🗣️ "Path enumeration: store the full path string in each row.
`categories: id, path_string, name`.
For category 3 (child of 2 -> child of 1): `path_string = '1/2/3'`.
Queries: `WHERE path_string LIKE '1/2/%'` finds all descendants of category 2.
`WHERE '1/3/5' LIKE path_string || '%'` finds all ancestors of node 5.
PostgreSQL Ltree extension: `path_string ltree 'Electronics.Computers.*'`.
Benefits: simple queries, fast with GiST index. Costs: path must be
maintained on every write (update when reparenting), maximum path length
limit. Best for: read-heavy hierarchies with rare restructuring."

**Q6: What happens when a recursive CTE encounters a cycle in the data?**

🗣️ "Without cycle protection: the recursive member keeps matching rows
indefinitely (A -> B -> A -> B -> ...). The working table grows without bound.
PostgreSQL: eventually hits `max_recursion_depth` (default 1000) and errors:
'ERROR: infinite recursion detected in recursive query'.
Prevention: (1) depth limit: `WHERE r.depth < 100` in the recursive member.
Terminates at max depth. (2) Visited array: `ARRAY[id]` in anchor,
`path || c.id` in recursive, `WHERE NOT c.id = ANY(path)` prevents revisiting.
(3) PostgreSQL 14+: `CYCLE id SET is_cycle USING path` syntax adds cycle
detection automatically. For production data that might have cycles
(user-generated hierarchies): always add cycle detection."

**Q7: How do you paginate through a large recursive CTE result?**

🗣️ "Recursive CTEs cannot have LIMIT in the recursive member. But the
final query can have LIMIT and OFFSET. Caveat: the full recursive traversal
still runs; LIMIT only limits the output rows. For a tree with 1 million
nodes and LIMIT 50: all 1 million nodes are computed, then 50 are returned.
No performance benefit from LIMIT on the CTE output.
Optimization: (1) add WHERE filters in the anchor or recursive member to
limit the traversal scope (prune branches early); (2) use a starting node
with a small subtree; (3) for paginated UI: consider materializing the
full tree into a temp table, adding an index, then paginating from the
temp table. For recursive CTEs: the traversal cost is determined by the
data structure, not the LIMIT on the output."

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



