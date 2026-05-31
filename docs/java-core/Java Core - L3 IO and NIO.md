---
layout: default
title: "Java Core - L3 IO and NIO"
parent: "Java Core"
grand_parent: "SK Interview"
nav_order: 9
permalink: /java-core/l3-io-and-nio/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Core - L3 IO and NIO](#java-core---l3-io-and-nio) | medium |

---

# Java Core - L3 IO and NIO

## Java IO Streams

---

### 🎯 Model Answer

**30 seconds:**
> Java IO (`java.io`) provides stream-based I/O: byte streams
> (`InputStream`/`OutputStream`) and character streams (`Reader`/`Writer`).
> Streams are unidirectional and sequential. The decorator pattern layers
> functionality: `new BufferedReader(new FileReader(path))` adds buffering
> to unbuffered file reading. Character streams handle encoding conversion
> (between bytes and characters). Always close streams in `finally` or
> via `try-with-resources` to release file handles.

**3 minutes (Senior):**
> The IO class hierarchy is large but follows the decorator pattern:
> base classes (`FileInputStream`, `FileReader`) + decorator wrappers
> (`BufferedInputStream`, `DataInputStream`, `ObjectInputStream`).
> `BufferedInputStream` reads 8KB at a time from disk instead of one
> byte; dramatically improves performance.
>
> Character streams vs byte streams: `FileReader` reads characters using
> the platform's default encoding - a trap on systems with non-UTF-8
> defaults. Always specify encoding explicitly:
> `new InputStreamReader(fis, StandardCharsets.UTF_8)`.
>
> `ObjectInputStream`/`ObjectOutputStream` provide Java serialization.
> Deserializing untrusted data is a critical security vulnerability -
> arbitrary code execution via gadget chains. Never deserialize data
> from untrusted sources without validation. Use `ObjectInputFilter` (Java 9+)
> to restrict deserializable classes.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Java IO streams - let me cover the byte/character
stream hierarchy, the decorator pattern for layering, encoding pitfalls,
buffering importance, and try-with-resources."

**(2) First principles:** "From first principles: file data is bytes.
Reading one byte at a time from disk is slow (each system call has
overhead). Buffering batches reads into larger chunks. Character streams
abstract the byte-to-character conversion, letting you work with text
regardless of the underlying encoding."

**(3) Bridge:** "IO streams are like postal mail: you send and receive
one letter at a time (unbuffered) or batch them into packages (buffered).
Character streams are like translated mail - the bytes are letters in
foreign language; the character stream translates them for you."

---

### 📘 Concept Explanation

**Stream hierarchy overview:**
```
Byte Streams:
  InputStream  <-- abstract
    FileInputStream   - read from file
    ByteArrayInputStream - read from byte[]
    PipedInputStream  - read from pipe
  FilterInputStream  <-- decorator base
    BufferedInputStream  - buffering
    DataInputStream      - read primitives
    ObjectInputStream    - deserialize objects

  OutputStream <-- abstract
    FileOutputStream
    ByteArrayOutputStream
    PipedOutputStream
  FilterOutputStream
    BufferedOutputStream
    DataOutputStream
    ObjectOutputStream
    PrintStream  - System.out is a PrintStream

Character Streams:
  Reader  <-- abstract
    InputStreamReader  - bytes -> chars (with encoding)
      FileReader       - opens file, platform encoding (AVOID)
    StringReader
    BufferedReader     - buffering + readLine()
    
  Writer  <-- abstract
    OutputStreamWriter - chars -> bytes (with encoding)
      FileWriter       - opens file, platform encoding (AVOID)
    PrintWriter        - println() for text
    BufferedWriter
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Decorator pattern in IO:**
```java
// Building a buffered, charset-specific file reader:
InputStream raw = new FileInputStream(path);
InputStreamReader decoded = new InputStreamReader(raw, UTF_8);
BufferedReader buffered = new BufferedReader(decoded, 8192);
// OR in one line:
BufferedReader br = new BufferedReader(
    new InputStreamReader(new FileInputStream(path), UTF_8));

// Decorate with multiple layers:
DataOutputStream out = new DataOutputStream(
    new BufferedOutputStream(new FileOutputStream(path)));
out.writeInt(42);    // DataOutputStream: write primitive
out.writeUTF("hi"); // write String with length prefix
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The file reading example shows three approaches:
> pre-Java 7 (explicit close in finally), Java 7+ (try-with-resources),
> and NIO Files API (modern). The encoding pitfall shows why `FileReader`
> is dangerous and `InputStreamReader` with explicit charset is required.
> The binary read/write example demonstrates `DataInputStream`/`DataOutputStream`
> for typed binary protocols.

```java
// BAD: pre-try-with-resources (resource leak if exception):
BufferedReader br = null;
try {
    br = new BufferedReader(new FileReader("file.txt")); // platform encoding!
    String line;
    while ((line = br.readLine()) != null) {
        process(line);
    }
} finally {
    if (br != null) br.close(); // doesn't compile: close() throws IOException
    // Actually: close() propagates IOException, hiding original exception!
}

// GOOD: try-with-resources (Java 7+)
// Closes all declared resources in reverse order, even if exceptions:
try (BufferedReader br = new BufferedReader(
        new InputStreamReader(
            new FileInputStream("file.txt"), StandardCharsets.UTF_8))) {
    String line;
    while ((line = br.readLine()) != null) {
        process(line);
    }
} // auto-closes; if readLine() throws AND close() throws: primary exception
  // propagates, close() exception added as suppressed

// BETTER: use NIO Files API (fewer layers, handles encoding):
List<String> lines = Files.readAllLines(Path.of("file.txt"), UTF_8);
// Or for large files (streaming):
try (Stream<String> stream = Files.lines(Path.of("file.txt"), UTF_8)) {
    stream.filter(line -> !line.isBlank()).forEach(this::process);
}

// Binary data (custom protocol): DataOutputStream/DataInputStream
try (DataOutputStream dos = new DataOutputStream(
        new BufferedOutputStream(new FileOutputStream("data.bin")))) {
    dos.writeInt(42);          // 4 bytes, big-endian
    dos.writeLong(System.currentTimeMillis()); // 8 bytes
    dos.writeUTF("hello");     // 2-byte length prefix + UTF-8 bytes
}

try (DataInputStream dis = new DataInputStream(
        new BufferedInputStream(new FileInputStream("data.bin")))) {
    int n = dis.readInt();
    long ts = dis.readLong();
    String s = dis.readUTF();
}
```

> **Code walkthrough:** `try-with-resources` with multiple resources
> closes them in REVERSE order of declaration (innermost first). This
> means `BufferedReader` is closed before `InputStreamReader`, which
> is closed before `FileInputStream`. If `close()` on one resource throws,
> the exception is suppressed (available via `getSuppressed()`) and the
> next resource is still closed. The original exception from the try block
> always takes precedence over suppressed close exceptions. This is the
> correct behavior: you want to know what caused the failure, not that
> cleanup also failed.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Java IO has byte streams (`InputStream`/`OutputStream`) and character
> streams (`Reader`/`Writer`). Always use `try-with-resources` to avoid
> resource leaks. Specify encoding explicitly (`UTF_8`) - never rely on
> platform default. `BufferedReader`/`BufferedWriter` add buffering for
> performance. `Files.readAllLines()` is the modern shortcut.

---

**Senior / Staff (5+ years):**
> For any serious file processing, use `java.nio.file.Files` API rather
> than IO streams directly. `Files.lines()` returns a lazy stream;
> critical for large files (avoids reading entire file into memory).
> `Files.readAllLines()` is only appropriate for small files that fit
> in memory. Binary protocol work: `DataInputStream`/`DataOutputStream`
> for typed reads/writes. Java serialization: avoid for new systems -
> use JSON/Protocol Buffers/Avro instead. Serialization's security issues
> (CVE-2015-4852, RCE via gadget chains) have made it a security liability.

---

### ⚠️ Common Misconceptions

**Misconception 1: "`FileReader` is the right class for reading text files."**
`FileReader` uses the platform's default encoding. On Windows, this is
usually Windows-1252 or UTF-16; on Linux, usually UTF-8. Code that
works on one platform fails on another. Always use
`new InputStreamReader(new FileInputStream(path), StandardCharsets.UTF_8)`,
or `Files.newBufferedReader(path, UTF_8)`.

**Misconception 2: "Closing the outer stream is sufficient."**
With `try-with-resources`: declare all resources or the outermost stream.
Closing `BufferedReader` calls `close()` on the wrapped stream chain.
But if `new BufferedReader(new InputStreamReader(fis))` throws an
exception in the constructor, `fis` might not be closed if `BufferedReader`
wasn't assigned to the resource variable. Safest: declare each resource
explicitly in `try`.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Java deserialization of untrusted data (CVE-class vulnerability).**
```java
// DANGER: deserializing untrusted data
ObjectInputStream ois = new ObjectInputStream(socketInput);
Object obj = ois.readObject(); // may execute attacker-controlled code!
// Attacker can craft a serialized object using "gadget chains"
// (known classes in the classpath that do dangerous things in their
// readObject methods) to achieve Remote Code Execution (RCE).

// Fix: ObjectInputFilter (Java 9+)
ObjectInputFilter filter = ObjectInputFilter.Config.createFilter(
    "java.base/*;!*"); // allow only java.base classes
ois.setObjectInputFilter(filter);

// Better fix: don't use Java serialization for untrusted input.
// Use JSON (Jackson), Protobuf, or other safe formats.
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Diagnosis: deserialization RCE typically shows up as unexpected process
spawning or network connections. Tools: ysoserial generates exploit payloads
for testing; SerializationDumper inspects binary streams.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Byte vs character streams | 2 minutes |
| Decorator pattern in IO | 2 minutes |
| try-with-resources semantics | 2 minutes |
| Encoding pitfalls | 2 minutes |
| Buffering and performance | 2 minutes |
| IO vs NIO for files | 2 minutes |
| Serialization security | 2-3 minutes |
| Stream closing order | 2 minutes |
| Large file processing | 2 minutes |

---

**Q1 (Byte vs character streams): What is the difference between byte
streams and character streams?**

A: **Byte streams** (`InputStream`/`OutputStream`): deal in raw bytes (0-255).
No encoding awareness. Work for any binary data: images, audio, serialized objects.

**Character streams** (`Reader`/`Writer`): deal in Java `char` values (UTF-16).
Built on top of byte streams via `InputStreamReader`/`OutputStreamWriter`.
Handle encoding conversion (bytes <-> chars). Work for text data.

```java
// Byte stream: reads raw bytes
try (InputStream is = new FileInputStream("image.jpg")) {
    byte[] buffer = new byte[8192];
    int bytesRead;
    while ((bytesRead = is.read(buffer)) != -1) {
        process(buffer, 0, bytesRead); // process raw bytes
    }
}

// Character stream: reads decoded text
try (Reader r = new InputStreamReader(
        new FileInputStream("text.txt"), UTF_8)) {
    char[] buffer = new char[8192];
    int charsRead;
    while ((charsRead = r.read(buffer)) != -1) {
        process(new String(buffer, 0, charsRead)); // process text
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Rule: use byte streams for binary data. Use character streams (with
explicit encoding) for text data.

*What separates good from great:* Java `char` is UTF-16 internally.
`InputStreamReader` converts from external encoding (e.g., UTF-8) to
Java's internal UTF-16. `OutputStreamWriter` converts back. For files
with multi-byte characters (emoji, CJK characters), be aware: a single
Unicode code point may be one `char` (BMP) or two `char` values (surrogate
pair, above U+FFFF). Java's `String.length()` returns char count (UTF-16
units), not code point count. `"emoji".codePointCount(0, s.length())`
gives actual Unicode character count.

---

**Q2 (Decorator pattern in IO): How does the decorator pattern apply
to Java IO?**

A: The decorator pattern wraps an object to add functionality while
preserving the same interface.

```java
// All decorators take a stream in their constructor:
InputStream base = new FileInputStream("data.bin"); // component

// Decorator: adds buffering
InputStream buffered = new BufferedInputStream(base);

// Decorator: adds ability to read Java primitives
DataInputStream data = new DataInputStream(buffered);

// Decorator chain: FileInputStream -> BufferedInputStream -> DataInputStream
// Each layer adds functionality without knowing about others

// The same with OutputStreams:
OutputStream os = new FileOutputStream("out.bin");
os = new BufferedOutputStream(os);        // add buffering
os = new DataOutputStream(os);           // add typed writes (primitives)
os = new GZIPOutputStream(os);           // add GZIP compression

// Writing to a compressed file:
try (DataOutputStream dos = new DataOutputStream(
        new GZIPOutputStream(
            new BufferedOutputStream(new FileOutputStream("data.gz"))))) {
    dos.writeInt(42);
    dos.writeUTF("compressed data!");
}
// Layers: FileOutputStream (base) -> BufferedOutputStream (buffering)
//      -> GZIPOutputStream (compression) -> DataOutputStream (typed write)
// Data flows: int -> DataOutputStream serializes -> GZIPOutputStream compresses
//           -> BufferedOutputStream batches -> FileOutputStream writes
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The decorator pattern in IO allows
arbitrary composition of behaviors without combinatorial explosion of
subclasses. If you had N functionalities (buffering, compression, encryption,
data types) and M stream types (file, network, memory): without decorator
you'd need N*M subclasses. With decorator: N+M classes, combine at
construction time. This is why `new GZIPOutputStream(new BufferedOutputStream(socket.getOutputStream()))` works perfectly - each layer is unaware
of the others. The cost: deeply nested constructors are verbose; the NIO
Files API wraps this complexity into simpler factory methods.

---

**Q3 (try-with-resources semantics): Explain how try-with-resources
handles exceptions.**

A:
```java
// Syntax:
try (ResourceA a = ...; ResourceB b = ...) {
    // use a and b
} catch (Exception e) {
    // handle
}
// Resources closed in reverse order: b first, then a
// Even if the try block throws OR if previous close() throws

// Exception handling with multiple exceptions:
try (AutoCloseable outer = new Outer();  // closed second
     AutoCloseable inner = new Inner()) { // closed first
    throw new RuntimeException("from body");
} catch (Exception e) {
    // e is "from body" (the primary exception)
    // If outer.close() ALSO throws:
    //   e.getSuppressed()[0] = exception from outer.close()
    //   e.getSuppressed()[1] = exception from inner.close()
    // Primary exception always takes precedence!
}

// Without try-with-resources (old way - bug: exception from finally
// suppresses exception from try):
InputStream is = new FileInputStream("f");
try {
    throw new IOException("read failed");
} finally {
    is.close(); // if this ALSO throws IOException:
                // the original "read failed" is SWALLOWED!
    // The finally exception replaces the try exception!
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The suppressed exception mechanism
(introduced with try-with-resources in Java 7) is a correct solution
to a pre-existing bug. Before Java 7: a `finally` block that throws
replaces the original exception - the original failure is lost, making
debugging impossible. With try-with-resources: the primary exception
survives, and any `close()` exceptions are attached as suppressed.
When debugging failures in code using resources: always check
`e.getSuppressed()` in the stack trace - these are often clues to
cascading failures.

---

**Q4 (Encoding pitfalls): What are the encoding pitfalls in Java IO?**

A:

**Pitfall 1: Platform-default encoding**
```java
// WRONG: FileReader uses platform default encoding
Reader r = new FileReader("config.properties");
// On Windows with Windows-1252 default: reads bytes as Windows-1252
// On Linux with UTF-8 default: reads as UTF-8
// Same file, different results!

// CORRECT:
Reader r = new InputStreamReader(
    new FileInputStream("config.properties"),
    StandardCharsets.UTF_8); // explicit encoding
// Or:
Reader r = Files.newBufferedReader(
    Path.of("config.properties"), StandardCharsets.UTF_8);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Pitfall 2: PrintStream encoding (System.out)**
```java
// System.out is a PrintStream with platform encoding
System.out.println("日本語"); // may display as "???" on non-UTF-8 terminals
// In production servers (Linux/UTF-8): usually OK
// In CI/CD pipelines or Windows: may corrupt
// Fix for tests:
PrintStream out = new PrintStream(System.out, true, StandardCharsets.UTF_8);
// Or: set JVM default: -Dfile.encoding=UTF-8 (Java 17)
//     or: -Dstdout.encoding=UTF-8 (Java 18+)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Pitfall 3: BOM in UTF-8 files**
```java
// Some files (especially from Windows Notepad) start with UTF-8 BOM:
// EF BB BF (the BOM bytes)
// BufferedReader.readLine() does NOT strip BOM!
String firstLine = br.readLine();
if (firstLine.startsWith("\uFEFF")) { // BOM as Unicode
    firstLine = firstLine.substring(1);
}
// Or use Apache Commons IO's BOMInputStream
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The file.encoding system property was
the conventional way to set default encoding but was "soft" in older Java
(not always respected). Java 17 introduced `java.nio.charset.Charset.defaultCharset()`
being settable via system property. Java 18 made UTF-8 the default on all
platforms (`-Dfile.encoding=UTF-8` no longer needed on most JDKs). This
was a major portability improvement. In modern Java (18+): `FileReader`
uses UTF-8 by default on all platforms. But for explicit, portable code:
always specify encoding regardless of Java version.

---

**Q5 (Buffering and performance): Why is buffering critical for IO performance?**

A:
```java
// Measuring unbuffered vs buffered read:
// Unbuffered: one system call per byte
try (InputStream is = new FileInputStream("large.bin")) {
    int b;
    while ((b = is.read()) != -1) { // system call for each byte!
        process((byte) b);
    }
    // For a 1MB file: ~1,000,000 system calls
    // Typical system call: ~1-2 microseconds
    // Total: ~1-2 seconds just in system call overhead!
}

// Buffered: one system call per 8KB
try (InputStream is = new BufferedInputStream(
        new FileInputStream("large.bin"))) {
    int b;
    while ((b = is.read()) != -1) { // reads from buffer; OS call every 8KB
        process((byte) b);
    }
    // For a 1MB file: ~128 system calls
    // Total: <1 millisecond in system call overhead
}

// Block read: most efficient
try (InputStream is = new BufferedInputStream(
        new FileInputStream("large.bin"))) {
    byte[] buffer = new byte[8192];
    int bytesRead;
    while ((bytesRead = is.read(buffer)) != -1) {
        process(buffer, 0, bytesRead); // process a block at a time
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Buffering is the single most impactful
IO optimization. The `read()` method on `BufferedInputStream` reads from
an in-memory buffer (refilled when empty by reading 8192 bytes from the
OS in one system call). The performance difference: on Linux, `read(2)`
system call for 1 byte vs 8192 bytes is roughly the same cost (~1µs).
Reading a 1MB file: 1 call vs 1M calls = 1000x difference. NIO
`FileChannel.read(ByteBuffer)` can be even faster: direct byte buffers
avoid a copy between kernel and user space.

---

**Q6 (IO vs NIO for files): When do you use IO vs NIO for file operations?**

A:

| Use Case | IO API | NIO (Files) API |
|---|---|---|
| Read entire small file | `FileReader` + loop | `Files.readAllLines()` or `Files.readString()` |
| Read large file line by line | `BufferedReader` + loop | `Files.lines()` (lazy stream) |
| Write text | `PrintWriter` / `BufferedWriter` | `Files.write()` or `Files.writeString()` |
| Copy files | Manual read-write loop | `Files.copy()` |
| Move / rename | `File.renameTo()` (unreliable) | `Files.move()` (atomic on same filesystem) |
| Check if file exists | `new File(path).exists()` | `Files.exists(path)` |
| File metadata | `File.length()`, `lastModified()` | `Files.size()`, `Files.getLastModifiedTime()` |
| Walk directory | `File.listFiles()` + recursion | `Files.walk()` or `Files.walkFileTree()` |
| Binary file processing | IO streams | NIO `FileChannel` + `ByteBuffer` |

```java
// Modern NIO for common operations:
// Read entire file (small files only):
String content = Files.readString(Path.of("config.txt"), UTF_8);

// Write file (overwrites; use APPEND for append):
Files.writeString(Path.of("out.txt"), content, UTF_8,
    StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);

// Copy:
Files.copy(source, dest, StandardCopyOption.REPLACE_EXISTING);

// Walk directory:
Files.walk(Path.of("src"), 10) // max depth 10
    .filter(p -> p.toString().endsWith(".java"))
    .forEach(System.out::println);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* `Files.move()` with `ATOMIC_MOVE` is
the only reliable way to atomically rename or replace a file on a single
filesystem. `File.renameTo()` returns a boolean on failure (no exception),
silently fails across filesystems, and is not atomic. Production pattern:
write to a temp file, then `Files.move(temp, dest, ATOMIC_MOVE)` to avoid
readers seeing a partially-written file. This is used by databases (WAL),
configuration management (Ansible), and deployment tools.

---

**Q7 (Serialization security): Why is Java serialization a security risk?**

A: Java object deserialization executes code during the deserialization
process. If an attacker can inject a crafted byte stream:

1. `readObject()` methods of objects in the stream are called during deserialization
2. Classes already on the classpath (gadgets) may have `readObject()` that
   triggers dangerous operations
3. By chaining gadgets, attackers can achieve arbitrary code execution (RCE)

```java
// Known vulnerable deserialization:
ObjectInputStream ois = new ObjectInputStream(untrustedInput);
Object obj = ois.readObject(); // DANGEROUS if input is untrusted!

// Real exploit classes (before patches):
// - Apache Commons Collections: InvokerTransformer chain
// - Spring Framework: various gadget chains
// - JDK itself: UnicastRef, JMX gadgets

// Mitigations:
// 1. Don't deserialize untrusted input (best defense)
// 2. Java 9+ ObjectInputFilter:
ObjectInputFilter filter = ObjectInputFilter.Config.createFilter(
    "com.myapp.*;!*"); // only allow your own classes
// 3. Java 9+ JEP 290: set JVM-wide filter:
// -Djdk.serialFilter=maxbytes=10000;maxdepth=5;!*

// Safe alternatives:
// JSON: ObjectMapper.readValue(json, MyClass.class) - no code execution
// Protobuf: generated parser with no dynamic dispatch
// Avro/Thrift: schema-driven, no arbitrary code execution
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Java serialization's fundamental problem:
`readObject()` is a code execution point, not just data deserialization.
CVE-2015-4852 (WebLogic), CVE-2015-7501 (JBoss), and others caused billions
in security incidents. The fix requires not just patching vulnerable libraries
but architectural changes: stop accepting Java-serialized data from untrusted
sources. Modern systems: JSON over HTTP (Jackson), gRPC (Protobuf), or
message queues with schema registries (Avro) - none execute arbitrary code
during parsing. The `ObjectInputFilter` (Java 9+) is a defense-in-depth
measure, not a complete fix: an allowlist is safe; a blocklist will always
miss gadget classes.

---

**Q8 (Stream closing order): What is the correct order to close nested
IO streams?**

A: With `try-with-resources`: resources are closed in REVERSE declaration
order (innermost stream first). With manual close: close outermost first
(which propagates close to inner).

```java
// try-with-resources: reverse order (correct)
try (InputStream fis = new FileInputStream("file");         // closed last
     BufferedInputStream bis = new BufferedInputStream(fis); // closed second
     DataInputStream dis = new DataInputStream(bis)) {       // closed first
    dis.readInt();
}
// Close order: dis, bis, fis

// Manual: close outermost (propagates down):
DataInputStream dis = new DataInputStream(
    new BufferedInputStream(new FileInputStream("file")));
dis.close(); // calls BufferedInputStream.close() -> FileInputStream.close()

// RISK: in try-with-resources, if any constructor throws,
// only already-declared resources are closed:
try (InputStream fis = new FileInputStream("file"); // declared
     ObjectInputStream ois = new ObjectInputStream(fis)) { // if this throws:
    // fis is closed (it was declared)
    // ois is not open (constructor failed)
    // Correct: fis is properly closed
}

// RISK: if you don't use try-with-resources and constructor throws:
InputStream fis = new FileInputStream("file"); // opened
ObjectInputStream ois;
try {
    ois = new ObjectInputStream(fis); // might throw
} catch (IOException e) {
    fis.close(); // must manually close fis if ois construction fails!
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The `try-with-resources` resource variable
scope is important: only resources declared IN the parentheses are
automatically closed. If you open a resource inside the try block (not
in the declaration), it won't be auto-closed. For chained stream construction:
if any inner constructor throws, any already-constructed outer streams
that aren't in the resource variable list need manual cleanup. This is
why `try-with-resources` with each stream separately declared is safer
than nesting all in one `new`:
```java
// Safer (each declared):
try (FileInputStream fis = new FileInputStream("f");
     InputStreamReader isr = new InputStreamReader(fis, UTF_8);
     BufferedReader br = new BufferedReader(isr)) { ... }
// vs: new BufferedReader(new InputStreamReader(new FileInputStream("f")))
// Only the outermost is in the resource variable - inner leaks on constructor failure
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

**Q9 (Large file processing): How do you process a file that doesn't
fit in memory?**

A:
```java
// Files.readAllLines() - NOT for large files: loads ALL lines into memory
List<String> lines = Files.readAllLines(path, UTF_8); // OOM for 10GB file!

// GOOD: Files.lines() - lazy Stream, processes one line at a time:
long count;
try (Stream<String> stream = Files.lines(path, UTF_8)) { // lazy
    count = stream
        .filter(line -> line.contains("ERROR"))
        .count(); // only "ERROR" lines are processed per line
} // stream and underlying reader closed

// For very large binary files: NIO FileChannel with direct ByteBuffer
try (FileChannel channel = FileChannel.open(path, StandardOpenOption.READ)) {
    ByteBuffer buffer = ByteBuffer.allocateDirect(1024 * 1024); // 1MB direct
    while (channel.read(buffer) > 0) {
        buffer.flip(); // prepare for reading
        while (buffer.hasRemaining()) {
            process(buffer.get()); // process byte
        }
        buffer.clear(); // prepare for next read
    }
}

// Memory-mapped files: OS maps file into virtual address space
try (FileChannel channel = FileChannel.open(path)) {
    MappedByteBuffer mmap = channel.map(
        FileChannel.MapMode.READ_ONLY, 0, channel.size());
    // Entire file accessible as a ByteBuffer
    // OS pages in data on demand - no explicit read loop
    // Fastest for random access patterns on large files
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* `Files.lines()` is the right tool for
large text files: it buffers reads but doesn't hold all lines in memory.
The `Stream` must be closed (use try-with-resources) to release the
underlying file handle. Memory-mapped files (`MappedByteBuffer`) are
the fastest for read-heavy, random-access patterns on large files:
the OS handles page-in/page-out transparently. Used by: JVM class loading,
database engines (SQLite, H2), search engines (Lucene). The downside:
`MappedByteBuffer` is hard to unmap explicitly in Java (a known limitation;
requires reflection or closing the `FileChannel` and waiting for GC).

---

### ⚖️ Comparison Table

| Aspect | IO (java.io) | NIO (java.nio) | NIO2 (Files API) |
|---|---|---|---|
| Paradigm | Stream (one byte/char at a time) | Channel + Buffer (block-oriented) | Path-based file ops |
| Blocking | Blocking | Non-blocking available | Blocking (convenience) |
| Performance | Good with buffering | Best for large files | Good |
| Ease of use | Moderate | Complex | Simplest |
| API style | Imperative | Low-level | Modern/functional |
| Best for | Text processing, protocols | High-throughput binary | File management |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: class hierarchy described adequately in Concept Explanation)*

---

---

## NIO Files API

---

### 🎯 Model Answer

**30 seconds:**
> `java.nio.file.Files` and `java.nio.file.Path` (NIO2, Java 7) are
> the modern Java file system API. Key operations: `Files.readString()`,
> `Files.writeString()`, `Files.copy()`, `Files.move()`, `Files.delete()`,
> `Files.exists()`, `Files.walk()`, `Files.lines()`. `Path` replaces
> the legacy `java.io.File`. `Paths.get()` or `Path.of()` (Java 11)
> create Paths. NIO2 provides atomic operations (`ATOMIC_MOVE`), proper
> exceptions (not just boolean returns), and tree walking. `WatchService`
> monitors file system changes.

**3 minutes (Senior):**
> Key improvements over `java.io.File`: (1) Proper exception handling -
> `File.delete()` returns boolean; `Files.delete()` throws `IOException`
> with reason. (2) Atomic operations - `Files.move(src, dest, ATOMIC_MOVE)`
> is atomic on POSIX filesystems. (3) Symbolic links - `Files.readSymbolicLink()`,
> link following options. (4) Metadata - `Files.readAttributes()`, `BasicFileAttributes`.
> (5) Directory traversal - `Files.walk()` (depth-first), `Files.walkFileTree()` (visitor).
>
> `WatchService`: registers a path to receive events (`ENTRY_CREATE`,
> `ENTRY_MODIFY`, `ENTRY_DELETE`). Uses OS-level notifications (inotify
> on Linux, FSEvents on macOS, ReadDirectoryChangesW on Windows) - not
> polling. Used by: Spring Boot DevTools (auto-restart), Webpack dev server,
> configuration reload systems.
>
> Path operations: `path.resolve()` (append), `path.relativize()` (compute
> relative path), `path.normalize()` (remove `.`, `..`), `path.toAbsolutePath()`,
> `path.getParent()`, `path.getFileName()`.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "NIO Files API - let me cover Path operations, the Files
utility class, WatchService for file system events, and the improvements
over java.io.File."

**(2) First principles:** "From first principles: file system operations
need: reliable error reporting (not just booleans), atomic operations
to avoid partial writes, and notification-based change detection (not
polling). NIO2 provides all three."

**(3) Bridge:** "NIO2 is the 'grown-up' file API. `java.io.File` is
like a pocket knife - convenient but limited, with silent failures.
NIO2 is the full toolbox: proper errors, atomic operations, notifications,
and rich metadata access."

---

### 📘 Concept Explanation

**Path basics:**
```java
// Creating Paths:
Path p1 = Path.of("/home/user/file.txt"); // Java 11
Path p2 = Paths.get("/home/user/file.txt"); // Java 7+
Path p3 = Path.of("relative/path.txt");  // relative to cwd
Path p4 = Path.of("C:", "Users", "user", "file.txt"); // Windows

// Path operations:
Path base = Path.of("/home/user");
Path file = base.resolve("docs/file.txt");  // /home/user/docs/file.txt
Path rel = Path.of("/home").relativize(file); // user/docs/file.txt
Path norm = Path.of("/a/b/../c").normalize(); // /a/c
Path abs = Path.of("relative.txt").toAbsolutePath(); // CWD + relative.txt

// Components:
path.getParent();    // /home/user/docs
path.getFileName();  // file.txt (as Path)
path.getRoot();      // / (or null if relative)
path.getNameCount(); // number of path elements
path.getName(0);     // first element

// Conversion to/from legacy File:
File legacy = path.toFile();
Path modern = legacy.toPath();
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Files utility key methods:**
```java
// Existence and type:
Files.exists(path)                // true/false
Files.exists(path, LinkOption.NOFOLLOW_LINKS) // don't follow symlinks
Files.isDirectory(path)
Files.isRegularFile(path)
Files.isSymbolicLink(path)
Files.isReadable(path)
Files.isWritable(path)

// Metadata:
Files.size(path)
Files.getLastModifiedTime(path)
Files.getOwner(path)
BasicFileAttributes attrs = Files.readAttributes(
    path, BasicFileAttributes.class);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The WatchService example shows event-driven
> file monitoring vs polling. The atomic write pattern (write to temp,
> then move) is the production-safe way to update files: readers never
> see a partially-written file. The directory walk example demonstrates
> `Files.walk()` with stream processing to find files matching criteria.

```java
// Atomic file update pattern (write then rename):
Path target = Path.of("/etc/app/config.json");
Path temp = Path.of("/etc/app/config.json.tmp." + UUID.randomUUID());

// Write to temp:
Files.writeString(temp, newConfig, UTF_8,
    StandardOpenOption.CREATE_NEW); // fail if exists (prevents race)

try {
    // Atomic rename: readers see old or new, never partial:
    Files.move(temp, target,
        StandardCopyOption.REPLACE_EXISTING,
        StandardCopyOption.ATOMIC_MOVE);    // atomic on POSIX filesystems
} catch (AtomicMoveNotSupportedException e) {
    // Fallback: non-atomic move (cross-filesystem)
    Files.move(temp, target, StandardCopyOption.REPLACE_EXISTING);
} catch (Exception e) {
    Files.deleteIfExists(temp); // clean up temp on failure
    throw e;
}

// WatchService: OS-level file change notification:
WatchService watcher = FileSystems.getDefault().newWatchService();
Path dir = Path.of("/etc/app");
dir.register(watcher,
    StandardWatchEventKinds.ENTRY_CREATE,
    StandardWatchEventKinds.ENTRY_MODIFY,
    StandardWatchEventKinds.ENTRY_DELETE);

// In a background thread:
while (!Thread.interrupted()) {
    WatchKey key = watcher.take(); // blocks until event
    for (WatchEvent<?> event : key.pollEvents()) {
        WatchEvent.Kind<?> kind = event.kind();
        if (kind == StandardWatchEventKinds.OVERFLOW) continue;
        Path changed = (Path) event.context(); // filename only, not full path!
        Path fullPath = dir.resolve(changed);  // resolve to full path
        if (kind == StandardWatchEventKinds.ENTRY_MODIFY) {
            reloadConfig(fullPath);
        }
    }
    key.reset(); // must reset to receive further events
}

// Directory walk: find all .java files in a directory tree:
try (Stream<Path> walk = Files.walk(Path.of("src"), Integer.MAX_VALUE)) {
    List<Path> javaFiles = walk
        .filter(p -> p.toString().endsWith(".java"))
        .filter(Files::isRegularFile) // exclude .java directories (shouldn't exist)
        .collect(Collectors.toList());
}
```

> **Code walkthrough:** The atomic write pattern is production-critical:
> writing directly to the target file creates a window where the file
> is partially written and another process reads it (empty or corrupt).
> Writing to a temp file first, then atomically moving it, eliminates
> this window - the rename is a single atomic operation at the filesystem
> level (POSIX `rename(2)`). The `ATOMIC_MOVE` flag throws
> `AtomicMoveNotSupportedException` for cross-filesystem moves (a temp
> file on `/tmp` and target on `/home` may be different filesystems);
> always handle this case with a fallback.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `Path` is the modern replacement for `java.io.File`. Use `Files.readString()`,
> `Files.writeString()`, `Files.copy()`, `Files.move()`. `Files.delete()`
> throws exceptions on failure (unlike `File.delete()` which returns false).
> `Files.walk()` traverses directories. `WatchService` monitors for changes.

---

**Senior / Staff (5+ years):**
> `WatchService` uses OS-level notifications: `inotify` on Linux,
> `kqueue` on macOS, `ReadDirectoryChangesW` on Windows. This is far
> more efficient than polling (`Files.getLastModifiedTime()` in a loop).
> However: macOS `WatchService` polls by default (JDK 8 issue - fixed
> in JDK 21 with `FileSystemProvider` improvements). For cross-platform
> reliability: use Apache Commons IO's `FileAlterationObserver` or Spring's
> `FileSystemWatcher` which handles OS differences. `Files.walk()` lazy
> stream must be closed (use try-with-resources) - it holds an open
> `DirectoryStream` internally that must be released.

---

### ⚠️ Common Misconceptions

**Misconception 1: "`Files.walk()` can be used without try-with-resources."**
`Files.walk()` returns a `Stream<Path>` that holds an open directory
stream internally. If you don't close it (via try-with-resources or
`stream.close()`), the directory file descriptor leaks. JVM eventually
closes it via GC finalizer, but this is non-deterministic. Always:
`try (Stream<Path> s = Files.walk(...)) { ... }`.

**Misconception 2: "`Files.move()` with `ATOMIC_MOVE` works cross-filesystem."**
Atomic move (POSIX `rename(2)`) only works within the same filesystem.
Moving from `/tmp/` to `/data/` fails with `AtomicMoveNotSupportedException`
if they're different mount points. The pattern: keep temp file on the
same filesystem as the target. `Path.of(target.getParent(), "temp")` creates
the temp file in the same directory as the target.

---

### 🚨 Failure Modes and Diagnosis

**Failure: WatchService misses events due to buffer overflow.**
```java
// WatchService has a limited event queue:
// If events arrive faster than they're processed:
WatchEvent.Kind<?> kind = event.kind();
if (kind == StandardWatchEventKinds.OVERFLOW) {
    // Some events were missed! Re-scan the directory:
    rescanDirectory(dir);
    continue;
}
// Always handle OVERFLOW: it means "you missed some events"
// Never ignore it - use OVERFLOW to trigger a full re-scan
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Diagnosis: file changes not being detected; application out-of-sync
with filesystem. Check if OVERFLOW events are being received and ignored.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Path vs File comparison | 2 minutes |
| Atomic file write pattern | 2 minutes |
| WatchService internals | 2 minutes |
| Files.walk resource management | 2 minutes |
| Copy options | 2 minutes |
| Directory traversal options | 2 minutes |
| Temp files and paths | 90 seconds |
| File attributes | 2 minutes |
| Symbolic links handling | 2 minutes |

---

**Q1 (Path vs File comparison): What are the improvements of Path/Files
over java.io.File?**

A:

| Aspect | java.io.File | java.nio.file.Path + Files |
|---|---|---|
| Error reporting | boolean return (delete, mkdir) | Throws IOException with detail |
| Atomic operations | None | `Files.move(ATOMIC_MOVE)` |
| Symbolic links | Partial support | Full support, follow/no-follow options |
| File attributes | `length()`, `lastModified()` | `BasicFileAttributes`, extended attrs |
| Directory listing | `listFiles()` (loads all into array) | `Files.list()` (lazy stream) |
| Tree walking | Manual recursion | `Files.walk()`, `Files.walkFileTree()` |
| Change notification | Polling only | `WatchService` (OS events) |
| Interoperability | Standard | Integrates with NIO channels |

```java
// File: silent failure
File f = new File("/read-only/file");
f.delete(); // returns false - WHY did it fail?

// Files: informative exception
try {
    Files.delete(Path.of("/read-only/file"));
} catch (NoSuchFileException e) {
    log.error("File does not exist: {}", e.getFile());
} catch (AccessDeniedException e) {
    log.error("Permission denied: {}", e.getFile());
} catch (DirectoryNotEmptyException e) {
    log.error("Directory not empty: {}", e.getFile());
}

// Files.deleteIfExists: delete if present, no exception if absent:
Files.deleteIfExists(path); // throws only on failure (not if missing)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The exception hierarchy under
`java.nio.file` is much richer than generic `IOException`. `NoSuchFileException`,
`AccessDeniedException`, `DirectoryNotEmptyException`,
`NotDirectoryException`, `AtomicMoveNotSupportedException` - each is
catchable separately for precise error handling. In production code:
catch specific exceptions to provide clear user-facing messages and
distinguish "retry-able" failures (temporary lock) from permanent ones
(permission denied). The boolean return from `File.delete()` was a
historical mistake that makes error handling impossible.

---

**Q2 (Atomic file write pattern): How do you atomically update a file?**

A: The pattern: write to a temp file, then atomically rename to target.

```java
/**
 * Atomically replaces target with new content.
 * Readers see old or new content, never partial writes.
 */
public static void atomicWrite(Path target, String content)
        throws IOException {
    // Create temp file in SAME directory as target (important!)
    // Same directory = same filesystem = atomic rename possible
    Path temp = Files.createTempFile(
        target.getParent(),  // same dir as target
        ".tmp-",             // prefix
        null);               // suffix (auto-generated)

    try {
        Files.writeString(temp, content, UTF_8,
            StandardOpenOption.WRITE,
            StandardOpenOption.TRUNCATE_EXISTING);

        // Attempt atomic move:
        try {
            Files.move(temp, target,
                StandardCopyOption.REPLACE_EXISTING,
                StandardCopyOption.ATOMIC_MOVE);
        } catch (AtomicMoveNotSupportedException e) {
            // Fallback: non-atomic but still replace-existing
            // (window of partial visibility exists)
            Files.move(temp, target,
                StandardCopyOption.REPLACE_EXISTING);
        }
    } catch (IOException e) {
        Files.deleteIfExists(temp); // clean up
        throw e;
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* `Files.createTempFile(parent, ...)` is
important: the temp file must be on the same filesystem as the target.
`Files.createTempFile()` without a parent uses the system temp dir
(`/tmp` on Linux) which may be a different filesystem from `/etc/app/`.
Cross-filesystem move is NOT atomic (copies then deletes). Another
production pattern: databases use WAL (Write-Ahead Log) which is the
same principle - write changes to a separate log file first, then apply
to the main file.

---

**Q3 (WatchService internals): How does WatchService work under the hood?**

A: `WatchService` delegates to OS-level file change notification mechanisms:

| OS | Mechanism | Details |
|---|---|---|
| Linux | `inotify` | Kernel watches inodes; instant notification |
| macOS | `kqueue` / FSEvents | JDK 8: polling fallback; JDK 17+: FSEvents |
| Windows | `ReadDirectoryChangesW` | Win32 API for directory change events |

```java
// Registration:
WatchService ws = FileSystems.getDefault().newWatchService();
path.register(ws, ENTRY_CREATE, ENTRY_MODIFY, ENTRY_DELETE);
// Under the hood: JVM calls inotify_add_watch(fd, path, mask) on Linux

// Consuming events:
WatchKey key = ws.take(); // blocks until event (or poll() for non-blocking)
// Under the hood: JVM calls read(inotify_fd) which blocks until event

// Event details:
for (WatchEvent<?> event : key.pollEvents()) {
    Path changed = (Path) event.context(); // only FILENAME, not full path
    int count = event.count(); // >1 if repeated events coalesced
}
key.reset(); // MUST reset or key goes invalid; no more events for this key
// Under the hood: continues the inotify watch

// Cancel (stop watching):
key.cancel();
ws.close(); // releases inotify file descriptor
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The WatchKey lifecycle is critical:
after `take()`, the key is in "signaled" state and won't receive events.
`key.reset()` returns it to "ready" state. Forgetting `key.reset()`
means: you process the first batch of events, then never get more.
Symptom: file changes detected initially, then missed. Also: WatchService
monitors directories, not individual files. To watch `config.json`:
register its parent directory and filter events by filename.

---

**Q4 (Files.walk resource management): What resource leak can occur
with Files.walk()?**

A: `Files.walk()` opens a directory stream internally. This stream holds
a file descriptor. Without closing: the FD leaks.

```java
// LEAK: no try-with-resources
Stream<Path> paths = Files.walk(dir);
paths.forEach(System.out::println);
// Stream is not closed! DirectoryStream FD leaks.
// GC eventually finalizes it, but non-deterministic.

// CORRECT: try-with-resources
try (Stream<Path> paths = Files.walk(dir)) {
    paths.forEach(System.out::println);
} // DirectoryStream closed here

// Also: if early-terminating the stream:
try (Stream<Path> paths = Files.walk(dir)) {
    Optional<Path> first = paths
        .filter(p -> p.endsWith("pom.xml"))
        .findFirst(); // stream not fully consumed - still need to close!
}

// Files.find: walk with built-in filter (more efficient than walk+filter):
try (Stream<Path> found = Files.find(dir, 10,
        (path, attrs) -> attrs.isRegularFile()
                         && path.toString().endsWith(".log"))) {
    found.forEach(System.out::println);
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Also:** `Files.list()` (single directory, not recursive) has the same
requirement: close the returned stream.

*What separates good from great:* File descriptor exhaustion (`Too many
open files`) is a production failure mode in Java services. Default FD
limits on Linux: 1024 per process (adjustable). A service that calls
`Files.walk()` or `Files.list()` in a loop without closing will exhaust
FDs quickly under load. Diagnosis: `lsof -p <pid> | wc -l` (count open FDs),
`lsof -p <pid> | grep DIR` (directory streams). `-XX:+PrintGC` and heap
dumps won't show this - it's an OS resource leak, not heap memory.

---

**Q5 (Copy options): What StandardCopyOption values exist and when
do you use each?**

A:
```java
// REPLACE_EXISTING: overwrite target if it exists
Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING);
// Without REPLACE_EXISTING: throws FileAlreadyExistsException if target exists

// COPY_ATTRIBUTES: copy file attributes (timestamps, permissions)
Files.copy(source, target,
    StandardCopyOption.REPLACE_EXISTING,
    StandardCopyOption.COPY_ATTRIBUTES);
// Without: target gets current time as creation time

// ATOMIC_MOVE: move atomically (same filesystem only)
Files.move(source, target, StandardCopyOption.ATOMIC_MOVE);
// Throws AtomicMoveNotSupportedException if cross-filesystem

// LinkOption.NOFOLLOW_LINKS: don't follow symlinks
Files.copy(symlink, target, LinkOption.NOFOLLOW_LINKS);
// Copies the symlink itself, not the file it points to

// Combination for directory copy (Files.copy only copies one file/dir):
Files.copy(source, target,
    StandardCopyOption.REPLACE_EXISTING,
    StandardCopyOption.COPY_ATTRIBUTES);
// For recursive directory copy: use Files.walk + copy each file
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* `Files.copy()` does NOT recursively
copy directories - it only copies a single file or creates an empty
directory. For recursive directory copy: combine `Files.walk()` with
individual `Files.copy()` calls for each file. This is a common interview
question: "How do you copy a directory tree?" Answer: walk the source,
for each file/directory: create the relative path in the target, copy
the file. The `walkFileTree` with a `FileVisitor` is the traditional
approach; `Files.walk()` stream with manual copy is the modern approach.

---

**Q6 (Directory traversal options): What are the options for traversing
a directory tree?**

A:
```java
// 1. Files.walk(path): depth-first, Stream<Path>
// Simple, functional, closes properly with try-with-resources
try (Stream<Path> walk = Files.walk(root)) {
    walk.filter(Files::isRegularFile)
        .forEach(this::processFile);
}

// 2. Files.find(path, depth, matcher): walk with built-in filter
// More efficient than walk+filter when filter is simple:
try (Stream<Path> found = Files.find(root, 10,
        (p, attrs) -> attrs.isRegularFile() && attrs.size() > 1024 * 1024)) {
    found.forEach(System.out::println); // files > 1MB
}

// 3. Files.walkFileTree: event-based visitor (pre/post-visit):
Files.walkFileTree(root, new SimpleFileVisitor<Path>() {
    @Override
    public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) {
        process(file, attrs);
        return FileVisitResult.CONTINUE;
    }
    @Override
    public FileVisitResult visitFileFailed(Path file, IOException e) {
        log.error("Cannot visit: {} - {}", file, e.getMessage());
        return FileVisitResult.CONTINUE; // skip, don't abort
    }
    @Override
    public FileVisitResult preVisitDirectory(Path dir,
            BasicFileAttributes attrs) {
        if (dir.getFileName().toString().startsWith(".")) {
            return FileVisitResult.SKIP_SUBTREE; // skip hidden dirs
        }
        return FileVisitResult.CONTINUE;
    }
});

// FileVisitResult options:
// CONTINUE, SKIP_SUBTREE (skip this directory's contents),
// SKIP_SIBLINGS (skip other files in same directory), TERMINATE
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* `visitFileFailed` in `walkFileTree`
handles permission-denied errors gracefully. `Files.walk()` by default
throws on permission-denied entries; `walkFileTree` with `visitFileFailed`
returning `CONTINUE` skips inaccessible paths. For production directory
scans (backup tools, search indexers): always use `walkFileTree` with
proper `visitFileFailed` handling. `SKIP_SUBTREE` is essential for
performance: skipping `node_modules`, `.git`, build output directories.

---

**Q7 (Temp files and paths): How do you create temp files safely?**

A:
```java
// Creates temp file with unique name in system temp dir:
Path temp = Files.createTempFile("prefix-", ".tmp");
// e.g., /tmp/prefix-8429347230423.tmp

// Creates temp file in specific directory:
Path temp = Files.createTempFile(dir, "prefix-", ".tmp");

// Temp directory:
Path tempDir = Files.createTempDirectory("myapp-");

// Auto-delete on JVM exit (legacy approach):
temp.toFile().deleteOnExit(); // unreliable: only on normal JVM exit!

// CORRECT: try-with-resources for temp file lifetime:
Path temp = Files.createTempFile("work-", ".json");
try {
    Files.writeString(temp, json, UTF_8);
    processFile(temp);
} finally {
    Files.deleteIfExists(temp); // explicit cleanup
}

// For temp directory with cleanup:
Path tempDir = Files.createTempDirectory("workdir-");
try {
    // use tempDir
} finally {
    // Recursively delete:
    Files.walk(tempDir)
        .sorted(Comparator.reverseOrder()) // delete files before dirs
        .forEach(p -> { try { Files.delete(p); }
                         catch (IOException e) { /* log */ } });
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* `deleteOnExit()` is unreliable: only
called on normal JVM shutdown (not on kill -9, OutOfMemoryError, or
StackOverflow). Temp files from `deleteOnExit()` accumulate if the JVM
crashes. Pattern: use explicit deletion in a `finally` block or
try-with-resources. For large-scale temp file usage (many parallel
operations): use a temp directory under your application's work dir
(not `/tmp`) and clean it up on application startup (orphaned temps
from previous crashes). `/tmp` is typically `tmpfs` (in-memory on Linux)
- large temp files fill RAM, not disk.

---

**Q8 (File attributes): How do you read and set file attributes?**

A:
```java
// BasicFileAttributes: available on all filesystems
BasicFileAttributes attrs = Files.readAttributes(
    path, BasicFileAttributes.class);
attrs.creationTime()     // FileTime
attrs.lastModifiedTime() // FileTime
attrs.lastAccessTime()   // FileTime
attrs.size()             // in bytes
attrs.isRegularFile()
attrs.isDirectory()
attrs.isSymbolicLink()
attrs.fileKey()          // filesystem-specific ID (inode on UNIX)

// PosixFileAttributes: POSIX filesystems (Linux, macOS)
PosixFileAttributes posix = Files.readAttributes(
    path, PosixFileAttributes.class);
posix.owner()            // UserPrincipal
posix.group()            // GroupPrincipal
posix.permissions()      // Set<PosixFilePermission>

// Read/write permissions:
Set<PosixFilePermission> perms = posix.permissions();
// {OWNER_READ, OWNER_WRITE, GROUP_READ, OTHERS_READ}

// Set permissions:
Files.setPosixFilePermissions(path,
    PosixFilePermissions.fromString("rwxr-xr-x"));
// or:
Files.setAttribute(path, "posix:permissions",
    PosixFilePermissions.fromString("rw-r--r--"));

// Set timestamps:
Files.setLastModifiedTime(path, FileTime.fromMillis(System.currentTimeMillis()));
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* `BasicFileAttributes.fileKey()` returns
the inode number on UNIX filesystems (as `Object` - cast to `Long` after
checking). Two `Path` objects with the same `fileKey` are the same
underlying file (handles hard links and symlinks). This is how `Files.isSameFile(p1, p2)` works. In deduplication tools and backup systems: use `fileKey`
to detect hard links (same inode = same physical file blocks, don't copy twice).
`Files.isSameFile()` does the inode comparison correctly even for symlinks
pointing to the same file with different paths.

---

**Q9 (Symbolic links handling): How does NIO2 handle symbolic links?**

A:
```java
// By default: Files methods FOLLOW symlinks
// (operate on the target of the link)
Files.size(symlink);      // size of target file
Files.readAttributes(symlink, BasicFileAttributes.class).isSymbolicLink();
// Returns false! Attributes of the TARGET (regular file)

// NOFOLLOW_LINKS: operate on the symlink itself
Files.readAttributes(symlink, BasicFileAttributes.class,
    LinkOption.NOFOLLOW_LINKS).isSymbolicLink(); // returns true

// Read symlink target:
Path target = Files.readSymbolicLink(symlink);
// Returns the path the symlink points to

// Create symlink:
Files.createSymbolicLink(link, target);
// link -> target

// Check if a path is a symlink (without following):
Files.isSymbolicLink(path); // same as NOFOLLOW readAttributes

// Walk: follows symlinks by default? NO (avoids infinite loops)
Files.walk(root); // by default: FileVisitOption.NOFOLLOW_LINKS
Files.walk(root, FileVisitOption.FOLLOW_LINKS); // follows (may cycle!)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Detecting cycles when following symlinks:
```java
Files.walkFileTree(root,
    EnumSet.of(FileVisitOption.FOLLOW_LINKS),
    Integer.MAX_VALUE,
    new SimpleFileVisitor<>() {
        @Override
        public FileVisitResult visitFileFailed(Path file, IOException e) {
            if (e instanceof FileSystemLoopException) {
                log.warn("Cycle detected: {}", file);
                return FileVisitResult.CONTINUE; // skip the cycle
            }
            throw e;
        }
    });
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* `Files.walk()` does NOT follow symlinks
by default - a safe default that prevents infinite loops (`a -> b -> a`).
`FileVisitOption.FOLLOW_LINKS` opts into symlink following, and
`FileSystemLoopException` (subclass of IOException) signals a detected
cycle (by comparing `fileKey` values). In container environments (Docker):
symlinks are common for configuration injection, library versioning
(`/usr/lib/libssl.so -> libssl.so.1.1`), and JDK installation
(`/usr/bin/java -> /etc/alternatives/java`). Knowing how to handle them
correctly matters for tools that inspect containers.

---

### ⚖️ Comparison Table

| Operation | java.io.File | java.nio.file.Files |
|---|---|---|
| Delete | `delete()` returns boolean | `delete()` throws IOException |
| Atomic move | Not supported | `move(ATOMIC_MOVE)` |
| Check existence | `exists()` | `exists()` with follow/no-follow |
| Directory list | `listFiles()` (array) | `list()` (lazy stream) |
| Tree walk | Manual recursion | `walk()`, `walkFileTree()` |
| Change watch | Polling | `WatchService` (OS events) |
| File metadata | Limited | `readAttributes(BasicFileAttributes)` |
| Path operations | String concatenation | `resolve()`, `relativize()`, etc. |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept)*

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



