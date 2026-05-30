---
layout: default
title: "Database SQL - L1 Data Modification"
parent: "Database SQL"
grand_parent: "SK Interview"
nav_order: 4
permalink: /database-sql/l1-data-modification/
render_with_liquid: false
---

# INSERT, UPDATE, DELETE - Modifying Table Data

**TL;DR:** INSERT adds rows, UPDATE modifies rows, DELETE removes rows.
All three are transactional - they can be rolled back. The critical rule:
UPDATE and DELETE without a WHERE clause affect every row in the table.
Always verify with SELECT before executing bulk modifications.

---

### 🎯 Model Answer

**30 seconds:**
> INSERT adds rows to a table. UPDATE modifies existing rows (always
> include a WHERE clause or all rows are changed). DELETE removes rows
> (again, WHERE clause required). All three are transactional DML
> statements that can be wrapped in a transaction and rolled back.
> RETURNING (PostgreSQL) lets you get the affected rows back in one
> statement.

**3 minutes:**
> INSERT can insert a single row, multiple rows (VALUES with multiple
> tuples), or the result of a SELECT query (INSERT INTO ... SELECT ...).
> For bulk inserts: multi-row INSERT is much faster than individual
> INSERTs (one network round trip, one transaction, one index update
> per batch).
>
> UPDATE: always include a WHERE clause unless intentionally updating
> all rows. PostgreSQL and MySQL support `UPDATE ... FROM` (or `UPDATE ...
> JOIN` in MySQL) for updating based on another table's values.
> UPDATE in PostgreSQL with MVCC creates a new row version - the old
> version is kept as a dead tuple until VACUUM removes it.
>
> DELETE: removes rows physically. With foreign key `ON DELETE CASCADE`:
> cascades to child tables. An alternative to DELETE for archiving is
> soft delete: add a `deleted_at` column, UPDATE it instead of deleting,
> and filter on `deleted_at IS NULL` in queries.
>
> TRUNCATE: removes all rows faster than DELETE (no per-row logging,
> no row-level triggers). Cannot be rolled back in some databases
> (MySQL) but can be rolled back in PostgreSQL within a transaction.

**Blank Mind Recovery:**

**(1) Restate:** "INSERT adds, UPDATE modifies, DELETE removes. All
transactional. WHERE clause mandatory for UPDATE/DELETE to avoid
full-table modification."

**(2) First principles:** "Mutations change the database state. All
mutations are atomic (either all or nothing) and must maintain
consistency (constraints checked after each mutation)."

**(3) Bridge:** "Like editing a spreadsheet. INSERT = add a new row.
UPDATE = edit an existing cell. DELETE = remove a row. But unlike a
spreadsheet: every edit is reversible (ROLLBACK) and concurrent edits
are protected by locking."

---

### 📘 Concept Explanation

**INSERT forms:**

```sql
-- Single row
INSERT INTO table (col1, col2) VALUES (v1, v2);

-- Multiple rows (one round trip, much faster)
INSERT INTO table (col1, col2)
VALUES (v1, v2), (v3, v4), (v5, v6);

-- From SELECT (copy or transform)
INSERT INTO archive_orders
SELECT * FROM orders WHERE created_at < '2020-01-01';

-- UPSERT (insert or update if key exists)
-- PostgreSQL:
INSERT INTO users (email, name)
VALUES ('a@b.com', 'Alice')
ON CONFLICT (email)
DO UPDATE SET name = EXCLUDED.name, updated_at = now();

-- MySQL:
INSERT INTO users (email, name)
VALUES ('a@b.com', 'Alice')
ON DUPLICATE KEY UPDATE name = VALUES(name);
```

**UPDATE forms:**

```sql
-- Basic update with WHERE
UPDATE orders SET status = 'SHIPPED' WHERE id = 123;

-- Update multiple columns
UPDATE users
SET last_login = now(), login_count = login_count + 1
WHERE id = :user_id;

-- Update from another table (PostgreSQL)
UPDATE orders o
SET total_cents = i.computed_total
FROM order_totals i
WHERE i.order_id = o.id;
```

**DELETE vs TRUNCATE:**

- DELETE: row-by-row (slower), triggers fire, can have WHERE clause,
  can be rolled back, leaves table structure intact.
- TRUNCATE: bulk remove (faster, no per-row undo logging), no WHERE,
  triggers may or may not fire (database-dependent), resets identity
  sequences. In PostgreSQL: TRUNCATE can be rolled back within a transaction.

---

### 💻 Code Example

```sql
-- INSERT BEST PRACTICES

-- BAD: individual inserts in a loop (N round trips)
-- Application code:
-- for each product: INSERT INTO products VALUES (...)
-- 1000 products = 1000 network round trips

-- GOOD: multi-row insert (one round trip)
INSERT INTO products (name, price_cents, category_id)
VALUES
    ('Widget A', 999, 1),
    ('Widget B', 1499, 1),
    ('Gadget X', 2999, 2);
-- One round trip, one transaction, one index update pass.

-- UPSERT: insert or update if key conflicts
INSERT INTO user_settings (user_id, key, value)
VALUES (42, 'theme', 'dark')
ON CONFLICT (user_id, key)
DO UPDATE SET
    value      = EXCLUDED.value,
    updated_at = now();
-- If (user_id=42, key='theme') already exists: update it.
-- If not: insert it.
-- Atomic: no race condition between SELECT and INSERT.
```

> **Code walkthrough:** Multi-row INSERT is a fundamental performance
> optimization. A 1,000-row single-statement INSERT is 10-100x faster
> than 1,000 individual inserts because: one network round trip, one
> transaction overhead, and the database can batch index updates.
> UPSERT (`ON CONFLICT DO UPDATE`) solves the "insert or update" problem
> atomically. Without it: a `SELECT` to check if the row exists, then
> `INSERT` or `UPDATE` - this has a race condition (between SELECT and
> INSERT, another connection may insert the same key). UPSERT is atomic.

```sql
-- UPDATE: safe patterns

-- BAD: update without WHERE (affects ALL rows)
UPDATE orders SET status = 'CANCELLED';
-- Catastrophic: every order is now cancelled.

-- GOOD: always include WHERE
UPDATE orders
SET   status = 'CANCELLED', cancelled_at = now()
WHERE id = :order_id
  AND status IN ('PENDING', 'PLACED');
-- Only updates the specific order if it is in a
-- cancellable state. Idempotent: safe to retry.

-- VERIFY BEFORE BULK UPDATE (development discipline)
-- Run this SELECT first, confirm the rows, then run UPDATE:
SELECT id, status FROM orders
WHERE  created_at < '2020-01-01'
  AND  status = 'PENDING';
-- After confirming: replace SELECT with UPDATE SET:
UPDATE orders
SET   status = 'EXPIRED'
WHERE created_at < '2020-01-01'
  AND status = 'PENDING';
```

> **Code walkthrough:** The BAD `UPDATE orders SET status = 'CANCELLED'`
> has no WHERE - every row is affected. In production this is a
> catastrophic mistake. The safe discipline: write the SELECT version
> first to confirm which rows match, then replace `SELECT columns` with
> `UPDATE table SET ...` keeping the identical WHERE clause. The GOOD
> update also includes a state check (`AND status IN ('PENDING', 'PLACED')`)
> making it idempotent: running it twice will not cancel an order that
> was already shipped.

```sql
-- DELETE: safe patterns and alternatives

-- BAD: delete without WHERE
DELETE FROM sessions;  -- deletes ALL sessions

-- GOOD: delete with WHERE
DELETE FROM sessions
WHERE expires_at < now();  -- expired sessions only

-- SOFT DELETE: keep data, mark as deleted
ALTER TABLE orders ADD COLUMN deleted_at TIMESTAMPTZ;

-- Instead of DELETE:
UPDATE orders SET deleted_at = now() WHERE id = :id;

-- Query with soft delete filter:
SELECT * FROM orders WHERE deleted_at IS NULL;

-- RETURNING: get deleted rows back (PostgreSQL)
DELETE FROM expired_tokens
WHERE expires_at < now()
RETURNING token, user_id;
-- Returns the rows that were deleted for logging.
```

> **Code walkthrough:** Soft delete adds a `deleted_at` timestamp column.
> DELETE becomes an UPDATE. All queries add `WHERE deleted_at IS NULL`.
> Benefits: (1) data is retained for audit; (2) accidental deletes are
> recoverable (UPDATE deleted_at = NULL); (3) the deleted data is available
> for analytics. Cost: every query must include the `IS NULL` filter;
> add an index if the filter is on a large table. `RETURNING` (PostgreSQL)
> gets the affected rows in one statement - no need for a SELECT after
> DELETE/UPDATE to find the modified rows.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> INSERT adds rows, UPDATE modifies rows, DELETE removes rows. Always
> include a WHERE clause with UPDATE and DELETE. Verify with a SELECT
> first before running bulk modifications. Multi-row INSERT is faster
> than single-row INSERT in a loop. UPSERT (ON CONFLICT DO UPDATE in
> PostgreSQL) handles insert-or-update atomically.

---

**Senior / Staff:**
> Bulk DML operations have non-obvious side effects: UPDATE in PostgreSQL
> creates a new row version for every updated row (MVCC dead tuples);
> bulk updates on large tables generate substantial WAL, consume disk,
> and may trigger auto-vacuum. For large bulk operations (millions of
> rows): batch in chunks of 10,000-100,000 rows per transaction to avoid
> holding a large transaction that blocks VACUUM and replication.
> TRUNCATE is faster than DELETE for clearing a table but acquires an
> ACCESS EXCLUSIVE lock that blocks all other operations.

---

### ⚠️ Common Misconceptions

**"DELETE is safe to use for large tables"**

Reality: DELETE on millions of rows creates a large transaction that:
(1) holds row-level locks for the duration; (2) generates a large WAL
(one entry per deleted row); (3) in PostgreSQL, leaves dead tuples that
VACUUM must clean up. For bulk deletes: use batched DELETE with LIMIT,
or TRUNCATE if deleting all rows.

**"TRUNCATE and DELETE are equivalent"**

Reality: TRUNCATE resets identity sequences (PostgreSQL: unless RESTART
IDENTITY is omitted). DELETE does not. TRUNCATE cannot have a WHERE
clause. TRUNCATE fires statement-level triggers, not row-level triggers.
TRUNCATE acquires an ACCESS EXCLUSIVE lock (blocks reads). DELETE
acquires row-level locks.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Bulk UPDATE locks table and blocks application**

Symptom: UPDATE affecting millions of rows; application queries time out.

Diagnosis: the UPDATE holds row locks for its duration. Other queries
wait. Long-running transactions show in `pg_stat_activity`.

Fix: batch the update:
```sql
DO $$
DECLARE batch_size INT := 10000;
BEGIN
  LOOP
    UPDATE orders SET status = 'ARCHIVED'
    WHERE id IN (
        SELECT id FROM orders
        WHERE created_at < '2020-01-01'
        AND status != 'ARCHIVED'
        LIMIT 10000)
    AND status != 'ARCHIVED';
    EXIT WHEN NOT FOUND;
    PERFORM pg_sleep(0.1);  -- brief pause
  END LOOP;
END $$;
```

---

### 🎯 Interview Deep-Dive

**Q1: What is the difference between DELETE, TRUNCATE, and DROP?**

🗣️ "DELETE: removes rows matching a WHERE clause (or all rows if no WHERE).
Row-level transactional. Generates per-row WAL. Fires row-level triggers.
Table structure remains. TRUNCATE: removes all rows. Faster (no per-row
undo logging). No WHERE clause. Resets sequences. Fires statement-level
triggers. Table structure remains. In PostgreSQL: can be rolled back in
a transaction. DROP: removes the entire table definition and all its data.
Cannot be undone without restoring from backup. Use DELETE for conditional
removal, TRUNCATE for clearing a table entirely, DROP for removing a table."

**Q2: What is an UPSERT and how does it prevent race conditions?**

🗣️ "UPSERT is an atomic insert-or-update. Without UPSERT: application
checks if a row exists (SELECT), then INSERTs if not found. Between
the SELECT and INSERT, another connection may insert the same key -
duplicate key error. UPSERT handles this atomically: the database
acquires a lock on the potential key position, inserts if not present,
updates if present. `INSERT ON CONFLICT DO UPDATE` in PostgreSQL.
`INSERT ON DUPLICATE KEY UPDATE` in MySQL. Use UPSERT for idempotent
operations: creating or updating user settings, caching computed values,
maintaining counters."

**Q3: How does MVCC affect UPDATE performance in PostgreSQL?**

🗣️ "PostgreSQL MVCC implements UPDATE as: (1) mark the old row version
as dead (set xmax to current transaction ID); (2) insert a new row version
with the updated values. Both versions coexist. Concurrent readers see
the old version. After the update commits: the new version is visible.
The old version (dead tuple) stays until VACUUM removes it. Impact:
frequently updated rows accumulate dead tuples. Table bloat. VACUUM
reclaims space. `HOT updates` (Heap-Only Tuple) are an optimization:
if the update does not change any indexed column, the new version stays
on the same heap page and the index is not updated - much faster."

**Q4: What is the RETURNING clause and when should you use it?**

🗣️ "RETURNING (PostgreSQL, also in SQL:2003) returns the affected rows
from INSERT, UPDATE, or DELETE. `INSERT INTO orders ... RETURNING id`
returns the auto-generated ID. `UPDATE orders SET status = 'SHIPPED'
WHERE id = ? RETURNING id, status, updated_at` returns the updated row.
Use when: (1) you need the auto-generated ID after INSERT (avoids a
separate SELECT); (2) you want to confirm what was updated/deleted;
(3) you want to log or process the affected rows in one round trip.
Without RETURNING: `INSERT` + `SELECT LASTVAL()` is two round trips
and not concurrency-safe for all scenarios."

**Q5: How do you safely run a large UPDATE in production without downtime?**

🗣️ "Four steps: (1) Test on a dev/staging database first with representative
data volume. (2) Run as a SELECT first: `SELECT COUNT(*) WHERE condition`
to understand the scope. (3) Batch the update: `UPDATE ... WHERE id IN
(SELECT id ... LIMIT 10000)` in a loop with a brief pause between batches.
This keeps each transaction small, releases locks between batches, and
allows VACUUM to run. (4) Monitor `pg_stat_activity` during execution for
blocking queries. For schema changes (ALTER TABLE): use tools like
pt-online-schema-change (MySQL) or pg_repack (PostgreSQL) that build the
new table structure online and swap atomically."

**Q6: What is a soft delete and what are the trade-offs?**

🗣️ "Soft delete: add a `deleted_at TIMESTAMPTZ` column. Deletion becomes
`UPDATE ... SET deleted_at = now()`. All queries filter on `WHERE deleted_at IS NULL`.
Benefits: data is retained for audit and recovery, accidental deletes are
reversible. Costs: (1) every query must include the IS NULL filter -
easy to forget, partial indexes help; (2) the table grows without bound
(deleted rows accumulate); (3) unique constraints no longer work correctly
(deleted rows still occupy the unique value space). Alternatives: move
deleted rows to an archive table; use a boolean `is_deleted` flag
(same problem but simpler). Soft delete is widely used but requires
discipline to maintain correctly."

**Q7: How does DELETE with JOIN work and when do you need it?**

🗣️ "PostgreSQL: `DELETE FROM table USING other_table WHERE condition`.
MySQL: `DELETE table FROM table JOIN other_table WHERE condition`.
Use when: deleting rows from one table based on a condition in another table.
Example: delete all orders for customers in a specific region.
`DELETE FROM orders o USING customers c
WHERE o.customer_id = c.id AND c.region = 'EU'`.
Without DELETE FROM/USING: you must first SELECT the matching IDs,
then DELETE WHERE id IN (...). The DELETE JOIN approach is a single
statement, atomic, and lets the optimizer choose the join strategy.
For large deletes: use the batched approach with the join in the subquery."

---

# Tables and Schemas - Organizing Data Structures

**TL;DR:** Tables are the primary storage unit in a relational database.
Schemas (namespaces) group tables logically. A well-designed table has
a clear primary key, appropriate data types, necessary constraints,
and indexes. Table design decisions have long-term consequences for
query performance and maintainability.

---

### 🎯 Model Answer

**30 seconds:**
> A table stores rows of the same entity type. Columns define the schema
> (structure) of each row. Schemas (namespaces) group tables - like
> packages in code. Table design decisions: choose the right primary key
> (surrogate vs. natural), select appropriate data types (no storing numbers
> as strings), add NOT NULL and CHECK constraints, and create indexes
> on columns that will be searched or joined.

**3 minutes:**
> Table creation involves several decisions: (1) Primary key: surrogate
> (`BIGINT GENERATED ALWAYS AS IDENTITY`) for most entities; natural key
> for reference tables (ISO country codes). (2) Data types: use the
> right type - `TIMESTAMPTZ` for timestamps (stores UTC, displays in
> local timezone), `DECIMAL` for money (never `FLOAT` - binary float
> precision errors), `TEXT` or `VARCHAR(n)` for strings (`TEXT` is fine
> in PostgreSQL; `VARCHAR(255)` is a MySQL holdover that has no performance
> difference in PostgreSQL).
>
> Constraints: `NOT NULL` is the most impactful - it prevents NULL from
> creeping into columns that should never be null. `UNIQUE` prevents
> duplicate values. `CHECK` enforces valid value ranges. `FOREIGN KEY`
> enforces referential integrity. Add all constraints you can justify -
> they are the database's defense against invalid data.
>
> Schemas (in PostgreSQL/SQL Server): logical namespaces for tables.
> `public.users`, `analytics.user_events`, `billing.invoices`. Benefits:
> organization, access control (GRANT on schema), name collision avoidance.
> In MySQL: "schema" and "database" are synonyms.

**Blank Mind Recovery:**

**(1) Restate:** "Tables: rows of same entity. Columns define structure.
Schemas: namespaces. Good design: right PK, data types, constraints, indexes."

**(2) First principles:** "A table is a set of tuples with the same schema.
Design defines what is valid. Constraints enforce validity at write time."

**(3) Bridge:** "Like designing a form. Each field has a type (date picker,
not free text for dates), required/optional (NOT NULL), valid values
(CHECK constraint on status), and a unique ID (primary key). The form's
schema ensures all submitted data is usable."

---

### 📘 Concept Explanation

**Data type choices:**

```
Integers:
  SMALLINT (2 bytes, -32768 to 32767) - flags, tiny ranges
  INTEGER  (4 bytes, -2B to 2B)       - most IDs, counts
  BIGINT   (8 bytes, very large)       - high-volume IDs

Decimals:
  DECIMAL(p,s) / NUMERIC(p,s) - exact, for money
  FLOAT / DOUBLE PRECISION    - inexact, for science
  NEVER use FLOAT for money (0.1 + 0.2 != 0.3)

Strings:
  VARCHAR(n)  - variable length, up to n chars
  TEXT        - variable length, unlimited
  CHAR(n)     - fixed length, padded (rarely useful)

Dates/Times:
  DATE           - date only (2024-01-15)
  TIME           - time only (14:30:00)
  TIMESTAMP      - local datetime (no timezone)
  TIMESTAMPTZ    - UTC-stored, timezone-aware (preferred)
  INTERVAL       - duration ('3 days', '1 hour 30 minutes')

Boolean:
  BOOLEAN        - true/false (PostgreSQL native)
  TINYINT(1)     - MySQL boolean (0=false, 1=true)

JSON:
  JSON   - stored as text, validated on insert
  JSONB  - stored as binary, indexable (PostgreSQL)
```

**Schema organization:**

```sql
-- PostgreSQL schema namespacing
CREATE SCHEMA app;
CREATE SCHEMA analytics;
CREATE SCHEMA billing;

CREATE TABLE app.users (...);
CREATE TABLE analytics.page_views (...);
CREATE TABLE billing.invoices (...);

-- Grant schema access
GRANT USAGE ON SCHEMA analytics TO reporting_user;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics
    TO reporting_user;
```

---

### 💻 Code Example

```sql
-- TABLE DESIGN: getting it right

-- BAD: poor data type choices
CREATE TABLE orders_bad (
    id       VARCHAR(36),       -- UUID as string (slow)
    amount   FLOAT,             -- money as float (wrong)
    order_dt VARCHAR(20),       -- date as string (wrong)
    active   INTEGER,           -- boolean as int
    status   VARCHAR(255)       -- no constraint on values
);
-- Problems:
-- UUID comparisons on VARCHAR: slow (no byte comparison)
-- amount = 0.1 + 0.2 = 0.30000000000000004 (float error)
-- order_dt = '01/15/2024' can't be compared or indexed as date
-- active = 2 is allowed (should be 0 or 1 only)
-- status = 'INVALID_STATUS' is allowed (no check constraint)

-- GOOD: proper data types and constraints
CREATE TABLE orders (
    id          UUID
        PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id BIGINT NOT NULL
        REFERENCES customers(id),
    amount_cents INTEGER NOT NULL
        CHECK (amount_cents > 0),    -- money as integer cents
    order_date  DATE NOT NULL,       -- proper date type
    status      VARCHAR(20) NOT NULL
        CHECK (status IN (
            'PENDING','PLACED','SHIPPED',
            'DELIVERED','CANCELLED')),
    is_gift     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_customer_id
    ON orders(customer_id);
CREATE INDEX idx_orders_status_created
    ON orders(status, created_at DESC);
```

> **Code walkthrough:** The BAD table uses FLOAT for money (binary float
> precision errors make `0.1 + 0.2 = 0.30000000000000004`), VARCHAR for
> dates (cannot ORDER BY, cannot use date functions), and integers for
> booleans. The GOOD table: `amount_cents` stores money as integer cents
> (no floating point, exact arithmetic), `DATE` for dates (supports
> date arithmetic, range comparisons), `BOOLEAN` for flags, `TIMESTAMPTZ`
> for timestamps (UTC storage, automatic timezone conversion on display),
> and a `CHECK` constraint on `status` to restrict to valid values.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Tables store rows of the same entity. Each column has a data type:
> use INTEGER for IDs, DECIMAL or integer cents for money (never FLOAT),
> DATE/TIMESTAMPTZ for dates, BOOLEAN for flags. Add NOT NULL on columns
> that should never be null. Add CHECK constraints for valid value ranges.
> Add FOREIGN KEY for relationships. Create indexes on columns used in
> WHERE and JOIN clauses.

---

**Senior / Staff:**
> The most impactful table design decisions: (1) money as integer cents
> (BIGINT or INTEGER) - avoids all floating point issues;
> (2) TIMESTAMPTZ over TIMESTAMP (without timezone) - TIMESTAMPTZ
> stores UTC and converts on display; TIMESTAMP stores local time and
> is ambiguous across daylight saving changes; (3) NOT NULL by default -
> add NOT NULL to every column unless NULL is semantically meaningful;
> (4) CHECK constraints on status/type columns - the database enforces
> valid values; the application cannot bypass them.

---

### ⚠️ Common Misconceptions

**"VARCHAR(255) is more efficient than TEXT"**

Reality: in PostgreSQL, TEXT and VARCHAR(n) have identical storage
and performance. VARCHAR(255) is a MySQL habit that became cargo-cult
in PostgreSQL usage. In PostgreSQL: use TEXT for unlimited strings.
Use VARCHAR(n) only when you genuinely need to enforce a maximum length.

**"FLOAT is fine for financial amounts"**

Reality: IEEE 754 binary float cannot represent most decimal fractions
exactly. `0.1` stored as FLOAT becomes `0.10000000000000001`.
Summing thousands of such values accumulates error. For financial data:
use `NUMERIC(precision, scale)` (exact decimal arithmetic) or store
amounts as integer cents (`amount_cents BIGINT`).

---

### 🚨 Failure Modes and Diagnosis

**Failure: TIMESTAMP without timezone causes DST ambiguity**

Symptom: application shows wrong times near daylight saving change.
"2024-11-03 01:30:00" occurs twice (before and after DST end).

Diagnosis: column is `TIMESTAMP` (no timezone). Application stores
local time, which is ambiguous.

Fix: use `TIMESTAMPTZ`. The database stores UTC. The application
displays in local timezone. UTC has no DST ambiguity.

---

### 🎯 Interview Deep-Dive

**Q1: What is the difference between VARCHAR and TEXT in PostgreSQL?**

🗣️ "In PostgreSQL: identical. Both store variable-length character data.
Both use the same TOAST mechanism for large values (> 2KB). VARCHAR(n)
adds a length check (rejected if the value exceeds n characters).
TEXT has no length limit. Performance: identical. Storage: identical
(variable-length header + actual data, no padding). Use TEXT unless
you specifically need to enforce a maximum length. VARCHAR(255) is a
MySQL convention; it adds nothing in PostgreSQL."

**Q2: Why should you never store money as a FLOAT?**

🗣️ "FLOAT uses IEEE 754 binary floating point. Binary fractions cannot
represent most decimal fractions exactly. `1.10` in binary float is
approximately `1.0999999999999999`. Summing floats: `100 * 1.10 = 109.99999...`
instead of `110.00`. For financial amounts: two options.
(1) NUMERIC(precision, scale): exact decimal arithmetic. Slower than
float for math-heavy operations. `NUMERIC(12, 2)` for amounts up to
9,999,999,999.99. (2) Integer cents: store as BIGINT cents
(`price_cents BIGINT`). All arithmetic is exact integer arithmetic.
Convert to dollars for display (`price_cents / 100.0`). Preferred in
high-volume financial systems."

**Q3: What is table partitioning and when should you use it?**

🗣️ "Partitioning: divide a large table into smaller physical segments
(partitions) based on a column's value range (range partitioning),
list of values (list partitioning), or hash (hash partitioning).
Benefits: (1) partition pruning - a query on `WHERE created_at >= '2024-01-01'`
only scans the 2024 partition, not all years; (2) partition maintenance -
drop the oldest partition to archive data (instant, no row-by-row delete);
(3) parallel scan across partitions. Use when: a table exceeds 50-100GB
and most queries filter on the partition key. Overhead: more complex
queries (cross-partition joins), FK constraints from partitioned tables
are limited."

**Q4: What are generated columns and when are they useful?**

🗣️ "Generated columns (PostgreSQL 12+, MySQL 5.7+): a column whose value
is automatically computed from other columns. Two types: (1) virtual
(computed on read, no storage) and (2) stored (computed on write,
stored on disk). Use for: derived values that are frequently queried
(full name = first_name || ' ' || last_name), coordinates computed
from lat/lon (for PostGIS indexing), computed prices
(net_price = list_price * (1 - discount)). Benefits: always consistent
(computed by the database, not the application), indexable (stored
generated columns can be indexed), eliminates application-side redundancy."

**Q5: What is a table's physical storage structure?**

🗣️ "In PostgreSQL: a table is a heap file. A heap is an unordered
collection of 8KB pages. Each page contains a header, item pointers,
and row data. Rows are stored in the order they were inserted (or
updated, since MVCC creates new versions). For a brand new table with
sequential inserts: rows are physically adjacent. After updates and
deletes: pages have gaps (dead tuples). No clustering by default.
A clustered table (Oracle/SQL Server) stores rows in primary key order.
PostgreSQL: CLUSTER command reorganizes a table by an index but does
not maintain the order on subsequent writes."

**Q6: How do you handle schema changes on large production tables?**

🗣️ "ALTER TABLE in PostgreSQL: some changes are instant (add a nullable
column, add a constraint as NOT VALID), some require a full table rewrite
(add NOT NULL to an existing column, change column type). Table rewrite
on a 100M-row table: minutes to hours, locks the table. Strategies:
(1) add a nullable column with a default, backfill in batches, then
add NOT NULL; (2) use pg_repack for online reordering without table locks;
(3) for index additions: `CREATE INDEX CONCURRENTLY` - builds the index
without locking writes, takes longer but is online.
Zero-downtime schema changes require planning and tooling."

**Q7: What is a schema version and why is it important?**

🗣️ "A schema version (migration version) is a sequential identifier for
each database schema change. Tools: Flyway, Liquibase (Java), Alembic
(Python), db-migrate (Node). Each schema change is a versioned migration
file. The tool tracks which migrations have been applied (in a migrations
table). On deploy: the tool runs pending migrations in order.
Benefits: the database schema is version-controlled alongside the code;
teams can reproduce the exact schema state for any commit; rollback is
a reverse migration. In production: migrations should be backward-
compatible (the old code version runs against the new schema)."

---

# Data Types - Choosing Correct Column Types

**TL;DR:** Choosing the right data type for each column is one of the
most impactful design decisions. The wrong type causes precision errors
(FLOAT for money), storage waste (VARCHAR(MAX) for short strings),
or prevents index use (VARCHAR for numeric IDs). The right type
enforces validity, enables efficient storage, and supports correct
arithmetic and comparisons.

---

### 🎯 Model Answer

**30 seconds:**
> Data type selection: use the most specific type that correctly represents
> the data. Integers for counts and IDs, DECIMAL/integer cents for money
> (never FLOAT), DATE/TIMESTAMPTZ for dates, BOOLEAN for flags.
> The wrong type causes bugs (float precision), wastes storage, or
> prevents the database from using indexes efficiently.

**3 minutes:**
> The most common type mistakes: (1) FLOAT for money - binary float cannot
> represent most decimal fractions exactly, causing rounding errors.
> Use NUMERIC(p,s) or integer cents. (2) VARCHAR for numeric IDs -
> `ORDER BY id` on a VARCHAR column sorts lexicographically ('10' < '9').
> Use BIGINT for IDs. (3) TIMESTAMP without timezone - stores local time
> which is ambiguous across DST changes. Use TIMESTAMPTZ. (4) Storing
> enum-like values as VARCHAR without constraints - allows arbitrary
> strings. Use CHECK constraints or a separate lookup table.
>
> Type choice also affects storage: `SMALLINT` (2 bytes) vs `INTEGER`
> (4 bytes) vs `BIGINT` (8 bytes). For a table with 1 billion rows:
> the difference between SMALLINT and BIGINT columns is 6GB. For
> low-cardinality status columns: `SMALLINT` (0-32767) is sufficient.
> For primary keys: `BIGINT` is safer than `INTEGER` (2 billion row limit).

**Blank Mind Recovery:**

**(1) Restate:** "Right type = correctness + efficiency. Money: integer
cents or NUMERIC. Dates: TIMESTAMPTZ. Booleans: BOOLEAN. IDs: BIGINT."

**(2) First principles:** "A type defines the set of valid values and
the operations on them. The correct type is the one that exactly models
the domain's value set and supports the required operations."

**(3) Bridge:** "Like measuring cups in a kitchen. Using a tablespoon
to measure liters: wrong unit (type mismatch), causes errors. Using
the exact right measuring tool (the right data type) ensures accurate
operations."

---

### 📘 Concept Explanation

**Type selection quick reference:**

```
Entity IDs:         BIGINT (safe to 9.2 * 10^18 rows)
                    UUID (universally unique, distributed inserts)
Counts/Scores:      INTEGER (up to 2.1 billion)
Small flags/codes:  SMALLINT (up to 32767)
Money:              BIGINT cents OR NUMERIC(12,2)
Percentages:        NUMERIC(5,2) (0.00 to 999.99)
Text (unlimited):   TEXT (PostgreSQL)
Text (bounded):     VARCHAR(n) only when max length matters
Short codes:        CHAR(2) for fixed-length codes (ISO country)
Dates only:         DATE
Time only:          TIME
Datetime:           TIMESTAMPTZ (always, over TIMESTAMP)
Durations:          INTERVAL
Boolean flags:      BOOLEAN (never TINYINT or VARCHAR)
Binary data:        BYTEA (files -> store path, not file itself)
JSON (indexed):     JSONB (PostgreSQL)
Enums:              CHECK constraint OR lookup table
```

**UUID vs BIGINT as primary key:**

```
BIGINT (auto-increment):
  + Smallest (8 bytes)
  + Sequential (good B-tree insert performance)
  + Human-readable in debugging
  - Single point of generation (no distributed insert)
  - Predictable (security concern for guessable IDs)

UUID (random v4):
  + Globally unique (safe for distributed systems)
  + Unpredictable (safe for external IDs)
  - 16 bytes (2x BIGINT)
  - Random inserts cause B-tree page splits (fragmentation)
  - Less human-readable

UUIDv7 (time-ordered):
  + Sequential (like BIGINT for B-tree performance)
  + Globally unique
  + Sortable by generation time
  - 16 bytes
  - Relatively new (not in all UUID libraries yet)
```

---

### 💻 Code Example

```sql
-- MONEY TYPES: the definitive example

-- BAD: float money (precision errors)
CREATE TABLE invoices_bad (
    amount FLOAT  -- binary float, precision errors
);
INSERT INTO invoices_bad VALUES (0.1), (0.2);
SELECT SUM(amount) FROM invoices_bad;
-- Result: 0.30000000000000004  (wrong!)

-- GOOD option 1: NUMERIC (exact decimal)
CREATE TABLE invoices_numeric (
    amount NUMERIC(12, 2)  -- up to 9,999,999,999.99
);
INSERT INTO invoices_numeric VALUES (0.10), (0.20);
SELECT SUM(amount) FROM invoices_numeric;
-- Result: 0.30  (correct)

-- GOOD option 2: integer cents (preferred for high volume)
CREATE TABLE invoices_cents (
    amount_cents BIGINT  -- store as cents (integer)
);
INSERT INTO invoices_cents VALUES (10), (20);
SELECT SUM(amount_cents) / 100.0 AS amount
FROM invoices_cents;
-- Result: 0.30  (correct, exact integer arithmetic)
```

> **Code walkthrough:** The FLOAT table demonstrates the binary float
> precision problem: `0.1 + 0.2 = 0.30000000000000004`. Even one cent
> of error can cause financial discrepancies in high-volume systems.
> NUMERIC uses exact decimal arithmetic internally - stored as a
> sequence of digits. Integer cents is the most common enterprise
> approach: store `1050` for `$10.50`, display as `amount_cents / 100.0`.
> Integer arithmetic is always exact. No precision configuration needed.

```sql
-- DATETIME TYPES: the TIMESTAMPTZ vs TIMESTAMP decision

-- BAD: TIMESTAMP without timezone
CREATE TABLE events_bad (
    occurred_at TIMESTAMP  -- local time, ambiguous
);
-- Stores '2024-11-03 01:30:00' - is this before or
-- after DST ends? Ambiguous. Cannot be converted correctly.

-- GOOD: TIMESTAMPTZ (always use this)
CREATE TABLE events_good (
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Stores UTC internally. Displays in session timezone.
-- '2024-11-03 01:30:00-05:00' - unambiguous.

-- COMPARING DATES AND TIMESTAMPS
SELECT *
FROM orders
WHERE created_at >= '2024-01-01'::TIMESTAMPTZ
  AND created_at <  '2024-02-01'::TIMESTAMPTZ;
-- Cast the literal to TIMESTAMPTZ to avoid implicit
-- conversion ambiguity.

-- EXTRACTING DATE PARTS
SELECT
    id,
    DATE(created_at AT TIME ZONE 'America/New_York')
        AS local_date,
    EXTRACT(HOUR FROM created_at AT TIME ZONE 'UTC')
        AS hour_utc
FROM orders;
```

> **Code walkthrough:** `TIMESTAMPTZ` (Timestamp With Time Zone) stores
> the moment in UTC, regardless of the session's timezone. When reading:
> the database converts UTC to the session's timezone. `TIMESTAMP` (without
> timezone) stores exactly what you give it with no timezone conversion.
> This means `TIMESTAMP` values near a DST transition are ambiguous:
> `2024-11-03 01:30:00` could be either 1:30 AM before DST ends (UTC-4)
> or 1:30 AM after DST ends (UTC-5). Always use `TIMESTAMPTZ`. The UTC
> storage makes all arithmetic correct and all comparisons unambiguous.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Use BIGINT for primary keys, NUMERIC or integer cents for money (never
> FLOAT), TIMESTAMPTZ for dates and times, BOOLEAN for true/false, TEXT
> for strings (or VARCHAR(n) when you need a length limit). The most
> common mistakes: using FLOAT for money (precision errors), using VARCHAR
> for numeric IDs (sorts wrong), and using TIMESTAMP instead of TIMESTAMPTZ
> (DST ambiguity).

---

**Senior / Staff:**
> The type decision has production consequences. FLOAT for money in a
> financial system: ledger discrepancies discovered months later.
> TIMESTAMP without timezone: DST-related bugs in appointment scheduling.
> VARCHAR for IDs: sorting bugs in reports. The right types make these
> entire classes of bugs impossible. When reviewing schemas: always check
> money columns (must be NUMERIC or integer), datetime columns (must be
> TIMESTAMPTZ), and ID columns (must be numeric or UUID, never VARCHAR).

---

### ⚠️ Common Misconceptions

**"UUID primary keys are always better than BIGINT"**

Reality: Random UUID v4 primary keys cause B-tree index fragmentation
because new UUIDs are inserted at random positions in the B-tree.
For high-insert-rate tables: this causes page splits and index bloat.
BIGINT auto-increment keys are always inserted at the right end of
the B-tree (monotonically increasing) - optimal for insert performance.
UUIDv7 (time-ordered) has BIGINT-like insert performance with UUID
uniqueness benefits.

**"Storing amounts as DECIMAL(19,4) is always safe for money"**

Reality: DECIMAL is exact decimal arithmetic - no precision errors.
But DECIMAL operations are slower than integer operations. For extremely
high-volume financial systems (millions of transactions per second):
integer cents (BIGINT) is faster because integer arithmetic is native
CPU instruction-level. DECIMAL requires software decimal arithmetic.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Lexicographic sort on VARCHAR ID column**

Symptom: `ORDER BY id` on a VARCHAR ID produces 1, 10, 100, 2, 20, 200.

Diagnosis: ID column is VARCHAR. Lexicographic sort.

Fix: migrate column to BIGINT or UUID. In the interim:
`ORDER BY CAST(id AS BIGINT)`.

**Failure: Float equality comparison always fails**

```sql
-- BAD: float equality (almost always wrong)
WHERE amount = 10.50  -- may never match if stored as float

-- FIX: use NUMERIC or integer, or range for float
WHERE ABS(amount - 10.50) < 0.001  -- float range check
-- Better: migrate to NUMERIC or integer cents
```

---

### 🎯 Interview Deep-Dive

**Q1: Why is TIMESTAMPTZ preferred over TIMESTAMP in PostgreSQL?**

🗣️ "TIMESTAMPTZ (with timezone) stores the absolute moment in time as
UTC. When reading: the session timezone converts UTC to local. TIMESTAMP
(without timezone) stores exactly what you insert with no conversion.
Problems with TIMESTAMP: (1) daylight saving ambiguity - '2024-11-03 01:30:00'
occurs twice; (2) no timezone context - you cannot convert to another
timezone correctly; (3) comparing timestamps from two different timezones
is wrong (both appear as numbers, but they represent different moments).
TIMESTAMPTZ eliminates all these: every value is unambiguously UTC.
Use TIMESTAMPTZ for all datetime columns."

**Q2: What is the SERIAL type and should you use it in new PostgreSQL schemas?**

🗣️ "SERIAL is a shorthand: `id SERIAL` is equivalent to creating an INTEGER
column and a sequence, with the sequence as the default value. `BIGSERIAL`
does the same for BIGINT. Issues: SERIAL is not the SQL standard. The
sequence is created as a side effect and is not directly tied to the column
in the same way as `GENERATED ALWAYS AS IDENTITY`. In new schemas:
use `BIGINT GENERATED ALWAYS AS IDENTITY` - this is the SQL standard
syntax, prevents manual inserts to the identity column (ALWAYS), and
makes the intent explicit. In existing schemas: SERIAL continues to work
fine."

**Q3: When should you use JSONB vs. individual columns?**

🗣️ "Individual columns when: the fields are known at design time, queried
or filtered frequently (need indexes), or have relational integrity requirements.
JSONB when: the attributes vary per row (user profile with arbitrary metadata),
the schema is rapidly evolving (no migration for each new field), the data
is consumed by the application as a whole (no need to query individual fields).
JSONB in PostgreSQL is indexable (GIN index on all keys), supports containment
operators (@>), and can be queried with `->` and `->>` operators. Hybrid:
core fields as columns, metadata as JSONB. This gives you the best of
both worlds - fast indexed queries on core fields, flexible storage for
variable metadata."

**Q4: What is the N+1 problem with ENUM types?**

🗣️ "Most databases have a native ENUM type. PostgreSQL `CREATE TYPE status AS ENUM ('pending', 'active', 'archived')`.
Problem: adding a new ENUM value is a schema change (ALTER TYPE ... ADD VALUE).
In PostgreSQL 9.1+: adding a value is fast (no table rewrite). But in
earlier versions: it required a full table rewrite. More importantly:
the valid values are part of the database type definition, not application
code. Keeping them in sync is an operational burden. Alternative: VARCHAR
with a CHECK constraint - adding a new value requires only a constraint
change. Or: a lookup table with a FK reference (most flexible, allows
adding metadata to each status). For simple, stable value sets: ENUM
is fine. For frequently-changing value sets: CHECK constraint or lookup table."

**Q5: How do binary data types work and when should you store files in a DB?**

🗣️ "PostgreSQL `BYTEA` stores binary data. MySQL `BLOB`. Both store arbitrary
bytes. Storage limits: PostgreSQL BYTEA: up to 1GB per value (via TOAST).
Should you store files in the database? Rarely. For small, metadata-heavy
blobs (thumbnails, certificates, PDFs that need transactional consistency
with the row): yes - they are backed up with the database, no separate
storage service needed. For large files (images, videos, attachments):
no - store in object storage (S3, GCS), store only the path/URL in the
database. Reasons: databases are expensive storage (disk + memory);
large BLOBs slow backup/restore; object storage is designed for large files."

**Q6: What are domain types and when are they useful?**

🗣️ "A domain (PostgreSQL) is a named type based on an existing type with
additional constraints: `CREATE DOMAIN email AS VARCHAR(255) CHECK (VALUE ~ '^.+@.+$')`.
Columns declared as `email` type enforce the email format constraint automatically.
Benefits: (1) reusable validation - define the email constraint once, apply
to any column; (2) self-documenting - `email` tells you the purpose.
Compared to CHECK constraints on individual columns: domain is centralized.
Adding a new check for emails: alter the domain once, all email columns
get the constraint. Use for: email, phone number, positive integer, money,
URL - any column type with application-wide validation rules."

**Q7: How does column ordering in a table affect storage efficiency?**

🗣️ "In PostgreSQL: tables are heap files, and rows are stored sequentially.
NULL values in variable-length columns take only 1-2 bytes in the column
header (NULL bitmap). FIXED-LENGTH columns (INTEGER, BIGINT, BOOLEAN)
can be packed tightly. In practice: column ordering affects alignment padding.
An INTEGER (4 bytes) after a BIGINT (8 bytes) may have 4 bytes of padding
in some database engines. PostgreSQL handles alignment internally but
column ordering can matter for wide tables with many small columns.
The practical advice: put NOT NULL fixed-length columns first, nullable
and variable-length columns last. This is a micro-optimization - correctness
and index design matter far more."
