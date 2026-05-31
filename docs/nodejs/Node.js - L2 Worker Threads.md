---
layout: default
title: "Node.js - L2 Worker Threads"
parent: "Node.js"
nav_order: 6
permalink: /nodejs/l2-worker-threads/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Worker Threads and CPU-bound Tasks](#worker-threads-and-cpu-bound-tasks) | medium |
| 2 | [Child Processes](#child-processes) | medium |

---

# Worker Threads and CPU-bound Tasks

---

### 🎯 Model Answer

**30 seconds:**

> Worker threads run JavaScript in a separate thread, solving Node.js's
> single-threaded CPU-blocking problem. The main thread and workers
> share memory via `SharedArrayBuffer`; pass messages via
> `postMessage(data)` / `parentPort.on('message', ...)`. Use worker
> threads for: image processing, video transcoding, PDF generation,
> JSON parsing of large files, crypto operations, ML inference. Not
> for: I/O-bound work (the event loop handles that fine). Each worker
> gets its own V8 instance and event loop.

**Blank Mind Recovery:**

**(1) What:** "Separate thread for CPU work. Own V8 + event loop."

**(2) When:** "CPU-bound work that would block the main event loop."

**(3) Not when:** "I/O-bound (DB queries, HTTP). Event loop handles those."

---

### 📘 Concept Explanation

**What it is:**

Worker threads provide true multi-threading in Node.js for CPU-intensive
operations, preventing the main event loop from blocking.

**How it works:**

```
Worker threads architecture:

  Main thread (event loop):
    - Handles HTTP, I/O, connections
    - Creates workers for CPU tasks
    - Communicates via message passing

  Worker thread:
    - Separate V8 instance + event loop
    - Runs JavaScript in parallel
    - Can share memory (SharedArrayBuffer)
    - Full Node.js API access (including I/O)

  Communication patterns:
    1. Message passing (data copying):
      // Main thread:
      const worker = new Worker('./worker.js',
        { workerData: { task: 'process', data: largeArray } }
      );
      worker.on('message', (result) => console.log(result));
      worker.on('error', (err) => handleError(err));

      // worker.js:
      import { workerData, parentPort } from 'worker_threads';
      const result = heavyComputation(workerData.data);
      parentPort.postMessage(result);

    2. SharedArrayBuffer (zero-copy):
      // Shared memory between threads:
      const sharedBuf = new SharedArrayBuffer(4);
      const arr = new Int32Array(sharedBuf);

      const worker = new Worker('./worker.js',
        { workerData: { sharedBuf } }
      );
      // Worker can read/write arr directly (no copy)
      // Requires atomic operations for synchronization:
      Atomics.add(arr, 0, 1); // thread-safe increment

  Worker pool pattern:
    Creating workers has overhead (~50ms, ~10MB).
    For many tasks: create a pool, reuse workers.
    Libraries: piscina (recommended), workerpool
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Production) - Worker pool with piscina:**

```javascript
// Using piscina - the recommended worker pool:
// npm install piscina

// main.js:
import Piscina from 'piscina';
import { readFile } from 'fs/promises';

const pool = new Piscina({
  filename: new URL('./image-worker.js', import.meta.url).href,
  maxThreads: 4,  // default: (CPU cores - 1) or 4
});

// Handle image resizes concurrently:
async function processImages(imagePaths) {
  const tasks = imagePaths.map(path =>
    pool.run({ imagePath: path, width: 800, height: 600 })
  );
  return Promise.all(tasks);
}

// image-worker.js - runs in worker thread:
import sharp from 'sharp'; // CPU-intensive image library

export default async function({ imagePath, width, height }) {
  const buffer = await readFile(imagePath);
  const resized = await sharp(buffer)
    .resize(width, height, { fit: 'inside' })
    .jpeg({ quality: 85 })
    .toBuffer();
  return resized; // transferred back to main thread
}

// BAD: CPU work on main thread (blocks event loop):
app.post('/process-image', async (req, res) => {
  const imageData = req.body;
  // This blocks ALL incoming requests during processing:
  const processed = expensiveImageResize(imageData);
  res.json({ processed });
});

// GOOD: offload to worker pool:
app.post('/process-image', asyncRoute(async (req, res) => {
  const imageData = req.body;
  // Main thread returns immediately after posting to pool:
  const processed = await pool.run({ imageData });
  res.json({ processed });
}));
```

> **Code walkthrough:** `piscina` manages a pool of worker threads,
> reusing them across tasks to avoid the ~50ms startup cost per worker.
> `maxThreads: 4` limits to 4 concurrent CPU-bound tasks - matching
> available CPU cores minus one (leaving one for the main event loop).
> The worker function is a default-export async function: piscina
> calls it with the data argument and returns the result as a Promise.
> The BAD example shows what happens without workers: image processing
> is synchronous/CPU-intensive, blocking the event loop during the
> entire operation - all other HTTP requests queue up and timeout.

---

### ⚖️ Comparison Table

| Pattern | Use case | Overhead | Shared state |
|---|---|---|---|
| Event loop | I/O-bound | None | Shared (single thread) |
| Worker threads | CPU-bound | ~50ms startup | SharedArrayBuffer |
| Child processes | Isolation, legacy | ~100ms | IPC or files |
| Cluster | HTTP horizontal scale | ~200ms | Separate processes |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Worker threads let me run CPU-intensive code in a separate thread
> so it doesn't block the main event loop. I create a worker with
> `new Worker('./worker.js')`, pass data with `workerData`, and get
> results via `worker.on('message')`. I use the `piscina` library for
> a thread pool instead of creating workers manually.

**Senior / Staff:**

> The key design question: is the work I/O-bound or CPU-bound? I/O-bound
> operations (DB queries, HTTP calls) should use the event loop naturally.
> CPU-bound work (image processing, ML inference, cryptography, data
> transformation) blocks the event loop and needs worker threads. Worker
> thread startup cost is significant (~50ms, ~10MB), so always use a
> pool for repeated tasks. SharedArrayBuffer with Atomics provides zero-copy
> data sharing for large data sets, avoiding the serialization cost of
> message passing.

---

### ⚠️ Common Misconceptions

**Misconception: Worker threads replace the cluster module.**

Cluster spawns multiple Node.js processes and load-balances HTTP
connections across them (horizontal scaling across CPU cores). Worker
threads run CPU tasks in background threads (vertical parallelism).
They solve different problems: cluster for HTTP throughput, workers
for CPU-intensive per-request work.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Worker thread pool backlog grows unboundedly.**

Cause: Worker tasks arrive faster than the pool can process them.
`piscina.queueSize` grows without bound.

Fix:
```javascript
const pool = new Piscina({
  filename: './worker.js',
  maxThreads: 4,
  maxQueue: 100  // reject when queue exceeds 100
});

try {
  await pool.run(task);
} catch (err) {
  if (err.message.includes('queue is full')) {
    res.status(503).json({ error: 'Server busy' });
  }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| When should you use Worker Threads? | Decision | ★★☆ | 2 min |
| How do threads communicate in Node.js? | Mechanism | ★★☆ | 3 min |
| Worker threads vs cluster - difference? | Comparison | ★★★ | 3 min |
| What is SharedArrayBuffer? | Mechanism | ★★★ | 3 min |
| How do you implement a thread pool? | Code | ★★★ | 3 min |
| What is the startup cost of worker threads? | Production | ★★☆ | 2 min |

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


# Child Processes

---

### 🎯 Model Answer

**30 seconds:**

> Child processes run separate OS processes from Node.js. Four methods:
> `exec()` (command string, buffered output), `spawn()` (streaming I/O,
> best for large output), `fork()` (Node.js-specific with IPC channel),
> `execFile()` (file without shell). Use for: running CLI tools (git,
> ffmpeg, Python scripts), shell commands, or isolating crashes from
> the main process. Key: `fork()` for Node.js child processes with
> message passing. `spawn()` for shell commands with streaming output.

**Blank Mind Recovery:**

**(1) Four methods:** "`exec` (buffered cmd). `spawn` (streaming). `fork`
(Node.js + IPC). `execFile` (file, no shell)."

**(2) When:** "Run external programs. Shell commands. Process isolation."

**(3) Security:** "Never pass user input to `exec()` directly - shell injection."

---

### 📘 Concept Explanation

**What it is:**

Node.js's API for spawning child OS processes, enabling interaction
with shell commands, external programs, and isolated Node.js workers.

**How it works:**

```
child_process methods:

  exec(command, options, callback):
    - Runs command in a shell
    - Buffers ALL output in memory
    - Callback with (err, stdout, stderr)
    - Good for small output commands

    exec('git log --oneline -10', (err, stdout) => {
      console.log(stdout);
    });
    // Or promisified:
    const { exec } = require('util').promisify(
      require('child_process').exec
    );
    const { stdout } = await exec('git status');

  spawn(command, args, options):
    - No shell (safer, no injection)
    - Streaming stdout/stderr
    - Good for long-running or large output
    - Returns ChildProcess with stream interface

    const ls = spawn('ls', ['-la', '/tmp']);
    ls.stdout.on('data', data => console.log(data.toString()));
    ls.on('close', code => console.log('exit code:', code));

  fork(modulePath, args, options):
    - Spawns another Node.js process
    - Built-in IPC channel (send/message)
    - Good for process isolation in Node.js apps

    const child = fork('./heavy-task.js');
    child.send({ task: 'compute', data: inputData });
    child.on('message', result => handleResult(result));

  execFile(file, args, options, callback):
    - Like exec but runs a file directly (no shell)
    - Safer than exec for paths

  Security:
    // CRITICAL: NEVER use user input in exec:
    exec(`grep ${userInput} /var/log/app.log`);
    // userInput = "; rm -rf /var" = disaster

    // SAFE: use spawn with args array:
    spawn('grep', [userInput, '/var/log/app.log']);
    // args are passed directly to execv, no shell interpretation
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Production) - Running external tools safely:**

```javascript
import { spawn, exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// Safe: spawn with args array (no shell injection):
async function runFFmpeg(inputPath, outputPath, width, height) {
  return new Promise((resolve, reject) => {
    const ff = spawn('ffmpeg', [
      '-i', inputPath,
      '-vf', `scale=${width}:${height}`,
      '-y', outputPath  // -y = overwrite
    ]);

    let stderr = '';
    ff.stderr.on('data', d => { stderr += d.toString(); });

    ff.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`ffmpeg failed: ${stderr}`));
      } else {
        resolve(outputPath);
      }
    });

    ff.on('error', reject); // command not found etc.
  });
}

// Process isolation with fork:
// parent.js:
import { fork } from 'child_process';

function runInIsolation(task) {
  return new Promise((resolve, reject) => {
    const child = fork('./worker-process.js', [], {
      timeout: 30000 // kill after 30s
    });

    child.send(task);

    child.on('message', resolve);
    child.on('error', reject);
    child.on('exit', (code) => {
      if (code !== 0) reject(new Error(`Worker exited: ${code}`));
    });
  });
}

// worker-process.js:
process.on('message', async (task) => {
  try {
    const result = await processTask(task);
    process.send(result);
    process.exit(0);
  } catch (err) {
    process.send({ error: err.message });
    process.exit(1);
  }
});
```

> **Code walkthrough:** `spawn` with an args array is the safe pattern
> for external programs - arguments are passed directly to `execv` without
> shell interpretation. If user-supplied data ends up in `exec()` string,
> it can inject shell commands (the classic shell injection vulnerability).
> The FFmpeg example shows proper error handling: `stderr` accumulates
> error output (ffmpeg logs progress to stderr even on success), and
> `close` fires with the exit code. The `fork` pattern enables process
> isolation: if the worker crashes, only the child process dies, the
> parent continues. The `timeout` option in fork options kills the
> child if it takes too long.

---

### ⚖️ Comparison Table

| Method | Shell | Output | Use case |
|---|---|---|---|
| `exec` | Yes | Buffered | Short commands |
| `spawn` | No | Streaming | External programs |
| `fork` | No | IPC messages | Node.js isolation |
| `execFile` | No | Buffered | Safe file execution |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Child processes let me run shell commands or external programs from
> Node.js. `exec()` runs a command and gives me the output as a string.
> `spawn()` is better for large output because it streams. `fork()`
> creates another Node.js process with two-way communication. I always
> use `spawn` with an args array instead of `exec` with user input to
> avoid shell injection.

**Senior / Staff:**

> The design choice: child processes for external programs and process
> isolation; worker threads for CPU-intensive JavaScript. Child processes
> have more overhead (~100ms startup, separate memory) but are completely
> isolated - a crash in a child process doesn't affect the parent.
> Worker threads share memory and are faster but a thrown error
> can affect the pool. For running untrusted code or CPU-intensive
> non-JS work (Python ML model, ImageMagick), child processes are correct.

---

### ⚠️ Common Misconceptions

**Misconception: `exec()` is safe with proper string escaping.**

Shell escaping is notoriously complex and varies by OS. Any manual
escaping approach will eventually fail. The only safe approach is
`spawn()` with an args array, which passes arguments directly to
the OS without shell interpretation. Never use `exec()` with
user-controlled input.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `ENOENT` when spawning a process.**

Cause: The executable isn't in `PATH` or the path is wrong.

Diagnose:
```bash
# Test outside Node.js:
which ffmpeg  # find the full path

# In Node.js: provide full path:
spawn('/usr/bin/ffmpeg', [...args]);
# Or ensure PATH is set correctly in process.env
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| `exec` vs `spawn` - when to use each? | Comparison | ★★☆ | 2 min |
| What is shell injection and how to prevent it? | Security | ★★★ | 3 min |
| `fork` vs worker threads - difference? | Comparison | ★★★ | 3 min |
| How do you handle a child process crash? | Failure | ★★☆ | 2 min |

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



