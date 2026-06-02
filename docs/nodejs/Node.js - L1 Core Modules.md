---
layout: default
title: "Node.js - L1 Core Modules"
parent: "Node.js"
nav_order: 4
permalink: /nodejs/l1-core-modules/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Node.js File System Module](#nodejs-file-system-module) | foundational |
| 2 | [Node.js HTTP and Net Modules](#nodejs-http-and-net-modules) | foundational |
| 3 | [Node.js Path, OS, and Utility Modules](#nodejs-path-os-and-utility-modules) | foundational |

---

# Node.js File System Module

🎯 **Interview Weight:** foundational (★☆☆) - fs is used in every backend
Node.js app; async vs sync choice and stream vs buffer trade-off are key

---

### 🎯 Model Answer

**30 seconds:**

> Node.js `fs` module provides file system operations. Two API styles:
> callback-based (`fs.readFile`) and promise-based via `fs/promises`.
> Synchronous versions (`fs.readFileSync`) exist but block the event loop -
> only acceptable in CLI tools or startup scripts, never in servers.
> For large files, use streams (`fs.createReadStream`) instead of reading
> the entire file into memory.

**3 minutes:**

> The critical decision: buffer vs stream. `readFile` loads the entire file
> into memory at once. A 1GB log file would require 1GB of RAM per request.
> `createReadStream` reads chunks (highWaterMark, default 64KB) enabling
> processing without holding the whole file in memory. Key operations:
> read (`readFile`, `createReadStream`), write (`writeFile`, `appendFile`,
> `createWriteStream`), stat (`stat`, `access`), directory (`readdir`,
> `mkdir`, `rmdir`). Security: always sanitize file paths from user input -
> path traversal is the #1 fs vulnerability.

**Blank Mind Recovery:**

**(1) Restate:** "fs module: read/write files. Two APIs: callback (legacy)
and promises (modern). Never sync in servers (blocks event loop). Buffer
vs stream: readFile loads all into memory, createReadStream chunks it.
Security: sanitize paths from user input (path traversal)."

---

### 📘 Concept Explanation

**What it is:**

The `fs` module is Node.js's built-in file system interface. It provides
synchronous, callback-based, and Promise-based APIs for all file operations.

**How it works - the API spectrum:**

```javascript
import { promises as fsp } from 'fs';
import { createReadStream, createWriteStream } from 'fs';
import { pipeline } from 'stream/promises';
import path from 'path';

// READING: small files - buffer entire file
async function readConfig(configPath) {
  const content = await fsp.readFile(configPath, 'utf8');
  return JSON.parse(content);
}

// READING: large files - stream chunks (memory efficient)
async function processLargeLog(logPath) {
  const readable = createReadStream(logPath, {
    encoding: 'utf8',
    highWaterMark: 64 * 1024, // 64KB chunks
  });

  for await (const chunk of readable) {
    processChunk(chunk);
  }
}

// WRITING: small data
async function writeResult(filePath, data) {
  await fsp.writeFile(filePath, JSON.stringify(data), 'utf8');
}

// WRITING: stream with backpressure handling
async function streamTransform(inputPath, outputPath) {
  const readable = createReadStream(inputPath);
  const writable = createWriteStream(outputPath);
  // pipeline handles backpressure + cleanup on error
  await pipeline(readable, writable);
}

// DIRECTORY OPERATIONS:
async function ensureDir(dirPath) {
  // { recursive: true } - no error if exists
  await fsp.mkdir(dirPath, { recursive: true });
}

async function listFiles(dirPath) {
  const entries = await fsp.readdir(dirPath, { withFileTypes: true });
  return entries.filter(e => e.isFile()).map(e => e.name);
}

// FILE METADATA:
async function getFileInfo(filePath) {
  try {
    const stats = await fsp.stat(filePath);
    return {
      size: stats.size,
      created: stats.birthtime,
      modified: stats.mtime,
    };
  } catch (err) {
    if (err.code === 'ENOENT') return null;
    throw err;
  }
}

// SECURITY: path traversal prevention
function safePath(baseDir, userInput) {
  const resolved = path.resolve(baseDir, userInput);
  const base = path.resolve(baseDir);
  if (!resolved.startsWith(base + path.sep) && resolved !== base) {
    throw new Error('Path traversal detected');
  }
  return resolved;
}
```

> **Code walkthrough:** The API spectrum: `readFileSync` blocks the eventice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> loop (CPU stuck on I/O for every request). `fsp.readFile` yields during
> I/O. `createReadStream` yields AND uses constant memory. The `safePath`
> function shows the correct security pattern: `path.join` alone does NOT
> prevent traversal since `path.join('/uploads', '../../../etc/passwd')`
> normalizes to `../../etc/passwd` which escapes the directory.

**Why it matters:**

Every Node.js backend uses the file system for configs, uploads, logs,
or generated files. Buffer-vs-stream choice directly impacts memory under
load. Path traversal prevention is the #1 security issue in file-serving
endpoints.

**Trade-offs:**

Buffers are simpler but dangerous for large files. Streams require handling
`data`/`end` events or async iteration. The `pipeline` utility simplifies
stream chaining and ensures cleanup on error.

**Failure modes:**

- `ENOENT`: file not found - check path and working directory
- `EACCES`: permission denied - file permissions or process user
- `EMFILE`: too many open file handles - not closing streams properly
- Path traversal: user input `../../etc/passwd` escaping upload dir

**Scale behavior:**

10 concurrent requests reading 100MB files each = 1GB RAM spike. Switch
to streams for files over ~1MB. Use `stat()` to check size before deciding.

**Decision framework:**

File size < 1MB and single use: `fsp.readFile`. File > 1MB: `createReadStream`.
Repeated reads (like config): read once and cache in memory.

**Memory model:**

`readFile` allocates a Buffer equal to the file size. `createReadStream`
allocates one `highWaterMark`-sized Buffer and reuses it per chunk. The
difference is O(fileSize) vs O(64KB).

---

### 💻 Code Example


```javascript
// BAD: anti-pattern - see GOOD example below
```


```javascript
// BAD: anti-pattern - see GOOD example below
```

```javascript
// BAD: sync fs in a request handler (blocks all requests)
app.get('/config', (req, res) => {
  // ALL other requests wait while this reads from disk
  const config = fs.readFileSync('./config.json', 'utf8');
  res.json(JSON.parse(config));
});

// GOOD: async fs with promises
app.get('/config', async (req, res) => {
  // Event loop free during disk I/O
  const content = await fsp.readFile('./config.json', 'utf8');
  res.json(JSON.parse(content));
});

// BAD: loading large file into memory for download
app.get('/download/:file', async (req, res) => {
  const filePath = safePath('./uploads', req.params.file);
  // Loads entire file (possibly 500MB) into RAM per request
  const content = await fsp.readFile(filePath);
  res.send(content);
});

// GOOD: stream directly to response
app.get('/download/:file', (req, res) => {
  try {
    const filePath = safePath('./uploads', req.params.file);
    const readable = createReadStream(filePath);
    readable.on('error', (err) => {
      if (err.code === 'ENOENT') res.status(404).end();
      else res.status(500).end();
    });
    readable.pipe(res);
  } catch (err) {
    // Path traversal error caught here
    res.status(403).end();
  }
});
```

> **Code walkthrough:** `readFileSync` in a request handler is the mostice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> common Node.js performance mistake. While the file reads (even 1-10ms
> on fast SSDs), the event loop is blocked and no other request is
> processed. The async version yields during I/O. The streaming download
> is critical for large files: without streaming, 100 concurrent downloads
> of a 100MB file would require 10GB of RAM for buffers. The `safePath`
> prevents directory traversal attacks at the fs layer.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> The `fs` module handles files and directories. Use `fs.promises.readFile`
> for async reads and `fs.writeFile` for writes. Avoid sync methods in
> server code - they block the event loop. For large files, use
> `createReadStream` instead of `readFile` to avoid loading everything
> into memory at once.

**Senior / Staff:**

> The key fs decisions: async vs sync (never sync in servers), and buffer
> vs stream (stream for anything over ~1MB). Always sanitize user-provided
> paths - `path.join` is insufficient, you need `path.resolve` + `startsWith`
> to verify containment. For production: cache frequently-read small configs
> in memory. For large file processing, use `pipeline` from `stream/promises`
> over manual `.pipe()` - it handles cleanup (closing streams) on error.
> Error code discrimination (`ENOENT` vs `EACCES` vs `EMFILE`) is essential
> for meaningful error responses.

---

### ⚠️ Common Misconceptions

**"path.join prevents path traversal":**

False. `path.join('/uploads', '../../../etc/passwd')` produces
`../../etc/passwd` - escaping the directory. Use `path.resolve`
and verify the result starts with the allowed base.

**"readFile is fine for any file size":**

`readFile` allocates a Buffer equal to the file size. A 500MB file
allocates 500MB of RAM per concurrent read. This kills servers under load.

**"Sync fs is only slightly slower":**

Sync fs blocks the ENTIRE event loop - not just the current request.
Every other pending request, timer, and I/O callback is frozen during
the synchronous read. On a loaded server, one sync read can delay
thousands of responses.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: Server hangs on file downloads**

```bash
# Check for open file descriptors (EMFILE)
lsof -p $(pgrep node) | wc -l
# Default limit: 1024. Fix:
ulimit -n 65536
```

> **Code walkthrough:** This Default limit: 1024. Fix: example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

**Symptom: Path traversal allowing reads outside upload dir**

```javascript
// DIAGNOSTIC: log all file reads with resolved path
const origRead = fsp.readFile.bind(fsp);
fsp.readFile = async (p, ...args) => {
  console.log('[fs] reading:', path.resolve(p));
  return origRead(p, ...args);
};
```

> **Code walkthrough:** This Default limit: 1024. Fix: example demonstrates async/await Promise resolution. **KEY MECHANISM:** async functions return Promises; await suspends the microtask until the Promise settles. **WHY IT MATTERS:** unhandled Promise rejections crash the Node process in v15+ or fire unhandledRejection event. **TAKEAWAY: always await or .catch() every Promise - silent rejections are production defects.**

**Symptom: High memory on download endpoint**

The endpoint uses `readFile` instead of streaming. Switch to
`createReadStream` + `pipe`. Memory drops immediately under load.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| Sync vs async fs | 2-3 min | Event loop blocking |
| Buffer vs stream choice | 2-3 min | Memory under load |
| Path traversal prevention | 2-3 min | path.resolve + startsWith |
| Error code handling | 2-3 min | ENOENT vs EACCES vs EMFILE |
| pipeline vs manual pipe | 2-3 min | Cleanup on error |
| File descriptor leaks | 2-3 min | Always close streams |
| Caching config files | 2-3 min | Read once, store in memory |

---

**[SENIOR] Q1 - [DESIGN] How do you serve user-uploaded files safely in Node.js?**

> **Answer:**
>
> ```javascript
> import path from 'path';
> import { createReadStream } from 'fs';
> import { stat } from 'fs/promises';
>
> const UPLOAD_DIR = path.resolve('./uploads');
>
> app.get('/files/:filename', async (req, res) => {
>   // 1. VALIDATE: filename format (no separators, safe chars)
>   const { filename } = req.params;
>   if (!/^[\w-]+\.\w{2,10}$/.test(filename)) {
>     return res.status(400).json({ error: 'Invalid filename' });
>   }
>
>   // 2. SANITIZE: resolve and verify within upload dir
>   const filePath = path.resolve(UPLOAD_DIR, filename);
>   if (!filePath.startsWith(UPLOAD_DIR + path.sep)) {
>     return res.status(403).json({ error: 'Forbidden' });
>   }
>
>   // 3. CHECK existence and get size
>   let stats;
>   try {
>     stats = await stat(filePath);
>   } catch (err) {
>     if (err.code === 'ENOENT') return res.status(404).end();
>     throw err;
>   }
>
>   // 4. STREAM response (no memory spike regardless of size)
>   res.setHeader('Content-Length', stats.size);
>   res.setHeader('Content-Disposition',
>     `attachment; filename="${filename}"`);
>   const stream = createReadStream(filePath);
>   stream.on('error', () => res.status(500).end());
>   stream.pipe(res);
> });
> ```
>
> Two layers of path validation: regex to catch obvious attacks AND
> `resolve` + `startsWith` to catch URL-encoded traversal attempts.
> Setting `Content-Length` before streaming enables client progress bars.
>
> *What separates good from great:* Understanding that validation alone
> (regex) is not sufficient - you need the `path.resolve` containment
> check as a second layer because filenames can be URL-encoded or contain
> Unicode lookalikes.

---

**[JUNIOR] Q2 - [MECHANISM] A file download endpoint is causing OOM errors under load.**
Diagnose and fix it.** `[MID]` DEBUGGING

> **Answer:**
>
> OOM on download = buffering instead of streaming.
>
> ```javascript
> // DIAGNOSE: watch memory per request
> setInterval(() => {
>   const mem = process.memoryUsage();
>   console.log({
>     rss: (mem.rss / 1024 / 1024).toFixed(1) + 'MB',
>     heap: (mem.heapUsed / 1024 / 1024).toFixed(1) + 'MB',
>   });
> }, 1000);
>
> // BROKEN (allocates full file per request):
> app.get('/download/:file', async (req, res) => {
>   const data = await readFile(filePath);
>   res.send(data);
> });
>
> // FIXED (constant memory regardless of file size):
> app.get('/download/:file', (req, res) => {
>   const stream = createReadStream(filePath);
>   stream.pipe(res);
> });
> ```
>
> Memory drops from O(fileSize * concurrentRequests) to O(64KB constant).
>
> *What separates good from great:* Knowing to check if the endpoint uses
> `readFile` (obvious) vs streaming but not handling backpressure (stream
> fills buffer because response is slow). `pipe` handles backpressure
> automatically by pausing the readable stream when the write buffer is full.

---

**[JUNIOR] Q3 - [MECHANISM] When should you use synchronous fs methods vs async methods?**

> **Answer:**
>
> Use synchronous methods (`readFileSync`, `writeFileSync`) only in two contexts: (1) application startup code that runs before the server begins accepting requests, and (2) CLI tools where blocking is acceptable.
>
> Never use synchronous fs methods in HTTP request handlers or inside any live event handler. Node.js is single-threaded - a `readFileSync` blocks the entire event loop. For a 10ms file read with 100 concurrent requests, you can add up to 1 second of latency to every pending request.
>
> ```javascript
> // WRONG: blocks all other requests while reading
> app.get('/config', (req, res) => {
>   const data = fs.readFileSync('./config.json', 'utf8');
>   res.json(JSON.parse(data));
> });
>
> // CORRECT: non-blocking
> app.get('/config', async (req, res) => {
>   const data = await fs.promises.readFile('./config.json', 'utf8');
>   res.json(JSON.parse(data));
> });
>
> // ACCEPTABLE: at startup, before server.listen
> const config = JSON.parse(fs.readFileSync('./config.json', 'utf8'));
> const server = http.createServer(app);
> server.listen(3000);
> ```
>
> *What separates good from great:* Even `fs.promises.readFile` loads the entire file into memory. For large files, use `createReadStream` regardless of sync/async. Blocking vs non-blocking and buffering vs streaming are two separate decisions.

---

**[JUNIOR] Q4 - [DEBUGGING] How do you handle specific fs error codes: ENOENT, EACCES, and EMFILE?**

> **Answer:**
>
> Node.js fs errors carry a `.code` property mapping to OS error codes. Handle them separately - they require different responses:
>
> - `ENOENT` - file does not exist; usually expected, return null or a default
> - `EACCES` - permission denied; this is a deployment misconfiguration, not user error
> - `EMFILE` - too many open file descriptors; this is a resource leak bug in your code
>
> ```javascript
> async function safeRead(filePath) {
>   try {
>     return await fs.promises.readFile(filePath, 'utf8');
>   } catch (err) {
>     switch (err.code) {
>       case 'ENOENT': return null;
>       case 'EACCES':
>         throw new Error(
>           `Permission denied: ${filePath}. ` +
>           'Check process user has read access.'
>         );
>       case 'EMFILE':
>         throw new Error(
>           'File descriptor limit reached. ' +
>           'Run: ulimit -n 65536'
>         );
>       default: throw err;
>     }
>   }
> }
> ```
>
> `EMFILE` silently accumulates - the most common cause is `createReadStream` streams that are opened but never closed when an error path exits early.
>
> *What separates good from great:* Never use a generic `catch (err)` for fs errors. `ENOENT` is normal flow. `EMFILE` means you have a leak bug that needs a code fix, not a retry.

---

**[SENIOR] Q5 - [MECHANISM] When should you use `stream.pipeline` over `stream.pipe`?**

> **Answer:**
>
> Always prefer `pipeline` in production. `pipe` has a critical flaw: if the destination stream errors or closes early, the source stream is NOT automatically destroyed - causing file descriptor leaks.
>
> ```javascript
> import { createReadStream, createWriteStream } from 'fs';
> import { pipeline } from 'stream/promises';
> import { createGzip } from 'zlib';
>
> // WRONG: source stream leaks if writeStream errors
> readStream.pipe(gzip).pipe(writeStream);
>
> // CORRECT: all streams destroyed on error
> await pipeline(
>   createReadStream('input.log'),
>   createGzip(),
>   createWriteStream('output.log.gz')
> );
> ```
>
> `pipeline` from `stream/promises` (Node 15+) propagates errors through the chain, calls `destroy()` on all streams on failure, and returns a Promise that rejects on error.
>
> *What separates good from great:* `EMFILE: too many open files` after days of uptime is almost always `pipe` without error cleanup. Every production stream chain should use `pipeline`.

---

**[JUNIOR] Q6 - [DEBUGGING] How do file descriptor leaks happen and how do you detect them?**

> **Answer:**
>
> A file descriptor leak occurs when a stream is opened but never closed. Every open fd consumes an OS resource - default limit is 1024 on Linux.
>
> Common causes: (1) `createReadStream` opened but never consumed or closed, (2) `pipe` chain where source stream is not destroyed on destination error, (3) early return from a function after opening a stream but before closing it.
>
> ```javascript
> // LEAK: stream never closed when format check fails
> app.get('/preview', (req, res) => {
>   const stream = createReadStream(filePath); // fd opens here
>   if (req.query.format !== 'text') {
>     res.json({ error: 'unsupported' }); // returns, stream abandoned
>     return;
>   }
>   stream.pipe(res);
> });
>
> // FIXED: open stream only when needed
> app.get('/preview', (req, res) => {
>   if (req.query.format !== 'text') {
>     res.json({ error: 'unsupported' });
>     return;
>   }
>   createReadStream(filePath).pipe(res);
> });
>
> // DIAGNOSE: count open fds - should be stable
> // lsof -p $(pgrep node) | wc -l
> ```
>
> *What separates good from great:* Always open streams as late as possible - in the branch that actually needs them. A steady increase in fd count over time (check with `lsof`) is the diagnostic signal.

---

**[JUNIOR] Q7 - [DESIGN] How do you cache a config file so it is only read once at startup?**

> **Answer:**
>
> Read the file synchronously at module initialization and export the parsed result. Node.js module caching ensures this code runs once per process lifetime.
>
> ```javascript
> // config.js
> import { readFileSync } from 'fs';
> import path from 'path';
> import { fileURLToPath } from 'url';
>
> const __dirname = path.dirname(fileURLToPath(import.meta.url));
>
> // Intentionally sync: runs once at startup before server.listen
> const raw = readFileSync(path.join(__dirname, 'config.json'), 'utf8');
> export const config = Object.freeze(JSON.parse(raw));
> // All imports get the same frozen object - no re-reads
> ```
>
> `Object.freeze` prevents consumers from accidentally mutating the shared config object. Any mutation attempt throws `TypeError` in strict mode.
>
> *What separates good from great:* Beginner mistake is reading config inside each request handler. The symptom in dev: config hot-reloads work, giving a false impression that production also picks up config changes live. It does not.

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


# Node.js HTTP and Net Modules

🎯 **Interview Weight:** foundational (★☆☆) - http module is what Express
wraps; understanding the base layer explains middleware and body parsing

---

### 🎯 Model Answer

**30 seconds:**

> `http` module creates HTTP servers and makes HTTP requests. Every
> Express/Fastify app is built on `http.createServer`. The `req` is a
> Readable stream; `res` is a Writable stream. Body must be read manually
> with `data`/`end` events - frameworks handle this for you. For HTTP
> requests in Node.js 18+, use the built-in `fetch`. `net` module creates
> raw TCP servers for protocols below HTTP (WebSockets, custom protocols).

**3 minutes:**

> `http.createServer((req, res) => {})` - the callback runs for every
> request. `req` has `.method`, `.url`, `.headers`, and is a Readable
> stream for the body. `res` has `.writeHead(status, headers)` and
> `.end(body)`. For HTTPS: `https.createServer({ key, cert }, handler)`.
> The `http.Agent` controls connection pooling: `keepAlive: true` reuses
> TCP connections, reducing handshake overhead for microservice-to-microservice
> calls. Without a body size limit, attackers can exhaust memory by sending
> huge request bodies - always set a limit.

**Blank Mind Recovery:**

**(1) Restate:** "http.createServer: low-level HTTP. req=Readable, res=Writable.
Body is streamed (read manually with data/end). Express wraps this. For
outbound requests: fetch (Node 18+). https.createServer for TLS.
http.Agent for connection pooling."

---

### 📘 Concept Explanation

**What it is:**

The `http` module is Node.js's built-in HTTP implementation. All HTTP
frameworks (Express, Fastify, Koa) use `http.createServer` internally.

**How it works:**

```javascript
import http from 'http';
import https from 'https';
import { readFileSync } from 'fs';

// BASIC HTTP SERVER:
const server = http.createServer((req, res) => {
  // req.method: 'GET', 'POST', etc.
  // req.url: '/users?limit=10'
  // req.headers: { 'content-type': 'application/json', ... }

  // Body is a stream - must be read manually:
  let body = '';
  let bodySize = 0;
  req.on('data', chunk => {
    bodySize += chunk.length;
    if (bodySize > 1_048_576) { // 1MB body limit
      res.writeHead(413);
      res.end('Payload too large');
      req.destroy();
      return;
    }
    body += chunk;
  });
  req.on('end', () => {
    let parsed = {};
    const ct = req.headers['content-type'];
    if (ct?.includes('application/json')) {
      try { parsed = JSON.parse(body); }
      catch { res.writeHead(400); res.end('Invalid JSON'); return; }
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ received: parsed }));
  });
  req.on('error', (err) => {
    console.error('Request error:', err);
    res.writeHead(500);
    res.end();
  });
});

server.listen(3000, () => console.log('Listening :3000'));

// HTTPS:
const httpsServer = https.createServer({
  key: readFileSync('./certs/private.key'),
  cert: readFileSync('./certs/certificate.crt'),
}, (req, res) => {
  res.writeHead(200);
  res.end('Secure!');
});

// HTTP CLIENT - modern (Node.js 18+):
const response = await fetch('https://api.example.com/users', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ name: 'Alice' }),
});
const data = await response.json();

// CONNECTION POOLING via Agent:
const agent = new http.Agent({
  keepAlive: true,
  maxSockets: 50,    // max concurrent connections per host
  maxFreeSockets: 10, // max idle connections to keep alive
});
```

> **Code walkthrough:** The body reading pattern shows exactly whatice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> `express.json()` does internally: listen to `data` events, concatenate
> chunks, then `JSON.parse`. The 1MB body limit is critical security -
> without it an attacker can POST gigabytes until the server OOMs. The
> `http.Agent` with `keepAlive: true` reuses TCP connections avoiding
> the 3-way handshake overhead on every request in a microservice mesh.

**Why it matters:**

Understanding the raw HTTP server explains how middleware works, why body
parsers are needed, and where performance bottlenecks occur. Debugging
Express middleware issues requires understanding IncomingMessage and
ServerResponse internals.

**Trade-offs:**

Raw `http` gives maximum control but requires manual routing, body parsing,
and error handling. Frameworks add a few microseconds of overhead but
provide safety, routing, and middleware chaining.

**Failure modes:**

- No body limit: memory exhaustion from large POST bodies
- Not calling `res.end()`: requests hang waiting for response
- Not handling `error` event on req: uncaught exception crashes server
- Sync code in handler: blocks event loop for all requests

**Scale behavior:**

Connection pooling with `keepAlive: true` reduces latency by 1-3ms per
request. Critical when making 100+ downstream calls per second. Tune
`maxSockets` to match expected concurrency per downstream host.

**Decision framework:**

Raw `http`: learning, custom proxies, embedding HTTP in tools.
Express/Fastify: all production applications.

**Memory model:**

Each `createServer` callback invocation gets a new `req`/`res`. The `req`
body stream holds data in memory only while being read. Connection state
(keep-alive) is maintained by the server's socket pool.

---

### 💻 Code Example

```javascript
// WHAT EXPRESS DOES UNDER THE HOOD (simplified):
function createMiniExpress() {
  const middlewares = [];

  const handler = (req, res) => {
    let i = 0;
    function next(err) {
      if (err) {
        res.writeHead(500);
        res.end(err.message);
        return;
      }
      const fn = middlewares[i++];
      if (fn) fn(req, res, next);
      // If no more middleware: request hangs
      // (real Express sends 404 here)
    }
    next();
  };

  handler.use = (fn) => middlewares.push(fn);
  return { handler, server: http.createServer(handler) };
}

// JSON body parser (what express.json() does internally):
function jsonBodyParser(req, res, next) {
  if (req.method === 'GET' || req.method === 'HEAD') {
    return next(); // no body expected
  }

  let body = '';
  let size = 0;
  req.on('data', (chunk) => {
    size += chunk.length;
    if (size > 1_048_576) { // 1MB
      req.destroy(new Error('Body too large'));
      return;
    }
    body += chunk;
  });
  req.on('end', () => {
    if (req.headers['content-type']?.includes('application/json')) {
      try {
        req.body = JSON.parse(body);
        next();
      } catch (e) {
        res.writeHead(400);
        res.end('Invalid JSON');
      }
    } else {
      next();
    }
  });
  req.on('error', next);
}
```

> **Code walkthrough:** The mini-Express shows that middleware is just aice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> queue of `(req, res, next)` functions invoked in order. Each calls `next()`
> to continue the chain. `jsonBodyParser` reveals exactly what `express.json()`
> does: reads the stream body, enforces size limit, parses JSON, attaches
> to `req.body`. This is why Express route handlers receive `req.body`
> synchronously - the middleware upstream already consumed the stream.
> After the stream is consumed, it cannot be read again.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `http.createServer` creates a server. The callback receives `req` and
> `res` objects. The request body must be read by listening to `data` and
> `end` events. Express wraps this so route handlers get `req.body`
> automatically (via `express.json()` middleware). For making HTTP requests
> in Node.js 18+, use `fetch`.

**Senior / Staff:**

> The raw `http` module is where all Express behavior is rooted. Understanding
> this explains: why `express.json()` must come before route handlers (it
> consumes the req stream), why you can't read `req.body` twice (stream
> already consumed), and why slow clients can hold connections open.
> Connection pooling via `http.Agent` with `keepAlive: true` is critical
> for microservice communication - without it, every outgoing request
> creates a new TCP connection with a full handshake. Set
> `server.keepAliveTimeout` higher than the load balancer's timeout to
> prevent spurious connection resets (a common production gotcha).

---

### ⚠️ Common Misconceptions

**"req.body is automatically available":**

Only with a body-parser middleware. The raw `req` is a stream. Forgetting
`express.json()` before a POST handler gives `req.body = undefined`.

**"fetch is a third-party module in Node.js":**

`fetch` has been native in Node.js since v18 (2022). `node-fetch`, `axios`,
and `got` are still widely used but `fetch` is the built-in standard.

**"HTTPS requires a different server architecture":**

`https.createServer` is identical to `http.createServer` but takes TLS
options. In production, TLS is typically terminated at the load balancer
and the cluster runs plain HTTP internally.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: Requests never complete (hang indefinitely)**

```javascript
// CAUSE: missing res.end() in a code path
app.get('/users', async (req, res) => {
  const users = await db.findAll();
  if (users.length > 0) res.json(users);
  // BUG: empty result has no response sent
  // FIX: always respond in all branches

  // Add server-level timeout as safety net:
  server.setTimeout(30000);
  server.on('timeout', (socket) => socket.destroy());
});
```

> **Code walkthrough:** This Unknown example demonstrates async/await Promise resolution using async/await. **KEY MECHANISM:** async functions return Promises; await suspends the microtask until the Promise settles. **WHY IT MATTERS:** unhandled Promise rejections crash the Node process in v15+ or fire unhandledRejection event. **TAKEAWAY: always await or .catch() every Promise - silent rejections are production defects.**

**Symptom: Memory grows on POST-heavy endpoints**

Missing body size limit. Add `express.json({ limit: '1mb' })` or
implement manual limit in raw http handler.

**Symptom: Connection reset errors in microservices**

Keep-alive timeout mismatch. `server.keepAliveTimeout` must exceed
the load balancer's timeout. AWS ALB default: 60s. Set Node.js server to 65s.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| How Express wraps http | 2-3 min | Middleware queue over createServer |
| Request body streaming | 2-3 min | data/end events, size limit |
| HTTPS vs HTTP termination | 2-3 min | TLS at LB, plain HTTP inside |
| fetch vs http.request | 2-3 min | Node 18+ native fetch |
| Keep-alive connection pool | 2-3 min | Agent configuration |
| Body size limits | 2-3 min | Memory attack prevention |
| Server timeout config | 2-3 min | keepAliveTimeout, setTimeout |

---

**[JUNIOR] Q1 - [DEBUGGING] Why does `req.body` appear as `undefined` in Express route handlers?**

> **Answer:**
>
> `req.body` is populated by body-parser middleware. If it's `undefined`,
> the middleware wasn't registered or wasn't registered BEFORE the route.
>
> ```javascript
> // BROKEN: middleware registered after route
> app.post('/users', (req, res) => {
>   console.log(req.body); // undefined
>   res.json(req.body);
> });
> app.use(express.json()); // too late
>
> // BROKEN: wrong Content-Type from client
> // express.json() only parses if Content-Type: application/json
>
> // FIXED:
> app.use(express.json());          // must come first
> app.use(express.urlencoded({ extended: true })); // for form data
>
> app.post('/users', (req, res) => {
>   console.log(req.body); // { name: 'Alice' }
> });
>
> // DIAGNOSTIC: check Content-Type
> app.post('/debug', (req, res) => {
>   console.log('Content-Type:', req.headers['content-type']);
>   res.json({ ct: req.headers['content-type'], body: req.body });
> });
> ```
>
> Three cases: (1) middleware not registered, (2) registered after route,
> (3) correct middleware but wrong Content-Type from client.
>
> *What separates good from great:* Case 3 is the tricky one - Postman
> sending `raw` body without setting Content-Type to `application/json`
> means Express never calls the JSON parser. The fix is on the client
> side, not the server. Knowing this saves significant debugging time.

---

**[JUNIOR] Q2 - [MECHANISM] Explain how Express wraps the Node.js `http` module.**

> **Answer:**
>
> Express's `app` object is a function with the signature `(req, res, next)`. When you call `app.listen(3000)`, Express calls `http.createServer(app)` internally - the Express app itself IS the request handler passed to `createServer`.
>
> The `req` and `res` objects Express provides are the same `IncomingMessage` and `ServerResponse` objects from Node's `http` module, extended with convenience methods (`req.params`, `res.json()`, `res.status()`). No magic - just property augmentation.
>
> The middleware queue is the core innovation: when a request arrives, Express calls `next()` to pass control down a chain of functions. `app.use`, `app.get`, `app.post` all register functions into this chain. The chain short-circuits when a function sends a response without calling `next()`.
>
> ```javascript
> // What Express does internally:
> const http = require('http');
> const server = http.createServer((req, res) => {
>   app(req, res); // app is the middleware chain runner
> });
> server.listen(3000);
> ```
>
> *What separates good from great:* Understanding that `req` is a Readable stream and `res` is a Writable stream. Express does NOT buffer request bodies - you need body-parser middleware for that. Raw `http` gives you the stream; middleware converts it to a usable object.

---

**[JUNIOR] Q3 - [MECHANISM] How do you read a raw HTTP request body without Express body-parser?**

> **Answer:**
>
> ```javascript
> const http = require('http');
>
> http.createServer((req, res) => {
>   if (req.method !== 'POST') {
>     res.writeHead(405).end();
>     return;
>   }
>
>   const chunks = [];
>   let totalSize = 0;
>   const MAX_SIZE = 1 * 1024 * 1024; // 1MB limit
>
>   req.on('data', (chunk) => {
>     totalSize += chunk.length;
>     if (totalSize > MAX_SIZE) {
>       res.writeHead(413).end('Payload Too Large');
>       req.destroy(); // stop receiving data
>       return;
>     }
>     chunks.push(chunk);
>   });
>
>   req.on('end', () => {
>     const body = Buffer.concat(chunks).toString('utf8');
>     try {
>       const data = JSON.parse(body);
>       res.writeHead(200, { 'Content-Type': 'application/json' });
>       res.end(JSON.stringify({ received: data }));
>     } catch {
>       res.writeHead(400).end('Invalid JSON');
>     }
>   });
>
>   req.on('error', (err) => {
>     console.error('Request error:', err);
>     res.writeHead(500).end();
>   });
> }).listen(3000);
> ```
>
> Always implement a size limit. Without it, a client can send an arbitrarily large body and exhaust server memory.
>
> *What separates good from great:* The size check must be inside the `data` event, not in `end`. Checking in `end` means you have already buffered the full oversized payload. `req.destroy()` stops Node from reading more data from the socket.

---

**[SENIOR] Q4 - [DESIGN] Where should TLS termination happen in a Node.js deployment?**

> **Answer:**
>
> TLS should be terminated at the load balancer or reverse proxy (NGINX, AWS ALB, Cloudflare), not in the Node.js process. Node.js applications run plain HTTP internally.
>
> Why:
> - TLS handshakes are CPU-intensive. Dedicated hardware (ALB) or optimized proxy (NGINX) handles this more efficiently than Node.js
> - Certificate management (renewal, rotation) is centralized at the infrastructure layer, not spread across all application instances
> - Internal service-to-service traffic can use plain HTTP within a private network (VPC), reducing CPU overhead
>
> For mutual TLS (mTLS) between microservices, use a service mesh (Envoy/Istio) rather than Node.js `https` module in every service.
>
> When to terminate TLS in Node.js: single-process dev/test environments, cases where end-to-end encryption is required and you cannot use a service mesh.
>
> ```javascript
> // In production: app serves plain HTTP, TLS at ALB
> const http = require('http');
> http.createServer(app).listen(3000);
>
> // Trust X-Forwarded-Proto from ALB
> app.set('trust proxy', true);
> app.use((req, res, next) => {
>   if (req.protocol !== 'https') {
>     return res.redirect(`https://${req.hostname}${req.url}`);
>   }
>   next();
> });
> ```
>
> *What separates good from great:* Setting `trust proxy` is mandatory when ALB terminates TLS - otherwise Express sees all requests as HTTP even when the original client used HTTPS, breaking HTTPS redirects and secure cookie flags.

---

**[JUNIOR] Q5 - [MECHANISM] When should you use `fetch` vs `http.request` in Node.js?**

> **Answer:**
>
> In Node.js 18+, use the built-in `fetch` for all new HTTP client code. It is the same API as browser `fetch`, reducing cognitive overhead for full-stack developers.
>
> Use `http.request` (or the `https` module) when:
> - You need streaming control (pipe response directly to a file stream without buffering)
> - You need per-request socket configuration (custom timeout, agent, keep-alive settings)
> - You are supporting Node.js < 18 without a polyfill
>
> ```javascript
> // MODERN: use fetch (Node.js 18+)
> const response = await fetch('https://api.example.com/data');
> if (!response.ok) throw new Error(`HTTP ${response.status}`);
> const data = await response.json();
>
> // STREAMING with http.request (when fetch is insufficient):
> const https = require('https');
> https.get('https://example.com/large-file', (res) => {
>   res.pipe(fs.createWriteStream('./output'));
> });
>
> // Note: fetch can also stream via response.body (ReadableStream)
> const { body } = await fetch('https://example.com/large-file');
> await pipeline(body, fs.createWriteStream('./output'));
> ```
>
> *What separates good from great:* `fetch` does not handle HTTP errors the same way as `axios` - a 404 or 500 response does NOT throw; you must check `response.ok`. This is a common production bug when migrating from `axios` to `fetch`.

---

**[SENIOR] Q6 - [DESIGN] How do you configure HTTP keep-alive connection pooling in Node.js?**

> **Answer:**
>
> By default, Node.js `http.request` does not reuse connections. Each request opens a new TCP connection. For services making high-volume outbound HTTP requests, this causes significant latency and port exhaustion.
>
> ```javascript
> const http = require('http');
>
> // Configure an Agent with connection reuse
> const agent = new http.Agent({
>   keepAlive: true,
>   maxSockets: 50,      // max concurrent connections per host
>   maxFreeSockets: 10,  // idle connections to keep open
>   timeout: 30000,      // idle socket timeout
> });
>
> // Pass agent to all requests to this host
> http.request({
>   hostname: 'internal-service',
>   port: 3001,
>   path: '/api/data',
>   agent,
> });
>
> // With fetch (Node.js 18+): use undici Agent
> const { fetch, Agent } = require('undici');
> const myAgent = new Agent({ connections: 50 });
> fetch('http://internal-service/api', { dispatcher: myAgent });
> ```
>
> For server-side `keepAliveTimeout`: this must exceed the load balancer's idle timeout. AWS ALB default is 60s; set `server.keepAliveTimeout = 65000` to prevent the ALB from sending a request on a connection Node is about to close (502 errors).
>
> *What separates good from great:* Knowing that high `maxSockets` can exhaust the upstream service's connection pool. The right value is `upstream_max_connections / number_of_node_instances`, not "as high as possible."

---

**[JUNIOR] Q7 - [DESIGN] How do you prevent a body-size attack on an HTTP server?**

> **Answer:**
>
> Without a body size limit, a client can send a multi-gigabyte POST body, causing out-of-memory errors. Two layers of defense:
>
> 1. **At the framework/middleware level** - limits buffered body size
> 2. **At the connection level** - limits total data per request
>
> ```javascript
> // Layer 1: Express body-parser limit (default: 100kb)
> app.use(express.json({ limit: '1mb' }));
> app.use(express.urlencoded({ limit: '1mb', extended: true }));
>
> // Layer 2: Raw http request limit
> const server = http.createServer(app);
> server.maxHeadersCount = 100;  // header count limit
>
> // For file uploads: use multer with limits
> const upload = multer({
>   limits: {
>     fileSize: 10 * 1024 * 1024, // 10MB per file
>     files: 5,                    // max 5 files
>   },
> });
>
> // For raw http: enforce in data event
> req.on('data', (chunk) => {
>   total += chunk.length;
>   if (total > MAX_BYTES) {
>     res.writeHead(413).end();
>     req.destroy();
>   }
> });
> ```
>
> Setting a limit in Express body-parser does NOT help if you have custom raw http handling - the limit is per-middleware, not per-connection.
>
> *What separates good from great:* The `413 Payload Too Large` status code must be sent AND `req.destroy()` called. Sending the response without destroying the request stream means Node continues reading the body anyway, consuming memory and CPU.

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


# Node.js Path, OS, and Utility Modules

🎯 **Interview Weight:** foundational (★☆☆) - path is in every fs operation;
cross-platform correctness and path security depend on it

---

### 🎯 Model Answer

**30 seconds:**

> `path` module handles file paths cross-platform. Use `path.join`
> for safe concatenation and `path.resolve` to get absolute paths.
> Never concatenate paths with string operators - this breaks on Windows
> and creates security vulnerabilities. `os` gives system info (CPU count,
> memory, platform). `util.promisify` converts callback APIs to Promises.
> In ES modules, `__dirname` doesn't exist - derive it from `import.meta.url`.

**3 minutes:**

> Why `path.join` over string concatenation: `path.join('a', 'b')`
> produces `a/b` on Unix and `a\b` on Windows. String concatenation
> hardcodes the separator. `path.resolve` returns an absolute path:
> `path.resolve('uploads', file)` = `/cwd/uploads/file`. For security:
> resolve the path and verify it starts with the allowed base directory.
> `os.cpus().length` is used to size worker thread pools. In containers,
> this may report host CPU count - check cgroup limits. `util.promisify`
> wraps any error-first callback function to return a Promise.

**Blank Mind Recovery:**

**(1) Restate:** "path.join: cross-platform concatenation. path.resolve:
absolute path. Never string-concat paths. __dirname in ESM: use
fileURLToPath + path.dirname. os.cpus().length: hardware threads for
worker sizing. util.promisify: callback-to-promise."

---

### 📘 Concept Explanation

**What it is:**

`path`, `os`, and `util` are core utility modules for file system work,
system introspection, and API compatibility.

**How it works:**

```javascript
import path from 'path';
import os from 'os';
import { promisify } from 'util';
import { readFile } from 'fs'; // callback version

// PATH MODULE:
// Cross-platform joining
const configPath = path.join('config', 'app.json');
// Unix: config/app.json  |  Windows: config\app.json

// Absolute resolution from cwd
const absPath = path.resolve('uploads', 'photos', 'img.jpg');
// e.g. /srv/app/uploads/photos/img.jpg

// Path components
const full = '/Users/alice/docs/report.pdf';
path.dirname(full);          // /Users/alice/docs
path.basename(full);         // report.pdf
path.basename(full, '.pdf'); // report (without extension)
path.extname(full);          // .pdf
path.parse(full);
// { root:'/', dir:'/Users/alice/docs',
//   base:'report.pdf', ext:'.pdf', name:'report' }

// __dirname equivalent in ES modules:
import { fileURLToPath } from 'url';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
// Same as CommonJS __dirname

// OS MODULE:
os.cpus().length   // logical CPU count
os.totalmem()      // total RAM in bytes
os.freemem()       // free RAM in bytes
os.platform()      // 'linux', 'darwin', 'win32'
os.tmpdir()        // /tmp  or  C:\Users\...\Temp
os.homedir()       // /Users/alice
os.hostname()      // machine hostname

// CPU-bound worker sizing:
const WORKER_COUNT = Math.max(1, os.cpus().length - 1);
// Leave 1 core for event loop + I/O

// UTIL MODULE:
const readFileAsync = promisify(readFile);
const content = await readFileAsync('config.json', 'utf8');

// util.inspect: better than JSON.stringify
import { inspect } from 'util';
const circular = {};
circular.self = circular;
// JSON.stringify(circular) throws circular reference error
inspect(circular);
// Handles: { self: [Circular *1] }

// util.types: safe runtime type checking
import { types } from 'util';
types.isPromise(Promise.resolve()); // true
types.isDate(new Date());           // true
types.isMap(new Map());             // true
```

> **Code walkthrough:** The `fileURLToPath` + `path.dirname` pattern isice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> a common interview question - ESM doesn't provide `__dirname` globally.
> `promisify` converts any callback-based API following the error-first
> convention `(err, result)` to a Promise. The worker count heuristic
> `cpus().length - 1` reserves one core for the main event loop handling
> I/O callbacks.

**Why it matters:**

`path` is security-critical. String-concatenated paths break on Windows
AND are vulnerable to traversal. `os.cpus().length` drives correct worker
thread pool sizing.

**Trade-offs:**

`path.join` normalizes separators but does NOT prevent traversal.
`path.resolve` + containment check is more expensive but required for
user-provided paths. Accept the overhead for security.

**Failure modes:**

- Hardcoded `/` separators: breaks on Windows CI/CD pipelines
- `path.join` used for security: still allows `../` traversal
- Missing `__dirname` shim in ESM: `ReferenceError: __dirname is not defined`
- Over-provisioning workers in containers: host cpus() misleads sizing

**Scale behavior:**

`os.cpus().length` is static (read once at startup). In containers,
this may report the host's CPU count, not the container's CPU limit.
Read cgroup limits for accurate container sizing.

**Decision framework:**

Path concatenation: always `path.join`. User-provided paths: `path.resolve`
+ `startsWith` check. ES modules: derive `__dirname` from `import.meta.url`.
Workers: `os.cpus().length - 1` as starting point.

**Memory model:**

`path` functions are pure synchronous computations with no I/O. `os`
module caches static system info; `freemem()` calls the OS each time.

---

### 💻 Code Example


```javascript
// BAD: anti-pattern - see GOOD example below
```

```javascript
// BAD: hardcoded separator + string concatenation
const imgPath = __dirname + '/public/images/' + filename;
// Breaks on Windows, vulnerable to traversal

// GOOD: path.join for joining (still not traversal-safe for user input)
const imgPath2 = path.join(__dirname, 'public', 'images', filename);
// path.join('/uploads', '../../../etc/passwd') -> ../../etc/passwd
// Still vulnerable!

// BETTER: path.resolve + containment check for user-provided input
function safeUserPath(base, userFilename) {
  const baseResolved = path.resolve(base);
  const targetResolved = path.resolve(base, userFilename);
  if (!targetResolved.startsWith(baseResolved + path.sep)) {
    throw Object.assign(new Error('Path traversal'), {
      code: 'ETRAVERSAL',
      filename: userFilename,
    });
  }
  return targetResolved;
}

// __dirname in ES modules (import syntax):
// CommonJS (CJS) - __dirname available globally:
// const dir = path.join(__dirname, 'public');

// ES Modules (ESM) - derive it:
import { fileURLToPath } from 'url';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dir = path.join(__dirname, 'public');
```

> **Code walkthrough:** The progression: string concat (breaks cross-platform)ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> -> `path.join` (solves separators, not security) -> `path.resolve` +
> `startsWith` (solves both). The `path.sep` suffix on the base prevents
> partial matches: `/uploads-private` starting with `/uploads` would
> falsely match without the `sep` suffix. The ES module `__dirname` pattern
> is mandatory knowledge for any project using `import` syntax.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `path.join` combines path segments correctly for any OS. `path.resolve`
> creates absolute paths. `os.cpus().length` gives the CPU count for
> worker pool sizing. `util.promisify` converts old Node.js callback
> functions to return Promises. In ES modules, `__dirname` isn't available
> - use `fileURLToPath` and `path.dirname` instead.

**Senior / Staff:**

> The security implication of path handling is the key senior concern:
> `path.join` is insufficient for user-provided paths - it normalizes but
> allows `../` traversal. `path.resolve` + `startsWith` is the correct
> pattern. Container CPU detection is a common production gotcha:
> `os.cpus().length` reports the HOST machine's CPUs, not the container's
> CPU quota. In Kubernetes, check cgroup limits or use a library that
> accounts for the container's actual allocation. `util.promisify` is
> valuable for adapting older third-party libraries with callback APIs.

---

### ⚠️ Common Misconceptions

**"path.join prevents path traversal":**

It normalizes separators but `path.join('/uploads', '../etc/passwd')`
still resolves outside the directory. Only `path.resolve` + containment
check prevents traversal.

**"os.cpus().length gives container CPU quota":**

In Docker/Kubernetes, this reports the HOST machine's CPU count. If the
container is limited to 2 CPUs on a 32-core host, `cpus().length` returns
32. Inspect cgroup limits separately.

**"util.promisify works on all callback APIs":**

Only for error-first convention `callback(error, result)`. Non-standard
signatures need manual Promise wrappers.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: `ReferenceError: __dirname is not defined`**

```javascript
// FIX:
import { fileURLToPath } from 'url';
import path from 'path';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
```

> **Code walkthrough:** This Unknown example demonstrates variable declaration. **KEY MECHANISM:** const prevents reassignment but not mutation; the reference is locked, the value is not. **WHY IT MATTERS:** const obj = {}; obj.x = 1 works - const does not freeze the object. **TAKEAWAY: use Object.freeze() to prevent mutation; const only guards the binding.**

**Symptom: Files not found on Windows (works on macOS)**

```javascript
// DIAGNOSE:
console.log('sep:', path.sep);  // Should be \ on Windows
console.log('path:', filePath); // Look for mixed separators / and \
// FIX: Replace all hardcoded '/' with path.join/path.resolve
```

> **Code walkthrough:** This Unknown example demonstrates JavaScript pattern. **KEY MECHANISM:** V8 JIT-compiles hot functions to machine code; polymorphic call sites deoptimize the function. **WHY IT MATTERS:** closure captures the reference not the value - loop variables captured in closures retain last value. **TAKEAWAY: use block-scoped let/const in loops and closures to prevent stale reference bugs.**

**Symptom: Worker threads underperforming in containers**

`os.cpus().length` in Docker returns host CPU count. Container quota is 2
but returns 32, spawning 31 workers competing for 2 CPUs.

```javascript
// Read actual container quota from cgroup:
import { readFileSync } from 'fs';
function getContainerCPUs() {
  try {
    const quota = parseInt(
      readFileSync('/sys/fs/cgroup/cpu/cpu.cfs_quota_us', 'utf8')
    );
    const period = parseInt(
      readFileSync('/sys/fs/cgroup/cpu/cpu.cfs_period_us', 'utf8')
    );
    if (quota > 0) return Math.ceil(quota / period);
  } catch {}
  return os.cpus().length;
}
```

> **Code walkthrough:** This Unknown example demonstrates variable declaration using container. **KEY MECHANISM:** const prevents reassignment but not mutation; the reference is locked, the value is not. **WHY IT MATTERS:** const obj = {}; obj.x = 1 works - const does not freeze the object. **TAKEAWAY: use Object.freeze() to prevent mutation; const only guards the binding.**

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| path.join vs path.resolve security | 2-3 min | Both, plus startsWith |
| __dirname in ES modules | 2-3 min | fileURLToPath + dirname |
| Container CPU detection | 2-3 min | cgroup vs os.cpus() |
| util.promisify requirements | 2-3 min | Error-first convention |
| path.sep in regex patterns | 2-3 min | Cross-platform correctness |
| os.tmpdir use cases | 2-3 min | Temp files, cleanup |
| util.inspect vs JSON.stringify | 2-3 min | Circular, functions, depth |

---

**[JUNIOR] Q1 - [MECHANISM] You see `ReferenceError: __dirname is not defined`. Fix it and**
explain why it happens.** `[JUNIOR]` DEBUGGING

> **Answer:**
>
> ```javascript
> // BROKEN in ESM (type: "module" in package.json):
> import path from 'path';
> const configDir = path.join(__dirname, 'config');
> // ReferenceError: __dirname is not defined
>
> // FIXED:
> import path from 'path';
> import { fileURLToPath } from 'url';
>
> const __filename = fileURLToPath(import.meta.url);
> const __dirname = path.dirname(__filename);
>
> const configDir = path.join(__dirname, 'config');
> ```
>
> WHY: CommonJS wraps every module in a function that receives `__dirname`,
> `__filename`, `module`, `exports`, and `require`. ES modules are true
> module scope - none of those wrappers exist. `import.meta.url` is the
> ESM equivalent: `file:///srv/app/index.js`. `fileURLToPath` converts
> it to a native path (`/srv/app/index.js`). `path.dirname` strips the
> filename.
>
> *What separates good from great:* Many third-party packages still use
> CJS internally; the error surfaces when YOUR code is ESM but uses a
> CJS-style pattern from a tutorial. Also knowing that creating the
> `__dirname` shim at the module level once (not inside functions) is
> the correct pattern.

---

**[SENIOR] Q2 - [DEBUGGING] What is the security risk with path concatenation, and how do you prevent path traversal?**

> **Answer:**
>
> Path traversal attacks use `../` sequences in user-supplied filenames to escape the intended directory and read arbitrary files from the server.
>
> ```javascript
> // VULNERABLE: direct use of user input in path
> app.get('/files/:name', (req, res) => {
>   const filePath = './uploads/' + req.params.name;
>   // If name = '../../etc/passwd', reads /etc/passwd
>   res.sendFile(filePath);
> });
>
> // FIXED: resolve and verify containment
> import path from 'path';
> const UPLOAD_DIR = path.resolve('./uploads');
>
> app.get('/files/:name', (req, res) => {
>   const resolved = path.resolve(UPLOAD_DIR, req.params.name);
>   if (!resolved.startsWith(UPLOAD_DIR + path.sep)) {
>     return res.status(403).end();
>   }
>   res.sendFile(resolved);
> });
> ```
>
> `path.resolve` handles `../` sequences, URL-encoded traversal (`%2F`), and Unicode lookalikes. The `startsWith(UPLOAD_DIR + path.sep)` check prevents the edge case where the filename matches the directory prefix exactly.
>
> *What separates good from great:* Regex validation alone (e.g., `/^[\w-]+\.\w+$/`) is insufficient for path security. URL-encoded sequences bypass regex but are resolved by `path.resolve`. Always use containment check as the authoritative gate.

---

**[JUNIOR] Q3 - [MECHANISM] Why does `os.cpus().length` sometimes return the wrong value in containers?**

> **Answer:**
>
> `os.cpus()` reads from the OS interface, which in a container reports the HOST machine's CPU count, not the container's CPU limit. A container configured with 0.5 CPU shares on a 32-core host reports `os.cpus().length = 32`.
>
> This affects worker thread pool sizing - a Node.js app that creates `os.cpus().length` workers will spawn 32 threads when it has only 0.5 CPU available, causing extreme thread contention.
>
> ```javascript
> // Safer: use cgroup-aware CPU detection
> function getContainerCPUCount() {
>   try {
>     // Read cgroup v2 CPU limit
>     const quota = fs.readFileSync(
>       '/sys/fs/cgroup/cpu.max', 'utf8'
>     ).trim().split(' ');
>     if (quota[0] === 'max') return os.cpus().length;
>     return Math.ceil(parseInt(quota[0]) / parseInt(quota[1]));
>   } catch {
>     return os.cpus().length; // fallback for non-container
>   }
> }
>
> const WORKERS = Math.max(1, getContainerCPUCount());
> ```
>
> *What separates good from great:* This is a production issue at scale. Apps running in Kubernetes with resource limits but no cgroup-aware CPU detection silently over-thread, causing p99 latency spikes under load.

---

**[JUNIOR] Q4 - [MECHANISM] What are the requirements for using `util.promisify`?**

> **Answer:**
>
> `util.promisify` wraps a function that follows Node.js error-first callback convention (`(err, result) => void`) and returns a Promise-returning version.
>
> Requirements: (1) the function's last argument must be a callback, (2) the callback's first argument must be the error (`null` on success), (3) the callback's second argument is the success value.
>
> ```javascript
> const { promisify } = require('util');
> const fs = require('fs');
>
> // Works: fs.readFile follows error-first callback convention
> const readFileAsync = promisify(fs.readFile);
> const data = await readFileAsync('./file.txt', 'utf8');
>
> // Works: custom error-first callback function
> function loadUser(id, callback) {
>   db.query('SELECT * FROM users WHERE id = ?', [id], callback);
> }
> const loadUserAsync = promisify(loadUser);
>
> // Does NOT work: callback not error-first
> function badCallback(result, err) { } // wrong order
> // promisify(badCallback) - will never properly detect errors
>
> // Custom Promise return: use util.promisify.custom symbol
> readFileAsync[util.promisify.custom] = (path, options) => {
>   return new Promise((resolve, reject) => {
>     // custom implementation
>   });
> };
> ```
>
> *What separates good from great:* Many Node.js built-in functions already have Promise versions in `fs.promises`, `dns.promises`, etc. Use those instead of promisifying manually - they are more performant and correctly typed.

---

**[JUNIOR] Q5 - [DEBUGGING] Why does `path.sep` matter in regex patterns, and how do you use it correctly?**

> **Answer:**
>
> `path.sep` is `/` on Unix/macOS and `\\` on Windows. Hardcoding `/` in path-related regex breaks on Windows deployments.
>
> ```javascript
> import path from 'path';
>
> // WRONG on Windows (hardcoded Unix separator)
> function getRelative(base, full) {
>   return full.replace(base + '/', '');
> }
>
> // WRONG: escaping issue - backslash in regex needs double escape
> const sep = path.sep; // '\' on Windows
> const regex = new RegExp(sep); // ERROR or wrong match
>
> // CORRECT: escape the separator for use in RegExp
> const escapedSep = path.sep.replace(/\\/g, '\\\\');
> const pathSepRegex = new RegExp(escapedSep, 'g');
>
> // BETTER: use path.relative instead of regex manipulation
> const relative = path.relative(baseDir, fullPath);
> ```
>
> In most cases, prefer `path.relative`, `path.join`, and `path.resolve` over manual string manipulation or regex. They handle separators correctly for the current OS.
>
> *What separates good from great:* Node.js path utilities normalize separators. `path.join('a', 'b')` always produces the correct result for the current OS. Only resort to regex when you have no alternative, and always use `path.sep` as the separator source.

---

**[JUNIOR] Q6 - [MECHANISM] What is `os.tmpdir()` and when should you use it?**

> **Answer:**
>
> `os.tmpdir()` returns the OS-designated temporary directory (`/tmp` on Linux/macOS, `%TEMP%` on Windows). Use it when you need to write temporary files that should not persist beyond the current operation.
>
> ```javascript
> import os from 'os';
> import path from 'path';
> import fs from 'fs/promises';
> import crypto from 'crypto';
>
> async function processUpload(fileBuffer) {
>   // Create a unique temp file path
>   const tmpPath = path.join(
>     os.tmpdir(),
>     `upload-${crypto.randomUUID()}.tmp`
>   );
>
>   try {
>     await fs.writeFile(tmpPath, fileBuffer);
>     // Process the file...
>     const result = await processFile(tmpPath);
>     return result;
>   } finally {
>     // Always clean up temp files
>     await fs.unlink(tmpPath).catch(() => {}); // ignore if already deleted
>   }
> }
> ```
>
> Important: in containers, `/tmp` may be memory-mapped (tmpfs). Writing large files to `/tmp` consumes container memory. For large temporary files, use a mounted volume instead.
>
> *What separates good from great:* Always clean up temp files in a `finally` block. Temp files in `/tmp` are not automatically cleaned during process lifetime - only on OS reboot or by explicit cleanup cron jobs.

---

**[JUNIOR] Q7 - [MECHANISM] What is the difference between `util.inspect` and `JSON.stringify` for debugging?**

> **Answer:**
>
> `JSON.stringify` only handles JSON-serializable values. It silently drops functions, `undefined`, `Symbol`, and produces `[object Object]` for circular references (actually throws with a circular reference error).
>
> `util.inspect` is designed for debugging - it handles circular references, functions, class instances, Symbols, and produces human-readable output.
>
> ```javascript
> import util from 'util';
>
> const obj = {
>   fn: () => 'hello',         // JSON.stringify drops this
>   undef: undefined,          // JSON.stringify drops this
>   sym: Symbol('id'),         // JSON.stringify drops this
>   date: new Date(),          // JSON.stringify converts to string
>   nested: { deep: { data: 1 } },
> };
>
> // JSON.stringify: { "date": "2024-01-01T..." }
> // (fn, undef, sym all silently dropped)
>
> // util.inspect: shows everything
> console.log(util.inspect(obj, { depth: Infinity, colors: true }));
> // { fn: [Function: fn], undef: undefined, sym: Symbol(id), ... }
>
> // Circular reference handling:
> const circ = {};
> circ.self = circ;
> JSON.stringify(circ);        // TypeError: circular structure
> util.inspect(circ);          // { self: [Circular *1] }
> ```
>
> *What separates good from great:* `util.inspect` accepts depth and colors options. Set `depth: Infinity` for fully-expanded objects. In production logging, use `JSON.stringify` with a replacer function to strip non-serializable values rather than using `inspect` (which produces non-parseable output).

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



