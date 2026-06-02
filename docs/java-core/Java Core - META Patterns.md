---
layout: default
title: "Java Core - META Patterns"
parent: "Java Core"
grand_parent: "SK Interview"
nav_order: 17
permalink: /java-core/meta-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Core - META Patterns](#java-core---meta-patterns) | medium |

---

# Java Core - META Patterns

## Java Code Review Mental Model

---

### 🎯 Model Answer

**30 seconds:**
> Code review in Java means checking five dimensions: correctness (does it
> do what it should?), safety (null, concurrency, resource leaks, exceptions),
> design (coupling, naming, abstractions), performance (allocations, O(n) patterns),
> and maintainability (readability, testability). The highest-value checks:
> null handling, resource closing (try-with-resources), thread safety, and
> equals/hashCode consistency.

**3 minutes (Senior):**
> Java code review has a checklist, but the mental model matters more.
> Ask: "What breaks if I pass null, a negative number, an empty list, or
> a list of 10 million elements?" - this is boundary testing in your head.
> Correctness issues: wrong algorithm, off-by-one errors, incorrect condition
> logic, missing edge cases. Safety issues: NullPointerException, unclosed
> resources, race conditions, integer overflow, ClassCastException.
> Design issues: Law of Demeter violations, feature envy, exposed internals,
> inappropriate exception types, missing abstractions. Performance: O(n^2)
> in a loop, unnecessary object creation in hot paths, missing indexes (if
> reviewing data access code).
>
> The Pareto principle applies: 80% of bugs come from 20% of patterns. Learn
> to spot the high-frequency bug families first: null, resources, concurrency.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Java code review - five dimensions: correctness, safety,
design, performance, maintainability. I'll walk through each with examples."

**(2) First principles:** "A code review is a second pair of eyes looking for
what the author assumed was true but isn't. Focus on what the code assumes and
verify those assumptions."

**(3) Bridge:** "Code review is like proofreading a legal contract. You don't
just check grammar (style) - you look for ambiguous clauses (design), missing
conditions (logic), and unenforceable promises (incorrect assumptions)."

---

### 📘 Concept Explanation

**Five-dimension code review checklist:**

```plaintext
1. CORRECTNESS
   - Does the algorithm implement the specification?
   - Off-by-one: < vs <=, 0-based vs 1-based indexing
   - Missing edge cases: empty collections, null input, zero/negative
   - Integer overflow: int arithmetic on large numbers (use long)
   - Floating-point equality: == instead of Math.abs(a-b) < epsilon

2. SAFETY
   - NullPointerException: unguarded dereference of nullable values
   - Resource leaks: streams, connections not in try-with-resources
   - Thread safety: shared mutable state without synchronization
   - Exception handling: swallowed exceptions, wrong exception type
   - Security: SQL injection, deserialization of untrusted data

3. DESIGN
   - Single responsibility: class does too much
   - Information hiding: returning mutable internal collections
   - Naming: unclear names, abbreviations, misleading names
   - Abstraction: implementation details leaking into public API
   - Coupling: direct reference to concrete class instead of interface

4. PERFORMANCE
   - String concatenation in loop (use StringBuilder)
   - Unnecessary object creation (new String(bytes) -> new String(bytes,...
   - Inefficient data structure (LinkedList where ArrayList fits, HashMap without capacity)
   - N+1 query: loading entities in a loop (use JOIN FETCH)
   - Missing cache: repeated expensive computation

5. MAINTAINABILITY
   - Long methods (> 30 lines usually needs splitting)
   - Magic numbers without named constants
   - Untestable code (private static methods, static singletons, System.currentTimeMillis)
   - Missing tests for edge cases
   - Duplication: same logic in two places
```

> **Code walkthrough:** This META Patterns example demonstrates Java Stream pipeline using interface. **KEY MECHANISM:** the stream is lazy - intermediate ops build a pipeline, terminal op drives it. **WHY IT MATTERS:** calling terminal op twice throws IllegalStateException; parallel() on small data adds overhead. **TAKEAWAY: collect() or findFirst() triggers the pipeline; reuse by wrapping in Supplier.**

---

### 💻 Code Example

> **Code walkthrough:** The review of `getUserData` shows the most commonice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> Java safety issues in a realistic method: null dereference, unclosed resources,
> exception swallowing, and type-unsafe access. The fixed version addresses
> each with the standard Java idiom.


```java
// BAD: calling get() without checking presence
Optional<User> user = findUser(id);
String name = user.get().getName(); // NoSuchElementException risk
```

```java
// BAD: multiple code review findings in one method
String getUserData(Long userId) {
    try {
        Connection conn = dataSource.getConnection(); // FINDING 1: not closed
        ResultSet rs = conn.createStatement()
            .executeQuery("SELECT * FROM users WHERE id=" + userId); // FINDING 2: SQL injection
        if (rs.next()) {
            String data = rs.getString("data");
            return data.toUpperCase(); // FINDING 3: data could be null
        }
    } catch (SQLException e) {
        e.printStackTrace(); // FINDING 4: exception swallowed, no rethrow
    }
    return null; // FINDING 5: caller needs null check, no Optional
}

// GOOD: all findings addressed
Optional<String> getUserData(Long userId) {
    Objects.requireNonNull(userId, "userId required"); // FINDING 5: explicit null input

    String sql = "SELECT data FROM users WHERE id = ?"; // FINDING 2: parameterized
    try (Connection conn = dataSource.getConnection(); // FINDING 1: auto-closed
         PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setLong(1, userId);
        try (ResultSet rs = ps.executeQuery()) { // FINDING 1: ResultSet also closed
            if (rs.next()) {
                String data = rs.getString("data");
                return Optional.ofNullable(data) // FINDING 3: null-safe
                    .map(String::toUpperCase);
            }
            return Optional.empty();
        }
    } catch (SQLException e) {
        throw new DataAccessException("Failed to fetch user " + userId, e); // FINDING 4: rethrow
    }
}

// Code review red flags checklist:
// - "catch (Exception e) { e.printStackTrace(); }" -> always a FAIL
// - "return null" from methods returning collections -> return empty instead
// - ".equals()" on possibly-null value -> NPE waiting to happen
// - "new ArrayList(list)" inside a loop -> O(n^2) copy
// - synchronized method with long I/O -> lock held too long
// - "static mutable field" -> global state / threading issues
```

> **Code walkthrough:** The fixed version uses try-with-resources for allice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> resources (Connection, PreparedStatement, ResultSet - each is `AutoCloseable`).
> PreparedStatement prevents SQL injection (parameterized query). `Optional<String>`
> makes the absent case explicit in the type system. The `DataAccessException`
> wraps the technical exception with context (which userId) and propagates
> to the caller. This pattern covers 90% of common Java data access review
> findings in one example.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Check for: nulls (use Objects.requireNonNull for parameters), try-with-resources
> for any AutoCloseable, equals/hashCode together, proper exception handling
> (no swallowing). Use static analysis tools: SpotBugs, Checkstyle, SonarQube
> to catch common patterns automatically before human review.

---

**Senior / Staff (5+ years):**
> Go beyond syntax: review for thread safety (any shared mutable state? any
> race condition if this runs concurrently?), backward compatibility (is this
> a library method? are callers depending on this signature?), failure modes
> (what happens if the database is down? if the network is slow? if the input
> is 10 million items?). The highest-value reviews challenge assumptions:
> "you assume this list is always small - is that guaranteed?" A 30-line method
> that's clear but has a hidden race condition is worse than a 100-line method
> that's verbose but correct. Correctness > conciseness.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Style issues are the most important in a code review."**
Style is the lowest-value review category. Automated tools (Checkstyle,
SpotBugs, Google Java Format) should handle style before human review.
Human reviewers should focus on: correctness, safety, and design issues
that tools cannot detect. A code review that spends 80% of comments on
variable naming and spacing and misses a race condition has failed.

**Misconception 2: "More code comments = better code."**
Comments that explain WHAT the code does are noise (the code shows what it
does). Comments that explain WHY are valuable (business rule, non-obvious
constraint). Best documentation: clear naming and small methods that are
self-evident. Aim for code that doesn't need comments; write comments only
for non-obvious trade-offs, workarounds, or domain knowledge.

---

### 🚨 Failure Modes and Diagnosis

**Failure: equals() without hashCode() - breaks HashMap, HashSet behavior.**
```java
// BAD: equals() without hashCode()
class User {
    String email;

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof User u)) return false;
        return email.equals(u.email); // logical equality by email
    }
    // hashCode() NOT overridden -> uses Object.hashCode() (identity-based)
}

// Symptom:
Set<User> users = new HashSet<>();
users.add(new User("alice@example.com"));
users.contains(new User("alice@example.com")); // FALSE! Different hash codes!
// HashSet checks hashCode first -> different hash -> different bucket -> not found!

// Fix:
@Override
public int hashCode() {
    return Objects.hash(email); // must use same fields as equals
}
// Rule: if a.equals(b), then a.hashCode() == b.hashCode() (REQUIRED by contract)

// Diagnostic: add to code review checklist:
// "Whenever equals() is overridden, hashCode() must also be overridden."
// IDE will warn: "equals() but not hashCode()" via IntelliJ inspection
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **WHAT BREAKS: document thread-safety guarantees on every shared mutable class.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Top 5 Java code review issues | 2 minutes |
| null handling strategies | 2 minutes |
| Resource leak detection | 2 minutes |
| Thread safety review | 2-3 minutes |
| equals/hashCode contract | 2 minutes |
| Exception handling patterns | 2 minutes |
| Design smell detection | 2 minutes |

---

**Q1 (Top 5 issues): What are the top 5 Java code review findings?**

A:
1. **NullPointerException risk:** dereferencing a value that could be null
   without checking. Fix: `Objects.requireNonNull` for required parameters,
   `Optional<T>` for optional returns
2. **Unclosed resources:** connections, streams, files not in try-with-resources
   Fix: `try (var conn = ...; var stmt = ...) { }`
3. **Exception swallowing:** `catch (Exception e) { e.printStackTrace(); }` - error lost
   Fix: rethrow as domain exception with context
4. **Shared mutable state without synchronization:** concurrent access without
   `synchronized`, `volatile`, or concurrent collection
5. **equals/hashCode inconsistency:** `equals()` overridden but `hashCode()` not,
   breaking all hash-based collections

*What separates good from great:* These five patterns account for the majority
of Java bugs in production. Static analysis tools (SpotBugs for null/resource,
Checkstyle for style, PMD for complexity, SonarQube combines all) automate
detection. The remaining high-value manual check: logic errors and race conditions
that require understanding the application context.

---

**Q2 (Thread safety review): How do you review code for thread safety?**

A:
```java
// RED FLAGS in code review:
// 1. Non-final mutable static field
static Map<String, User> cache = new HashMap<>(); // NOT thread-safe!
// Fix: ConcurrentHashMap, or lock-protected access, or immutable + reference swap

// 2. Compound check-then-act without atomicity
if (!cache.containsKey(key)) {  // check
    cache.put(key, load(key));  // act
    // Another thread may add key between check and act -> lost update!
}
// Fix: ConcurrentHashMap.computeIfAbsent(key, k -> load(k))

// 3. Iterator over shared collection
for (User u : sharedList) { ... } // ConcurrentModificationException!
// Fix: CopyOnWriteArrayList, synchronized block, or stream on snapshot

// 4. Reading a long or double without volatile/synchronized
long counter; // non-atomic on 32-bit JVM (two 32-bit writes)
// Fix: AtomicLong, or volatile (for visibility without atomicity)

// 5. Double-checked locking without volatile
static MyClass instance; // NOT volatile: broken DCL
if (instance == null) {
    synchronized (MyClass.class) {
        if (instance == null) instance = new MyClass(); // may publish partially constructed!
    }
}
// Fix: volatile instance, or class holder idiom, or enum singleton
```

> **Code walkthrough:** This Unknown example demonstrates mutex locking using SQL. **KEY MECHANISM:** the JVM acquires the intrinsic lock on the object monitor before entering the block. **WHY IT MATTERS:** a thread holding the lock blocks all other threads - a bottleneck at scale. **TAKEAWAY: prefer ReentrantLock or ConcurrentHashMap over synchronized for hot paths.**

*What separates good from great:* Thread safety bugs are notoriously hard
to reproduce (intermittent, timing-dependent). The review strategy: look for
SHARED + MUTABLE state. Single-threaded code is safe by definition. Immutable
shared state is safe by definition. The only risky combination: shared +
mutable + no synchronization. When reviewing: ask "can two threads access
this field simultaneously?" If yes: is it properly protected?

---

**Q3 (Resource leaks): How do you identify and fix resource leaks?**

A:
```java
// All java.io.Closeable and java.lang.AutoCloseable should be in try-with-resources

// Connection: expensive, limited pool (will exhaust!)
Connection conn = dataSource.getConnection();
// ... if exception thrown above, conn never closed!

// Stream: file descriptor leak (OS limit ~65536 open files per process)
InputStream in = Files.newInputStream(path);
// ... if exception, file descriptor leaked!

// Correct pattern (try-with-resources handles close + exception):
try (Connection conn = dataSource.getConnection();
     InputStream in = Files.newInputStream(path)) {
    // use resources
} // auto-closed in reverse order, even on exception

// Java 9: effectively final variable in try-with-resources
InputStream in = getInputStream();
try (in) { // reuse existing variable (Java 9+)
    // use in
}

// Static analysis: SpotBugs rule OBL_UNSATISFIED_OBLIGATION
// Finds: Closeable created but not closed on all exit paths
// Run: spotbugs -textui -high myapp.jar

// Less obvious leak: thread pools, scheduled executors
ExecutorService exec = Executors.newFixedThreadPool(4);
// ... if exception: executor threads run forever! JVM never exits
// Fix: exec.shutdown() in finally or use try-with-resources (ExecutorService
// is Closeable in Java 19+ via AutoCloseable)
```

> **Code walkthrough:** This Unknown example demonstrates thread pool management using thread pool. **KEY MECHANISM:** the pool maintains a work queue; submitted tasks block until a thread is free. **WHY IT MATTERS:** unconfigured pool sizes exhaust threads under load or waste memory at rest. **TAKEAWAY: always name threads and bound queue size to detect saturation.**

*What separates good from great:* Connection pool exhaustion is the most
common resource leak symptom in production. The log shows: "Timeout waiting
for connection from pool" - application hangs, not crashes. The root cause:
a code path that throws an exception before the connection is closed, returning
it to the pool. With 10 threads each leaking one connection: pool of 10 = fully
exhausted after 10 requests. Diagnosis: `connection.pool.size` metric drops
steadily (or JMX pool stats). Fix: always try-with-resources, or at minimum
`finally { conn.close(); }`.

---

**Q4 (Design smells): What design smells do you look for in Java review?**

A:
```java
// 1. Law of Demeter violation (call chain)
order.getCustomer().getAddress().getCity(); // "train wreck"
// Fix: order.getShippingCity() or order.getCustomer().shippingCity()
// Reason: change to Customer.getAddress() breaks all callers of the chain

// 2. Feature Envy: method uses another object's data more than its own
class OrderValidator {
    boolean isValid(Order order) {
        // Uses all Customer fields, none of Order fields:
        return order.getCustomer().getAge() >= 18
            && order.getCustomer().getCountry().equals("US")
            && !order.getCustomer().isBlacklisted();
        // This logic BELONGS in Customer
    }
}
// Fix: move to Customer.isEligibleToOrder()

// 3. Returning mutable internal state
class Registry {
    private final Map<String, User> users = new HashMap<>();
    public Map<String, User> getUsers() { return users; } // BAD: caller can mutate!
    // Fix: return Collections.unmodifiableMap(users) or Map.copyOf(users)
}

// 4. Boolean parameter (splits two behaviors into one method)
void processOrder(Order order, boolean urgent);
// What does true mean? urgent? expedited? priority? rush?
// Fix: two methods (processOrder, processUrgentOrder)
// or: processOrder(Order, OrderPriority priority) with enum

// 5. Overly broad exception catch:
catch (Exception e) { // catches NPE, OutOfMemoryError, etc.
    log.warn("Something failed", e); // hides bugs silently
}
// Fix: catch specific exceptions; let unexpected exceptions propagate
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **WHAT BREAKS: log or rethrow every exception; empty catch blocks are defects.**

*What separates good from great:* Design smell detection requires context.
Not every long method or large class is a problem: a 100-line method in a
utility class with clear local variables may be more readable than 5 extracted
single-line methods with opaque names. Code review is not about mechanically
applying rules but asking: "Is this code as clear and correct as it can be
given the constraints?" The best reviewers ask questions: "Why did you choose
this approach? Did you consider X?" rather than mandating changes.

---

**Q5 (Security review): What security issues do you look for in Java review?**

A:
```java
// SQL Injection: always parameterized queries
String sql = "SELECT * FROM users WHERE email = '" + email + "'";
// email = "' OR '1'='1" -> returns all users!
// Fix: PreparedStatement with ? placeholder

// Path traversal: user input used in file paths
File f = new File("/data/uploads/" + filename);
// filename = "../../../etc/passwd" -> directory traversal!
// Fix:
Path safe = Path.of("/data/uploads").resolve(filename).normalize();
if (!safe.startsWith("/data/uploads"))
    throw new SecurityException("Path traversal attempt: " + filename);

// Deserialization: never deserialize untrusted data
ObjectInputStream ois = new ObjectInputStream(untrustedStream);
Object obj = ois.readObject(); // code execution gadget chains!
// Fix: use ObjectInputFilter, or avoid Java serialization for untrusted input

// Logging sensitive data:
log.info("User logged in: email={}, password={}", email, password); // BAD!
// Fix: never log passwords, tokens, PII
log.info("User logged in: email={}", email); // OK

// Random number generation for security:
Random r = new Random(); // NOT cryptographically secure
r.nextInt(100); // predictable with known seed
// Fix: SecureRandom for tokens, passwords, nonces:
SecureRandom sr = new SecureRandom();
byte[] token = new byte[32];
sr.nextBytes(token); // cryptographically random
String tokenHex = HexFormat.of().formatHex(token); // 64-char hex token
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates Java Stream pipeline using SQL. **KEY MECHANISM:** the stream is lazy - intermediate ops build a pipeline, terminal op drives it. **WHY IT MATTERS:** calling terminal op twice throws IllegalStateException; parallel() on small data adds overhead. **WHAT BREAKS: collect() or findFirst() triggers the pipeline; reuse by wrapping in Supplier.**

*What separates good from great:* Security review is the highest-risk review
dimension. A single SQL injection can exfiltrate the entire database. A single
path traversal can read server credentials. The OWASP Top 10 is the checklist:
injection, broken authentication, XSS, insecure deserialization, security
misconfiguration. In Java: SQL injection is #1 (PreparedStatement always),
insecure deserialization is #2 (avoid Java serialization for external input),
path traversal is #3 (normalize + prefix check). Automated tools: OWASP
Dependency-Check (vulnerable dependencies), SonarQube security rules,
Semgrep rules for Java security patterns.

---

**Q6 (Exception review): What exception handling patterns are correct?**

A:
```java
// ANTI-PATTERN 1: swallow exceptions
try { doWork(); }
catch (Exception e) { } // silent failure - hides bugs, debugging nightmare

// ANTI-PATTERN 2: log and rethrow (double-logging)
catch (Exception e) {
    log.error("Error", e);
    throw e; // logs here AND in the caller: duplicate stack trace in logs
}
// Fix: log OR throw, not both (unless at the top-level boundary handler)

// ANTI-PATTERN 3: wrap and lose context
catch (SQLException e) {
    throw new RuntimeException("Database error"); // lost: which SQL, which params
}
// Fix: include context:
throw new DataAccessException("Failed to fetch user " + userId, e);

// CORRECT: wrap with context, don't re-log
catch (IOException e) {
    throw new ServiceException("Failed to read config from " + path, e);
}
// One place logs at the boundary (REST controller, message consumer, etc.)

// CORRECT: handling specific recoverable cases
try {
    return cache.get(key);
} catch (CacheException e) {
    log.warn("Cache miss for {}: {}", key, e.getMessage());
    return loadFromDatabase(key); // specific recovery action
}

// CORRECT: finally for cleanup (when not using try-with-resources)
try { doWork(); }
finally { cleanup(); } // always runs: normal AND exception paths
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using Kafka messaging. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

*What separates good from great:* Exception handling strategy should be
defined at the architecture level, not method by method. The "log at the
boundary" pattern: lower-level methods throw checked or unchecked exceptions
with context. The top-level handler (Spring's `@ExceptionHandler`,
Kafka consumer error handler, main method) logs the full stack trace once
and returns an appropriate error response. This produces one log entry per
error (not duplicate stack traces from log-and-rethrow). The MDC (Mapped
Diagnostic Context) in log4j/logback adds correlation IDs: every log line
for a request includes `requestId=abc123`, making distributed tracing easier.

---

**Q7 (Immutability review): How do you review for mutability issues?**

A:
```java
// REVIEW: is this object safely shared?

// FAIL: mutable class fields exposed
class Config {
    public List<String> allowedHosts; // mutable, public!
    // Any caller can: config.allowedHosts.add("evil.com")
}

// FAIL: returning mutable copy reference
class SecurityConfig {
    private List<String> allowedHosts = new ArrayList<>();
    public List<String> getAllowedHosts() {
        return allowedHosts; // caller can mutate!
    }
}

// PASS: defensive copy on return
public List<String> getAllowedHosts() {
    return List.copyOf(allowedHosts); // unmodifiable snapshot
}

// PASS: immutable from construction
class SecurityConfig {
    private final List<String> allowedHosts;
    SecurityConfig(List<String> hosts) {
        this.allowedHosts = List.copyOf(hosts); // copy + immutable
    }
    public List<String> getAllowedHosts() {
        return allowedHosts; // already immutable, safe to return directly
    }
}

// REVIEW checklist for mutability:
// - final on all fields? (can't reassign, but doesn't prevent mutation of objects)
// - mutable fields (List, Map, Date, byte[]) -> defensive copy on input and output?
// - Is this class used as a HashMap key? -> must be immutable (hashCode must be stable)
// - Is this class used across threads? -> must be thread-safe (immutable or synchronized)
```

> **Code walkthrough:** This Unknown example demonstrates mutex locking using coice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Immutability review is about anticipating
where sharing goes wrong. A `List<String>` field that's never shared across
threads and is always replaced wholesale (not mutated) is fine as mutable.
A `List<String>` field that's accessed concurrently or returned to callers
who might modify it needs to be immutable. The review question: "Who holds a
reference to this, and could any of them modify it?" If the answer is
"multiple callers in different threads," the class must be immutable or
properly synchronized.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: code review mental model is conceptual, not visual)*

---

---

## Java Version Upgrade Decision Framework

---

### 🎯 Model Answer

**30 seconds:**
> Java version upgrades follow a decision framework: first, LTS versions only
> (8, 11, 17, 21) for production - never non-LTS for long-running apps.
> Second, assess compatibility: does everything compile? (source compatibility),
> do existing .class files run? (binary compatibility), does behavior change?
> (semantic compatibility). Third: test with migration tools (`--release` flag,
> jdeps, jlink). Fourth: incremental adoption (compile with Java 17, run on
> Java 11, add Java 17 features gradually). LTS support: 8 (extended), 11
> (extended), 17 (until 2029), 21 (until 2031).

**3 minutes (Senior):**
> The version upgrade decision has two axes: WHEN (LTS timing) and HOW MUCH
> (how many Java features to adopt). LTS cadence: every 2 years since Java 17
> (17, 21, 25). Companies typically stay on LTS N-1 until N has 6+ months of
> proven stability and their ecosystem (frameworks, libraries, tools) is
> compatible.
>
> Java 11 to 17 changes: modules (JEP 261), removed APIs (Nashorn, CORBA,
> sun.misc.BASE64Encoder), new features (records, sealed classes, text blocks,
> pattern matching instanceof, switch expressions). Java 17 to 21: virtual
> threads (JEP 444), sequenced collections, record patterns, switch pattern
> matching GA.
>
> Migration blockers: reflection into JDK internals (modules block this),
> removed APIs (replaced in later versions or via third-party), bytecode
> instrumentation agents (need updating for new bytecode instructions),
> GraalVM native (closed-world constraint requires explicit config).

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Java version upgrade - LTS-only strategy, compatibility
assessment, migration tools (jdeps, jlink, --release flag), common blockers
(modules, removed APIs), and incremental adoption approach."

**(2) First principles:** "A version upgrade is a controlled risk: new features
vs compatibility cost. The framework: enumerate compatibility breaks, test
them, fix them, adopt new features gradually."

**(3) Bridge:** "Upgrading Java is like upgrading a building's electrical
system while tenants are inside. Plan during business hours (test in CI),
phase the upgrade (dev -> staging -> production), know what breaks (old
outlets = removed APIs), and have rollback (old JDK available)."

---

### 📘 Concept Explanation

**LTS Release Timeline:**
```plaintext
Java 8  (2014) - Extended support 2030 (Oracle) / 2026 (community)
Java 11 (2018) - Extended support 2026 (Oracle) / 2024 (community)
Java 17 (2021) - Extended support 2029 (Oracle) / 2027 (community)
Java 21 (2023) - Extended support 2031 (Oracle) / 2029 (community)
Java 25 (2025) - Next LTS, GA September 2025

Non-LTS (skip for production):
  Java 9, 10, 12, 13, 14, 15, 16, 18, 19, 20, 22, 23, 24

Decision:
  -> Still on Java 8? Plan Java 21 direct (8 -> 21 skip 11, 17)
     or 8 -> 17 -> 21 if step-by-step safer
  -> On Java 11? Upgrade to 17 or 21 next LTS
  -> On Java 17? Upgrade to 21
  -> Always run on latest LTS with active support
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** The migration toolchain uses `jdeps` (dependencyice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> scanner) to find illegal internal API usage, the `--release` flag to enforce
> source compatibility, and `jlink` to produce minimal runtime images. Running
> `jdeps --jdk-internals` before upgrading catches the most common migration
> blockers (sun.misc.* access, removed APIs).


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// STEP 1: Check for internal API usage before upgrading
// $ jdeps --jdk-internals --multi-release 17 myapp.jar
// Output:
//   com.example.Foo -> sun.misc.BASE64Encoder (JDK internal API)
//   com.example.Bar -> com.sun.xml.internal.ws.api.* (removed in Java 11)
// Action: replace sun.misc.BASE64Encoder -> java.util.Base64 (Java 8+)

// STEP 2: Compile with target release flag
// $ javac --release 11 --source 11 *.java  <- restricts to Java 11 API only
// This catches accidental use of newer APIs that won't run on Java 11

// STEP 3: Run with illegal access warnings (Java 9-16)
// $ java --illegal-access=warn -jar myapp.jar
// Prints warnings for each reflective access to JDK internals
// In Java 17: --illegal-access removed, access DENIED by default
// -> All warnings from above must be fixed before Java 17

// STEP 4: Add module opens for frameworks that need reflection
// Spring Boot with Java 17 needs:
// --add-opens java.base/java.lang=ALL-UNNAMED  <- for reflection-heavy frameworks
// --add-opens java.base/java.util=ALL-UNNAMED
// Spring Boot 3.x adds these automatically in its Maven/Gradle plugin

// STEP 5: Adopt new features incrementally
// Java 17 adoption:
// BAD: all at once (high risk)
// GOOD: Phase 1: just run on Java 17 (no code changes, just JVM upgrade)
//       Phase 2: use records for new DTOs
//       Phase 3: migrate existing value classes to records
//       Phase 4: adopt sealed classes where appropriate
//       Phase 5: use pattern matching instanceof

// Example: Java 14 instanceof pattern matching (adopted incrementally)
// Before (Java 8-13):
if (obj instanceof String) {
    String s = (String) obj; // redundant cast after instanceof
    process(s.toUpperCase());
}
// After (Java 14+, enabled by default Java 16+):
if (obj instanceof String s) { // pattern matching: cast + bind in one
    process(s.toUpperCase());
}

// Virtual threads (Java 21): drop-in for blocking I/O
// BAD (before Java 21): blocking thread-per-request (1000 threads for 1000 concurrent)
ExecutorService exec = Executors.newFixedThreadPool(200); // hard limit
// GOOD (Java 21): virtual threads (millions of concurrent, tiny overhead)
ExecutorService exec = Executors.newVirtualThreadPerTaskExecutor();
// Same blocking code: database calls, HTTP calls still use blocking I/O
// But now 1 physical thread can run thousands of virtual threads
```

> **Code walkthrough:** The `jdeps --jdk-internals` command is the mostice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> important pre-upgrade step: it reveals direct dependencies on JDK internal
> APIs that are blocked in Java 17+. The `--add-opens` flags are the migration
> bridge: they re-enable reflective access for frameworks that haven't updated
> yet, while you work on framework upgrades. Virtual threads in Java 21 are
> the biggest performance upgrade: a blocking HTTP call that held a thread
> for 200ms now holds a virtual thread (stackless, <1KB overhead) instead
> of a platform thread (1MB stack, OS context switch). Application throughput
> scales with the number of I/O-bound operations, not thread count.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Use LTS versions only (17 or 21). Run `jdeps --jdk-internals` to find
> migration blockers. Add `--add-opens` for framework compatibility. Adopt
> new features (records, text blocks, pattern matching) incrementally, not
> all at once. Verify with test suite at each step.

---

**Senior / Staff (5+ years):**
> Version upgrade decisions are ecosystem decisions, not just JVM decisions.
> Verify: Spring Boot version (Spring Boot 3 requires Java 17+), Hibernate 6
> (Java 11+), Kafka client (Java 11+), Jackson (Java 8+, fully Java 17),
> and all third-party libraries via `mvn dependency:tree | jdeps` analysis.
> The Java 17 migration is the most common current challenge: `--illegal-access`
> removals affect many older libraries (PowerMock, older Mockito, some XML
> libraries). Java 21 adds virtual threads - consider migrating blocking
> thread-per-request to virtual thread executor (one line change with dramatic
> throughput improvement for I/O-bound services).

---

### ⚠️ Common Misconceptions

**Misconception 1: "I can upgrade from Java 8 directly to Java 21 without issues."**
Direct 8 -> 21 is POSSIBLE but requires careful testing. Known issues:
(1) modules: `--add-opens` needed for reflection; (2) removed APIs (Nashorn
JS engine removed in Java 15, CORBA removed in Java 11); (3) behavior changes
in standard library (some hashCode and toString behaviors changed); (4) GC
defaults changed (G1 is default since Java 9, was Parallel GC in Java 8).
Use the `--release 8` flag to compile with Java 8 API constraints but run
on Java 21 JVM - lowest friction first step.

**Misconception 2: "Virtual threads (Java 21) speed up CPU-bound work."**
Virtual threads are ONLY beneficial for BLOCKING I/O: waiting for database
queries, HTTP calls, file I/O. For CPU-bound work (intensive calculations,
image processing), virtual threads offer zero benefit - they still need a
physical thread to execute. Increasing virtual thread count on CPU-bound work
causes more context switching (same cores, more threads = more overhead).
For CPU-bound: use `ForkJoinPool` or `parallelStream()` which is optimized
for parallel CPU work.

---

### 🚨 Failure Modes and Diagnosis

**Failure: IllegalAccessError after Java 17 upgrade - modules block reflection.**
```
Symptom: java.lang.reflect.InaccessibleObjectException:
  Unable to make field private final int java.lang.String.hash accessible

Cause: Java 17 strong encapsulation:
  - Reflective access to non-public JDK members DENIED by default
  - Previously: just a warning (--illegal-access=warn)
  - Java 17: illegal access = exception

Diagnosis:
  1. Check stack trace: which field/class is being accessed?
  2. Which library is doing it? (PowerMock, old Mockito, old serialization lib)
  3. Check library version: was it updated for Java 17 compatibility?

Fix options (in order of preference):
  1. Update the library to a Java 17-compatible version
  2. Add --add-opens: JVM flag opens the specific package
     --add-opens java.base/java.lang=ALL-UNNAMED
     --add-opens java.base/java.util=ALL-UNNAMED
  3. Replace the library with one that doesn't use reflection into JDK internals

Spring Boot 3 fix: move to Spring Boot 3.x (auto-handles --add-opens)
Mockito fix: Mockito 5+ is Java 17 compatible (uses Byte Buddy, not reflection)
PowerMock: ABANDONED, no Java 17 support -> migrate to Mockito 5 + @Spy
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using SQL. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| LTS version strategy | 2 minutes |
| Java 8 to 17 migration path | 2 minutes |
| jdeps and migration tools | 2 minutes |
| Module system impact | 2 minutes |
| Virtual threads value | 2 minutes |
| Records and sealed classes value | 2 minutes |
| GC changes across versions | 90 seconds |

---

**Q1 (LTS strategy): Which Java versions should production applications use?**

A: Production: LTS versions only. Current LTS: 8, 11, 17, 21.
New projects: Java 21 (longest supported, virtual threads, records, sealed classes GA).
Migration projects: Java 17 (if 21 not yet validated in ecosystem) or directly 21.
Security patches: always stay on latest patch version of your LTS (21.0.4, etc.).
Non-LTS (9, 10, 12-16, 18-20, 22-24): only for experimentation or preview features.
Support lifetime: Oracle LTS = 8 years from GA (17 until 2029, 21 until 2031).

*What separates good from great:* LTS choices also depend on vendor support.
Oracle JDK LTS: commercial (fee-based for some use cases). OpenJDK: free, but
community LTS varies. Alternative distributions: Adoptium (Eclipse Temurin),
Amazon Corretto, Microsoft OpenJDK, Azul Zulu - all LTS binary-compatible,
free for production. Most enterprises use Temurin or Corretto. Decision:
choose a distribution with a clear LTS commitment matching your support window.

---

**Q2 (Java 21 features): What are the key features in Java 21 for production?**

A:
1. **Virtual Threads (JEP 444):** Project Loom GA. Replaces thread pools for
   I/O-bound services. Same blocking code, 1000x more concurrent I/O capacity.
2. **Record Patterns (JEP 440):** Deconstruct records in pattern matching:
   `if (obj instanceof Point(int x, int y)) { ... }`
3. **Pattern Matching in switch (JEP 441):** Full switch expressions with
   type patterns and guards: `switch(shape) { case Circle c when c.radius > 10 -> ...; }`
4. **Sequenced Collections (JEP 431):** `SequencedCollection`, `SequencedMap` -
   uniform API for first/last element across all ordered collections.
5. **String Templates (Preview in 21, finalized in 23):** `STR."Hello \{name}"`
6. **Unnamed Patterns (Preview in 21):** `case Point(int x, _) ->` (ignore y)

*What separates good from great:* Virtual threads + record patterns + switch
expressions together change how you write Java. Before Java 21: complex
visitor patterns for discriminated unions (manually simulated). After:
sealed interfaces + records + pattern switch = algebraic data types with
exhaustive handling - the same pattern as Kotlin sealed classes or Rust enums.
The convergence: Java is gradually adopting functional programming idioms
(immutable records, sealed types, pattern matching) while maintaining backward
compatibility. This is the "Java maturity" phase: closing the gap with Kotlin
without abandoning the 30 years of Java code.

---

**Q3 (Migration risk): How do you assess and manage Java version upgrade risk?**

A:
```
Risk assessment framework:

LOW RISK (usually safe):
  - Application uses standard Java API (java.util, java.io, java.net)
  - No reflection into JDK internals
  - Dependencies are modern (updated in last 2 years)
  - Good test coverage (>70%)

MEDIUM RISK (needs careful testing):
  - Framework versions: Spring Boot 2 -> 3 (major), Hibernate 5 -> 6 (major)
  - Some use of sun.misc.* or com.sun.* (jdeps will find these)
  - Bytecode instrumentation agents (APM tools)
  - Custom ClassLoaders
  - Security manager usage (removed in Java 17)

HIGH RISK (plan carefully):
  - Large legacy codebase with no tests
  - Dependency on removed APIs (CORBA, Nashorn, JAXB, JAX-WS)
  - Heavy use of internal JDK APIs
  - GraalVM native image (reflection config required)
  - Custom JVM flags that changed semantics

Migration steps:
  1. jdeps --jdk-internals: find internal API usage
  2. mvn dependency:tree | grep: find outdated deps
  3. Compile with --release N: ensure source compatibility
  4. Run tests on new JVM: discover runtime issues
  5. Run with --add-opens: bridge period for frameworks
  6. Update frameworks: Spring Boot 3, Hibernate 6, Mockito 5
  7. Remove --add-opens: confirm everything works without bridge
  8. Adopt new features incrementally
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The most common Java 11 to 17 migration
failure: PowerMock or old Mockito versions that use reflection into JDK
internals for mocking. Java 17 blocks this with no workaround (no
`--add-opens` for all cases). The fix: migrate from PowerMock to Mockito 5
(Byte Buddy-based, Java 17 compatible). This is often a major test refactoring
effort - sometimes weeks. Always audit the testing library stack first when
planning a Java 17 upgrade.

---

**Q4 (Virtual threads): When do virtual threads help and when don't they?**

A:
Virtual threads help when:
- Blocking I/O (database, HTTP calls, file reads) is the bottleneck
- High concurrent request count (thousands of simultaneous requests)
- Migrating from thread-per-request model to scale without rewriting to async

Virtual threads do NOT help when:
- CPU-bound: computation uses CPU fully (no blocking)
- Already using reactive/async code (CompletableFuture, Project Reactor)
- GPU or memory-bound workloads

```java
// Drop-in migration for Tomcat-based Spring Boot:
// application.properties:
// spring.threads.virtual.enabled=true
// -> All request threads become virtual threads
// No code changes in controllers, services, repositories

// Manual executor:
try (var exec = Executors.newVirtualThreadPerTaskExecutor()) {
    List<Future<Result>> futures = new ArrayList<>();
    for (String url : urls) {
        futures.add(exec.submit(() -> fetch(url))); // each blocks a virtual thread
    }
    // Process results...
} // exec.close() waits for all tasks

// Thread-local pitfall:
// ThreadLocal values are per-virtual-thread (works correctly)
// But ThreadLocal use discouraged in virtual threads at scale
// (millions of virtual threads = millions of ThreadLocal entries)
// Use ScopedValue (Java 21 preview, GA in 23) for structured value passing
```

> **Code walkthrough:** This Unknown example demonstrates exception handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

*What separates good from great:* Virtual threads don't eliminate the need
to understand blocking. A virtual thread blocked on a `synchronized` block
(as opposed to `Lock`) pins the carrier platform thread: the platform thread
cannot be reused for other virtual threads. Java 21 issue: synchronized blocks
in the JDK itself and many libraries (HashMap, ArrayList, I/O streams) can pin.
JVM flag to detect pinning: `-Djdk.tracePinnedThreads=full`. Java 24 (JEP 491)
fixes most of these: synchronized blocks no longer pin carrier threads.
Immediate fix for Java 21: replace `synchronized` with `ReentrantLock` in
hot paths.

---

**Q5 (Records adoption): When should you use records vs traditional classes?**

A:
Records are the right choice when:
- The type is a pure data carrier (no complex logic)
- All fields should be required (no optional fields)
- Immutability is desired
- equals/hashCode/toString by field identity is correct


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// GOOD: use record
record UserDto(String name, String email, int age) {} // auto-equals, hashCode, toString

// BAD FIT for record:
// 1. Needs inheritance (records are final)
// 2. Has many optional fields (builder pattern better)
// 3. Needs custom serialization (Hibernate @Entity, some JSON edge cases)
// 4. Needs mutable state (records are immutable by default)

// Records + compact constructor for validation:
record Email(String value) {
    Email {
        Objects.requireNonNull(value, "email required");
        if (!value.contains("@"))
            throw new IllegalArgumentException("Invalid email: " + value);
        value = value.strip().toLowerCase(Locale.ROOT);
    }
}

// Records in switch pattern matching (Java 21):
sealed interface Shape permits Circle, Rectangle {}
record Circle(double radius) implements Shape {}
record Rectangle(double width, double height) implements Shape {}

double area(Shape shape) {
    return switch (shape) {
        case Circle(double r)           -> Math.PI * r * r;
        case Rectangle(double w, double h) -> w * h;
    };
}
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates null-safe value wrapping using interface. **KEY MECHANISM:** Optional.of() throws NPE on null; Optional.ofNullable() wraps null safely. **WHY IT MATTERS:** calling get() without isPresent() check produces NoSuchElementException. **WHAT BREAKS: prefer orElseThrow() with a meaningful message over bare get().**

*What separates good from great:* Records replace 80% of Lombok's `@Data`
use cases natively. The migration: `@Data class Foo { String a; int b; }` ->
`record Foo(String a, int b) {}` is often one line shorter and doesn't need
Lombok on the classpath. Caveats: Hibernate entities cannot be records (need
no-arg constructor, mutable state for proxy generation). Jackson works with
records in 2.12+. Spring's `@ConfigurationProperties` works with records in
Spring Boot 2.6+. The main record limitation: no inheritance hierarchy (records
are final). For "extend me" value types, abstract classes or sealed interfaces
with records as leaves are the pattern.

---

**Q6 (Sequenced collections): What are sequenced collections?**

A: Java 21 added `SequencedCollection`, `SequencedSet`, `SequencedMap` -
interfaces that add first/last access to ordered collections.

```java
// Before Java 21: no uniform API for first/last element
List<String> list = List.of("a", "b", "c");
String first = list.get(0);                    // List: get(0)
String last  = list.get(list.size() - 1);      // List: get(size-1)

Deque<String> deque = new ArrayDeque<>();
String dFirst = deque.peekFirst();             // Deque: peekFirst
String dLast  = deque.peekLast();              // Deque: peekLast

NavigableSet<String> nset = new TreeSet<>();
String nFirst = nset.first();                  // NavigableSet: first()
String nLast  = nset.last();                   // NavigableSet: last()

// After Java 21: uniform API via SequencedCollection
SequencedCollection<String> seq = List.of("a", "b", "c");
String first = seq.getFirst();                 // uniform: getFirst()
String last  = seq.getLast();                  // uniform: getLast()
SequencedCollection<String> reversed = seq.reversed(); // uniform: reversed()
seq.addFirst("z"); // add to front (for mutable collections)

// All these implement SequencedCollection now:
// List, Deque, LinkedHashSet, SortedSet (via NavigableSet)
// LinkedHashMap, TreeMap implement SequencedMap
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* Sequenced collections filled a long-standing
gap. The `Iterable` interface has `iterator()` but no `first()` or `last()`.
This caused every library and application to implement first/last access
differently. Now: `SequencedCollection.getFirst()` is the standard. The most
practical use: `LinkedHashMap.sequencedValues().getLast()` to get the most
recently added entry - common in LRU cache implementations.

---

**Q7 (GC evolution): How have JVM garbage collectors evolved across versions?**

A:
```plaintext
Java 8:  Default GC = Parallel GC (throughput-focused)
         G1 GC available (--XX:+UseG1GC) but not default
Java 9:  Default GC = G1 GC (balances throughput + latency)
Java 11: ZGC available (ultra-low latency, experimental)
         Shenandoah available (Red Hat contribution)
Java 15: ZGC production-ready
         Shenandoah production-ready
Java 21: Generational ZGC (ZGC + generational = better default)
         ZGC default in Java 21 (with generational enabled by default in future)

GC Selection:
  Parallel GC:     max throughput, highest pause times (batch processing)
  G1 GC:           balanced default, <500ms pauses typical (web services)
  ZGC:             sub-ms pauses, slightly lower throughput (latency-sensitive)
  Shenandoah:      similar to ZGC, Red Hat maintained

Migration note:
  Java 8 -> 11: default GC changed to G1 (usually better, rarely worse)
  Java 11 -> 17: GC defaults same, but GC improvements ongoing
  Java 17 -> 21: consider ZGC if latency critical
  Heap sizing:    same rules apply (-Xms, -Xmx) but G1 works better with larger heaps

Diagnosing GC after upgrade:
  -Xlog:gc*:file=gc.log:time,uptime (Java 9+)
  (replaces -XX:+PrintGCDetails in Java 8)
  jcmd <pid> GC.heap_info
  JFR GC events
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The Java 8 to 11 GC default change
(Parallel -> G1) is usually transparent but can cause latency changes in
throughput-optimized applications. Parallel GC: designed for maximum
throughput (few GC pauses but longer when they happen). G1: designed for
predictable pause times (<200ms default target). For batch jobs: Parallel GC
may be faster. For user-facing APIs: G1 is better. After upgrading, always
profile GC with the new version: `jcmd <pid> GC.heap_info` and JFR GC
events before declaring the upgrade successful.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: LTS timeline described adequately in text)*

---

---

## Debugging Java APIs in Production

---

### 🎯 Model Answer

**30 seconds:**
> Production Java debugging uses four main tools: `jstack` (thread dumps
> for deadlocks/hangs), `jmap` (heap dumps for memory issues), `jcmd` (all
> JVM diagnostics), and JFR (Java Flight Recorder, low-overhead continuous
> profiling). For live issues: `jstack <pid>` or kill -3 for thread dump,
> `jcmd <pid> VM.native_memory` for memory breakdown. Never attach a JDWP
> debugger to production (halts all threads on breakpoint). Use remote logging
> and metrics instead.

**3 minutes (Senior):**
> Production debugging is primarily OBSERVABILITY: metrics, logs, traces.
> Debugging tools are for when observability data is insufficient. The
> four-layer model: (1) metrics (Prometheus/Grafana: JVM heap, GC pauses,
> thread count), (2) logs (structured JSON logs with trace IDs, level DEBUG
> enabled only under load), (3) traces (OpenTelemetry spans across services),
> (4) profiling (JFR continuous recording, Async Profiler flame graphs for
> CPU-bound hotspots).
>
> For live issues: thread dump (`jstack`) is safe, returns in milliseconds.
> Heap dump (`jmap -dump:format=b,file=heap.hprof <pid>`) pauses the JVM
> for the dump duration - use `jcmd <pid> GC.heap_info` first for summary.
> JFR is the safest continuous tool: <1% overhead, captures method sampling,
> GC events, I/O, network, lock contention.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Production debugging - I'll cover the toolchain: jstack,
jmap, jcmd, JFR, and the right diagnosis flow for each symptom: high CPU,
memory leak, deadlock, high latency."

**(2) First principles:** "Production debugging = narrow down the hypothesis.
High CPU: profiler shows what code runs. High memory: heap dump shows what
objects live. Deadlock: thread dump shows what each thread waits for. Narrow
the search space systematically."

**(3) Bridge:** "Production debugging is like medical diagnosis: you don't
do every test upfront. Symptoms (CPU%, heap%, latency) guide the diagnostic
tool choice (profiler, heap dump, thread dump). Run the cheapest test first."

---

### 📘 Concept Explanation

**Symptom-to-tool mapping:**
```
High CPU:
  1. jstack <pid> -> which threads are in RUNNABLE state?
  2. top -H -p <pid> -> which native thread uses CPU?
     (map to Java thread via "nid" in thread dump)
  3. JFR method sampling OR async-profiler -> flamegraph of hot methods

Memory increasing / OutOfMemoryError:
  1. jcmd <pid> GC.heap_info -> current heap usage summary
  2. jcmd <pid> VM.native_memory -> native memory breakdown (Java heap vs...
  3. jmap -dump:format=b,file=heap.hprof <pid> -> full heap dump (pauses JVM!)
  4. Eclipse MAT / IntelliJ heap analysis -> find retained sets, leak suspects

Thread dump / Deadlock:
  1. jstack <pid> OR kill -3 <pid> -> thread dump to stdout
  2. Look for "Found one Java-level deadlock" in output
  3. Or: look for threads in BLOCKED state waiting for same lock

High latency / Slow requests:
  1. JFR method profiling: find slow call trees
  2. Async Profiler wall-clock mode: captures blocking time (I/O, lock wait)
  3. Distributed traces (Jaeger, Zipkin): find slow downstream services
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** The JFR diagnostic session covers the most commonice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> production scenario: unexplained latency increase. Recording a 30-second
> JFR snapshot while the symptom is active, then analyzing with JDK Mission
> Control, reveals method hotspots, GC pressure, and lock contention in
> one recording. The async-profiler flame graph is the most actionable output:
> wide bars = time spent, click to drill down.

```java
// SCENARIO: CPU spike in production - diagnosis steps:

// Step 1: Identify hot threads (without stopping the JVM)
// jstack <pid> | grep -A 5 "RUNNABLE" | head -80
// Output shows which Java methods are currently executing

// Step 2: JFR recording (lowest overhead, best info)
// $ jcmd <pid> JFR.start duration=30s settings=default filename=/tmp/app.jfr
// $ jcmd <pid> JFR.check  <- verify recording is active
// Wait 30 seconds, then:
// $ jcmd <pid> JFR.dump filename=/tmp/app.jfr  <- if using continuous mode
// Open in IntelliJ or JDK Mission Control

// Step 3 (if JFR not enough): async-profiler (flame graph)
// $ ./profiler.sh -d 30 -f /tmp/profile.html <pid>  <- 30s CPU profiling
// Opens as interactive SVG flame graph in browser

// Programmatic JFR (in-process recording for diagnostics endpoint):
RecordingConfiguration config = new RecordingConfiguration();
config.setName("production-debug");
config.setDuration(Duration.ofSeconds(30));
config.setDestination(Path.of("/tmp/app.jfr"));
config.setToDisk(true);

try (Recording recording = new Recording(config)) {
    recording.start();
    Thread.sleep(30_000);
    // recording auto-stops and saves at end of try block
}
// Return path to JFR file via internal diagnostics API

// SCENARIO: Memory leak diagnosis

// Step 1: confirm leak (watch heap with JFR or GC logs)
// -Xlog:gc*:file=/var/log/gc.log:time,uptime,level,tags (Java 11+)
// Full GC triggered frequently? Heap grows after GC? = leak.

// Step 2: light-weight object count (no pause)
// $ jcmd <pid> GC.class_histogram | head -30
// Shows: instances, bytes, class name for top 30 by instance count

// Step 3: heap dump (pauses JVM during dump!)
// $ jcmd <pid> GC.heap_dump /tmp/heap.hprof
// Or: add -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/ to JVM startup
// (auto-dumps on OOM before JVM exits - crucial for crash diagnosis)

// Step 4: analyze with Eclipse MAT
// Histogram: what objects exist?
// Dominator tree: what keeps large object graphs alive?
// "Leak suspects" report: often finds the root cause automatically

// Common leak patterns:
// - Cache without eviction (unbounded Map growing forever)
// - EventListener not deregistered (holds reference to listener and its context)
// - ThreadLocal not removed (thread pool reuse causes accumulation)
// - Static Map used as cache (never GC'd, grows with every unique key)
```

> **Code walkthrough:** The `jcmd <pid> GC.class_histogram` is the mostice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> production-safe first step for memory investigation: no JVM pause, output
> in seconds. It answers "what types of objects dominate heap?" before
> committing to a full heap dump (which pauses the JVM for seconds to minutes
> depending on heap size). The `HeapDumpOnOutOfMemoryError` flag is mandatory
> in production: without it, the OOM crash leaves no diagnosis artifact.
> Always add `-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/dumps/`
> to production JVM startup flags.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Use `jstack <pid>` for thread dumps (deadlocks, hangs). Use
> `jcmd <pid> GC.class_histogram` for memory issues (no pause). Add
> `-XX:+HeapDumpOnOutOfMemoryError` to every production JVM. Use JFR for
> CPU profiling. Never use a JDWP debugger in production.

---

**Senior / Staff (5+ years):**
> Production debugging is proactive, not reactive: set up JFR continuous
> recording with a rolling buffer (1-2 minutes, low overhead) so that when
> an incident happens you can dump the last 2 minutes and see what happened
> just before. JVM startup: `-XX:StartFlightRecording=settings=default,disk=true,maxage=2m`.
> Pair with structured logging (JSON, one-line per event, correlation ID on
> every log entry). Observability = metrics + logs + traces + profiling.
> When all four are in place: debugging is diagnosis, not guesswork.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Attaching a debugger to production is fine for short periods."**
JDWP debugger in production halts ALL JVM threads on every breakpoint.
A breakpoint that takes 1 second to inspect: all 200 concurrent users wait 1 second.
This is a production incident caused by the debugging action itself.
Alternatives: add temporary detailed logging (log the values you'd inspect
in a debugger), use conditional log levels (change log level via JMX without restart),
use JFR events (record events with field values, no pause), use bytecode instrumentation
agents (Arthas, Btrace) that inject probe code without breakpoints.

**Misconception 2: "OutOfMemoryError means you need more heap."**
OOM can mean: (1) heap leak (more heap just delays the inevitable),
(2) metaspace leak (too many dynamically generated classes - heap increase
does nothing), (3) off-heap leak (DirectByteBuffer, Netty), (4) heap is
genuinely too small (legitimate fix: increase). Diagnosis: check WHERE the
OOM occurs: `java.lang.OutOfMemoryError: Java heap space` = heap, `java.lang.OutOfMemoryError: Metaspace` = class loading, `java.lang.OutOfMemoryError: Direct buffer memory` = native off-heap. Different diagnoses, different fixes.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Thread deadlock - application hangs, requests time out.**
```plaintext
Symptom: requests timeout, JVM is running (not crashed), CPU near 0%
         Health checks pass but actual work is frozen

Step 1: Take thread dump
  $ jstack <pid>
  OR: kill -3 <pid>  (prints to stdout)
  OR: jcmd <pid> Thread.print

Step 2: Look for deadlock section:
  "Found one Java-level deadlock:"
  "Thread-1: waiting to lock <0x00000006c22a2000> (class Foo)"
  "Thread-2: waiting to lock <0x00000006c22b4100> (class Bar)"
  Thread-1 holds Bar, waits for Foo
  Thread-2 holds Foo, waits for Bar -> DEADLOCK

Step 3: Identify lock order
  Search for the lock addresses in the thread dump
  Find where Thread-1 holds the lock Thread-2 is waiting for

Step 4: Fix
  Option A: establish global lock ordering (always lock A before B)
  Option B: use tryLock with timeout (java.util.concurrent.Lock)
    if (!lockA.tryLock(1, TimeUnit.SECONDS)) { /* retry or fail fast */ }
  Option C: reduce locking scope (hold locks for shorter periods)
  Option D: use optimistic concurrency (ConcurrentHashMap.compute)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Thread dump analysis | 2 minutes |
| Heap dump workflow | 2 minutes |
| JFR usage | 2 minutes |
| OutOfMemoryError diagnosis | 2 minutes |
| Deadlock detection | 2 minutes |
| CPU spike diagnosis | 2 minutes |
| Production observability setup | 2-3 minutes |

---

**Q1 (Thread dump): How do you take and analyze a Java thread dump?**

A:
```
Methods to capture:
  $ jstack <pid>                       <- attach and dump (safe, fast)
  $ jcmd <pid> Thread.print            <- preferred, more info
  $ kill -3 <pid>                      <- prints to JVM stdout (always works)
  JFR Thread events                    <- continuous, lowest overhead
  JMX: ThreadMXBean.dumpAllThreads()   <- programmatic

Thread states (what they mean):
  RUNNABLE:  executing Java code (or waiting for OS resources like I/O)
  BLOCKED:   waiting to acquire a synchronized monitor
  WAITING:   in Object.wait(), Thread.join(), LockSupport.park()
  TIMED_WAITING: in sleep(), wait(timeout), park(timeout)

Analysis:
  1. DEADLOCK: "Found one Java-level deadlock" section
  2. HOT THREADS: many threads in RUNNABLE in the same method = hotspot
  3. STUCK: threads in WAITING/BLOCKED for extended period = lock/resource
  4. POOL exhaustion: all ThreadPool threads BLOCKED waiting for I/O

Thread naming: use meaningful names for debugging
  Thread t = new Thread(work, "payment-processor-1"); // named!
  ExecutorService exec = Executors.newFixedThreadPool(4, r -> {
      Thread t = new Thread(r, "batch-worker-" + counter.incrementAndGet());
      return t;
  });
  // Thread dump shows: "payment-processor-1" not "Thread-42"
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using thread pool. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Thread naming is a production
first-responder technique: when you get a thread dump with 200 threads,
`Thread-42 BLOCKED at ...` tells you nothing. `payment-processor-1 BLOCKED
waiting for database connection` tells you everything. Name threads at the
executor level using a `ThreadFactory`. Spring Boot's task executor auto-names
threads with the `AsyncExecutor` or bean name. The pattern: executor name +
sequential number (`http-nio-8080-exec-1`, `kafka-consumer-0`).

---

**Q2 (Heap analysis): What tools do you use for Java heap analysis?**

A:
1. **`jcmd <pid> GC.class_histogram`:** no pause, shows top classes by
   instance count and bytes. First stop for memory investigation.
2. **`jcmd <pid> GC.heap_dump /tmp/dump.hprof`:** full heap dump, pauses
   JVM during dump (seconds to minutes). Use only when histogram is insufficient.
3. **Eclipse MAT (Memory Analyzer):** open-source, powerful. "Leak Suspects"
   report, dominator tree, OQL (object query language). Best for deep analysis.
4. **IntelliJ built-in heap viewer:** lighter, good for quick inspection
5. **JFR `OldObjectSample` events:** identifies long-lived objects without
   full heap dump (low overhead, continuous)

```plaintext
Heap dump analysis workflow (Eclipse MAT):
  1. Open .hprof file
  2. Run "Leak Suspects" report -> auto-detects common patterns
  3. Check "Dominator Tree" -> which objects retain the most memory?
  4. Check "Histogram" -> which classes have unexpected instance counts?
  5. Path to GC root -> why is this object not garbage collected?

Common findings:
  - Unbounded cache: HashMap with millions of entries, no eviction
  - Session leak: HTTP sessions not invalidated, holding large objects
  - Thread-local leak: ThreadLocal<ByteBuffer> in thread pool, accumulates
  - Classloader leak: webapp redeployment in app server, old ClassLoader retained
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The "path to GC roots" is the key operation
in MAT. A leaked object is leaked because something is holding a reference to
it. "Path to GC root" shows the chain: `StaticField -> HashMap -> ArrayList
-> MyObject`. The chain reveals: there's a static `HashMap` (never GC'd)
that references `ArrayList`s that reference your leaked objects. The fix:
add eviction (Caffeine/Guava cache), or remove the static reference, or
ensure the cache is cleared on application shutdown.

---

**Q3 (JFR profiling): How do you use JFR to diagnose production issues?**

A:
```bash
# Method 1: One-shot recording
jcmd <pid> JFR.start duration=60s settings=profile filename=/tmp/issue.jfr
# Wait 60 seconds, then analyze /tmp/issue.jfr

# Method 2: Continuous recording (always on, rolling buffer)
# Add to JVM startup flags:
-XX:StartFlightRecording=settings=default,disk=true,maxage=5m,dumponexit=true,\
filename=/var/log/jfr/continuous.jfr

# When incident occurs: dump the last 5 minutes
jcmd <pid> JFR.dump filename=/tmp/incident.jfr maxage=5m

# Method 3: Programmatic (diagnostic endpoint)
# FlightRecorder.getFlightRecorder().takeSnapshot()
# -> returns Recording with last N minutes of events
```

> **Code walkthrough:** This -> returns Recording with last N minutes of events example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Key JFR event categories and what they reveal:
```
jdk.MethodSampling       -> hot methods (CPU profiling)
jdk.GCHeapSummary        -> heap usage over time
jdk.JavaMonitorWait      -> thread contention / lock wait
jdk.SocketRead/Write     -> network I/O timing
jdk.FileRead/Write       -> file I/O timing
jdk.ObjectAllocationInNewTLAB -> allocation hotspots
jdk.ThreadSleep          -> where threads are sleeping
jdk.CPULoad              -> CPU usage over time
```

> **Code walkthrough:** This -> returns Recording with last N minutes of events example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The continuous JFR recording setup is the
difference between "we have data" and "we have no idea what happened."
When an OOM crash occurs at 3am, if you have `dumponexit=true` and a pre-OOM
heap dump (`HeapDumpOnOutOfMemoryError`), you have everything needed for
offline diagnosis. Without it: the JVM exits, state is gone, you're debugging
a ghost. The 2-5 minute rolling buffer is the sweet spot: enough history to
capture the lead-up to an incident, low enough overhead (<1%) for continuous
production use.

---

**Q4 (Memory leak patterns): What are the most common Java memory leak patterns?**

A:
```java
// PATTERN 1: Unbounded static cache
class UserCache {
    private static final Map<Long, User> CACHE = new HashMap<>(); // grows forever!

    static User get(Long id) {
        return CACHE.computeIfAbsent(id, UserRepository::findById);
    }
}
// Fix: Caffeine with size or time-based eviction:
static final Cache<Long, User> CACHE = Caffeine.newBuilder()
    .maximumSize(10_000)
    .expireAfterWrite(10, TimeUnit.MINUTES)
    .build();

// PATTERN 2: EventListener not removed
class EventBus {
    List<EventListener> listeners = new ArrayList<>();
    void register(EventListener l) { listeners.add(l); }
    // No deregister! Each registered object held forever
}
// Fix: WeakReference or explicit deregistration:
void deregister(EventListener l) { listeners.remove(l); }
// Or: WeakHashMap<EventListener, Void> listeners = new WeakHashMap<>();
//     (auto-removed when listener has no other references)

// PATTERN 3: ThreadLocal not removed in thread pool
class RequestContext {
    static ThreadLocal<User> CURRENT_USER = new ThreadLocal<>();
}
void handleRequest(User user) {
    RequestContext.CURRENT_USER.set(user);
    // ... handle request ...
    // RequestContext.CURRENT_USER.remove(); // MISSING! Thread reused from pool
    // Next request on same thread: CURRENT_USER still set to previous user!
}
// Fix: always call .remove() in finally:
try {
    RequestContext.CURRENT_USER.set(user);
    handleRequest();
} finally {
    RequestContext.CURRENT_USER.remove(); // ALWAYS clean up
}
```

> **Code walkthrough:** This -> returns Recording with last N minutes of events example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

*What separates good from great:* The ThreadLocal leak is the most insidious:
it's not just a memory leak, it's a data leak between requests. User A's
request context (authentication, tenant ID, permissions) remains on the thread
and is picked up by user B's request if the thread is reused from the pool.
This is a security vulnerability masquerading as a memory leak. Spring Security's
`SecurityContextHolder` uses ThreadLocal and clears it via `SecurityContextPersistenceFilter`
at the end of every request - this is the correct pattern.

---

**Q5 (High CPU): Step-by-step high CPU diagnosis in Java production.**

A:
```bash
# Step 1: confirm Java process is the cause
top                              # identify which PID uses CPU

# Step 2: find which thread inside Java process
top -H -p <java_pid>             # -H = show threads, not just process
# Find the thread with high CPU; note the PID (native thread ID)

# Step 3: convert native thread ID to hex (for thread dump correlation)
printf '%x' <thread_pid>        # e.g., 12345 -> 0x3039

# Step 4: get thread dump and find the thread
jstack <java_pid> | grep "nid=0x3039" -A 20
# Shows: which Java method the hot thread is executing

# Common findings:
# - JVM in GC: "GC Thread" in RUNNABLE = GC is CPU consumer
#   -> Check heap: jcmd <pid> GC.heap_info
#   -> If heap nearly full: OOM imminent, add heap or fix memory issue
# - Application thread in tight loop: find the hot method
#   -> JFR method sampling: which method appears most?
# - JSON/XML parsing hotspot: deserializing massive payloads in tight loop
#   -> Optimize: streaming parse, result caching, async deserialization
# - Regex backtracking (ReDoS): catastrophic regex with adversarial input
#   -> Use timeout: Pattern.CASE_INSENSITIVE + input length check
```

> **Code walkthrough:** This -> Use timeout: Pattern.CASE_INSENSITIVE + input length check example demonstrates shell script pattern using Kafka messaging. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

*What separates good from great:* The native thread ID to hex conversion
is the key link between `top -H` (OS-level thread view) and `jstack` (JVM-level
thread view). `top -H -p <pid>` shows TIDs in decimal; jstack shows thread IDs
as hex in the `nid=0x...` field. Connecting these: `printf '%x' <tid>` converts
to hex. Without this connection, you can see "some thread uses 99% CPU" but
not WHICH Java code it's executing. With the nid link: you find the exact
method in the exact thread within seconds.

---

**Q6 (GC diagnosis): How do you diagnose GC performance issues in production?**

A:
```bash
# Enable GC logging (Java 11+):
-Xlog:gc*:file=/var/log/jvm/gc.log:time,uptime,level,tags:filecount=10,filesize=20m

# Key metrics to monitor:
# - GC pause time: how long does each GC pause the application?
#   Goal: P99 < 100ms for web services
# - GC frequency: how often? (hourly = fine, every 30s = problem)
# - After-GC heap: heap reclaimed? If heap after GC grows -> leak

# JFR GC analysis:
jcmd <pid> JFR.start duration=60s settings=default filename=/tmp/gc.jfr
# Open in Mission Control: "GC" tab shows timeline of GC pauses

# Common GC problems and fixes:
# 1. Promotion failure: old generation fills before young gen GC cleans it
#    Fix: increase old gen size (-Xmx), or reduce allocation rate
# 2. Humongous allocation: objects > 50% region size (G1) -> direct to old gen
#    Fix: reduce object size or increase G1 region size (-XX:G1HeapRegionSize)
# 3. Metaspace OOM: too many classes loaded (class generation, reflection)
#    Fix: -XX:MaxMetaspaceSize=512m, find what generates classes (bytecode gen?)
# 4. GC overhead limit exceeded: >98% time in GC
#    Fix: leak or insufficient heap; heap dump to find leak

# Monitoring setup (Prometheus JVM micrometer):
# jvm_gc_pause_seconds_max
# jvm_memory_used_bytes{area="heap"}
# jvm_gc_live_data_size_bytes (baseline heap after full GC)
```

> **Code walkthrough:** This jvm_gc_live_data_size_bytes (baseline heap after full GC) example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

*What separates good from great:* `jvm_gc_live_data_size_bytes` (or equivalent)
is the most important long-term GC metric. This is the heap required for
"live" data after a full GC - it should be stable over time. If it grows
monotonically over hours/days: you have a memory leak. A common mistake:
monitoring only `jvm_memory_used_bytes` which fluctuates with GC cycles.
The "live data size" is the floor and reveals trends that usage metrics hide.
Rule of thumb: set heap to 2-3x the live data size for adequate GC breathing room.

---

**Q7 (Arthas): How do you use Arthas for live production debugging?**

A: Arthas is a JVM diagnostic tool from Alibaba - attaches to a running JVM
and provides live introspection without code changes or restarts.

```bash
# Download and attach to running JVM:
java -jar arthas-boot.jar <pid>

# Key commands:

# Watch method arguments and return values LIVE:
watch com.example.OrderService createOrder "{params,returnObj}" -x 2
# Output: every call to createOrder shows params and return value

# Trace method call tree with timing:
trace com.example.OrderService createOrder -n 5
# Shows: createOrder -> validateOrder [5ms] -> saveOrder [50ms] -> sendEmail [200ms]
# Immediately shows which sub-method is slow!

# Decompile class at runtime (see what's actually loaded):
jad com.example.OrderService
# Shows: actual bytecode-decompiled Java
# Reveals: is this the version you think it is?

# Monitor method call count and avg time:
monitor com.example.OrderService createOrder -c 5
# Every 5 seconds: count, fail count, avg time, success rate

# Redefine class at runtime (hot reload for debugging):
# 1. Edit the class on your dev machine
# 2. Compile: javac OrderService.java
# 3. retransform /path/to/OrderService.class  (!)
# Changes take effect immediately without restart

# Stack trace who's calling a method:
stack com.example.DatabasePool getConnection
# Shows: full call stack for each getConnection call
# Find: who is calling getConnection without closing it!
```

> **Code walkthrough:** This Find: who is calling getConnection without closing it! example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

*What separates good from great:* Arthas `trace` is the production equivalent
of a profiler for a specific code path: you get the call tree of ONE specific
method with timing, live, in production, without any restart or code change.
Traditional profilers sample all methods; `trace` focuses exactly on the
method you're investigating. The Arthas `watch` command is the replacement
for adding debug logging: instead of deploying a new version with `log.debug("param: " + param)`,
you `watch` the method live and see the values immediately. This is only
safe for diagnostic use: Arthas attaches via JVMTI and has measurable overhead
on the traced methods; disable after diagnosis.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: symptom-to-tool mapping described adequately in Concept Explanation)*

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



