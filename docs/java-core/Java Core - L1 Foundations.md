---
layout: default
title: "Java Core - L1 Foundations"
parent: "Java Core APIs"
nav_order: 2
permalink: /java-core/l1-foundations/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Iterable, Iterator, and the Enhanced For Loop Contract](#iterable-iterator-and-the-enhanced-for-loop-contract) | low-medium |
| 2 | [Comparable vs Comparator: Natural vs External Ordering](#comparable-vs-comparator-natural-vs-external-ordering) | low-medium |
| 3 | [List, Set, Map, Queue: The Four Core Collection Interfaces](#list-set-map-queue-the-four-core-collection-interfaces) | low |
| 4 | [Checked vs Unchecked Exceptions: The Historical Design Debate](#checked-vs-unchecked-exceptions-the-historical-design-debate) | medium |
| 5 | [Exception Hierarchy: Throwable, Error, Exception, RuntimeException](#exception-hierarchy-throwable-error-exception-runtimeexception) | low-medium |

---

# Iterable, Iterator, and the Enhanced For Loop Contract

**Interview Weight:** low-medium - Appears in collections internals
discussions; tests whether you understand what `for-each` actually does.

---

### 🎯 Model Answer

**30 seconds:**

> `Iterable<T>` is the interface that enables the enhanced for loop
> (`for (T item : collection)`). It has one method: `iterator()`.
> `Iterator<T>` has `hasNext()` and `next()` - the compiler expands
> the for-each into a while loop calling these. Any class implementing
> `Iterable` can be used in a for-each. The contract: `next()` throws
> `NoSuchElementException` if `hasNext()` is false.

**3 minutes (Senior):**

> The enhanced for loop is syntactic sugar. `for (String s : list)`
> compiles to:
>
> ```
> Iterator<String> it = list.iterator();
> while (it.hasNext()) {
>     String s = it.next();
>     // body
> }
> ```
>
> This means: (1) the collection is evaluated once and `iterator()`
> called once, (2) the loop variable is local to each iteration,
> (3) the iterator state is hidden - you cannot call `it.remove()`
> from inside the loop because `it` is not accessible.
>
> `Iterator.remove()` is the only safe way to remove during iteration.
> Any structural modification through the collection directly (not
> through the iterator) increments `modCount`, which the iterator
> checks on each `next()` call - causing `ConcurrentModificationException`.
>
> For custom types to support for-each, implement `Iterable<T>` and
> return an `Iterator<T>`. The iterator's state is a cursor into the
> data structure; each `Iterator` instance is independent so multiple
> loops can run concurrently on the same collection.

**Framework:** INTERFACES (Iterable -> iterator()) + COMPILATION
(for-each to while) + CONTRACT (modCount, remove rule)

_Adapting up:_ Discuss `Spliterator` (Java 8) - the parallel-capable
iterator used by the Streams API, with `tryAdvance()` and `forEachRemaining()`.

_Adapting down:_ for-each works because the collection is `Iterable`.
`Iterator` has `hasNext()` and `next()`.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how for-each works - it compiles
to a while loop using `Iterator`. `Iterable` provides the iterator,
`Iterator` has hasNext/next."

**(2) First principles:** "To traverse a collection, you need a cursor
that moves through elements. The Iterator pattern separates the cursor
(Iterator) from the collection (Iterable) so multiple cursors can
exist independently."

**(3) Bridge:** "Iterator is like a bookmark: the book (Iterable) stays
put, the bookmark (Iterator) tracks your position. Multiple people can
have separate bookmarks in the same book."

---

### 📘 Concept Explanation

**What it is:**

`java.lang.Iterable<T>`: one method: `Iterator<T> iterator()`. Implemented
by all `Collection` subtypes plus arrays (via for-each compiler support).

`java.util.Iterator<T>`: three methods:

- `boolean hasNext()`: returns true if more elements remain
- `T next()`: returns next element and advances cursor
- `default void remove()`: removes the last element returned by `next()`
  (optional operation - throws `UnsupportedOperationException` if not
  supported; only valid to call once per `next()` call)

**For-each compilation:**

```java
// Source:
for (String s : list) { System.out.println(s); }

// Compiled to:
for (Iterator<String> it = list.iterator(); it.hasNext(); ) {
    String s = it.next();
    System.out.println(s);
}
```

**Safe removal during iteration:**

```java
List<String> names = new ArrayList<>(
    List.of("Alice", "Bob", "Charlie"));

// BAD: ConcurrentModificationException
for (String name : names) {
    if (name.startsWith("B")) names.remove(name); // throws!
}

// GOOD: use Iterator.remove()
Iterator<String> it = names.iterator();
while (it.hasNext()) {
    if (it.hasNext() && it.next().startsWith("B")) {
        it.remove(); // safe - updates modCount in sync
    }
}

// BETTER (Java 8): removeIf
names.removeIf(name -> name.startsWith("B"));
```

**Spliterator (Java 8):**

`Spliterator<T>` is the parallelism-aware replacement for Iterator in the
Streams API. Has `tryAdvance()` (process one element), `forEachRemaining()`
(process all), and `trySplit()` (split for parallel processing). You rarely
use it directly - `Stream` uses it internally.

---

### 💻 Code Example

#### Custom Iterable type

```java
// A range type that can be used in for-each
public class IntRange implements Iterable<Integer> {
    private final int start;
    private final int end;  // exclusive

    public IntRange(int start, int end) {
        if (end < start) throw new IllegalArgumentException(
            "end must be >= start");
        this.start = start;
        this.end = end;
    }

    @Override
    public Iterator<Integer> iterator() {
        return new Iterator<>() {
            private int current = start;

            @Override
            public boolean hasNext() {
                return current < end;
            }

            @Override
            public Integer next() {
                if (!hasNext()) throw new NoSuchElementException();
                return current++;
            }
            // remove() not supported: throws by default
        };
    }
}

// Usage:
IntRange range = new IntRange(1, 6);
for (int n : range) {
    System.out.print(n + " "); // 1 2 3 4 5
}
```

> **Code walkthrough:** `IntRange` implements `Iterable<Integer>`,
> enabling for-each. The anonymous `Iterator` holds cursor state
> (`current`) independently per iteration. Multiple loops on the same
> `IntRange` each get their own `Iterator` instance with their own
> `current` field. `NoSuchElementException` is thrown when `next()`
> is called past the end - this is the required contract.

---

### 🎓 Answers by Seniority

**Junior:** `Iterable` has one method `iterator()`. `Iterator` has
`hasNext()` and `next()`. The for-each loop uses these automatically.

**Mid-level:** The for-each compiles to a while loop using `Iterator`.
Structural modification during for-each throws
`ConcurrentModificationException` because the iterator checks `modCount`.
Use `iterator.remove()` or `list.removeIf()` to safely remove during
iteration.

**Senior:** Any class implementing `Iterable<T>` supports for-each.
`Iterator.remove()` is the only safe in-loop removal because it
synchronizes the internal `expectedModCount`. `Spliterator` (Java 8)
extends the concept for parallel stream processing via `trySplit()`.

**Staff:** Lazy iterators are a critical API design pattern: a database
cursor, a file line reader, a paginated API result. All implement
`Iterator<T>` and load data on `next()` call rather than materializing
the full result. `Files.lines()` and `ResultSet` are examples.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                               | Reality                                                                                                                                                                     | Danger                                            |
| --- | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| 1   | You can modify a collection inside a for-each loop          | Modifying through the collection (not the iterator) causes `ConcurrentModificationException`                                                                                | Runtime exception in production                   |
| 2   | `Iterator.remove()` works with any collection               | `remove()` is an optional operation. For iterators over immutable collections (`List.of()`, `Arrays.asList()`), it throws `UnsupportedOperationException`                   | Unexpected exception on "remove during iteration" |
| 3   | for-each and traditional for loop have the same performance | For `ArrayList`, they're equivalent. For `LinkedList`, for-each via `Iterator` is O(n) total; traditional indexed `get(i)` is O(n^2) because each `get` traverses from head | Accidental O(n^2) loop on LinkedList              |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - `ConcurrentModificationException` in for-each**

Symptom: `java.util.ConcurrentModificationException` from a for-each
loop.

Root cause: Structural modification (add/remove) through the collection
directly inside the loop.

Fix: Use `list.removeIf()`, `iterator.remove()`, or collect removals
and apply after the loop.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                           |
| ---------------- | ---------------------------------------------- |
| 15 min           | for-each expansion; Iterable/Iterator contract |
| 30 min           | Add safe removal patterns; Spliterator         |
| 45 min           | Implement a custom Iterable                    |

---

**[JUNIOR] Q1: What does the compiler do with a for-each loop?**
[CONCEPTUAL]

_Why they ask:_ Tests whether you know the mechanism, not just the syntax.

_Likely follow-up:_ "Can you use for-each with an array?"

The compiler expands `for (T item : collection)` to an `Iterator`-based
while loop: calls `collection.iterator()`, then loops `while(it.hasNext())`
calling `it.next()` to get each element. The iterator reference is
not accessible in the loop body.

For arrays, the compiler generates an indexed loop (arrays are not
`Iterable` - the compiler handles them specially).

_What separates good from great:_ Knowing arrays are NOT `Iterable`
(they work with for-each via special compiler handling, not via the
`Iterable` interface).

---

**[MID] Q2: Why does modifying a list inside a for-each cause an
exception?** [DEBUGGING]

_Why they ask:_ Tests understanding of the fail-fast mechanism.

_Likely follow-up:_ "Is this guaranteed to always throw?"

`ArrayList` and other `java.util` collections maintain a `modCount`
field incremented on every structural modification. The iterator
captures `expectedModCount = modCount` at creation. On each `next()`,
it checks `modCount == expectedModCount` - if they differ, throws
`ConcurrentModificationException`.

This is best-effort, not guaranteed: in a multi-threaded scenario,
the check is not synchronized and might miss some modifications.

Safe alternatives: `Iterator.remove()` (updates `expectedModCount`),
`list.removeIf()` (Java 8, single-pass safe), or collect-then-remove.

_What separates good from great:_ Knowing ConcurrentModificationException
is fail-fast best-effort, NOT a thread-safety guarantee.

---

**[SENIOR] Q3: What is `Spliterator` and when would you use it directly?**
[CONCEPTUAL]

_Why they ask:_ Tests depth of Java 8 collections internals.

_Likely follow-up:_ "How does `trySplit()` enable parallel streams?"

`Spliterator<T>` (Java 8) is the iterator for the Streams framework. Key
additions over `Iterator`:

- `tryAdvance(Consumer<T>)`: process one element; returns false when done
- `forEachRemaining(Consumer<T>)`: process remaining elements
- `trySplit()`: split into two Spliterators for parallel processing
- `estimateSize()`: approximate remaining elements for work partitioning
- `characteristics()`: flags (ORDERED, SORTED, SIZED, DISTINCT, IMMUTABLE)
  that allow the Streams framework to optimize operations

`Arrays.spliterator()` and `Collection.spliterator()` provide default
implementations. `ForkJoinPool` + `trySplit()` = parallel stream execution.

You rarely use `Spliterator` directly - it is the plumbing of `Stream.parallel()`.
Custom use: implementing a parallel-safe data source (e.g., splitting
a database result set across threads).

_What separates good from great:_ Explaining `characteristics()` flags
(e.g., `SORTED` allows skipping re-sort; `SIZED` allows exact work
partitioning without `estimateSize()` guess).

---

**[MID] Q4: DEBUGGING: A for-each loop silently visits the wrong
number of elements. What are the possible causes?** [DEBUGGING]

_Why they ask:_ Tests edge case knowledge of iterator contracts.

_Likely follow-up:_ "How would you debug it?"

Possible causes:

1. **Collection modified by another thread between iterations**: the
   iterator sees a stale snapshot or inconsistent state. May throw
   `ConcurrentModificationException` or silently skip/repeat elements.

2. **Custom `Iterator` with a bug**: `next()` advances by 2 instead of
   1, or `hasNext()` returns false early.

3. **`remove()` without advancing**: calling `remove()` twice without
   calling `next()` in between throws `IllegalStateException` - but
   if caught and ignored, it appears as skipped elements.

4. **`CopyOnWriteArrayList` snapshot**: iteration is over the snapshot
   taken when the iterator was created. Elements added after iterator
   creation are not visible. This is by design but surprises developers.

Debug: add a counter inside the loop, compare to `collection.size()`
after the loop. Enable assertions on your custom Iterator.

_What separates good from great:_ Identifying `CopyOnWriteArrayList`
snapshot behavior as a silent "missing elements" cause.

---

**[SENIOR] Q5: When is using `Iterator` directly preferable to for-each?**
[TRADE-OFF]

_Why they ask:_ Tests ability to choose between equivalent patterns.

_Likely follow-up:_ "Can you use for-each with interleaved collections?"

Prefer explicit `Iterator` when:

1. **Removal during iteration**: `iterator.remove()` is the only safe
   single-pass approach (cleaner than `removeIf` for complex conditions
   involving the previous element).

2. **Parallel iteration of two collections**: step through two lists
   simultaneously - `for-each` only works on one collection at a time.

   ```java
   Iterator<A> ia = listA.iterator();
   Iterator<B> ib = listB.iterator();
   while (ia.hasNext() && ib.hasNext()) {
       process(ia.next(), ib.next());
   }
   ```

3. **Early exit with cleanup**: when you need to know WHICH iterator
   was active when an exception occurred, having the variable in scope
   helps.

4. **Custom iterator that supports extra methods**: an iterator with
   a `peek()` method requires the variable to be in scope.

For simple traversal with no modification: for-each is cleaner.

_What separates good from great:_ The parallel iteration example -
for-each cannot traverse two collections simultaneously.

---

---

# Comparable vs Comparator: Natural vs External Ordering

**Interview Weight:** low-medium - Appears whenever sorting or
ordered collections are discussed.

---

### 🎯 Model Answer

**30 seconds:**

> `Comparable<T>` is implemented by the class itself - it defines the
> "natural ordering" via `compareTo(T other)`. Integers, Strings, Dates
> implement it. `Comparator<T>` is an external ordering strategy - a
> separate object with `compare(T a, T b)`. Use `Comparable` when the
> class has one obvious ordering. Use `Comparator` when you need multiple
> orderings, when you cannot modify the class, or when ordering is
> context-dependent.

**3 minutes (Senior):**

> `Comparable<T>` embeds ordering in the class: `String` implements
> `Comparable<String>` using lexicographic Unicode order. `Integer`
> uses numeric order. These are used by `TreeSet`, `TreeMap`, and
> `Collections.sort()` without a `Comparator` argument.
>
> `Comparator<T>` externalizes ordering: `Collections.sort(list, cmp)`
> or `TreeSet<T>(comparator)`. Lambda syntax makes it concise:
> `Comparator.comparing(Person::getAge).thenComparing(Person::getName)`.
>
> The `compareTo` / `compare` contract: negative if `a < b`, zero
> if `a == b`, positive if `a > b`. CRITICAL: if `compareTo` returns
> 0, it SHOULD equal `equals()` returning true. Violating this causes
> bugs in `TreeSet`/`TreeMap` (which use compareTo for equality, not
> equals()).
>
> Java 8 `Comparator` has default methods for composition:
> `comparing()`, `thenComparing()`, `reversed()`, `nullsFirst()`,
> `nullsLast()` - enabling complex sort keys in one expression.

**Framework:** COMPARABLE (one natural order, in class) vs
COMPARATOR (external, multiple orders, Java 8 composable)

_Adapting up:_ Discuss the `compareTo` / `equals` consistency
requirement and how violating it corrupts `TreeMap`.

_Adapting down:_ `Comparable` for one natural sort; `Comparator`
for custom sorts passed to `sort()`.

**Blank Mind Recovery:**

**(1) Restate:** "Comparable is built into the class (natural order).
Comparator is external (custom order). Strings are Comparable
lexicographically. For custom sort, implement Comparator."

**(2) First principles:** "Ordering has two locations: inside the
object ('I know my natural order') or outside ('this context needs
a specific order'). Comparable = natural, Comparator = contextual."

**(3) Bridge:** "Comparable is like a student ID number - each student
has exactly one. Comparator is like different course rosters - the
same students sorted by GPA, by name, by enrollment date. One natural
order, many contextual orders."

---

### 📘 Concept Explanation

**`Comparable<T>`:**

```java
public interface Comparable<T> {
    int compareTo(T other);
    // contract: negative if this < other
    //           zero    if this == other
    //           positive if this > other
}
```

- Implemented by `Integer`, `String`, `Double`, `Date`, `LocalDate`,
  `BigDecimal`, all primitive wrappers, `enum` types
- Used by: `TreeSet`, `TreeMap` (default ordering), `Collections.sort(list)`,
  `Arrays.sort(array)` without explicit `Comparator`
- Only ONE ordering per class (natural order)

**`Comparator<T>`:**

```java
@FunctionalInterface
public interface Comparator<T> {
    int compare(T a, T b);
    // contract: same sign rules as compareTo
}
```

Java 8 factory methods and composition:

```java
// Sort by last name, then first name
Comparator<Person> byName =
    Comparator.comparing(Person::getLastName)
              .thenComparing(Person::getFirstName);

// Sort by age descending
Comparator<Person> byAgeDesc =
    Comparator.comparing(Person::getAge).reversed();

// Nulls first, then by name
Comparator<Person> withNulls =
    Comparator.nullsFirst(
        Comparator.comparing(Person::getName));

// Multi-key example
Comparator<Order> orderSort =
    Comparator.comparing(Order::getStatus)
              .thenComparing(Order::getPriority,
                  Comparator.reverseOrder())
              .thenComparing(Order::getCreatedAt);
```

**The critical contract: `compareTo` consistency with `equals`:**

```
If a.compareTo(b) == 0, then a.equals(b) SHOULD be true.
```

This is not enforced by the compiler but violated by some classes
(`BigDecimal`: `new BigDecimal("1.0").compareTo(new BigDecimal("1.00"))
== 0` but `equals()` returns false). Using `BigDecimal` in a `TreeSet`
treats "1.0" and "1.00" as duplicates. Using it in a `HashSet` treats
them as distinct.

---

### 💻 Code Example

#### Custom ordering with Comparator composition

```java
import java.util.*;

record Employee(String name, String dept, int salary) {}

public class SortingDemo {
    public static void main(String[] args) {
        List<Employee> employees = List.of(
            new Employee("Alice", "Eng",   90_000),
            new Employee("Bob",   "Eng",   85_000),
            new Employee("Carol", "Sales", 70_000),
            new Employee("Dave",  "Eng",   90_000)
        );

        // BAD: manual comparison - verbose, error-prone
        List<Employee> sorted1 = new ArrayList<>(employees);
        sorted1.sort((a, b) -> {
            int deptCmp = a.dept().compareTo(b.dept());
            if (deptCmp != 0) return deptCmp;
            int salCmp = Integer.compare(b.salary(), a.salary());
            if (salCmp != 0) return salCmp;
            return a.name().compareTo(b.name());
        });

        // GOOD: Comparator.comparing chain - readable, composable
        Comparator<Employee> byDeptThenSalaryDescThenName =
            Comparator.comparing(Employee::dept)
                .thenComparing(Employee::salary,
                    Comparator.reverseOrder())
                .thenComparing(Employee::name);

        List<Employee> sorted2 = employees.stream()
            .sorted(byDeptThenSalaryDescThenName)
            .toList();

        sorted2.forEach(System.out::println);
        // Carol (Sales, 70k)
        // Alice (Eng, 90k) - same salary as Dave, A before D
        // Dave (Eng, 90k)
        // Bob  (Eng, 85k)
    }
}
```

> **Code walkthrough:** `Comparator.comparing(Employee::dept)` creates
> a primary sort key. `.thenComparing(Employee::salary, reverseOrder())`
> sorts by salary descending within each department.
> `.thenComparing(Employee::name)` breaks salary ties alphabetically.
> Each comparator is composed without branching logic, making the
> intent clear. `reverseOrder()` avoids the negation trick
> (`-Integer.compare(...)`) which is a common error source.

---

### 🎓 Answers by Seniority

**Junior:** `Comparable` is implemented by the class with `compareTo()`.
`Comparator` is a separate object with `compare()`. Use `Comparable`
when the class has a natural order (numbers, strings). Use `Comparator`
when you need a custom sort order.

**Mid-level:** Key difference: `Comparable` is one fixed order built into
the class; `Comparator` is an external, swappable strategy. Java 8
`Comparator.comparing().thenComparing()` chains make multi-key sorts
clean. `TreeSet`/`TreeMap` use `Comparable` by default but accept a
`Comparator` in their constructors.

**Senior:** The `compareTo`/`equals` consistency contract is critical:
`TreeSet` uses `compareTo` for deduplication, not `equals`. `BigDecimal`
violates this: `new BigDecimal("1.0").equals(new BigDecimal("1.00"))` is
false but `compareTo` returns 0 - so `TreeSet` deduplicates them.

**Staff:** Comparator composition is an API design decision. Returning
`Comparator<Person>` from a factory method allows callers to compose
orderings. Caching comparators as constants avoids repeated
`Comparator.comparing()` chain construction in hot paths (negligible
GC pressure but clarity benefit).

---

### ⚠️ Common Misconceptions

| #   | Misconception                                             | Reality                                                                                                                                             | Danger                                                                                                         |
| --- | --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| 1   | `compareTo` returning 0 means `equals` returns true       | Only a recommendation, not enforced. `BigDecimal` is the canonical example: compareTo("1.0", "1.00") == 0, equals() == false                        | TreeSet/TreeMap using compareTo for deduplication produces different results than HashSet/HashMap using equals |
| 2   | You need to implement `Comparable` to sort a class        | You can always pass a `Comparator` to `sort()`. `Comparable` is only required for natural ordering used by `TreeSet`/`TreeMap` default constructors | Unnecessarily coupling ordering into the domain class                                                          |
| 3   | `Comparator.reversed()` is the same as negating compareTo | `reversed()` is correct; `-compareTo()` can overflow when values are `Integer.MIN_VALUE`. Always use `Comparator.reverseOrder()` or `.reversed()`   | Integer overflow causing incorrect sort order                                                                  |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - `BigDecimal` in `TreeSet` deduplicates unexpectedly**

Symptom: A `TreeSet<BigDecimal>` treating `1.0` and `1.00` as
the same element; or a `HashSet<BigDecimal>` treating them as
distinct.

Root cause: `BigDecimal.compareTo()` returns 0 for equal values
with different scale; `BigDecimal.equals()` returns false for
different scale. `TreeSet` uses `compareTo`; `HashSet` uses
`equals/hashCode`.

Fix: Normalize all values to the same scale before insertion
(`bd.stripTrailingZeros()`) or use a custom `Comparator`.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                            |
| ---------------- | ----------------------------------------------- |
| 15 min           | Comparable vs Comparator - when to use each     |
| 30 min           | Add Comparator.comparing() chain; contract      |
| 45 min           | Add BigDecimal gotcha; TreeMap/TreeSet behavior |

---

**[JUNIOR] Q1: What is the difference between `Comparable` and
`Comparator`?** [CONCEPTUAL]

_Why they ask:_ Most common collections ordering question.

_Likely follow-up:_ "Which one do you pass to `Collections.sort()`?"

`Comparable<T>`: implemented by the class itself; defines one
"natural order." `compareTo(T other)` returns negative/zero/positive.
Used by `TreeSet`, `TreeMap`, and `Collections.sort(list)` (no
Comparator arg). Examples: `Integer`, `String`, `LocalDate`.

`Comparator<T>`: a separate strategy object. Defines an external
ordering. `compare(T a, T b)`. Passed to `Collections.sort(list, cmp)`,
`TreeSet(comparator)`, `list.sort(cmp)`. A class can have many
Comparators but only one `Comparable` ordering.

_What separates good from great:_ Noting that `Comparator` is a
`@FunctionalInterface` - can be expressed as a lambda.

---

**[MID] Q2: How do you sort a list of objects by multiple fields?**
[HANDS-ON]

_Why they ask:_ Tests practical Comparator usage.

_Likely follow-up:_ "How do you handle null values?"

```java
// Sort people by last name, then first name, then age
Comparator<Person> sort =
    Comparator.comparing(Person::getLastName)
              .thenComparing(Person::getFirstName)
              .thenComparingInt(Person::getAge);

list.sort(sort);

// With null handling:
Comparator<Person> withNulls =
    Comparator.nullsLast(
        Comparator.comparing(Person::getLastName,
            Comparator.nullsLast(Comparator.naturalOrder()))
    );
```

`nullsFirst()` / `nullsLast()` wrap any Comparator to handle null
values explicitly rather than throwing `NullPointerException`.

_What separates good from great:_ Knowing `nullsFirst()`/`nullsLast()`
and `thenComparingInt()` (avoids Integer boxing) as specific
Comparator factory methods.

---

**[SENIOR] Q3: DEBUGGING: Objects are not being deduplicated in a
`TreeSet` as expected. Diagnose.** [DEBUGGING]

_Why they ask:_ Tests the compareTo/equals consistency contract.

_Likely follow-up:_ "How would you fix it?"

`TreeSet` uses `compareTo()` (or the provided `Comparator`) for ALL
comparisons including equality. If `a.compareTo(b) == 0`, `TreeSet`
considers `a` and `b` equal, regardless of `a.equals(b)`.

Possible causes:

1. Class implements `Comparable` but `compareTo` uses a different
   field than `equals`/`hashCode`
2. Using `BigDecimal` with different scales (classic case)
3. Custom `Comparator` passed to `TreeSet` that considers objects
   equal in a different way than `equals`

Fix: Ensure `compareTo` is consistent with `equals`. If not possible
(third-party class), use a `Comparator` that explicitly delegates to
`equals` as a tiebreaker:

```java
Comparator<BigDecimal> consistent =
    Comparator.comparing(BigDecimal::doubleValue)
              .thenComparing(BigDecimal::toPlainString);
```

_What separates good from great:_ Naming the `compareTo`/`equals`
consistency contract by name and knowing it is recommended but not
enforced.

---

---

# List, Set, Map, Queue: The Four Core Collection Interfaces

**Interview Weight:** low - Foundational knowledge; appears as setup
for deeper collection implementation questions.

---

### 🎯 Model Answer

**30 seconds:**

> The four root contracts: `List` (ordered, indexed, allows duplicates),
> `Set` (unique elements, no index), `Map` (key-value, not a Collection
> subtype), `Queue` (FIFO or priority order). `List` and `Set` extend
> `Collection`; `Map` does not. Choose based on the invariant you need:
> ordering, uniqueness, lookup by key, or ordered processing.

**3 minutes (Senior):**

> `List`: ordered sequence with `get(int index)`. Order is insertion
> order by default. Duplicates allowed. `ArrayList` for random access,
> `LinkedList` (rarely) for head/tail ops, `ArrayDeque` for queue use.
>
> `Set`: unique elements defined by `equals()`/`hashCode()`. No index.
> `HashSet` for O(1) contains, `LinkedHashSet` for insertion order,
> `TreeSet` for sorted order (uses `compareTo`).
>
> `Map`: key-value pairs. Keys are unique (same contract as Set).
> NOT a `Collection`. Methods: `get(key)`, `put(key, value)`,
> `containsKey()`, `keySet()`, `values()`, `entrySet()`.
>
> `Queue`: elements processed in order. `peek()` inspects head,
> `poll()` removes head (null if empty), `remove()` removes head
> (throws if empty). `Deque` extends Queue for both-end access.
> `BlockingQueue` adds blocking operations for thread-safe
> producer-consumer.

**Framework:** CONTRACT (what invariant each provides) +
IMPLEMENTATIONS (concrete choices) + SELECTION CRITERIA

_Adapting up:_ Discuss how Java's Collection hierarchy uses interfaces
as pure contracts, how `AbstractList`/`AbstractSet`/`AbstractMap` provide
default implementations, and the extension path.

_Adapting down:_ List=ordered list, Set=unique set, Map=dictionary,
Queue=queue. One example of each.

**Blank Mind Recovery:**

**(1) Restate:** "Four core interfaces: List (ordered, duplicates ok),
Set (unique), Map (key-value), Queue (FIFO). Map is NOT a Collection."

**(2) First principles:** "Every data structure provides a contract:
what can you store, in what order, with what lookup guarantee. The four
interfaces cover the four most common contracts."

**(3) Bridge:** "List=bookshelf (ordered, can have two copies of the
same book). Set=guest list (each name appears once). Map=phone book
(name to number). Queue=checkout line (first in, first out)."

---

### 📘 Concept Explanation

**Interface hierarchy:**

```
java.lang.Iterable
  java.util.Collection
    java.util.List      (ordered, indexed)
    java.util.Set       (unique)
      java.util.SortedSet  (sorted, first/last/headSet/tailSet)
        java.util.NavigableSet (floor/ceiling/higher/lower)
    java.util.Queue     (FIFO or priority)
      java.util.Deque   (double-ended queue)
        java.util.BlockingDeque (j.u.c. - blocking)

java.util.Map           (NOT a Collection)
  java.util.SortedMap   (sorted keys)
    java.util.NavigableMap (floor/ceiling/higher/lower keys)
```

**Interface selection criteria:**

| Need                           | Interface       | Primary implementation |
| ------------------------------ | --------------- | ---------------------- |
| Ordered sequence, index access | `List`          | `ArrayList`            |
| Unique elements, fast contains | `Set`           | `HashSet`              |
| Unique elements, sorted        | `SortedSet`     | `TreeSet`              |
| Key-value lookup               | `Map`           | `HashMap`              |
| Key-value, sorted keys         | `SortedMap`     | `TreeMap`              |
| FIFO queue                     | `Queue`         | `ArrayDeque`           |
| Priority ordering              | `Queue`         | `PriorityQueue`        |
| Stack (LIFO)                   | `Deque`         | `ArrayDeque`           |
| Thread-safe queue              | `BlockingQueue` | `LinkedBlockingQueue`  |

**Method signatures by interface:**

```java
// List-specific methods:
list.get(int index)       // O(1) ArrayList, O(n) LinkedList
list.set(int index, T e)
list.add(int index, T e)  // insert at position
list.indexOf(Object o)
list.subList(from, to)    // live view

// Set: extends Collection, no extra methods (uniqueness is the contract)

// Map (not Collection):
map.get(Object key)                // null if absent
map.getOrDefault(key, defaultVal)  // Java 8
map.put(K key, V value)
map.putIfAbsent(K key, V value)    // Java 8
map.containsKey(Object key)
map.keySet()                       // Set<K> live view
map.values()                       // Collection<V> live view
map.entrySet()                     // Set<Map.Entry<K,V>> live view
map.computeIfAbsent(K key, Function<K,V> mappingFn)  // Java 8
map.merge(K key, V value, BiFunction<V,V,V> remap)   // Java 8

// Queue-specific methods:
queue.offer(E e)   // add (returns false if full, vs add throws)
queue.poll()       // remove head, null if empty
queue.peek()       // view head, null if empty
// Deque adds:
deque.addFirst/addLast
deque.pollFirst/pollLast
deque.peekFirst/peekLast
```

---

### 💻 Code Example

#### Choosing the right interface for return types

```java
// BAD: returns implementation - over-exposes internals
public ArrayList<String> getActiveUsers() {
    ArrayList<String> result = new ArrayList<>();
    // ... populate
    return result;
}

// GOOD: return narrowest interface satisfying callers
public List<String> getActiveUsers() {
    // callers only need iteration + indexed access
    return new ArrayList<>(activeUsers);
}

// BEST: if callers never modify, return immutable
public List<String> getActiveUsers() {
    return List.copyOf(activeUsers);  // Java 10 immutable copy
}

// When uniqueness matters in return:
public Set<String> getUniquePermissions(User user) {
    // Set contract signals: no duplicates
    return new HashSet<>(user.getRawPermissions());
}
```

> **Code walkthrough:** Returning `List` instead of `ArrayList` means
> the implementation can be swapped to `LinkedList`, an immutable
> `List.copyOf()`, or any other List without changing callers. Returning
> `Set` communicates to callers that results are deduplicated. Returning
> `List.copyOf()` prevents callers from mutating the internal state.

---

### 🎓 Answers by Seniority

**Junior:** List = ordered, allows duplicates. Set = unique elements.
Map = key-value. Queue = FIFO. ArrayList, HashSet, HashMap, ArrayDeque
are the main implementations.

**Mid-level:** Code to the narrowest interface that meets the caller's
needs. Return `List`, not `ArrayList`. Map is NOT a Collection - no
iteration without `entrySet()`/`keySet()`. Use `Queue` interface for
any FIFO/priority queue so you can swap between `ArrayDeque`,
`PriorityQueue`, and `LinkedBlockingQueue`.

**Senior:** The SortedSet/NavigableSet hierarchy adds range operations
(`headSet(to)`, `tailSet(from)`, `subSet(from, to)`) used in range
queries. `NavigableMap` adds `floorKey()`, `ceilingKey()` for
range lookups on `TreeMap`. These are often overlooked but eliminate
manual binary search implementations.

**Staff:** Interface selection is an API contract decision. Returning
`Collection<T>` vs `List<T>` communicates different capabilities. A
method returning `Map<K,V>` commits to key-value semantics. Design
for the consumer's need: if they iterate without index access,
`Iterable<T>` is the minimal contract.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                    | Reality                                                                                                                                         | Danger                                                                 |
| --- | ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| 1   | `Map` is a subtype of `Collection`               | `Map` does NOT extend `Collection`. It is a completely separate hierarchy. `map instanceof Collection` is always false                          | Trying to pass a Map where a Collection is expected                    |
| 2   | `Set` maintains insertion order                  | `HashSet` does NOT maintain any order. `LinkedHashSet` maintains insertion order. `TreeSet` maintains sorted order                              | Depending on `HashSet` iteration order which is implementation-defined |
| 3   | `Queue.remove()` and `Queue.poll()` are the same | `poll()` returns null if empty. `remove()` throws `NoSuchElementException` if empty. Same duality exists for `offer`/`add` and `peek`/`element` | NPE vs exception surprise depending on which method was called         |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Depending on `HashMap` iteration order**

Symptom: Tests pass locally but fail in production; or behavior
changes between Java versions.

Root cause: Code iterates `HashMap.entrySet()` and assumes a
particular order. HashMap order is unspecified and can change
between JVM runs or Java versions.

Fix: Use `LinkedHashMap` for insertion order, `TreeMap` for sorted
order. Never assume `HashMap` order.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                             |
| ---------------- | ------------------------------------------------ |
| 10 min           | Four interfaces; Map not a Collection            |
| 20 min           | Add implementation choices; Queue poll vs remove |
| 30 min           | Add NavigableMap/NavigableSet range operations   |

---

**[JUNIOR] Q1: Why is `Map` not a subtype of `Collection`?**
[CONCEPTUAL]

_Why they ask:_ Tests conceptual understanding of the hierarchy.

_Likely follow-up:_ "How do you iterate over a Map then?"

A `Collection` represents a group of individual elements you can
iterate over. A `Map` represents ASSOCIATIONS between keys and values

- it is a different abstraction. You iterate over key-value pairs
  (`Map.Entry`), not individual elements.

If `Map` extended `Collection`, `size()` would be ambiguous (the count
of entries? keys? values?), and `contains()` would be ambiguous (does
it check keys? values? entries?).

To iterate a Map: `map.entrySet()` returns `Set<Map.Entry<K,V>>` -
this IS a `Collection` and can be used in for-each.

_What separates good from great:_ Explaining why the abstraction
mismatch (association vs element group) is the design reason, not
a historical accident.

---

**[MID] Q2: What is the difference between `Queue.poll()` and
`Queue.remove()`?** [CONCEPTUAL]

_Why they ask:_ Tests knowledge of Queue's dual-method API.

_Likely follow-up:_ "What about `peek()` vs `element()`?"

`Queue` has two versions of each operation:

| Operation | Throws exception            | Returns null/false       |
| --------- | --------------------------- | ------------------------ |
| Insert    | `add(e)` throws if full     | `offer(e)` returns false |
| Remove    | `remove()` throws if empty  | `poll()` returns null    |
| Examine   | `element()` throws if empty | `peek()` returns null    |

The "null-returning" versions (`offer`, `poll`, `peek`) are preferred
when the empty state is normal and should be handled, not exceptional.
The "throwing" versions (`add`, `remove`, `element`) are for when
empty/full is a programming error.

_What separates good from great:_ Knowing the dual-method pattern
is intentional (exception vs null for empty/full) and applies to
BlockingQueue with additional `put()`/`take()` (blocking).

---

**[SENIOR] Q3: When would you use `NavigableMap` over a regular `Map`?**
[TRADE-OFF]

_Why they ask:_ Tests knowledge of underused but powerful API.

_Likely follow-up:_ "Give a real use case."

`NavigableMap` (implemented by `TreeMap`) adds range and neighbor
operations not available in `Map`:

- `floorKey(k)`: largest key <= k
- `ceilingKey(k)`: smallest key >= k
- `lowerKey(k)`: largest key < k
- `higherKey(k)`: smallest key > k
- `headMap(to)`: submap of keys < to
- `tailMap(from)`: submap of keys >= from
- `subMap(from, to)`: submap of keys in [from, to)
- `descendingMap()`: reverse-order view

Real use case: a time-series store mapping `Instant` to readings.
`map.floorKey(queryTime)` returns the most recent reading at or before
a given time - no linear search.

Another use case: rate limiting with sliding window. Store request
timestamps in `TreeMap<Long, Integer>` keyed by timestamp. Use
`tailMap(now - windowMs)` to get all requests in the window in O(log n).

_What separates good from great:_ A specific production use case -
time-series lookup or sliding window - not just listing the methods.

---

---

# Checked vs Unchecked Exceptions: The Historical Design Debate

**Interview Weight:** medium - Appears in exception design discussions
at mid-level and above; tests whether you can articulate the trade-off.

---

### 🎯 Model Answer

**30 seconds:**

> Checked exceptions must be declared (`throws`) or caught at compile
> time. `IOException`, `SQLException`, `ParseException`. Unchecked
> exceptions (`RuntimeException` subtypes) need no declaration.
> `NullPointerException`, `IllegalArgumentException`. The design rule:
> checked = caller can and SHOULD recover; unchecked = programming
> error or unrecoverable. Java's overuse of checked exceptions is
> controversial - most modern APIs use unchecked, and checked
> exceptions are incompatible with lambdas.

**3 minutes (Senior):**

> The original intent: checked exceptions force the caller to
> acknowledge the failure and decide: handle it or propagate it.
> `IOException` is checked because the caller really should decide
> whether to retry, use a default, or abort.
>
> In practice, checked exceptions have three problems: (1) callers
> often cannot recover from them and just wrap them in
> `RuntimeException` - boilerplate with no benefit. (2) They are
> incompatible with lambda expressions: `Stream.map()` cannot
> pass a method that throws a checked exception without a wrapper.
> (3) They leak implementation details: if a service uses JDBC
> internally, callers should not need to handle `SQLException`.
>
> Modern Java trend: Spring Data wraps all `SQLException` in unchecked
> `DataAccessException`. Project Reactor and CompletableFuture chains
> only work with unchecked exceptions. The effective rule: use
> checked exceptions only when the caller has a SPECIFIC recovery
> action they can take that is meaningfully different from rethrowing.

**Framework:** INTENT (force acknowledgment) -> PROBLEMS (boilerplate,
lambda incompatibility, impl leakage) -> MODERN-TREND (unchecked) +
RULE-OF-THUMB

_Adapting up:_ Discuss functional interfaces with checked exceptions,
the Vavr `Try` monad, and how Kotlin handles this (only unchecked).

_Adapting down:_ checked = must catch/declare (IOException), unchecked
= optional (NullPointerException). Use unchecked for most new code.

**Blank Mind Recovery:**

**(1) Restate:** "Checked exceptions must be declared or caught. Unchecked
don't. The design question: when is the caller expected to recover?
Modern preference is unchecked because checked causes boilerplate."

**(2) First principles:** "Exception handling forces a decision at every
call site. Checked = compiler-enforced decision. Unchecked = optional.
The question is whether forced decisions add value or just boilerplate."

**(3) Bridge:** "Checked exceptions are like mandatory receipts for every
transaction - useful for taxes (important transactions) but annoying
for everyday coffee purchases. Unchecked is the default; checked is for
transactions important enough to require acknowledgment."

---

### 📘 Concept Explanation

**The hierarchy:**

```
Throwable
  Error                    - JVM-level, do not catch (OutOfMemoryError,
    OutOfMemoryError          StackOverflowError, AssertionError)
    StackOverflowError
    ...
  Exception                - CHECKED base class
    IOException            - Checked: file/network operations
    SQLException           - Checked: JDBC operations
    ParseException         - Checked: parsing failures
    InterruptedException   - Checked: thread interruption
    RuntimeException       - UNCHECKED base class
      NullPointerException
      IllegalArgumentException
      IllegalStateException
      IndexOutOfBoundsException
      ClassCastException
      ArithmeticException  (/ by zero)
      UnsupportedOperationException
      ConcurrentModificationException
```

**Rules:**

- `Exception` and its subtypes (except `RuntimeException`) = CHECKED
- `RuntimeException` and its subtypes = UNCHECKED
- `Error` and its subtypes = UNCHECKED (but don't catch them)
- `Throwable` itself = technically unchecked but never catch it

**Checked exception problems:**

```java
// Problem 1: wrapping just to satisfy compiler
public void loadConfig() {
    try {
        String text = Files.readString(Path.of("config.yml"));
    } catch (IOException e) {
        // Cannot recover - just rethrow as unchecked
        throw new RuntimeException("config load failed", e);
    }
}

// Problem 2: lambda incompatibility
List<Path> paths = List.of(Path.of("a.txt"), Path.of("b.txt"));
// Does NOT compile: readString throws checked IOException
paths.stream()
    .map(p -> Files.readString(p))  // compile error
    .toList();

// Workaround: ugly wrapper
paths.stream()
    .map(p -> {
        try { return Files.readString(p); }
        catch (IOException e) {
            throw new RuntimeException(e); }
    })
    .toList();

// Problem 3: implementation detail leakage
public interface UserRepository {
    User findById(long id) throws SQLException; // leaks JDBC!
    // callers must handle SQL even if impl changes to JPA
}
```

**When checked exceptions ARE right:**

- `FileNotFoundException`: caller might want to try an alternate path
- `InterruptedException`: MUST be handled - `Thread.currentThread().interrupt()`
  must be called to restore the interruption flag
- API method where different callers take meaningfully different recovery
  actions on failure

---

### 💻 Code Example

#### Checked vs unchecked design decision

```java
// BAD: checked exception leaks implementation detail
public interface PaymentService {
    Receipt charge(PaymentRequest req) throws SQLException;
    // Why does the payment API force callers to know about SQL?
}

// GOOD: unchecked wraps implementation detail
public interface PaymentService {
    Receipt charge(PaymentRequest req); // clean contract
    // Implementation wraps SQLException in PaymentException
    // (a RuntimeException subtype)
}

// Unchecked exception hierarchy for domain errors:
public class PaymentException extends RuntimeException {
    private final ErrorCode code;
    public PaymentException(ErrorCode code, String msg,
                            Throwable cause) {
        super(msg, cause);
        this.code = code;
    }
}

// Caller handles only what they can recover from:
try {
    service.charge(request);
} catch (PaymentException e) {
    if (e.getCode() == ErrorCode.INSUFFICIENT_FUNDS) {
        // specific recovery action
        return Response.declined("Insufficient funds");
    }
    throw e; // let other errors propagate
}
```

> **Code walkthrough:** The `PaymentService` interface uses unchecked
> exceptions. The `SQLException` from JDBC is an implementation detail
>
> - wrapped in `PaymentException`. Callers handle only the errors they
>   can specifically recover from (`INSUFFICIENT_FUNDS`); others
>   propagate. This is the Spring approach: `DataAccessException`
>   hierarchy wraps all JDBC exceptions in unchecked subtypes with
>   meaningful names.

---

### 🎓 Answers by Seniority

**Junior:** Checked exceptions (IOException, SQLException) must be
caught or declared in `throws`. Unchecked (NullPointerException,
IllegalArgumentException) are optional. The difference is whether
the compiler enforces handling.

**Mid-level:** Design rule: use checked when the caller has a specific
recovery action; unchecked for programming errors. In practice, most
modern APIs use unchecked to avoid boilerplate wrapping and lambda
incompatibility. Spring wraps all SQLExceptions in unchecked
`DataAccessException`.

**Senior:** Three problems with checked: boilerplate wrapping, lambda
incompatibility (cannot throw checked from `Function<T,R>`), and
interface pollution (implementation details leak through). `InterruptedException`
must always be handled specifically: either re-throw or call
`Thread.currentThread().interrupt()` to restore the flag.

**Staff:** Exception design is API design. A public API's exception
contract is as important as its method signatures. Rule: throw unchecked
unless callers have a meaningful specific recovery action. Provide a
hierarchy (PaymentException subtypes) so callers can catch specifically.
Never throw raw `RuntimeException` without a message.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                  | Reality                                                                                                                                                                                                                    | Danger                                                                    |
| --- | ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| 1   | Catching `Exception` is a safe catch-all       | Catching `Exception` also catches `RuntimeException` including bugs (NPE, AIOOBE). These should propagate, not be swallowed                                                                                                | Swallowing programming errors; symptoms appear far from the cause         |
| 2   | Checked exceptions are always more informative | They are more coercive (compiler forces handling) but not necessarily more informative than unchecked. An unchecked `PaymentDeclinedException` with a clear message is more informative than a generic checked `Exception` | Associating "checked = better documented" when the opposite is often true |
| 3   | `InterruptedException` can be safely swallowed | `InterruptedException` indicates a thread was interrupted (e.g., for graceful shutdown). Swallowing it prevents the thread from responding to shutdown signals                                                             | Application hangs on shutdown because interrupt signal was lost           |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Swallowing `InterruptedException`**

Symptom: Application takes very long to shut down or hangs.

Root cause: `InterruptedException` was caught and not re-thrown or
the interrupt flag was not restored.

Fix: Always either re-throw `InterruptedException` or call
`Thread.currentThread().interrupt()` before returning.

---

**Failure 2 - Catching `Exception` hiding bugs**

Symptom: Application silently produces wrong results; errors appear
in logs as generic "unexpected error."

Root cause: `catch (Exception e)` blocks swallow `NullPointerException`
and other `RuntimeException` subtypes.

Fix: Catch specific exceptions. If you need a catch-all, catch
`RuntimeException` separately and at minimum log with full stack trace.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                     |
| ---------------- | -------------------------------------------------------- |
| 15 min           | Checked vs unchecked hierarchy; design rule              |
| 30 min           | Add lambda incompatibility problem; InterruptedException |
| 45 min           | Add Spring DataAccessException example; API design       |

---

**[JUNIOR] Q1: What makes an exception "checked"?** [CONCEPTUAL]

_Why they ask:_ Basic hierarchy knowledge check.

_Likely follow-up:_ "Name three checked and three unchecked exceptions."

An exception is "checked" if it is a subtype of `Exception` but NOT
a subtype of `RuntimeException`. The compiler requires every checked
exception to be either declared in `throws` or caught.

`RuntimeException` and its subtypes (plus `Error`) are unchecked -
the compiler does not require handling.

Checked examples: `IOException`, `SQLException`, `ParseException`,
`InterruptedException`, `ClassNotFoundException`.

Unchecked examples: `NullPointerException`, `IllegalArgumentException`,
`IndexOutOfBoundsException`, `ClassCastException`,
`IllegalStateException`.

_What separates good from great:_ Knowing `Error` is also unchecked
(not caught normally) and that `Throwable` itself is technically
unchecked.

---

**[MID] Q2: Why are checked exceptions incompatible with lambda
expressions?** [TRADE-OFF]

_Why they ask:_ Tests practical awareness of where checked exceptions
cause problems.

_Likely follow-up:_ "How do you work around it?"

Functional interfaces like `Function<T,R>` do not declare `throws`
in their method signature. A lambda that throws a checked exception
cannot be assigned to such an interface.

```java
// Does NOT compile: readString throws IOException (checked)
Function<Path, String> reader = path -> Files.readString(path);

// The only options are:
// 1. Wrap in unchecked (ugly)
Function<Path, String> reader = path -> {
    try { return Files.readString(path); }
    catch (IOException e) { throw new RuntimeException(e); }
};

// 2. Create a functional interface that declares throws
@FunctionalInterface
interface ThrowingFunction<T, R> {
    R apply(T t) throws Exception;
}

// 3. Use a utility method (Vavr, etc.)
```

This is why most modern APIs (Reactor, Spring) use unchecked
exceptions - they need to work naturally in lambda pipelines.

_What separates good from great:_ Knowing the root cause (functional
interface declaration) and being able to write the workaround.

---

**[SENIOR] Q3: What special handling does `InterruptedException`
require?** [PRODUCTION]

_Why they ask:_ InterruptedException mishandling is a common production bug.

_Likely follow-up:_ "What happens if you don't restore the interrupt flag?"

`InterruptedException` is thrown when a blocking operation (like
`Thread.sleep()`, `queue.take()`, `future.get()`) is interrupted.
Interruption is a cooperative cancellation mechanism - it is used
for graceful shutdown.

The two correct responses:

1. **Re-throw**: if the method can propagate the interruption.
   Declare `throws InterruptedException`.
2. **Restore the flag**: if you cannot re-throw, call
   `Thread.currentThread().interrupt()` before returning. This
   re-sets the interrupt flag so the next blocking call in the call
   stack sees the interruption.

Wrong (anti-pattern):

```java
try {
    Thread.sleep(1000);
} catch (InterruptedException e) {
    // WRONG: swallow silently - interrupt signal lost
    logger.warn("Interrupted");
}

// CORRECT:
try {
    Thread.sleep(1000);
} catch (InterruptedException e) {
    Thread.currentThread().interrupt(); // restore flag
    return; // or throw new RuntimeException(e)
}
```

Why it matters: if you swallow `InterruptedException`, a graceful
shutdown signal (like `ExecutorService.shutdownNow()`) is silently
ignored. The thread keeps running after shutdown, causing application
hang.

_What separates good from great:_ Explaining the cooperative
cancellation model - `interrupt()` doesn't force stop, it signals
the thread to check and stop voluntarily.

---

---

# Exception Hierarchy: Throwable, Error, Exception, RuntimeException

**Interview Weight:** low-medium - Companion to the checked/unchecked
question; tests whether you know the full picture.

---

### 🎯 Model Answer

**30 seconds:**

> `Throwable` is the root of all exceptions. It has two direct subtypes:
> `Error` (JVM-level unrecoverable: OutOfMemoryError, StackOverflowError)
> and `Exception` (application errors). `Exception` splits into checked
> (declare or catch) and unchecked via `RuntimeException`. The practical
> rule: never catch `Error` or raw `Throwable` in application code.

**3 minutes (Senior):**

> The hierarchy exists to separate three categories of failure:
>
> `Error`: JVM-level failures that indicate the runtime is in an
> unrecoverable state. `OutOfMemoryError` means no heap left.
> `StackOverflowError` means infinite recursion. Application code
> should not try to recover. The ONLY legitimate catch is in a
> top-level framework handler that wants to log before dying.
>
> `Exception`: recoverable failures in application or library code.
> All `Exception` subtypes (except `RuntimeException`) are checked -
> the compiler requires handling. These represent expected failure
> modes: file not found, network timeout, invalid input.
>
> `RuntimeException`: unchecked exceptions representing programming
> errors. `NullPointerException` = null was used where a reference
> was expected. `IllegalArgumentException` = invalid argument passed.
> `IllegalStateException` = object is in wrong state for the operation.
> These should PROPAGATE to the top (not be caught) so they surface
> as bugs.
>
> `try-with-resources` (Java 7) closes `AutoCloseable` resources
> automatically; `finally` always runs; suppressed exceptions are
> attached to the primary exception via `addSuppressed()`.

**Framework:** THREE-CATEGORIES (Error, checked Exception, unchecked
RuntimeException) + TRY-WITH-RESOURCES + BEST PRACTICES

_Adapting up:_ Discuss multi-catch (`catch (IOException | SQLException e)`),
exception chaining (`initCause`, constructor taking Throwable), and
`Throwable.addSuppressed()` for try-with-resources edge cases.

_Adapting down:_ Error = JVM crash, Exception = app error (catch it),
RuntimeException = bug (don't catch it).

**Blank Mind Recovery:**

**(1) Restate:** "Throwable -> Error (JVM) and Exception. Exception ->
RuntimeException (unchecked bugs) and checked exceptions. Error =
never catch. RuntimeException = let propagate."

**(2) First principles:** "Exceptions separate: unrecoverable JVM failures
(Error), expected application failures (checked Exception), and
programming bugs (RuntimeException). Each needs different handling."

**(3) Bridge:** "Error is a heart attack - don't treat it yourself, call
emergency services (shut down). Checked Exception is a known illness -
treat it (catch and handle). RuntimeException is a bug in the code -
find and fix it (don't mask it with a catch)."

---

### 📘 Concept Explanation

**Full hierarchy with examples:**

```
Throwable
  getMessage(), getStackTrace(), getCause(), addSuppressed()

  Error (UNCHECKED - do not catch in application code)
    OutOfMemoryError      - heap exhausted
    StackOverflowError    - infinite recursion
    AssertionError        - assert statement failed
    LinkageError          - class loading issues
      NoClassDefFoundError  - class found at compile, missing at runtime
    VirtualMachineError   - JVM integrity

  Exception (CHECKED - base class for checked exceptions)
    IOException           - I/O operations
      FileNotFoundException
      SocketException
      EOFException
    SQLException          - JDBC operations
    ParseException        - parsing failures
    InterruptedException  - thread interruption
    ReflectiveOperationException
      ClassNotFoundException
      NoSuchMethodException

    RuntimeException (UNCHECKED - programming errors)
      NullPointerException      - null used as reference
      IllegalArgumentException  - invalid method argument
      IllegalStateException     - wrong state for operation
      IndexOutOfBoundsException - array/list index invalid
        ArrayIndexOutOfBoundsException
        StringIndexOutOfBoundsException
      ClassCastException        - invalid cast
      ArithmeticException       - divide by zero
      NumberFormatException     - invalid number string
      UnsupportedOperationException  - operation not implemented
      ConcurrentModificationException - modified during iteration
      NoSuchElementException    - Iterator.next() when empty
      StackOverflowError        (also Error but commonly seen)
```

**Exception chaining:**

```java
try {
    parseConfig(file);
} catch (IOException e) {
    // GOOD: preserve original cause for debugging
    throw new ConfigException("Failed to load config", e);
    // BAD: throw new ConfigException("..."); // cause lost!
}
```

**try-with-resources:**

```java
// Automatically closes resources in reverse order
// even if an exception is thrown
try (Connection conn = dataSource.getConnection();
     PreparedStatement ps = conn.prepareStatement(sql)) {
    // use ps...
} catch (SQLException e) {
    // conn and ps already closed before catch executes
    // If BOTH body and close() throw, the close exception
    // is suppressed (attached to the body exception):
    // e.getSuppressed() returns the close exception
}
```

---

### 💻 Code Example

#### Exception hierarchy in API design

```java
// BAD: raw RuntimeException loses context
public User loadUser(long id) {
    try {
        return userDao.findById(id);
    } catch (Exception e) {
        throw new RuntimeException(e); // raw, no message
    }
}

// GOOD: typed unchecked hierarchy with clear messages
public class UserServiceException extends RuntimeException {
    public enum Code { NOT_FOUND, DB_ERROR, INVALID_ID }
    private final Code code;

    public UserServiceException(Code code, String msg,
                                Throwable cause) {
        super(msg, cause); // preserve cause chain!
        this.code = code;
    }
    public Code getCode() { return code; }
}

public User loadUser(long id) {
    if (id <= 0) throw new UserServiceException(
        Code.INVALID_ID, "id must be positive: " + id, null);
    try {
        User u = userDao.findById(id);
        if (u == null) throw new UserServiceException(
            Code.NOT_FOUND, "User not found: " + id, null);
        return u;
    } catch (SQLException e) {
        throw new UserServiceException(
            Code.DB_ERROR, "DB error loading user " + id, e);
    }
}
```

> **Code walkthrough:** The typed hierarchy (`UserServiceException`
> with an enum code) gives callers the ability to catch specifically
> (`catch (UserServiceException e) { if e.getCode() == NOT_FOUND }`)
> without coupling to JDBC. The `Throwable cause` is always preserved
> in the constructor - callers and log aggregators can see the full
> chain from original `SQLException` through to the service exception.
> Contrast with `throw new RuntimeException(e)` which provides no
> context at the catch site.

---

### 🎓 Answers by Seniority

**Junior:** `Throwable` is the root. `Error` = JVM crash (OutOfMemoryError).
`Exception` = application errors. `RuntimeException` = bugs (NPE,
IllegalArgumentException). Don't catch `Error` or `RuntimeException`
normally.

**Mid-level:** Three categories: Error (JVM unrecoverable), checked
Exception (expected, declare or catch), RuntimeException (programming
bugs, let propagate). Exception chaining via `new MyException(msg, cause)`
preserves the original error for debugging.

**Senior:** Try-with-resources uses `AutoCloseable`. If both the body
and `close()` throw, the close exception is suppressed (attached to
the primary via `addSuppressed()`). Multi-catch (`catch (A | B e)`)
is useful when two exception types have the same handling. Exception
types should form a hierarchy (domain exception base class with subtypes)
for targeted catching.

**Staff:** Exception design is API design. Rule: every thrown exception
should have enough context to diagnose without a debugger. Include the
failing value in the message (`"User not found: " + id`). Always
preserve the cause chain. Define a domain exception hierarchy so callers
can catch at the right granularity.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                   | Reality                                                                                                                                                                                                              | Danger                                                        |
| --- | ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| 1   | `catch (Exception e)` is a good general handler | Catches all RuntimeExceptions (bugs) as well as checked exceptions. Bugs should propagate to surface and be fixed, not masked                                                                                        | Swallowing NPE or AIOOBE in production, silent wrong behavior |
| 2   | `finally` always runs after a return statement  | `finally` runs even after `return` in try/catch. If `finally` also has `return`, it OVERRIDES the try's return value. Exception thrown in `finally` suppresses the original exception                                | Silent value override or exception suppression                |
| 3   | `Error` should be caught for cleanup            | JVM is in an unrecoverable state during `Error`. Cleanup code in an `Error` catch may itself fail (heap exhausted - even allocation fails). Catch `Error` only in top-level frameworks to log, then let the JVM exit | Attempting cleanup in a broken JVM state causes more damage   |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Lost exception cause chain**

Symptom: Exception log shows `PaymentException: unexpected error`
with no underlying cause.

Root cause: `throw new PaymentException(e.getMessage())` - the cause
is passed as a String message, not as the Throwable cause. The original
stack trace is lost.

Fix: Always use the `Throwable` constructor: `throw new PaymentException(
"unexpected error", e)`.

---

**Failure 2 - `OutOfMemoryError` leaves system in inconsistent state**

Symptom: Application continues running after OOM but produces wrong
results or refuses connections.

Root cause: `OutOfMemoryError` was caught (in a `catch (Exception)` or
`catch (Throwable)` block), partially completed work left data in an
inconsistent state.

Fix: Never catch `Error`. Let the JVM restart (health check + orchestrator
restart). Ensure operations are idempotent so restarting is safe.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                               |
| ---------------- | -------------------------------------------------- |
| 15 min           | Hierarchy; which to catch; Error vs Exception      |
| 30 min           | Add try-with-resources; exception chaining         |
| 45 min           | Add suppressed exceptions; multi-catch; API design |

---

**[JUNIOR] Q1: What is the difference between `Error` and `Exception`?**
[CONCEPTUAL]

_Why they ask:_ Tests knowledge of the Throwable hierarchy root.

_Likely follow-up:_ "Name two Errors and two Exceptions."

Both extend `Throwable`, but represent different severity:

`Error`: JVM-level failure where normal operation cannot continue.
`OutOfMemoryError` (heap exhausted), `StackOverflowError` (infinite
recursion), `AssertionError` (failed assertion). Application code
should NOT catch `Error` - the JVM may not be able to execute any
recovery code reliably.

`Exception`: application-level failure that code can handle.
`IOException` (file not found, network timeout), `SQLException`
(database error), `IllegalArgumentException` (invalid input).

Catch `Exception` subtypes. Never catch `Error`. If you need a
catch-all for logging: `catch (Throwable t)` in a framework-level
handler, followed by re-throw.

_What separates good from great:_ Explaining why you should not
catch `Error` (JVM may be in unrecoverable state; even allocation
for the catch block may fail with OOM).

---

**[MID] Q2: How does try-with-resources work and what happens if
both the body and `close()` throw?** [CONCEPTUAL]

_Why they ask:_ Tests Java 7 feature understanding.

_Likely follow-up:_ "What is `addSuppressed()`?"

`try (Resource r = new Resource())` requires `r` to implement
`AutoCloseable`. The compiler wraps the body in an equivalent to:

```java
Resource r = new Resource();
Throwable primary = null;
try {
    // body
} catch (Throwable t) {
    primary = t;
    throw t;
} finally {
    if (primary != null) {
        try { r.close(); }
        catch (Throwable suppressed) {
            primary.addSuppressed(suppressed);
        }
    } else {
        r.close(); // close exception propagates normally
    }
}
```

If the body throws AND `close()` throws: the body exception
propagates; the close exception is attached as a suppressed exception
via `addSuppressed()`. Retrieve with `e.getSuppressed()`.

Multiple resources are closed in reverse declaration order.

_What separates good from great:_ Knowing the reverse-order close
and `addSuppressed()` behavior - these are tested in senior interviews.

---

**[SENIOR] Q3: DEBUGGING: Production logs show `NullPointerException`
with no useful stack trace. How do you diagnose it?** [DEBUGGING]

_Why they ask:_ Tests practical NPE diagnosis with modern JVM features.

_Likely follow-up:_ "What is Helpful NullPointerExceptions?"

Classic NPE: `NullPointerException: null` - no message, ambiguous.
`user.getAddress().getCity().toUpperCase()` - which part is null?

Java 14+ "Helpful NullPointerExceptions" (enabled by default in Java 17):
NPE message now says: `Cannot invoke "Address.getCity()" because
the return value of "User.getAddress()" is null`. This tells you
exactly which method returned null.

Diagnosis steps:

1. Check JVM version - Java 14+ has helpful NPEs by default.
   For older JVMs, enable: `-XX:+ShowCodeDetailsInExceptionMessages`
2. Use the stack trace line number to identify the expression
3. Add null checks or `Objects.requireNonNull()` around the
   flagged method
4. Consider whether Optional should be used for nullable returns

Pre-Java 14: split the chain across variables to identify which
one is null:

```java
Address addr = user.getAddress();  // line A
String city = addr.getCity();       // line B - NPE here means addr is null
String upper = city.toUpperCase();  // line C
```

_What separates good from great:_ Knowing Java 14+ helpful NPEs
by name and the JVM flag to enable them on older JVMs.

---

**[STAFF] Q4: How would you design an exception hierarchy for a
payment service?** [ARCHITECTURE]

_Why they ask:_ Tests exception design as API design.

_Likely follow-up:_ "How does this map to HTTP response codes?"

```
PaymentException (unchecked RuntimeException base)
  PaymentDeclinedException      - card declined (400)
    InsufficientFundsException  - specific decline reason
    CardExpiredException
  PaymentValidationException    - invalid request (422)
    InvalidCardNumberException
    MissingRequiredFieldException
  PaymentGatewayException       - gateway error (502)
  PaymentTimeoutException       - timeout (504)
```

Design rules:

1. Base is `RuntimeException` - callers don't need to declare
2. Each leaf has enough context (card last 4, amount, reason code)
   in fields - not just in the message string
3. HTTP mapping is in a separate exception mapper - the domain
   exception knows nothing about HTTP
4. Always chain the original cause: `new PaymentGatewayException(
"gateway timeout", originalException)`
5. Include request identifiers in every exception for traceability

Callers catch at the right granularity:

```java
try {
    service.charge(request);
} catch (PaymentDeclinedException e) {
    return Response.paymentDeclined(e.getDeclineCode());
} catch (PaymentValidationException e) {
    return Response.badRequest(e.getErrors());
} catch (PaymentException e) {
    // unexpected payment error - log and return 500
    log.error("Unexpected payment error", e);
    return Response.internalError();
}
```

_What separates good from great:_ The HTTP mapping living outside
the exception (separation of concerns) and the catch hierarchy
from specific to general.
