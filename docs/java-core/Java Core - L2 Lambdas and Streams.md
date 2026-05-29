---
layout: default
title: "Java Core - L2 Lambdas and Streams"
parent: "Java Core"
grand_parent: "SK Interview"
nav_order: 7
permalink: /java-core/l2-lambdas-and-streams/
---

# Java Core - L2 Lambdas and Streams

## Lambda Expressions and Functional Interfaces

### 🎯 Model Answer

**30 seconds:**
> A lambda expression is an anonymous function: `(params) -> body`.
> It can be used anywhere a FUNCTIONAL INTERFACE (an interface with
> exactly one abstract method) is expected. The compiler infers the
> target type from context. Java provides built-in functional interfaces
> in `java.util.function`: `Function<T,R>`, `Predicate<T>`,
> `Consumer<T>`, `Supplier<T>`, `BiFunction<T,U,R>`, and primitive
> variants. Lambdas capture effectively-final local variables from
> enclosing scope. Method references (`Class::method`) are shorthand
> for single-method lambdas.

**3 minutes (Senior):**
> Lambdas desugar to static synthetic methods at compile time (Java 8+
> via `invokedynamic`). Each lambda invocation does NOT create a new
> class per call - the JVM generates a class at runtime on first use
> (invokeDynamic bootstraps this). The key implication: lambdas do not
> have their own `this` (they capture the enclosing `this`). Inner
> anonymous classes have their own `this`.
>
> Effective finality: variables captured by lambdas must not be
> reassigned after capture. `int count = 0; Runnable r = () -> count++;`
> is a compile error. Workaround: `AtomicInteger count = new AtomicInteger();`
> The REFERENCE to count is effectively final; the integer value changes.
>
> Functional interfaces designed for different uses: `Function` (in -> out),
> `Predicate` (in -> boolean), `Consumer` (in -> void), `Supplier` (() -> out),
> `UnaryOperator<T>` (T -> T), `BinaryOperator<T>` (T,T -> T).

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Lambda expressions - let me cover syntax, functional
interfaces, method references, variable capture rules, and the common
functional interface types."

**(2) First principles:** "From first principles: passing behavior as
data requires either subclassing (verbose), anonymous classes (still
verbose), or first-class functions (lambdas). Java 8 added lambdas to
enable functional programming patterns without the ceremony."

**(3) Bridge:** "A lambda is like a recipe card you hand to a chef
(a method that accepts a functional interface). Before Java 8, you had
to create a whole cookbook (class) to write one recipe. Now you can
just write the recipe inline."

---

### 📘 Concept Explanation

**Lambda syntax variants:**
```java
// (params) -> expression
Predicate<String> isEmpty = s -> s.isEmpty();
Function<String, Integer> len = s -> s.length();

// (params) -> { block }
Consumer<String> print = s -> {
    if (s != null) System.out.println(s.toUpperCase());
};

// Multiple parameters:
BiFunction<Integer, Integer, Integer> add = (a, b) -> a + b;

// No parameters:
Supplier<String> greeting = () -> "Hello!";

// With explicit types (rarely needed, inferred from target):
Function<String, Integer> len = (String s) -> s.length();
```

**Method references (shorthand lambdas):**
```java
// Static method reference:
Function<String, Integer> parse = Integer::parseInt;
// Equivalent: s -> Integer.parseInt(s)

// Instance method reference (on specific instance):
String prefix = "Hello";
Predicate<String> starts = prefix::startsWith;
// Equivalent: s -> prefix.startsWith(s)

// Instance method reference (on any instance of the class):
Function<String, String> upper = String::toUpperCase;
// Equivalent: s -> s.toUpperCase()

// Constructor reference:
Supplier<ArrayList<String>> listMaker = ArrayList::new;
// Equivalent: () -> new ArrayList<String>()

Function<Integer, ArrayList<String>> listWithCap = ArrayList::new;
// Equivalent: cap -> new ArrayList<String>(cap)
```

---

### 💻 Code Example

> **Code walkthrough:** The variable capture example shows the critical
> difference between capturing a reference vs a value. The `AtomicInteger`
> workaround is idiomatic for counting in lambdas. The closure-vs-capture
> distinction matters: lambdas capture the REFERENCE (must be effectively
> final), not a copy of the value. Using mutable state in lambdas that
> run concurrently causes race conditions.

```java
// BAD: mutable variable capture (compile error):
int count = 0;
List<String> names = List.of("Alice", "Bob", "Carol");
names.forEach(name -> count++); // COMPILE ERROR: local variable must
                                 // be final or effectively final

// GOOD: use AtomicInteger for mutable capture:
AtomicInteger count = new AtomicInteger(0);
names.forEach(name -> count.incrementAndGet()); // reference is final
System.out.println(count.get()); // 3

// BETTER: use stream reduction:
long count = names.stream().count(); // 3

// Functional interface composition:
Function<String, String> trim = String::trim;
Function<String, String> upper = String::toUpperCase;
Function<String, String> trimThenUpper = trim.andThen(upper);
Function<String, String> upperAfterTrim = upper.compose(trim);
// andThen: apply trim, then apply upper
// compose: same as andThen but reversed (apply upper, then trim)
// Both produce same result here; compose is less common

// Predicate combination:
Predicate<String> isLong = s -> s.length() > 5;
Predicate<String> startsWithA = s -> s.startsWith("A");
Predicate<String> longOrStartsWithA = isLong.or(startsWithA);
Predicate<String> longAndStartsWithA = isLong.and(startsWithA);
Predicate<String> notLong = isLong.negate();

List<String> filtered = names.stream()
    .filter(isLong.or(startsWithA))
    .collect(Collectors.toList());
```

> **Code walkthrough:** `Function.andThen(f)` creates a composed function
> that applies `this`, then `f`. `Function.compose(f)` applies `f` first,
> then `this`. Remember: `g.andThen(f) = f(g(x))`. This is function
> composition. Predicate composition with `.and()`, `.or()`, `.negate()`
> enables building complex filter conditions from simple, reusable parts.
> This is the open/closed principle applied to filtering logic.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Lambdas are anonymous functions that implement functional interfaces.
> Syntax: `(params) -> body`. Method references (`Class::method`) are
> shorthand. Captured variables must be effectively final. Common functional
> interfaces: `Function`, `Predicate`, `Consumer`, `Supplier`.

---

**Senior / Staff (5+ years):**
> Lambdas use `invokedynamic` (Java 7 bytecode instruction). On first
> use, a bootstrap method generates a class implementing the functional
> interface. Subsequent calls reuse the same class or even the same
> instance (if the lambda doesn't capture any variables - stateless lambdas
> are singletons). This means lambdas have near-zero overhead compared
> to anonymous classes. The capturing behavior: non-capturing lambdas
> are cached as constants. Capturing lambdas create a new instance per
> call (they need to store the captured reference). Design principle:
> prefer non-capturing lambdas (pure functions) in high-frequency paths.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Lambda creates a new object for each call."**
Non-capturing lambdas (no variable capture) are typically optimized
by the JVM to a single shared instance. Capturing lambdas (that close
over a variable) create a new instance per call, but the overhead is
small (like `new Object()`) - much less than a full anonymous class.

**Misconception 2: "Lambda `this` refers to the lambda itself."**
Lambda `this` refers to the ENCLOSING class instance (same as using
`this` in the enclosing method). An anonymous class has its own `this`.
This difference affects callback patterns where you need to reference
`this` for unregistering or self-reference.

---

### 🚨 Failure Modes and Diagnosis

**Failure: capturing mutable field causes thread-safety issue.**
```java
class Service {
    private String prefix = "LOG: ";
    Runnable createLogger(String msg) {
        // Captures 'this' (via this.prefix)
        return () -> System.out.println(prefix + msg);
        // If another thread changes prefix, this lambda sees the change!
    }
}
```
Diagnosis: inconsistent log prefixes; use effectively-final local
variable: `String p = this.prefix; return () -> System.out.println(p + msg);`

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Lambda syntax and types | 2 minutes |
| Functional interfaces | 2 minutes |
| Method references | 2 minutes |
| Effective finality | 2 minutes |
| Lambda vs anonymous class | 2 minutes |
| invokedynamic internals | 2-3 minutes |
| Predicate/Function composition | 2 minutes |
| Custom functional interface | 90 seconds |
| Lambda in concurrent context | 2 minutes |

---

**Q1 (Lambda syntax and types): Describe the different lambda syntax forms.**

A:
```java
// Form 1: single param, single expression (no parens, no return)
Predicate<String> p1 = s -> s.isEmpty();

// Form 2: single param, block (needs return if non-void)
Function<String, String> f1 = s -> {
    if (s == null) return "";
    return s.trim();
};

// Form 3: multiple params
BiFunction<String, Integer, String> f2 = (str, n) -> str.repeat(n);

// Form 4: no params
Supplier<String> s1 = () -> "constant";

// Form 5: explicit types (compiler usually infers)
Function<String, Integer> f3 = (String s) -> s.length();

// Form 6: throws checked exception (must wrap or define @FunctionalInterface)
// Supplier<String> s2 = () -> Files.readString(path); // won't compile!
// Either: custom @FunctionalInterface that declares throws IOException,
// or wrap in try-catch:
Supplier<String> s2 = () -> {
    try { return Files.readString(path); }
    catch (IOException e) { throw new UncheckedIOException(e); }
};
```

*What separates good from great:* The checked exception limitation is
a real friction point. Java's standard functional interfaces don't declare
checked exceptions. Solutions: (1) wrap in unchecked exception
(`UncheckedIOException`), (2) define custom functional interface with
`throws`, (3) use Vavr's `CheckedFunction` or similar library. In
production: wrapping with `UncheckedIOException` or `RuntimeException`
with a cause is standard. The cause chain remains intact for logging.

---

**Q2 (Functional interfaces): What is a functional interface? List
the key JDK functional interfaces.**

A: A functional interface has exactly ONE abstract method. It may have
default and static methods. Annotated with `@FunctionalInterface` (optional
but recommended - enforces the one-abstract-method constraint).

```java
// JDK functional interfaces:
// java.util.function package

Function<T, R>        // T -> R (transform)
BiFunction<T,U,R>     // (T,U) -> R
UnaryOperator<T>      // T -> T (extends Function<T,T>)
BinaryOperator<T>     // (T,T) -> T

Predicate<T>          // T -> boolean (test)
BiPredicate<T,U>      // (T,U) -> boolean

Consumer<T>           // T -> void (action)
BiConsumer<T,U>       // (T,U) -> void

Supplier<T>           // () -> T (factory)

Runnable              // () -> void (in java.lang)
Callable<V>           // () -> V throws Exception (in java.util.concurrent)

// Primitive specializations (avoid autoboxing):
IntFunction<R>        // int -> R
ToIntFunction<T>      // T -> int
IntUnaryOperator      // int -> int
IntBinaryOperator     // (int, int) -> int
// Also: Long, Double variants
```

*What separates good from great:* Choosing the right functional interface
avoids unnecessary boxing. `mapToInt(Function<T, Integer>)` would box
every `int` result into `Integer`. `mapToInt(ToIntFunction<T>)` avoids
this. When designing APIs that accept callbacks: prefer the specific
primitive variant if the type is known (`IntSupplier` instead of
`Supplier<Integer>`). For custom functional interfaces: define them
only when none of the JDK interfaces fits, and annotate with
`@FunctionalInterface` for documentation and compiler enforcement.

---

**Q3 (Method references): Explain the four kinds of method references.**

A:

**1. Static method reference: `ClassName::staticMethod`**
```java
// s -> Integer.parseInt(s) -> Integer::parseInt
Function<String, Integer> parse = Integer::parseInt;
```

**2. Instance method on a specific instance: `instance::instanceMethod`**
```java
String prefix = "Hello";
Predicate<String> starts = prefix::startsWith; // prefix bound at creation
// s -> prefix.startsWith(s)
```

**3. Instance method on any instance of the class: `ClassName::instanceMethod`**
```java
// The target instance is the first argument:
Function<String, String> upper = String::toUpperCase;
// s -> s.toUpperCase()

Comparator<String> comp = String::compareTo;
// (s1, s2) -> s1.compareTo(s2)
```

**4. Constructor reference: `ClassName::new`**
```java
Supplier<List<String>> listFactory = ArrayList::new;
// () -> new ArrayList<>()

BiFunction<String, Integer, StringBuilder> sb = StringBuilder::new;
// (str, capacity) -> not directly, but: () -> new StringBuilder()
// The matching depends on the functional interface's parameter count
```

*What separates good from great:* Type 3 (unbound instance method) is
the most confusing. `String::toUpperCase` has zero explicit parameters
in the method signature, but the lambda form `s -> s.toUpperCase()` has
one parameter. This is because the "receiver" (the object on which the
method is called) becomes the first parameter in the functional interface.
This is why `String::compareTo` works as a `Comparator<String>` -
`Comparator.compare(s1, s2)` maps to `s1.compareTo(s2)`.

---

**Q4 (Effective finality): What is "effectively final" and why does
Java require it for lambda captures?**

A: "Effectively final" means a variable whose value is never changed
after initialization (it could be declared `final` but isn't required to be).

Java 8 relaxed the rule from "must be declared `final`" to "must be
effectively final" - same semantics, less verbosity.

```java
int x = 10;           // effectively final (never reassigned)
int y = 20;
y = 30;               // NOT effectively final (reassigned)

Runnable r = () -> {
    System.out.println(x); // OK: x is effectively final
    System.out.println(y); // COMPILE ERROR: y is not effectively final
};
```

**Why required?**
Lambda runs in a different context (possibly different thread, certainly
after the local variable goes out of scope). Java could capture a COPY
of the value (like closures in other languages), which it does. But if
the local variable could change, the lambda would see an inconsistent
view: `y = 30; Runnable r = () -> print(y); y = 40;` - which `y` should
the lambda print?

The requirement for effective finality makes the captured value unambiguous:
the lambda gets the value at capture time and it never changes.

*What separates good from great:* The restriction is specific to LOCAL
VARIABLES. Instance fields can be mutated inside lambdas (they're accessed
via `this` reference, which is effectively final). The mutation of instance
fields in lambdas is legal but can cause thread-safety issues in concurrent
streams. `Stream.parallel()` with lambdas that modify shared instance
state without synchronization is a common production bug.

---

**Q5 (Lambda vs anonymous class): What are the differences between
lambdas and anonymous classes?**

A:

| Aspect | Anonymous Class | Lambda |
|---|---|---|
| `this` reference | Refers to the anonymous class | Refers to enclosing class |
| `super` keyword | References anonymous class's super | Not applicable |
| Can have state (fields) | Yes | No (captures only) |
| Can extend a class | Yes | No (functional interface only) |
| Can be serialized | If implements Serializable | Unreliable; avoid |
| Performance | New class generated at compile time | invokedynamic; better at runtime |
| Shadowing outer variables | Yes (same-name field shadows outer) | No (compile error) |
| Single abstract method | No restriction | Required |

```java
// Lambda captures enclosing this:
class Outer {
    String name = "Outer";
    Runnable lambda = () -> System.out.println(this.name); // "Outer"
    Runnable anon = new Runnable() {
        String name = "Anon";
        public void run() {
            System.out.println(this.name);  // "Anon"
            System.out.println(Outer.this.name); // "Outer"
        }
    };
}
```

*What separates good from great:* The `this` difference is the practical
one for real code. In event listener patterns (Swing, Android), an anonymous
class registered as a listener needs to reference itself to unregister:
`button.removeActionListener(this)` - `this` being the anonymous class.
A lambda can't do this - you'd need a variable reference:
`ActionListener listener = e -> handle(e); button.addActionListener(listener);
button.removeActionListener(listener);`

---

**Q6 (invokedynamic internals): How does the JVM implement lambdas
internally?**

A: Java 8 lambdas use the `invokedynamic` bytecode instruction
(originally added in Java 7 for dynamic languages on the JVM).

**The process:**
```
1. Compiler encounters lambda expression
2. Compiler generates:
   - invokedynamic instruction (at the lambda use site)
   - A synthetic static method containing the lambda body
     (e.g., lambda$myMethod$0)
   
3. First execution of invokedynamic:
   - JVM calls the bootstrap method (LambdaMetafactory.metafactory())
   - LambdaMetafactory generates a class implementing the functional interface
     (at RUNTIME, not compile time - this is the "dynamic" part)
   - The generated class's method delegates to the synthetic static method
   
4. Subsequent executions:
   - Non-capturing lambdas: same instance reused (constant)
   - Capturing lambdas: new instance per call (stores captured values)
```

**Why invokedynamic instead of anonymous class at compile time?**
- Forward compatibility: JVM is free to optimize lambda implementation
  in future versions without recompiling code
- Lazy class generation: classes only created when first used
- No proliferation of .class files: lambdas don't generate separate
  .class files in the JAR (anonymous classes do: `Outer$1.class`)

*What separates good from great:* The invokedynamic approach is one
reason Java 8 lambdas outperform equivalent anonymous classes in
benchmarks. Anonymous classes create a new .class file per use site,
loaded at startup. Lambdas generate one class per lambda expression
type (not per call), loaded lazily on first use. JVM profiling tools
(async-profiler, JFR) show lambda execution under the synthetic method
name (`lambda$method$0`). Knowing this helps interpret profiles.

---

**Q7 (Predicate/Function composition): How do you compose lambdas?**

A:
```java
// Function composition (andThen = left-to-right, compose = right-to-left):
Function<String, String> trim = String::trim;
Function<String, Integer> length = String::length;
Function<String, Integer> trimThenLength = trim.andThen(length);
// trimThenLength.apply("  hello  ") = 5

// Predicate combination:
Predicate<Integer> isPositive = n -> n > 0;
Predicate<Integer> isEven = n -> n % 2 == 0;
Predicate<Integer> isPositiveEven = isPositive.and(isEven);
Predicate<Integer> isPositiveOrEven = isPositive.or(isEven);
Predicate<Integer> isNotPositive = isPositive.negate();
Predicate<Object> isNull = Predicate.not(Objects::nonNull); // Java 11

// Consumer chaining (andThen):
Consumer<String> print = System.out::println;
Consumer<String> log = s -> logger.info("Processing: {}", s);
Consumer<String> printAndLog = print.andThen(log);
// Executes print first, then log

// Predicate.not() (Java 11): negate a method reference
List<String> strings = List.of("hello", "", "world", "");
strings.stream()
    .filter(Predicate.not(String::isEmpty)) // != isEmpty()
    .collect(Collectors.toList()); // ["hello", "world"]
```

*What separates good from great:* Function composition is mathematical
function composition: `f.andThen(g)` means `g(f(x))`. Use composition
to build processing pipelines from small reusable pieces. Real-world:
a validation pipeline for incoming data:
`Validator.isNotNull().and(Validator.hasMinLength(3)).and(Validator.matchesPattern("[A-Z]+"))`.
Each validator is a `Predicate<String>` - reusable across different
fields, composable for different field validation rules.

---

**Q8 (Custom functional interface): When should you define your own
functional interface?**

A: Define a custom functional interface when:

1. **Semantic clarity**: `BiFunction<String, String, String>` is opaque;
   `StringMerger` communicates domain meaning.

2. **Checked exceptions**: need to declare `throws IOException`.

3. **Primitive performance**: specialized to avoid boxing (though prefer
   JDK primitives like `IntUnaryOperator`).

4. **Documentation**: custom name in IDE, javadocs, error messages.

```java
// Custom functional interface with checked exception:
@FunctionalInterface
interface FileTransformer {
    String transform(String content, Path source)
        throws IOException;
    // Can have default methods:
    default FileTransformer andThen(FileTransformer next) {
        return (content, path) ->
            next.transform(this.transform(content, path), path);
    }
}

// Usage: cleaner API with domain-specific name
void processFiles(List<Path> files, FileTransformer transformer)
        throws IOException {
    for (Path file : files) {
        String content = Files.readString(file);
        String result = transformer.transform(content, file);
        Files.writeString(file, result);
    }
}
// Caller:
processFiles(paths, (content, path) ->
    content.replace("deprecated_api", "new_api"));
```

*What separates good from great:* The `@FunctionalInterface` annotation
is documentation and a compile-time guard. Without it: if you accidentally
add a second abstract method, the interface still compiles but lambdas
can no longer be used with it. With the annotation: the compiler errors
immediately. As a library author: always annotate intended functional
interfaces. For the `throws` use case: consider whether the checked
exception is truly appropriate or whether wrapping in a RuntimeException
(with the cause) is cleaner for callers.

---

**Q9 (Lambda in concurrent context): What are the thread-safety
considerations for lambdas?**

A: Lambdas themselves are not inherently thread-safe or unsafe - it
depends on what state they access.

```java
// SAFE: pure function (no shared mutable state):
Function<Integer, Integer> square = n -> n * n;
// Parallel streams with pure lambdas are safe:
List<Integer> squares = nums.parallelStream()
    .map(n -> n * n)
    .collect(Collectors.toList());

// UNSAFE: shared mutable state in parallel stream:
List<Integer> results = new ArrayList<>(); // NOT thread-safe!
nums.parallelStream()
    .map(n -> n * n)
    .forEach(results::add); // DATA RACE: multiple threads add simultaneously
// results may be incomplete, have nulls, or throw ConcurrentModificationException

// SAFE: use thread-safe collectors:
List<Integer> results = nums.parallelStream()
    .map(n -> n * n)
    .collect(Collectors.toList()); // Collectors.toList() is thread-safe

// SAFE with explicit synchronization:
List<Integer> syncResults = Collections.synchronizedList(new ArrayList<>());
nums.parallelStream().map(n -> n * n).forEach(syncResults::add); // OK

// PREFERRED: accumulate then return with collectors:
Map<String, Long> count = words.parallelStream()
    .collect(Collectors.groupingByConcurrent(  // parallel-safe
        Function.identity(),
        Collectors.counting()));
```

*What separates good from great:* The `parallel()` + mutable collection
pattern is one of the most common parallel stream bugs. `ArrayList`
is not thread-safe; concurrent adds can corrupt the backing array.
The correct mental model: treat parallel stream lambdas as pure functions
that take input and return output. Use collectors to aggregate - they're
designed for parallel execution. If you need side effects: make them
thread-safe (ConcurrentHashMap, AtomicInteger, synchronized) or use
`forEachOrdered()` to force sequential execution in order.

---

### ⚖️ Comparison Table

| Aspect | Lambda | Anonymous Class | Method Reference |
|---|---|---|---|
| Syntax verbosity | Low | High | Lowest |
| `this` binding | Enclosing class | Own class | Enclosing class |
| State | Captured only | Fields allowed | Captured only |
| Functional interface | Required | Optional | Required |
| Checked exceptions | Wrapping needed | Declare in interface | Same as target |
| invokedynamic | Yes | No (compile-time class) | Yes |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept)*

---

---

## Streams API Pipelines

### 🎯 Model Answer

**30 seconds:**
> A Stream is a sequence of elements supporting sequential and parallel
> aggregate operations. A pipeline has three parts: (1) SOURCE (collection,
> array, IO), (2) INTERMEDIATE OPERATIONS (lazy: filter, map, sorted,
> distinct, flatMap, limit, skip, peek) - each returns a new Stream,
> (3) TERMINAL OPERATION (eager: collect, forEach, reduce, count, min,
> max, findFirst, anyMatch, allMatch) - triggers execution. Streams
> are not collections: they do not store data, process lazily, and can
> only be consumed ONCE.

**3 minutes (Senior):**
> Lazy evaluation: intermediate operations do nothing until a terminal
> is called. With `filter().map().findFirst()`: the stream does not
> filter all elements first, then map all. Instead: it tries the first
> element through filter and map; if findFirst is satisfied, stops.
> Short-circuit operations (`findFirst`, `limit`, `anyMatch`) can process
> far fewer elements than the full source.
>
> Parallel streams: `stream.parallel()` splits the source and processes
> chunks in the `ForkJoinPool.commonPool()`. Works well for CPU-bound,
> stateless operations on large datasets. Works poorly for I/O-bound,
> stateful (sorted), or small datasets (overhead exceeds benefit).
>
> Collectors: `toList()`, `groupingBy()`, `joining()`, `partitioningBy()`,
> `toMap()`, `counting()`, `summarizingInt()`. `Collectors.groupingBy()
> ` is O(n) - one pass - not O(n log n) like sorting.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Streams API - let me cover the source-intermediate-
terminal pipeline structure, lazy evaluation, common operations, collectors,
and parallel streams."

**(2) First principles:** "From first principles: processing a collection
requires iteration. Before streams, you'd write a for loop with accumulation
variables. Streams abstract the iteration, support lazy evaluation (only
process what's needed), and enable parallel processing without explicit
thread management."

**(3) Bridge:** "A stream pipeline is like an assembly line with conveyor
belts. The raw materials come in (source), pass through processing
stations (intermediate operations), and the finished product comes out
(terminal). The conveyor only moves when the final station requests
the next part (lazy)."

---

### 📘 Concept Explanation

**Pipeline structure:**
```java
List<Employee> employees = getEmployees();

// SOURCE -> INTERMEDIATE* -> TERMINAL
List<String> seniorNames = employees.stream()    // SOURCE
    .filter(e -> e.getYears() > 5)               // INTERMEDIATE (lazy)
    .sorted(Comparator.comparing(Employee::getName)) // INTERMEDIATE
    .map(Employee::getName)                       // INTERMEDIATE
    .collect(Collectors.toList());               // TERMINAL (triggers all)
```

**Key intermediate operations:**
```
filter(Predicate)   - keep elements matching predicate
map(Function)       - transform each element
flatMap(Function)   - map to Stream, flatten 1 level
distinct()          - remove duplicates (uses equals/hashCode)
sorted()            - natural order sort (stable, O(n log n))
sorted(Comparator)  - custom order sort
limit(n)            - truncate to first n elements
skip(n)             - skip first n elements
peek(Consumer)      - debug-only: see elements without consuming
```

**Key terminal operations:**
```
collect(Collector)  - accumulate into collection/map/string
forEach(Consumer)   - process each element (unordered in parallel)
forEachOrdered(Consumer) - process in encounter order (even parallel)
count()             - count elements
min(Comparator)     - minimum Optional<T>
max(Comparator)     - maximum Optional<T>
reduce(identity, BinaryOp) - fold into single value
findFirst()         - first element Optional<T> (short-circuits)
findAny()           - any element Optional<T> (better for parallel)
anyMatch(Predicate) - true if any match (short-circuits)
allMatch(Predicate) - true if all match
noneMatch(Predicate)- true if none match
toArray()           - to Object[]
```

---

### 💻 Code Example

> **Code walkthrough:** The BAD nested for-loop contrasted with GOOD
> stream pipeline shows the declarative vs imperative style. The
> `flatMap` example is essential - it converts a `Stream<List<T>>` to
> `Stream<T>` by flattening. The groupingBy example shows a complex
> collector chain that replaces multiple lines of loop-based code with
> a single expression.

```java
// DOMAIN: employees with departments and salaries
record Employee(String name, String dept, int salary) {}

// BAD: imperative with mutable accumulators:
List<Employee> employees = loadEmployees();
List<String> result = new ArrayList<>();
for (Employee e : employees) {
    if (e.salary() > 50000) {
        result.add(e.name().toUpperCase());
    }
}
Collections.sort(result);

// GOOD: declarative stream pipeline:
List<String> result = employees.stream()
    .filter(e -> e.salary() > 50000)
    .map(e -> e.name().toUpperCase())
    .sorted()
    .collect(Collectors.toList());

// flatMap: one-to-many transformation
List<List<String>> nested = List.of(
    List.of("Java", "Python"),
    List.of("Go", "Rust"),
    List.of("JavaScript")
);
List<String> flat = nested.stream()
    .flatMap(Collection::stream) // Stream<List<String>> -> Stream<String>
    .collect(Collectors.toList());
// ["Java", "Python", "Go", "Rust", "JavaScript"]

// Collectors: group by department, get average salary:
Map<String, Double> avgSalaryByDept = employees.stream()
    .collect(Collectors.groupingBy(
        Employee::dept,
        Collectors.averagingInt(Employee::salary)));

// Collectors: get highest earner per department:
Map<String, Optional<Employee>> topByDept = employees.stream()
    .collect(Collectors.groupingBy(
        Employee::dept,
        Collectors.maxBy(Comparator.comparingInt(Employee::salary))));

// reduce: sum of salaries (prefer specialized mapToInt().sum() for int):
int totalSalary = employees.stream()
    .mapToInt(Employee::salary) // IntStream (no boxing)
    .sum();                     // terminal operation
// int totalSalary = employees.stream().reduce(0, (acc, e) -> acc + e.salary(), Integer::sum);
// mapToInt().sum() is cleaner and avoids boxing
```

> **Code walkthrough:** `mapToInt(Employee::salary).sum()` is
> preferred over `reduce()` for numeric aggregation on streams of
> objects because (1) it avoids boxing `int` to `Integer`, (2) `IntStream`
> has specialized methods (`sum`, `average`, `min`, `max`,
> `summaryStatistics`) that are idiomatic. `reduce()` is for custom
> folding operations that don't fit the built-in aggregations. The
> three-arg `reduce` (identity, accumulator, combiner) is needed for
> parallel streams where the combiner merges partial results.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Streams process elements lazily: nothing happens until a terminal
> operation is called. Pipeline: source -> filter/map/etc. -> collect.
> `flatMap` flattens nested streams. `Collectors.groupingBy()` groups
> into a map. Don't reuse a stream (consumed once). Prefer `mapToInt().sum()`
> over `reduce()` for numeric aggregation.

---

**Senior / Staff (5+ years):**
> Short-circuit operations (`findFirst`, `limit`, `anyMatch`) enable
> early termination - critical for performance on large data. Infinite
> streams (`Stream.generate()`, `Stream.iterate()`) are valid precisely
> because of laziness. For parallel streams: `ForkJoinPool.commonPool()`
> (shared with all parallel operations in the JVM). If your parallel
> stream does I/O, it blocks common pool threads and affects other
> parallel operations. Use a custom ForkJoinPool for I/O-heavy parallel:
> `new ForkJoinPool(16).submit(() -> list.parallelStream().map(this::ioOp).collect(...)).get()`.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Streams are faster than for-loops."**
For simple sequential operations on small collections: for-loops are
typically faster (no lambda invocation overhead, no pipeline setup).
Streams shine for: complex pipelines, parallel processing, readability.
Profile before switching to streams for performance.

**Misconception 2: "Parallel streams always improve performance."**
Parallel streams add overhead: splitting the source, thread management,
combining partial results. For small collections (< 10,000 elements),
overhead often exceeds savings. For I/O-bound operations: parallel
streams tie up ForkJoinPool threads on I/O, starving CPU work. Rule:
measure before using parallel().

---

### 🚨 Failure Modes and Diagnosis

**Failure: stream reuse causes IllegalStateException.**
```java
Stream<String> stream = list.stream().filter(s -> !s.isEmpty());
long count = stream.count();     // consumes the stream
stream.findFirst();              // IllegalStateException: stream closed!
// Fix: create a new stream for each terminal operation:
long count = list.stream().filter(s -> !s.isEmpty()).count();
Optional<String> first = list.stream().filter(s -> !s.isEmpty()).findFirst();
```
Diagnosis: `java.lang.IllegalStateException: stream has already been
operated upon or closed`. Always create a fresh stream from the source
for each terminal operation.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Stream pipeline lazy evaluation | 2 minutes |
| flatMap explained | 2 minutes |
| Collectors groupingBy | 2 minutes |
| Stream vs Collection | 2 minutes |
| Parallel stream trade-offs | 2-3 minutes |
| reduce vs collect | 2 minutes |
| Infinite streams | 2 minutes |
| Stream ordering | 2 minutes |
| Custom Collector | 2-3 minutes |

---

**Q1 (Stream pipeline lazy evaluation): Explain lazy evaluation in streams
with a concrete example.**

A: Intermediate operations return a new Stream without processing elements.
The processing begins only when the terminal operation is invoked.

```java
Stream<Integer> stream = List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    .stream()
    .filter(n -> {
        System.out.println("filter: " + n);
        return n % 2 == 0;
    })
    .map(n -> {
        System.out.println("map: " + n);
        return n * n;
    });
// At this point: NOTHING has been printed. No elements processed.

// Terminal operation triggers processing:
Optional<Integer> first = stream.findFirst();
// Output:
// filter: 1   (1 fails filter)
// filter: 2   (2 passes filter)
// map: 2      (2 is mapped to 4)
// DONE: findFirst returns Optional[4]
// Elements 3-10 are NEVER processed!
```

The stream processed only 3 elements (1, 2 for filter; 2 for map) out of 10.
Without laziness, all 10 would be filtered, then all matching mapped.

*What separates good from great:* Lazy evaluation enables two critical
optimizations: (1) Short-circuit: `findFirst()`, `limit(n)`, `anyMatch()`
can terminate before processing all elements. An infinite stream:
`Stream.iterate(0, n -> n + 1).filter(n -> n > 100).findFirst()` terminates
at 101. (2) Fusion: the JVM can fuse sequential filter+map+filter into
a single pass, avoiding intermediate collections. Benchmarks show fused
pipelines are often competitive with optimized for-loops.

---

**Q2 (flatMap explained): Explain flatMap with a real-world example.**

A: `map` applies a function and wraps the result in the stream.
`flatMap` applies a function that returns a stream, then flattens
(concatenates) all resulting streams into one.

```java
// Real-world: each order has a list of items - get all items:
record OrderItem(String productId, int quantity) {}
record Order(String orderId, List<OrderItem> items) {}

List<Order> orders = getOrders();

// map gives Stream<List<OrderItem>> - nested, not what we want:
Stream<List<OrderItem>> nested = orders.stream()
    .map(Order::items); // each Order maps to a List<OrderItem>

// flatMap gives Stream<OrderItem> - flat, usable:
List<OrderItem> allItems = orders.stream()
    .flatMap(order -> order.items().stream()) // flatten each list
    .collect(Collectors.toList());

// Distinct product IDs across all orders:
Set<String> productIds = orders.stream()
    .flatMap(order -> order.items().stream())
    .map(OrderItem::productId)
    .collect(Collectors.toSet());

// flatMap for Optional streams (Java 9):
List<Optional<String>> optionals = List.of(
    Optional.of("a"), Optional.empty(), Optional.of("b")
);
List<String> values = optionals.stream()
    .flatMap(Optional::stream) // removes empties
    .collect(Collectors.toList()); // ["a", "b"]
```

*What separates good from great:* `flatMap` is the functional equivalent
of the monad bind operation. Understanding it deeply: `map` is 1-to-1,
`flatMap` is 1-to-many-then-flatten. The flattening is exactly ONE level:
`Stream<Stream<Stream<T>>>` flatMapped once is `Stream<Stream<T>>`.
Real-world patterns requiring flatMap: expanding relationships (orders to
items, sentences to words, files to lines), filtering with Optional in
streams, expanding enum values to their related items.

---

**Q3 (Collectors groupingBy): How does `Collectors.groupingBy()` work
and what are its variants?**

A:
```java
// Basic groupingBy: Map<K, List<V>>
Map<String, List<Employee>> byDept = employees.stream()
    .collect(Collectors.groupingBy(Employee::dept));
// {"Engineering": [Alice, Bob], "HR": [Carol, Dave]}

// Downstream collector (count instead of List):
Map<String, Long> countByDept = employees.stream()
    .collect(Collectors.groupingBy(
        Employee::dept,
        Collectors.counting()));
// {"Engineering": 2, "HR": 2}

// Downstream: map values to names:
Map<String, List<String>> namesByDept = employees.stream()
    .collect(Collectors.groupingBy(
        Employee::dept,
        Collectors.mapping(Employee::name, Collectors.toList())));

// Multi-level grouping:
Map<String, Map<Integer, List<Employee>>> byDeptAndLevel = employees.stream()
    .collect(Collectors.groupingBy(
        Employee::dept,
        Collectors.groupingBy(Employee::level)));

// partitioningBy: splits into two groups (true/false):
Map<Boolean, List<Employee>> partition = employees.stream()
    .collect(Collectors.partitioningBy(e -> e.salary() > 60000));
// {true: [high earners], false: [others]}

// toMap: specify key and value functions
Map<String, Integer> nameToSalary = employees.stream()
    .collect(Collectors.toMap(
        Employee::name,
        Employee::salary,
        (existing, replacement) -> existing)); // merge fn: handle duplicate keys
```

*What separates good from great:* `groupingBy` performs a single O(n)
pass and builds the map incrementally - it does NOT sort first. The
result map's entry order is unspecified (HashMap). For sorted keys: use
`groupingBy(key, TreeMap::new, downstream)`. For stable insertion order:
`groupingBy(key, LinkedHashMap::new, downstream)`. The `merge function`
parameter in `toMap` is required when duplicate keys are possible -
without it, `toMap` throws `IllegalStateException` on duplicate keys
in Java 8. Always provide a merge function for production code.

---

**Q4 (Stream vs Collection): When do you use a Stream vs a Collection?**

A:

| Aspect | Collection | Stream |
|---|---|---|
| Stores data | Yes | No (processes from source) |
| Iterable | Yes (multiple times) | Once (terminal exhausts it) |
| Modifiable | Yes (add/remove) | No |
| Lazy | No (all in memory) | Yes |
| Parallel | Requires external sync | `parallel()` built-in |
| Infinite | No | Yes (generate/iterate) |
| Intermediate results | Yes | No |
| Random access | Some (List) | No |

**Use Collection when:**
- Need to store results for later use
- Need random access or multiple iterations
- Passing data between components

**Use Stream when:**
- One-pass processing (filter, map, aggregate)
- Lazy evaluation needed (short-circuit, large data)
- Composing transformations
- Parallel processing

```java
// One-pass aggregation: Stream
double avgSalary = employees.stream()
    .mapToInt(Employee::salary)
    .average().orElse(0);

// Store results + later access: collect to List
List<String> names = employees.stream()
    .map(Employee::name).collect(Collectors.toList());
names.get(0); // random access - needs Collection
```

*What separates good from great:* Streams cannot be used as method
arguments that are iterated multiple times. A common mistake: returning
a Stream from a method and calling two terminal operations on it (first
call consumes it, second throws IllegalStateException). Stream as a
return type is appropriate only for terminal-once use; return a Collection
or Supplier<Stream> for reusable data. Spring Data's `Stream<T> findAll()`
requires the transaction to remain open for the full stream consumption -
a common pitfall in non-transactional service code.

---

**Q5 (Parallel stream trade-offs): When should you use parallel streams?**

A: Parallel streams split the source, process chunks on ForkJoinPool threads,
and merge results. Beneficial when:

**Good fit for parallel:**
- Large data (> 10,000 elements typically)
- CPU-intensive, stateless operations
- Data structures that split well: ArrayList, arrays (random access)
- No ordering constraint (unordered operations)

**Poor fit for parallel:**
- Small data (overhead exceeds benefit)
- I/O-bound operations (blocks ForkJoinPool threads)
- Stateful operations requiring ordering (sorted())
- Poorly-splittable sources: LinkedList, IO streams
- Operations with side effects on shared state

```java
// BAD: parallel for small list (overhead dominates):
List<Integer> small = List.of(1, 2, 3, 4, 5);
small.parallelStream().map(n -> n * 2).collect(Collectors.toList());
// Sequential is faster for 5 elements

// GOOD: parallel for large CPU-bound work:
List<Image> images = loadImages(); // 10,000 images
List<Image> processed = images.parallelStream()
    .map(this::applyFilters) // CPU-bound: works well in parallel
    .collect(Collectors.toList());

// DANGEROUS: I/O in parallel on common pool:
// Blocks ForkJoinPool.commonPool() threads on network calls
urls.parallelStream()
    .map(url -> httpClient.get(url)) // BLOCKS COMMON POOL THREAD
    .collect(Collectors.toList()); // other parallel ops in JVM starved
// Use: CompletableFuture or virtual threads (Java 21) instead
```

*What separates good from great:* The ForkJoinPool.commonPool() is
shared across all parallel streams in the JVM, `CompletableFuture`
executions, and user code that submits to it. Blocking it with I/O
starves other parallel work. The solution for I/O-bound parallel work:
use `CompletableFuture.supplyAsync()` with a dedicated executor, or
Java 21 virtual threads (`Thread.ofVirtual()`). Always measure parallel
vs sequential performance with realistic data sizes before making the
switch. JMH (Java Microbenchmark Harness) is the standard tool.

---

**Q6 (reduce vs collect): When do you use reduce vs collect?**

A:
```java
// reduce: fold elements into a single value (immutable accumulation)
int sum = IntStream.rangeClosed(1, 100).reduce(0, Integer::sum);
// identity=0, accumulator=(acc, n) -> acc + n
// Result: 5050

// collect: mutable reduction into a container
List<String> names = employees.stream()
    .map(Employee::name)
    .collect(Collectors.toList()); // mutable container built up

// Parallel reduce: identity must be an identity for the accumulator:
// reduce(0, Integer::sum) is correct: 0 is the identity for sum
// reduce("", String::concat) is DANGEROUS in parallel:
//   partial results can be concatenated in unpredictable orders
//   AND is O(n^2) due to string creation
// Better: collect(Collectors.joining()) for String concatenation

// Three-arg reduce for parallel (identity, accumulator, combiner):
int sumParallel = employees.parallelStream()
    .reduce(
        0,                           // identity
        (acc, e) -> acc + e.salary(), // accumulator
        Integer::sum                 // combiner (merges partial results)
    );
```

**Rule:** use `reduce` for immutable accumulation into a single value
(sum, product, max). Use `collect` for mutable container building
(List, Map, StringBuilder). For parallel: `reduce` is safe if identity
is correct and accumulator is associative and stateless.

*What separates good from great:* The two-arg `reduce(identity, accumulator)`
works in parallel by splitting the stream, reducing each part (using
identity as the starting value), then combining. The identity MUST truly
be an identity: `reduce(0, ...)` for sum, `reduce(1, ...)` for product,
`reduce("", ...)` for concatenation. Providing a non-identity as the
"identity" causes wrong results in parallel (partial results are combined
with the identity again). This is the most common `reduce` bug.

---

**Q7 (Infinite streams): How do you create and use infinite streams?**

A:
```java
// Stream.iterate: first element = seed, rest = f(previous)
Stream<Integer> naturals = Stream.iterate(0, n -> n + 1);
// 0, 1, 2, 3, 4, ...

// Java 9: Stream.iterate with predicate (like a for loop)
Stream<Integer> under100 = Stream.iterate(0, n -> n < 100, n -> n + 1);
// like: for (int n = 0; n < 100; n++)

// Stream.generate: each element from a Supplier
Stream<Double> randoms = Stream.generate(Math::random);
Stream<String> uuids = Stream.generate(() -> UUID.randomUUID().toString());

// Use with short-circuit or limit:
List<Integer> first10Evens = Stream.iterate(0, n -> n + 2)
    .limit(10)
    .collect(Collectors.toList()); // [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]

// Fibonacci:
Stream.iterate(new int[]{0, 1}, f -> new int[]{f[1], f[0] + f[1]})
    .limit(10)
    .mapToInt(f -> f[0])
    .forEach(System.out::println); // 0 1 1 2 3 5 8 13 21 34

// Real-world: paginated API calls:
Stream.iterate(1, page -> page + 1)
    .map(page -> api.getUsers(page, 100))
    .takeWhile(users -> !users.isEmpty())  // Java 9: stop when empty page
    .flatMap(Collection::stream)
    .collect(Collectors.toList());
```

*What separates good from great:* The paginated API use case is a real
production pattern for consuming paginated REST APIs. `takeWhile` (Java 9)
is the key: it stops the infinite iteration when the predicate becomes false.
Before Java 9, you'd use `generate` with a `AtomicBoolean` flag or implement
a custom `Spliterator`. The `takeWhile`/`dropWhile` (Java 9) additions
fill the gap between `limit(n)` (count-based) and `filter` (which never
short-circuits for non-matching tails).

---

**Q8 (Stream ordering): What is encounter order and how does it affect
parallel streams?**

A: Encounter order = the order in which elements appear in the source.
Some sources have encounter order (List, arrays - ordered). Some don't
(HashSet, HashMap - unordered).

```java
// Ordered source: order is preserved
List<Integer> nums = List.of(1, 2, 3, 4, 5);
nums.stream().map(n -> n * 2).collect(Collectors.toList());
// [2, 4, 6, 8, 10] - order preserved

// Unordered source: no order guarantee
Set<Integer> numSet = new HashSet<>(nums);
numSet.stream().map(n -> n * 2).collect(Collectors.toList());
// any order: [8, 2, 10, 4, 6] or similar

// Parallel with ordered source: order maintained, but may be slower:
nums.parallelStream().collect(Collectors.toList()); // order preserved but slower
// Worker threads must synchronize to maintain order

// Unordered hint: improve parallel performance when order doesn't matter:
nums.parallelStream()
    .unordered()                // hint: don't need encounter order
    .filter(n -> n % 2 == 0)   // may process in any order
    .collect(Collectors.toList()); // [4, 2] or [2, 4] - any order, faster

// findFirst vs findAny:
Optional<Integer> first = nums.parallelStream().findFirst(); // forces order
Optional<Integer> any = nums.parallelStream().findAny(); // no order - faster
```

*What separates good from great:* Maintaining encounter order in parallel
streams requires coordination between threads (they must produce output
in order). `unordered()` tells the stream it can abandon order, potentially
improving parallel performance. For pipelines where order doesn't matter
(collecting to a Set, computing aggregates), always add `unordered()` in
parallel mode. For pipelines where order matters (collecting to a List
that's displayed to users): don't add `unordered()`, accept the ordering
cost.

---

**Q9 (Custom Collector): How do you implement a custom Collector?**

A:
```java
// Collector<T, A, R>: T=input, A=accumulator, R=result
// Implement 5 methods: supplier, accumulator, combiner, finisher, characteristics

// Example: collect to an immutable list (Guava-style):
Collector<String, List<String>, List<String>> toImmutableList =
    Collector.of(
        ArrayList::new,                      // supplier: creates mutable container
        List::add,                           // accumulator: adds element
        (left, right) -> {                   // combiner: merge two containers (parallel)
            left.addAll(right);
            return left;
        },
        Collections::unmodifiableList,       // finisher: convert to final result
        Collector.Characteristics.UNORDERED  // optional characteristics
    );

// Characteristics:
// CONCURRENT: combiner not used; accumulator handles concurrent access
// UNORDERED: order of accumulation doesn't matter
// IDENTITY_FINISH: finisher is identity (no-op); result = accumulator type

// Real-world: collect statistics:
Collector<Integer, int[], IntSummaryStatistics> stats =
    Collector.of(
        () -> new int[]{0, 0, Integer.MAX_VALUE, Integer.MIN_VALUE}, // [count, sum, min, max]
        (acc, n) -> {
            acc[0]++; acc[1] += n;
            acc[2] = Math.min(acc[2], n);
            acc[3] = Math.max(acc[3], n);
        },
        (left, right) -> new int[]{
            left[0] + right[0],
            left[1] + right[1],
            Math.min(left[2], right[2]),
            Math.max(left[3], right[3])
        },
        acc -> new IntSummaryStatistics(acc[0], acc[2], acc[3], acc[1])
    );
```

*What separates good from great:* Custom collectors are rare but
powerful for building domain-specific aggregations. The combiner is
ONLY called for parallel streams - it merges two partial results.
If your collector is not parallel-safe: don't add CONCURRENT.
The finisher allows transformation of the internal mutable accumulator
into the final immutable result type. For the IDENTITY_FINISH optimization:
the JVM skips the finisher call entirely, saving one function invocation
per pipeline execution.

---

### ⚖️ Comparison Table

| Approach | for-loop | Stream | Parallel Stream |
|---|---|---|---|
| Readability | Low-medium | High | High |
| Laziness | No | Yes | Yes |
| Short-circuit | Manual (break) | Built-in | Built-in |
| Thread safety | Manual | N/A (sequential) | Requires care |
| Performance (small data) | Fastest | Comparable | Slower (overhead) |
| Performance (large data) | Good | Good | Faster (if CPU-bound) |
| Infinite data | Manual | Yes (generate/iterate) | Yes |
| Composability | Low | High | High |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: pipeline structure described adequately in Concept Explanation)*
