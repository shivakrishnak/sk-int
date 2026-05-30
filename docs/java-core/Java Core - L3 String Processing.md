---
layout: default
title: "Java Core - L3 String Processing"
parent: "Java Core"
grand_parent: "SK Interview"
nav_order: 11
permalink: /java-core/l3-string-processing/
render_with_liquid: false
---

# Java Core - L3 String Processing

## String Processing and Regular Expressions

### 🎯 Model Answer

**30 seconds:**
> Java Strings are immutable UTF-16 sequences. String operations that
> "modify" a string create new objects. `StringBuilder` is mutable for
> repeated concatenation. For regex: `Pattern.compile(regex)` returns a
> thread-safe `Pattern`; `pattern.matcher(str)` returns a non-thread-safe
> `Matcher` (per-thread). Key regex risk: catastrophic backtracking -
> `(a+)+b` on "aaaaac" causes exponential time. Always pre-compile patterns
> as static finals. `String.format` is 5-10x slower than concatenation for
> simple cases; use it only for complex formatting.

**3 minutes (Senior):**
> String immutability supports the String pool: identical literals share
> references. `intern()` moves a runtime string into the pool. Java 9+
> compact strings: ASCII-only strings stored as byte[] (Latin-1 encoding)
> instead of char[], halving memory for common ASCII strings.
>
> StringBuilder: single-threaded mutable string. StringBuffer: same but
> synchronized (rarely needed - prefer StringBuilder). String concatenation
> in loops: Java compiler converts `s += x` to `new StringBuilder().append(s).append(x).toString()`
> per iteration - O(n^2) for n iterations. Pre-allocate StringBuilder with
> expected capacity to minimize resizing.
>
> Regex performance: `Pattern.compile()` builds NFA (expensive); do once as
> static final. `matches()` requires FULL string match; `find()` searches
> for substring match. Possessive quantifiers (`a++`) and atomic groups
> (`(?>...)`) prevent backtracking. For input validation (user data):
> always set a character limit before applying regex to prevent ReDoS attacks.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "String processing - let me cover String immutability
and pool, StringBuilder vs StringBuffer, regex with Pattern/Matcher,
performance traps, and ReDoS security."

**(2) First principles:** "Strings being immutable means concatenation
allocates new objects. For building strings: StringBuilder pools mutations
before creating the final string. Regex patterns are compiled state
machines - compile once, run many times."

**(3) Bridge:** "String processing is like carpentry. String concatenation
is a single cut. StringBuilder is a workbench where you assemble pieces
before showing the final result. Regex is a CNC machine - expensive
to set up (compile), fast to run repeatedly."

---

### 📘 Concept Explanation

**String pool and immutability:**
```
"Hello" literal -> String pool -> single shared instance
new String("Hello") -> heap object (outside pool)
"Hello".intern() -> look up pool, return pooled reference
```

**String manipulation methods (key ones):**
```java
// Testing:
s.isEmpty()          // length == 0
s.isBlank()          // Java 11: only whitespace
s.contains("sub")    // includes substring
s.startsWith("pre")  // prefix check
s.matches("regex")   // full-match regex
// Searching:
s.indexOf("sub")     // first occurrence (-1 if not found)
s.lastIndexOf("sub") // last occurrence
s.indexOf('c', 5)    // from position 5
// Transformation:
s.toUpperCase()      // new String
s.toLowerCase(Locale.ROOT) // locale-independent for programs!
s.trim()             // removes ASCII whitespace (<=32)
s.strip()            // Java 11: removes Unicode whitespace
s.stripLeading()     // leading only
s.stripTrailing()    // trailing only
s.replace('a', 'b')  // char replacement
s.replace("old", "new") // literal replacement
s.replaceAll("regex", "sub") // regex replacement
s.split("regex")     // split into array
// Conversion:
String.valueOf(42)   // int to String
Integer.parseInt("42") // String to int
// Java 11+ methods:
s.repeat(3)          // "ha".repeat(3) = "hahaha"
s.lines()            // Stream<String> of lines
```

**StringBuilder:**
```java
StringBuilder sb = new StringBuilder(256); // pre-allocate capacity!
sb.append("Hello").append(", ").append("World");
sb.insert(5, " beautiful"); // insert at index
sb.delete(5, 15);            // delete range
sb.reverse();                // reverse in-place
sb.setCharAt(0, 'h');        // modify char at index
String result = sb.toString();
```

---

### 💻 Code Example

> **Code walkthrough:** The O(n^2) string concatenation in loops is one
> of Java's most common performance bugs. Every `+=` in a loop creates
> a new String: first iteration allocates 2 chars, second 4, third 6...
> total allocations = n*(n+1)/2. For n=10,000: 50M character allocations.
> StringBuilder accumulates into a single growable buffer: amortized O(n).
> The regex examples show both correct usage (static final Pattern) and
> the dangerous ReDoS pattern.

```java
// BAD: string concatenation in loop - O(n^2)
String buildReport(List<String> lines) {
    String result = ""; // new String() every iteration!
    for (String line : lines) {
        result += line + "\n"; // 2 allocations per iteration
    }
    return result;
    // For 10,000 lines: ~50M character copies total!
}

// GOOD: StringBuilder - O(n)
String buildReport(List<String> lines) {
    StringBuilder sb = new StringBuilder(lines.size() * 80); // pre-size!
    for (String line : lines) {
        sb.append(line).append('\n'); // char not String literal!
    }
    return sb.toString(); // single final allocation
}

// ALSO GOOD: String.join (JDK 8+)
String report = String.join("\n", lines);
// Or: stream collectors
String report = lines.stream()
    .collect(Collectors.joining("\n", "", "\n")); // prefix, suffix

// Regex: compile once as static final
private static final Pattern EMAIL_PATTERN = Pattern.compile(
    "^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$"
);

boolean isValidEmail(String input) {
    if (input == null || input.length() > 254) return false; // bounds check!
    return EMAIL_PATTERN.matcher(input).matches(); // full match
}

// Regex: find vs matches
String text = "Contact: alice@example.com or bob@example.com";
Matcher m = EMAIL_PATTERN.matcher(text);
while (m.find()) {
    System.out.println("Found: " + m.group()); // extract each match
}
// matches() would fail: "Contact: ..." is not an email (not full match)

// Named capture groups (Java 7+):
Pattern p = Pattern.compile(
    "(?<year>\\d{4})-(?<month>\\d{2})-(?<day>\\d{2})");
Matcher m = p.matcher("2024-01-15");
if (m.matches()) {
    String year  = m.group("year");  // "2024"
    String month = m.group("month"); // "01"
    String day   = m.group("day");   // "15"
}

// ReDoS vulnerable pattern: NEVER use in production on user input
// Pattern: (a+)+  - catastrophic backtracking
// "aaaaab" -> exponential attempts to match the trailing 'b'
// Pattern p = Pattern.compile("(a+)+b"); // DANGEROUS on user input!
// Safe: possessive quantifier (no backtracking): "a++b"
// Safe: atomic group: "(?> a+)b"
```

> **Code walkthrough:** The `'\\n'` vs `"\n"` in `append()` matters:
> `append('\n')` appends a char (faster, no String allocation); `append("\n")`
> appends a String (requires string lookup). For high-frequency loops,
> prefer char literals for single characters. Pre-sizing StringBuilder
> with `lines.size() * 80` (estimated line length) avoids internal buffer
> resizing - each resize creates a new array twice the old size and copies.
> If you know the approximate output size, pre-sizing is a significant
> optimization.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Use `StringBuilder` for string building in loops. Pre-compile regex
> patterns as `static final Pattern`. `String.matches()` is a full-match
> check (matches the ENTIRE string), not `contains()`. `+` concatenation
> is fine for one-off cases; avoid in loops. `toLowerCase(Locale.ROOT)`
> for case-insensitive comparisons in code (not for user display).

---

**Senior / Staff (5+ years):**
> String performance at scale: interning large numbers of strings causes
> PermGen/Metaspace pressure in Java 8 (pool moved to heap in Java 8).
> `String.format` uses `Formatter` internally - each call parses the
> format string; fine for low-frequency use, bad in hot paths (use
> StringBuilder or String.join). For internationalization: never use
> `toLowerCase()` without locale - Turkish "I".toLowerCase() = "ı" (dotless i),
> not "i". Use `Locale.ROOT` for programmatic identifiers, `Locale.forLanguageTag()`
> for user-facing. ReDoS: input validation with complex regex on user data is
> an attack surface - bound input length, use possessive quantifiers, test
> with a ReDoS detector tool.

---

### ⚠️ Common Misconceptions

**Misconception 1: "`==` compares String content."**
`==` compares references (memory addresses). Two `new String("abc")` objects
are `==`-different but `.equals()`-equal. String literals from the pool
MAY be `==`-equal (both point to the pool entry) but this is an implementation
detail, not a contract. Always use `.equals()` for string comparison.

**Misconception 2: "`String.matches(regex)` searches for a pattern."**
`matches()` requires the ENTIRE string to match the pattern. For substring
search: `Pattern.compile(regex).matcher(str).find()`. Equivalent:
`matches(".*" + regex + ".*")` but that's inefficient.

---

### 🚨 Failure Modes and Diagnosis

**Failure: ReDoS - regex denial of service.**
```java
// Vulnerable pattern on user input:
// Pattern: ^(a+)+$ matches "aaaa...b" exponentially
// An attacker sends: "aaaaaaaaaaaaaaaaaac" (20 a's + c)
// Match attempt: O(2^20) = 1M+ backtracking steps -> thread blocked!

// Diagnosis: thread dumps show threads stuck in java.util.regex.Pattern$GroupTail
// with massive callstack depth (regex recursion)

// Fix 1: Add input length limit before regex:
if (input.length() > 1000)
    throw new ValidationException("Input too long");

// Fix 2: Use possessive quantifiers (no backtracking):
Pattern.compile("^(a++)++$"); // possessive ++ never backtracks

// Fix 3: Rewrite to avoid nested quantifiers:
Pattern.compile("^a+$"); // equivalent simpler form

// Tools: bl.ocks.org/nicowillis/5781121 (ReDoS detector)
// Java 8 regex has NO timeout - vulnerable to runaway regexes
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| String immutability benefits | 2 minutes |
| StringBuilder vs StringBuffer | 90 seconds |
| String pool and intern() | 2 minutes |
| Regex Pattern/Matcher | 2 minutes |
| ReDoS and security | 2-3 minutes |
| String.format performance | 2 minutes |
| Text blocks (Java 15) | 90 seconds |
| Locale-sensitive operations | 2 minutes |
| String comparison | 90 seconds |

---

**Q1 (String immutability): What are the benefits of String immutability?**

A:
1. **Thread safety:** shared strings need no synchronization
2. **String pool:** identical literals share one instance (memory savings)
3. **Hashcode caching:** `String.hashCode()` is computed once and cached (used as HashMap keys)
4. **Security:** passwords/filenames can't be modified by callers; interned strings stable
5. **Simplicity:** method contracts are clearer without defensive copies

```java
// Thread safety - no synchronization needed:
static final String CONFIG_KEY = "database.url"; // shared across threads
// Mutation would be unsafe: any thread could corrupt CONFIG_KEY

// Hashcode caching (see String source):
// private int hash; // cached on first call
String key = "somekey";
map.get(key); // hashCode computed and cached on first call
map.get(key); // subsequent calls use cached value (0 check: 0 not cached)

// Security: password as char[] is better than String for clearing:
char[] password = {'s','e','c','r','e','t'};
// ... use password ...
Arrays.fill(password, '\0'); // zero out after use - preventss heap dump exposure
// vs: String password = "secret" -> can't clear! stays in pool
```

*What separates good from great:* The security implication is subtle.
`String` in the pool can outlive the use - a heap dump taken after the
user logged out still contains the password string. `char[]` passwords
can be zeroed after use, removing them from memory. This is why
`JPasswordField.getPassword()` returns `char[]`, not `String`. Modern
secure coding: use `char[]` for passwords/secrets, zero after use.

---

**Q2 (StringBuilder vs StringBuffer): When do you use StringBuilder vs StringBuffer?**

A: **StringBuilder** (Java 5): not thread-safe, high performance.
**StringBuffer** (Java 1.0): all methods synchronized, thread-safe, slower.

In practice: always use `StringBuilder` unless you specifically need
a thread-safe mutable string shared between threads (rare).

```java
// SingleThread: StringBuilder
void buildLog(List<Event> events) {
    StringBuilder sb = new StringBuilder(events.size() * 100);
    for (Event e : events) sb.append(e).append('\n');
    return sb.toString();
}

// Multi-thread scenario where StringBuffer MIGHT be used:
// (but usually better to use a different design)
class LogAggregator {
    private final StringBuffer buffer = new StringBuffer();
    void addLog(String entry) { buffer.append(entry).append('\n'); }
    String getLog()  { return buffer.toString(); }
}
// Better: ConcurrentLinkedQueue<String>, then join at read time

// Realistic answer: StringBuffer is legacy. In 20 years of Java development,
// you'll almost never need it. StringBuilder for everything.
```

*What separates good from great:* The JVM JIT can sometimes "destack"
`StringBuilder` allocations in tight loops (escape analysis). If the
StringBuilder doesn't escape the method, the JIT may eliminate the allocation
entirely, placing the buffer on the stack. This is an optimization you don't
control but is worth knowing: prefer local StringBuilder variables that don't
escape for maximum JIT optimization opportunity.

---

**Q3 (String pool and intern()): How does the String pool work and when do you intern()?**

A: The String pool (String intern table) is a hash table of canonical
string references in the JVM heap (Java 8+, was PermGen before).
String literals are automatically interned. `intern()` looks up or inserts
a string into the pool.

```java
String a = "hello"; // from pool (literal)
String b = "hello"; // same pool reference
System.out.println(a == b); // true (same object)

String c = new String("hello"); // new heap object, NOT from pool
System.out.println(a == c); // false (different objects)
System.out.println(a.equals(c)); // true (same content)

String d = c.intern(); // look up "hello" in pool -> returns a
System.out.println(a == d); // true (d is the pooled reference)

// Performance use case: intern large numbers of repeated strings
// (e.g., parsing CSV with repeated category values)
// WARNING: interning millions of unique strings = OutOfMemoryError
// (pool never GCed for strong references)

// Safer alternative: use an explicit cache:
Map<String, String> cache = new HashMap<>();
String intern(String s) {
    return cache.computeIfAbsent(s, k -> k); // own pool, GC-able
}
```

*What separates good from great:* Interning is a space-time trade-off.
If you have millions of record fields that are frequently the same string
(stock symbols, country codes, status strings), interning eliminates
duplicate objects. Netflix's Hollow library uses this for large dataset
optimizations. The risk: the JVM String pool's default table size is 60013
(Java 8 and earlier); adjust with `-XX:StringTableSize=N` for large pools.
Java 11+ uses a default of 65536. For production analytics with many distinct
strings: don't intern (memory pressure); for repeated lookup values: interning
reduces memory.

---

**Q4 (Regex Pattern/Matcher): How do you use Pattern and Matcher efficiently?**

A:
```java
// WRONG: re-compiling pattern every call
boolean isValid(String email) {
    return email.matches("[^@]+@[^@]+"); // compiles pattern EVERY call!
}

// CORRECT: static final Pattern (compile once)
private static final Pattern EMAIL =
    Pattern.compile("^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$");

boolean isValid(String email) {
    if (email == null || email.length() > 254) return false;
    return EMAIL.matcher(email).matches(); // reuse Pattern, new Matcher OK
}
// Matcher is NOT thread-safe - create new per call (cheap)
// Pattern IS thread-safe - one static instance is fine

// Extracting groups:
Pattern p = Pattern.compile("(\\d+)\\s+(\\w+)");
Matcher m = p.matcher("42 items found");
if (m.find()) {
    String count = m.group(1); // "42"
    String unit  = m.group(2); // "items"
}

// Find all matches:
Pattern WORD = Pattern.compile("\\b\\w+\\b");
Matcher wm = WORD.matcher("Hello World Java");
while (wm.find()) {
    System.out.println(wm.group() + " at " + wm.start());
}

// Replace with function (Java 9):
String result = Pattern.compile("\\d+")
    .matcher("abc 123 def 456")
    .replaceAll(mr -> String.valueOf(Integer.parseInt(mr.group()) * 2));
// "abc 246 def 912"
```

*What separates good from great:* `Pattern.compile()` is expensive because
it builds a finite automaton from the regex string. In microbenchmarks, it's
100-1000x slower than `Matcher.matches()`. In a web request handler called
1000 times/second, recompiling a regex on every request wastes CPU.
Use `static final Pattern` as the default. The `Matcher.replaceAll(Function)`
in Java 9 enables dynamic replacement without needing to manually loop with
`find()` and `appendReplacement()`/`appendTail()` - cleaner and less error-prone.

---

**Q5 (ReDoS): What is ReDoS and how do you prevent it?**

A: **ReDoS** (Regular Expression Denial of Service): a regex that takes
exponential time on certain inputs, blocking the thread.

Cause: nested quantifiers on ambiguous patterns cause catastrophic
backtracking. The regex engine tries every possible match path.

```java
// Vulnerable patterns (exponential on adversarial input):
// (a+)+b   -> "aaaaaac" = exponential backtracking
// (a|aa)+  -> similar
// (.*a){20} -> exponential on strings with many 'a's

// Attack: send "aaaaaaaaaaaaaaaaaac" (many a's, no b)
// Engine tries every combination -> thread blocked for seconds/minutes

// PREVENTION:
// 1. Bound input length (before regex):
if (input.length() > 1000) throw new IllegalArgumentException("Too long");

// 2. Use possessive quantifiers (Java supports):
Pattern.compile("(a++)++b"); // a++ never gives back what it matched

// 3. Atomic groups (same as possessive):
Pattern.compile("(?>a+)+b");

// 4. Avoid nested quantifiers on ambiguous patterns:
// Instead of (a+)+ use a+ (they match the same but without catastrophic backtracking risk)

// 5. Use a regex linter/validator:
// - ReDoS Checker: https://devina.io/redos-checker
// - vuln-regex-detector: npm package for CI/CD

// Production example: OWASP recommends
// - All user input: length limit + character whitelist
// - Complex validation: explicit parser over regex
// - Use java.util.regex timeout wrapper if needed:
ExecutorService executor = Executors.newSingleThreadExecutor();
Future<Boolean> future = executor.submit(
    () -> UNSAFE_PATTERN.matcher(userInput).matches());
try {
    return future.get(100, TimeUnit.MILLISECONDS); // timeout!
} catch (TimeoutException e) {
    future.cancel(true);
    throw new ValidationException("Input validation timeout");
}
```

*What separates good from great:* ReDoS is a real attack vector. In 2016,
a regex in the Node.js `moment` library caused a severe ReDoS vulnerability.
In 2019, Cloudflare had an outage partly caused by a catastrophic backtracking
regex in their WAF. Java's `java.util.regex` has NO built-in timeout.
At scale, a single malicious request can cause a thread to hang for minutes.
The timeout wrapper pattern (ExecutorService + Future.get with timeout) is
the only safe mitigation for user-provided content validated by complex regex.
For greenfield code: prefer explicit parsers (parser combinators, Antlr) for
complex grammar validation.

---

**Q6 (String.format performance): When is String.format appropriate?**

A: `String.format()` parses the format string on every call and uses
varargs (boxing primitives). For high-frequency logging or string building:
prefer concatenation or StringBuilder.

```java
// Benchmark: 1 million iterations
// String.format: ~800ms
// StringBuilder.append: ~15ms
// String concat (JIT-optimized): ~20ms

// LOW FREQUENCY: String.format is fine (human-readable, error-resistant)
String errorMsg = String.format(
    "User %s (id=%d) failed login at %s from %s",
    username, userId, timestamp, ipAddress);
// Great for error messages - rare, readability matters

// HIGH FREQUENCY: avoid String.format in hot paths
// BAD: logging in tight loop
for (Item item : millionItems) {
    log.debug(String.format("Processing item %d: %s", item.id(), item.name()));
}

// GOOD: use SLF4J's lazy formatting (evaluates only if debug enabled!)
for (Item item : millionItems) {
    log.debug("Processing item {}: {}", item.id(), item.name());
    // SLF4J: if DEBUG disabled, no String created at all!
}

// Text blocks (Java 15): excellent for multi-line strings
String json = """
    {
      "name": "%s",
      "age": %d
    }
    """.formatted(name, age); // .formatted() on text blocks (Java 15)
```

*What separates good from great:* The SLF4J pattern (`log.debug("x {}", y)`)
is far more important than `String.format` for performance. If debug logging
is disabled (production default), SLF4J never evaluates the format string
or calls `toString()` on the arguments. With `String.format("x %s", obj)`:
`obj.toString()` is always called (even when logging is disabled), then the
format string is parsed, then the result is created - all wasted. This is
why SLF4J's parameterized logging is a performance best practice, not just
style.

---

**Q7 (Text blocks): How do text blocks work in Java 15+?**

A: Text blocks are multi-line string literals that strip common leading
whitespace and use `\n` as line terminator:

```java
// Before: escaping nightmare
String json = "{\n    \"name\": \"Alice\",\n    \"age\": 30\n}";

// After: text block (Java 15, standard)
String json = """
    {
        "name": "Alice",
        "age": 30
    }
    """;
// Incidental whitespace stripped based on closing """ position

// Position of closing """ determines stripping:
String a = """
    Hello
    World
    """; // trailing newline included; strips 4 spaces
String b = """
    Hello
    World
    """.stripIndent(); // explicit stripping

// Escape sequences in text blocks:
String s = """
    Line 1\
    Line 2
    """;
// \<newline> = line continuation: "Line 1Line 2\n"

// \s (trailing whitespace anchor):
String s = """
    column1   \s
    column2   \s
    """;
// \s prevents stripping of intentional trailing spaces

// Formatted:
String sql = """
    SELECT *
    FROM users
    WHERE id = %d
    """.formatted(userId);
```

*What separates good from great:* Text blocks improve correctness, not
just readability. The stripping algorithm is deterministic: indentation
common to ALL content lines (and the closing `"""`) is stripped. This means
the indented text block inside a method body doesn't produce leading spaces
in the output. `\s` at line end is the escape to preserve intentional
trailing whitespace - useful for fixed-width data, CSV generation, protocol
messages where trailing spaces are significant.

---

**Q8 (Locale-sensitive): When does Locale matter for string operations?**

A:
```java
// BAD: locale-sensitive comparison in code logic
String country = userInput.toLowerCase();
if (country.equals("turkey")) { // wrong!
// "Turkey".toLowerCase() in Turkish locale = "turkey" but
// "I".toLowerCase(Locale.of("tr","TR")) = "ı" (dotless i)
// "I".toLowerCase() may return "i" or "ı" depending on default Locale!

// GOOD: locale-independent for programmatic comparisons
String country = userInput.toLowerCase(Locale.ROOT);
// Locale.ROOT: no locale-specific mappings, A-Z only

// GOOD: locale-specific for user display
String userDisplay = name.toUpperCase(Locale.forLanguageTag("tr-TR"));

// Locale.ROOT vs Locale.ENGLISH:
// Locale.ROOT: stable, no locale rules (use for code-facing operations)
// Locale.ENGLISH: English locale rules (may differ on some edge chars)

// String comparison ignoring case:
// BAD: "Turkey".equalsIgnoreCase("turkey") - may fail with Turkish locale
// GOOD:
boolean match = s1.toLowerCase(Locale.ROOT)
    .equals(s2.toLowerCase(Locale.ROOT));
// Or: Collator for full locale-aware comparison
Collator collator = Collator.getInstance(Locale.GERMAN);
collator.setStrength(Collator.PRIMARY); // ignore case and accents
int cmp = collator.compare("straße", "STRASSE"); // 0 (same in German)
```

*What separates good from great:* Locale bugs are among the hardest to
reproduce - they only manifest on machines with non-English system locales.
The famous Turkish test: set JVM locale to Turkish (`java -Duser.language=tr`),
then `"FILE".toLowerCase().equals("file")` returns `false` because "I"
lowercases to "ı" (dotless i). This breaks string comparisons in HTTP
header parsing, configuration key comparisons, and enum name lookups.
Production rule: every `toLowerCase()` / `toUpperCase()` in production code
needs an explicit Locale. `Locale.ROOT` for internal identifiers.
User's locale for display.

---

**Q9 (String comparison): How do you correctly compare strings?**

A:
```java
// == compares references, not content:
String a = new String("hello");
String b = new String("hello");
a == b      // false (different objects)
a.equals(b) // true  (same content)

// Case-insensitive content comparison:
// BAD: locale-sensitive
a.equalsIgnoreCase(b);
// BETTER: explicit locale
a.toLowerCase(Locale.ROOT).equals(b.toLowerCase(Locale.ROOT));

// Null-safe comparison (Java 7+):
Objects.equals(a, b); // returns false if either is null, not NPE

// Comparing with a known constant (yoda style to avoid NPE):
"expected".equals(userInput); // NPE-safe (left side is non-null)
// vs: userInput.equals("expected") -> NPE if userInput is null

// Ordering strings (for sorting):
List<String> names = List.of("charlie", "Alice", "bob");
// Case-insensitive sort:
names.stream()
    .sorted(String.CASE_INSENSITIVE_ORDER)
    .forEach(System.out::println); // Alice, bob, charlie

// Locale-aware sort (for user display):
Collator de = Collator.getInstance(Locale.GERMAN);
names.sort(de); // handles German umlauts correctly
```

*What separates good from great:* `Objects.equals(a, b)` is the standard
null-safe equality check. In Spring/JPA code, null checks before
`.equals()` are boilerplate: `a != null && a.equals(b)` - replaced by
`Objects.equals(a, b)`. For sorting user-visible data: always use
`Collator` with the user's locale, not natural String ordering (which is
Unicode codepoint order, not alphabetical in any language). "ü" sorts
after "z" in Unicode order but between "u" and "v" in German locale.

---

### ⚖️ Comparison Table

| Tool | Thread Safe | Use Case | Performance |
|---|---|---|---|
| String concat (`+`) | Yes (immutable) | 1-2 concatenations | Fine |
| StringBuilder | No | Loop building, single thread | Fastest |
| StringBuffer | Yes | Shared mutable string | Slower (sync) |
| String.join | Yes | Static list join | Good |
| Collectors.joining | Yes | Stream collection | Good |
| String.format | Yes | Complex formatting | Slow |
| Text block | Yes | Multi-line literals | Same as String |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept)*

---

---

## Java Annotations

### 🎯 Model Answer

**30 seconds:**
> Annotations are metadata markers on code elements (classes, methods,
> fields, parameters, packages). Built-in: `@Override`, `@Deprecated`,
> `@SuppressWarnings`, `@FunctionalInterface`. Custom annotations:
> `@interface MyAnnotation { String value() default ""; }`. Retention:
> `SOURCE` (discarded at compile), `CLASS` (in bytecode, not loaded),
> `RUNTIME` (available via reflection). Most framework annotations
> (`@Autowired`, `@Entity`, `@Test`) are RUNTIME retention. Annotation
> processors run at compile time (Lombok, MapStruct).

**3 minutes (Senior):**
> `@Retention(RUNTIME)` enables runtime processing via reflection:
> `method.getAnnotation(Transactional.class)`. `@Target` restricts where
> an annotation can be used (`ElementType.METHOD`, `FIELD`, `TYPE`, etc.).
> `@Repeatable` (Java 8) allows the same annotation multiple times on one element.
>
> Two processing models: (1) annotation processors (APT, JSR 269) run at
> compile time via `javac` - produce new source files or validate. Lombok,
> MapStruct, Dagger use this. (2) Runtime reflection - Spring, Hibernate,
> JUnit read `RUNTIME` retention annotations after class loading.
>
> Performance: reflection-based annotation reading has overhead; frameworks
> cache the results after first scan. Spring scans class annotations once
> at startup, caches to `BeanDefinition`. Hibernate scans entity annotations
> once per `SessionFactory` creation. Avoid reading annotations in hot paths
> without caching.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Annotations - let me cover definition, meta-annotations,
retention policies, custom annotations, compile-time processors vs runtime
reflection."

**(2) First principles:** "Annotations add metadata without changing code
behavior. The metadata needs a consumer: either the compiler, an APT
processor at compile time, or reflection at runtime."

**(3) Bridge:** "Annotations are like sticky notes on code. `SOURCE`
annotations are notes the compiler reads then throws away. `CLASS` annotations
are permanent notes in the file but no one reads them at runtime. `RUNTIME`
annotations are notes anyone can read while the program runs."

---

### 📘 Concept Explanation

**Meta-annotations (annotations on annotations):**
```java
@Retention(RetentionPolicy.RUNTIME)  // when available
@Target({ElementType.METHOD, ElementType.TYPE}) // where usable
@Documented                          // include in Javadoc
@Inherited                           // subclasses inherit from superclass
@Repeatable(MyAnnotations.class)     // can be used multiple times
public @interface MyAnnotation {
    String value() default "";       // element named "value" (special!)
    int timeout() default 30;
    Class<?>[] targets() default {};
}
```

**Defining and using custom annotations:**
```java
// Define:
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface Validate {
    int minLength() default 0;
    int maxLength() default Integer.MAX_VALUE;
    String pattern() default ".*";
    String message() default "Validation failed";
}

// Use:
class User {
    @Validate(minLength=2, maxLength=50, message="Name must be 2-50 chars")
    private String name;

    @Validate(pattern="[^@]+@[^@]+\\.[^@]+", message="Invalid email")
    private String email;
}

// Process at runtime via reflection:
void validate(Object obj) throws ValidationException {
    for (Field field : obj.getClass().getDeclaredFields()) {
        Validate v = field.getAnnotation(Validate.class);
        if (v == null) continue;
        field.setAccessible(true);
        String value = (String) field.get(obj);
        if (value == null || value.length() < v.minLength()) {
            throw new ValidationException(
                field.getName() + ": " + v.message());
        }
    }
}
```

---

### 💻 Code Example

> **Code walkthrough:** The custom `@RateLimit` annotation with AOP processing
> shows the standard framework pattern: define the annotation (metadata),
> implement the processor (behavior), wire them together (AOP / annotation
> processor). The annotation carries the configuration (max calls, period);
> the processor implements the logic. This separates concern: calling code
> expresses intent (`@RateLimit(max=100)`), infrastructure implements it.

```java
// Custom annotation for rate limiting:
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface RateLimit {
    int maxCalls() default 100;
    int perSeconds() default 60;
    String message() default "Rate limit exceeded";
}

// Usage:
@Service
class PaymentService {
    @RateLimit(maxCalls=10, perSeconds=60, message="Too many payment attempts")
    public Receipt processPayment(PaymentRequest request) { ... }

    @RateLimit(maxCalls=1000, perSeconds=60)
    public PaymentStatus getStatus(String id) { ... }
}

// AOP processor (Spring):
@Aspect
@Component
class RateLimitAspect {
    private final Map<String, RateLimiter> limiters = new ConcurrentHashMap<>();

    @Around("@annotation(rateLimit)")
    public Object enforceLimitAspect(ProceedingJoinPoint pjp,
                                      RateLimit rateLimit) throws Throwable {
        String key = pjp.getSignature().toLongString();
        RateLimiter limiter = limiters.computeIfAbsent(key, k ->
            RateLimiter.create(
                (double) rateLimit.maxCalls() / rateLimit.perSeconds()));

        if (!limiter.tryAcquire()) {
            throw new TooManyRequestsException(rateLimit.message());
        }
        return pjp.proceed();
    }
}

// Compile-time annotation processor (validates at compile time):
@SupportedAnnotationTypes("com.example.RateLimit")
@SupportedSourceVersion(SourceVersion.RELEASE_17)
public class RateLimitProcessor extends AbstractProcessor {
    @Override
    public boolean process(Set<? extends TypeElement> annotations,
                           RoundEnvironment roundEnv) {
        for (Element element : roundEnv.getElementsAnnotatedWith(
                RateLimit.class)) {
            RateLimit rl = element.getAnnotation(RateLimit.class);
            if (rl.maxCalls() <= 0) {
                processingEnv.getMessager().printMessage(
                    Diagnostic.Kind.ERROR,
                    "maxCalls must be > 0", element);
            }
        }
        return true;
    }
}
```

> **Code walkthrough:** The AOP aspect uses `@annotation(rateLimit)` to
> intercept any method annotated with `@RateLimit` and inject the annotation
> instance as a parameter (`rateLimit`). The `computeIfAbsent` on
> `ConcurrentHashMap` creates a separate `RateLimiter` (Guava) per method
> signature. The compile-time processor (`AbstractProcessor`) runs during
> `javac` - it catches invalid annotation values before runtime. Most
> framework validation (Bean Validation, Lombok) uses this approach: compile
> errors instead of runtime surprises.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `@Retention(RUNTIME)` is required for annotations read via reflection.
> `@Target` restricts where the annotation can appear. Custom annotations:
> `@interface MyAnnotation { String value(); }`. The `value()` element is
> special: `@MyAnnotation("x")` is shorthand for `@MyAnnotation(value="x")`.
> Annotations don't do anything by themselves - they need a processor
> (framework, APT, or your own reflection code) to act on them.

---

**Senior / Staff (5+ years):**
> Annotation processors vs runtime reflection is an architectural choice.
> APT (compile-time): zero runtime cost, strong validation at compile time,
> produces new source files (Lombok, MapStruct, Dagger). Runtime reflection
> (Spring, Hibernate): flexible, can respond to dynamic state, but has
> startup cost and requires JVM module access (Java 9+ `--add-opens`).
> Java 9+ platform modules restrict reflective access; frameworks like Spring
> need `--add-opens java.base/java.lang` or native proxy-based injection.
> In Java 17+ with sealed classes: many patterns using reflection can be
> replaced with type-safe alternatives.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Annotations add runtime behavior themselves."**
Annotations are pure metadata. `@Transactional` doesn't make a method
transactional - Spring's `TransactionInterceptor` reads the annotation
and wraps the method in a transaction. Remove Spring context: `@Transactional`
does nothing. The annotation is a marker; the framework provides behavior.

**Misconception 2: "`@Inherited` works for interfaces and methods."**
`@Inherited` only applies to class-level annotations (meta-annotation
`@Target(TYPE)`), and only for class inheritance (not interface implementation).
`@Inherited` on a superclass annotation IS inherited by subclasses.
But: if an interface is annotated, the implementing class does NOT inherit
that annotation. Spring's `@Transactional` on an interface is a common
mistake - Spring (proxy-based) may not pick it up depending on proxy type.

---

### 🚨 Failure Modes and Diagnosis

**Failure: annotation not picked up by framework.**
```java
// Example: @Transactional on interface not working
interface UserService {
    @Transactional // WRONG: Spring CGLIB proxy doesn't inherit interface annotations
    User save(User user);
}
// Diagnosis: transactions not started, no exception but data not committed

// Fix: put @Transactional on the implementing class method:
@Service
class UserServiceImpl implements UserService {
    @Transactional // CORRECT: Spring reads from concrete class
    public User save(User user) { return repo.save(user); }
}

// OR: use AspectJ weaving instead of CGLIB proxy (full bytecode instrumentation)
// @EnableTransactionManagement(mode = AdviceMode.ASPECTJ)
```
Diagnosis: enable debug logging for `org.springframework.transaction`.
Check `TransactionSynchronizationManager.isActualTransactionActive()` in
the method body.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Annotation processing models | 2 minutes |
| Retention policies | 90 seconds |
| Custom annotation creation | 2 minutes |
| @Repeatable | 90 seconds |
| APT vs runtime reflection | 2-3 minutes |
| Framework annotation pitfalls | 2 minutes |
| Annotation inheritance | 2 minutes |
| Bean Validation annotations | 2 minutes |
| Security risks | 2 minutes |

---

**Q1 (Processing models): What are the two models for processing annotations?**

A: **1. Compile-time Annotation Processing (APT, JSR 269):**
Runs during `javac` compilation. `AbstractProcessor` subclass registered
in `META-INF/services/javax.annotation.processing.Processor`. Can generate
new source files, emit compile errors/warnings, cannot modify existing source.
Examples: Lombok (modifies AST via compiler internals), MapStruct
(generates mapper implementations), Dagger (generates DI code).

**2. Runtime Reflection:**
Reads `RUNTIME` retention annotations after class loading via
`Class.getAnnotation()`, `Method.getAnnotation()`, etc. Flexible but
has overhead. AOP frameworks (Spring AOP, AspectJ) build proxy objects
that intercept method calls and read annotations. JPA providers (Hibernate)
scan entity classes at `SessionFactory` creation.

```java
// Reading annotation at runtime:
Method m = SomeClass.class.getMethod("myMethod");
RateLimit rl = m.getAnnotation(RateLimit.class);
if (rl != null) {
    System.out.println("Max calls: " + rl.maxCalls());
}

// Scanning all fields for annotation:
Field[] fields = clazz.getDeclaredFields();
for (Field f : fields) {
    if (f.isAnnotationPresent(Validate.class)) {
        // process field
    }
}

// Annotation processor skeleton (APT):
@AutoService(Processor.class) // Guava AutoService: auto-registers
@SupportedAnnotationTypes("com.example.Validate")
class ValidateProcessor extends AbstractProcessor { ... }
```

*What separates good from great:* The choice between APT and runtime
reflection is primarily a "when do you want the cost?" question.
APT: cost at build time (slower builds), zero runtime overhead.
Runtime reflection: fast builds, startup cost (Spring context startup
can be seconds), per-call overhead (usually cached). For serverless
(AWS Lambda, Azure Functions): startup time matters - compile-time
injection (Quarkus, Micronaut with APT) beats Spring's runtime reflection
by 10x on cold start. This is why Quarkus uses Jandex (bytecode index)
and APT-style processing to eliminate Spring-style runtime scanning.

---

**Q2 (Retention policies): Explain the three retention policies.**

A:
- `SOURCE`: annotation present in source only, discarded by compiler.
  Use: IDE hints, documentation (`@Override` validates at compile, then gone).
- `CLASS` (default): stored in bytecode (.class file) but NOT loaded into JVM at runtime. Use: bytecode tooling (ASM, Byte Buddy can read them without loading class).
- `RUNTIME`: loaded into JVM, accessible via reflection. Use: ALL framework annotations (`@Autowired`, `@Transactional`, `@Entity`, `@Test`).

```java
@Retention(RetentionPolicy.SOURCE)  // compile-time only
public @interface Todo { String value(); } // reminder for developers

@Retention(RetentionPolicy.CLASS)   // default (rarely needed explicitly)
public @interface BytecodeMarker { String value(); }

@Retention(RetentionPolicy.RUNTIME) // most framework annotations
public @interface Cacheable {
    String region() default "default";
    int ttlSeconds() default 3600;
}
// Spring can call:
// method.getAnnotation(Cacheable.class).ttlSeconds()
```

*What separates good from great:* `CLASS` retention is the rare middle
ground: useful for bytecode instrumentation tools that process .class
files without loading them (javap, ASM, ProGuard, R8). These tools read
the bytecode file directly, not through JVM class loading. ProGuard uses
CLASS retention annotations to identify methods to preserve. If you're
writing a bytecode agent that processes .class files at build time (not
runtime), CLASS retention adds metadata without JVM overhead.

---

**Q3 (Custom annotation): How do you create and use a custom annotation?**

A:
```java
// Step 1: Define the annotation
@Retention(RetentionPolicy.RUNTIME) // required for runtime processing
@Target({ElementType.METHOD, ElementType.TYPE})
@Documented                         // optional: appear in Javadoc
public @interface Audit {
    // Elements (like methods in an interface, but annotation elements):
    String action() default "";         // optional (has default)
    AuditLevel level() default AuditLevel.INFO; // enum element
    boolean logParams() default false;  // boolean element
    Class<?>[] excludeTypes() default {}; // array element

    // No "value()" -> must always use named elements
    // @Audit(action="CREATE", level=AuditLevel.WARN)
}
// If only one element named "value()": @Audit("CREATE") works

// Step 2: Use the annotation
@Service
class OrderService {
    @Audit(action="CREATE_ORDER", logParams=true)
    public Order createOrder(OrderRequest request) { ... }

    @Audit(action="CANCEL_ORDER", level=AuditLevel.WARN)
    public void cancelOrder(Long orderId) { ... }
}

// Step 3: Process the annotation (AOP + Spring)
@Aspect
@Component
class AuditAspect {
    @Around("@annotation(audit)")
    public Object log(ProceedingJoinPoint pjp, Audit audit)
            throws Throwable {
        log.info("AUDIT: action={} level={}", audit.action(), audit.level());
        if (audit.logParams()) {
            log.info("PARAMS: {}", Arrays.toString(pjp.getArgs()));
        }
        try {
            Object result = pjp.proceed();
            log.info("AUDIT: action={} SUCCESS", audit.action());
            return result;
        } catch (Exception e) {
            log.warn("AUDIT: action={} FAILED: {}", audit.action(), e.getMessage());
            throw e;
        }
    }
}
```

*What separates good from great:* Custom annotations work best when they
express business intent cleanly. `@Audit(action="CREATE_ORDER")` is more
readable than manually injecting an AuditLogger into every method.
The annotation becomes the "what", the AOP aspect the "how". This separation
lets you: change the audit implementation (log to DB, to Kafka, to external
system) without touching any service code. Add auditing to new methods
with one annotation. Remove auditing from methods by removing the annotation.
Test audit behavior independently of business logic.

---

**Q4 (@Repeatable): How does @Repeatable work?**

A: `@Repeatable` (Java 8) allows the same annotation to appear multiple
times on the same element. Requires a "container annotation":

```java
// Container annotation (holds array of the repeatable annotation):
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Schedules {
    Schedule[] value(); // must have value() returning array of Schedule
}

// Repeatable annotation:
@Repeatable(Schedules.class) // points to container
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Schedule {
    String cron();
    String timezone() default "UTC";
}

// Usage: multiple @Schedule on same method
@Schedule(cron = "0 0 9 * * MON-FRI")            // 9am weekdays
@Schedule(cron = "0 0 12 * * SAT", timezone="EST") // noon Saturday EST
public void sendReport() { ... }

// Reading: must use getAnnotationsByType (not getAnnotation) for repeatables:
Schedule[] schedules = method.getAnnotationsByType(Schedule.class);
for (Schedule s : schedules) {
    System.out.println(s.cron() + " @ " + s.timezone());
}
// getAnnotation(Schedule.class) returns null if multiple applied!
// (It finds Schedules container, not Schedule)

// Or: getAnnotation(Schedules.class) returns the container
Schedules container = method.getAnnotation(Schedules.class);
```

*What separates good from great:* `@Repeatable` solves the "wrapper array
annotation" boilerplate. Before Java 8: `@Schedules({@Schedule("cron1"), @Schedule("cron2")})`.
After: just use `@Schedule` twice. The key trap: reading with `getAnnotation()`
vs `getAnnotationsByType()`. When an element has multiple `@Schedule`,
the compiler wraps them in `@Schedules` container. `getAnnotation(Schedule.class)`
looks for a bare `Schedule` - finds nothing (only the container exists).
`getAnnotationsByType(Schedule.class)` unwraps the container and returns
all `Schedule` instances. Always use `getAnnotationsByType` for `@Repeatable` annotations.

---

**Q5 (APT vs runtime): Trade-offs between APT and runtime reflection for
annotation processing.**

A:

| Aspect | Annotation Processing (APT) | Runtime Reflection |
|---|---|---|
| When | Compile time | Runtime (startup or call time) |
| Cost | Build time | Startup time or per-call |
| Source generation | Yes (Lombok, MapStruct) | No |
| Error detection | Compile errors | Runtime exceptions |
| Framework examples | Lombok, MapStruct, Dagger | Spring, Hibernate, JUnit |
| JVM module access | Not needed | Needs --add-opens in Java 9+ |
| Serverless cold start | Fast (no scanning) | Slow (classpath scanning) |
| Debugging | Hard (generated code) | Easy (step through reflective code) |

```java
// MapStruct (APT): generates implementation at compile time
@Mapper
interface UserMapper {
    UserDTO toDto(User user);
    User toEntity(UserDTO dto);
}
// Compile: generates UserMapperImpl.java
// Runtime: no reflection needed - calls generated code directly

// Spring (runtime): reads annotations at startup
@Service
class UserService {
    @Autowired UserRepository repo; // injected at startup via reflection
}
// Startup: Spring scans classpath, reads @Service, @Autowired, wires beans
// No code generation; flexible but slower to start

// Quarkus (hybrid): processes at compile time, runs AOT
// @Inject fields: resolved at build time, fast startup
// This is why Quarkus starts in 50ms vs Spring's 2000ms+
```

*What separates good from great:* The performance difference matters at
scale. In a microservices architecture with 50 services, Spring's runtime
scanning adds 1-3 seconds to each deployment startup. For Kubernetes with
rolling updates across 10 pods: 50-150 extra seconds of startup across
the fleet. Quarkus/Micronaut's compile-time processing: 100-500ms startup
because there's no classpath scanning or proxy generation. The trade-off:
APT frameworks are less flexible (no dynamic bean registration) but
dramatically faster. Choose based on startup time requirements.

---

**Q6 (Framework annotation pitfalls): Common annotation misuse with frameworks.**

A:
```java
// PITFALL 1: @Transactional on private methods (Spring CGLIB ignored)
@Service
class OrderService {
    public void processOrder(Order order) {
        saveOrderInternal(order); // calls self - bypasses proxy!
    }

    @Transactional // IGNORED: Spring proxy can't intercept self-calls
    private void saveOrderInternal(Order order) {
        repo.save(order);
    }
    // Fix: extract to separate Spring bean, or use AspectJ weaving
}

// PITFALL 2: @Cacheable on method called from within same class
@Service
class ProductService {
    public Product getWithRelations(Long id) {
        Product p = findById(id); // bypasses @Cacheable proxy!
        // ...
    }

    @Cacheable("products")
    public Product findById(Long id) { return repo.findById(id); }
    // Fix: inject self: @Autowired ProductService self; self.findById(id);
    // Or: AopContext.currentProxy() (requires exposeProxy=true)
}

// PITFALL 3: @Async on same class method call (same proxy issue)
// All three pitfalls share the same root cause: Spring's CGLIB/JDK proxy
// wraps the bean; direct calls within the class bypass the proxy

// PITFALL 4: Bean Validation on service layer (controller validation not propagated)
@Service
class UserService {
    public void createUser(@Valid UserDTO dto) { // @Valid has no effect without a trigger!
        // @Valid requires a Spring method validation interceptor
    }
    // Fix: @Validated on class + @Valid on params
    // OR: validate in controller (auto-applied with @RequestBody @Valid)
}

@Service
@Validated // enables method-level validation in Spring
class UserService {
    public void createUser(@Valid UserDTO dto) { // NOW it works
```

*What separates good from great:* The "same-class method call bypasses AOP
proxy" is one of the most common Spring bugs. It's invisible in unit tests
(no proxy) and only manifests in integration tests. The spring documentation
mentions it, but developers often miss it. Production symptoms: transactions
not committed, caches not populated, methods not running async. The root
cause is always the same: calling `this.method()` goes directly to the
target object, not through the proxy wrapper. Solutions: (1) separate
bean, (2) self-injection, (3) AspectJ full weaving (works for all cases
including `final` methods and `private` methods).

---

**Q7 (Annotation inheritance): How does annotation inheritance work in Java?**

A:
- `@Inherited` on an annotation meta-type: class-level annotations on a
  superclass are inherited by subclasses.
- Interface annotations: NOT inherited by implementing classes (even with `@Inherited`).
- Method annotations: NOT inherited when overriding.

```java
@Inherited
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@interface CategoryMarker { String value(); }

@CategoryMarker("service")
class BaseService {}

class UserService extends BaseService {}
// UserService.class.getAnnotation(CategoryMarker.class) != null (inherited!)

// But interfaces:
@CategoryMarker("api")
interface UserApi {}

class UserApiImpl implements UserApi {}
// UserApiImpl.class.getAnnotation(CategoryMarker.class) == null
// Interface annotations NOT inherited even with @Inherited!

// Method annotations: NOT inherited
class Base {
    @Transactional
    public void save() {}
}
class Child extends Base {
    @Override
    public void save() {} // @Transactional NOT present here!
    // Spring will NOT apply transaction to Child.save() calls!
    // Fix: re-annotate in Child, or put @Transactional on Child class
}
```

*What separates good from great:* Spring has a meta-annotation search
(`AnnotationUtils.findAnnotation()`) that walks the class and interface
hierarchy looking for annotations. `method.getAnnotation()` only checks
the specific method. `AnnotationUtils.findAnnotation(method, Transactional.class)`
checks the method, then superclass methods, then interfaces. This is why
Spring's `@Transactional` on an interface SOMETIMES works with JDK proxy
(which creates a proxy for the interface): Spring finds the annotation
via interface hierarchy search. But with CGLIB proxy (subclass-based),
interface annotations are not visible to the proxy lookup. Knowing this
distinction separates engineers who debug Spring transaction issues from
those who cargo-cult annotations.

---

**Q8 (Bean Validation): How do Bean Validation annotations work?**

A: Bean Validation (JSR 380, Hibernate Validator) provides annotations for
field-level constraints. Spring MVC automatically triggers validation when
`@Valid` or `@Validated` is on a controller method parameter.

```java
// Constraint annotations:
class UserRegistrationRequest {
    @NotNull @Size(min=2, max=50)
    private String name;

    @NotBlank @Email
    private String email;

    @NotNull @Size(min=8, max=100)
    @Pattern(regexp="(?=.*\\d)(?=.*[a-z])(?=.*[A-Z]).+",
             message="Must contain uppercase, lowercase, digit")
    private String password;

    @Min(18) @Max(120)
    private Integer age;

    @Past // date in the past
    private LocalDate birthDate;
}

// In controller: triggers validation, 400 on failure
@PostMapping("/users")
ResponseEntity<UserDTO> register(@Valid @RequestBody UserRegistrationRequest req) { ... }

// Custom validator:
@Constraint(validatedBy = UniqueEmailValidator.class)
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface UniqueEmail {
    String message() default "Email already registered";
    Class<?>[] groups() default {};  // required by Bean Validation spec
    Class<? extends Payload>[] payload() default {}; // required
}

class UniqueEmailValidator implements ConstraintValidator<UniqueEmail, String> {
    @Autowired UserRepository repo; // Spring injects it!
    @Override
    public boolean isValid(String email, ConstraintValidatorContext ctx) {
        return email == null || !repo.existsByEmail(email);
    }
}
```

*What separates good from great:* Custom `ConstraintValidator` beans can be
Spring-managed (injection works!). This enables database-backed validation
(`@UniqueEmail` checking the DB) in the validation layer. The `groups()`
attribute enables validation groups: different validation rules for create
vs update (`@NotNull(groups=Create.class)`). `@Valid` triggers recursive
validation of nested objects; `@Validated` (Spring) enables group selection.
Validation failure throws `MethodArgumentNotValidException` in controllers
(auto-handled by Spring's default exception handler: 400 with field errors).

---

**Q9 (Security risks): What are the security risks of annotation-based
runtime reflection?**

A:
1. **Annotation data injection:** annotation values (strings) come from
   code, but custom annotation processors may pass them to SQL/OS commands.
   ```java
   @Table(name = userInput) // annotation values are compile-time constants
   // Actually safe: annotation values must be compile-time constants
   // Real risk: annotation processor that reads other config files
   ```

2. **Reflection bypass of access controls:** `field.setAccessible(true)` bypasses `private`.
   ```java
   // Malicious code (if allowed to run):
   Field secretField = Config.class.getDeclaredField("apiKey");
   secretField.setAccessible(true); // bypasses private!
   String apiKey = (String) secretField.get(config);
   // Java 9 module system prevents this for JDK classes without --add-opens
   ```

3. **Deserialization of annotated types (Jackson):**
   ```java
   // @JsonTypeInfo allows polymorphic deserialization
   // Without @JsonTypeInfo restrictions: arbitrary class instantiation!
   // CVE-2017-7525: Jackson deserializing malicious JSON could execute code
   // Fix: use @JsonTypeInfo with @JsonSubTypes (whitelist approach)
   // Or: disable default typing (objectMapper.disableDefaultTyping())
   ```

4. **Spring SpEL injection in annotation values:**
   ```java
   // @PreAuthorize, @Value can execute SpEL expressions
   // If user input reaches SpEL expression: Remote Code Execution!
   @PreAuthorize("hasRole('" + userInput + "')") // NEVER do this!
   // SpEL evaluates: #{T(java.lang.Runtime).getRuntime().exec('...')}
   ```

*What separates good from great:* The Jackson polymorphic deserialization
vulnerability (CVE-2017-7525 and related CVEs) was among the most severe
Java security issues in 2017-2019. The root cause: `@JsonTypeInfo` with
`Id.CLASS` allows the JSON input to specify which Java class to instantiate.
An attacker sends a JSON with a "gadget class" (JNDI lookup, Spring EL
evaluation) as the type. Mitigation: use `@JsonSubTypes` whitelist,
or `MapperFeature.ALLOW_COERCION_OF_SCALARS`, or Jackson's default typing
allowlist. Any annotation that executes code or creates objects from
runtime input is a security boundary.

---

### ⚖️ Comparison Table

| Annotation Processing Model | Timing | Error Detection | Flexibility | Examples |
|---|---|---|---|---|
| APT (JSR 269) | Compile time | Compile errors | Low (static) | Lombok, MapStruct |
| Runtime reflection | JVM startup | Runtime exceptions | High (dynamic) | Spring, Hibernate |
| Bytecode instrumentation | Load time | Runtime | Medium | AspectJ, Byte Buddy |
| Hybrid (AOT) | Build + run | Both | Medium | Quarkus, Micronaut |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept)*
