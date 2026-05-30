---
layout: default
title: "Node.js - L4 Debugging"
parent: "Node.js"
nav_order: 11
permalink: /nodejs/l4-debugging/
---

# Production Debugging and Heap Analysis

---

### 🎯 Model Answer

**30 seconds:**

> Production debugging in Node.js requires non-invasive tools that
> don't require restarts. Key: `--inspect` flag opens a Chrome DevTools
> debugging port. `v8.writeHeapSnapshot()` creates a heap dump. `node --prof`
> records CPU profile. For live production: `process.kill(pid, 'SIGUSR2')`
> triggers heap snapshot programmatically. Structured logging (pino, winston)
> with correlation IDs is the first line of diagnosis. Distributed
> tracing (OpenTelemetry) shows cross-service latency. Heap analysis:
> load `.heapsnapshot` in Chrome DevTools Memory tab.

**3 minutes:**

**Production debugging hierarchy:**

1. **Structured logs with correlation IDs** - fastest, zero overhead
2. **Metrics** (event loop lag, memory, req/s) - continuous visibility
3. **Distributed traces** - for cross-service latency problems
4. **CPU flamegraph** - for CPU hotspot investigation
5. **Heap snapshot** - for memory leak investigation
6. **Remote debugger** - last resort, one instance only, brief session

**The core challenge:** Production servers can't be paused for debugging
(customers affected). All techniques must work without stopping the server.

**Blank Mind Recovery:**

**(1) First:** "Logs + metrics. Correlation ID. Look before instrumenting."

**(2) Memory leak:** "Heap snapshot: `v8.writeHeapSnapshot()`. Compare
before/after suspected operation."

**(3) CPU problem:** "`0x` flamegraph or `--prof`. Find the hot function."

---

### 📘 Concept Explanation

**What it is:**

Techniques and tools for diagnosing production issues in Node.js:
from structured logging to heap analysis and remote debugging.

**How it works:**

```
Debugging tools and their use cases:

  1. Structured logging (pino - fastest logger):
     import pino from 'pino';
     const log = pino({
       level: process.env.LOG_LEVEL ?? 'info',
     });

     // Correlation ID for request tracing:
     app.use((req, res, next) => {
       req.correlationId = req.headers['x-correlation-id']
         ?? crypto.randomUUID();
       req.log = log.child({ correlationId: req.correlationId });
       next();
     });

     app.get('/api/users/:id', (req, res) => {
       req.log.info({ userId: req.params.id }, 'Fetching user');
       // log output: {"correlationId":"abc123","userId":"42","msg":"Fetching user"}
       // Can trace ONE request across all log entries
     });

  2. Process signal for heap snapshot (no restart):
     process.on('SIGUSR2', () => {
       const filename = v8.writeHeapSnapshot();
       log.info({ filename }, 'Heap snapshot written');
     });
     // Trigger: kill -SIGUSR2 <pid>
     // Or: process.kill(process.pid, 'SIGUSR2')

  3. Remote debugging (one instance, brief):
     node --inspect=0.0.0.0:9229 server.js
     # Connect via SSH tunnel:
     # ssh -L 9229:localhost:9229 user@server
     # Open chrome://inspect in local Chrome

  4. Memory leak workflow:
     a) Monitor: watch heapUsed grow via metrics
     b) Trigger snapshot: SIGUSR2 (baseline)
     c) Run suspected leak operation N times
     d) Trigger snapshot again (SIGUSR2)
     e) Load both in Chrome DevTools Memory > Comparison
     f) Sort by "Retained Size" difference
     g) Click suspect objects, follow "Retainers" path

  5. CPU profiling without restart (Node.js 16+):
     node --cpu-prof server.js
     # Or with inspector API:
     import inspector from 'node:inspector';
     const session = new inspector.Session();
     session.connect();
     session.post('Profiler.enable', () => {
       session.post('Profiler.start', () => {
         setTimeout(() => {
           session.post('Profiler.stop', (err, { profile }) => {
             fs.writeFileSync('profile.cpuprofile',
               JSON.stringify(profile));
           });
         }, 30000); // profile for 30 seconds
       });
     });
```

---

### 💻 Code Example

**Example (Debugging) - Memory leak detection in production:**

```javascript
import v8 from 'v8';
import { writeFile } from 'fs/promises';
import { monitorEventLoopDelay } from 'perf_hooks';

// Expose memory and event loop metrics for monitoring:
const histogram = monitorEventLoopDelay({ resolution: 20 });
histogram.enable();

// Metrics endpoint (expose to Prometheus/Grafana):
app.get('/metrics', (req, res) => {
  const memory = process.memoryUsage();
  const metrics = [
    `nodejs_heap_used_bytes ${memory.heapUsed}`,
    `nodejs_heap_total_bytes ${memory.heapTotal}`,
    `nodejs_rss_bytes ${memory.rss}`,
    `nodejs_external_bytes ${memory.external}`,
    `nodejs_event_loop_lag_p50 ${histogram.percentile(50) / 1e6}`,
    `nodejs_event_loop_lag_p99 ${histogram.percentile(99) / 1e6}`,
  ].join('\n');
  res.type('text/plain').send(metrics);
});

// Heap snapshot on demand (HTTP endpoint for internal use):
app.post('/debug/heapdump', (req, res) => {
  // IMPORTANT: restrict to internal/admin access only
  if (req.ip !== '127.0.0.1') {
    return res.status(403).end();
  }
  try {
    const filename = v8.writeHeapSnapshot();
    res.json({ filename });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Detect memory growth trend:
const heapHistory = [];
setInterval(() => {
  heapHistory.push(process.memoryUsage().heapUsed);
  if (heapHistory.length > 12) heapHistory.shift(); // 1h window at 5min
  if (heapHistory.length >= 6) {
    const trend = heapHistory.slice(-6);
    const growing = trend.every(
      (v, i) => i === 0 || v >= trend[i - 1]
    );
    if (growing) {
      console.warn('Memory growing for 30+ minutes - possible leak');
    }
  }
}, 5 * 60 * 1000); // every 5 minutes
```

> **Code walkthrough:** The metrics endpoint exposes Node.js internal
> metrics in Prometheus format. `histogram.percentile(99) / 1e6` converts
> nanoseconds to milliseconds for event loop lag p99. The heap snapshot
> endpoint is restricted to `127.0.0.1` - exposing it publicly leaks
> all application memory contents. The trend detection watches 6
> consecutive memory measurements (30 minutes with 5-minute interval):
> if heap consistently grows without shrinking, it logs a warning. This
> is a simple but effective production-safe leak detector that runs
> continuously without heap dumps.

---

### ⚖️ Comparison Table

| Technique | Overhead | Restarts? | Use case |
|---|---|---|---|
| Structured logs | Minimal | No | All issues |
| Metrics + Grafana | Minimal | No | Trend detection |
| Heap snapshot | High (brief) | No | Memory leaks |
| CPU flamegraph | Medium | No | CPU hotspots |
| Remote debugger | High | No | Interactive debugging |
| Core dump | Extreme | No | Crash analysis |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> For production debugging I rely on structured logs with correlation
> IDs first - they let me trace a single request across all log entries.
> For memory leaks, I take heap snapshots with `v8.writeHeapSnapshot()`
> and compare in Chrome DevTools. For CPU problems, I use `clinic.js`
> or `0x` for flamegraphs.

**Senior / Staff:**

> Production debugging is about minimum interruption maximum signal.
> The debugging stack: always-on structured logging (pino, zero overhead
> in hot paths), continuous metrics (event loop lag p99, heapUsed trend),
> distributed traces for cross-service issues. When metrics indicate
> a problem: heap snapshot via SIGUSR2 handler or admin endpoint
> (never restart!). CPU profiling via inspector API or `--prof`
> attached to one instance. Remote debugger only as last resort
> and only briefly - it pauses V8 at breakpoints, affecting all traffic.

---

### ⚠️ Common Misconceptions

**Misconception: `console.log` is fine for production debugging.**

`console.log` is synchronous, unstructured, and expensive under load.
`pino` (JSON logger) is 5-10x faster because it buffers writes and uses
async I/O. Structured JSON logs are machine-parseable by log aggregators
(Datadog, Splunk, CloudWatch). Unstructured text requires regex parsing
and loses context like correlation IDs.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `SIGBUS` or `SIGSEGV` crashes Node.js process.**

Cause: Native addon (N-API/nan) memory corruption, or OS-level issue.

Diagnose:
```bash
# Enable core dumps:
ulimit -c unlimited
node server.js

# When crash occurs: core file created
# Analyze with lldb or gdb:
lldb --core core.12345 $(which node)
(lldb) bt  # backtrace shows crash location
```

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How do you debug a production Node.js memory leak? | Debugging | ★★★ | 5 min |
| What is a correlation ID? | Definition | ★★☆ | 2 min |
| How do you take a heap snapshot without restarting? | Mechanism | ★★★ | 3 min |
| `console.log` vs structured logging? | Comparison | ★★☆ | 2 min |
| How do you detect event loop blocking in production? | Debugging | ★★★ | 3 min |
| How would you debug a CPU spike in production? | Debugging | ★★★ | 4 min |
| What metrics would you monitor for a Node.js service? | Production | ★★★ | 4 min |
| Remote debugger in production - when and how? | Production | ★★★ | 3 min |
| How does distributed tracing help debugging? | Mechanism | ★★★ | 3 min |
| Walk me through debugging: "response times are slow" | BEHAVIORAL | ★★★ | 5 min |
| How do you profile without restarting the server? | Production | ★★★ | 4 min |
| What's in a production-ready logging setup? | Design | ★★★ | 4 min |

**Q: Walk through diagnosing a production Node.js service with 5s response times.**

A:

**Step 1: Check metrics first.**
- Event loop lag p99: if >500ms -> blocking in event loop
- CPU: if >80% -> CPU-bound work
- Memory: if growing -> GC pressure
- Error rate: if elevated -> errors are slow paths
- DB query p99: if >1s -> database bottleneck

**Step 2: Event loop blocking (p99 lag >100ms).**
- Take CPU flamegraph: `0x` or `--prof` on one instance
- Look for thick synchronous stacks in flamegraph
- Common culprits: JSON.parse on large objects, crypto, regex

**Step 3: DB bottleneck (DB query p99 high).**
- Check connection pool: pool exhausted? (waiting for connection)
- Check slow query log in database
- Look for N+1 queries (100 queries per request)
- Missing indexes: `EXPLAIN ANALYZE` on slow queries

**Step 4: Memory/GC pressure.**
- Heap snapshot comparison
- Look for growing object counts
- Check GC pause duration in `--trace-gc` output

*What separates good from great:* Correlating multiple metrics
simultaneously. High event loop lag AND high CPU = blocking synchronous
work. High event loop lag AND low CPU = many small async callbacks
queuing. Low event loop lag AND slow responses = I/O bottleneck
outside Node.js (database, external service).
