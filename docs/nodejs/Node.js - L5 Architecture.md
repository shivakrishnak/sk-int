---
layout: default
title: "Node.js - L5 Architecture"
parent: "Node.js"
nav_order: 12
permalink: /nodejs/l5-architecture/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Node.js Service Architecture at Scale](#nodejs-service-architecture-at-scale) | medium |

---

# Node.js Service Architecture at Scale

---

### 🎯 Model Answer

**30 seconds:**

> At scale, Node.js architecture decisions center on: (1) when to split
> into microservices vs monolith (microservices add network overhead and
> complexity - avoid until you need team independence or different
> scaling requirements); (2) how to handle CPU-bound work (worker
> threads or separate Python/Go service); (3) async patterns for
> long-running tasks (message queues - BullMQ, Kafka); (4) graceful
> shutdown and health checks for Kubernetes compatibility; (5) connection
> pooling and shared-nothing architecture.

**Blank Mind Recovery:**

**(1) CPU work:** "Worker threads (same process) or sidecar service
(different language)."

**(2) Long tasks:** "Message queue (BullMQ) - decouple and retry."

**(3) Kubernetes:** "Health endpoint, graceful shutdown, stateless."

---

### 📘 Concept Explanation

**What it is:**

Architectural patterns for building maintainable, scalable Node.js
services for production at scale.

**How it works:**

```
Node.js service architecture layers:

  Presentation layer:
    - Express/Fastify router
    - Input validation (zod)
    - Response formatting
    - Rate limiting, CORS, auth middleware

  Application layer (use cases):
    - Business logic
    - Orchestrates domain services
    - No framework dependencies
    - Pure functions, easy to test

  Domain layer:
    - Core business entities
    - Business rules
    - Repository interfaces (not implementations)

  Infrastructure layer:
    - Database (pg, mongoose)
    - Cache (ioredis)
    - Message queue (bullmq, kafka)
    - External HTTP clients
    - File storage (S3)

  Key architectural patterns:

  1. Repository pattern:
     interface UserRepository {
       findById(id: string): Promise<User | null>;
       save(user: User): Promise<void>;
     }
     // Implementation: PostgreSQL, MongoDB, or in-memory for tests

  2. Queue-based async processing:
     // HTTP request: validate, enqueue, return 202 Accepted
     // Worker process: dequeue, process, update status
     // Client polls or uses webhooks for result

  3. Circuit breaker (resilience):
     // When external service fails, circuit opens
     // Fail fast instead of timing out (protect the event loop)

  4. Health checks for orchestrators:
     app.get('/health', (req, res) => {
       res.json({ status: 'ok', version, uptime: process.uptime() });
     });
     app.get('/ready', async (req, res) => {
       // Check dependencies:
       const dbOk = await db.query('SELECT 1').then(() => true)
         .catch(() => false);
       const redisOk = await redis.ping().then(() => true)
         .catch(() => false);
       if (!dbOk || !redisOk) return res.status(503).json({ dbOk, redisOk });
       res.json({ status: 'ready' });
     });
```

> **Code walkthrough:** This Node.js Service Architecture at Scale example demonstrates a key concept in practice using async/await. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Production) - Queue-based architecture with BullMQ:**

```javascript
// api-server.js - HTTP layer (fast, stateless):
import { Queue } from 'bullmq';
import { redis } from './infrastructure/redis.js';

const emailQueue = new Queue('emails', { connection: redis });

// Endpoint: accepts request and enqueues work (returns fast):
app.post('/api/reports/generate',
  authenticate,
  asyncRoute(async (req, res) => {
    const job = await emailQueue.add('generate-report', {
      userId: req.user.id,
      reportType: req.body.reportType,
      filters: req.body.filters
    }, {
      attempts: 3,           // retry up to 3 times
      backoff: { type: 'exponential', delay: 2000 }
    });
    // Return immediately with job ID:
    res.status(202).json({
      jobId: job.id,
      statusUrl: `/api/reports/${job.id}/status`
    });
  })
);

// worker.js - separate process for heavy work:
import { Worker } from 'bullmq';

const worker = new Worker('emails', async (job) => {
  const { userId, reportType, filters } = job.data;
  // Long-running operation (doesn't block API server):
  const report = await generateReport(reportType, filters);
  await notifyUser(userId, report);
  return { reportUrl: report.url };
}, { connection: redis, concurrency: 5 });

worker.on('failed', (job, err) => {
  logger.error({ jobId: job.id, err }, 'Job failed');
});

// Graceful shutdown (critical for Kubernetes):
let server;

async function start() {
  server = app.listen(PORT, () => {
    logger.info(`Server listening on :${PORT}`);
  });
}

async function shutdown() {
  logger.info('Shutting down...');
  // 1. Stop accepting new connections:
  server.close();
  // 2. Close queue connection (complete in-flight jobs):
  await emailQueue.close();
  // 3. Wait for active requests (max 30s):
  await new Promise(resolve => setTimeout(resolve, 100));
  // 4. Close DB connections:
  await db.end();
  process.exit(0);
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
```

> **Code walkthrough:** The queue-based pattern decouples requestice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> acceptance from work execution. The HTTP endpoint validates input,
> enqueues the job, and returns `202 Accepted` with a job ID. The worker
> process (separate Node.js process) consumes jobs at its own pace.
> `attempts: 3` with exponential backoff handles transient failures.
> Graceful shutdown is critical for Kubernetes: `SIGTERM` fires before
> pod termination. `server.close()` stops accepting new connections;
> in-flight requests complete normally. `emailQueue.close()` lets
> the worker finish current jobs. Without graceful shutdown, Kubernetes
> will kill the process after the termination grace period (30s default),
> potentially cutting off active requests.

---

### 🏛️ System Design

**Design: Node.js microservice with complete production readiness**

```
Production-ready service checklist:

  Infrastructure:
    [ ] Dockerfile with non-root user, multi-stage build
    [ ] Kubernetes Deployment with resource limits
    [ ] readinessProbe /ready - starts traffic only when ready
    [ ] livenessProbe /health - restarts if unhealthy
    [ ] terminationGracePeriodSeconds: 30
    [ ] Horizontal Pod Autoscaler (CPU/memory)
    [ ] PodDisruptionBudget (maintain capacity during deploys)

  Observability:
    [ ] Structured logging with correlation IDs (pino)
    [ ] Prometheus metrics endpoint /metrics
    [ ] Distributed tracing (OpenTelemetry)
    [ ] Error tracking (Sentry)
    [ ] Custom business metrics (order count, user signups)

  Resilience:
    [ ] Circuit breaker for external HTTP calls
    [ ] Retry with backoff for transient failures
    [ ] Timeout on all external calls (axios timeout)
    [ ] Connection pool limits (pg pool max)
    [ ] Rate limiting on public APIs

  Security:
    [ ] helmet() - security headers
    [ ] express-rate-limit
    [ ] Input validation (zod) on all routes
    [ ] Secrets from env vars (never hardcoded)
    [ ] npm audit in CI pipeline
    [ ] Non-root Docker user
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### ⚖️ Comparison Table

| Pattern | When to use | When to avoid |
|---|---|---|
| Monolith | Small team, early stage | When teams step on each other |
| Microservices | Team independence, diff scaling | Small teams, adds network overhead |
| BullMQ queue | Long-running async tasks | Simple sync operations |
| Worker threads | In-process CPU work | Cross-service parallelism |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I structure Node.js apps in layers: routes, services (business logic),
> and data access. For long-running tasks I use a queue (BullMQ) so
> the HTTP server stays fast. For production I add health endpoints,
> graceful shutdown, and structured logging.

**Senior / Staff:**

> Architecture decisions at scale: resist microservices until you have
> a clear team boundary reason. A monolith with clean internal module
> boundaries is easier to operate than 20 microservices. When you do
> split: extract services along bounded contexts (Domain-Driven Design),
> not technical layers. The event loop's I/O efficiency makes Node.js
> excellent as an API gateway or BFF (backend for frontend). For CPU
> work: worker threads for in-process, dedicated services (Python, Go)
> for ML inference or video processing.

---

### ⚠️ Common Misconceptions

**Misconception: Microservices are always more scalable.**

Microservices add network latency, distributed transaction complexity,
and operational overhead (service discovery, distributed tracing,
multiple deployments). A well-structured monolith can scale to millions
of requests. Netflix, Amazon, and Uber started as monoliths and split
only when team coordination became the bottleneck, not performance.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Service goes down during Kubernetes deployment.**

Cause: Readiness probe not implemented, or too aggressive. New pods
receive traffic before they're ready.

Fix:
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 10  # wait for startup
  periodSeconds: 5
  failureThreshold: 3

# /ready must return 200 ONLY when DB and Redis are connected
# Return 503 during startup or when dependencies are down
```

> **Code walkthrough:** This Return 503 during startup or when dependencies are down example demonstrates YAML configuration pattern. **KEY MECHANISM:** YAML parsers are whitespace-sensitive; indentation errors cause silent value misinterpretation. **WHY IT MATTERS:** unquoted strings starting with special chars (*, &, ?, |) trigger YAML parser errors. **TAKEAWAY: quote strings containing YAML special chars; validate YAML before deploying to production.**

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| Monolith vs microservices - when to split? | Decision | ★★★ | 4 min |
| How do you handle long-running tasks in Node.js? | Design | ★★★ | 4 min |
| What is graceful shutdown and why is it needed? | Mechanism | ★★★ | 3 min |
| How do you make a Node.js service Kubernetes-ready? | Production | ★★★ | 4 min |
| Circuit breaker pattern - what and when? | Pattern | ★★★ | 3 min |
| How do you structure a large Node.js codebase? | Design | ★★★ | 4 min |
| What is a BFF (Backend for Frontend)? | Definition | ★★★ | 2 min |
| How do you handle partial failures in microservices? | Failure | ★★★ | 4 min |
| What metrics would you alert on for a Node.js service? | Production | ★★★ | 3 min |
| How do you implement request correlation across services? | Design | ★★★ | 3 min |
| Describe your ideal Node.js service template. | BEHAVIORAL | ★★★ | 5 min |
| How would you migrate a monolith to microservices? | Architecture | ★★★ | 5 min |

**Q: How do you handle a cascading failure when an upstream dependency goes down?**

A:

**Without protection (cascading failure):**
- Service A calls Service B
- Service B is slow (500ms timeout)
- Service A threads up waiting for B
- Service A event loop fills with pending B callbacks
- Service A becomes slow, affecting its callers
- Entire chain fails

**Circuit breaker pattern (opossum library):**
```javascript
import CircuitBreaker from 'opossum';

const breaker = new CircuitBreaker(fetchFromServiceB, {
  timeout: 3000,          // fail if >3s
  errorThresholdPercentage: 50, // open at 50% error rate
  resetTimeout: 30000     // try again after 30s
});

breaker.fallback(() => ({ data: [], fromCache: true }));
breaker.on('open', () => logger.warn('Circuit open: ServiceB'));
breaker.on('close', () => logger.info('Circuit closed: ServiceB'));

const result = await breaker.fire(requestData);
```

> **Code walkthrough:** This Return 503 during startup or when dependencies are down example demonstrates variable declaration using async/await. **KEY MECHANISM:** const prevents reassignment but not mutation; the reference is locked, the value is not. **WHY IT MATTERS:** const obj = {}; obj.x = 1 works - const does not freeze the object. **TAKEAWAY: use Object.freeze() to prevent mutation; const only guards the binding.**

*What separates good from great:* The fallback strategy. An open circuit
should return a cached response or a degraded response - not fail the
entire request. Design every external call with a fallback that provides
partial value.

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



