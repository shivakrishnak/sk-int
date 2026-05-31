---
layout: default
title: "Node.js - L1 File System and Streams"
parent: "Node.js"
nav_order: 3
permalink: /nodejs/l1-file-system-streams/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [File System API (fs)](#file-system-api-fs) | medium |
| 2 | [Streams and Piping](#streams-and-piping) | medium |
| 3 | [Buffer and Encoding](#buffer-and-encoding) | medium |

---

# File System API (fs)

---

### 🎯 Model Answer

**30 seconds:**

> The `fs` module is Node.js's file system API. It comes in three
> forms: callback-based (`fs.readFile`), promise-based (`fs.promises.readFile`),
> and synchronous (`fs.readFileSync`). Use promises/async-await for
> application code, never synchronous methods in servers (they block
> the event loop). Common operations: read, write, append, delete,
> mkdir, stat, watch. `fs.promises` is the modern API for all new code.

**Blank Mind Recovery:**

**(1) Three APIs:** "Callbacks (old). `fs.promises` (modern). `*Sync`
(scripts only, never in servers)."

**(2) Common operations:** "readFile, writeFile, appendFile, unlink
(delete), mkdir, stat, readdir."

**(3) Rule:** "Never `*Sync` in HTTP request handlers - blocks event loop."

---

### 📘 Concept Explanation

**What it is:**

The built-in Node.js module for interacting with the file system:
reading, writing, watching, and managing files and directories.

**How it works:**

```
fs module APIs:

  Three API styles:
    1. fs (callback): fs.readFile(path, options, callback)
    2. fs.promises: await fs.promises.readFile(path, options)
    3. fs (sync): fs.readFileSync(path, options) - BLOCKS

  Common operations:
    Read file:
      const data = await readFile('file.txt', 'utf8');

    Write file (overwrite):
      await writeFile('out.txt', 'content', 'utf8');

    Append to file:
      await appendFile('log.txt', 'new line\n', 'utf8');

    Delete file:
      await unlink('temp.txt');

    Create directory:
      await mkdir('dist/assets', { recursive: true });

    List directory:
      const files = await readdir('./src');

    File metadata:
      const stats = await stat('file.txt');
      stats.size         // bytes
      stats.isDirectory() // boolean
      stats.mtime        // last modified Date

    Check existence:
      try {
        await access('file.txt', fs.constants.F_OK);
      } catch {
        // file does not exist
      }

    Watch for changes:
      fs.watch('config.json', (eventType, filename) => {
        console.log(`${filename} changed: ${eventType}`);
      });

  When to use sync APIs (fs.*Sync):
    - CLI scripts (not servers)
    - Config loading at startup (before server starts)
    - Build scripts
    Never in:
    - HTTP request handlers
    - Async middleware
    - Anywhere the event loop must remain available
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Production) - File operations with error handling:**

```javascript
import {
  readFile, writeFile, mkdir, stat, unlink
} from 'fs/promises';
import { join } from 'path';

// Read JSON config safely:
async function loadConfig(configPath) {
  try {
    const raw = await readFile(configPath, 'utf8');
    return JSON.parse(raw);
  } catch (err) {
    if (err.code === 'ENOENT') {
      return {}; // file doesn't exist, return defaults
    }
    if (err instanceof SyntaxError) {
      throw new Error(
        `Invalid JSON in ${configPath}: ${err.message}`
      );
    }
    throw err;
  }
}

// Write file atomically (temp file + rename):
async function atomicWrite(targetPath, content) {
  const tmpPath = targetPath + '.tmp';
  await writeFile(tmpPath, content, 'utf8');
  // rename is atomic on POSIX systems:
  await import('fs').then(fs =>
    fs.promises.rename(tmpPath, targetPath)
  );
}

// Ensure directory exists before writing:
async function ensureDir(filePath) {
  const dir = join(filePath, '..');
  await mkdir(dir, { recursive: true });
}

// Common error codes:
// ENOENT - no such file or directory
// EACCES - permission denied
// EEXIST - file already exists
// EISDIR - is a directory (can't read as file)
// EMFILE - too many open files (OS limit)
```

> **Code walkthrough:** `loadConfig` shows defensive file reading:
> catching `ENOENT` (file not found) and returning defaults rather than
> crashing is the right default for optional config files. Parsing errors
> are re-thrown with context. `atomicWrite` solves a real production
> problem: writing to a file directly means a crash mid-write leaves a
> partial/corrupt file. Writing to a temp file then atomically renaming
> ensures readers see either the old or the new complete file. `mkdir`
> with `{ recursive: true }` creates the full directory path without
> throwing if it already exists - the idiomatic way to ensure a directory.

---

### ⚖️ Comparison Table

| API | Use case | Blocks event loop |
|---|---|---|
| `fs.readFile()` + callback | Legacy code | No |
| `fs.promises.readFile()` | Modern app code | No |
| `fs.readFileSync()` | CLI scripts, startup | Yes |
| `fs.createReadStream()` | Large files | No |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I use `fs.promises` for file operations. `readFile` reads a file,
> `writeFile` writes, `mkdir` creates directories. I always use
> `{ recursive: true }` with `mkdir` to avoid errors if the directory
> exists. I never use synchronous methods like `readFileSync` in
> server request handlers because they block the event loop.

**Senior / Staff:**

> The `fs.promises` API is the right choice for all new code. For
> high-throughput logging or large file processing, streams are more
> appropriate than `readFile`/`writeFile`. `readFile` loads the entire
> file into memory - a 1GB log file would consume 1GB of RAM. Streams
> process it in chunks. For config loading at startup, `readFileSync`
> is acceptable because the event loop isn't serving requests yet.
> Watch out for `EMFILE` (too many open files) in production - use
> a semaphore to limit concurrency when processing many files.

---

### ⚠️ Common Misconceptions

**Misconception: `fs.promises.access()` is the right way to check if a file exists.**

The `access()` pattern has a TOCTOU (time-of-check time-of-use) race:
between checking and using the file, it could be deleted. Better: just
try the operation and handle `ENOENT` in the catch block.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `EMFILE: too many open files` under load.**

Cause: Server opens many files concurrently without closing them,
hitting OS limit (default ~1024 on Linux).

Fix: Use a concurrency limiter (p-limit, async-sema).
```javascript
import pLimit from 'p-limit';
const limit = pLimit(10); // max 10 concurrent file ops
await Promise.all(
  files.map(f => limit(() => readFile(f)))
);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| fs callback vs fs.promises vs sync - which to use? | Decision | ★☆☆ | 2 min |
| Why not use `readFileSync` in request handlers? | Mechanism | ★★☆ | 2 min |
| How do you write a file atomically? | Production | ★★★ | 3 min |
| What is `ENOENT` and how do you handle it? | Debugging | ★☆☆ | 1 min |

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


# Streams and Piping

---

### 🎯 Model Answer

**30 seconds:**

> Streams are Node.js's abstraction for processing data incrementally
> as it arrives rather than loading everything into memory. Four types:
> Readable (source), Writable (destination), Duplex (both), Transform
> (transform data in transit). Key: pipe connects them. `readable.pipe(writable)`.
> Use streams for large files, HTTP bodies, video streaming, CSV
> processing. A 1GB file processed as a stream uses kilobytes of memory.
> Without streams, it uses 1GB.

**Blank Mind Recovery:**

**(1) What:** "Process data as chunks. Not all at once. Memory-efficient."

**(2) Four types:** "Readable, Writable, Duplex, Transform."

**(3) Why:** "1GB file -> 1GB RAM without streams. With streams -> 64KB."

---

### 📘 Concept Explanation

**What it is:**

An abstract interface for working with streaming data - data that
arrives or is processed incrementally rather than all at once.

**How it works:**

```
Stream types and data flow:

  Readable stream:
    Source of data: fs.createReadStream(), http.IncomingMessage,
    process.stdin, crypto.createHash()
    Events: 'data', 'end', 'error'
    Modes: flowing (data events) and paused (read on demand)

  Writable stream:
    Destination: fs.createWriteStream(), http.ServerResponse,
    process.stdout
    Methods: write(), end()
    Events: 'finish', 'error', 'drain'

  Duplex stream:
    Both readable and writable: net.Socket, TLS streams

  Transform stream:
    Processes data: zlib.createGzip(), crypto.createCipher(),
    custom CSV parsers, protocol codecs

  Piping:
    source.pipe(transform).pipe(destination)

    readStream
      .pipe(gzip)          // compress
      .pipe(encrypt)       // encrypt
      .pipe(writeStream)   // save to disk

  Backpressure:
    When write is slower than read, buffer fills up.
    pipe() handles backpressure automatically:
    - pauses readable when writable buffer is full
    - resumes when writable drains

  Memory usage comparison:
    Without streams:
      const data = await readFile('1gb.log'); // 1GB in RAM
      process(data);

    With streams:
      const readable = createReadStream('1gb.log');
      // processes 64KB chunks, ~64KB in RAM at any time
      for await (const chunk of readable) {
        process(chunk);
      }
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Production) - File processing with streams:**

```javascript
import { createReadStream, createWriteStream } from 'fs';
import { createGzip } from 'zlib';
import { pipeline } from 'stream/promises';

// BAD: load entire file then compress:
import { readFile, writeFile } from 'fs/promises';
const data = await readFile('large.csv'); // loads all into memory
await writeFile('large.csv.gz', gzipSync(data)); // again in memory

// GOOD: stream compression - constant memory usage:
await pipeline(
  createReadStream('large.csv'),
  createGzip(),              // Transform stream
  createWriteStream('large.csv.gz')
);
// Memory: ~64KB chunk buffer regardless of file size

// Custom Transform stream - CSV line counter:
import { Transform } from 'stream';

class LineCounter extends Transform {
  constructor() {
    super({ readableObjectMode: true });
    this._lineCount = 0;
    this._remainder = '';
  }

  _transform(chunk, encoding, callback) {
    const data = this._remainder + chunk.toString();
    const lines = data.split('\n');
    this._remainder = lines.pop(); // incomplete last line
    this._lineCount += lines.length;
    callback();
  }

  _flush(callback) {
    if (this._remainder) this._lineCount++;
    this.push({ lineCount: this._lineCount });
    callback();
  }
}

// Async iterator (modern stream consumption):
const readable = createReadStream('data.csv', {
  highWaterMark: 64 * 1024 // 64KB chunks
});

for await (const chunk of readable) {
  // process chunk (Buffer)
  console.log(`Chunk: ${chunk.length} bytes`);
}
```

> **Code walkthrough:** `pipeline` from `stream/promises` is the modern
> replacement for `.pipe()`. It automatically handles errors and cleanup
> across all streams in the chain - if gzip throws, the read and write
> streams are properly closed. The old `.pipe()` doesn't propagate errors,
> causing resource leaks. `Transform` shows the custom stream pattern:
> `_transform` processes each incoming chunk and calls `callback()` when
> done; `_flush` is called when the source ends, allowing final output.
> `highWaterMark` controls chunk size: smaller = more frequent chunks
> (more overhead), larger = more memory but fewer round-trips.

---

### ⚖️ Comparison Table

| Approach | Memory usage | Latency | Complexity |
|---|---|---|---|
| `readFile` | All file in RAM | After full read | Low |
| Streams + pipe | O(chunk size) | First chunk fast | Medium |
| `for await...of` | O(chunk size) | First chunk fast | Low |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Streams process data in chunks instead of loading everything into
> memory. A readable stream emits 'data' events, a writable stream
> accepts writes. I connect them with `pipe()` or `pipeline()`. Good
> for large files or HTTP response bodies. `pipeline()` from
> `stream/promises` is the modern way.

**Senior / Staff:**

> Streams are fundamental to Node.js performance for data-intensive
> operations. Key concepts: backpressure (writable can't keep up with
> readable - `pipe` handles this, `write()` returning `false` and
> 'drain' event for manual handling), object mode (stream objects
> instead of Buffers), and `highWaterMark` tuning. For custom transforms,
> object mode streams that emit parsed objects (not raw bytes) are
> idiomatic. `stream/promises.pipeline` is non-negotiable - `.pipe()`
> doesn't propagate errors.

---

### ⚠️ Common Misconceptions

**Misconception: `.pipe()` handles all errors.**

`.pipe()` does NOT propagate errors. If a transform stream throws,
the readable and writable streams are not automatically closed, causing
resource leaks. Always use `stream/promises.pipeline` for error-safe
stream chaining, or listen for 'error' on every stream individually.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Memory grows unbounded when processing large files.**

Cause: Using `readFile` instead of streams, or accumulating chunks
in an array before processing.

```javascript
// BAD: accumulates all chunks:
const chunks = [];
stream.on('data', chunk => chunks.push(chunk));
stream.on('end', () => {
  const full = Buffer.concat(chunks); // all in memory now
});

// GOOD: process chunks incrementally or use pipeline:
for await (const chunk of stream) {
  await processChunk(chunk); // each chunk processed and GC'd
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What are streams and why use them? | Definition | ★☆☆ | 2 min |
| What is backpressure? | Mechanism | ★★☆ | 3 min |
| `.pipe()` vs `pipeline()` - difference? | Comparison | ★★☆ | 2 min |
| How do you create a Transform stream? | Code | ★★☆ | 3 min |

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


# Buffer and Encoding

---

### 🎯 Model Answer

**30 seconds:**

> Buffer is Node.js's object for raw binary data. It's a fixed-length
> sequence of bytes, similar to a `Uint8Array`. Files, network data,
> and cryptographic hashes are all raw bytes - before you can work with
> them as strings you must decode them with an encoding. Common encodings:
> `utf8` (text), `hex` (40-char hash), `base64` (email attachments, data
> URLs). Never concatenate Buffers with the `+` operator - use
> `Buffer.concat([buf1, buf2])`. Create: `Buffer.from('text', 'utf8')`.

**Blank Mind Recovery:**

**(1) What:** "Fixed array of bytes. Raw binary data."

**(2) Create:** "`Buffer.from(string, encoding)` or `Buffer.alloc(size)`."

**(3) Encode/decode:** "`buf.toString('utf8')` to string. `Buffer.from(str, 'utf8')` to Buffer."

---

### 📘 Concept Explanation

**What it is:**

A built-in Node.js class for working with raw binary data - network
packets, file contents, cryptographic output, and protocol data.

**How it works:**

```
Buffer basics:

  Creating Buffers:
    // From string:
    const buf = Buffer.from('Hello', 'utf8');
    // [72, 101, 108, 108, 111]

    // From hex string (e.g., hash output):
    const hash = Buffer.from('deadbeef', 'hex');

    // From base64 (e.g., image data):
    const img = Buffer.from(base64String, 'base64');

    // Allocate fixed size (zeroed):
    const buf = Buffer.alloc(1024);

    // Allocate uninitialized (faster, may contain old data):
    const buf = Buffer.allocUnsafe(1024); // risky - fill before use

  Encoding/decoding:
    buf.toString('utf8')     // bytes to UTF-8 string
    buf.toString('hex')      // bytes to hex string
    buf.toString('base64')   // bytes to base64 string

  Common encodings:
    utf8    - text (human-readable, variable length per char)
    ascii   - 7-bit ASCII only
    hex     - 2 hex chars per byte (40 chars = 20 bytes = SHA-1)
    base64  - 4 chars per 3 bytes (data URLs, email attachments)
    latin1  - 1 byte per char (binary-safe for legacy data)
    binary  - alias for latin1

  Concatenation:
    // BAD: + operator converts to string first:
    const result = buf1 + buf2;  // wrong! converts to '[object Object]'

    // GOOD: Buffer.concat:
    const result = Buffer.concat([buf1, buf2]);

  Buffer vs string encoding errors:
    When saving a UTF-8 string to a file:
      await writeFile('out.txt', 'Hello', 'utf8');  // explicit encoding
      await writeFile('out.txt', 'Hello');  // implicit utf8 (default)
      await writeFile('out.txt', buffer);   // raw bytes, no encoding

  Security: avoid Buffer.allocUnsafe in secure contexts:
    Buffer.allocUnsafe(8) may contain OLD MEMORY DATA
    (previously freed memory from other operations).
    In cryptographic contexts, always use Buffer.alloc(n)
    or fill immediately after allocUnsafe.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Production) - Binary data handling:**

```javascript
import { createHash, randomBytes } from 'crypto';
import { readFile } from 'fs/promises';

// Hash a file (returns Buffer, convert to hex string):
async function hashFile(filePath) {
  const contents = await readFile(filePath);
  // readFile without encoding returns a Buffer:
  return createHash('sha256')
    .update(contents)   // accepts Buffer directly
    .digest('hex');     // returns hex string
}

// Generate secure random token:
function generateToken(bytes = 32) {
  return randomBytes(bytes).toString('base64url');
  // 32 bytes = 256 bits of entropy = 43 base64url chars
  // base64url is URL-safe (no +, /, =)
}

// BAD: string concatenation with binary data:
const chunks = [];
stream.on('data', chunk => {
  // chunk is a Buffer; string += Buffer causes encoding:
  let result = '';
  result += chunk; // toString() called, may corrupt binary
});

// GOOD: collect Buffers then concat:
const buffers = [];
stream.on('data', chunk => buffers.push(chunk));
stream.on('end', () => {
  const complete = Buffer.concat(buffers);
  const text = complete.toString('utf8');
});

// Encoding issue diagnosis:
const buf = Buffer.from([0xC3, 0xA9]); // é in UTF-8 (2 bytes)
console.log(buf.toString('utf8'));   // 'é' - correct
console.log(buf.toString('latin1')); // 'Ã©' - mojibake!
// Always decode with the SAME encoding used to encode
```

> **Code walkthrough:** `readFile` without an encoding option returns
> a `Buffer`, not a string. This is intentional: for binary files
> (images, PDFs, executables), you don't want string encoding at all.
> `createHash().update(buffer)` accepts Buffer directly, which is more
> efficient than converting to a string first. `randomBytes(32).toString('base64url')`
> is the modern idiom for secure token generation. `base64url` uses
> URL-safe characters (replaces `+` with `-`, `/` with `_`, removes `=`
> padding) which is essential for tokens in URLs and HTTP headers.
> The mojibake example (`Ã©`) is a classic production bug: data encoded
> as UTF-8 but decoded as Latin-1, common in legacy systems.

---

### ⚖️ Comparison Table

| Type | Description | Use case |
|---|---|---|
| `Buffer` | Fixed binary, Node.js specific | File I/O, network, crypto |
| `Uint8Array` | Web standard binary | Cross-runtime code |
| `string` | Decoded text | Human-readable data |
| `ArrayBuffer` | Raw memory (no methods) | Web APIs, TypedArrays |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Buffer holds raw binary data as bytes. When I read a file with
> `readFile` and no encoding, I get a Buffer. To get a string, I call
> `buf.toString('utf8')`. To create a Buffer from a string, I use
> `Buffer.from('text', 'utf8')`. I never concatenate Buffers with `+`.

**Senior / Staff:**

> Buffer extends `Uint8Array` and is interchangeable with it for most
> purposes. Modern code should prefer the Web standard `Uint8Array`
> when writing cross-runtime libraries. In security-sensitive code,
> never use `Buffer.allocUnsafe` - it may expose old memory contents.
> The encoding decision (utf8 vs latin1 vs binary) matters most when
> dealing with legacy protocols or mixed binary/text data. Base64 is
> not an encryption scheme - it's just a binary-to-text encoding.

---

### ⚠️ Common Misconceptions

**Misconception: base64 is a form of encryption.**

Base64 is a reversible binary-to-text encoding, not encryption. It
only makes binary data safe to transmit in text-based protocols (HTTP
headers, JSON, email). `Buffer.from(base64, 'base64').toString('utf8')`
trivially decodes it.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Garbled text (mojibake) when reading files.**

Cause: File is UTF-8 but decoded as ASCII/Latin-1, or vice versa.

```bash
# Detect file encoding:
file -i suspicious-file.txt
# output: suspicious-file.txt: text/plain; charset=utf-8

# Node.js: force explicit encoding everywhere:
const data = await readFile('file.txt', 'utf8'); # explicit
# NOT: readFile('file.txt') then toString() without encoding
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Fix: Always specify encoding explicitly. Never assume ASCII.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is a Buffer in Node.js? | Definition | ★☆☆ | 1 min |
| Buffer vs string - when to use each? | Decision | ★★☆ | 2 min |
| How do you encode/decode binary data? | Mechanism | ★★☆ | 2 min |
| `Buffer.alloc` vs `Buffer.allocUnsafe` | Comparison | ★★☆ | 2 min |
| What is mojibake and how to diagnose it? | Debugging | ★★☆ | 3 min |

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



