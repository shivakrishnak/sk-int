---
layout: default
title: "Database SQL - L2 Transactions Basics"
parent: "Database SQL"
nav_order: 8
permalink: /database-sql/l2-transactions-basics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Transactions and ACID Properties](#transactions-and-acid-properties) | medium |
| 2 | [Commit and Rollback - Transaction Lifecycle](#commit-and-rollback---transaction-lifecycle) | medium |

---

# Transactions and ACID Properties

**TL;DR:** A transaction is a unit of work that is atomic (all or nothing),
consistent (constraints maintained), isolated (concurrent transactions do
not interfere), and durable (committed data survives crashes). These
four ACID properties are the guarantees that make databases safe for
concurrent, crash-prone environments.

---

### 🎯 Model Answer

**30 seconds:**
> A transaction groups multiple SQL operations into an all-or-nothing unit.
> ACID: Atomic (all operations succeed or all are rolled back), Consistent
> (database constraints are always valid), Isolated (concurrent transactions
> do not see each other's in-progress data), Durable (committed changes
> survive crashes). Without transactions: partial failures leave the database
> in an inconsistent state.

**3 minutes:**
> Atomicity: if a bank transfer debits account A but then crashes before
> crediting account B, the debit is rolled back automatically. Either
> both the debit and credit happen, or neither does.
>
> Consistency: the database enforces constraints (NOT NULL, UNIQUE, FK,
> CHECK) at transaction commit. A transaction that would violate a
> constraint is rejected. This is the "rules cannot be broken" guarantee.
>
> Isolation: two concurrent transactions editing the same data do not
> interfere. Transaction 1 reading a row does not see Transaction 2's
> in-progress write (before commit). The exact guarantee depends on the
> isolation level (READ COMMITTED, REPEATABLE READ, SERIALIZABLE).
>
> Durability: once the database returns "COMMIT", the data is on disk.
> Even if the server crashes immediately after: the data is recoverable.
> Implemented via the Write-Ahead Log (WAL).

**Blank Mind Recovery:**

**(1) Restate:** "ACID: Atomic (all or nothing), Consistent (constraints
valid), Isolated (concurrent transactions don't interfere), Durable (committed
data survives crashes). Without ACID: partial failures corrupt data."

**(2) First principles:** "A database with concurrent access and crashes
needs guarantees. ACID defines the minimum set of guarantees for correctness.
Each property handles a different failure mode."

**(3) Bridge:** "Like a bank vault: Atomic = either the full transfer
completes or nothing changes. Consistent = the vault enforces its rules
(no negative balances). Isolated = your transaction is private until complete.
Durable = once the receipt is printed, the money is there."

---

### 📘 Concept Explanation

**The ACID properties:**

```
A - ATOMICITY
  All operations in the transaction succeed,
  or ALL are rolled back.
  - Protects against: partial failure, crashes mid-transaction.
  - Implemented via: undo log (rollback capability).

C - CONSISTENCY
  The database is in a valid state before and after
  every transaction. All constraints are satisfied.
  - Protects against: constraint violations, corrupted state.
  - Implemented via: constraint checking at commit time.

I - ISOLATION
  Concurrent transactions behave as if executing
  sequentially (to some degree, per isolation level).
  - Protects against: dirty reads, non-repeatable reads,
    phantom reads.
  - Implemented via: MVCC (PostgreSQL), locking, or both.

D - DURABILITY
  Committed transactions survive crashes.
  - Protects against: data loss from crash, power failure.
  - Implemented via: Write-Ahead Log (WAL). Every committed
    change is first written to the WAL on disk before
    the COMMIT returns.
```

> **Code walkthrough:** This reference maps each ACID letter to its guarantee, the exact failure it prevents, and how the engine implements it. The implementation column is the key insight: Atomicity uses an undo log so a crash mid-transaction can be reversed; Durability uses WAL so a committed change survives a crash before the page is flushed to disk. Consistency relies on constraint checking at commit time, not continuously. Isolation is implemented by MVCC in PostgreSQL rather than coarse table locks, which is why reads do not block writes. Knowing the implementation mechanism separates surface knowledge from the understanding needed to diagnose production failures.

**Read phenomena in isolation:**

```
DIRTY READ: reading uncommitted data from another transaction.
  T1 updates row X (not committed).
  T2 reads row X: sees T1's uncommitted value.
  T1 rolls back. T2 has used a value that never existed.

NON-REPEATABLE READ: reading the same row twice, getting
different values.
  T1 reads row X: sees value V1.
  T2 updates and commits row X: new value V2.
  T1 reads row X again: sees V2. Changed within T1's view.

PHANTOM READ: re-running a WHERE query gets different rows.
  T1 queries WHERE age > 20: gets 5 rows.
  T2 inserts a new row with age=25 and commits.
  T1 re-runs WHERE age > 20: gets 6 rows. New "phantom" row.
```

> **Code walkthrough:** Each anomaly is shown as a two-transaction sequence, making the timing dependency concrete. Dirty read requires T1 to be uncommitted when T2 reads, so T1's ROLLBACK retroactively invalidates T2's data. Non-repeatable read only occurs when T2 commits between T1's two reads of the exact same row. Phantom read targets range queries rather than individual rows, which is why row-level locking cannot prevent it - a new row inserted by T2 was not locked by T1 because it did not exist yet. Preventing phantoms requires predicate locks or SERIALIZABLE isolation, not just row locks.

---

### 💻 Code Example

```sql
-- TRANSACTION: the basic pattern

-- BAD: multiple operations without a transaction
UPDATE accounts SET balance = balance - 500
WHERE id = 1;
-- If the system crashes here, account 1 is debited
-- but account 2 is never credited. Money lost.
UPDATE accounts SET balance = balance + 500
WHERE id = 2;

-- GOOD: wrap in a transaction
BEGIN;

  UPDATE accounts
  SET balance = balance - 500
  WHERE id = 1 AND balance >= 500;

  -- If the debit affected 0 rows (insufficient funds),
  -- the credit should not proceed.
  -- Application checks rowcount here; if 0: ROLLBACK.

  UPDATE accounts
  SET balance = balance + 500
  WHERE id = 2;

COMMIT;
-- If any error occurs before COMMIT: the database
-- automatically rolls back both updates.
-- Either both happen, or neither.
```

> **Code walkthrough:** The BAD version runs two separate auto-commitice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> statements. A crash between them leaves account 1 debited and account 2
> uncredited. The GOOD version wraps both in `BEGIN...COMMIT`. If the server
> crashes after BEGIN but before COMMIT: the WAL records that the transaction
> was not committed, and recovery rolls back both updates. The `balance >= 500`
> check makes the debit conditional (optimistic lock on sufficient balance).
> The application checks if rows were affected; if 0 rows updated: ROLLBACK.

```sql
-- TRANSACTION ISOLATION: what you see in READ COMMITTED

-- PostgreSQL default: READ COMMITTED isolation.
-- Each statement sees the most recently committed data.

-- Session 1 (T1):
BEGIN;
SELECT balance FROM accounts WHERE id = 1;
-- Returns: 1000

-- Session 2 (T2): concurrent transaction
BEGIN;
UPDATE accounts SET balance = 800 WHERE id = 1;
COMMIT;  -- T2 commits

-- Session 1 (T1): re-reads the same row
SELECT balance FROM accounts WHERE id = 1;
-- READ COMMITTED: T1 now sees 800 (T2's committed change).
-- This is a NON-REPEATABLE READ (value changed within T1).
COMMIT;

-- Under REPEATABLE READ or SERIALIZABLE:
-- T1's second read would still return 1000.
-- T1's snapshot was taken at the start of the transaction.
```

> **Code walkthrough:** READ COMMITTED allows non-repeatable reads.
> Each SELECT within T1 sees the latest committed snapshot. T2 commits
> a balance change; T1's next read sees the new value. This is intentional:
> READ COMMITTED prevents dirty reads (seeing uncommitted data) but allows
> the balance to change between reads within the same transaction. For
> applications that need stable reads: REPEATABLE READ takes a snapshot
> at transaction start and uses it for all reads in that transaction.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> A transaction is a group of SQL operations that succeeds or fails as
> a unit. ACID: Atomic (all or nothing), Consistent (constraints enforced),
> Isolated (concurrent transactions see committed data), Durable (committed
> data survives crashes). Always use transactions for multi-step operations
> that must either all succeed or all fail. `BEGIN; ... COMMIT;` for success,
> `ROLLBACK` for failure.

---

**Senior / Staff:**
> The most important thing to understand about ACID in interviews: the
> 'I' (Isolation) is a spectrum. The default isolation level (READ COMMITTED)
> prevents dirty reads but allows non-repeatable reads and phantom reads.
> REPEATABLE READ prevents those but allows phantom reads. SERIALIZABLE
> prevents all anomalies but has the highest overhead. The right isolation
> level is the weakest one that still produces correct application behavior
> for your use case. Higher isolation = more lock contention or more MVCC
> conflict aborts.

---

### ⚠️ Common Misconceptions

**"ACID is all-or-nothing in all aspects"**

Reality: 'Isolated' is not all-or-nothing. It is a spectrum:
READ UNCOMMITTED (weakest) through SERIALIZABLE (strongest). Most
databases default to READ COMMITTED, which allows non-repeatable reads.
True serializable isolation has real performance costs. Applications
choose the right level for their correctness requirements.

**"COMMIT guarantees data is on disk immediately"**

Reality: COMMIT guarantees data will survive a crash. The mechanism:
the WAL record for the commit is flushed to disk synchronously (`fsync`).
The actual data page may still be in memory and written later by the
background writer. Recovery: if the server crashes, the WAL records
are replayed to restore the committed state. The committed data page
is reconstructed from the WAL.

---

### ⚖️ Comparison Table

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Overhead |
|---|---|---|---|---|
| READ UNCOMMITTED | Possible | Possible | Possible | Lowest |
| READ COMMITTED (default) | Prevented | Possible | Possible | Low |
| REPEATABLE READ | Prevented | Prevented | Possible | Medium |
| SERIALIZABLE | Prevented | Prevented | Prevented | Highest |

---

### 🏛️ System Design

*(Omit: L2 keyword - transaction isolation at system level is covered in L3 Concurrency Control)*

---

### 📊 Diagram

*(Omit: ACID concepts are best illustrated in the code and table above)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Long-running transaction blocks other operations**

Symptom: application writes are stalled; `pg_stat_activity` shows a
transaction open for hours.

Cause: a transaction was started but never committed or rolled back
(application bug, connection lost, long batch operation).

Diagnosis:
```sql
SELECT pid, now() - xact_start AS duration, query, state
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;
```

> **Code walkthrough:** This diagnostic query surfaces all non-idle connections with their age, identifying transactions that are holding locks too long. `now() - xact_start` produces a human-readable interval showing exactly how long each transaction has been open. The `state != 'idle'` filter excludes connections waiting for the next query; the dangerous state is `idle in transaction`, where BEGIN was issued but the connection is sitting without executing SQL while holding row locks. Sorting by `duration DESC` surfaces the oldest blockers first. Run this immediately when application writes stall or lock wait timeouts appear in logs.

Fix: kill the idle-in-transaction session:
```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND now() - xact_start > INTERVAL '5 minutes';
```

> **Code walkthrough:** `pg_terminate_backend(pid)` sends SIGTERM to the backend process, which triggers a graceful shutdown and automatic ROLLBACK of the abandoned transaction, releasing all held locks. The `INTERVAL '5 minutes'` threshold is a tuning decision: too short kills legitimate long-running transactions; too long allows blocking to continue. This is an emergency fix - the root cause is almost always a missing `connection.close()` or error handling gap in application code that never commits or rolls back. Production systems should configure `idle_in_transaction_session_timeout` in PostgreSQL to enforce this automatically without manual intervention.

Set `idle_in_transaction_session_timeout` to auto-kill them.

---

### 🎯 Interview Deep-Dive

**[JUNIOR] Q1 - [TRADE-OFF] What is the difference between a dirty read, non-repeatable read, and phantom read?**

🗣️ "Dirty read: Transaction T1 reads data that T2 has modified but not
yet committed. If T2 rolls back: T1 has used data that never existed.
Non-repeatable read: T1 reads row X. T2 updates and commits X. T1 reads X
again and gets a different value. The same row returns different data within
one transaction. Phantom read: T1 runs a range query (WHERE age > 20).
T2 inserts a new row matching the range and commits. T1 runs the same range
query and gets an extra row - a 'phantom' that appeared. Each isolation
level prevents: READ COMMITTED prevents dirty reads. REPEATABLE READ
prevents dirty and non-repeatable reads. SERIALIZABLE prevents all three."

**[JUNIOR] Q2 - [MECHANISM] How does PostgreSQL implement isolation without traditional locking for reads?**

🗣️ "PostgreSQL uses MVCC (Multi-Version Concurrency Control). Instead of
locking rows for reads: each row has a version with a transaction ID range
(when it was created, when it was superseded). Each transaction has a snapshot:
the transaction ID at transaction start. A transaction sees: all rows whose
creation transaction ID is committed and within the snapshot, and excluding
rows superseded by committed transactions within the snapshot.
Result: readers never block writers, writers never block readers.
Concurrent writes to the same row: PostgreSQL takes a row-level lock on the
existing version (for the UPDATE). The new version is only visible after commit."

**[JUNIOR] Q3 - [FAILURE] What happens when two transactions try to UPDATE the same row?**

🗣️ "Transaction T1 UPDATEs row X: acquires a row-level exclusive lock.
Transaction T2 tries to UPDATE the same row X: T2 is blocked, waiting for T1's
lock to be released. When T1 COMMITS: T2 is unblocked. T2 sees T1's committed
version of the row (READ COMMITTED). T2's UPDATE proceeds from the new version.
Under SERIALIZABLE isolation: T2 may conflict with T1 even on non-overlapping
operations (serialization conflict). Under REPEATABLE READ: T2 may see an
error: 'could not serialize access due to concurrent update' if T1 and T2
have a conflicting update pattern. The application must handle the retry."

**[MID] Q4 - [SCENARIO] What is a savepoint and when would you use it?**

🗣️ "A savepoint is a named marker within a transaction. `SAVEPOINT sp1`.
If an error occurs: you can roll back to the savepoint (`ROLLBACK TO sp1`)
without rolling back the entire transaction. The subsequent operations
after the savepoint are undone, but prior work is preserved.
Use case: in a bulk import, process records one by one inside a transaction.
If record N fails: roll back to the savepoint before N, log the error,
continue with N+1. Without savepoints: any error rolls back all 10,000
records. With savepoints: only the failing record is skipped. JDBC: `conn.setSavepoint()`.
Spring: `TransactionDefinition.PROPAGATION_NESTED` uses a savepoint."

**[MID] Q5 - [SCENARIO] What is an optimistic lock vs. a pessimistic lock and when should you use each?**

🗣️ "Pessimistic lock: lock the row when reading it, preventing others from
modifying it until you commit. `SELECT ... FOR UPDATE`. Guarantees no
concurrent modification. Cost: serializes access, reduces concurrency.
Use when: conflicts are frequent, you need strict consistency, the lock
duration is short. Optimistic lock: do not lock when reading. Before updating:
check that the row has not been modified (via a version column or timestamp).
If changed: retry. Use when: conflicts are rare, high concurrency is needed,
lock contention would be a bottleneck. In Hibernate/JPA: `@Version` on an
entity uses optimistic locking. Optimistic is better for most web applications
(most users do not conflict); pessimistic is better for financial operations
where conflicts are frequent and costly."

**[SENIOR] Q6 - [MECHANISM] How do you handle transaction management in a Spring application?**

🗣️ "Spring's `@Transactional` annotation declaratively wraps the method
in a transaction. The Spring proxy begins a transaction before the method,
commits on success, and rolls back on RuntimeException or Error. Key settings:
`isolation`: controls the JDBC transaction isolation level. `propagation`:
REQUIRED (join existing or create new), REQUIRES_NEW (always create new,
suspend outer). `readOnly = true`: hint to the database to optimize for
reads (no dirty checks in JPA, may use a read replica).
`rollbackFor`: list of exceptions that trigger rollback (by default:
RuntimeException and Error, not checked exceptions).
Anti-pattern: calling a `@Transactional` method from within the same bean
(no proxy interception) - use PROPAGATION_REQUIRES_NEW only via a proxy call."

**[SENIOR] Q7 - [MECHANISM] What is the two-phase commit (2PC) protocol?**

🗣️ "Two-phase commit is a distributed transaction protocol for atomicity
across multiple databases or services. Phase 1 (Prepare): the coordinator
asks all participants to prepare. Each participant ensures it can commit
and logs the prepared state to durable storage. If any participant fails:
the coordinator sends Abort. Phase 2 (Commit): if all prepared: coordinator
sends Commit. Participants commit and release locks.
Problem: the coordinator can fail between phases, leaving participants in
a prepared-but-uncertain state. They hold locks until the coordinator
recovers. 2PC provides distributed atomicity but at high latency cost
and with coordinator failure risk. Alternative: saga pattern (sequence of
local transactions with compensating transactions for failure)."

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


# Commit and Rollback - Transaction Lifecycle

**TL;DR:** COMMIT makes all changes in the transaction permanent and visible
to other transactions. ROLLBACK undoes all changes since the last BEGIN.
In PostgreSQL, every statement outside an explicit transaction is
auto-committed. Understanding when transactions start and end is critical
for correctness in application code.

---

### 🎯 Model Answer

**30 seconds:**
> COMMIT finalizes all changes in the current transaction: they become
> permanent and visible. ROLLBACK undoes all changes since the last BEGIN.
> Auto-commit mode: most databases run each SQL statement as its own
> transaction. Explicit transactions: `BEGIN ... COMMIT` groups multiple
> statements into one atomic unit.

**3 minutes:**
> Transaction lifecycle: BEGIN starts a transaction. Subsequent SQL
> statements accumulate in the transaction. COMMIT writes all changes to
> the WAL, makes them visible to other transactions, and releases all
> locks. ROLLBACK undoes all changes (writes them as deleted from the
> WAL perspective), makes the state as if the transaction never ran,
> and releases all locks.
>
> JDBC: auto-commit is on by default. Each `executeUpdate()` is its own
> transaction. For multi-step operations: `conn.setAutoCommit(false)`,
> then `conn.commit()` or `conn.rollback()`. Spring `@Transactional` manages
> this automatically.
>
> Important: in PostgreSQL, once an error occurs in a transaction (without
> a SAVEPOINT), the entire transaction is in an aborted state. Subsequent
> statements return "ERROR: current transaction is aborted, commands ignored."
> You must `ROLLBACK` before starting a new transaction.

**Blank Mind Recovery:**

**(1) Restate:** "COMMIT = permanent + visible + locks released.
ROLLBACK = undo all changes + locks released. Auto-commit = each statement
is its own transaction."

**(2) First principles:** "A transaction is a unit of isolation. COMMIT
is when that unit's changes enter the shared database state. Until COMMIT:
changes exist only in the transaction's private workspace."

**(3) Bridge:** "Like drafting a document. BEGIN = create a draft.
SQL statements = edits. COMMIT = publish the final document (visible to all).
ROLLBACK = delete the draft (as if it never existed)."

---

### 📘 Concept Explanation

**Transaction state machine:**

```
START
  |
  v
[ACTIVE] <---- BEGIN
  |
  |--(SQL statement with error) --> [ABORTED]
  |                                     |
  |--(ROLLBACK) ----------------------> END
  |
  |--(COMMIT) --> WAL flush --> [COMMITTED] --> END

ABORTED state:
  All subsequent statements are rejected:
  "ERROR: current transaction is aborted"
  Only ROLLBACK (or ROLLBACK TO savepoint) is accepted.
```

> **Code walkthrough:** This state machine reveals a critical PostgreSQL behavior: once any statement fails mid-transaction, the connection enters ABORTED state where every subsequent SQL is rejected with the same error regardless of whether it would succeed independently. The only escape is ROLLBACK. The COMMIT path shows WAL flush happening before COMMIT returns to the client - this is the implementation of the Durability guarantee. The ABORTED trap is the most common source of cascading errors in connection pools: a failed statement puts the connection in ABORTED state, and subsequent queries on the reused connection all fail until rollback is issued.

**JDBC transaction management:**

```java
// Auto-commit mode (default): each statement is a transaction
connection.setAutoCommit(true);  // default
statement.executeUpdate("UPDATE ...");  // auto-committed

// Manual transaction:
connection.setAutoCommit(false);
try {
    statement.executeUpdate("UPDATE account SET...");
    statement.executeUpdate("UPDATE account SET...");
    connection.commit();        // commit both
} catch (SQLException e) {
    connection.rollback();      // rollback both
    throw e;
}
```

> **Code walkthrough:** This shows the two JDBC transaction modes side by side. In auto-commit mode, each `executeUpdate` is wrapped in its own implicit BEGIN/COMMIT - fine for single-statement operations but breaks atomicity across multiple statements. Manual mode uses `setAutoCommit(false)` to start an explicit transaction, then requires explicit `commit()` on success and `rollback()` in the catch block. Without the `rollback()` call, a failure after the first UPDATE commits one change and leaves the other uncommitted - a silent partial update that violates atomicity. Connection poolers like HikariCP reset autocommit between borrows, so always set it explicitly rather than assuming state.

---

### 💻 Code Example

```sql
-- COMMIT AND ROLLBACK: the patterns

-- BAD: individual auto-commit statements (no atomicity)
-- Each statement commits independently.
-- A crash between them leaves inconsistent state.
UPDATE inventory SET quantity = quantity - 1
WHERE product_id = 42;
-- (crash here: inventory decremented but order not created)
INSERT INTO orders (product_id, quantity) VALUES (42, 1);

-- GOOD: wrapped in an explicit transaction
BEGIN;

  UPDATE inventory
  SET    quantity = quantity - 1
  WHERE  product_id = 42 AND quantity > 0;

  -- Verify the update succeeded (optimistic check):
  -- Application code checks affected rows:
  --   if rows_affected == 0: ROLLBACK (out of stock)

  INSERT INTO orders (product_id, customer_id, quantity)
  VALUES (42, 101, 1);

COMMIT;
-- Both changes committed atomically.
-- If the INSERT fails: BEGIN..COMMIT block ensures
-- the UPDATE is also rolled back (automatic in PG
-- when an error occurs in the transaction).

-- ROLLBACK ON ERROR
BEGIN;
  UPDATE accounts SET balance = balance - 500 WHERE id = 1;
  -- Simulate an error:
  SELECT 1 / 0;  -- ERROR: division by zero
  -- Transaction is now ABORTED. All subsequent
  -- statements fail until ROLLBACK.
ROLLBACK;
-- Both statements are rolled back.
-- accounts table is unchanged.
```

> **Code walkthrough:** The BAD version uses auto-commit mode: each UPDATEice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> and INSERT is its own transaction. A crash between them permanently
> decrements inventory without creating an order. The GOOD version wraps
> both in `BEGIN...COMMIT`. If either statement fails: the error puts the
> transaction in ABORTED state; the final `COMMIT` is rejected; both
> changes are rolled back. The `AND quantity > 0` guard prevents negative
> inventory. The ROLLBACK example shows the aborted-transaction state:
> after `1/0` causes an error, the transaction cannot proceed until ROLLBACK.


```java
// BAD: calling @Transactional method from same class
// Spring proxy is bypassed - no transaction started
public void processOrder(Order order) {
    saveOrder(order); // self-call bypasses proxy
}
@Transactional
public void saveOrder(Order order) { /* ... */ }
```


```java
// BAD: calling @Transactional method from same class
// Spring proxy is bypassed - no transaction started
public void processOrder(Order order) {
    saveOrder(order); // self-call bypasses proxy
}
@Transactional
public void saveOrder(Order order) { /* ... */ }
```

```java
// JAVA + SPRING: @Transactional rollback

@Service
public class OrderService {

    // BAD: no transaction, partial failure possible
    public void createOrderBad(long productId, long custId) {
        inventoryRepo.decrementStock(productId);
        // If this throws: stock decremented, no order
        orderRepo.insertOrder(productId, custId);
    }

    // GOOD: @Transactional wraps both operations
    @Transactional  // begins transaction before method
    public void createOrder(long productId, long custId) {
        inventoryRepo.decrementStock(productId);
        // If RuntimeException thrown: Spring rolls back
        orderRepo.insertOrder(productId, custId);
    }  // commits here if no exception

    // GOOD: explicit rollback on checked exception
    @Transactional(rollbackFor = Exception.class)
    public void createOrderChecked(
            long productId, long custId) throws Exception {
        inventoryRepo.decrementStock(productId);
        // Checked exceptions also trigger rollback
        orderRepo.insertOrder(productId, custId);
    }
}
```

> **Code walkthrough:** The BAD method has no transaction. If `insertOrder`ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> throws after `decrementStock` succeeds: stock is decremented but no order
> is created. The GOOD method uses `@Transactional` - Spring's AOP proxy
> starts a transaction before the method and commits on normal return.
> If a RuntimeException is thrown: Spring calls `connection.rollback()`,
> undoing the stock decrement. `rollbackFor = Exception.class` extends
> rollback to checked exceptions (by default Spring only rolls back on
> unchecked exceptions and Errors).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> COMMIT makes transaction changes permanent and visible. ROLLBACK undoes
> all changes. Auto-commit: each SQL statement is its own transaction.
> Explicit transaction: `BEGIN ... COMMIT` or `BEGIN ... ROLLBACK`. In Java
> with Spring: `@Transactional` handles commit and rollback automatically.
> An error inside `@Transactional` causes automatic rollback on RuntimeException.

---

**Senior / Staff:**
> The most common transaction bug in Java/Spring: `@Transactional` on a
> `self-invoked` method. When Service.methodA() calls `this.methodB()` where
> methodB is `@Transactional`: the proxy is bypassed (direct object call,
> not through Spring's proxy). methodB runs without a new transaction.
> Fix: inject the service into itself (`@Autowired ServiceClass self`) or
> use `@Transactional(propagation = REQUIRES_NEW)` via a separate bean.
> Second common bug: catching exceptions inside `@Transactional` and swallowing
> them - the rollback signal (exception) never reaches Spring's proxy, so
> the transaction commits even after an error.

---

### ⚠️ Common Misconceptions

**"@Transactional on a method means everything inside that method is one transaction"**

Reality: `@Transactional` works via Spring AOP proxy. If the method is
called directly from within the same bean (not through the proxy): the
transaction does not start. The method runs outside any transaction.
Additionally: `@Transactional(readOnly = true)` does not prevent writes -
it is a hint that allows optimizations (JPA avoids dirty checks) but
does not enforce read-only at the database level.

**"ROLLBACK means the data was never written"**

Reality: during a transaction, changes are written to the database buffer
pool and to the WAL. ROLLBACK marks those changes as invalid (writes a
rollback WAL record). VACUUM later cleans up the dead tuples.
ROLLBACK does not mean "data was never touched" - it means "the logical
state is as if the changes never happened."

---

### ⚖️ Comparison Table

| Mode | Isolation Unit | Rollback on Error | Use Case |
|---|---|---|---|
| Auto-commit | Per statement | Not possible | Simple reads/single writes |
| Explicit transaction | Multi-statement | Possible | Multi-step operations |
| @Transactional (Spring) | Method boundary | Automatic on RuntimeException | Service-layer operations |
| JPA UnitOfWork | EntityManager session | flush() or clear() | ORM-managed entities |

---

### 🏛️ System Design

*(Omit: L2 keyword - distributed transactions are covered in L5 Architecture Decisions)*

---

### 📊 Diagram

*(Omit: transaction state machine illustrated in ASCII above)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Spring @Transactional not rolling back on checked exception**

Symptom: code throws a checked exception inside `@Transactional`; changes
are committed despite the error.

Cause: by default, Spring rolls back only on RuntimeException and Error,
not checked exceptions.

Fix:
```java
@Transactional(rollbackFor = Exception.class)
```

> **Code walkthrough:** This single-annotation change fixes the most common Spring transaction bug: checked exceptions not triggering rollback. By default, Spring's transaction proxy only rolls back on RuntimeException and Error - checked exceptions are rethrown with changes committed, which is almost never the intended behavior in a service method. Setting `rollbackFor = Exception.class` makes the proxy intercept all Throwable subtypes and issue ROLLBACK before rethrowing. Use `noRollbackFor` when a specific checked exception represents an expected business condition that should not roll back (for example, a validation exception that should commit audit logs).

Or rethrow as an unchecked exception:
```java
catch (CheckedException e) {
    throw new RuntimeException("Unexpected error", e);
}
```

> **Code walkthrough:** Wrapping a checked exception as RuntimeException triggers Spring's default rollback behavior without modifying the `@Transactional` annotation. The original exception is preserved as the cause, so stack traces remain complete for debugging. This pattern is appropriate when the checked exception signals a programming error rather than an expected recoverable condition - it communicates 'this should never happen in correct code'. The trade-off is that callers lose the ability to `catch (CheckedException e)` specifically; they must handle RuntimeException or let it propagate. Prefer `rollbackFor` on the annotation when you want to be explicit; use wrapping only when the exception truly is unexpected.

**Failure: Transaction committed in aborted state (PostgreSQL)**

Symptom: `ERROR: current transaction is aborted, commands ignored until
end of transaction block`.

Cause: an error occurred in the transaction, putting it in ABORTED state.
Subsequent SQL was attempted without first rolling back.

Fix: always catch errors and issue `ROLLBACK` before retrying:
```sql
ROLLBACK;  -- clears the aborted state
-- Now start a new transaction
BEGIN;
...
```

> **Code walkthrough:** This two-step recovery pattern clears PostgreSQL's ABORTED state before retrying. Once any error occurs inside a transaction, PostgreSQL enters ABORTED state and rejects every subsequent statement with 'current transaction is aborted, commands ignored until end of transaction block' - no matter how simple the next query is. `ROLLBACK` is the only accepted command; it releases all locks and returns the connection to a clean state. Application connection pools must call rollback automatically when they detect or return a connection in ABORTED state, otherwise the next operation on that connection will fail with the same error cascade.

---

### 🎯 Interview Deep-Dive

**[JUNIOR] Q1 - [TRADE-OFF] What is the difference between auto-commit and explicit transactions in JDBC?**

🗣️ "Auto-commit (default): each call to `executeUpdate()` or `executeQuery()`
is wrapped in its own transaction. The database commits immediately after
each statement. No grouping. Explicit transaction: `conn.setAutoCommit(false)`.
Then execute multiple statements. Finally `conn.commit()` or `conn.rollback()`.
The entire group is one atomic operation. Use explicit transactions for:
any multi-step operation that must be atomic (transfer funds, place order with
inventory decrement), batch inserts (better performance - one commit for
thousands of rows vs. one commit per row). Always call `conn.rollback()` in
the catch block and restore auto-commit mode in finally."

**[JUNIOR] Q2 - [MECHANISM] What is connection pool transaction management and why does it matter?**

🗣️ "Connection pools (HikariCP, c3p0) reuse connections. When a connection
is returned to the pool: any open transaction must be handled. HikariCP:
if a connection is returned with an open transaction (auto-commit=false and
no commit/rollback): HikariCP rolls back the transaction and resets the
connection to auto-commit before returning it to the pool. If the connection
is in an error state (aborted transaction in PostgreSQL): HikariCP detects
this via a validation query and discards the connection. In Spring with
`@Transactional`: Spring's `DataSourceTransactionManager` handles all this -
it begins the transaction before the method, commits or rolls back after,
and returns the connection to the pool in a clean state."

**[JUNIOR] Q3 - [MECHANISM] How does PostgreSQL handle an error mid-transaction?**

🗣️ "In PostgreSQL: once an error occurs in an explicit transaction (BEGIN...),
the transaction enters ABORTED state. All subsequent SQL statements are
rejected with 'ERROR: current transaction is aborted, commands ignored until
end of transaction block.' The transaction can only be exited by ROLLBACK.
Contrast with MySQL: MySQL auto-rollbacks the failed statement and continues
the transaction. PostgreSQL's approach is safer: it prevents the application
from accidentally proceeding after an error with a half-changed state.
To handle errors without rolling back the entire transaction: use SAVEPOINT
and ROLLBACK TO SAVEPOINT to roll back only the failed part."

**[MID] Q4 - [TRADE-OFF] What is the difference between ROLLBACK and ROLLBACK TO SAVEPOINT?**

🗣️ "ROLLBACK (without SAVEPOINT): rolls back all changes made since BEGIN.
The transaction ends. A new transaction must be started with BEGIN.
ROLLBACK TO SAVEPOINT name: rolls back only the changes made since the
savepoint was set. The transaction continues (it is still active). The
savepoint is released but the transaction is not. Use ROLLBACK TO SAVEPOINT
for: partial error handling within a transaction (skip the failed record,
continue with the next), nested operation rollback (try an operation,
if it fails roll back just that part and try an alternative).
In JDBC: `conn.rollback(Savepoint sp)` rolls back to the savepoint;
`conn.releaseSavepoint(sp)` removes the savepoint."

**[MID] Q5 - [MECHANISM] How does implicit transaction mode in frameworks differ from explicit?**

🗣️ "JPA EntityManager: `persist()`, `merge()`, `remove()` queue changes.
No SQL is sent until `flush()` or transaction commit. `flush()` sends
SQL but does not commit. The transaction commits when the `@Transactional`
method returns. If the method throws: the transaction is rolled back and
the queued changes are discarded. This is the 'Unit of Work' pattern:
changes are accumulated in memory and written as a batch.
Explicit JDBC: SQL is sent immediately. `executeUpdate()` fires the SQL.
The difference: with JPA, you can call `merge()` then change the entity
again before commit, and JPA detects all changes in one flush.
With JDBC: each `executeUpdate()` is a separate database round trip."

**[SENIOR] Q6 - [MECHANISM] What is read-only transaction optimization?**

🗣️ "`@Transactional(readOnly = true)` in Spring signals a read-only transaction.
Effects: (1) Spring informs the JPA flush mode - entities are not dirty-checked
on flush (no `SELECT ... FOR UPDATE` for optimistic lock reads). This avoids
the overhead of tracking entity changes. (2) Some databases accept the hint
and skip undo log generation for the transaction. (3) Read replicas: some
load balancers or DataSource wrappers route `readOnly` transactions to a
read replica. Performance gain: significant for read-heavy workloads.
Important: `readOnly = true` does NOT prevent write SQL from executing -
it is a hint, not an enforcement. If you accidentally call a write method
inside a `readOnly` transaction, the write may succeed (or be rejected by the
replica if routed there)."

**[SENIOR] Q7 - [MECHANISM] How do you handle distributed transactions across microservices?**

🗣️ "Two-phase commit (2PC): coordinator asks all services to prepare,
then commits all or aborts all. Problem: blocking protocol - if coordinator
fails between prepare and commit, participants hold locks indefinitely.
Saga pattern (preferred): a sequence of local transactions. Each service
performs its part and publishes an event. If any step fails: compensating
transactions undo previous steps. Two types: (1) Choreography - each service
listens for events and reacts (event-driven); (2) Orchestration - a saga
orchestrator directs each step. Saga provides eventual consistency, not ACID
isolation. For most microservice scenarios: saga is better than 2PC. 2PC
is only appropriate when you control both databases and can accept the
lock contention risk."

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



