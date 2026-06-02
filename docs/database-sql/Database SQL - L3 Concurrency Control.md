---
layout: default
title: "Database SQL - L3 Concurrency Control"
parent: "Database SQL"
grand_parent: "SK Interview"
nav_order: 12
permalink: /database-sql/l3-concurrency-control/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Transaction Isolation Levels - Read Phenomena and Trade-offs](#transaction-isolation-levels---read-phenomena-and-trade-offs) | medium |
| 2 | [Optimistic vs Pessimistic Locking](#optimistic-vs-pessimistic-locking) | medium |

---

# Transaction Isolation Levels - Read Phenomena and Trade-offs

**TL;DR:** SQL defines four isolation levels (Read Uncommitted, Read Committed,
Repeatable Read, Serializable) that prevent three read anomalies (dirty reads,
non-repeatable reads, phantom reads). Higher isolation = fewer anomalies + more
contention. PostgreSQL default: Read Committed. Serializable prevents all anomalies
using snapshot isolation (SSI) with low lock overhead.

---

### 🎯 Model Answer

**30 seconds:**
> Four isolation levels prevent three read phenomena. Read Committed (default in
> PostgreSQL): prevents dirty reads. Repeatable Read: also prevents non-repeatable
> reads. Serializable: prevents phantom reads too - every transaction sees a
> consistent snapshot as if transactions executed serially. Higher isolation
> reduces anomalies but increases contention or serialization failures.

**3 minutes:**
> The three read phenomena:
> (1) Dirty read: transaction A reads uncommitted changes from transaction B.
> If B rolls back: A read data that never existed. Prevented by Read Committed.
> (2) Non-repeatable read: transaction A reads a row, transaction B updates
> and commits it, transaction A re-reads the same row and gets a different value.
> Prevented by Repeatable Read.
> (3) Phantom read: transaction A executes a range query (COUNT(*) WHERE amount > 100),
> transaction B inserts a new row matching that range and commits, transaction A
> re-executes the same range query and gets a different count (a "phantom" row appeared).
> Prevented by Serializable.
>
> PostgreSQL implementation: Read Committed uses per-statement snapshots.
> Repeatable Read and Serializable use per-transaction snapshots (MVCC).
> Serializable uses SSI (Serializable Snapshot Isolation) - tracks read-write
> dependencies and aborts transactions that would create a cycle.

**Blank Mind Recovery:**

**(1) Restate:** "4 levels: Read Uncommitted, Read Committed, Repeatable Read,
Serializable. 3 phenomena: dirty read, non-repeatable read, phantom read.
Higher level prevents more. Default: Read Committed."

**(2) First principles:** "Isolation: concurrent transactions should not interfere.
Perfect isolation (Serializable) is expensive. Lower levels allow some interference
for better concurrency."

**(3) Bridge:** "Like a shared Google Doc. (1) Dirty read: see someone's unsaved
typing. (2) Non-repeatable read: you refresh and the paragraph you just read changed.
(3) Phantom read: you counted 5 paragraphs, someone added one, now 6.
Serializable: you work on a snapshot - no interference visible."

---

### 📘 Concept Explanation

**Isolation level matrix:**

```
Level              Dirty  Non-Rep  Phantom
                   Read   Read     Read
----------------------------------------------
Read Uncommitted    YES    YES      YES  (no prevention)
Read Committed       no    YES      YES  (default PG)
Repeatable Read      no     no      YES  (PG: no phantom)
Serializable         no     no       no  (full isolation)

YES = phenomenon CAN occur at this level
no  = phenomenon is PREVENTED at this level

PostgreSQL note: Repeatable Read in PG also prevents
phantom reads (MVCC snapshot covers the full transaction).
```

> **Code walkthrough:** This Read Phenomena and Trade-offs example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**PostgreSQL-specific behavior:**

```
Read Committed (default):
  - Each statement sees data committed before the
    statement started (per-statement snapshot).
  - Most common. Good for most OLTP workloads.
  - Can have non-repeatable reads within a transaction.

Repeatable Read:
  - Transaction sees data committed before the
    transaction started (per-transaction snapshot).
  - Re-reading the same row always returns the same data.
  - In PostgreSQL: also prevents phantom reads
    (MVCC snapshot is consistent for the whole TX).

Serializable (SSI):
  - All transactions behave as if executed one at a time.
  - Uses Serializable Snapshot Isolation (no lock escalation).
  - Conflict detected -> transaction aborted with:
    ERROR: could not serialize access due to read/write dependencies
  - Application must retry serialization failures.
```

> **Code walkthrough:** This Read Phenomena and Trade-offs example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

```sql
-- DEMONSTRATION: Read Committed non-repeatable read

-- Session 1 (transaction A):
BEGIN;
SELECT balance FROM accounts WHERE id = 1;
-- Returns: 1000

-- Session 2 (transaction B) - concurrent:
UPDATE accounts SET balance = 500 WHERE id = 1;
COMMIT;  -- B commits

-- Session 1 (transaction A) continued:
SELECT balance FROM accounts WHERE id = 1;
-- Returns: 500  <-- non-repeatable read!
-- The same row returned a different value within the
-- same transaction (Read Committed allows this).
COMMIT;

-- FIX: use Repeatable Read for this transaction
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE id = 1;
-- Returns: 1000

-- Session 2 updates and commits (same as above)

SELECT balance FROM accounts WHERE id = 1;
-- Returns: 1000  <-- same as before (snapshot)
-- No non-repeatable read.
COMMIT;
```

> **Code walkthrough:** Under Read Committed: each SELECT statement takesice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> a fresh snapshot of the database at the moment it executes. Transaction A's
> second SELECT sees transaction B's committed update because the snapshot
> is refreshed per-statement. Under Repeatable Read: the snapshot is taken
> at the start of the transaction (at the first statement after BEGIN).
> Transaction B's update is committed after A's snapshot point - A's snapshot
> excludes it. The second SELECT returns the original value.

```sql
-- SERIALIZABLE ISOLATION: write skew prevention

-- Problem: each doctor checks if the other is on call
-- before going off call. Both see the other as on-call.
-- Both go off call. Result: 0 doctors on call. WRONG.

-- Accounts table: doctor_id, on_call

-- BAD: Read Committed (write skew allowed)
-- Session 1 (Doctor A):
BEGIN;
SELECT COUNT(*) FROM doctors WHERE on_call = true;
-- Returns: 2 (both A and B on call)
UPDATE doctors SET on_call = false WHERE id = 'A';
COMMIT;  -- A goes off call, saw 2 on call

-- Session 2 (Doctor B) - concurrent with A:
BEGIN;
SELECT COUNT(*) FROM doctors WHERE on_call = true;
-- Returns: 2 (read A as still on call, not committed yet)
UPDATE doctors SET on_call = false WHERE id = 'B';
COMMIT;  -- B goes off call, saw 2 on call
-- RESULT: 0 doctors on call. INCORRECT.

-- GOOD: Serializable prevents write skew
-- Session 1 (Doctor A):
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM doctors WHERE on_call = true;
UPDATE doctors SET on_call = false WHERE id = 'A';
COMMIT;

-- Session 2 (Doctor B) - concurrent:
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM doctors WHERE on_call = true;
UPDATE doctors SET on_call = false WHERE id = 'B';
COMMIT;
-- ERROR: could not serialize access due to read/write
--        dependencies among transactions
-- One of them fails. Application retries. The retry
-- reads 1 doctor on call -> refuses to go off call.
```

> **Code walkthrough:** Write skew: two transactions each read a condition,ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> make decisions based on it, write changes that together invalidate the
> condition. Neither individual transaction is wrong alone - the problem
> is the interaction. Read Committed allows write skew because each
> transaction reads the correct committed data at its snapshot point.
> Serializable (SSI) detects the read-write dependency cycle: A read
> doctors, B read doctors, A wrote doctors, B wrote doctors - this is
> a cycle. One transaction is aborted. The retry reads the updated state
> and makes the correct decision.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Four isolation levels: Read Uncommitted (no prevention), Read Committed
> (default, prevents dirty reads), Repeatable Read (prevents non-repeatable reads),
> Serializable (prevents all anomalies including phantoms). Higher isolation
> prevents more anomalies but has more overhead. PostgreSQL default is
> Read Committed.

---

**Senior / Staff:**
> For OLTP: Read Committed is correct for most workloads. Use Repeatable Read
> when a transaction must read the same data twice and get consistent results
> (e.g., read-modify-write on complex objects). Use Serializable for critical
> financial invariants (prevent write skew) without manual locking. PostgreSQL's
> SSI is low-overhead: it tracks dependencies and aborts only when a conflict
> is detected, not on every read. Application code must handle serialization
> failures: wrap transactions in retry loops. The retried transaction sees
> the correct committed state and makes the right decision.

---

### ⚠️ Common Misconceptions

**"Serializable uses heavy locking"**

Reality: PostgreSQL's Serializable uses SSI (Serializable Snapshot Isolation),
which tracks read-write dependencies without holding locks on read rows.
Transactions proceed concurrently; conflicts are detected at commit time.
Only conflicting transactions are aborted. Read-only transactions in
Serializable mode: never aborted.

**"Read Committed prevents all practical anomalies"**

Reality: Read Committed allows write skew (demonstrated in the doctor
example) and lost updates in certain patterns. For financial systems where
"read a value, compute a new value, write it back" must be consistent:
Read Committed can produce incorrect results. Either use Serializable or
add explicit locking (`SELECT ... FOR UPDATE`).

---

### ⚖️ Comparison Table

| Level | Dirty Read | Non-Rep Read | Phantom | Overhead | Use Case |
|---|---|---|---|---|---|
| Read Uncommitted | Possible | Possible | Possible | Lowest | Analytics (approx OK) |
| Read Committed | Prevented | Possible | Possible | Low | Default OLTP |
| Repeatable Read | Prevented | Prevented | Prevented* | Medium | Read-then-write patterns |
| Serializable | Prevented | Prevented | Prevented | Medium** | Financial invariants |

*PostgreSQL Repeatable Read prevents phantom reads too (MVCC snapshot)
**PostgreSQL SSI has low overhead; retries are the main cost

---

### 🏛️ System Design

*(Omit: L3 keyword - isolation level selection is a query/transaction pattern concern)*

---

### 📊 Diagram

*(Omit: phenomena illustrated clearly in code examples above)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Serialization failure (40001) under load**

Symptom: `ERROR: could not serialize access due to read/write dependencies`
(SQLSTATE 40001). Frequency increases under high concurrency.

Cause: Serializable transactions detected a read-write dependency cycle.

Fix: implement retry loop in application code:
```java
int retries = 0;
while (retries < 5) {
    try (Connection conn = dataSource.getConnection()) {
        conn.setTransactionIsolation(
            Connection.TRANSACTION_SERIALIZABLE);
        conn.setAutoCommit(false);
        // Execute business logic
        conn.commit();
        break;
    } catch (SQLException e) {
        if ("40001".equals(e.getSQLState())) {
            retries++;  // Serialization failure - retry
            Thread.sleep(10 * retries);  // Backoff
        } else {
            throw e;
        }
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

---

### 🎯 Interview Deep-Dive

**[JUNIOR] Q1 - [MECHANISM] How does PostgreSQL implement Read Committed using MVCC?**

🗣️ "MVCC (Multi-Version Concurrency Control): PostgreSQL keeps multiple versions
of each row. Each row version has xmin (transaction that created it) and
xmax (transaction that deleted/updated it). At Read Committed: each statement
gets a snapshot of the database. The snapshot includes all transactions
committed before the statement started. A row version is visible if:
xmin is committed and before the snapshot point, AND (xmax is not committed
OR xmax is after the snapshot point). Under Read Committed: a long transaction
that executes multiple SELECTs sees a different snapshot for each SELECT
(the snapshot is taken at statement start, not transaction start). This allows
non-repeatable reads: the second SELECT sees commits that happened between
the two statements."

**[JUNIOR] Q2 - [MECHANISM] What is write skew and which isolation level prevents it?**

🗣️ "Write skew: two transactions read overlapping data, each writes different
data, but their combined effect violates a constraint that each individual
write would not. The doctor on-call example: both doctors check 'is at least
one doctor on call?' (yes). Both decide to go off call. Together: zero doctors
on call - violates the constraint. Read Committed allows this: each transaction
reads the correct committed data at its point. Serializable prevents write skew:
SSI detects that both transactions read the same predicate (on_call count)
and both wrote to the doctors table. This is a rw-dependency cycle (T1 read
what T2 wrote would affect, T2 read what T1 wrote would affect). One is aborted."

**[JUNIOR] Q3 - [TRADE-OFF] What is the difference between snapshot isolation and serializable?**

🗣️ "Snapshot Isolation (SI): each transaction works on a consistent snapshot
taken at transaction start. No dirty reads or non-repeatable reads. But:
write skew is possible. Two transactions can read the same snapshot and each
make writes that together violate a constraint. SI is NOT fully serializable.
Serializable Snapshot Isolation (SSI): extends SI with conflict detection.
SSI tracks which transactions read which data (rw-anti-dependencies).
If a cycle of rw-dependencies exists: one transaction is aborted (serialization failure).
SSI is fully serializable but has minimal additional overhead over SI.
PostgreSQL's REPEATABLE READ: this is SI (consistent snapshot, but write skew possible).
PostgreSQL's SERIALIZABLE: this is SSI (detects write skew cycles)."

**[MID] Q4 - [MECHANISM] How do you choose the right isolation level for a given use case?**

🗣️ "Decision framework: (1) Is dirty read acceptable? Never acceptable in production.
Use at least Read Committed. (2) Is the transaction a simple read-then-write
on a single row? Use Read Committed + SELECT ... FOR UPDATE (pessimistic lock).
(3) Does the transaction read multiple rows and compute a result, then write
back (like 'total inventory' calculation)? Use Repeatable Read or Serializable
to prevent the snapshot from changing mid-transaction. (4) Does correctness
depend on a multi-row invariant (like 'at least one doctor on call')?
Use Serializable. (5) Is the transaction read-only (analytics)? Use Read Committed
or Repeatable Read. Serializable read-only transactions are never aborted in
PostgreSQL - they are safe and have no conflict overhead."

**[MID] Q5 - [FAILURE] What happens to a long-running transaction under Read Committed?**

🗣️ "Under Read Committed: each statement sees data committed before that statement.
A transaction running for 1 hour: its SELECT statements see progressively
more recent data as the transaction runs. Two SELECTs in the same transaction
can return different data. This is the non-repeatable read: allowed at Read Committed.
Additional risk: a long transaction holds its xmin (transaction ID) open.
Other transactions' dead rows (xmax set) cannot be VACUUMed while this transaction's
xmin is live. A transaction open for 1+ hours can cause table bloat:
VACUUM cannot clean up rows that are dead but newer than the old transaction's
xmin. Monitor: `pg_stat_activity` for long-running transactions.
`idle in transaction`: a transaction that started but is not executing -
still holds its xmin."

**[SENIOR] Q6 - [MECHANISM] How does SELECT FOR UPDATE interact with isolation levels?**

🗣️ "`SELECT ... FOR UPDATE`: acquires a row-level exclusive lock on the selected rows.
Blocks concurrent transactions that try to update or lock the same rows.
Under Read Committed: SELECT FOR UPDATE acquires a lock AND sees the most
recently committed version of the row (re-reads the committed version, not
the snapshot version). This is 'lock re-read': if another transaction updated
the row between the snapshot and the lock acquisition, the post-lock read
sees the update. Under Repeatable Read: SELECT FOR UPDATE also re-reads
the committed version at lock time. If the row changed: PostgreSQL returns
an error (cannot update a row that was concurrently modified). Application
must retry. SELECT FOR UPDATE is useful for: (1) read-then-update patterns
where no other transaction should modify the row between the read and update;
(2) preventing lost updates at Read Committed."

**[SENIOR] Q7 - [MECHANISM] What is a lost update and how do you prevent it?**

🗣️ "Lost update: two transactions read a value, both increment it, both write
back. The second write overwrites the first. Example: T1 reads count=10,
T2 reads count=10, T1 writes count=11, T2 writes count=11. Net result: 11,
not 12. One increment is lost. Prevention methods: (1) Atomic operations:
`UPDATE counter SET count = count + 1 WHERE id = ?`. The increment is
performed inside the database engine atomically. (2) SELECT FOR UPDATE:
T1 reads count=10 with a lock. T2 blocks until T1 commits. T2 re-reads
count=11 and writes 12. (3) Optimistic locking: read a version number,
write with WHERE version = old_version. If another transaction updated it:
version changed; UPDATE affects 0 rows; application retries.
(4) Serializable: SSI detects the rw-dependency pattern for lost updates
and aborts one transaction."

**[SENIOR] Q8 - [MECHANISM] What is two-phase locking (2PL) and why does PostgreSQL not use it?**

🗣️ "2PL: traditional serializable isolation approach. Phase 1 (growing): transaction
acquires locks but does not release them. Phase 2 (shrinking): transaction releases
locks but does not acquire new ones. 2PL is provably serializable. Drawbacks:
(1) read locks block writers; writer locks block readers - high contention;
(2) deadlock risk increases: more locks held longer; (3) throughput degrades
under concurrency. PostgreSQL uses MVCC: readers never block writers, writers
never block readers. For serializability: SSI tracks dependencies without
holding read locks. Benefits: higher concurrency, better read scalability.
Cost: serialization failures need application retry logic. 2PL still used
in some databases (MySQL with S locks in Serializable mode)."

**[SENIOR] Q9 - [DEBUGGING] How do you debug isolation level issues in production?**

🗣️ "Step 1: identify the symptom. Non-repeatable read: same query in a transaction
returns different data. Write skew: invariant violated despite each individual
write being correct. Lost update: counter or balance is lower than expected.
Step 2: enable log of transactions by isolation level:
`log_min_duration_statement = 0` captures all queries with timing.
Analyze logs for concurrent transactions on the same rows.
Step 3: reproduce in staging with `pgbench` custom scripts that simulate
the concurrent access pattern. Step 4: check `pg_stat_activity` for
concurrent transactions: `WHERE state = 'active' AND query NOT LIKE '%pg_stat%'`.
Step 5: choose the fix: (a) increase isolation level to Repeatable Read
or Serializable; (b) add SELECT FOR UPDATE; (c) use atomic SQL operations.
Always choose the minimal intervention that solves the problem."

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


# Optimistic vs Pessimistic Locking

**TL;DR:** Pessimistic locking acquires a lock before reading to prevent concurrent
modification (`SELECT FOR UPDATE`). Optimistic locking assumes no conflict, reads
without locking, then verifies at write time that no concurrent modification
occurred (using a version number or timestamp). Pessimistic is safe under high
contention. Optimistic has higher throughput under low contention.

---

### 🎯 Model Answer

**30 seconds:**
> Pessimistic: lock the row before reading; no one else can modify it until you
> commit. `SELECT ... FOR UPDATE`. Safe but can cause contention.
> Optimistic: read without locking; at write time, check a version column to
> verify no one changed it. If changed: retry. Higher throughput when conflicts
> are rare.

**3 minutes:**
> Pessimistic locking: `SELECT id, balance FROM accounts WHERE id=1 FOR UPDATE`.
> Other transactions trying to update account 1 are blocked until this transaction
> commits or rolls back. No lost updates, no race conditions. Cost: contention under
> heavy read-then-write on the same rows. Risk: deadlock (T1 locks A then B, T2 locks B
> then A - deadlock).
>
> Optimistic locking: no lock on read. The row has a `version` column (integer
> or timestamp). Read: `SELECT id, balance, version FROM accounts WHERE id=1`.
> Write: `UPDATE accounts SET balance=new_val, version=version+1 WHERE id=1 AND version=old_version`.
> If `UPDATE` affects 0 rows: another transaction changed the row (version changed);
> the application retries. If 1 row updated: success.
>
> Decision: high contention (same rows frequently) -> pessimistic (fewer retries).
> Low contention (infrequent conflicts) -> optimistic (higher concurrency, no blocking).
> Distributed systems (no shared lock manager) -> optimistic is the only option.

**Blank Mind Recovery:**

**(1) Restate:** "Pessimistic: lock before read (FOR UPDATE). Optimistic: check version
at write (UPDATE WHERE version=old). If 0 rows updated: retry."

**(2) First principles:** "Both prevent lost updates. Pessimistic: prevent by blocking.
Optimistic: prevent by detecting and retrying."

**(3) Bridge:** "Pessimistic: bathroom key system. Take the key before you go.
Others wait. Optimistic: scratch ticket. Check if the data changed before confirming.
If already scratched: try again."

---

### 📘 Concept Explanation

**Pessimistic locking modes in PostgreSQL:**

```sql
FOR UPDATE         -- exclusive row lock
                   -- blocks: UPDATE, DELETE, SELECT FOR UPDATE
                   -- does not block: regular SELECT

FOR NO KEY UPDATE  -- weaker exclusive lock
                   -- blocks: FOR UPDATE only
                   -- allows: foreign key checks

FOR SHARE          -- shared lock
                   -- blocks: FOR UPDATE, FOR NO KEY UPDATE
                   -- allows: multiple concurrent readers

FOR KEY SHARE      -- weakest shared lock
                   -- blocks: FOR UPDATE only
                   -- used by foreign key enforcement
```

> **Code walkthrough:** This Optimistic vs Pessimistic Locking example demonstrates query execution using SQL. **KEY MECHANISM:** the query planner builds an execution plan based on table statistics and indexes. **WHY IT MATTERS:** SELECT * reads all columns even if only 2 are needed - widens rows, increases I/O. **TAKEAWAY: always SELECT only the columns you need; index the columns in WHERE and JOIN clauses.**

**Optimistic locking: version column pattern:**

```sql
-- Schema:
ALTER TABLE orders ADD COLUMN version INTEGER NOT NULL DEFAULT 0;

-- Read:
SELECT id, status, total_cents, version
FROM orders WHERE id = :id;

-- Write (optimistic check):
UPDATE orders
SET status = :new_status,
    version = version + 1
WHERE id = :id
  AND version = :read_version;
-- If 0 rows updated -> concurrent modification -> retry
-- If 1 row updated -> success
```

> **Code walkthrough:** This Optimistic vs Pessimistic Locking example demonstrates query execution using SQL. **KEY MECHANISM:** the query planner builds an execution plan based on table statistics and indexes. **WHY IT MATTERS:** SELECT * reads all columns even if only 2 are needed - widens rows, increases I/O. **TAKEAWAY: always SELECT only the columns you need; index the columns in WHERE and JOIN clauses.**

---

### 💻 Code Example

```sql
-- PESSIMISTIC LOCKING: bank transfer

-- Transfer $100 from account 1 to account 2
BEGIN;

-- Lock both rows in consistent order (lower ID first)
-- to prevent deadlock
SELECT id, balance
FROM accounts
WHERE id IN (1, 2)
ORDER BY id
FOR UPDATE;
-- Rows are locked. No other transaction can modify them.

-- Perform the transfer
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

COMMIT;
-- Locks released. Other transactions can proceed.
```

> **Code walkthrough:** `FOR UPDATE` acquires an exclusive lock on bothice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> account rows. Any other transaction attempting `FOR UPDATE` or `UPDATE`
> on account 1 or 2 is blocked until this transaction commits. The consistent
> ordering (`ORDER BY id`) is critical: if T1 locks [1, 2] and T2 locks [2, 1]
> concurrently, they deadlock. By always locking in the same order (lower ID first):
> T2 will block on account 1 until T1 commits, then proceed safely. No deadlock.

```java
// OPTIMISTIC LOCKING: Java + Spring implementation

@Entity
@Table(name = "orders")
public class Order {

    @Id
    private Long id;

    @Version  // JPA optimistic locking
    private Long version;

    private String status;
    private long totalCents;
}

// Service layer:
@Transactional
public void updateOrderStatus(
        Long orderId, String newStatus) {
    Order order = orderRepository.findById(orderId)
        .orElseThrow(() -> new EntityNotFoundException());

    order.setStatus(newStatus);
    // JPA auto-executes:
    // UPDATE orders SET status=?, version=version+1
    // WHERE id=? AND version=?
    // If 0 rows updated: throws OptimisticLockException

    orderRepository.save(order);
    // If concurrent modification: OptimisticLockException
}

// Retry logic:
public void updateWithRetry(
        Long orderId, String newStatus) {
    int retries = 3;
    while (retries-- > 0) {
        try {
            updateOrderStatus(orderId, newStatus);
            return;
        } catch (OptimisticLockException e) {
            if (retries == 0) throw e;
            // Small backoff before retry
        }
    }
}
```

> **Code walkthrough:** Spring JPA `@Version` annotation adds optimistic locking.
> When `save()` executes: JPA generates `UPDATE orders SET status=?, version=version+1 WHERE id=? AND version=?`.
> The WHERE clause includes `version=?` (the version read at load time).
> If another transaction updated the row first: the version column incremented;
> the WHERE clause matches 0 rows; JPA detects `UPDATE count = 0` and throws
> `OptimisticLockException`. The retry loop loads the fresh state (new version)
> and re-applies the business logic. This works correctly because the retry
> reads the latest committed state before writing.

```sql
-- DEADLOCK PREVENTION with pessimistic locking

-- BAD: inconsistent lock order -> deadlock risk
-- Transaction A:
BEGIN;
SELECT * FROM accounts WHERE id = 1 FOR UPDATE; -- lock 1
SELECT * FROM accounts WHERE id = 2 FOR UPDATE; -- lock 2
-- Meanwhile, Transaction B:
BEGIN;
SELECT * FROM accounts WHERE id = 2 FOR UPDATE; -- lock 2
SELECT * FROM accounts WHERE id = 1 FOR UPDATE; -- blocked by A
-- A is waiting for 2, B has 2. B is waiting for 1, A has 1.
-- DEADLOCK. PostgreSQL detects it and aborts one transaction.

-- GOOD: consistent lock order (always lower ID first)
BEGIN;
SELECT * FROM accounts
WHERE id IN (1, 2)
ORDER BY id  -- ensures consistent order
FOR UPDATE;
-- Both rows locked in one statement, consistent order.
-- Concurrent T2: blocks on id=1 (T1 has it).
-- No deadlock possible.
```

> **Code walkthrough:** The deadlock scenario: T1 holds lock on account 1 andice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> waits for account 2. T2 holds lock on account 2 and waits for account 1.
> Neither can proceed - PostgreSQL's deadlock detector identifies the cycle
> and aborts the one with the least work done (throws `ERROR: deadlock detected`).
> The consistent ordering solution: lock all required rows in a single SELECT
> with `IN (...) ORDER BY id FOR UPDATE`. This guarantees T1 and T2 always
> try to lock rows in the same order. T2 blocks on id=1 until T1 commits.
> No cycle possible.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Pessimistic locking: acquire a lock before reading (`SELECT FOR UPDATE`) - other
> transactions block until you're done. Optimistic locking: read without lock,
> write with a version check (`UPDATE ... WHERE version = old_version`) - if
> 0 rows updated, retry. Pessimistic for high-contention rows. Optimistic for
> rarely-conflicting data.

---

**Senior / Staff:**
> The trade-off: pessimistic prevents conflicts (no wasted work) but reduces
> concurrency. Optimistic maximizes concurrency but wastes work on retries
> under high contention. For financial operations on a small set of highly-contested
> accounts: pessimistic wins (retries would be very frequent). For e-commerce
> order processing where each customer modifies their own orders (infrequent
> conflicts): optimistic wins (high throughput, no blocking). For distributed
> systems without a shared lock manager (sharded databases, microservices):
> optimistic is the only viable choice.

---

### ⚠️ Common Misconceptions

**"Optimistic locking is always faster"**

Reality: optimistic locking has higher throughput only under low contention.
Under high contention: most writes fail and retry (wasted work). If 90%
of writes fail due to conflicts: the retry overhead is massive. Pessimistic
locking: in high-contention scenarios, one transaction proceeds while others
wait (no wasted work, just latency). Under high contention: pessimistic
often has higher throughput.

**"SELECT FOR UPDATE prevents all anomalies"**

Reality: `SELECT FOR UPDATE` prevents lost updates for the locked rows.
It does not prevent phantom reads (new rows inserted by other transactions
are not locked, since they don't exist yet at lock time). For phantom
prevention: use Serializable isolation.

---

### ⚖️ Comparison Table

| Aspect | Pessimistic | Optimistic |
|---|---|---|
| Lock on read | Yes (FOR UPDATE) | No |
| Conflict prevention | Blocking | Detection + retry |
| High contention | Efficient (no retries) | Poor (many retries) |
| Low contention | Overhead (unnecessary locks) | Efficient |
| Distributed systems | Hard (no shared lock manager) | Natural fit |
| Deadlock risk | Yes (multi-row locking) | None |
| Application complexity | Low | Retry logic needed |

---

### 🏛️ System Design

*(Omit: L3 keyword - locking strategy at architectural scale covered in L4/L5)*

---

### 📊 Diagram

*(Omit: pessimistic and optimistic flows illustrated clearly in code examples)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Deadlock under pessimistic locking**

Symptom: `ERROR: deadlock detected` under concurrent load. One transaction
is aborted.

Cause: two transactions lock rows in different orders. Each holds a lock
the other needs.

Fix: always acquire locks in a consistent order (by row ID, for example).
Or acquire all needed locks in a single `SELECT ... WHERE id IN (...) ORDER BY id FOR UPDATE`.

**Failure: Optimistic lock starvation under high contention**

Symptom: application repeatedly retries (5, 10+ times) before succeeding.
Latency spikes. CPU usage from retry logic.

Cause: too many concurrent writers on the same rows. Every writer competes;
most fail and retry.

Fix: switch to pessimistic locking for the contested rows. Or partition
the data to reduce per-row contention (e.g., multiple counter shards
aggregated periodically).

---

### 🎯 Interview Deep-Dive

**[JUNIOR] Q1 - [MECHANISM] How would you implement optimistic locking without a version column?**

🗣️ "Two options besides a version integer: (1) Timestamp: store `updated_at TIMESTAMP`
in the row. Read: get updated_at. Write: `UPDATE ... WHERE id=? AND updated_at=?`.
Drawback: timestamp precision may not be sufficient (two updates in the same
millisecond: both succeed incorrectly). Use `TIMESTAMP(6)` (microseconds)
to mitigate. (2) Hash of content: compute a hash of the relevant columns.
Store the hash. Write: compare hash on read vs hash on write. Drawback:
expensive hash computation per write. (3) Checksum or etag: same principle.
Version integer is preferred: simple, atomic increment, no precision issues,
O(1) check."

**[JUNIOR] Q2 - [SCENARIO] When would you use SELECT FOR SHARE instead of FOR UPDATE?**

🗣️ "`FOR UPDATE`: exclusive lock. Blocks all concurrent writes and FOR UPDATE/FOR SHARE.
Use when you intend to modify the row. `FOR SHARE`: shared lock. Blocks writers but
allows concurrent readers with FOR SHARE. Use when you need to ensure the row is
not modified but multiple readers need to hold the same shared constraint.
Example: validating a foreign key reference. `SELECT * FROM products WHERE id=? FOR SHARE`.
You want to ensure the product exists and is not deleted before inserting an
order_item. FOR SHARE: another transaction can also FOR SHARE (both are reading).
A transaction trying to DELETE the product: blocks until both FOR SHARE transactions
commit. FOR UPDATE would be overkill: you are not modifying the product row."

**[JUNIOR] Q3 - [MECHANISM] How does Spring's @Version annotation work with database-generated versions?**

🗣️ "`@Version` with `Long`: JPA adds `version bigint NOT NULL DEFAULT 0` to the schema.
On every `UPDATE` issued by JPA: `WHERE version = :loaded_version`. On success:
JPA increments the in-memory entity's version. On failure (0 rows): throws
`OptimisticLockException`. Database-generated: set `@Version @Generated` or
use a database trigger to auto-update a `last_modified` timestamp. JPA reads
the timestamp after update. Less common. Version integer is preferred: deterministic,
no clock skew. In distributed microservices: if two services share a database table,
both using JPA optimistic locking on the same entity: version conflicts are caught
correctly. Across microservices that each have their own database: optimistic locking
must be implemented at the API layer (ETags) or event sourcing."

**[MID] Q4 - [MECHANISM] How do you handle optimistic locking in a batch update scenario?**

🗣️ "Batch update: update 1,000 order statuses in a single transaction.
Optimistic locking with version check per row:
`UPDATE orders SET status=:new_status, version=version+1 WHERE id=:id AND version=:version`.
Execute as a JDBC batch. Check affected rows per statement. If any row returns 0 updated:
the entire batch is in an inconsistent state. Options: (1) Abort and retry the entire batch
from the beginning (re-read all 1,000 rows). High cost if conflicts are frequent.
(2) Accept partial success: commit rows that succeeded; retry only failed rows.
Risky if rows have interdependencies. (3) Switch to pessimistic locking for batch
operations: `SELECT ... WHERE id IN (...) FOR UPDATE` - locks all rows upfront,
no conflict during the batch update. Pessimistic is often better for batch scenarios:
the batch runs faster and no retries are needed."

**[MID] Q5 - [TRADE-OFF] What is the difference between a lost update and write skew?**

🗣️ "Lost update: two transactions read and write the SAME rows. T1 reads x=10,
T2 reads x=10, T1 writes x=11, T2 writes x=11. T1's write is lost: x should be 12.
The conflict is on the same row. Prevented by: FOR UPDATE, optimistic locking
(version check), atomic operations (UPDATE SET x=x+1).
Write skew: two transactions read DIFFERENT rows but their combined writes violate
a constraint. Doctor example: both read the count of on-call doctors (two different
reads of the same derived value), both write their own row (different rows), together
violate the 'at least 1 on call' constraint. Neither individual write is wrong.
Prevented by: Serializable isolation only. FOR UPDATE on the rows does not help
(the predicate is on the COUNT, not specific rows). Optimistic locking per-row
does not help either."

**[SENIOR] Q6 - [MECHANISM] How do you detect long-held locks in PostgreSQL?**

🗣️ "Query `pg_locks` joined with `pg_stat_activity`:
```sql
SELECT l.locktype, l.relation::regclass, l.mode,
       l.granted, a.pid, a.query_start, a.state, a.query
FROM pg_locks l
JOIN pg_stat_activity a ON a.pid = l.pid
WHERE NOT l.granted
ORDER BY a.query_start;
```
> **Code walkthrough:** This Unknown example demonstrates query execution using SQL. **KEY MECHANISM:** the query planner builds an execution plan based on table statistics and indexes. **WHY IT MATTERS:** SELECT * reads all columns even if only 2 are needed - widens rows, increases I/O. **TAKEAWAY: always SELECT only the columns you need; index the columns in WHERE and JOIN clauses.**

Not granted = blocked transaction. `query_start` = when it started waiting.
Find the blocker: same relation, `granted = true`. Look at the blocking query.
High-value diagnostic: long-held FOR UPDATE with `idle in transaction` state -
a connection acquired a lock and then sat idle (connection leak, crashed client).
Fix: `pg_cancel_backend(pid)` to cancel the blocking query. Or set
`idle_in_transaction_session_timeout = '5min'` in postgresql.conf to auto-cancel."

**[SENIOR] Q7 - [MECHANISM] How does optimistic locking work in a NoSQL or distributed database?**

🗣️ "Distributed databases without a central lock manager use conditional writes:
(1) DynamoDB: `ConditionExpression='version = :v'`. If condition fails: throws
`ConditionalCheckFailedException`. Application retries.
(2) Cassandra: Lightweight Transactions (LWT) with PAXOS: `UPDATE t SET v=new WHERE pk=? IF v=old`.
Only one of N concurrent LWTs succeeds. Expensive (PAXOS round trips). Use sparingly.
(3) Redis: WATCH/MULTI/EXEC (optimistic transaction):
`WATCH key -> GET key -> verify value -> MULTI -> SET key val -> EXEC`.
EXEC returns null if the watched key changed. Retry.
(4) HTTP APIs: ETags. GET returns ETag header (hash of resource). PUT with
`If-Match: etag` header. Server rejects if current etag differs.
All of these are the same pattern: read a version, write with a version check,
retry on conflict."

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



