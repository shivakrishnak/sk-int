---
layout: default
title: "Java Core - L2 IO and NIO"
parent: "Java Core"
nav_order: 6
permalink: /java-core/l2-io-and-nio/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java IO Streams: InputStream OutputStream](#java-io-streams-inputstream-outputstream) | high |
| 2 | [Reader Writer and Buffered IO](#reader-writer-and-buffered-io) | high |
| 3 | [File and Path API: java.nio.file](#file-and-path-api-javaniofile) | high |
| 4 | [NIO Channels Buffers and Selectors](#nio-channels-buffers-and-selectors) | high |
| 5 | [try-with-resources and AutoCloseable](#try-with-resources-and-autocloseable) | high |

---

# Java IO Streams: InputStream OutputStream

**Interview Weight:** high - Foundational I/O knowledge. Interviewers
test whether you know the byte-vs-character split, buffering, and
the try-with-resources pattern for safe resource handling.

---

### 🎯 Model Answer

**30 seconds:**

> Java I/O has two base hierarchies: `InputStream`/`OutputStream`
> for byte streams (images, binary data), and `Reader`/`Writer`
> for character streams (text with encoding). Byte streams read and
> write raw bytes. Character streams handle encoding/decoding.
> Always wrap with `Buffered*` variants to avoid per-byte system
> calls. Always use try-with-resources to guarantee stream closure.

**3 minutes (Senior):**

> The I/O class hierarchy is a decorator pattern. The base class
> (`FileInputStream`) reads from a source. Wrapping it in
> `BufferedInputStream` adds in-memory buffering (8KB by default)
> so reads from the application see large chunks rather than
> individual byte system calls. Wrapping that in `DataInputStream`
> adds methods to read Java primitives (int, long, float) as binary.
>
> The key production rule: unbuffered I/O in a loop is a performance
> anti-pattern. Reading a file one byte at a time with `FileInputStream.read()`
> generates one system call per byte. With a `BufferedInputStream`,
> the OS reads 8KB per system call and returns bytes from the buffer.
> The difference is orders of magnitude for large files.
>
> In modern Java (Java 7+), `Files.readAllBytes()`, `Files.readString()`,
> `Files.lines()`, and `Files.copy()` handle common I/O operations
> without manual stream management. Use the `Files` utility class
> for one-off operations; use manual streams only when you need
> streaming (large files where you cannot load everything in memory).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Java's I/O stream hierarchy
- how byte and character streams work."

**(2) First principles:** "Any I/O system needs: a data source
(file, network), a read mechanism (byte or character), and
buffering to avoid expensive system calls per byte."

**(3) Bridge:** "This is analogous to Python's IO module - `io.RawIOBase`
for bytes, `io.TextIOWrapper` for text, `io.BufferedReader` for
buffering."

---

### 📘 Concept Explanation

**What it is:**

`InputStream`/`OutputStream`: abstract base for byte-oriented I/O.
Key concrete classes: `FileInputStream`, `FileOutputStream`,
`ByteArrayInputStream`, `ByteArrayOutputStream`,
`BufferedInputStream`, `BufferedOutputStream`, `DataInputStream`,
`DataOutputStream`, `ObjectInputStream`, `ObjectOutputStream`.

**How it works:**

```
  Byte Stream Hierarchy (decorator pattern):
  
  FileInputStream (source: reads bytes from file)
      ↓ wraps
  BufferedInputStream (adds 8KB buffer - reduces syscalls)
      ↓ wraps
  DataInputStream (adds typed reads: readInt, readLong, readUTF)
  
  ObjectInputStream (wraps any InputStream for Java serialization)
```

**The key insight:**

`InputStream.read()` (single byte) returns an `int` from 0-255 or
-1 at end-of-stream. The return type is `int`, not `byte`, because
`byte` is signed in Java (-128 to 127) and would conflate value 255
(0xFF) with end-of-stream. This is one of Java's original API design
decisions that cannot be changed without breaking backward compatibility.

**When to use it:**

- `FileInputStream/FileOutputStream`: binary file I/O
- `ByteArrayInputStream/ByteArrayOutputStream`: in-memory I/O
  (serialize to byte array, pass bytes between components)
- `BufferedInputStream/BufferedOutputStream`: always wrap file
  and network streams
- `DataInputStream/DataOutputStream`: binary protocol I/O
- `Files` utility: simple read/write operations

**When NOT to use it:**

- Do not use `FileInputStream` for text files - use `FileReader`
  or `Files.readString()` which handles encoding correctly
- Do not write unbuffered loops over `FileInputStream.read()`
  for large files

---

### 💻 Code Example

**Example 1: Correct vs incorrect file reading**

```java
// BAD: Unbuffered byte-by-byte read - O(n) system calls
try (InputStream in = new FileInputStream("large.bin")) {
    int b;
    while ((b = in.read()) != -1) {  // one syscall per byte!
        process((byte) b);
    }
}

// BAD: Forgetting to close (pre-try-with-resources anti-pattern)
InputStream in = new FileInputStream("file.bin");
try {
    process(in);
} finally {
    in.close();  // If process() throws and close() throws,
}                // the process() exception is silently suppressed

// GOOD: Buffered read with try-with-resources
try (InputStream in = new BufferedInputStream(
        new FileInputStream("large.bin"), 64 * 1024)) {  // 64KB buffer
    byte[] chunk = new byte[8192];
    int bytesRead;
    while ((bytesRead = in.read(chunk)) != -1) {
        process(chunk, bytesRead);
    }
}

// GOOD: For simple cases, use Files utility (Java 7+)
byte[] allBytes = Files.readAllBytes(Path.of("small.bin")); // loads fully
// For streaming large files, use Files.newInputStream():
try (InputStream in = Files.newInputStream(Path.of("large.bin"))) {
    // process in chunks
}
```

> **Code walkthrough:** The BAD unbuffered pattern generates one OS
> system call per byte - catastrophically slow for large files.
> The GOOD buffered pattern uses a 64KB buffer, reducing system
> calls by a factor of 65,536. The `Files` utility is the modern
> approach for simple cases. Note: `read(chunk)` may return fewer
> bytes than `chunk.length` - always use the returned `bytesRead`,
> not `chunk.length`, when processing the buffer.

**Example 2: Copying streams correctly**

```java
// GOOD: Efficient stream copy with fixed buffer
public static long copyStream(InputStream in, OutputStream out)
        throws IOException {
    byte[] buffer = new byte[8192];
    long totalBytes = 0;
    int bytesRead;
    while ((bytesRead = in.read(buffer)) != -1) {
        out.write(buffer, 0, bytesRead);  // write exactly bytesRead bytes
        totalBytes += bytesRead;
    }
    return totalBytes;
}

// Even simpler: Java 9+ InputStream.transferTo()
long transferred = inputStream.transferTo(outputStream);

// Java 7+: Files.copy for file-to-file
Files.copy(sourcePath, destPath, StandardCopyOption.REPLACE_EXISTING);
```

> **Code walkthrough:** Manual stream copy must pass the exact
> `bytesRead` count to `out.write()` - writing the full buffer
> when fewer bytes were read would corrupt the output with stale
> data. Java 9's `transferTo()` handles this correctly internally.
> For file-to-file copies, `Files.copy()` uses OS-level copy
> operations that are more efficient than Java-level byte transfers.

---

### ⚖️ Comparison

| Class | Data Type | Buffered | Use Case |
|-------|-----------|----------|----------|
| `FileInputStream` | bytes | no | Binary file source |
| `BufferedInputStream` | bytes | yes (8KB default) | Any byte source (wrap it!) |
| `DataInputStream` | typed primitives | no (wrap it!) | Binary protocol parsing |
| `FileReader` | chars | no | Text file source (wrap it!) |
| `BufferedReader` | chars | yes | Text line-by-line reading |
| `Files.newInputStream` | bytes | OS-buffered | Modern file byte streams |

**The deciding factor:** Always buffer. Byte streams for binary
data (images, serialized objects, protocols). Character streams
for text with encoding.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Java I/O splits into byte streams (`InputStream`/`OutputStream`)
> for binary data and character streams (`Reader`/`Writer`) for
> text. Always wrap with `Buffered*` to avoid per-byte system calls.
> Use try-with-resources to ensure streams are closed. For simple
> files, use `Files.readAllBytes()` or `Files.readString()`.

*Push deeper:* Why `InputStream.read()` returns int, not byte.

---

**Senior / Staff (5+ years):**

> In production I use the `Files` utility for simple cases and
> buffered streams for streaming. The performance difference between
> buffered and unbuffered I/O for large files is orders of
> magnitude. I configure buffer sizes explicitly (`64KB` instead
> of the default `8KB`) for high-throughput file processing. For
> network I/O, I use NIO2 with asynchronous channels for
> non-blocking operations.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between InputStream and Reader?"

🗣️ "`InputStream` reads raw bytes - the fundamental unit is a
byte (0-255). `Reader` reads characters - it decodes bytes using
a specified character encoding. Use `InputStream` for binary data
(images, serialized objects). Use `Reader` for text, and always
specify the encoding explicitly: `new InputStreamReader(in, StandardCharsets.UTF_8)`
rather than relying on the platform default."

#### Mechanism

- "Why does `InputStream.read()` return int instead of byte?"

🗣️ "Because Java's `byte` is signed (-128 to 127), and the end-
of-stream sentinel value is -1. If `read()` returned `byte`, the
value 255 (0xFF, valid byte) would be -1 as a signed byte - the
same as end-of-stream. By returning `int` (0-255 for data, -1
for end-of-stream), the API can distinguish 256 possible byte
values from the end-of-stream sentinel."

#### Debugging

- "Your file reading is very slow. What would you check?"

🗣️ "First: is it buffered? Wrapping with `BufferedInputStream`
and a larger buffer (64KB+) reduces system calls by orders of
magnitude. Second: are you reading one byte at a time in a loop
vs reading chunks? `read(byte[])` should be used, not `read()`
in a loop. Third: check the buffer size - the default 8KB is often
too small for high-throughput file processing. Fourth: for the
largest files, consider memory-mapped I/O via `FileChannel` and
`MappedByteBuffer`."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Hierarchy, buffering, int-not-byte rationale. |
| Hiring Manager   | Performance impact of unbuffered I/O. |
| Bar Raiser       | NIO channels, memory-mapped files, transferTo. |
| Peer Engineer    | "We profiled and 40% of time was in unbuffered read loops..." |

---

---

# Reader Writer and Buffered IO

**Interview Weight:** high - The character-stream complement to
byte streams. Interviewers probe for encoding awareness - the
most common I/O bug in Java.

---

### 🎯 Model Answer

**30 seconds:**

> `Reader`/`Writer` are the character-stream equivalents of
> `InputStream`/`OutputStream`. The critical difference: they
> handle character encoding - converting bytes to/from characters
> using a specified `Charset`. Always specify encoding explicitly
> (UTF-8) rather than relying on the platform default. Wrap with
> `BufferedReader`/`BufferedWriter` for efficient line-oriented
> text I/O. `Files.readString()` and `Files.writeString()` are the
> modern high-level alternatives for complete file reads.

**3 minutes (Senior):**

> The most common I/O bug in Java: using the default charset. If
> you construct `new FileReader("file.txt")` without specifying
> a charset, it uses `Charset.defaultCharset()`, which depends on
> the JVM locale setting. On Windows this might be Windows-1252;
> on Linux it is usually UTF-8. The same code behaves differently
> on different machines, causing garbled characters for non-ASCII
> content. The fix: always specify `StandardCharsets.UTF_8` or
> another explicit charset.
>
> `BufferedReader.readLine()` reads one line at a time, handling
> `\n`, `\r`, and `\r\n` line endings. For large files, reading
> line by line is memory-efficient - you only hold one line in
> memory. `Files.lines()` provides the same as a lazy `Stream<String>`
> that must be closed.
>
> `PrintWriter` is a `Writer` subclass with `println()` and `printf()`
> - convenient for human-readable output. It swallows exceptions
> (errors are tracked via `checkError()`), which is a design flaw
> - prefer `BufferedWriter` in production code where you need to
> handle I/O errors explicitly.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Reader, Writer, and
BufferedReader/BufferedWriter - the character-oriented I/O."

**(2) First principles:** "Text needs encoding/decoding between
bytes and characters. Character streams abstract this, handling
multi-byte encodings transparently."

---

### 📘 Concept Explanation

**What it is:**

`Reader`/`Writer`: abstract base for character-oriented I/O.
Key classes: `FileReader`/`FileWriter` (file text), `StringReader`/
`StringWriter` (in-memory), `InputStreamReader`/`OutputStreamWriter`
(bridge: converts byte streams to character streams with encoding),
`BufferedReader`/`BufferedWriter` (adds buffering + `readLine`).

**The key insight:**

`InputStreamReader` is the bridge from byte to character. By
combining it with `BufferedReader`, you get the full pipeline:
`new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8))`.
This is the safe, explicit way to read text from any byte stream.

**How it works:**

```
  Byte Stream              Character Stream
  ─────────────            ─────────────────
  InputStream       →     InputStreamReader  →  BufferedReader
  FileInputStream   →     FileReader          →  BufferedReader
  ByteArrayInputStream → StringReader (in-memory)

  bytes[...]  →  charset decode  →  char[...]  →  String (line)
```

---

### 💻 Code Example

**Example 1: Encoding-safe text reading**

```java
// BAD: Uses platform default charset - different on Windows vs Linux
try (Reader r = new FileReader("config.txt")) {
    // FileReader internally uses Charset.defaultCharset()
    // On Windows: Windows-1252; on Linux: UTF-8
    // Non-ASCII chars (UTF-8 encoded) read incorrectly on Windows
}

// GOOD: Explicit UTF-8 encoding
Path path = Path.of("config.txt");

// Modern approach (Java 11+): Files.readString / Files.lines
String content = Files.readString(path, StandardCharsets.UTF_8);

// Streaming approach for large files:
try (Stream<String> lines = Files.lines(path, StandardCharsets.UTF_8)) {
    lines.forEach(System.out::println);
}  // Stream.close() called - releases file handle

// Manual approach (needed for non-file InputStreams):
try (BufferedReader reader = new BufferedReader(
        new InputStreamReader(inputStream, StandardCharsets.UTF_8))) {
    String line;
    while ((line = reader.readLine()) != null) {
        processLine(line);
    }
}
```

> **Code walkthrough:** The BAD pattern uses the platform default
> charset - a portability bug waiting to happen. Non-ASCII content
> in a UTF-8 file reads as garbage on systems with a different
> default charset. The GOOD patterns explicitly specify
> `StandardCharsets.UTF_8`. `Files.lines()` returns a lazy stream
> that must be explicitly closed (use try-with-resources) to release
> the file handle.

**Example 2: Efficient text writing**

```java
// BAD: Unbuffered writes - one syscall per write call
try (Writer w = new FileWriter("output.txt", StandardCharsets.UTF_8)) {
    for (String line : lines) {
        w.write(line);
        w.write("\n");  // each write = one syscall
    }
}

// GOOD: Buffered writer with explicit flush
try (BufferedWriter writer = Files.newBufferedWriter(
        Path.of("output.txt"), StandardCharsets.UTF_8)) {
    for (String line : lines) {
        writer.write(line);
        writer.newLine();  // uses platform line separator
    }
    // flush() called automatically on close() via try-with-resources
}

// GOOD: For simple string content
Files.writeString(Path.of("output.txt"),
    String.join("\n", lines),
    StandardCharsets.UTF_8,
    StandardOpenOption.CREATE,
    StandardOpenOption.TRUNCATE_EXISTING);
```

> **Code walkthrough:** `Files.newBufferedWriter()` is the modern
> API: it creates an encoding-specified, buffered writer in one call.
> `newLine()` uses the platform line separator (`\r\n` on Windows,
> `\n` on Unix) which is correct for files that will be opened on
> the current platform. `Files.writeString()` is the simplest
> option for writing a complete string to a file.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Reader/Writer handle text with character encoding. Always specify
> the charset explicitly (UTF-8) - never use the default. Wrap with
> BufferedReader for line-by-line reading. Use `Files.readString()`
> and `Files.writeString()` for simple cases.

---

**Senior / Staff (5+ years):**

> The encoding bug is the most common text I/O issue in production.
> I enforce explicit UTF-8 charset in all text I/O through code
> review, and configure `-Dfile.encoding=UTF-8` on JVM startup
> to set the default for legacy code that does not specify it. For
> high-throughput text processing, `Files.lines()` as a parallel
> stream provides automatic parallelization with correct resource
> management.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between InputStream and Reader?"

🗣️ "The difference is byte vs character. InputStream reads raw
bytes. Reader reads characters, handling encoding: it knows how
to convert byte sequences to Java chars according to a charset.
Use Reader when the data is text and you need correct handling
of multi-byte encodings like UTF-8."

#### Debugging

- "Your application reads UTF-8 files correctly on Linux but
  shows garbled text on Windows. What is wrong?"

🗣️ "The application is using the platform default charset instead
of explicitly specifying UTF-8. On Linux, the default is usually
UTF-8; on Windows, it is often Windows-1252. The fix: wherever
a Reader or Writer is constructed, explicitly pass
`StandardCharsets.UTF_8`. For legacy code, add `-Dfile.encoding=UTF-8`
to the JVM startup args as a stopgap. In new code, always use
`Files.readString(path, StandardCharsets.UTF_8)` or
`new InputStreamReader(stream, StandardCharsets.UTF_8)`."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Encoding bridge (InputStreamReader), charset specification. |
| Hiring Manager   | Production encoding bugs, cross-platform behavior. |
| Bar Raiser       | Files.lines lazy stream lifecycle, parallel stream text processing. |
| Peer Engineer    | "The UTF-8 vs Windows-1252 bug showed up in production in week one..." |

---

---

# File and Path API: java.nio.file

**Interview Weight:** high - The modern file API since Java 7.
Interviewers test whether you know `Files` and `Path` vs the
deprecated `java.io.File`.

---

### 🎯 Model Answer

**30 seconds:**

> `java.nio.file.Path` and `Files` (Java 7+) replaced
> `java.io.File`. The old `File` API returned `false` silently
> on failure (e.g., `file.delete()` returns false instead of
> throwing). `Path` is a path representation; `Files` provides
> static utility methods that throw exceptions on failure. Key
> operations: `Files.exists()`, `Files.copy()`, `Files.move()`,
> `Files.delete()`, `Files.readAllBytes()`, `Files.writeString()`,
> `Files.walk()` for directory traversal.

**3 minutes (Senior):**

> The key API design improvement: `Files` methods throw `IOException`
> instead of returning `false`. Old `File.delete()` returns `false`
> and you have no idea why - permission denied? File does not exist?
> Directory not empty? `Files.delete()` throws a specific exception:
> `NoSuchFileException`, `DirectoryNotEmptyException`,
> `AccessDeniedException` - so you know exactly what failed.
>
> `Files.walk()` and `Files.find()` traverse directory trees lazily
> as `Stream<Path>`. They must be closed (use try-with-resources)
> because they hold a directory iterator. `Files.walkFileTree()` is
> the callback-based alternative when you need `FileVisitor`
> semantics (visited, failed, complete callbacks).
>
> For atomic file operations, use `Files.move()` with
> `StandardCopyOption.ATOMIC_MOVE`. For copy with metadata
> preservation, use `COPY_ATTRIBUTES`. File attributes (creation
> time, owner, permissions) are accessed via `Files.getAttribute()`
> or `Files.readAttributes(BasicFileAttributes.class)`.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the modern Java file API -
Path and Files from java.nio.file."

**(2) First principles:** "Any file API needs: path representation,
read/write, metadata access, and directory traversal. The old
java.io.File had all of these but with a terrible error reporting
design."

---

### 📘 Concept Explanation

**What it is:**

`java.nio.file` (NIO.2, Java 7): `Path` represents a file system
path (replacing `java.io.File`). `Files` provides static methods
for file operations. `Paths` and `Path.of()` construct Path instances.
`FileSystem` abstracts different file system implementations.

**How it works:**

```java
// Path construction
Path p = Path.of("/home/user/data.txt");
Path relative = Path.of("data", "config.txt");  // path joining
Path resolved = base.resolve("subdir/file.txt");
Path normalized = p.normalize();  // removes ./ and ../

// File operations - throw IOException on failure
Files.createDirectories(Path.of("a/b/c"));  // mkdir -p equivalent
Files.copy(src, dst, StandardCopyOption.REPLACE_EXISTING);
Files.move(src, dst, StandardCopyOption.ATOMIC_MOVE);
Files.delete(p);                 // throws NoSuchFileException if absent
Files.deleteIfExists(p);         // no-op if absent (returns boolean)

// Read/write
byte[]   bytes   = Files.readAllBytes(p);
String   text    = Files.readString(p, UTF_8);
List<String> lines = Files.readAllLines(p, UTF_8);
Files.write(p, bytes);
Files.writeString(p, "content", UTF_8);

// Directory traversal - MUST close the stream
try (Stream<Path> paths = Files.walk(dir, Integer.MAX_VALUE)) {
    paths.filter(Files::isRegularFile)
         .filter(f -> f.toString().endsWith(".java"))
         .forEach(System.out::println);
}
```

**The key insight:**

`java.io.File` methods return `boolean` on failure - you lose
the reason. `java.nio.file.Files` throws specific IOExceptions.
This is the core reason to prefer the new API: error diagnosis
is vastly better.

---

### 💻 Code Example

**Example 1: Directory traversal and file processing**

```java
// Count lines in all .java files in a directory tree
Path rootDir = Path.of("src/main/java");

long totalLines;
try (Stream<Path> files = Files.walk(rootDir)) {
    totalLines = files
        .filter(Files::isRegularFile)
        .filter(p -> p.toString().endsWith(".java"))
        .mapToLong(p -> {
            try {
                return Files.lines(p).count();
            } catch (IOException e) {
                return 0;
            }
        })
        .sum();
}
System.out.printf("Total Java lines: %,d%n", totalLines);

// Watch a directory for changes (Java 7+ WatchService)
WatchService watcher = FileSystems.getDefault().newWatchService();
rootDir.register(watcher,
    StandardWatchEventKinds.ENTRY_CREATE,
    StandardWatchEventKinds.ENTRY_MODIFY,
    StandardWatchEventKinds.ENTRY_DELETE);

WatchKey key = watcher.take();  // blocks until an event
for (WatchEvent<?> event : key.pollEvents()) {
    Path changed = (Path) event.context();
    System.out.println(event.kind() + ": " + changed);
}
key.reset();
```

> **Code walkthrough:** `Files.walk()` returns a lazy `Stream<Path>`
> - the directory is traversed on-demand as elements are consumed.
> Closing the stream (try-with-resources) releases the directory
> iterator. `Files.lines()` inside the map also returns a lazy
> stream - in this example it is consumed immediately by `count()`,
> but in production code you would also need to close it.
> `WatchService` provides OS-level file system events - much more
> efficient than polling.

**Example 2: Old File vs new Path**

```java
// BAD: java.io.File - silent failures
File f = new File("/path/to/file.txt");
if (!f.delete()) {
    // Why? Permission denied? Not found? Not empty?
    // Cannot tell without additional checks
    System.err.println("Delete failed (reason unknown)");
}
boolean created = new File("/a/b/c").mkdirs();  // silent false on error

// GOOD: java.nio.file.Files - throws specific exceptions
try {
    Files.delete(Path.of("/path/to/file.txt"));
} catch (NoSuchFileException e) {
    logger.warn("File not found: {}", e.getFile());
} catch (DirectoryNotEmptyException e) {
    logger.warn("Directory not empty: {}", e.getFile());
} catch (AccessDeniedException e) {
    logger.error("Permission denied: {}", e.getFile());
}

// Or: no-op if not present (explicit intent)
boolean wasDeleted = Files.deleteIfExists(Path.of("/path/to/file.txt"));

// Create directories - throws IOException with reason on failure
Files.createDirectories(Path.of("/a/b/c"));
```

> **Code walkthrough:** The `File.delete()` silent false return is
> the canonical example of the old API's design flaw. `Files.delete()`
> throws specific checked exceptions that tell you exactly why the
> operation failed. `deleteIfExists()` is the "POSIX unlink"
> equivalent - it is not an error if the file was already absent.

---

### ⚖️ Comparison

| API | Error Handling | Features | Use When |
|-----|---------------|----------|----------|
| `java.io.File` | returns false | basic file ops | Legacy code only |
| `java.nio.file.Files` | throws IOException | full modern API | All new code |
| `Files.walkFileTree()` | FileVisitor callbacks | tree with lifecycle | Complex traversal |
| `Files.walk()` | lazy Stream | simple traversal | Most traversal |

**The deciding factor:** Always use `java.nio.file` in new code.
Convert `File` to `Path` with `file.toPath()` when bridging.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Use `java.nio.file.Path` and `Files` in new code. The old
> `java.io.File` is legacy. `Files` methods throw meaningful
> exceptions instead of returning false. Key operations: `exists()`,
> `copy()`, `move()`, `delete()`, `readString()`, `writeString()`,
> `walk()`.

---

**Senior / Staff (5+ years):**

> The `WatchService` is the production choice for file change
> notification - polling is wasteful. For atomic file writes (no
> partial files on crash), write to a temp file and then
> `Files.move(tmp, target, ATOMIC_MOVE)`. For large directory
> trees, `Files.walk()` with `maxDepth` avoids infinite recursion
> from symlinks. On high-throughput file processing, memory-mapped
> I/O via `FileChannel.map()` bypasses Java heap allocation.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What replaced `java.io.File` in Java 7?"

🗣️ "`java.nio.file.Path` and the `Files` utility class replaced
`java.io.File`. The key improvement: `Files` methods throw specific
`IOException` subclasses instead of returning `false` on failure.
`File.delete()` returns `false` and you do not know why; `Files.delete()`
throws `NoSuchFileException`, `DirectoryNotEmptyException`, or
`AccessDeniedException` so you know exactly what went wrong."

#### Debugging

- "Your application is not releasing file handles and eventually
  runs out of file descriptors. What is the cause?"

🗣️ "The most common cause: `Files.lines()` or `Files.walk()` streams
were not closed. These hold open file handles and must be explicitly
closed via try-with-resources. `Files.readAllBytes()` and
`Files.readString()` close the file handle internally. Any code
that opens a `Stream<Path>` from `Files.walk()` and does not close
it leaks a file descriptor."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Path vs File API, specific exceptions, walk() lifecycle. |
| Hiring Manager   | File descriptor leak - production impact. |
| Bar Raiser       | WatchService, atomic move, memory-mapped I/O. |
| Peer Engineer    | "The files.walk without close leaked handles in our batch job..." |

---

---

# NIO Channels Buffers and Selectors

**Interview Weight:** high - Tested at senior level for high-
throughput server development. NIO is the foundation of Netty,
embedded Tomcat, and all high-performance Java networking.

---

### 🎯 Model Answer

**30 seconds:**

> Java NIO (New I/O, Java 1.4) introduced non-blocking I/O for
> network servers. Three core abstractions: `Channel` (bidirectional
> I/O endpoint - replaces streams), `Buffer` (direct memory block
> for I/O data), `Selector` (event demultiplexer - monitors multiple
> channels on a single thread). Together they enable thousands of
> concurrent connections on a single thread, unlike traditional I/O
> which requires one thread per connection.

**3 minutes (Senior):**

> Traditional blocking I/O requires a thread per connection. For
> 10,000 concurrent connections, you need 10,000 threads - each
> consuming ~1MB of stack, ~10GB total. NIO with a Selector runs
> 10,000 connections on a single thread: the selector multiplexes
> I/O events, and the thread only processes connections that have
> data ready.
>
> The `Buffer` pattern is different from streams. Buffers have a
> `position`, `limit`, and `capacity`. After writing data to a
> buffer, you call `flip()` to switch from write to read mode
> (sets limit = position, position = 0). After reading, call
> `clear()` or `compact()` to prepare for the next write. Forgetting
> `flip()` is the most common NIO bug - you read back garbage.
>
> `FileChannel` with `transferTo()`/`transferFrom()` enables zero-
> copy file transfer by delegating to the OS's sendfile() system
> call - avoiding the user-space byte copy entirely. This is how
> Kafka achieves high-throughput log transfer.
>
> In modern Java (21+), virtual threads (Project Loom) make blocking
> I/O NIO-equivalent for most use cases: you can write blocking-
> style code with millions of virtual threads. NIO with Selectors
> is still relevant for performance-critical networking code that
> needs fine-grained control.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Java NIO - channels,
buffers, and selectors for non-blocking I/O."

**(2) First principles:** "Traditional I/O blocks the calling
thread. For servers handling many connections, blocking per-
connection requires per-thread overhead. NIO avoids this by
using event-driven multiplexing."

---

### 📘 Concept Explanation

**What it is:**

`java.nio` (Java 1.4): `Channel` (full-duplex I/O endpoint),
`Buffer` (typed in-memory I/O buffer), `Selector` (select()-based
event multiplexer). Key channel types: `FileChannel`, `SocketChannel`,
`ServerSocketChannel`, `DatagramChannel`.

**How it works:**

```
  Thread
    │
  Selector (select() call - blocks until event)
    │
  ┌─────────────────────────────────────┐
  │  SelectionKey  SelectionKey  Key... │
  │  SocketChannel  SocketChannel  ...  │
  │  (ACCEPT) (READ) (WRITE) ...        │
  └─────────────────────────────────────┘

  Buffer lifecycle:
    [capacity=8, limit=8, pos=0]  ← initial (write mode)
    write data → pos=5
    flip() → [limit=5, pos=0]     ← read mode
    read data → pos=5
    clear() → [limit=8, pos=0]    ← write mode again
```

**The key insight:**

`Buffer.flip()` is the critical transition from write mode to read
mode. The channel writes into the buffer (position advances).
When you want to read back what was written, `flip()` sets
`limit = current position, position = 0`. Forgetting `flip()`
means reading from position to capacity - reading unwritten bytes.

---

### 💻 Code Example

**Example 1: Non-blocking server with Selector**

```java
// Non-blocking echo server - handles multiple clients, one thread
ServerSocketChannel server = ServerSocketChannel.open();
server.bind(new InetSocketAddress(8080));
server.configureBlocking(false);

Selector selector = Selector.open();
server.register(selector, SelectionKey.OP_ACCEPT);

ByteBuffer buffer = ByteBuffer.allocate(256);

while (true) {
    selector.select();  // blocks until at least one event
    Set<SelectionKey> readyKeys = selector.selectedKeys();
    Iterator<SelectionKey> iter = readyKeys.iterator();

    while (iter.hasNext()) {
        SelectionKey key = iter.next();
        iter.remove();  // REQUIRED: remove key from selected set

        if (key.isAcceptable()) {
            SocketChannel client = server.accept();
            client.configureBlocking(false);
            client.register(selector, SelectionKey.OP_READ);

        } else if (key.isReadable()) {
            SocketChannel client = (SocketChannel) key.channel();
            buffer.clear();                // prepare for write
            int bytesRead = client.read(buffer);
            if (bytesRead == -1) {
                client.close();
            } else {
                buffer.flip();             // switch to read mode
                client.write(buffer);      // echo back
            }
        }
    }
}
```

> **Code walkthrough:** The Selector monitors all registered channels.
> `selector.select()` blocks until at least one channel has an event.
> The key patterns: (1) always `iter.remove()` after processing a
> key - it stays in `selectedKeys()` forever otherwise. (2) `buffer.clear()`
> before reading from a channel (write mode), `buffer.flip()` before
> writing to a channel (read mode). Missing either flip or clear
> produces silent data corruption.

**Example 2: Zero-copy file transfer**

```java
// GOOD: Zero-copy file-to-socket transfer (sendfile syscall)
// Used in Kafka, Netty, high-throughput file servers
try (FileChannel fileChannel = FileChannel.open(Path.of("largefile.bin"));
     SocketChannel socketChannel = SocketChannel.open(remoteAddress)) {

    long transferred = fileChannel.transferTo(
        0,                        // start position
        fileChannel.size(),       // total bytes
        socketChannel             // destination
    );
    System.out.println("Transferred " + transferred + " bytes (zero-copy)");
}
// The OS copies directly from file page cache to socket buffer
// No bytes pass through the JVM heap at all
```

> **Code walkthrough:** `FileChannel.transferTo()` delegates to the
> OS `sendfile()` system call on Linux (and equivalent on other OS).
> The data moves from the file's page cache directly to the socket
> buffer without copying through the JVM heap. For a 1GB file,
> traditional `InputStream → OutputStream` copy would allocate
> and copy 1GB through the Java heap. `transferTo()` copies zero
> bytes through Java - the JVM only orchestrates the OS operation.

---

### ⚖️ Comparison

| Approach | Threads | Model | Best For |
|----------|---------|-------|----------|
| Blocking IO (InputStream) | 1 per connection | Sequential | Simple apps, low concurrency |
| NIO + Selector | 1 for many | Event-driven | High-concurrency servers (Netty) |
| Virtual Threads (Java 21) | 1 per connection (virtual) | Sequential-looking | Modern high-concurrency apps |
| Async NIO (`AsynchronousSocketChannel`) | Few OS threads | Callback/Future | Ultra-low-latency systems |

**The deciding factor:** Virtual threads (Java 21+) make NIO
Selectors unnecessary for most new code. Use NIO Selectors
for performance-critical networking in pre-Java 21 environments
or when you need fine-grained buffer control.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> NIO provides non-blocking I/O. Key abstractions: Channel
> (bidirectional I/O endpoint), Buffer (memory block for data),
> Selector (monitors many channels on one thread). It enables
> servers that handle thousands of connections without thousands
> of threads. Most developers use Netty or other frameworks built
> on NIO rather than NIO directly.

*Push deeper:* Buffer's flip()/clear() lifecycle.

---

**Senior / Staff (5+ years):**

> NIO is the foundation of every high-performance Java network
> framework (Netty, Vert.x, embedded Tomcat). The Selector pattern
> is the Java implementation of the reactor pattern. In Java 21+,
> virtual threads provide a simpler alternative for most use cases -
> blocking I/O on a virtual thread is actually NIO under the hood,
> managed by the JVM. I still use `FileChannel.transferTo()` for
> zero-copy file serving regardless of Java version - that is an
> OS-level optimization that virtual threads do not change.

*Push deeper:* Direct ByteBuffers (`allocateDirect()`) that use
off-heap memory, `AsynchronousSocketChannel` for completion-port
model, and how Netty abstracts the Channel/Selector model.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is NIO and how does it differ from traditional I/O?"

🗣️ "NIO (New I/O) provides non-blocking I/O with three main
abstractions: Channels (bidirectional I/O endpoints), Buffers
(typed memory blocks for I/O data), and Selectors (event
multiplexers). Traditional I/O is stream-based and blocking -
each read blocks the calling thread. NIO Selectors allow one
thread to monitor thousands of channels and only process those
with data ready. This is how Netty handles millions of concurrent
connections."

#### Mechanism

- "What does Buffer.flip() do and why is it necessary?"

🗣️ "`flip()` switches a Buffer from write mode to read mode.
After writing data into a buffer (filling from position 0 onward),
`position` is at the end of the written data. `flip()` sets
`limit = position` and `position = 0` - now you can read from
the beginning of the written data up to the limit. Without `flip()`,
reading starts from the current position (end of data) and reads
until capacity - giving you empty/garbage bytes."

#### Performance and Scalability

- "How would you serve a large file from a Java server with
  minimal CPU overhead?"

🗣️ "`FileChannel.transferTo()` is the answer. It delegates to the
OS `sendfile()` system call, which transfers data directly from
the file's page cache to the socket buffer without copying through
the JVM heap. For a 1GB file, this means zero bytes pass through
Java memory. Traditional `InputStream`/`OutputStream` copy would
allocate and copy 1GB through the heap, generating GC pressure.
`transferTo()` is why Kafka can sustain Gbps log replication
on modest hardware."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Buffer flip/clear lifecycle, Selector pattern. |
| Hiring Manager   | Connection scalability - threads vs selectors. |
| Bar Raiser       | Virtual threads vs NIO, zero-copy, direct buffers. |
| Peer Engineer    | "Forgetting iter.remove() in the selector loop cost us an hour..." |

---

---

# try-with-resources and AutoCloseable

**Interview Weight:** high - Critical for correct resource
management. Interviewers test for knowledge of suppressed
exceptions and the AutoCloseable contract.

---

### 🎯 Model Answer

**30 seconds:**

> `try-with-resources` (Java 7) automatically closes resources
> that implement `AutoCloseable` (or `Closeable`) at the end of
> the try block - even if an exception is thrown. Resources are
> closed in reverse declaration order. If both the try body and
> `close()` throw, the close exception is attached as a suppressed
> exception to the primary exception - nothing is silently lost.
> This replaces the error-prone manual try/finally pattern.

**3 minutes (Senior):**

> The critical improvement over try/finally: suppressed exceptions.
> In the old pattern:
> ```java
> try { doWork(); } finally { resource.close(); }
> ```
> If both `doWork()` and `resource.close()` throw, the `close()`
> exception propagates and the `doWork()` exception is silently
> discarded. This has caused lost exceptions in production that
> hide the real root cause of failures.
>
> try-with-resources preserves both exceptions. The primary exception
> (from the try body) propagates; the `close()` exception is attached
> as a suppressed exception via `addSuppressed()`. You can retrieve
> them with `e.getSuppressed()`.
>
> Multiple resources are closed in reverse declaration order - the
> last declared resource is closed first. This is the correct order
> when resources wrap each other (close the outer wrapper before
> the inner source). Implementing `AutoCloseable` requires a
> single `close()` method that should be idempotent (safe to call
> multiple times). `Closeable` extends `AutoCloseable` and restricts
> `close()` to throw only `IOException`.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about try-with-resources and how
it handles resource cleanup safely."

**(2) First principles:** "Resources (file handles, connections,
streams) must be released when no longer needed. Manual tracking
with finally blocks loses exceptions when both the body and cleanup
throw. try-with-resources is the language-level solution."

---

### 📘 Concept Explanation

**What it is:**

`try-with-resources` (Java 7): automatically calls `close()` on
`AutoCloseable` resources declared in the try header. `AutoCloseable`
is the minimal interface: `void close() throws Exception`.
`Closeable` (used by I/O) extends `AutoCloseable` with `throws IOException`.

**How it works:**

```java
// Equivalent bytecode expansion of try-with-resources:
// try (Resource r = new Resource()) { body; }
// expands to approximately:
Resource r = new Resource();
Throwable primaryEx = null;
try {
    body;
} catch (Throwable t) {
    primaryEx = t;
    throw t;
} finally {
    if (primaryEx != null) {
        try {
            r.close();
        } catch (Throwable suppressed) {
            primaryEx.addSuppressed(suppressed);  // attached, not lost
        }
    } else {
        r.close();  // close normally, exception propagates if thrown
    }
}
```

**The key insight:**

Multiple resources are closed in reverse order. `try (A a = new A(); B b = new B())` closes `b` first, then `a`. This is the correct order when `b` wraps `a` - close the wrapper before the wrapped.

**When to use it:**

- Any class that implements `Closeable` or `AutoCloseable`:
  streams, readers/writers, connections, channels, statements,
  result sets, `WatchService`, `Selector`, `ZipFile`
- Custom resources that hold OS handles, locks, or external
  connections
- Any object you need cleaned up on exception paths

**When NOT to use it:**

- Objects that do not hold external resources and whose `close()`
  is purely a no-op or flag-set - try-with-resources adds
  unnecessary boilerplate
- Very long-lived resources that span multiple methods - these
  should be managed at the service lifecycle level, not in
  a local try block

---

### 💻 Code Example

**Example 1: Multiple resources and suppressed exceptions**

```java
// GOOD: Multiple resources - closed in reverse order (b first, then a)
try (FileInputStream  a = new FileInputStream("input.txt");
     GZIPOutputStream b = new GZIPOutputStream(
                              new FileOutputStream("output.gz"))) {
    a.transferTo(b);    // Java 9+ InputStream.transferTo()
}
// b.close() called first (correct: closes GZIP wrapper before file)
// a.close() called second

// Recovering suppressed exceptions in catch blocks
try (Connection conn = dataSource.getConnection();
     PreparedStatement stmt = conn.prepareStatement(sql)) {
    return stmt.executeQuery();
} catch (SQLException e) {
    // Check if close() also threw and log it
    for (Throwable suppressed : e.getSuppressed()) {
        logger.warn("Suppressed exception during close: {}", suppressed.getMessage());
    }
    throw new DatabaseException("Query failed", e);
}

// BAD: Old try/finally pattern - loses one exception
Connection conn = dataSource.getConnection();
try {
    return conn.createStatement().executeQuery(sql);
} finally {
    conn.close();  // if executeQuery() threw AND close() throws,
                   // executeQuery's exception is silently discarded!
}
```

> **Code walkthrough:** Resources are closed in reverse order -
> `GZIPOutputStream` before `FileInputStream` - correct for wrapped
> streams. The suppressed exception handling is production-essential:
> if a database query fails and connection close also fails, you
> want to log both. The old try/finally discards the query exception
> if close throws; try-with-resources attaches it as suppressed.

**Example 2: Custom AutoCloseable resource**

```java
// Custom resource with idempotent close
public class DatabaseLock implements AutoCloseable {
    private final String lockName;
    private boolean released = false;

    public DatabaseLock(DataSource ds, String lockName)
            throws SQLException {
        this.lockName = lockName;
        acquireLock(ds, lockName);
    }

    @Override
    public void close() {  // idempotent: safe to call multiple times
        if (!released) {
            released = true;
            releaseLock(lockName);
        }
    }
}

// Usage: lock automatically released even if processing throws
try (DatabaseLock lock = new DatabaseLock(ds, "order-" + orderId)) {
    processOrder(orderId);
}  // lock.close() guaranteed to be called

// BAD: Without AutoCloseable, manual release is error-prone
DatabaseLock lock = new DatabaseLock(ds, "order-" + orderId);
try {
    processOrder(orderId);
} finally {
    lock.release();  // What if processOrder() threw and release() also throws?
}
```

> **Code walkthrough:** `DatabaseLock` implements `AutoCloseable`
> with an idempotent `close()` - calling it twice is safe because
> the `released` flag prevents double-release. The try-with-resources
> guarantees `close()` is called even if `processOrder()` throws,
> eliminating resource leaks that the manual pattern misses.

---

### ⚖️ Comparison

| Approach | Exception Safety | Code Complexity | Suppressed Exceptions |
|----------|-----------------|-----------------|----------------------|
| Manual try/finally | partial (one exception lost) | high | lost |
| try-with-resources | full | minimal | preserved |
| `@Cleanup` (Lombok) | full (compile-time) | minimal | preserved |

**The deciding factor:** Always use try-with-resources for any
`AutoCloseable`. Manual try/finally is only needed for complex
multi-step release logic that requires custom ordering beyond
simple close calls.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> try-with-resources automatically closes resources that implement
> AutoCloseable at the end of the block, even if an exception is
> thrown. Resources are declared in parentheses after `try`. It
> replaces the error-prone try/finally pattern for resource cleanup.

*Push deeper:* What happens when both the body and close() throw.

---

**Senior / Staff (5+ years):**

> The key production advantage of try-with-resources over try/
> finally is suppressed exception preservation. I have diagnosed
> production bugs where a database connection's `close()` was
> throwing but the application was silently swallowing the real
> exception from the query. try-with-resources attaches both -
> you see the real failure. I enforce try-with-resources for all
> `AutoCloseable` resources in code reviews and use static analysis
> (Checkstyle, SpotBugs) to catch violations.

*Push deeper:* `@SneakyThrows` (Lombok) and `AutoCloseable`
vs `Closeable` contract differences, and why `AutoCloseable.close()`
can throw any `Exception` while `Closeable.close()` restricts to
`IOException`.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is try-with-resources?"

🗣️ "try-with-resources (Java 7) is a language feature that
automatically calls `close()` on resources implementing `AutoCloseable`
at the end of a try block. Resources declared in the try header
are guaranteed to be closed - in reverse order - regardless of
whether an exception was thrown. If both the try body and a
`close()` call throw, the close exception is stored as a suppressed
exception on the primary exception rather than silently discarded."

#### Mechanism

- "What is a suppressed exception?"

🗣️ "A suppressed exception is one that was thrown during the
cleanup of a try-with-resources block (in a `close()` call), while
a primary exception was already propagating. Instead of discarding
one exception or the other, Java attaches the secondary (close)
exception to the primary exception via `addSuppressed()`. Callers
can retrieve all suppressed exceptions with `e.getSuppressed()`.
This preserves the full failure picture and is a significant
improvement over the old try/finally pattern."

#### Debugging

- "Your application is showing OOM errors about too many open
  file handles. What would you look for?"

🗣️ "I would look for `Stream<Path>` from `Files.walk()` or
`Files.lines()` that are not being closed. These hold open file
descriptors. The pattern: any stream that wraps a file or directory
iterator must be in a try-with-resources block. A `Files.lines(path)`
that is assigned to a field or passed through multiple methods
without explicit close will leak. I would use a profiler (JFR,
async-profiler) to get file descriptor allocation stack traces,
then add the missing try-with-resources."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | AutoCloseable contract, suppressed exceptions, reverse-close order. |
| Hiring Manager   | Resource leak prevention - production reliability. |
| Bar Raiser       | Closeable vs AutoCloseable, idempotent close, @SneakyThrows. |
| Peer Engineer    | "Suppressed exceptions saved us in diagnosing a DB connection pool issue..." |
