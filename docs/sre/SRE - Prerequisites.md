---
layout: default
title: "SRE - Prerequisites"
parent: "SRE"
grand_parent: "SK Interview"
nav_order: 1
permalink: /sre/prerequisites/
render_with_liquid: false
---

## Keywords in This File

{: .no_toc }

| #   | Keyword | Weight |
| --- | ------- | ------ |
| 1   | [Distributed Systems Failure Modes](#distributed-systems-failure-modes) | high |
| 2   | [Linux Operations and Systems Monitoring](#linux-operations-and-systems-monitoring) | high |
| 3   | [CI/CD and Deployment Pipeline Basics](#cicd-and-deployment-pipeline-basics) | medium |

---

# Distributed Systems Failure Modes

🎯 Interview Weight: high - asked in every SRE and backend
systems interview; your failure taxonomy directly signals
whether you think about reliability from first principles.

---

### 🎯 Model Answer

**30 seconds:**
> Distributed systems fail in ways single-process systems cannot:
> partial failures where some nodes succeed while others fail
> simultaneously; network partitions where nodes lose connectivity
> but keep running; and timing failures where a node replies too
> slowly for the caller's deadline. The critical insight is that
> silence - a timeout - is indistinguishable from slowness or
> death, forcing every caller to decide under uncertainty.

**3 minutes (Senior):**
> The fundamental difference between distributed and single-process
> failure is that partial failure is the norm, not the exception.
> A single-process application either runs or crashes. A distributed
> system can have 3 out of 10 nodes healthy, 2 slow, 4 crashed,
> and 1 returning wrong results - all simultaneously. I have seen
> this exact scenario cause more production incidents than anything
> else I have worked on.
>
> The failure modes I care about most in practice are: crash
> failures where a node stops completely; omission failures where
> a node receives a message but does not reply - hard to distinguish
> from network loss; timing failures where the node replies but
> after the caller's timeout; and Byzantine failures where the node
> replies with incorrect data - the hardest to detect.
>
> Network partitions deserve special attention. During a partition,
> two parts of the system can both believe they are primary, both
> accept writes, and create a split-brain state. The recovery from
> split-brain is painful - it requires reconciling diverged state.
> I always design systems to choose consistency over availability
> during a partition unless the business explicitly accepts stale reads.
>
> Cascade failures are the most dangerous operational failure mode.
> A slow dependency causes upstream callers to wait, exhausting their
> thread pools, making them unresponsive to their callers, repeating
> up the call chain. Circuit breakers, bulkheads, and timeouts are
> the defenses.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff adds: "Designing against failure modes means
choosing your failure semantics explicitly. Is the system fail-fast
(return error immediately) or fail-safe (return stale data)?
Is it optimized for availability or consistency during partitions?
These choices are architectural and must be reflected in SLO
definitions."

*Adapting down:* Junior: "Distributed systems can fail in unique
ways - a node can crash, messages can get lost, or a node can
respond slowly or incorrectly. These failures require explicit
detection and recovery logic that single-process programs do not need."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about distributed systems failure
modes - let me walk through the main categories and why each
matters for reliability."

**(2) First principles:** "From first principles, a distributed
system has nodes communicating over a network. Both nodes and the
network can fail independently. When a node does not respond, it
could have crashed, be slow, or the network could be broken -
callers cannot distinguish these without additional mechanisms."

**(3) Bridge:** "Think of a distributed system like a team in
different buildings connected by walkie-talkies. A single team
in one room either talks or does not. A distributed team faces
partial outages: some members are unreachable, messages are delayed,
and you cannot tell if silence means they are busy or the radio
is broken."

---

### 📘 Concept Explanation

**What it is:**
Distributed systems failure modes are the distinct categories of
ways that nodes, networks, and data can fail in a multi-process
system running across a network. They require explicit detection
and recovery mechanisms that single-process systems do not need.

**The problem it solves:**
Before this taxonomy, developers treated all failures as binary:
working or crashed. This led to systems without timeouts (blocking
forever on slow nodes), without partial failure handling (failing
entire requests because one dependency was slow), and without
split-brain protection. The taxonomy creates shared vocabulary
for designing defenses.

**How it works:**

```
FAILURE MODE TAXONOMY
=====================

CRASH FAILURE
  Node stops completely. No more messages.
  Detection: heartbeat timeout
  Defense: failover, replication

OMISSION FAILURE
  Node receives message, sends no reply.
  Indistinguishable from network loss.
  Detection: request-level timeout
  Defense: retry with idempotency key

TIMING FAILURE
  Node replies after caller's deadline.
  Caller may have retried - causing duplicates.
  Detection: latency SLI breach
  Defense: deadline propagation, idempotency

BYZANTINE FAILURE
  Node replies with incorrect data.
  Hardest to detect without verification.
  Detection: checksums, consensus votes
  Defense: quorum reads, hash verification

NETWORK PARTITION
  Subset of nodes loses connectivity.
  Both sides may continue (split-brain).
  Detection: partition detection algorithms
  Defense: leader election, fencing tokens

CASCADE FAILURE
  Slow dependency -> thread pool exhaustion
  Propagates up the call chain.
  Detection: latency AND error rate together
  Defense: circuit breaker, bulkhead, timeout
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**
Timeouts are mandatory, not optional. Without a timeout, every
omission failure becomes an infinite hang. But a timeout introduces
a new problem: the operation may still be executing after the caller
gives up, causing duplicate effects on retry. This is why idempotency
is the required companion to timeouts in distributed systems.

**When to use it:**
Apply this taxonomy when designing any multi-service system,
reviewing SLOs, setting timeout and retry policies, or diagnosing
a production incident. Every SRE must classify an observed failure
into this taxonomy within the first five minutes of an incident.

**When NOT to use it:**
Byzantine failure defenses (consensus protocols, checksums per
operation) add overhead justified only for high-stakes or adversarial
environments. Most business systems only need crash and omission
defenses. Single-process applications do not need most of this.

**Alternatives:**
- Formal methods (TLA+) - model failure modes mathematically
- Chaos engineering - empirically discover failure modes via injection
- Redundancy-only approaches - add replicas but do not model failures

**First-principles derivation:**
A distributed system is nodes communicating over a network.
Networks drop packets (omission), delay packets (timing), and
partition (connectivity split). Nodes crash or compute incorrectly.
Because these failures are independent, the combined system exhibits
failure combinations impossible in a single process. The taxonomy
follows directly from the combination of node and network failure modes.

---

### 💻 Code Example

*(Omit: Distributed systems failure modes are a conceptual taxonomy.
Code illustrations belong in specific defense mechanisms - circuit
breakers, retry policies, bulkheads - covered at L3+. This keyword
establishes the vocabulary, not the implementation.)*

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Distributed systems fail in ways single-process apps cannot.
> Crash failures happen when a node stops. Omission failures happen
> when a node receives a request but never replies - maybe it is
> overwhelmed or the network dropped the reply. Timing failures
> happen when a node replies too slowly. And cascade failures happen
> when one slow service causes backpressure that takes down everything
> upstream. The practical rule: always set timeouts and handle errors
> explicitly - never assume a call will succeed.

*Push deeper:* Explain the split-brain scenario - what happens
when two database nodes both believe they are primary during a
network partition. This demonstrates understanding of why
distributed consensus is non-trivial.

---

**Senior / Staff (5+ years):**
> The failure mode I care most about in production is cascade
> failure - a single slow dependency can take down an entire service
> graph. I have seen this three times in production. Each time, the
> root cause was a missing timeout or missing circuit breaker on a
> downstream call. Once a thread pool saturates, health checks start
> failing too, triggering restarts, causing traffic spikes, saturating
> the pool again within seconds.
>
> For SLO design, failure mode taxonomy matters because different
> failures breach SLOs in different ways. Crash failures cause
> error rate spikes - immediate SLO breach. Timing failures cause
> latency SLO breaches before error rate rises. Recognizing which
> mode is active in the first five minutes directs the response
> to the right diagnostic path.

*Push deeper:* Staff angle: "Byzantine failure defense is only
justified when the cost of incorrect data exceeds the overhead
of verification. A financial ledger justifies consensus-based
writes. A product catalog does not. The SLO drives the failure
mode defense level."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| A timeout means the operation failed | A timeout means the caller gave up; the operation may still be running, which is why idempotency is mandatory with retries |
| Network partitions are rare edge cases | Partitions happen regularly in cloud environments during deployments, maintenance, and network reconfigurations |
| Retries fix omission failures | Retries without idempotency keys cause duplicate processing; retries only fix omission failures when the operation is idempotent |
| Byzantine failures only matter for blockchains | Any system where a bug or hardware fault causes a node to return incorrect data experiences Byzantine failure |
| Cascade failures require large distributed systems | Two services can cascade: if B hangs and A has no timeout or circuit breaker, A will exhaust its threads and fail too |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Cascade failure from missing timeout**

*Symptom:* Error rate and latency spike together across multiple
services simultaneously. Health checks for multiple services
start failing. Thread pool exhaustion in logs:
`RejectedExecutionException`.

*Root cause:* Service A calls Service B with no timeout. Service B
becomes slow. Service A threads block waiting. Thread pool fills.
Service A stops responding. Upstream services cascade.

*Diagnostic:*
```bash
# Check thread pool saturation via actuator
curl http://service-a:8080/actuator/metrics/ \
  executor.pool.size
# Check for blocked threads
jstack <pid> | grep -A5 "BLOCKED\|WAITING" | \
  head -40
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Add explicit timeouts on all outbound calls. Add
circuit breakers. Use bulkhead pattern to isolate thread
pools per downstream dependency.

*Prevention:* Chaos engineering - inject latency into
dependencies in staging to verify cascades do not occur.

**Failure 2: Split-brain during network partition**

*Symptom:* Two instances of a stateful service both accept
writes. After partition heals, data is inconsistent. Clients
see different results depending on which node they hit.

*Root cause:* No leader election or fencing tokens. Both nodes
believed they were primary during the partition.

*Diagnostic:*
```bash
# Check for diverged state (etcd cluster example)
etcdctl endpoint status --cluster -w table
# Look for different RAFT TERM or RAFT INDEX values
# Divergence confirms split-brain occurred
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Implement fencing tokens. Any write to storage must
include a monotonically increasing token; old tokens are
rejected. Use a consensus algorithm (Raft, Paxos) for
leader election.

*Prevention:* Design for CP (consistency over availability)
when split-brain is unacceptable. Test with network partition
injection (Chaos Mesh, tc netem).

**Failure 3: Retry storm amplification**

*Symptom:* A brief upstream degradation causes traffic to
multiply 3-10x. The degraded service cannot recover because
the retry storm prevents it.

*Root cause:* All callers retry simultaneously with no
backoff or jitter. A 1-second spike generates 3-5x normal
load as all callers retry in sync.

*Diagnostic:*
```bash
# Check for exponential load spike in metrics
kubectl top pods -n <namespace>
# Check for synchronized retry in logs
grep "retry attempt" service.log | \
  awk '{print $1}' | uniq -c | head -20
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Exponential backoff with full jitter on all retries.
Circuit breakers to stop retrying when error rate exceeds
the configured threshold.

*Prevention:* Never use fixed-delay retries. Always use
exponential backoff with full jitter (random delay between
0 and max_delay, not a fixed exponential value).

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 20 minutes |
| Core themes | Failure taxonomy, cascade failures, timeouts, idempotency |
| Seniority signal | Junior: names modes; Senior: explains cascade mechanics |
| Common trap | Thinking timeouts alone prevent cascades without circuit breakers |
| Staff differentiator | Connecting failure modes to SLO design and CAP theorem choices |

---

**Q1 [JUNIOR]: What are the main categories of failure in
distributed systems?**

*Why they ask:* Baseline taxonomy check. A candidate who cannot
name failure modes cannot design defenses for them.

*Likely follow-up:* "Which failure mode is hardest to detect?"

The main categories are crash failures where a node stops and
sends no more messages; omission failures where a node is running
but does not reply to a specific message, which the caller cannot
distinguish from a network drop; timing failures where a node
replies but after the caller's deadline has passed; and Byzantine
failures where a node sends incorrect or inconsistent data.

In practice, the most common in cloud environments are crash
failures (pods restarting after OOM or liveness failures) and
timing failures (slow GC pauses, slow database queries). Byzantine
failures in business systems are usually caused by software bugs
returning incorrect data, not adversarial nodes.

The hardest to detect is Byzantine failure because the node appears
healthy and responds, but returns wrong results. Crash and omission
failures are detectable by timeout. Byzantine failures require
checksum verification, consensus voting, or correctness tests of
the data itself.

*What separates good from great:* Most candidates name crash and
network partition but miss timing failures. Great candidates
distinguish omission from crash (same observable symptom for
the caller, different root cause) and note that Byzantine failure
requires fundamentally different defenses.

---

**Q2 [JUNIOR]: Why does cascade failure happen and what prevents it?**

*Why they ask:* Cascade failure is the most common SRE emergency.
Understanding the mechanism is a basic reliability requirement.

*Likely follow-up:* "What is a circuit breaker and how does it
differ from a timeout?"

Cascade failure happens because thread pools are finite. Service A
has a pool of 50 threads for outbound calls to Service B. When B
becomes slow, A's threads block waiting for responses. Once all 50
threads are blocked, A cannot process any more requests - including
requests to other services and health checks. A now appears down
to its upstream callers. They experience the same thread pool
exhaustion. The failure propagates up the call chain in seconds.

The three defenses are timeouts, circuit breakers, and bulkheads.
Timeouts prevent threads from blocking indefinitely. Circuit breakers
detect when a downstream service is unhealthy and stop sending
requests, failing fast instead of blocking. Bulkheads isolate thread
pools per dependency so a slow Service B cannot consume all of
Service A's threads and prevent calls to Service C.

The key mistake is adding a timeout without a circuit breaker.
A timeout without a circuit breaker causes retries, which amplify
load on the already-struggling service and make recovery impossible.

*What separates good from great:* Most candidates know timeouts
prevent cascades. Great candidates explain the thread pool
exhaustion mechanism precisely and explain why timeouts without
circuit breakers can worsen cascades by generating retry storms.

---

**Q3 [MID]: What is the difference between fail-fast and fail-safe
design, and when do you choose each?**

*Why they ask:* Trade-off question testing whether the candidate
understands the business implications of failure semantics.

*Likely follow-up:* "What does fail-safe look like for a payment
service versus a product catalog?"

Fail-fast design returns an error immediately when it detects a
failure condition. Fail-safe design continues operating, typically
returning stale or degraded data instead of an error. The choice
is a business decision disguised as a technical one.

A payment processing service must fail-fast. Returning stale data
(a cached payment result) is unacceptable because the customer and
the business both need accurate, current information. An error is
better than incorrect data.

A product catalog can fail-safe. If the product data service is
unavailable, serving cached data from five minutes ago is better
than showing a blank page. A slight inaccuracy in a product price
is acceptable for short durations.

The SLO drives the choice. If the SLO is "correct data every time,"
fail-fast is required. If the SLO is "high availability with eventual
consistency acceptable," fail-safe with degradation is correct.

*What separates good from great:* Most candidates describe fail-fast
as universally better without nuance. Great candidates connect
the choice to the business consequence of wrong data versus no data
and frame it as an SLO question.

---

**Q4 [MID]: How do you diagnose a cascade failure in production?**

*Why they ask:* Debugging question - can the candidate run an
incident effectively, not just describe the theory?

*Likely follow-up:* "What does a Grafana dashboard look like during
a cascade failure versus a single-service failure?"

The key diagnostic signal is that error rate and latency spike
simultaneously across multiple services within a short window -
usually under two minutes. This contrasts with a single-service
incident where only one service degrades.

My first steps: check which service's metrics degraded first in the
timeline. That service is either the root cause or the first to
receive a slow upstream dependency call. Then I look at thread pool
metrics for that service - if thread pool utilization is at 100%,
it is a cascade scenario. Then I check what it was calling when
the pool filled.

```
Cascade timeline in Grafana:
t=0:   service-B latency p99: 50ms -> 5000ms
t=15s: service-A thread pool: 40/50 -> 50/50
t=20s: service-A error rate: 0% -> 40%
t=30s: service-A latency p99: 80ms -> 8000ms
t=35s: service-C error rate: 0% -> 60%
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Root cause is always upstream of t=0. I check: what changed in
service-B before t=0? Deployment, config change, database slow
query, downstream dependency slowdown.

*What separates good from great:* Most candidates describe cascade
failure conceptually. Great candidates walk through the actual
metric timeline with specific signals and distinguish cascade (multi-
service simultaneous spike) from single-service incident.

---

**Q5 [SENIOR]: What does idempotency have to do with distributed
failure modes?**

*Why they ask:* Trade-off and mechanism question. Idempotency is
the required companion to retries - missing it is a common bug.

*Likely follow-up:* "How do you implement idempotency for a
payment charge API?"

Idempotency is the required pair to any retry mechanism. The problem:
when a timing failure occurs (caller times out), the operation may
still be executing on the server. If the caller retries without an
idempotency key, the server executes the operation twice. For
charging a credit card, sending an email, or debiting an account,
this creates a serious production bug.

The fix is idempotency keys: the caller generates a unique key per
logical operation and sends it with every attempt. The server stores
the key and the result after the first execution. On retry, the
server detects the duplicate key and returns the cached result
without re-executing.

Implementation: the idempotency key is stored in a fast-access store
(Redis) with a TTL longer than the maximum retry window. The server
must atomically check-and-set the key: check if it exists, if not
then execute and store, if yes then return cached. This atomic
operation requires a distributed lock or a database transaction.

Every mutating API in a distributed system should accept an
idempotency key. This is not optional for any operation with
business side effects.

*What separates good from great:* Most candidates know what
idempotency means. Great candidates explain the connection to
retry-induced duplicate execution as the specific failure mode it
defends against, and describe the atomic check-and-store
implementation requirement.

---

**Q6 [SENIOR]: How do SREs use failure mode taxonomy to design SLOs?**

*Why they ask:* Connects theoretical knowledge to practical SRE
craft. Tests whether the candidate applies the taxonomy to work.

*Likely follow-up:* "What SLI detects cascade failures before
they become SLO breaches?"

Different failure modes manifest as different SLI breaches.
Crash failures cause error rate to spike immediately. Timing
failures cause latency to rise before error rate goes up - clients
wait up to the timeout before receiving an error. Byzantine failures
may not appear in error rate at all - the request succeeds but
returns wrong data.

This means an SLO that only measures error rate misses timing and
Byzantine failures. A complete SLO for a mission-critical service
needs: an error rate SLI (catches crash and omission), a latency
SLI at p99 (catches timing failures early), and a correctness SLI
(catches Byzantine failures - typically a canary query with a known
expected result checked periodically).

For cascade failure detection specifically: I use a composite alert
that fires when both latency AND thread pool utilization rise
simultaneously. Latency rising alone is a slow dependency. Thread
pool filling with rising latency is a cascade forming.

*What separates good from great:* Most candidates know SLIs in
isolation. Great candidates map specific failure modes to specific
SLI types and explain why error-rate-only SLOs are insufficient
for catching all distributed failure modes.

---

**Q7 [STAFF]: What is the relationship between failure modes and
the CAP theorem when designing a distributed service?**

*Why they ask:* Staff-level conceptual integration. Can the
candidate connect failure mode taxonomy to the foundational
distributed systems theorem?

*Likely follow-up:* "When would you intentionally choose a CP
system over an AP system?"

The CAP theorem states that during a network partition, a distributed
system must choose between consistency (all nodes see the same data)
and availability (all nodes continue responding). This is directly
the response strategy to the network partition failure mode.

A CP system stops accepting writes during a partition to avoid
split-brain. This means the partition failure mode manifests as
availability failures - clients get errors during the partition.
A financial ledger is CP: we prefer errors to incorrect balances.

An AP system continues accepting writes on both sides of a partition.
This means the partition failure mode manifests as Byzantine-like
behavior after healing - different nodes have different data. A
product catalog is AP: a stale product description is acceptable
during a partition.

At the staff level, this decision is documented in the service's
architecture decision record and reflected in the SLO: CP systems
have availability SLOs that explicitly allow degradation during
partitions; AP systems have consistency SLOs that explicitly allow
stale reads.

*What separates good from great:* Most candidates describe CAP as
an abstract theorem. Great candidates explain how the CP vs AP choice
maps to a specific failure mode response decision and show it
reflected in SLO design with concrete examples.

---

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


# Linux Operations and Systems Monitoring

🎯 Interview Weight: high - operations interview staple;
separates candidates who work in production from those who
only write code; asked in nearly every SRE screen.

---

### 🎯 Model Answer

**30 seconds:**
> Linux operations for SREs means diagnosing system health using
> command-line tools: top and htop for CPU and memory, iostat
> and dstat for disk I/O, ss for network connections, and strace
> and lsof for process-level diagnosis. The skill is not memorizing
> flags - it is knowing which tool answers which question when a
> service is misbehaving at 2 AM with no graphical dashboard.

**3 minutes (Senior):**
> Linux system monitoring as an SRE skill is about building a mental
> model of where resource contention can occur and knowing which tool
> observes each layer. I organize it into four resource domains:
> CPU, memory, disk I/O, and network.
>
> For CPU, I start with top or htop to see which processes are
> consuming CPU. The distinction between user-space CPU (%us) and
> kernel CPU (%sy) matters: high %sy means the kernel is busy -
> usually I/O or context switching. High %us means application code
> is consuming CPU. For sustained CPU analysis I use perf or
> async-profiler for flame graphs.
>
> For memory, I look for OOM kill events in dmesg first. Then I
> check free -m for overall memory health, specifically the
> "available" column (not "free"), and /proc/meminfo for detailed
> breakdown. High swap usage is a warning: the application is paging,
> which creates latency spikes that look like random slowdowns.
>
> For disk I/O, iostat -xz 1 shows device utilization, await (average
> wait time per request), and %util (device saturation). An await
> over 10ms on an SSD means the disk is the bottleneck. For diagnosing
> which process is causing I/O: iotop.
>
> For network, ss -s shows connection state summary instantly. High
> TIME_WAIT counts indicate connection churn. High CLOSE_WAIT indicates
> the application is not closing connections properly - always a bug.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff adds: "The tooling hierarchy for SRE is:
command-line tools for ad-hoc diagnosis in seconds when dashboards
are unavailable; agent-based metrics (Prometheus, DataDog) for
persistent visibility; and distributed tracing (Jaeger, Zipkin)
for request-level causality. An SRE who can only read dashboards
is helpless when dashboards are unavailable during the incident."

*Adapting down:* Junior: "Linux operations means using tools like
top, free, and df to see if the system is running out of CPU,
memory, or disk space. These are the first things to check when
a service is slow or unresponsive."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Linux operations and systems
monitoring - let me walk through the key tools by resource category."

**(2) First principles:** "From first principles, a server has four
resource types that can be exhausted: CPU, memory, disk I/O, and
network connections. Each has dedicated tools for observation and
diagnosis."

**(3) Bridge:** "Think of Linux monitoring tools like a doctor's
diagnostic instruments. top is the blood pressure cuff - quick
overall picture. iostat is the ECG - shows I/O activity patterns.
strace is the biopsy - goes inside a specific process to see
exactly what system calls it is making."

---

### 📘 Concept Explanation

**What it is:**
Linux operations and systems monitoring is the practice of observing
and diagnosing system resource consumption using command-line tools
and /proc filesystem interfaces, without relying on external
dashboards. It is the baseline operational skill for any SRE working
with Linux-based infrastructure.

**The problem it solves:**
Production incidents happen at unpredictable times, often when
dashboards are slow, unavailable, or missing the granularity needed.
A slow JVM heap, a runaway process consuming disk I/O, or an
application leaving connections in CLOSE_WAIT state requires direct
system observation. Command-line proficiency is the difference
between diagnosing in 5 minutes and 45 minutes while a service is
down.

**How it works:**

```
LINUX RESOURCE MONITORING MAP
==============================

CPU
  top / htop        real-time process CPU/mem
  uptime            load average (1/5/15 min)
  mpstat -P ALL 1   per-CPU utilization
  perf top          kernel-level CPU profiling
  KEY: %us, %sy, %wa, load vs CPU count

MEMORY
  free -m           total/used/available
  vmstat 1          virtual memory per second
  /proc/meminfo     full breakdown
  dmesg | grep OOM  OOM kill events
  KEY: available (not free), swap used, si/so

DISK I/O
  iostat -xz 1      device util, await, %util
  iotop             per-process I/O usage
  df -h             disk space
  KEY: await (ms/op), %util, r/s, w/s

NETWORK
  ss -s             socket state summary
  ss -tunp          all TCP/UDP with PIDs
  netstat -s        protocol statistics
  ip -s link show   interface statistics
  KEY: TIME_WAIT, CLOSE_WAIT, ESTABLISHED

PROCESS
  lsof -p <pid>     open files/connections
  strace -p <pid>   system call trace
  /proc/<pid>/fd/   open file descriptors
  KEY: fd count vs ulimit
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**
The /proc filesystem is the kernel's live state exposed as files.
Every monitoring tool reads from /proc. When tools are unavailable
(minimal containers, restricted environments), reading /proc directly
(cat /proc/meminfo, cat /proc/net/tcp) always works. This is the
ultimate fallback for every monitoring scenario.

**When to use it:**
During active production incidents when dashboards are slow or missing
data. During capacity planning to understand actual resource utilization
patterns. During performance debugging when a service is slow but the
reason is not obvious from application metrics.

**When NOT to use it:**
Manual command-line monitoring does not replace persistent metrics
(Prometheus, DataDog). Point-in-time snapshots miss intermittent
spikes. Command-line tools are for incident diagnosis; persistent
agent-based monitoring is for ongoing visibility.

**Alternatives:**
- Prometheus + Grafana - persistent metric collection and visualization
- DataDog / New Relic - SaaS observability with agent
- BPF/eBPF tools (bpftrace, bcc) - kernel-level tracing without overhead

**First-principles derivation:**
A Linux system is a kernel managing four resources: CPU time, memory
pages, I/O operations, and network packets. The kernel tracks the
state of every resource in data structures exposed via /proc.
Monitoring tools are interfaces to these kernel data structures.
Understanding which tool reads which /proc path makes it possible
to derive diagnostics without memorizing every flag.

---

### 💻 Code Example

**Example 1: Structured incident triage (wrong vs right)**

```bash
# BAD: checking only one metric in isolation
top
# Sees high CPU but does not know which process
# or why. No I/O visibility, no history.

# GOOD: structured four-resource triage
echo "=== LOAD ===" && uptime
echo "=== TOP PROCESSES ===" && \
  ps aux --sort=-%cpu | head -10
echo "=== MEMORY ===" && free -m
echo "=== DISK I/O ===" && iostat -xz 1 3
echo "=== NETWORK STATES ===" && ss -s
echo "=== OOM EVENTS ===" && \
  dmesg | grep -i "oom\|killed" | tail -5
```

> **Code walkthrough:** This script collects all four resource
> dimensions in one pass. `uptime` provides load average for trend
> context. `ps aux --sort=-%cpu` identifies the specific process.
> `iostat -xz 1 3` takes 3 samples over 3 seconds to catch
> intermittent I/O spikes. `dmesg` checks for recent OOM kills
> that may explain a sudden restart. Running all five commands in
> the first two minutes of an incident covers the most common root
> causes before escalating to application-level profiling.

**Example 2: Connection state diagnosis (wrong vs right)**

```bash
# BAD: only checking if service responds
curl http://service:8080/health  # returns 200
# Service appears healthy but has connection
# exhaustion building up silently.

# GOOD: check connection state distribution
ss -s
# Output:
# Total: 1200
# TCP: 1198 (estab 800, closed 12,
#       orphaned 0, timewait 350)

# High TIME_WAIT: connection churn
#   Fix: enable connection pooling, or:
#   sysctl -w net.ipv4.tcp_tw_reuse=1

# High CLOSE_WAIT: application bug
#   App is not closing connections.
#   Fix: find and fix the connection leak.
```

> **Code walkthrough:** `ss -s` gives a connection state summary
> in one command. TIME_WAIT accumulation is normal but thousands
> indicate connection churn that should be addressed with
> connection pooling. CLOSE_WAIT is always a bug: it means the
> remote side closed the connection but the application has not
> acknowledged the close, typically due to a leaked connection
> handle that never gets garbage collected.

**Example 3: Memory pressure diagnosis**

```bash
# Check available memory (not just free)
free -m
# total  used  free  shared  cache  available
# 16000 14800   200     100   3000       1200
# available = 1200 MB (reclaimable cache included)
# This is healthy despite low "free"

# Check swap activity for paging pressure
vmstat 1 5
# r  b   swpd  free  si  so  bi  bo
# 2  0  51200  1200  45  12 200  50
# si > 0 = pages read FROM swap = CRITICAL
# Process is experiencing disk-latency page faults

# Find which process is using most memory
ps aux --sort=-%mem | head -5
```

> **Code walkthrough:** `free -m` shows "available" which includes
> reclaimable page cache and is the correct health indicator, not
> "free". A system with 200 MB free but 3 GB in cache is healthy.
> Swap activity (si/so in vmstat) above zero means the system is
> paging to disk, causing latency spikes of 10-100ms per page
> fault. This is the most common Linux memory problem that is
> invisible when only looking at the "free" column of free -m.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> For Linux monitoring I use top to see CPU and memory at a glance,
> free -m for memory health, df -h for disk space, and ss -s for
> network connection counts. When a service is slow, I start with
> top to find which process is consuming CPU, then free -m to rule
> out memory pressure, then iostat to check if disk I/O is the
> bottleneck. The key is starting with overview tools and narrowing
> to the specific resource.

*Push deeper:* Explain the difference between `free` (unused memory)
and `available` memory (free plus reclaimable cache). Most candidates
confuse these. The available column is the actionable number.

---

**Senior / Staff (5+ years):**
> My Linux triage order during an incident: load average first
> (uptime), then CPU breakdown (top - specifically %wa and %sy,
> not just %us), then memory available (free -m available column
> and vmstat si/so for swap activity), then disk await (iostat -xz
> - await over 10ms on SSD is already a problem), then network
> state (ss -s looking specifically for CLOSE_WAIT which is always
> a bug, and TIME_WAIT for connection churn).
>
> The /proc filesystem is my escape hatch when tools are not
> installed in minimal containers. /proc/meminfo, /proc/net/tcp,
> /proc/stat are always available. I have diagnosed JVM heap issues
> in production containers with no installed tools by reading
> /proc/pid/status directly.

*Push deeper:* Staff angle: "eBPF tools (bpftrace, bcc) are the
next evolution. They allow kernel-level tracing with minimal overhead,
can answer questions like 'which DNS queries take over 100ms' or
'which system calls is this process making right now' without
strace's 50-70% throughput impact."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| `free` in `free -m` shows available memory | `available` is the correct column; `free` excludes reclaimable cache and gives a misleadingly low number |
| High CPU wait (%wa) means the CPU is overloaded | %wa means the CPU is idle waiting for I/O; the bottleneck is the disk subsystem, not the CPU |
| A service is healthy if its health endpoint returns 200 | Health endpoints often do not check thread pool saturation, connection exhaustion, or memory paging pressure |
| strace is safe to use on hot production paths | strace uses ptrace and can reduce process throughput by 50-70%; use on canary instances or with extreme caution |
| TIME_WAIT connections are a problem to eliminate | TIME_WAIT is the kernel's protection against delayed packet corruption; it is normal; only excessive counts warrant action |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: OOM kill causing unexpected service restart**

*Symptom:* Service pod restarts unexpectedly with no application
error in logs. Kubernetes shows OOMKilled as exit reason. No
increase in request rate that would explain increased memory.

*Root cause:* Application memory growth exceeded container memory
limit. Linux kernel OOM killer selected the container process
and sent SIGKILL (exit code 137).

*Diagnostic:*
```bash
# Kubernetes
kubectl describe pod <pod-name> | grep -A5 "Last State"
# Shows: Reason: OOMKilled, Exit Code: 137

# Bare metal
dmesg | grep -i "oom\|out of memory\|killed"

# Check memory trend before kill
kubectl top pods --containers | grep <service>
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Increase memory limit if usage is legitimate, or find
and fix the memory leak. For JVM: add
`-XX:+HeapDumpOnOutOfMemoryError` to capture heap dump before
the OOM kill.

*Prevention:* Set both memory request and limit on all containers.
Monitor memory utilization trend, not just current snapshot.

**Failure 2: Disk I/O saturation causing random latency spikes**

*Symptom:* Service latency p99 spikes randomly by 5-50x with
no corresponding CPU or memory change. Log writes correlate
with the spikes.

*Root cause:* Disk I/O device is saturated. Requests queue
behind I/O operations. Await time grows proportionally.

*Diagnostic:*
```bash
iostat -xz 1
# Device: r/s  w/s  await  %util
#   sda   5   200   45.0   98.0
# await > 10ms on SSD = saturated
# %util > 80% = bottleneck confirmed

# Find which process owns the I/O
iotop -o -d 1
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Move application logs to a separate volume. Switch to
async logging. Use faster storage (NVMe). Reduce I/O by
batching writes or using in-memory buffers.

*Prevention:* Separate OS disk from application log disk.
Alert when iostat %util exceeds 70%.

**Failure 3: File descriptor exhaustion**

*Symptom:* "Too many open files" errors in application logs.
Service stops accepting new connections. Existing connections
continue working. Gradual accumulation over hours.

*Root cause:* Application opens connections or file handles
without closing them. File descriptor count grows until it
hits the ulimit.

*Diagnostic:*
```bash
# Count open FDs for the process
ls /proc/<pid>/fd | wc -l

# System limit
cat /proc/<pid>/limits | grep "open files"

# Find CLOSE_WAIT connections (connection leak)
ss -tunp state close-wait | grep <pid>
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Find the code path opening connections without closing.
Use try-with-resources (Java) or with statement (Python). Add
connection pool test-on-borrow to detect stale connections.

*Prevention:* Alert on fd count growth trend. Code review
checklist: all connection opens have corresponding closes.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 20 minutes |
| Core themes | Resource triage order, /proc filesystem, connection states |
| Seniority signal | Junior: knows tools; Senior: interprets metrics correctly |
| Common trap | Confusing `free` with `available` in memory output |
| Staff differentiator | eBPF tools and /proc as universal fallback |

---

**Q1 [JUNIOR]: Walk me through diagnosing a slow service on
a Linux server.**

*Why they ask:* Baseline operational skill. Reveals whether
the candidate has a systematic approach or randomly tries tools.

*Likely follow-up:* "What if CPU, memory, and disk all look normal?"

My triage order is resource-focused, not tool-focused. I start
broad and narrow down. First: `uptime` to check load average -
if load is greater than CPU count, something is saturating CPU.
Then: `top` to identify which process is consuming most CPU and
memory. Third: `free -m`, looking at the available column (not
free). Fourth: `iostat -xz 1` to check disk await and %util.
Fifth: `ss -s` for network connection states.

If all four resource metrics look normal, the slowness is likely
in application logic - GC pauses, lock contention, or external
dependency latency. At that point I move to application-level
profiling and distributed tracing.

The mistake most candidates make is checking one metric and stopping.
A slow service can have normal CPU but saturated disk I/O. Or normal
disk but exhausted file descriptors. The triage must cover all four
resource types before concluding.

*What separates good from great:* Most candidates describe using
top and moving on. Great candidates describe a specific order
covering all four resource types and explain what conclusion each
metric points to.

---

**Q2 [MID]: What does high %wa in top mean, and what do you
check next?**

*Why they ask:* Tests understanding of CPU states - a common
misconception source that separates candidates with real experience.

*Likely follow-up:* "How do you confirm disk I/O is the bottleneck
rather than CPU?"

%wa is CPU wait time - the percentage of time the CPU is idle
specifically because it is waiting for I/O operations to complete.
The CPU is NOT busy; it is idle but blocked. The bottleneck is the
disk or network I/O subsystem, not the CPU.

This matters practically because adding CPU or scaling out compute
does not fix the problem. The right move is investigating I/O with
`iostat -xz 1`. A disk await over 10ms on an SSD or over 20ms on
an HDD indicates saturation. The fixes are: move to faster storage,
add read caching, reduce I/O frequency (batch writes, async logging).

High %wa combined with high disk %util in iostat confirms disk is
the bottleneck. High %wa with normal disk but slow networked storage
(NFS, EBS) points to network I/O as the bottleneck.

*What separates good from great:* Most candidates say "disk is slow"
without explaining the CPU-is-idle-not-CPU-busy distinction. Great
candidates explain that %wa means CPU is the bystander and
immediately specify iostat as the confirming diagnostic.

---

**Q3 [MID]: What is the difference between TIME_WAIT and
CLOSE_WAIT in TCP connection states?**

*Why they ask:* Tests connection debugging depth. These are
frequently confused and have completely different implications.

*Likely follow-up:* "What would you do if you saw 50,000
TIME_WAIT connections?"

TIME_WAIT and CLOSE_WAIT are both post-close TCP states but they
are on opposite sides and have different implications.

TIME_WAIT is the state the side that initiated the close enters
after the connection closes. It lasts 2*MSL (maximum segment
lifetime), typically 60-120 seconds. It is the kernel's protection
against delayed packets from the closed connection corrupting a new
connection reusing the same port tuple. TIME_WAIT is normal and
expected. Thousands of TIME_WAIT connections indicate high connection
churn - the fix is connection pooling to reuse connections, not
trying to eliminate TIME_WAIT.

CLOSE_WAIT is the state the passive-close side enters when the
remote side closes but the local side has not closed yet. In a
correct implementation, the application detects the EOF and closes
immediately. CLOSE_WAIT persisting for minutes or hours is always
a bug: the application is not reading the EOF or not calling close.

One TIME_WAIT = normal. Thousands = needs connection pooling.
One CLOSE_WAIT persisting = bug, needs code fix.

*What separates good from great:* Most candidates confuse the two
states. Great candidates identify which side is in each state, the
time-bounded vs. indefinite nature of each, and give distinct fixes.

---

**Q4 [SENIOR]: How do you find a memory leak in a Linux process?**

*Why they ask:* Memory leak diagnosis is a hands-on skill that
separates candidates with production experience.

*Likely follow-up:* "What tools would you use for a Java process
specifically?"

The sequence for finding a Linux process memory leak: First, confirm
the leak exists. `ps aux` or `top` sorted by memory should show the
process's RSS (resident set size) growing over time while requests
are stable. If RSS is stable, there is no leak.

Second, confirm heap vs. native memory leak. For JVM: use
`jcmd <pid> VM.native_memory` for native memory breakdown, and
`jcmd <pid> GC.heap_dump /tmp/heap.hprof` for heap analysis.
For non-JVM processes: use `/proc/<pid>/smaps` to examine memory
regions. Growing anonymous memory in smaps indicates a native
memory leak.

Third, in production when tools are restricted: watch VmRSS:
```
watch -n 5 grep VmRSS /proc/<pid>/status
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

If VmRSS grows steadily with stable workload, the leak is confirmed
and I can escalate to heap dump analysis in a staging replica.

*What separates good from great:* Most candidates mention heap dump
tools. Great candidates distinguish heap from native memory leaks,
describe a confirmation step before diving into analysis, and
mention /proc/pid/status as the minimal always-available diagnostic.

---

**Q5 [SENIOR]: When would you use strace in production and what
are the risks?**

*Why they ask:* Production safety awareness question. strace is
powerful but dangerous under load.

*Likely follow-up:* "What is a safer alternative for system call
profiling in production?"

strace is useful when a process is making unexpected system calls
causing latency - for example, `fsync` on every write, or
`getpid` in a hot loop, or blocked `futex` calls from lock
contention. It shows the exact sequence of system calls with timing.

The risk: strace uses ptrace, which stops the traced process to
inspect each system call. On a process handling 10,000 requests
per second, this can reduce throughput by 50-70%, causing SLO
breaches during the diagnostic itself.

Safe use patterns: attach to a canary instance, not a primary
instance under full load. Use `strace -e trace=file,network` to
trace only specific call groups. Use `strace -c` for summary
statistics (syscall counts and time) which is safer than
continuous event-by-event tracing.

The safer production alternative is eBPF-based tools like bpftrace:
```
bpftrace -e 'tracepoint:syscalls:sys_enter_fsync
{ printf("%s\n", comm); }'
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

This identifies fsync callers with minimal overhead because
aggregation happens in kernel space.

*What separates good from great:* Most candidates know what strace
does. Great candidates quantify the overhead risk and describe eBPF
alternatives and safe sampling approaches before attaching to any
production instance.

---

**Q6 [SENIOR]: How do you diagnose file descriptor exhaustion
and what is the temporary fix?**

*Why they ask:* FD exhaustion is a real production failure mode
with specific diagnostic commands and a known temporary mitigation.

*Likely follow-up:* "How do you find which type of resource is
being leaked?"

The symptom is "Too many open files" errors or EMFILE in logs, or
failed connection attempts despite the service appearing healthy.

Diagnosis steps:
```bash
# Count open FDs for the process
ls /proc/<pid>/fd | wc -l
# Compare to limit
cat /proc/<pid>/limits | grep "open files"
# Inspect what type of resource is leaked
ls -la /proc/<pid>/fd | tail -20
# Socket entries = connection leak
# File entries all same path = file handle leak
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Temporary fix: `ulimit -n 65536` in the shell, then restart the
service to apply. For systemd services: add `LimitNOFILE=65536`
to the service unit file and reload. This buys time to find and
fix the underlying bug.

The underlying bug is always either a connection leak (not closing
connections after use) or a file handle leak (not closing file
handles, often in error paths that skip the close call).

*What separates good from great:* Most candidates describe the error
message. Great candidates give the diagnostic sequence, distinguish
what type of resource is leaked from the fd directory contents,
and describe both temporary (ulimit) and permanent (code fix) paths.

---

**Q7 [STAFF]: What is the /proc filesystem and why does it matter
for SRE work in minimal container environments?**

*Why they ask:* Depth question separating candidates who know tools
from those who understand the underlying kernel model.

*Likely follow-up:* "Which /proc paths do you read directly in
your SRE work?"

The /proc filesystem is a virtual filesystem the Linux kernel
exposes to give userspace visibility into live kernel state. Every
file in /proc is not a real disk file - reading it invokes a kernel
function returning current state. This is how all monitoring tools
work: `top` reads /proc/stat, `free` reads /proc/meminfo, `ss`
reads /proc/net/tcp.

For SRE work in modern containerized environments, /proc matters
as the fallback when tool installation is impossible. Minimal
container images (distroless, scratch) have no top, no free, no ss.
But /proc is always present because it is the kernel interface:

```bash
# Memory without free -m
cat /proc/meminfo | grep -E "MemAvailable|SwapFree"

# Connection states without ss
cat /proc/net/tcp | wc -l

# Memory per process without ps
cat /proc/<pid>/status | grep VmRSS

# Load average without uptime
cat /proc/loadavg
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

This also matters for observability architecture: Prometheus node
exporter reads /proc paths and exposes them as metrics. Custom
exporters for application-specific metrics follow the same pattern.

*What separates good from great:* Most candidates use tools without
understanding the kernel model behind them. Great candidates explain
that all tools are /proc readers and can fall back to direct /proc
access in restricted environments - a skill that saves time in
real production incidents.

---

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


# CI/CD and Deployment Pipeline Basics

🎯 Interview Weight: medium - assumed prerequisite knowledge
for SRE roles; inability to describe pipeline stages or
deployment strategies signals lack of operations maturity.

---

### 🎯 Model Answer

**30 seconds:**
> CI/CD is the automation pipeline that takes code from a developer
> commit to running in production safely. CI runs tests and builds
> on every commit. CD automates the path from a passing build to
> staging and production. For SREs, the critical concern is
> deployment safety: deploy without causing incidents, and roll back
> in under five minutes if you do.

**3 minutes (Senior):**
> CI/CD for SREs is primarily a reliability tool, not a speed tool.
> The goal is not faster deployments but safer deployments - catching
> regressions before production and recovering quickly when deployments
> go wrong.
>
> The CI side is relatively straightforward: every commit triggers
> build, unit tests, integration tests, and static analysis. The
> critical SRE concern is flaky tests. A test suite with 5% flakiness
> trains engineers to ignore red builds, which means real failures
> get ignored too. I treat flaky test rate as a reliability metric.
>
> The CD side is where SRE complexity lives. The deployment strategy
> determines the blast radius when a bad build goes to production.
> A big-bang deployment (replace all instances at once) has 100%
> blast radius. A canary deployment (replace 5% of instances first,
> observe, then roll out) limits blast radius while still advancing
> deployments automatically.
>
> The three deployment strategies I use are: blue-green (zero downtime,
> instant rollback, but doubles infrastructure cost during deployment),
> canary (progressive traffic shift with automated SLO-based promotion
> or rollback), and rolling (replace instances one-by-one, requires
> backward compatibility).
>
> The SRE standard I enforce: every deployment must be reversible
> in under five minutes. If rollback takes 30 minutes, the deployment
> strategy is wrong regardless of how well-tested the build is.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff adds: "Progressive delivery (canary, feature
flags, traffic splitting) is the evolution beyond basic CD. The SRE
goal is controlling blast radius of every change. Deployment frequency
and change failure rate are the DORA metrics I track for reliability
- not just deployment speed."

*Adapting down:* Junior: "CI/CD automates the steps to get code
from a commit to production: build it, test it, deploy to staging,
then deploy to production. CI runs the tests automatically. CD
moves the passing build to the target environment without manual steps."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CI/CD and deployment pipelines
- let me walk through the stages and why each matters for reliability."

**(2) First principles:** "From first principles, getting code safely
to production requires: verifying it works (CI), moving it through
environments (CD), and having a way to reverse it quickly if it
breaks (rollback strategy). Every step exists to reduce the risk
of the next."

**(3) Bridge:** "A CI/CD pipeline is like a quality assembly line.
Raw material (code commit) enters one end. Each station (test, build,
security scan, staging deploy, production deploy) adds verification.
A problem at any station stops the line before a defective product
reaches customers."

---

### 📘 Concept Explanation

**What it is:**
CI/CD is the combination of Continuous Integration (automated build
and test on every commit) and Continuous Delivery or Deployment
(automated promotion of passing builds through environments to
production). It eliminates manual steps in the path from code change
to production availability.

**The problem it solves:**
Before CI/CD, integration happened infrequently (weekly "merge day"),
tests ran manually taking hours, and deployment was a scripted
ceremony with a scheduled window. Long integration cycles meant
bugs accumulated. Manual deployments were error-prone. Rollback
was a manual reversal of the same error-prone process. The result:
slow delivery with high incident rates on deployment day.

**How it works:**

```
CI/CD PIPELINE STAGES
======================

CONTINUOUS INTEGRATION (per commit)
  1. Commit triggers pipeline (GitHub Actions,
     Jenkins, GitLab CI)
  2. Build: compile, assemble artifact
  3. Unit tests: fast, isolated (< 5 min)
  4. Integration tests: services + test DB
  5. Static analysis: lint, SAST, dep scan
  6. Container build + push to registry
  Total: 5-15 minutes

CONTINUOUS DELIVERY / DEPLOYMENT
  7. Deploy to staging automatically
  8. Smoke tests in staging
  9. Manual gate (Delivery) or auto (Deployment)
  10. Deploy to production (strategy below)
  11. Post-deploy SLI validation
  12. Auto rollback if SLO breached

DEPLOYMENT STRATEGIES
  Blue-Green:
    Blue = live, Green = new version
    Route traffic to green after smoke test
    Rollback: flip traffic back to blue
    Cost: 2x infra during deployment window

  Canary:
    5% -> 25% -> 100% with observation windows
    Automated rollback on SLO breach
    Cost: complex routing, slower rollout time

  Rolling:
    Replace instances one-by-one
    Requires backward-compatible schema changes
    Rollback: redeploy previous version tag
    Cost: mixed versions run simultaneously
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**
Deployment strategy determines blast radius. Blue-green contains
the blast radius to 0% of production traffic until the switch.
A rolling deployment exposes up to 100% during rollout. For
reliability, the deployment strategy is as important as the
testing strategy - a well-tested bad build deployed big-bang to
all instances is worse than the same build deployed canary to 5%.

**When to use it:**
Always. Every project deploying to production more than once a week
should have a CI/CD pipeline. Deployment strategy choice depends on:
SLO stringency (strict SLOs need canary or blue-green), infrastructure
cost (rolling for cost-sensitive cases), and application state
requirements (stateful services need careful rolling deployment design).

**When NOT to use it:**
Fully automated CD (no human gate) requires high test coverage and
mature SLO-based monitoring. Deploying automatically to production
with 40% test coverage and no automated rollback is more dangerous
than manual deployment. Automate deployment only after the safety
mechanisms are in place.

**Alternatives:**
- GitOps (Argo CD, Flux) - declarative state in git, reconciler applies
- Feature flags (LaunchDarkly) - deploy dark, enable for users separately
- Trunk-based development + feature flags - ship trunk, release deliberately

**First-principles derivation:**
The fundamental risk in deployment is shipping a change that causes
a production incident. The two mitigation strategies are: verify
the change is safe before deploying (CI), and limit the exposure
if verification was insufficient (deployment strategy). A CI/CD
pipeline operationalizes both: automated tests catch bugs before
production; progressive deployment limits blast radius when bugs
escape tests.

---

### 💻 Code Example

**Example 1: GitHub Actions CI pipeline (wrong vs right)**

```yaml
# BAD: no caching, no test separation, slow
name: CI
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: mvn test   # ALL tests, no caching
      # 20+ minutes, blocks developers

# GOOD: cached deps, staged tests
name: CI
on: push
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          cache: maven    # caches .m2 directory
      - name: Unit tests (fast gate)
        run: mvn test -Dgroups=unit
      - name: Build artifact
        run: mvn package -DskipTests
      - name: Integration tests
        run: mvn test -Dgroups=integration
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-jar
          path: target/*.jar
```

> **Code walkthrough:** The BAD version runs all tests without
> dependency caching, re-downloading every library and running slow
> integration tests before fast unit tests. The GOOD version caches
> Maven dependencies (saves 2-5 minutes per build), runs fast unit
> tests first as an early gate, then builds the artifact, then runs
> slower integration tests. A unit test failure returns feedback in
> 2 minutes instead of 20. The artifact upload enables CD stages to
> consume the same verified build without rebuilding.

**Example 2: Canary with automated rollback (Argo Rollouts)**

```yaml
# Canary deployment spec with SLO-based rollback
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: payment-service
spec:
  strategy:
    canary:
      steps:
      - setWeight: 5       # 5% traffic to canary
      - pause: {duration: 5m}
      - analysis:
          templates:
          - templateName: error-rate-check
      - setWeight: 25
      - pause: {duration: 5m}
      - setWeight: 100
      canaryService: payment-service-canary
      stableService: payment-service-stable
```

> **Code walkthrough:** This Argo Rollouts spec sends 5% of traffic
> to the new version initially. After 5 minutes, an AnalysisTemplate
> checks the error rate SLI against the SLO threshold. If the error
> rate exceeds the threshold, Argo automatically rolls back to the
> stable version. If it passes, traffic advances to 25% and the
> check repeats. The automated analysis step is the key: manual
> observation at 2 AM leads to missed rollback windows and extended
> SLO breaches.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> CI/CD is the pipeline that automates getting code to production.
> CI is the automated test and build on every commit. CD is the
> automated deployment to staging and production. The main deployment
> strategies are rolling (replace instances one-by-one), blue-green
> (two environments, switch traffic), and canary (send 5% of traffic
> to the new version first and observe). For SRE work, the most
> important part of CD is having a rollback plan executable in under
> five minutes.

*Push deeper:* Explain what makes tests flaky and why flaky tests
are a reliability problem. A developer who learns to ignore red CI
is a developer who will ignore a real failure one day.

---

**Senior / Staff (5+ years):**
> My SRE perspective on CI/CD: deployment is the number one cause
> of production incidents at most organizations. Change failure rate
> (percent of deployments that cause a degradation) is a DORA metric
> I track explicitly. A team with 10% change failure rate and daily
> deployments is causing an incident from deployments every 10 days.
>
> The pipeline I design has three safety properties: fast feedback
> (unit test failures visible in 3 minutes, not 30), contained blast
> radius (canary or blue-green, never big-bang to production), and
> reversibility (every deploy can roll back in under 5 minutes,
> automated if possible).
>
> The SRE contribution to CI/CD is rollback automation integrated
> with SLO monitoring. If error rate rises above the error budget
> burn rate threshold within 10 minutes of deployment, rollback
> triggers automatically without waking the on-call engineer.

*Push deeper:* Staff angle: "Feature flags are the missing layer
in most CI/CD discussions. You can deploy code dark (merged and
deployed but flagged off), then enable for 1% of users as a canary,
then ramp up. This decouples deployment from release - you deploy
continuously and release deliberately."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| Continuous Deployment means deploying every commit automatically | CD means either Continuous Delivery (human gate to prod) or Continuous Deployment (fully automated); most organizations use Delivery |
| A canary deployment is slower and therefore worse than rolling | Canary is slower intentionally - the observation window is the safety mechanism, not a deficiency |
| Blue-green requires double the hardware permanently | In cloud environments, the green environment is created for the deployment window and torn down after; cost is hours, not permanent |
| Flaky tests are a minor annoyance | Flaky tests train engineers to ignore red builds; a team with flaky tests will eventually re-run past a real failure |
| Rollback means running the old deployment script again | Rollback in a well-designed CD pipeline is a single button or automated trigger; manual rollback procedures are not production-ready |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Manual rollback taking 30 minutes during incident**

*Symptom:* New deployment causes error rate spike. On-call initiates
rollback but the process requires re-running old pipeline, manually
scaling down new pods, and re-routing traffic - taking 20-30 minutes.
SLO is breached during the delay.

*Root cause:* Deployment pipeline has no automated rollback mechanism.
Rollback was an afterthought.

*Diagnostic:*
```bash
# Check if Kubernetes rollout history exists
kubectl rollout history deployment/service-name
# If yes, rollback is one command:
kubectl rollout undo deployment/service-name
# Verify status
kubectl rollout status deployment/service-name
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Redesign deployment pipeline to include rollback as a
first-class concern. Blue-green: traffic switch. Canary: automated
analysis with rollback. Rolling: kubectl rollout undo. Set the
acceptance criterion: rollback completes in under 5 minutes.

*Prevention:* Test rollbacks in staging every 30 days. Make rollback
time a deployment readiness gate.

**Failure 2: Flaky tests blocking deployments and eroding trust**

*Symptom:* Deployments fail in canary analysis or CI due to a test
that fails intermittently. Engineers start re-running analyses to
"get past" the flaky check. Eventually a real failure is re-run past.

*Root cause:* Analysis templates or integration tests have
non-deterministic outcomes unrelated to the deployment quality.

*Diagnostic:*
```bash
# Check analysis run history
kubectl get analysisrun -n <namespace>
# Alternating pass/fail with same code = flaky

# Find flaky tests in CI history
# Test passes 85-95% of runs = definitively flaky
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Quarantine flaky tests immediately - move to a separate
suite that does not block deployment. Fix the non-determinism
(time dependency, port conflict, ordering dependency).

*Prevention:* Track test flakiness rate as a metric. Alert when
a test's pass rate drops below 99%. Treat flaky tests as P2 bugs.

**Failure 3: Schema migration breaks rolling deployment**

*Symptom:* During rolling deployment, old instances that have not
yet been replaced start throwing SQL errors because a migration
added a NOT NULL column that old code does not populate.

*Root cause:* Database migration is not backward compatible. Rolling
deployment requires both versions to run simultaneously for some
period, but the schema change breaks old code immediately.

*Diagnostic:*
```bash
# Check if old pods are still running old image
kubectl get pods -o wide | grep <service>
# Check migration log
cat db_migration.log | grep -i "error\|failed"
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Use the expand-contract pattern. Phase 1: add column as
nullable (backward compatible). Phase 2: deploy new code. Phase 3:
after full rollout, make column required. Never add NOT NULL
constraints in a single migration during rolling deployment.

*Prevention:* All database migrations must be backward compatible
for the duration of a rolling deployment window. Automated schema
compatibility checks in CI.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 15 minutes |
| Core themes | Pipeline stages, deployment strategies, rollback, flaky tests |
| Seniority signal | Junior: names strategies; Senior: connects to SLO and blast radius |
| Common trap | Confusing Continuous Delivery with Continuous Deployment |
| Staff differentiator | DORA metrics, feature flags, change failure rate as reliability signal |

---

**Q1 [JUNIOR]: What is the difference between Continuous
Integration and Continuous Deployment?**

*Why they ask:* Terminology check that also reveals operational
understanding and maturity.

*Likely follow-up:* "What is Continuous Delivery and how does it
differ from Continuous Deployment?"

Continuous Integration is the practice of merging developer changes
into a shared branch frequently (daily or more) and running automated
tests on every merge. The goal is to detect integration bugs early,
before they accumulate into a large expensive fix.

Continuous Deployment is the extension of CI all the way to production:
every commit that passes automated tests is automatically deployed
to production without human approval. This requires high confidence
in the test suite and robust SLO-based monitoring with automated
rollback.

Continuous Delivery sits between the two: the pipeline automates
testing and staging deployment, but production deployment requires
a human approval gate. Most organizations use Delivery, not Deployment
- the human gate is a risk management decision, not a technical
limitation.

*What separates good from great:* Most candidates conflate the two.
Great candidates explain the three-tier distinction and specify the
conditions under which Continuous Deployment (fully automated) is
safe to use.

---

**Q2 [MID]: Which deployment strategy has the lowest blast radius
and what is the trade-off?**

*Why they ask:* Tests whether the candidate thinks about deployment
risk, not just deployment mechanics.

*Likely follow-up:* "When would you choose rolling over canary?"

The lowest blast radius strategy is canary deployment with automated
SLO-based rollback. A canary deploys the new version to 5% of
instances while 95% continues running the stable version. If SLI
monitoring detects a breach and triggers automatic rollback before
the full rollout, the blast radius is limited to 5% of production
traffic for the observation window duration.

The trade-off is deployment speed and complexity. A canary rollout
takes 30-60 minutes (5% observation, then 25%, then 100%, each
with monitoring pauses). Blue-green deploys in under 5 minutes with
instant cutover. Rolling is the simplest with no additional routing
infrastructure.

For a payment service, I use canary: a bad build affecting 5% of
payment transactions is better than 100%. For an internal tool,
rolling is simpler and fast enough given the lower SLO stringency.

*What separates good from great:* Most candidates name canary without
explaining the blast radius quantification. Great candidates explain
the 5% exposure window, the role of automated rollback, and the
speed vs. safety trade-off.

---

**Q3 [MID]: What makes a test flaky and why does it matter for SRE?**

*Why they ask:* Flaky tests are a real operational problem that
candidates with production experience understand deeply.

*Likely follow-up:* "How would you fix a test that fails 10% of
the time?"

A test is flaky when it produces different outcomes for the same code
without any code change. Common causes: time dependency (test checks
a timestamp and fails near midnight), port conflicts (test uses a
fixed port that may be in use), ordering dependency (test assumes
previous test ran first and modified shared state), external service
calls (test calls a real API that is sometimes slow), or race
conditions in multi-threaded test setups.

For SRE, flakiness matters because a CI pipeline with even 5% test
flakiness trains engineers to ignore red builds. The first time a
real bug causes a red build, it gets re-run instead of investigated.
This is how production incidents escape CI undetected. A flaky test
suite is worse than no test suite for trust - it provides false
confidence and erodes the safety mechanism designed to catch bugs
before production.

I treat test flakiness rate as an SLI. Any test that fails more
than once in 50 runs without code changes is quarantined immediately
and treated as a P2 bug.

*What separates good from great:* Most candidates describe flakiness
as an inconvenience. Great candidates explain the trust erosion
mechanism and treat flakiness as a reliability metric requiring
active management.

---

**Q4 [SENIOR]: How do you design a pipeline that rolls back
automatically when a deployment causes an SLO breach?**

*Why they ask:* Connecting deployment pipeline to SLO monitoring is
an advanced SRE practice that separates candidates with breadth.

*Likely follow-up:* "What SLI threshold triggers automated rollback?"

The pattern: deploy canary, monitor specific SLIs for a fixed window,
automatically roll back if any SLI exceeds its error budget burn
rate threshold.

Concretely with Argo Rollouts and Prometheus: I define an
AnalysisTemplate that queries the error rate SLI for the canary
deployment. If error rate exceeds 0.1% (our error budget burn rate
threshold) within the 10-minute observation window, Argo marks the
analysis Failed and triggers automatic rollback to the previous
stable version.

The SLI I use is the fast-burn alert threshold from our SLO - the
same threshold that would page an on-call engineer if triggered
outside a deployment window. If the deployment would cause an on-call
page, it should roll back automatically without waking anyone.

The key design constraint: rollback must complete faster than the SLO
breach accumulation rate. If we detect at the 10-minute mark and
the SLO allows 0.1% error budget per hour, rollback must complete
before 10 minutes of errors exhausts the hourly budget.

*What separates good from great:* Most candidates describe canary as
a manual observe-then-promote process. Great candidates describe the
automated analysis integrated with SLO monitoring and frame the
rollback threshold as derived from the error budget burn rate.

---

**Q5 [SENIOR]: What is the expand-contract pattern for database
migrations and why is it needed for rolling deployments?**

*Why they ask:* Database migration safety is a real operational
complexity that separates candidates with hands-on deployment experience.

*Likely follow-up:* "What happens if you skip the expand phase?"

The expand-contract pattern is the three-phase approach for making
database schema changes safe when old and new code run simultaneously
during rolling deployments.

Phase 1 (expand): Add the new column as nullable. Old code does not
know the column exists and ignores it. New code can start writing to
it. The schema change is backward compatible - old code still works.

Phase 2 (migrate): Deploy new code that reads and writes the new
column. Old code on non-updated instances still works because the
column is nullable. This is the rolling deployment phase where both
versions coexist.

Phase 3 (contract): After all instances run new code, apply the
final migration: make the column required, drop the old column,
remove the compatibility code path.

If you skip expand and apply a breaking migration (add NOT NULL
column, rename column used by old code), old instances immediately
throw SQL errors. In a rolling deployment, this means the migration
causes the incident the deployment was supposed to avoid.

*What separates good from great:* Most candidates know migrations
can break deployments. Great candidates name the three-phase pattern,
explain why each phase is safe, and give a concrete example of
what breaks if expand is skipped.

---

**Q6 [SENIOR]: What are the DORA metrics and which matter most
for SRE reliability?**

*Why they ask:* Tests familiarity with delivery performance
measurement and which metrics have direct reliability implications.

*Likely follow-up:* "How would you improve change failure rate
from 15% to 5%?"

The four DORA metrics are: deployment frequency (how often code
deploys to production), lead time for changes (commit to production),
change failure rate (percent of deployments causing a production
degradation), and mean time to restore (MTTR after an incident).

For SRE, the two that matter most are change failure rate and MTTR.
These are reliability metrics. Deployment frequency and lead time
are velocity metrics. A team deploying 50 times per day with a 20%
change failure rate is causing 10 deployment-related incidents per
day - velocity without safety is worse than slower deployment.

Change failure rate is the output metric for deployment safety. Above
5% signals insufficient safety mechanisms: inadequate test coverage,
no canary strategy, no automated rollback. MTTR is the output metric
for incident response capability. MTTR above the SLO recovery window
means runbooks and rollback procedures are inadequate.

*What separates good from great:* Most candidates recite all four
metrics equally. Great candidates distinguish reliability metrics
(change failure rate, MTTR) from velocity metrics and frame change
failure rate as the deployment pipeline quality indicator.

---

**Q7 [STAFF]: How do feature flags extend CI/CD and what are the
SRE implications?**

*Why they ask:* Staff-level progressive delivery question testing
understanding of deployment-release decoupling.

*Likely follow-up:* "What are the operational risks of using too
many feature flags?"

Feature flags decouple deployment from release. Code is merged to
the main branch and deployed to production in a dark state - the
flag is off. The release happens separately when the flag is enabled
for users. Deployment is continuous and low-risk; release is
controlled and independently reversible.

The SRE value is blast radius control without infrastructure
complexity. Instead of routing 5% of traffic to a separate canary
infrastructure (load balancer changes, separate metric collection,
added complexity), you enable a feature for 5% of users via a flag
configuration change - immediately reversible in seconds.

Feature flags also enable non-deployment rollback: if a bug is in
feature-flagged code, disabling the flag reverts behavior in seconds
without a redeployment or a Kubernetes rollout. The mean time to
mitigate drops from minutes (deployment rollback) to seconds (flag
toggle).

The operational risks are flag sprawl and stale flags. A codebase
with 200 feature flags has combinatorial complexity. Stale flags
(enabled but never evaluated) accumulate as dead code. I treat
feature flags as temporary by default: each flag gets a removal
ticket created at creation time, with a target date 30-90 days
after planned full rollout.

*What separates good from great:* Most candidates describe feature
flags as a developer convenience. Great candidates frame them as
an SRE reliability tool with explicit blast radius control and
faster MTTR, and name the operational risks with concrete mitigations.

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



