---
layout: default
title: "Java Core - L3 Internals"
parent: "Java Core APIs"
grand_parent: "SK Interview"
nav_order: 5
permalink: /java-core/l3-internals/
---

## Keywords in This File

{: .no_toc }

| #   | Keyword                                                                                                                                      | Weight |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| 1   | [equals and hashCode: The Full Contract and Cache Invalidation Bugs](#equals-and-hashcode-the-full-contract-and-cache-invalidation-bugs)     | high   |
| 2   | [HashMap vs ConcurrentHashMap: Concurrency Safety Guarantees](#hashmap-vs-concurrenthashmap-concurrency-safety-guarantees)                   | high   |
| 3   | [Java Serialization: ObjectOutputStream, Externalizable, Versioning](#java-serialization-objectoutputstream-externalizable-versioning)       | medium |
| 4   | [Java Reflection: Class, Method, Field - Performance and Security Cost](#java-reflection-class-method-field---performance-and-security-cost) | medium |
| 5   | [Java NIO: Channels, Buffers, Selectors, and Non-Blocking I/O](#java-nio-channels-buffers-selectors-and-non-blocking-io)                     | medium |

---

# equals and hashCode: The Full Contract and Cache Invalidation Bugs

**Interview Weight:** high - Appears in nearly every senior interview;
a violation causes silent, intermittent bugs in production.

---

### 🎯 Model Answer

**30 seconds:**

> `equals` and `hashCode` must satisfy a contract: if `a.equals(b)`,
> then `a.hashCode() == b.hashCode()`. The reverse is not required
> (hash collisions are allowed). Violating this breaks HashMap, HashSet,
> and any hash-based collection - entries become lost or duplicated.
> The second rule: `hashCode` must be consistent for the same object
> state. Mutable objects used as map keys break this if the fields
> used in `hashCode` are modified after insertion.

**3 minutes (Senior):**

> The full `equals` contract (from `Object.equals` Javadoc):
> (1) Reflexive: `a.equals(a)` is true. (2) Symmetric: `a.equals(b)`
> iff `b.equals(a)`. (3) Transitive: if `a.equals(b)` and `b.equals(c)`,
> then `a.equals(c)`. (4) Consistent: repeated calls return same result
> without object modification. (5) Null-safe: `a.equals(null)` is false.
>
> The `hashCode` contract adds: (6) Consistent with object state
> (same hash for same fields). (7) If `equals` returns true, hashCodes
> must be equal. Rule 7 is what breaks hash collections when violated.
>
> Cache invalidation bug: a mutable object is inserted as a map key.
> Later, the fields used in `hashCode` are modified. The bucket index
> (computed from hashCode) changes. The entry is stored in the old
> bucket but lookup computes the new bucket - the entry is "lost" to
> the map. The map still holds the entry (it's there, just in the wrong
> bucket) but `get(key)` returns null. This is a classic silent data loss bug.
>
> Modern approach: use Java records (Java 14+) or `@Override` both
> methods based on the same fields. Prefer immutable fields in map keys.

**Framework:** CONTRACT (7 rules) + CACHE-INVALIDATION-BUG (mutable keys)

- IMPLEMENTATION (fields to use, records)

_Adapting up:_ Discuss `Objects.hash()` vs `Objects.hashCode()`,
hash caching in `String` (lazy, correct for immutable), and why
`hashCode` should return different values for different objects
(collision avoidance).

_Adapting down:_ If `a.equals(b)` then `a.hashCode() == b.hashCode()`.
Override both or neither. Never use mutable objects as map keys.

**Blank Mind Recovery:**

**(1) Restate:** "equals and hashCode contract: equals true implies
same hash. Violation breaks HashMap. Mutable keys: hash changes after
insert = entry lost in wrong bucket."

**(2) First principles:** "HashMap uses hashCode to find the bucket,
equals to find the entry. If equals says 'same key' but hashCode sends
you to different buckets, you'll never find the entry."

**(3) Bridge:** "hashCode is the zip code, equals is the name on the
mailbox. If two people are the same (equals), they must have the same
zip code (hashCode). If their zip code changes after they moved in,
the mailman can't find their mail (cache invalidation)."

---

### 📘 Concept Explanation

**The full contract:**

```
equals contract (java.lang.Object Javadoc):
  1. Reflexive:     a.equals(a) == true
  2. Symmetric:     a.equals(b) iff b.equals(a)
  3. Transitive:    a.equals(b) AND b.equals(c) -> a.equals(c)
  4. Consistent:    a.equals(b) returns same value on repeat calls
                    (unless objects are modified)
  5. Non-null:      a.equals(null) == false  (for non-null a)

hashCode contract:
  6. Consistent:    Same object state -> same hashCode (within JVM session)
  7. Equals implies equal hash:
                    a.equals(b) -> a.hashCode() == b.hashCode()

Note: Rule 7 converse is NOT required:
  a.hashCode() == b.hashCode() does NOT mean a.equals(b)
  (this is a hash collision - normal and allowed)
```

**Correct implementation patterns:**

```java
// Pattern 1: Java record (auto-generates correct equals + hashCode)
record Point(int x, int y) {}
// auto-generated:
// equals: true iff both x and y are equal
// hashCode: based on x and y fields

// Pattern 2: Manual implementation (IDE-generated or manual)
public final class Point {
    private final int x;
    private final int y;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Point p)) return false;
        return x == p.x && y == p.y;
    }

    @Override
    public int hashCode() {
        return Objects.hash(x, y); // safe, consistent
    }
}

// Pattern 3: Objects.hash() - convenient but slightly slower
// than manually combining (creates Object[] then hashes)
int h = Objects.hash(field1, field2, field3);

// Pattern 4: Prime-based manual (faster, no array allocation)
int h = 31 * field1.hashCode()
      + 37 * field2.hashCode();
```

**Cache invalidation bug:**

```java
// The bug:
class MutableKey {
    int id;
    MutableKey(int id) { this.id = id; }

    @Override public boolean equals(Object o) {
        return o instanceof MutableKey k && k.id == this.id;
    }
    @Override public int hashCode() { return id; }
}

Map<MutableKey, String> map = new HashMap<>();
MutableKey key = new MutableKey(1);
map.put(key, "value");

// The entry is in bucket: (capacity-1) & hash(1)
key.id = 99; // MUTATION AFTER INSERT - changes hashCode!

// Lookup: computes hash(99) -> different bucket -> not found!
System.out.println(map.get(key)); // null!

// The entry is STILL in the map but unreachable:
System.out.println(map.size()); // 1 - it's there
System.out.println(map.values()); // [value] - still present
```

---

### 💻 Code Example

#### Symmetric violation - a subtle contract break

```java
// BAD: Symmetry violation - extremely subtle
class CaseInsensitiveString {
    private final String s;

    CaseInsensitiveString(String s) {
        this.s = s.toLowerCase();
    }

    @Override public boolean equals(Object o) {
        if (o instanceof CaseInsensitiveString c) {
            return s.equals(c.s);
        }
        // BAD: also accepts plain String!
        if (o instanceof String plain) {
            return s.equals(plain.toLowerCase()); // asymmetric!
        }
        return false;
    }
}

CaseInsensitiveString cis = new CaseInsensitiveString("HELLO");
String regular = "hello";

cis.equals(regular)     // true (by our equals)
regular.equals(cis)     // FALSE - String.equals uses identity class check
// SYMMETRY VIOLATED: cis.equals(regular) != regular.equals(cis)
```

> **Code walkthrough:** The violation is that `cis.equals(regular)` is
> `true` but `regular.equals(cis)` is `false`. This asymmetry breaks
> collections: `Set.contains(regular)` might return `false` even if a
> `CaseInsensitiveString("HELLO")` is in the set, because the set may
> call `regular.equals(cis)` in its bucket search. The fix: never make
> equals "work across types" - a CaseInsensitiveString should only be
> equal to another CaseInsensitiveString.

---

### 🎓 Answers by Seniority

**Junior:** `hashCode` and `equals` must be overridden together.
If two objects are equal, they must have the same hash code. Violating
this breaks HashMap and HashSet.

**Mid-level:** The 7-point contract. The cache invalidation bug: mutable
fields used in `hashCode` must not change after object is used as a
Map key. Use `Objects.hash(fields...)` for multi-field hash computation.
Records auto-generate correct implementations.

**Senior:** The symmetry requirement prevents cross-type equality tricks.
`String.hashCode()` is cached (lazily computed, then stored in a private
field) because String is immutable - the hash can never change. This is
a safe optimization only for immutable types. `Objects.hash(a,b,c)`
creates a temporary `Object[]` - in performance-critical paths, inline
the hash formula instead.

**Staff:** The `hashCode` quality matters for HashMap performance: if
all keys hash to the same bucket (constant hashCode, or all XOR to same
value), HashMap degrades to O(n) lookup (or O(log n) with Java 8
treeification). JDK 21 added identity-based hashCode randomization
(`-XX:+UseIdHashSalting`) as a security measure. For value-type classes,
annotate with `@ValueBased` (Java 16+) to hint the JVM that identity
semantics are not relied upon.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                                         | Reality                                                                                                                           | Danger                                                                        |
| --- | --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| 1   | Overriding `equals` without `hashCode` is fine for most cases         | Any HashMap or HashSet usage will break: equal objects can end up in different buckets - contains/get returns false               | Silent production bug: HashMap `get()` returns null for keys that are present |
| 2   | `Objects.hashCode(a)` is the same as `Objects.hash(a)`                | `Objects.hashCode(a)` is null-safe `a.hashCode()`. `Objects.hash(a)` creates a one-element array and hashes it - different value! | hashCode inconsistency between hashCode() and hash() usage                    |
| 3   | Mutable objects can safely be HashMap keys if hashCode doesn't change | The invariant requires that hashCode DOESN'T CHANGE for keys in the map. Any mutation to fields used in hashCode corrupts the map | Silent "lost entry" bug after key mutation                                    |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - HashMap returns null for key that was inserted**

Symptom: `map.get(key)` returns null, but `map.size()` is non-zero
and `map.values()` contains the expected value.

Root cause: The key's `hashCode()` changed after insertion (mutable
key, mutated after put).

Diagnostic: Before `get()`, print `System.identityHashCode(key)` and
compare to what was printed at `put()`. If different, the key was
mutated.

Fix: Use immutable objects as map keys. If mutability is required,
remove the key before mutation and re-insert after.

---

**Failure 2 - `HashSet` contains duplicates of "equal" objects**

Symptom: `set.size()` is larger than expected; logically identical
objects are both present.

Root cause: `equals()` was overridden but `hashCode()` was not (or
vice versa). Objects that `equals` considers equal have different
hash codes and land in different buckets - HashSet never sees them
as duplicates.

Fix: Override both `equals` and `hashCode` based on the same fields.
Use Java records or IDE "generate equals/hashCode" with all relevant fields.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                         |
| ---------------- | ------------------------------------------------------------ |
| 20 min           | 7-point contract; equals-hashCode pairing                    |
| 40 min           | Add cache invalidation bug; Objects.hash usage               |
| 1 hour           | Add symmetry violation; String hashCode caching; performance |

---

**[MID] Q1: What happens if you override `equals` but not `hashCode`?**
[DEBUGGING]

_Why they ask:_ The most common equals/hashCode mistake.

_Likely follow-up:_ "Can you give a concrete HashMap failure scenario?"

If `equals` is overridden but `hashCode` is not:

- `Object.hashCode()` is used (identity-based, different for
  every object instance)
- Two "equal" objects (by your `equals`) have different hashCodes
- HashMap puts them in different buckets
- `map.get(new Key(1))` computes `Object.hashCode()` of the new Key
  object, finds a different bucket than where the entry was stored,
  returns null

```java
class BadKey {
    int id;
    BadKey(int id) { this.id = id; }

    @Override public boolean equals(Object o) {
        return o instanceof BadKey k && k.id == id;
    }
    // hashCode NOT overridden - uses Object identity hash
}

Map<BadKey, String> map = new HashMap<>();
map.put(new BadKey(1), "Alice");
System.out.println(map.get(new BadKey(1))); // null!
// Two BadKey(1) objects have different identity hashCodes
// so they land in different buckets
```

_What separates good from great:_ Tracing the exact mechanism: hashCode
determines bucket, equals determines entry within bucket. If hashCode
sends to wrong bucket, equals is never called.

---

**[SENIOR] Q2: Why is it important that `hashCode` distributes values
well?** [CONCEPTUAL]

_Why they ask:_ Tests understanding of hash quality effects on
collection performance.

_Likely follow-up:_ "What is a degenerate hashCode implementation?"

Poor hash distribution = many collisions = many keys in the same bucket.
With Java 8 treeification, worst case is O(log n) per lookup instead
of O(1). Without it (or with key types that don't implement Comparable),
worst case is O(n) per lookup.

A degenerate `hashCode()` returning a constant: ALL keys go to bucket 0.
The map degrades to a linked list (O(n) per operation).

A degenerate `hashCode()` based on `id % 16` for IDs in range [0,15]:
all IDs map to at most 16 buckets, concentrating entries even with a
larger map.

Good hash distribution ensures:

1. Buckets are filled approximately uniformly
2. The expected chain length per bucket is O(1) (= total entries /
   number of buckets = load factor ≈ 0.75)
3. Lookup, insert, delete are O(1) average

Properties of good `hashCode`: avalanche effect (small input change
causes large hash change), determinism, low collision rate. The JDK's
`String.hashCode()` uses a polynomial rolling hash over char values.

_What separates good from great:_ Connecting hash quality to the security
concern (deliberately degenerate hashCodes for DoS attacks) and Java 8's
treeification as the defense.

---

**[SENIOR] Q3: How does `String` cache its `hashCode` and is this safe?**
[CONCEPTUAL]

_Why they ask:_ Tests understanding of lazy caching for immutable types.

_Likely follow-up:_ "Can you apply the same pattern to your classes?"

`String` computes `hashCode` lazily on first call and stores it in a
private field `private int hash;`:

```java
// Simplified String.hashCode() implementation:
public int hashCode() {
    int h = this.hash;
    if (h == 0 && value.length > 0) {
        h = computeHash(value);
        this.hash = h; // cache
    }
    return h;
}
```

This is safe ONLY because `String` is immutable: the char array `value`
never changes after construction, so the hash is stable. The cached
value will always be correct.

Applying to your classes: safe only for immutable classes. If any
field used in hashCode can change, the cached hash becomes stale.

The write to `this.hash` without synchronization is safe in Java
(for int): JMM guarantees that a write of an int value is atomic.
In the worst case (two threads compute simultaneously), both write
the same value (same chars = same hash). No corruption possible.

_What separates good from great:_ The thread safety reasoning: why
the unsynchronized write to `hash` is safe (same value, atomic write,
worst case is redundant computation, not corruption).

---

**[STAFF] Q4: BEHAVIORAL: Describe debugging a production issue
caused by a hashCode/equals violation.** [BEHAVIORAL - STAR]

_Why they ask:_ Tests production experience with this class of bug.

_Likely follow-up:_ "What tooling helped you find it?"

**Situation:** A user session service stored session objects in a
`HashMap<SessionKey, Session>`. Under load, some sessions became
unreachable - `getSession(userId, deviceId)` returned null even though
the session was active (visible in metrics).

**Task:** Diagnose why certain sessions were "missing" from the map
despite being inserted successfully.

**Action:**

1. Added instrumentation: logged `System.identityHashCode(key)` at
   `put()` time and `get()` time.
2. Observed: the identity hash codes were the same object - the key
   was not being replaced. But `hashCode()` values differed.
3. Investigated `SessionKey.hashCode()`: it included
   `sessionToken.hashCode()`. The token was generated lazily - it was
   null at `put()` time, triggering `Objects.hash(null)`, and non-null
   at `get()` time.

Root cause: `SessionKey.sessionToken` was set to null on construction
(lazy generation) and populated later. The hash computed at `put()`
(with null token) differed from the hash at `get()` (with token).

Fix: Generate the token before construction, ensuring all fields used
in `hashCode` are non-null and immutable at creation time. Made
`SessionKey` a record (auto-enforces all fields used in hashCode/equals).

**Result:** Session lookup errors eliminated. Added a test that verifies
`new SessionKey(args).hashCode() == new SessionKey(args).hashCode()`
to detect future regressions.

_What separates good from great:_ Using `System.identityHashCode`
to confirm it's the same object (eliminating a different root cause),
and adding a regression test that encodes the invariant.

---

**[SENIOR] Q5: TRADE-OFF: When should you make `equals` based on
business identity vs object identity?** [TRADE-OFF]

_Why they ask:_ Tests ability to reason about identity vs equality.

_Likely follow-up:_ "What about Value Objects in DDD?"

**Object identity** (default `Object.equals`): two references are
equal only if they point to the same object. Use when each instance
IS its own identity (e.g., event objects, running threads, tasks
in a scheduler).

**Business identity** (custom `equals`): two objects are equal if
their domain key is equal. Use for Value Objects, domain entities
where identity is defined by business fields (e.g., `Customer` equal
iff `customerId` is equal), and any class used as a Map key.

Rules of thumb:

1. If the class represents a VALUE (amount, address, email), use
   value equality. Java records do this automatically.
2. If the class represents an ENTITY with lifecycle (Customer, Order),
   equality should be based on the primary key (customerId, orderId).
   Other mutable fields (address, status) should NOT be in `equals`.
3. If the class represents a SERVICE or CAPABILITY (thread, connection,
   executor), use object identity.

DDD Value Object pattern: a Value Object has no identity beyond its
value. `Money(10, "USD").equals(Money(10, "USD"))` must be true.
Override `equals` and `hashCode` based on all fields.

_What separates good from great:_ The entity rule: only use the
primary key (immutable ID field) in `equals` for entities, not mutable
attributes like name or status. Mutable attribute equality changes
when you update the entity, causing HashMap corruption.

---

**[STAFF] Q6: ARCHITECTURE: How do you enforce the hashCode/equals
contract at scale across a codebase with 500+ domain classes?**
[ARCHITECTURE]

_Why they ask:_ Tests systematic approach to contract enforcement.

_Likely follow-up:_ "How would you find existing violations?"

**Enforcement strategies:**

1. **Java records for value objects**: records automatically generate
   correct, consistent equals/hashCode. Mandate records for all Value
   Objects in the codebase.

2. **IDE inspection + static analysis**: configure IntelliJ to flag
   classes that override equals without hashCode (or vice versa).
   Add Spotbugs (HE_EQUALS_NO_HASHCODE rule) to the build.

3. **EqualsVerifier library**: a test library that exhaustively checks
   all equals/hashCode contract rules:

   ```java
   @Test
   void equalsContract() {
       EqualsVerifier.forClass(MyEntity.class)
           .withOnlyTheseFields("id") // entity: only ID field
           .verify();
   }
   ```

   Add to every domain class test. It checks reflexivity, symmetry,
   transitivity, consistency, null-safety, and hashCode consistency.

4. **Architecture test (ArchUnit)**:

   ```java
   classes().that().implement(DomainEntity.class)
       .should().haveMethod("equals", Object.class)
       .andShould().haveMethod("hashCode")
       .check(importedClasses);
   ```

5. **Code review checklist**: every PR with a new class used as a
   Map key requires EqualsVerifier test.

_What separates good from great:_ Knowing EqualsVerifier by name and
the Spotbugs rule (HE_EQUALS_NO_HASHCODE), not just "we should write
tests."

---

**[MID] Q7: What is `Objects.hash()` and when should you use it
vs manual hash computation?** [TRADE-OFF]

_Why they ask:_ Tests practical hashCode implementation knowledge.

_Likely follow-up:_ "Is there a performance difference?"

`Objects.hash(o1, o2, o3)` computes `Arrays.hashCode(new Object[]{o1, o2, o3})`.
It is null-safe (null fields contribute 0 to the hash) and correct.

Internally: creates a temporary `Object[]` (allocates on heap, GC
pressure), then uses `Arrays.hashCode` (polynomial rolling hash:
`31 * accumulated + element.hashCode()`).

Trade-off:

**`Objects.hash(f1, f2, f3)`** - convenience:

- Readable, null-safe, correct
- Slightly slower: allocates `Object[]`, boxes primitives
- Use in non-hot code (most cases)

**Manual hash**:

```java
@Override public int hashCode() {
    int h = 17;
    h = 31 * h + id;           // no boxing for int
    h = 31 * h + name.hashCode();  // direct call
    return h;
}
```

- Faster: no array allocation, no boxing
- More verbose
- Use in hot paths where hashCode is called millions of times

For Java records: use the compiler-generated hashCode (uses
`Objects.hash` equivalent). Only optimize manually if profiling
shows hashCode is a bottleneck.

_What separates good from great:_ Knowing `Objects.hash` boxes primitives
and allocates `Object[]`, and when this matters (high-frequency
HashMap operations, custom key types in hot loops).

---

**[SENIOR] Q8: DEBUGGING: A `Set<User>` is not preventing duplicates
for users with the same ID. Diagnose the issue.** [DEBUGGING]

_Why they ask:_ Tests diagnostic methodology for equals/hashCode bugs.

_Likely follow-up:_ "How do you write a test that catches this?"

Step-by-step diagnosis:

1. Confirm the bug: create two `User` objects with the same ID,
   add both to the Set, check `set.size()` - should be 1.

   ```java
   User u1 = new User(1, "Alice");
   User u2 = new User(1, "Bob"); // same ID, different name
   Set<User> set = new HashSet<>();
   set.add(u1); set.add(u2);
   assert set.size() == 1; // FAILS -> confirms bug
   ```

2. Check if `equals` is overridden: `User.class.getDeclaredMethod("equals", Object.class)`.
   If absent: using Object identity, not ID equality.

3. If `equals` is overridden, check `hashCode`:

   ```java
   System.out.println(u1.hashCode()); // e.g., 1234
   System.out.println(u2.hashCode()); // e.g., 5678 - different!
   // Different hashCodes -> different buckets -> never compared
   ```

4. Verify: `u1.equals(u2)` should be `true` (same ID) but
   `u1.hashCode() == u2.hashCode()` should also be `true` for Set
   deduplication to work.

Likely root cause: `equals` overridden based on `id` but `hashCode`
inherited from `Object` (identity-based) - different instances have
different identity hashes.

Fix: Override `hashCode()` to return `Objects.hash(id)`. Or use
a record: `record User(int id, String name) {}` (records use ALL
fields - if deduplicate by ID only, use a custom class or comparator).

_What separates good from great:_ Using reflection to verify at runtime
whether methods are overridden, and knowing records use ALL fields in
equals/hashCode (so for ID-only deduplication, a record is wrong).

---

---

# HashMap vs ConcurrentHashMap: Concurrency Safety Guarantees

**Interview Weight:** high - Core concurrent collections question at
every senior+ level.

---

### 🎯 Model Answer

**30 seconds:**

> `HashMap` is not thread-safe: concurrent modification causes undefined
> behavior (data corruption, infinite loops in Java 7, lost updates).
> `ConcurrentHashMap` is fully thread-safe: lock-free reads via
> `volatile` fields, fine-grained bucket-level locking for writes.
> reads never block; writes contend only within the same bucket.
> Does NOT support null keys or values (unlike HashMap).

**3 minutes (Senior):**

> `HashMap` failure modes under concurrency: (1) Java 7: concurrent
> resize caused circular linked lists -> infinite loop in `get()` on
> affected thread. (2) Java 8+: circular list fixed but lost updates,
> corrupted tree nodes, incorrect size counts all possible.
>
> `ConcurrentHashMap` (Java 8+) internals: the backing `Node<K,V>[]`
> table is `volatile` - reads see the latest state without a lock. For
> puts into an empty bucket: a single CAS operation (compareAndSet)
> writes atomically. For puts into non-empty buckets: `synchronized`
> on the bucket's HEAD node - only one writer per bucket at a time.
> Reads (`get()`) acquire no locks.
>
> `ConcurrentHashMap` has atomic compound operations: `putIfAbsent()`,
> `computeIfAbsent()`, `merge()`, `compute()`. These are atomically
> correct. NON-atomic: `size()` (approximate count), the pattern
> `if (!map.containsKey(k)) map.put(k, v)` (use `putIfAbsent` instead),
> and separate check-then-act operations.

**Framework:** HASHMAP-FAILURES (Java 7 infinite loop, Java 8 corruption)

- CHM-READS (lock-free) + CHM-WRITES (CAS + bucket sync) + ATOMIC-OPS

_Adapting up:_ Discuss `ConcurrentHashMap.compute()` semantics (atomic
update function), `mappingCount()` vs `size()` for large maps, and
how `ConcurrentHashMap.newKeySet()` creates a concurrent Set.

_Adapting down:_ HashMap = not thread-safe. ConcurrentHashMap = thread-safe,
no nulls. Use CHM for concurrent access.

**Blank Mind Recovery:**

**(1) Restate:** "HashMap is not thread-safe: concurrent writes corrupt.
ConcurrentHashMap: reads lock-free, writes lock per bucket. No null
keys/values. Atomic ops: putIfAbsent, computeIfAbsent."

**(2) First principles:** "Concurrency safety requires atomicity and
visibility. HashMap guarantees neither. CHM uses volatile for visibility
(lock-free reads) and CAS/synchronized for atomicity (safe writes)."

**(3) Bridge:** "HashMap is a shared whiteboard with no rules - anyone
writes anywhere. ConcurrentHashMap is a whiteboard split into sections
with section-level locks - you can read everything freely but only one
person writes to each section at a time."

---

### 📘 Concept Explanation

**HashMap failure modes:**

```java
// Concurrent HashMap access - ALL THESE ARE BUGS:

// Bug 1: Lost update (two threads put, one wins)
Thread t1: map.put("A", 1);
Thread t2: map.put("A", 2);
// Result might be 1 or 2, but visibility not guaranteed

// Bug 2: Java 7 infinite loop (resize race)
// Concurrent resize creates circular linked list
// Any thread iterating that bucket loops forever (CPU 100%)

// Bug 3: HashMap.computeIfAbsent race
// Two threads both see key absent, both compute, both put
// One result is silently overwritten

// Diagnosis:
// - Thread stuck at 100% CPU: likely HashMap infinite loop
// - Heap dump shows circular reference in HashMap$Entry: confirms it
```

**`ConcurrentHashMap` read guarantee:**

```java
ConcurrentHashMap<String, Integer> chm = new ConcurrentHashMap<>();

// get() is lock-free:
// 1. Read table (volatile) -> guaranteed to see latest state
// 2. Compute hash, find bucket
// 3. Read bucket entries (volatile fields in Node)
// No lock acquired at any point

// This is safe and always consistent:
Integer value = chm.get("key"); // never blocks, always sees written data
```

**Write strategy:**

```java
// Put into EMPTY bucket: CAS
// Compare slot to null, set atomically (single CPU instruction)
// If another thread wins the CAS, retry

// Put into NON-EMPTY bucket:
synchronized (bucketHead) {
    // Only one writer per bucket at a time
    // Multiple threads write to DIFFERENT buckets concurrently
}
// For 16 buckets (default): up to 16 concurrent writers
```

**Atomic compound operations:**

```java
ConcurrentHashMap<String, List<String>> index = new ConcurrentHashMap<>();

// BAD: check-then-act is NOT atomic (race condition)
if (!index.containsKey(word)) {
    index.put(word, new ArrayList<>());
}
// Two threads can both see absent, both create new list

// GOOD: computeIfAbsent is atomic per key
index.computeIfAbsent(word, k -> new ArrayList<>())
    .add(document); // But: list.add is not atomic! Use CopyOnWriteArrayList

// Thread-safe multi-value map:
index.computeIfAbsent(word, k -> new CopyOnWriteArrayList<>())
    .add(document);

// Atomic increment:
ConcurrentHashMap<String, AtomicInteger> counts =
    new ConcurrentHashMap<>();
counts.computeIfAbsent(word, k -> new AtomicInteger())
    .incrementAndGet(); // atomic increment

// Or using merge:
wordCounts.merge(word, 1, Integer::sum); // atomic add
```

---

### 💻 Code Example

#### Thread-safe word counter

```java
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

public class WordCounter {

    // BAD: HashMap - loses updates under concurrent access
    private final Map<String, Integer> badCounts = new HashMap<>();

    // GOOD: ConcurrentHashMap with atomic merge
    private final ConcurrentHashMap<String, Integer>
        counts = new ConcurrentHashMap<>();

    public void count(String word) {
        // merge(key, value, remappingFn) is atomic:
        // If key absent: put(key, 1)
        // If key present: put(key, remappingFn(existing, 1))
        counts.merge(word, 1, Integer::sum);
    }

    public int getCount(String word) {
        return counts.getOrDefault(word, 0);
    }

    // Bulk processing (parallel stream + ConcurrentHashMap):
    public Map<String, Integer> countAll(List<String> words) {
        ConcurrentHashMap<String, Integer> result =
            new ConcurrentHashMap<>();
        words.parallelStream()
            .forEach(w -> result.merge(w, 1, Integer::sum));
        return result;
    }
}
```

> **Code walkthrough:** `ConcurrentHashMap.merge(key, 1, Integer::sum)`
> is the idiomatic atomic increment. It atomically reads the current
> value, applies the remapping function (`existing + 1`), and writes
> back - with internal retry on contention. This replaces the buggy
> `map.put(word, map.getOrDefault(word, 0) + 1)` (non-atomic, loses
> updates). In `countAll`, `parallelStream()` distributes processing
> across threads; the ConcurrentHashMap handles concurrent writes
> correctly with no external synchronization.

---

### 🎓 Answers by Seniority

**Junior:** `HashMap` is not thread-safe. Use `ConcurrentHashMap` for
concurrent access. `ConcurrentHashMap` does not allow null keys or values.

**Mid-level:** `ConcurrentHashMap` reads are lock-free (volatile table).
Writes are CAS for empty buckets, synchronized per-bucket for non-empty.
Atomic operations: `putIfAbsent`, `computeIfAbsent`, `merge`. Non-atomic:
`size()` (approximate), check-then-act patterns.

**Senior:** Java 7 `HashMap` under concurrent resize creates circular
linked lists causing infinite loops. Java 8 fixed this but still has
corruption. `ConcurrentHashMap.computeIfAbsent(k, fn)` is atomic:
the function runs at most once per key under contention (other threads
wait). `merge(k, v, fn)` is also atomic and the preferred way to
accumulate values.

**Staff:** `ConcurrentHashMap.size()` is approximate - uses a distributed
counter array (`LongAdder`-like) to avoid lock contention. For exact
count, use `mappingCount()` (returns `long`, avoids int overflow for
maps with > 2^31 entries). At high write concurrency, even per-bucket
locking creates contention - consider sharding across multiple maps
with a striped lock pattern.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                                                 | Reality                                                                                                                                                                   | Danger                                               |
| --- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| 1   | `Collections.synchronizedMap(HashMap)` and `ConcurrentHashMap` are equivalent | `synchronizedMap` uses a single global lock: reads block reads. `ConcurrentHashMap` has lock-free reads. At high concurrency, `synchronizedMap` serializes all operations | Performance bottleneck under concurrent read load    |
| 2   | `ConcurrentHashMap` makes all compound operations thread-safe                 | Individual operations are atomic, but separate operations are NOT. `if (!map.containsKey(k)) map.put(k, v)` is a race condition. Use `putIfAbsent`                        | Lost updates from compound operation race conditions |
| 3   | `ConcurrentHashMap.size()` is accurate                                        | `size()` returns an approximate count. The actual count is maintained across distributed segments without coordination. Use when exactness is not required                | Logic depending on exact CHM.size() may be incorrect |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Thread stuck at 100% CPU from HashMap infinite loop**

Symptom: One or more threads pegged at 100% CPU with no progress.

Diagnostic: Take thread dump (`kill -3` or jstack). Look for threads
stuck in `HashMap.get()` or `HashMap.put()` in a tight loop.
Take heap dump and inspect HashMap - circular next pointers confirm.

Root cause: Concurrent HashMap resize in Java 7 created circular
linked list in a bucket.

Fix: Replace HashMap with ConcurrentHashMap. Upgrade JDK to Java 8+
(fixed the specific circular list bug, though concurrent HashMap
is still unsafe and corrupt results are possible).

---

**Failure 2 - `computeIfAbsent` lambda called multiple times**

Symptom: Expensive initialization function called more than once
for the same key.

Root cause: Using `HashMap.computeIfAbsent()` from multiple threads
(not `ConcurrentHashMap`). Both see key absent, both call the function.

Fix: Use `ConcurrentHashMap.computeIfAbsent()` - the function is called
at most once per key (other threads wait).

Note: `ConcurrentHashMap.computeIfAbsent()` also disallows recursive
calls that modify the same map (can cause deadlock).

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                        |
| ---------------- | ----------------------------------------------------------- |
| 20 min           | HashMap thread-safety failures; CHM lock-free reads         |
| 40 min           | Add CAS writes; atomic operations; null restriction         |
| 1 hour           | Add Java 7 circular list bug; size() approximation; merge() |

---

**[MID] Q1: Why does `ConcurrentHashMap` not allow null keys or
values?** [CONCEPTUAL]

_Why they ask:_ Tests knowledge of a specific ConcurrentHashMap design
decision.

_Likely follow-up:_ "HashMap does allow null - why the difference?"

`ConcurrentHashMap` rejects null keys and values due to an inherent
ambiguity in concurrent context: when `map.get(key)` returns null,
there are two possible reasons: (1) the key is not in the map, or
(2) the key is in the map with value null.

In a single-threaded context (`HashMap`), you can disambiguate with
`map.containsKey(key)` - this is safe because state can't change
between the two calls.

In a multi-threaded context (`ConcurrentHashMap`), the check
`if (map.get(key) == null && !map.containsKey(key))` is NOT
atomic. Between the `get()` and `containsKey()`, another thread
could put a null value. The result is ambiguous.

The design decision: avoid the ambiguity entirely by prohibiting null.
This forces callers to use `Optional` or sentinel values, making the
absent vs null distinction explicit.

_What separates good from great:_ The TOCTOU (time-of-check-time-of-use)
race between `get(null)` and `containsKey(key)` as the root of the
design decision.

---

**[SENIOR] Q2: How does `ConcurrentHashMap.computeIfAbsent()` work
and is it always safe to use for caching?** [CONCEPTUAL]

_Why they ask:_ Tests understanding of CHM's atomic compute semantics.

_Likely follow-up:_ "What is the problem with recursive maps inside compute?"

`computeIfAbsent(key, mappingFunction)`: if key is absent, calls
`mappingFunction(key)` and puts the result. The mapping function is
called WHILE holding the bucket lock - other threads wanting to
modify the same bucket wait.

This guarantees: the function is called at most once for the same key
under concurrent access (if the function completes normally). The
mapped value is returned.

Caveats:

1. **Function must be non-blocking**: the bucket lock is held during
   the function call. If the function blocks (waits for I/O, another
   lock), it holds the bucket lock and all threads wanting to access
   that bucket stall.

2. **No recursive modification of the same map**: if the mapping
   function calls `computeIfAbsent` on the SAME `ConcurrentHashMap`
   AND the new key hashes to the SAME bucket, deadlock occurs
   (same thread tries to re-acquire the same monitor).

3. **Function called at most once, but may be called zero times**:
   if the key was inserted between the initial check and the lock
   acquisition, the function may not be called.

_What separates good from great:_ The deadlock scenario from recursive
same-bucket access inside the mapping function.

---

**[STAFF] Q3: ARCHITECTURE: When would you shard ConcurrentHashMap
and how?** [ARCHITECTURE]

_Why they ask:_ Tests ability to reason beyond basic concurrent collections.

_Likely follow-up:_ "What is Guava's Striped and when would you use it?"

`ConcurrentHashMap` has fine-grained locking (per bucket), but under
extreme write contention on the SAME bucket (many keys with the same
hash, or a very small map), bucket-level contention creates a bottleneck.

Also: for very large maps (100M+ entries), GC pause times increase
because the JVM must traverse all map entries during mark phase.

Sharding strategy:

```java
// Divide into N shards based on key hash
class ShardedMap<K, V> {
    private final int shardCount;
    private final ConcurrentHashMap<K, V>[] shards;

    @SuppressWarnings("unchecked")
    ShardedMap(int shardCount) {
        this.shardCount = shardCount;
        this.shards = new ConcurrentHashMap[shardCount];
        for (int i = 0; i < shardCount; i++) {
            shards[i] = new ConcurrentHashMap<>();
        }
    }

    private ConcurrentHashMap<K, V> shardFor(K key) {
        int shard = (key.hashCode() & Integer.MAX_VALUE)
                    % shardCount;
        return shards[shard];
    }

    public V get(K key) { return shardFor(key).get(key); }
    public V put(K key, V value) {
        return shardFor(key).put(key, value);
    }
}
```

Guava's `Striped<Lock>`: similar concept - splits a single lock into N
stripes. Lower overhead than N separate maps but same contention reduction.

Use sharding when: profiling shows CHM write contention as a bottleneck,
specifically when multiple threads frequently update entries in the same
buckets.

_What separates good from great:_ Identifying the GC pause motivation
for sharding (smaller individual maps = faster per-map GC traversal)
in addition to the contention reduction.

---

---

# Java Serialization: ObjectOutputStream, Externalizable, Versioning

**Interview Weight:** medium - Important for RMI, JCache, distributed
systems; and a key security topic.

---

### 🎯 Model Answer

**30 seconds:**

> Java serialization converts objects to a byte stream for persistence
> or network transfer. Classes must implement `Serializable` (marker
> interface). `ObjectOutputStream.writeObject(obj)` serializes;
> `ObjectInputStream.readObject()` deserializes. Critical: provide a
> `serialVersionUID` constant to control compatibility. `transient`
> fields are excluded. Deserialization is a well-known attack vector -
> never deserialize untrusted data.

**3 minutes (Senior):**

> Java serialization: writes class name + all non-transient, non-static
> fields recursively. `ObjectOutputStream` uses reflection to access
> private fields. On deserialization, `ObjectInputStream` creates the
> object WITHOUT calling the constructor - directly sets fields from
> the stream. This bypasses constructor validation and can produce
> objects in invalid states.
>
> `serialVersionUID`: a `long` that identifies the class version.
> If not declared, the JVM computes it from the class structure (fields,
> methods). A minor refactor (adding a method) changes the computed UID.
> When reading old serialized data with a new class version that has
> a different UID, `InvalidClassException` is thrown. ALWAYS declare
> `serialVersionUID` explicitly.
>
> `Externalizable` (extends `Serializable`): gives full control via
> `writeExternal(ObjectOutput)` and `readExternal(ObjectInput)` -
> you write/read exactly the fields you want. Faster than default
> serialization (no reflection) but requires more code.
>
> Modern alternatives: JSON (Jackson, Gson), protocol buffers,
> Avro - all better than Java serialization for persistence and
> network transfer.

**Framework:** MECHANISM (byte stream, no constructor on read) +
SERIALVERSIONUID (compatibility control) + TRANSIENT + EXTERNALIZABLE

- SECURITY-RISK

_Adapting up:_ Discuss `readObject`/`writeObject` custom methods for
partial customization, and `readResolve`/`writeReplace` for singleton
serialization and proxy objects.

_Adapting down:_ implement `Serializable`, declare `serialVersionUID`,
mark sensitive fields `transient`.

**Blank Mind Recovery:**

**(1) Restate:** "Serializable = bytes. readObject creates object without
constructor. serialVersionUID = version compatibility. transient = skip
field. Security risk: never deserialize untrusted data."

**(2) First principles:** "To save or transfer an object, convert its
state to bytes. To reconstruct, read bytes and restore state. The
security risk: the reconstructor trusts the byte stream to tell it what
class to create."

**(3) Bridge:** "Serialization is like packing for moving: all your
stuff in boxes (bytes). Deserialization is unpacking. serialVersionUID
is a box label version - if the box was packed with v1 furniture
instructions and you unpack with v2, it may not fit. And if a malicious
mover puts fake boxes in your truck (untrusted data), you might unpack
dangerous items."

---

### 📘 Concept Explanation

**Basic serialization:**

```java
// Serializable class
public class User implements Serializable {
    // ALWAYS declare to control compatibility
    private static final long serialVersionUID = 1L;

    private String username;
    private int age;
    private transient String password; // excluded from serialization
    private static final String SYSTEM = "MyApp"; // static - not serialized
}

// Serialize to bytes
User user = new User("alice", 30, "secret");
ByteArrayOutputStream bos = new ByteArrayOutputStream();
try (ObjectOutputStream oos = new ObjectOutputStream(bos)) {
    oos.writeObject(user);
}
byte[] bytes = bos.toByteArray();

// Deserialize from bytes
try (ObjectInputStream ois = new ObjectInputStream(
        new ByteArrayInputStream(bytes))) {
    User restored = (User) ois.readObject();
    // restored.password == null! (transient)
    // User() constructor was NEVER called
}
```

**serialVersionUID:**

```java
// WITHOUT explicit serialVersionUID:
// JVM computes from: class name + fields + methods + interfaces
// Adding a new METHOD changes the computed UID!
// -> Reading old serialized data throws InvalidClassException

// WITH explicit serialVersionUID = 1L:
private static final long serialVersionUID = 1L;
// Stays stable across refactors
// Old data compatible with new class version
// (as long as you handle missing/extra fields gracefully)
```

**`Externalizable` for performance:**

```java
public class FastUser implements Externalizable {
    private String username;
    private int age;

    // REQUIRED: public no-arg constructor
    public FastUser() {}

    @Override
    public void writeExternal(ObjectOutput out) throws IOException {
        out.writeUTF(username);  // write exactly what you want
        out.writeInt(age);
    }

    @Override
    public void readExternal(ObjectInput in)
            throws IOException {
        this.username = in.readUTF();  // read in same order
        this.age = in.readInt();
    }
}
```

**Custom `readObject` for validation:**

```java
public class Account implements Serializable {
    private static final long serialVersionUID = 1L;
    private final double balance;

    // Custom readObject: validate after deserialization
    private void readObject(ObjectInputStream ois)
            throws IOException, ClassNotFoundException {
        ois.defaultReadObject(); // reads all non-transient fields
        // Validate (constructor was NOT called, so validate here)
        if (balance < 0) {
            throw new InvalidObjectException(
                "Negative balance: " + balance);
        }
    }
}
```

---

### 💻 Code Example

#### Serialization security vulnerability

```java
// BAD: deserializing untrusted data
public Object deserialize(byte[] data) {
    try (ObjectInputStream ois = new ObjectInputStream(
            new ByteArrayInputStream(data))) {
        return ois.readObject(); // UNSAFE: class loading from stream
    }
}
// Attacker provides a "gadget chain" byte stream:
// Byte stream contains a serialized PriorityQueue whose comparator
// calls Runtime.exec() -> remote code execution!

// GOOD: use an ObjectInputFilter to allowlist classes
ObjectInputFilter filter = ObjectInputFilter.Config
    .createFilter("com.myapp.User;com.myapp.Order;!*");
// "!*" rejects all classes not explicitly allowed

ois.setObjectInputFilter(filter);
// Now only User and Order can be deserialized
// Gadget chain classes are rejected -> no RCE

// BEST: don't use Java serialization for external data
// Use JSON (Jackson) or protobuf instead:
ObjectMapper mapper = new ObjectMapper();
User user = mapper.readValue(jsonString, User.class);
// JSON deserialization does NOT perform arbitrary class loading
```

> **Code walkthrough:** Java deserialization can instantiate ANY
> `Serializable` class on the classpath - determined by the attacker's
> byte stream. "Gadget chains" are sequences of innocent-looking classes
> where method calls chain together to execute arbitrary code (using
> `PriorityQueue.comparator`, `InvokerTransformer`, etc.). The filter
> allowlists only specific classes. Modern applications should avoid Java
> serialization for externally-received data entirely.

---

### 🎓 Answers by Seniority

**Junior:** Implement `Serializable`, declare `serialVersionUID`, mark
sensitive fields `transient`.

**Mid-level:** `serialVersionUID` controls deserialization compatibility.
Without it, JVM recomputes from class structure - adding a method breaks
old data. Constructor is NOT called on deserialization - use `readObject`
for validation. `transient` excludes fields.

**Senior:** Deserialization is arbitrary class instantiation from the
stream - a well-known RCE vector (CVE library). Use `ObjectInputFilter`
to allowlist expected classes. Better: use JSON/protobuf instead of
Java serialization for any data crossing a trust boundary.

**Staff:** Java serialization is a legacy mechanism. Modern systems use
Jackson (JSON), protobuf, or Avro. Records (Java 16) are Serializable
but the serialization format is not guaranteed stable across JVM versions.
For DTOs crossing service boundaries, define an explicit serialization
format (JSON schema, protobuf IDL) separate from the Java class structure.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                                   | Reality                                                                                                                                                                             | Danger                                                                                            |
| --- | --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| 1   | `serialVersionUID` is optional and the JVM manages it           | Without explicit UID, adding any method changes the computed UID and breaks deserialization of existing data                                                                        | Production error on deployment: all cached/stored data becomes unreadable                         |
| 2   | `transient` fields are restored as null/0 after deserialization | Correct - they are initialized to the JVM default (null for objects, 0 for primitives). But if `readObject` is used, transient fields can be initialized manually                   | Logic errors in methods that use transient fields after deserialization                           |
| 3   | Java deserialization is safe if you control both endpoints      | Even with internal systems, if a serialized object is stored (in a cache, DB blob) and the code changes, old serialized data may trigger unexpected behavior during deserialization | Corrupted application state from deserialization of internally-stored objects after class changes |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - `InvalidClassException` on deployment**

Symptom: Application fails to read cached/stored data after deployment.

Root cause: Class was modified (new method, field reordering), the
auto-computed `serialVersionUID` changed, and stored data has the old UID.

Fix: Add explicit `serialVersionUID = 1L` to all `Serializable` classes.
For already-deployed classes: use the old computed UID (find it with
`serialver` tool) as the explicit value.

---

**Failure 2 - Deserialization RCE in HTTP endpoint**

Symptom: Server executes OS commands from incoming HTTP requests.

Root cause: Endpoint deserializes Java objects from request body.
Attacker sends a gadget chain exploiting commons-collections or
similar library on the classpath.

Fix: Apply `ObjectInputFilter` allowlist. Better: replace Java
serialization with JSON for all HTTP endpoints.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                               |
| ---------------- | ------------------------------------------------------------------ |
| 20 min           | Serializable basics; serialVersionUID; transient                   |
| 40 min           | Add Externalizable; readObject validation; constructor bypass      |
| 1 hour           | Add security vulnerability; ObjectInputFilter; modern alternatives |

---

**[MID] Q1: Why is it important to declare `serialVersionUID` explicitly?**
[CONCEPTUAL]

_Why they ask:_ Tests serialization versioning knowledge.

_Likely follow-up:_ "What does the auto-computed UID include?"

Without explicit `serialVersionUID`, the JVM computes a UID from:
class name, declared fields (names and types), declared methods (names,
signatures), and interfaces. ANY change to this structure - including
adding a new helper method - changes the computed UID.

When old serialized data is read and the class UID has changed,
`InvalidClassException` is thrown: "stream classdesc serialVersionUID
= X, local class serialVersionUID = Y."

Declaring `serialVersionUID = 1L` (or any fixed value) prevents this.
The JVM trusts the explicit declaration instead of computing. You take
responsibility for ensuring old data is still compatible with the new
class structure.

When to increment: when you make an incompatible change (remove a field,
change a field type). When to keep the same: when you add a new field
or method (new field will be null/0 when deserializing old data).

_What separates good from great:_ Knowing the exact components the JVM
uses to auto-compute (fields + methods + interfaces) - adding a PRIVATE
method still changes the UID.

---

**[SENIOR] Q2: Why is Java deserialization a security risk?**
[SECURITY]

_Why they ask:_ Java deserialization RCE is a critical CVE class.

_Likely follow-up:_ "Name a real CVE involving deserialization."

Java deserialization (`readObject()`) instantiates whatever class
the byte stream describes, as long as it implements `Serializable` and
is on the classpath. The attacker controls the byte stream.

"Gadget chains": many widely-used libraries (Apache Commons Collections,
Spring, Groovy) have `Serializable` classes whose `readObject()`/
`equals()`/`hashCode()` implementations ultimately invoke arbitrary
method calls. A carefully crafted chain of these classes, serialized
together, triggers method calls that execute `Runtime.exec()`.

Real CVEs:

- **CVE-2015-4852**: Apache Commons Collections gadget chain used to
  achieve RCE via Oracle WebLogic serialization endpoint
- **CVE-2016-4437**: Apache Shiro deserialization RCE
- **CVE-2017-10271**: Oracle WebLogic T3 protocol deserialization

Mitigations:

1. `ObjectInputFilter` allowlist (Java 9+, backported to 6/7/8)
2. Use agent-based serialization protection (e.g., NotSoSerial)
3. Disable Java deserialization endpoint if not needed
4. Replace with JSON/protobuf

_What separates good from great:_ Naming a specific CVE and the
mechanism (gadget chain through commons-collections).

---

**[SENIOR] Q3: What is `Externalizable` and when would you choose
it over `Serializable`?** [TRADE-OFF]

_Why they ask:_ Tests knowledge of the serialization control spectrum.

_Likely follow-up:_ "What is the performance difference?"

`Externalizable` extends `Serializable` with two methods:
`writeExternal(ObjectOutput)` and `readExternal(ObjectInput)`.
You control exactly which fields are written and read.

Differences from `Serializable`:

- `Externalizable` calls the no-arg constructor BEFORE `readExternal()`
  (required - class MUST have a public no-arg constructor)
- `Serializable` bypasses constructors entirely
- `Externalizable` is typically 2-3x faster (no reflection) but more verbose

When to use `Externalizable`:

1. Performance-critical serialization in hot paths (game state, HPC data)
2. Custom field format needed (compress, encrypt, rename fields)
3. Version migration: old format has different field order than new class

When to use `Serializable`:

1. Simple persistence of internal objects (session state, cache entries)
2. Speed of implementation matters more than runtime performance

In practice, most new code should use neither - use Jackson for JSON,
protobuf for binary. `Externalizable` is a niche optimization for
specific high-performance binary protocols.

_What separates good from great:_ Knowing `Externalizable` calls the
no-arg constructor (different from `Serializable`) and the requirement
for a public no-arg constructor.

---

---

# Java Reflection: Class, Method, Field - Performance and Security Cost

**Interview Weight:** medium - Expected at mid-to-senior level when
discussing frameworks like Spring, Hibernate, JUnit, or writing
generic utilities. The performance cost and Java 9+ module system
impact are standard follow-up questions.

---

### 🎯 Model Answer

Reflection is Java's runtime introspection API (`java.lang.reflect`).
It lets code inspect and modify class structure - fields, methods,
constructors, annotations - at runtime without compile-time type
knowledge.

Core classes: `Class<?>` (type metadata), `Field` (member variables),
`Method` (callable methods), `Constructor<?>` (object creation).
Access pattern: get a `Class` object via `.getClass()`,
`ClassName.class`, or `Class.forName("pkg.Name")` - then query it.

Key cost: reflection bypasses JIT optimizations and incurs access-
checking overhead per call. In hot paths it can be 50-300x slower
than direct calls. Mitigations: cache `Method`/`Field` objects,
call `setAccessible(true)` once (removes per-call checks), or use
`MethodHandle` (Java 7+) which the JIT can compile to native speed.

Security cost: `setAccessible(true)` requires the target package to
be `open` in the module system (Java 9+). Accessing non-opened
packages throws `InaccessibleObjectException` - the primary source
of Java 8-to-11/17 migration failures in frameworks.

---

### 📖 Concept Explanation

**Core type hierarchy:**

```text
java.lang.reflect
  Class<T>          - entry point; one instance per loaded type
    getDeclaredFields()   - all fields in THIS class (incl private)
    getFields()           - public fields incl. inherited
    getDeclaredMethods()  - all methods in THIS class
    getMethods()          - public methods incl. inherited
  Field             - access / modify instance and static fields
  Method            - invoke methods with Object[] args
  Constructor<T>    - create instances
  AccessibleObject  - setAccessible(true / false)
  Modifier          - decode access flags (public, static, final)
```

> **Diagram walkthrough:** `Class<T>` is the entry point for all
> reflection. `getDeclaredX()` returns members for that class only
> (private included, inherited excluded). `getX()` returns public
> members including inherited ones. Walking `getSuperclass()` with
> `getDeclaredFields()` at each step is the correct pattern for
> full field enumeration.

**Declared vs. inherited - the critical distinction:**

```java
// BAD: misses private fields in parent classes
Field[] fields = MyEntity.class.getFields(); // only public+inherited

// GOOD: full traversal including private fields
Class<?> c = MyEntity.class;
while (c != null && c != Object.class) {
    for (Field f : c.getDeclaredFields()) {
        f.setAccessible(true);
        // process all fields including private
    }
    c = c.getSuperclass();
}
```

> **Code walkthrough:** `getFields()` only returns public fields,
> missing private/protected ones and excluding inherited private
> fields even in getDeclaredFields(). The loop pattern above is how
> ORMs (Hibernate, EclipseLink) walk entity hierarchies for dirty
> checking and SQL generation. Terminating at `Object.class`
> prevents processing root Object fields.

**Access cost model:**

```text
Approach              Typical cost    JIT-compilable?
------------------------------------------------------
Direct method call    ~1 ns           Yes
MethodHandle          ~3 ns           Yes (after warmup)
Method.invoke cached  ~50-100 ns      No
Method.invoke lookup  ~300-1000 ns    No
Class.forName()       1-100 ms        No (I/O + classinit)
```

**setAccessible(true) and the module system:**

Before Java 9: `setAccessible(true)` worked on any field anywhere.
After Java 9: it only works if the package is explicitly `open` in
the module descriptor. Calling it on a non-open package throws
`InaccessibleObjectException`. The exception message identifies
exactly which `opens` directive is missing.

---

### 💻 Code Example

**BAD - Reflection lookup in a tight loop:**

```java
// BAD: getDeclaredMethod() + invoke() every iteration
for (int i = 0; i < 1_000_000; i++) {
    Method m = obj.getClass()
                  .getDeclaredMethod("process");
    m.invoke(obj); // lookup + access check every call
}
```

> **Code walkthrough:** `getDeclaredMethod()` scans the class's
> method table on every call - no caching by default. `invoke()`
> performs an access-permission check every call. One million
> iterations: roughly 300ms vs 1ms for a direct call. This pattern
> appears in poorly written serialization code and early Spring
> versions. The fix: cache and setAccessible once.

**GOOD - Cache Method, setAccessible once:**

```java
// GOOD: cache outside loop, remove per-call access check
Method m = obj.getClass()
              .getDeclaredMethod("process");
m.setAccessible(true); // removes per-call permission check
for (int i = 0; i < 1_000_000; i++) {
    m.invoke(obj); // ~50-100ns, down from ~300ns
}
// Best alternative for hot paths: MethodHandle
MethodHandle mh = MethodHandles.lookup()
    .unreflect(m);
for (int i = 0; i < 1_000_000; i++) {
    mh.invoke(obj); // JIT-compiled, ~1-3ns
}
```

> **Code walkthrough:** Caching the `Method` object eliminates
> repeated lookup. `setAccessible(true)` removes the per-call
> security check - a significant part of reflection overhead.
> `MethodHandle` via `unreflect()` converts the cached Method to a
> JIT-compilable handle - essential for any reflective code in
> hot paths. Spring's `ReflectionUtils` and Jackson's
> `BeanPropertyWriter` use exactly this pattern.

**Failure example - Java 9+ InaccessibleObjectException:**

```java
// FAILS on Java 9+ when accessing non-opened packages
Field f = String.class.getDeclaredField("value");
f.setAccessible(true); // InaccessibleObjectException!
// java.lang is NOT opened to unnamed modules by default

// FIX (migration only): --add-opens java.base/java.lang=ALL-UNNAMED
// PROPER FIX: use public String API instead of hacking internals
```

> **Code walkthrough:** Java 9 modules prevent reflective access to
> non-exported packages. The exception message is actionable -
> it names the exact module and package. `--add-opens` is a
> migration crutch for legacy code. The real fix is always to use
> public APIs. Many Java 8 frameworks required `--add-opens` when
> first migrating; modern versions are updated to avoid it.

---

### 👥 Answers by Seniority

**Junior:** Reflection lets Java code inspect and invoke methods or
access fields at runtime via `Class`, `Method`, and `Field` objects.
You get a `Class` with `.getClass()` or `Class.forName("name")`.
Frameworks like Spring use it to discover and wire components
without knowing your class at compile time.

**Mid-level:** `getDeclaredMethods()` gives private members of the
specific class; `getMethods()` gives public + inherited. Use
`setAccessible(true)` to bypass visibility. Cache `Method` objects
outside loops - each lookup is expensive. Under Java 9+ modules,
`setAccessible` only works on `open` packages; otherwise you get
`InaccessibleObjectException`. For high-frequency invocation, use
`MethodHandle` which the JIT can compile.

**Senior:** The performance cost is dominated by per-call access
checking and JNI invocation. Cache `Method`/`Field` objects, call
`setAccessible(true)` once. Replace with `MethodHandle` via
`Lookup.unreflect()` for JIT-compilable zero-cost invocation. In
Java 9+ modules, you need `opens` directives or `--add-opens` for
cross-module access. Understand the `Declared` vs non-`Declared`
pattern for full member traversal including private inherited fields.

_What separates good from great:_ Knowing that `MethodHandle` is
the implementation mechanism behind `invokedynamic` - the JVM
instruction powering lambdas, string concatenation
(`StringConcatFactory`), and pattern matching switches.

---

### ❌ Common Misconceptions

**"getDeclaredFields() includes inherited fields"** - False. It
returns only fields declared in that specific class. Walk
`getSuperclass()` to get the full inheritance hierarchy. Forgetting
this causes ORM field mapping bugs when entity classes extend
a base `@MappedSuperclass`.

**"Reflection is always slow"** - False. The bottleneck is per-call
access checking and method lookup. Cache `Method` objects, use
`setAccessible(true)`, and use `MethodHandle` for hot paths.
Spring's `BeanFactory` and Jackson process millions of reflective
operations per second with proper caching.

**"setAccessible(true) works everywhere in modern Java"** - False
since Java 9. It throws `InaccessibleObjectException` for
non-open packages. This is intentional security - modules protect
JDK internals from reflection.

**"Reflection bypasses type safety"** - Partly false. `invoke()`
returns `Object` so compile-time type safety is lost at the call
site, but the JVM still enforces types at runtime. A type mismatch
throws `ClassCastException`, not a silent memory corruption.

---

### 💥 Failure Modes and Diagnosis

**F1 - InaccessibleObjectException (Java 9+ modules)**

Symptom: `InaccessibleObjectException: Unable to make ... accessible`
Cause: `setAccessible(true)` on a field/method whose package is not
`open` in the module system.
Fix: Add `--add-opens module/package=ALL-UNNAMED` (migration) or
use public APIs (proper fix).

```text
Exception message tells you exactly what to add:
  "module java.base does not 'opens' java.lang to unnamed module"
  --> --add-opens java.base/java.lang=ALL-UNNAMED
```

**F2 - Performance regression in hot path**

Symptom: profiler shows `sun.reflect.GeneratedMethodAccessorN`
or `jdk.internal.reflect` consuming significant CPU.
Cause: uncached `Method` objects or missing `setAccessible(true)`.

```java
// Diagnostic: profile shows reflection in top 10 methods
// Fix: cache Method outside loop + setAccessible(true) once
// Then: replace with MethodHandle if still a bottleneck
```

**F3 - Missing private fields from superclass**

Symptom: ORM/mapper misses fields from parent class silently.
Cause: `getFields()` only returns public + inherited public.
`getDeclaredFields()` only returns this class's own fields.
Fix: Walk `getSuperclass()` with `getDeclaredFields()` at each step.

---

### 🎤 Interview Deep-Dive

| Time    | Focus                                    |
| ------- | ---------------------------------------- |
| 0-2 min | What is reflection, core classes         |
| 2-5 min | Declared vs inherited, traversal pattern |
| 5-7 min | Performance costs and mitigation         |
| 7-9 min | Module system impact (Java 9+)           |
| 9+ min  | MethodHandle, framework internals        |

**Q1 (CONCEPTUAL):** What is the difference between `getFields()`
and `getDeclaredFields()`?

`getFields()` returns all **public** fields of the class AND all
its superclasses/interfaces. `getDeclaredFields()` returns ALL
fields (public, protected, package-private, private) declared
in that specific class only - NOT inherited fields. For complete
field traversal (e.g., ORM dirty checking), walk `getSuperclass()`
calling `getDeclaredFields()` at each step. This distinction
applies equally to `getMethods()` and `getConstructors()`.

_What separates good from great:_ Knowing why ORMs call
`getDeclaredFields()` in a loop rather than `getFields()` - they
need private field access and need to handle each class in the
hierarchy separately to call `setAccessible(true)`.

**Q2 (PERFORMANCE):** Why is reflection slower than direct calls,
and how do you optimize it?

Reflection overhead comes from three layers: (1) Method lookup -
scanning the class's method table by name/signature, (2) Access
checking - verifying caller permissions on every `invoke()`, and
(3) JNI invocation overhead. After caching the `Method` object,
the dominant cost is access checking (~50-100ns per call vs ~1ns
direct). `setAccessible(true)` removes the access check entirely.
For the hottest paths, `MethodHandle` via `Lookup.unreflect()`
is JIT-compilable and reaches direct-call performance after warmup.

_What separates good from great:_ Knowing `MethodHandle` is not
just a wrapper - it uses `invokedynamic` under the hood, and the
JIT can inline across `MethodHandle` call sites just as it does for
direct calls.

**Q3 (DEBUGGING):** You migrate from Java 8 to Java 17 and get
`InaccessibleObjectException` in production. How do you fix it?

The exception message names the exact module and package. Step 1:
read it - "module X does not 'opens' Y to unnamed module". Step 2
(immediate): add `--add-opens X/Y=ALL-UNNAMED` to JVM startup args
to restore previous behavior. Step 3 (proper): check if a
newer version of the library uses public APIs instead of
reflection-based internals access. Step 4: file a support ticket
if using a vendor library. This is a module-system security feature,
not a regression - the module system prevents libraries from
tampering with JDK internals.

_What separates good from great:_ Understanding the long-term goal
is to eliminate `--add-opens`, not just add them.

**Q4 (TRADE-OFF):** When would you prefer code generation over
reflection?

Reflection: right when the set of classes is open/unknown at
build time (Spring DI scanning, Jackson JSON, JUnit discovery).
Code generation (Lombok, MapStruct, Dagger, APT): right when the
set of classes is known at build time, performance is critical,
or you're targeting GraalVM native image. Trade-off: reflection =
zero build-time setup, maximum flexibility, runtime cost; code
generation = compile-time verification, zero runtime overhead,
but requires explicit annotation processing setup.
GraalVM native image cannot use reflection without a
`reflect-config.json` file - forcing explicit enumeration of all
reflected classes, which defeats dynamic reflection entirely.

_What separates good from great:_ Naming GraalVM native image as
the forcing function pushing Spring 6 toward AOT code generation
instead of runtime reflection.

**Q5 (SECURITY):** What are the security implications of
`setAccessible(true)`?

`setAccessible(true)` bypasses Java visibility rules, making
private fields and methods accessible. Risks: (1) field tampering -
attackers who can execute code can modify `final` fields including
security credentials; (2) private method invocation - validation
and security checks inside private methods can be bypassed;
(3) Historical mitigation was `SecurityManager` with
`ReflectPermission("suppressAccessChecks")` - but `SecurityManager`
is deprecated in Java 17 (JEP 411) and removed in Java 21.
Current mitigation: the module system's `opens` mechanism. Packages
not explicitly opened cannot be accessed reflectively by
untrusted code.

_What separates good from great:_ Knowing that SecurityManager
removal shifted responsibility entirely to module encapsulation,
and that the module system's selective `opens` is a stronger model
than the all-or-nothing SecurityManager approach.

**Q6 (BEHAVIORAL):** Describe debugging a reflection issue in
production.

Structure: S-T-A-R.
Situation: Post-Java 11 upgrade, a serialization library threw
`InaccessibleObjectException` on specific data types.
Task: Restore stability quickly, then eliminate the root cause.
Action: Read exception message - identified exact module/package.
Added targeted `--add-opens` JVM arg. Traced the library call site.
Found the library was accessing `java.io.ObjectStreamClass` internals.
Filed issue with maintainers; upgraded to a version that uses
public API.
Result: Production stable in under 30 minutes. `--add-opens`
removed after library upgrade 6 weeks later.

_What separates good from great:_ Following up to eliminate the
`--add-opens` rather than treating it as permanent configuration.

**Q7 (KNOWLEDGE):** What is `MethodHandle` and how does it differ
from `Method.invoke()`?

A `MethodHandle` is a typed, directly invokable reference obtained
via `MethodHandles.Lookup`. Key differences: (1) JIT-compilable -
`MethodHandle.invokeExact()` can be inlined by the JIT; `Method.invoke()`
cannot. (2) Type safety - `MethodHandle` carries a `MethodType`
encoding argument and return types; `Method.invoke()` uses `Object...`
and returns `Object`. (3) Performance - after warmup, `invokeExact()`
is ~1-3ns (direct call equivalent); `Method.invoke()` stays
at ~50-100ns. (4) Module access - both need `setAccessible` or
`opens` for private/non-exported members. Use `MethodHandle` for
any reflective code in warm paths. Use `Lookup.unreflect(Method)`
to get a `MethodHandle` from a cached `Method` object.

_What separates good from great:_ Knowing that `invokedynamic`
bytecode uses `MethodHandle` bootstrap methods - lambdas, string
concatenation, and switch expressions are all lowered to
`invokedynamic` calls backed by `MethodHandle` chains.

**Q8 (SCALE):** What profiler signals indicate reflection is a
bottleneck and how do you fix it at scale?

Profiler signals: (1) CPU hotspot showing `sun.reflect.GeneratedMethodAccessorN`
or `jdk.internal.reflect.NativeMethodAccessorImpl.invoke()`, (2) High
allocation rate from boxing primitive return values from `invoke()`,
(3) Lock contention on `Class.getDeclaredMethod()` (class metadata
is synchronized in some JVMs). Fix path: cache all `Method`/`Field`
objects in `ConcurrentHashMap<String, Method>` at startup, call
`setAccessible(true)` once, replace with `MethodHandle` for the
hottest call sites, use `VarHandle` (Java 9+) for field access
with atomic operations. Measure each step - real-world reflection
bottlenecks often yield 5-20x improvement from just caching
and `setAccessible`.

_What separates good from great:_ Knowing `VarHandle` (not just
`MethodHandle`) - it provides `compareAndSet`, `getAndAdd`, and
memory ordering semantics on fields without `AtomicReference`
allocation overhead.

**Q9 (SYSTEM):** How has Spring's use of reflection evolved with
Spring 6 and AOT compilation?

Spring historically used reflection for: classpath scanning
(`@Component`), field injection (`@Autowired` private fields),
lifecycle callbacks (`@PostConstruct`), and proxy creation
(CGLIB subclassing). Spring 6 (Spring Boot 3) introduced AOT
compilation: at build time, Spring generates code that replaces
reflective field injection with direct method calls and generates
`reflect-config.json` hints for GraalVM native image. In native
mode, `@Autowired` field injection is replaced by generated code
calling the setter/constructor directly. This enables native
executables with near-zero startup time but removes the "magic"
of runtime classpath scanning. Developers must explicitly annotate
types used only via reflection with `@RegisterReflectionForBinding`.

_What separates good from great:_ Understanding this represents
a fundamental architectural shift - Spring is moving from
"flexible at runtime" to "predictable at build time" to enable
native compilation.

---

---

# Java NIO: Channels, Buffers, Selectors, and Non-Blocking I/O

**Interview Weight:** medium - Appears in backend/networking interviews;
tests knowledge beyond basic java.io streams.

---

### 🎯 Model Answer

**30 seconds:**

> Java NIO (java.nio, Java 1.4) adds non-blocking I/O to Java.
> Key abstractions: `Buffer` (typed arrays: ByteBuffer, IntBuffer),
> `Channel` (bidirectional I/O endpoint: files, sockets),
> `Selector` (single thread monitors multiple channels for readiness).
> The selector enables handling thousands of connections in one thread -
> the basis of Netty, Tomcat NIO, and all modern Java async servers.

**3 minutes (Senior):**

> **Buffer:** a fixed-capacity array with three pointers: `position`
> (next read/write), `limit` (end of valid data), `capacity` (total size).
> Pattern: write data, call `flip()` (sets `limit = position, position = 0`
> for reading), read data, call `clear()` or `compact()` for next write.
> Direct buffers (`ByteBuffer.allocateDirect()`) are allocated outside
> the Java heap (native memory), avoiding a copy when doing OS I/O calls.
>
> **Channel:** similar to streams but bidirectional and can be non-blocking.
> `FileChannel` (always blocking, supports `transferTo()` for zero-copy
> file-to-socket transfer), `SocketChannel`, `ServerSocketChannel`,
> `DatagramChannel`.
>
> **Selector:** a single thread calls `selector.select()` which blocks
> until at least one channel is ready for an operation (accept, read,
> write). Returns a set of `SelectionKey`s. Each key has: channel,
> selector, interest ops (what to monitor), ready ops (what's ready).
> This multiplexes I/O events across many channels with one thread
> (vs one thread per connection in classic blocking I/O).
>
> **NIO.2 (Java 7)**: `java.nio.file` - modern file API. `Path`,
> `Files`, `WatchService` for filesystem events, `AsynchronousFileChannel`
> for async file I/O.

**Framework:** BUFFER (position/limit/capacity + flip/clear) +
CHANNEL (bidirectional, non-blocking capable) + SELECTOR (event loop, multiplexing)

- NIO2 (Path, Files, Async)

_Adapting up:_ Discuss scatter/gather I/O (reading into multiple Buffers
in one syscall), memory-mapped files (`MappedByteBuffer`), and how Netty
abstracts over NIO with ByteBuf.

_Adapting down:_ NIO channels are like streams but bidirectional and
non-blocking. Buffer has position and limit. Selector monitors multiple
channels.

**Blank Mind Recovery:**

**(1) Restate:** "NIO: Buffer (typed memory), Channel (bi-directional I/O),
Selector (event multiplexer). Non-blocking sockets allow one thread to
handle many connections. NIO.2 adds Path/Files/async."

**(2) First principles:** "Classic blocking I/O: one thread per connection,
thread blocks waiting for data. NIO non-blocking: register interest in
data, thread continues; selector notifies when data arrives. C10K problem:
need one thread for 10,000 connections."

**(3) Bridge:** "Old I/O is like a restaurant where each waiter serves
exactly one table and stands there waiting for the customer to decide.
NIO Selector is one waiter with a radio - they handle 100 tables and
the radio (selector) alerts them which table needs attention."

---

### 📘 Concept Explanation

**Buffer state machine:**

```
Buffer lifecycle:
  1. Allocate:  allocate(capacity)
     position=0, limit=capacity, capacity=capacity

  2. Write data: buf.put(bytes) / channel.read(buf)
     position advances with each write

  3. flip():     limit = position; position = 0
     Now ready for reading from the start

  4. Read data:  buf.get() / channel.write(buf)
     position advances with each read

  5. After reading: clear() -> position=0, limit=capacity (full reset)
              OR   compact() -> copy remaining unread to start (partial reset)

Key methods:
  remaining()   = limit - position (how much to read)
  hasRemaining() = remaining() > 0
  rewind()      = position=0, limit unchanged (re-read same data)
  mark()/reset() = mark current position, reset to it later
```

**Buffer types and direct buffers:**

```java
// Heap buffer: backed by Java byte array (JVM heap)
ByteBuffer heapBuf = ByteBuffer.allocate(1024);

// Direct buffer: backed by native memory (off-heap)
ByteBuffer directBuf = ByteBuffer.allocateDirect(1024);
// Direct buffers bypass Java heap -> OS I/O operations
// don't need to copy through heap buffer first
// Faster for large I/O, but slower to allocate, no GC management

// Views for typed access:
IntBuffer intBuf = heapBuf.asIntBuffer(); // reads as int[]
LongBuffer longBuf = heapBuf.asLongBuffer();
```

**Selector pattern:**

```java
// Non-blocking server with Selector:
ServerSocketChannel server = ServerSocketChannel.open();
server.bind(new InetSocketAddress(8080));
server.configureBlocking(false); // must be non-blocking for selector

Selector selector = Selector.open();
server.register(selector, SelectionKey.OP_ACCEPT);

while (true) {
    selector.select(); // blocks until at least one channel ready

    Iterator<SelectionKey> iter =
        selector.selectedKeys().iterator();
    while (iter.hasNext()) {
        SelectionKey key = iter.next();
        iter.remove(); // MUST remove from selectedKeys!

        if (key.isAcceptable()) {
            SocketChannel client =
                ((ServerSocketChannel) key.channel()).accept();
            client.configureBlocking(false);
            client.register(selector, SelectionKey.OP_READ);
        } else if (key.isReadable()) {
            SocketChannel ch = (SocketChannel) key.channel();
            ByteBuffer buf = ByteBuffer.allocate(1024);
            int bytesRead = ch.read(buf);
            if (bytesRead == -1) { ch.close(); }
            else {
                buf.flip();
                ch.write(buf); // echo back
            }
        }
    }
}
```

**NIO.2 (Java 7) - Modern file API:**

```java
// Path: immutable file system path
Path file = Path.of("/data/config.yml");
Path resolved = Path.of("/data").resolve("config.yml");

// Files: bulk operations
String content = Files.readString(file);  // Java 11
List<String> lines = Files.readAllLines(file);
Files.writeString(file, content);         // Java 11
Stream<Path> dir = Files.walk(Path.of("/data")); // lazy traversal

// WatchService: filesystem event monitoring
WatchService watcher = FileSystems.getDefault().newWatchService();
file.getParent().register(watcher,
    StandardWatchEventKinds.ENTRY_CREATE,
    StandardWatchEventKinds.ENTRY_MODIFY);
WatchKey key = watcher.take(); // block for event
```

---

### 💻 Code Example

#### Zero-copy file transfer with `transferTo`

```java
import java.nio.*;
import java.nio.channels.*;
import java.nio.file.*;
import java.io.*;

public class ZeroCopyTransfer {

    // BAD: traditional copy - data goes through Java heap
    public static void traditionalCopy(
            String src, String dst) throws IOException {
        try (InputStream in = new FileInputStream(src);
             OutputStream out = new FileOutputStream(dst)) {
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) > 0) {
                out.write(buf, 0, n);
            }
        }
        // Data flow: disk -> kernel buffer -> Java heap -> kernel -> disk
        // Two kernel-userspace copies
    }

    // GOOD: NIO transferTo - may use sendfile() syscall
    public static void zeroCopyCopy(
            String src, String dst) throws IOException {
        try (FileChannel in = FileChannel.open(Path.of(src),
                 StandardOpenOption.READ);
             FileChannel out = FileChannel.open(Path.of(dst),
                 StandardOpenOption.CREATE,
                 StandardOpenOption.WRITE)) {
            in.transferTo(0, in.size(), out);
        }
        // Data flow: disk -> kernel buffer -> disk
        // May use sendfile(): OS-level zero-copy
        // No Java heap involvement for data
    }
}
```

> **Code walkthrough:** `FileChannel.transferTo()` asks the OS to copy
> data directly between two file descriptors. The JVM implementation
> calls `sendfile()` on Linux if available - the data never enters the
> Java heap. This eliminates two kernel-userspace copies and reduces
> CPU usage by ~50% for large file copies. For file-to-socket transfer
> (serving a file over HTTP), `transferTo(socketChannel)` is the
> foundation of efficient static file serving in NIO-based frameworks.

---

### 🎓 Answers by Seniority

**Junior:** NIO provides non-blocking I/O. `Channel` replaces streams.
`Buffer` holds data (use `flip()` to switch from write to read mode).
`java.nio.file.Files` and `Path` are the modern file API.

**Mid-level:** Buffer state: position, limit, capacity. `flip()` prepares
buffer for reading after writing. Selector enables one thread to handle
many non-blocking channels. `FileChannel.transferTo()` enables zero-copy
file transfer using OS `sendfile()`. Direct buffers avoid heap allocation
for I/O paths.

**Senior:** The Selector pattern is the basis of all scalable NIO servers.
Each `SelectionKey` must be removed from `selectedKeys()` manually after
processing - failing to do so causes the selector to repeatedly report
the same key as ready, consuming 100% CPU. Memory-mapped files
(`FileChannel.map()`) allow treating a file as a `ByteBuffer` backed
by OS page cache - useful for large read-only datasets.

**Staff:** Modern application code rarely uses NIO directly - Netty,
Vertx, or Spring WebFlux provide higher-level abstractions. Understanding
NIO internals is needed to diagnose Netty issues (buffer leak, selector
loop wakeups) and to tune direct buffer sizing
(`-XX:MaxDirectMemorySize`). Java 19+ Virtual Threads restore blocking
I/O ergonomics: each virtual thread can block without holding an OS
thread, making NIO's complexity largely unnecessary for new code.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                           | Reality                                                                                                                                                                                      | Danger                                                              |
| --- | ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 1   | `FileChannel` is non-blocking                           | `FileChannel` does NOT support non-blocking mode. File I/O in Java NIO is always synchronous (blocking). Only `SocketChannel`, `ServerSocketChannel`, `DatagramChannel` support non-blocking | Assuming file reads are non-blocking; CPU/thread blocking surprises |
| 2   | Forgetting `iter.remove()` on selectedKeys is harmless  | If a key is not removed from `selectedKeys` after handling, the Selector reports it as ready on the next `select()` call even if no new event occurred - causing a 100% CPU busy loop        | Selector spinning at 100% CPU, no actual I/O processed              |
| 3   | Direct ByteBuffer is always faster than heap ByteBuffer | Direct buffers are faster for large I/O (avoid heap-to-native copy). For small buffers or JVM-internal processing (parsing), heap buffers are faster (no JNI boundary crossing)              | Blanket use of direct buffers adds allocation cost for small I/O    |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - NIO Selector busy loop (100% CPU)**

Symptom: Selector thread pegged at 100% CPU with no I/O activity.

Root cause: Either `selectedKeys` not cleared after processing, or the
JDK selector implementation has the "spurious wakeup" bug (known JDK
issue pre-1.8u60 on Linux: epoll edge trigger mis-fires).

Diagnostic: Stack trace shows thread in tight `selector.select()` loop.
selectedKeys count is non-zero but no I/O is ready.

Fix: Always call `iter.remove()` for each processed key. For the JDK
bug: rebuild the Selector when detection threshold is exceeded
(this is what Netty does internally).

---

**Failure 2 - Buffer not flipped before channel write**

Symptom: Channel write sends 0 bytes or garbage data.

Root cause: Data written to ByteBuffer, then `channel.write(buf)` called
without `buf.flip()`. Buffer's position is at the end, remaining = 0,
nothing to write.

Fix: Always call `flip()` to switch from write mode to read mode before
writing a ByteBuffer to a Channel. Use `rewind()` if you need to
re-read the same buffer.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                              |
| ---------------- | ----------------------------------------------------------------- |
| 20 min           | Buffer position/limit/flip; Channel vs Stream; Selector overview  |
| 40 min           | Add Selector event loop code; transferTo; NIO.2                   |
| 1 hour           | Add direct buffers; FileChannel blocking; Java 19 virtual threads |

---

**[MID] Q1: What does `ByteBuffer.flip()` do and when must you call it?**
[CONCEPTUAL]

_Why they ask:_ A very common NIO beginner mistake.

_Likely follow-up:_ "What is the difference between `flip()` and `rewind()`?"

`ByteBuffer.flip()` sets `limit = position; position = 0`. It transitions
the buffer from "write mode" to "read mode":

- After writing data: position is at the end of written data, limit is capacity.
- After `flip()`: position is 0 (start of data), limit is end of written data.
  `remaining()` = amount of data written.

You must call `flip()` after writing data to a buffer BEFORE:

- Passing the buffer to `Channel.write(buf)` (to send data)
- Calling `buf.get()` to read data

Without `flip()`, `Channel.write(buf)` sees `remaining() = 0` and writes
nothing.

`flip()` vs `rewind()`:

- `flip()`: sets both limit and position (`limit=pos; pos=0`). Use after write.
- `rewind()`: sets `position=0`, limit unchanged. Use to re-read already-flipped data.

_What separates good from great:_ Knowing that `rewind()` re-reads without
knowing where the data ends (limit unchanged), while `flip()` sets limit to
the actual data boundary.

---

**[SENIOR] Q2: How does a Selector enable one thread to handle multiple
connections?** [CONCEPTUAL]

_Why they ask:_ Tests understanding of the key NIO scalability mechanism.

_Likely follow-up:_ "How many connections can a single selector handle?"

Classic blocking I/O: each connection requires a dedicated thread. Thread
is blocked in `read()` waiting for data. 10,000 connections = 10,000 threads.
Each thread uses ~512KB-1MB stack = 5-10GB just for thread stacks.

NIO Selector: channels are registered with interest ops (OP_ACCEPT, OP_READ,
OP_WRITE). One thread calls `selector.select()` which delegates to the OS
`epoll`/`kqueue`/`select` system call. The OS returns when one or more
channels have data ready. The thread processes ready channels, then calls
`select()` again.

This is the "event loop" or "reactor" pattern. One thread handles many
connections because it is never blocked waiting for a single connection.
It only runs when there is actual I/O to process.

Connection limit: OS-dependent. Linux epoll supports millions of file
descriptors. JVM overhead per channel is small (SelectionKey object).
Practical limit: hundreds of thousands to low millions per JVM.

_What separates good from great:_ Naming the OS primitives (`epoll` on Linux,
`kqueue` on macOS/BSD) and that Selector is a wrapper around them.

---

**[SENIOR] Q3: What is a memory-mapped file and when would you use it?**
[TRADE-OFF]

_Why they ask:_ Tests knowledge of advanced NIO for large data processing.

_Likely follow-up:_ "What are the risks of MappedByteBuffer?"

`FileChannel.map(mode, position, size)` returns a `MappedByteBuffer` backed
by the OS page cache instead of a Java heap array. Reading from the buffer
triggers the OS to page in file data from disk. No explicit read/write system
calls needed - file access appears as memory access.

Use cases:

- **Read-only large datasets**: load a 100GB file, access arbitrary offsets
  in O(1) without loading the whole file into memory. The OS manages what
  is in memory (page cache).
- **Shared memory between processes**: two JVMs mapping the same file see
  the same data (IPC via shared memory).
- **High-performance parsing**: walk a large binary file with sequential
  buffer access patterns.

Risks:

1. **`unmap()` does not exist in Java**: there is no safe way to unmap a
   `MappedByteBuffer` before GC collects it. The file descriptor and mapping
   stay open until GC runs. This prevents file deletion on Windows.
2. **SIGBUS on truncated file**: if the file is truncated while mapped,
   accessing the truncated region causes `SIGBUS` (native crash, not exception).
3. **Direct memory, not heap**: not visible to `-Xmx`, managed by OS.

_What separates good from great:_ The `unmap()` absence (the workaround is
a reflection call in pre-Java 21, or the `Cleaner` API in Java 9+) and the
SIGBUS crash risk.
