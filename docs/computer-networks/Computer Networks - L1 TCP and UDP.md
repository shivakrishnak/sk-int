---
layout: default
title: "Computer Networks - L1 TCP and UDP"
parent: "Computer Networks"
nav_order: 2
permalink: /computer-networks/l1-tcp-and-udp/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 4 | [TCP: Reliability, Connection, and Flow Control](#tcp-reliability-connection-and-flow-control) | high |
| 5 | [UDP and When to Choose It](#udp-and-when-to-choose-it) | high |
| 6 | [IP Addressing, Subnets, and CIDR](#ip-addressing-subnets-and-cidr) | medium |

---

# TCP: Reliability, Connection, and Flow Control

**Interview Weight:** Very High - TCP is in virtually every backend interview. Understanding its mechanisms explains connection-related bugs, latency patterns, and why certain optimizations work.

---

## Quick Reference

**One-line definition:** TCP (Transmission Control Protocol) provides reliable, ordered, byte-stream delivery between two endpoints through connection setup (3-way handshake), acknowledgment-based retransmission, flow control (receiver-side window), and congestion control (network-side window).

**Difficulty:** ★☆☆ | **Asked at:** All levels | **Seniority:** Junior-Senior

---

### 🎯 Model Answer

**30 seconds:**
TCP provides reliability through three mechanisms: acknowledgments (receiver confirms every byte received; sender retransmits if no ACK), ordering (sequence numbers allow the receiver to reorder out-of-order packets), and flow control (receiver advertises a "receive window" to prevent the sender from overwhelming it). The 3-way handshake (SYN → SYN-ACK → ACK) establishes the connection before any data. The 4-way close (FIN → ACK → FIN → ACK) tears it down. TCP connections have state - this is what makes firewalls "stateful" and what TIME_WAIT is protecting.

**3 minutes (Senior):**
TCP's reliability mechanisms directly affect production systems. Connection overhead: the 3-way handshake adds 1.5 RTT before the first byte of application data. TLS adds another 1-2 RTTs. For high-RPS services, connection pooling amortizes this cost. Congestion control: TCP uses AIMD (Additive Increase, Multiplicative Decrease) - it grows the congestion window slowly and halves it on packet loss. With 1% packet loss and 80ms RTT, TCP throughput saturates far below the link's bandwidth. The "slow start" phase after a new connection or loss event limits initial throughput. Flow control vs congestion control: flow control protects the receiver (receiver's buffer won't overflow); congestion control protects the network (intermediate routers won't drop packets). Both use the TCP window but serve different purposes. TIME_WAIT: after the active closer sends the final ACK, the connection stays in TIME_WAIT for 2*MSL (typically 60-120 seconds). This prevents a new connection from receiving segments from the old one. High-connection-rate servers get thousands of TIME_WAIT connections - expand ephemeral ports or enable `tcp_tw_reuse`.

**Framework:** HANDSHAKE → DATA TRANSFER → FLOW CONTROL → CONGESTION CONTROL → TEARDOWN → STATE MANAGEMENT

**Blank Mind Recovery:**

**(1) Restate:** "TCP reliability - how does TCP guarantee ordered, complete delivery despite network packet loss and reordering?"

**(2) First principles:** "The network drops packets randomly. To build reliability: number every byte (sequence numbers), confirm receipt (acknowledgments), resend if no confirmation (retransmission timer), and don't send faster than the receiver can accept (flow control)."

**(3) Bridge:** "Like certified mail: each letter has a number, the recipient signs for it (ACK), the sender waits before sending the next batch (window), and resends if the receipt doesn't come back (retransmission timer)."

---

### 📘 Concept Explanation

**What it is:**
TCP is the transport protocol providing reliable, ordered, duplex byte-stream communication. Used by HTTP/1.1, HTTP/2, gRPC, TLS, SSH, SMTP - all application protocols where reliability matters.

**The problem it solves:**
IP is unreliable: packets can be dropped, reordered, or duplicated. TCP builds reliability on top of IP so applications don't need to handle packet loss, ordering, or duplication.

**How it works:**

```
3-way handshake:
  Client          Server
    |---SYN------>|  (Seq=x, SYN flag)
    |<--SYN-ACK--|  (Seq=y, Ack=x+1)
    |---ACK------>|  (Ack=y+1) + optional data
  Connection established. Cost: 1.5 RTT

Data transfer with loss:
  Sender sends: [1][2][3][4][5]
  Packet [3] is lost in network.
  Receiver: ACK 1, ACK 2, ACK 2, ACK 2
             (duplicate ACKs = loss signal)
  Sender: fast-retransmit [3] on 3 dup ACKs
  Or: wait for RTO timer, then retransmit [3]

Flow control: receiver advertises window
  If receiver buffer has 64KB free:
  TCP header window = 64KB
  Sender may not exceed 64KB in-flight

Congestion control (AIMD simplified):
  New connection: window = 10 MSS (slow start)
  Each RTT without loss: window += 1 MSS
  On loss: window = window / 2

4-way close:
  |---FIN----->|  (active closer done sending)
  |<---ACK-----|
  |<---FIN-----|  (passive closer done sending)
  |---ACK----->|
  [TIME_WAIT: 2*MSL ~60-120s before freed]
```

> **Diagram walkthrough:** The handshake establishes sequence numbers for both directions (TCP is full-duplex with independent sequence spaces per direction). The data transfer shows fast retransmit triggered by 3 duplicate ACKs - this avoids waiting for the full RTO timeout, typically hundreds of milliseconds. The flow control window prevents buffer overflow on the receiver. The 4-way close allows half-close - each side signals FIN when it has finished sending, independently. TIME_WAIT on the active closer handles the case where the final ACK is lost (passive closer will retransmit its FIN; active closer, still in TIME_WAIT, can respond with a new ACK). The senior insight: Nagle's algorithm coalesces small writes into one TCP segment - it must be disabled (`TCP_NODELAY`) for interactive protocols like Redis and Postgres, or 40ms delays are introduced between each small write.

**Key TCP socket options for engineers:**

- TCP_NODELAY: disables Nagle algorithm. Required for interactive protocols (Redis, Postgres, MySQL). Most client libraries set this automatically.
- SO_KEEPALIVE: enables TCP keepalive probes. Combined with tcp_keepalive_time, tcp_keepalive_interval, tcp_keepalive_probes to detect dead connections.
- SO_REUSEADDR: allows binding to a port in TIME_WAIT state. Standard for server sockets.
- TCP_FASTOPEN: allows data in the SYN packet, reducing handshake to 1 RTT for known connections.

---

### 💻 Code Example

**BAD: Interactive protocol without TCP_NODELAY**

```python
# BAD: Redis client without TCP_NODELAY.
# Nagle algorithm coalesces small writes,
# waiting up to 40ms for data to accumulate.
# A pipeline of small Redis commands is
# serialized: each write waits for the
# previous one to be ACK'd before sending.
# A 10-command pipeline: 400ms instead of 40ms.

import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# TCP_NODELAY not set -> Nagle enabled (default)
sock.connect(('redis', 6379))
# Every small write waits up to 40ms before sending
sock.send(b"PING\r\n")
```

> **Code walkthrough:** Nagle buffers small writes until either a full MSS accumulates or the previous unacknowledged segment is ACK'd. For interactive protocols (Redis, Postgres), this means each small write waits for the previous ACK to return before the next write is sent - serializing latency. At 40ms RTT, a 10-command Redis pipeline takes 400ms. The application expects pipelining to work (all commands sent in one burst), but Nagle prevents it. The production symptom is "Redis is slow for batch operations" - which is actually the Nagle delay, not Redis.

**GOOD: TCP_NODELAY for low-latency interactive protocols**

```python
# GOOD: Disable Nagle for interactive protocols.
# Each write sent immediately, enabling true pipelining.
# Redis pipeline: all 10 commands sent in one burst,
# one RTT for all responses. 40ms total.

import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(
    socket.IPPROTO_TCP,
    socket.TCP_NODELAY,
    1  # 1 = disable Nagle algorithm
)
sock.connect(('redis', 6379))
# All writes sent immediately without coalescing delay.

# Verify in production:
# strace -e trace=network python app.py
# Should see each send() result in immediate write(2)
# syscall, not batched delays.
```

> **Code walkthrough:** `TCP_NODELAY` disables Nagle: each `send()` call transmits a TCP segment immediately regardless of size. The tradeoff is slightly more TCP overhead (more small segments) in exchange for lower per-command latency. For Redis/Postgres where commands are small (50-200 bytes) and pipelining is the throughput strategy, this tradeoff is always worth it. All production Redis clients (redis-py, Jedis, ioredis) set TCP_NODELAY by default. For raw socket code: always set TCP_NODELAY for request-response protocols. For bulk transfer (large file copy), leave Nagle enabled - it coalesces small writes without the latency penalty since you're sending data continuously.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
TCP provides reliability via ACKs and retransmission, ordering via sequence numbers, and flow control via receive window. The 3-way handshake establishes a connection in 1.5 RTT. Common production issues: not setting TCP_NODELAY for interactive protocols (Nagle delay), not tuning keepalive (dead connections held for 2 hours by default), and TIME_WAIT exhaustion at high connection rates. TCP connections are stateful - both endpoints maintain state, which is why firewalls must be stateful to allow return traffic.

---

**Senior / Staff (5+ years):**
At senior level, TCP internals explain production performance patterns. Slow start means the first request on a new connection is slower than subsequent ones (congestion window starts at 10 MSS and grows slowly). HTTP/2 multiplexing outperforms HTTP/1.1 partly because one HTTP/2 connection grows its congestion window, while many HTTP/1.1 connections all start in slow start simultaneously. TCP BBR is a newer congestion control algorithm from Google that achieves higher throughput and lower latency than CUBIC on lossy networks (cellular, satellite). BBR models the bottleneck bandwidth directly rather than using packet loss as the congestion signal, resulting in lower bufferbloat and more consistent throughput. Enable via `net.ipv4.tcp_congestion_control = bbr`.

---

### ⚠️ Common Misconceptions

**Misconception 1: "TCP guarantees delivery to the application"**

TCP guarantees delivery to the TCP layer on the remote machine. If the application crashes after the TCP ACK is sent but before processing the data, the data is lost from the application's perspective. Application-level acknowledgment (the database's write ACK, the message queue's publish confirmation) is the only true end-to-end delivery guarantee for distributed systems. TCP is "reliable transport," not "reliable processing."

---

**Misconception 2: "TIME_WAIT is a bug or misconfiguration"**

TIME_WAIT is deliberate. It exists to handle lost final ACKs (the passive closer retransmits its FIN; the active closer in TIME_WAIT responds) and to prevent stale segments from old connections entering new connections on the same 4-tuple. TIME_WAIT becomes a problem only when the ephemeral port range is exhausted at high connection rates. Fix: connection pooling (primary), expand port range (secondary), `tcp_tw_reuse=1` (tertiary). Never bypass TIME_WAIT with `tcp_tw_recycle` (deprecated in kernel 4.12 for breaking NAT).

---

**Misconception 3: "TCP zero window means the connection is broken"**

Zero window advertisement means the receiver's buffer is full - it's signaling "pause" to the sender. The sender enters zero-window-probe mode, sending periodic tiny segments to check if the window opens. When the application on the receiver reads its buffer, the window opens and transfer resumes. This is normal flow control during a burst, not a broken connection. It becomes a problem if the window stays zero indefinitely (application stopped reading) - this indicates a slow consumer or deadlock, not a network failure.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: TCP Retransmission Storm Under Load**

Symptom: service handles low load well but degrades nonlinearly at high load; latency spikes correlate with load; `ss` shows increasing retransmits.

Cause: switch/router buffer overflow under load causes packet drops. TCP interprets drops as congestion, reduces sending rate, and then more requests queue up, causing more drops - a feedback loop.

Diagnosis:
```bash
# Monitor TCP retransmit rate globally
nstat TcpRetransSegs -z
# or
netstat -s | grep -i retransmit

# Per-connection detail
ss -ti dst <server-ip>
# Key fields: rto (retransmit timeout ms),
#   cwnd (congestion window, MSS units),
#   retrans (retransmit count),
#   ssthresh (slow-start threshold)
# Small cwnd + high retrans = congestion

# Switch to BBR for better loss handling
sysctl -w net.ipv4.tcp_congestion_control=bbr
```

> **Code walkthrough:** `nstat TcpRetransSegs` shows the global retransmit counter. A counter that grows rapidly under load confirms packet loss. `ss -ti` provides per-connection TCP internals: `cwnd:2` means the congestion window is only 2 MSS (~3KB) - the connection is barely able to send anything due to repeated loss events. `retrans:5` means 5 retransmissions on this connection. `ssthresh:10` shows the connection has halved its window threshold multiple times. Switching to BBR reduces the number of retransmissions in buffer-bloat scenarios because BBR probes bandwidth without filling queues, while CUBIC (the default) deliberately fills queues to find the bottleneck, causing drops.

---

**Failure 2: Half-Open Connection Resource Leak**

Symptom: server accumulates connections in ESTABLISHED state that are no longer active; eventually runs out of file descriptors or connection slots.

Cause: client crashes or loses network connectivity without sending FIN. Server's TCP stack doesn't know the connection is dead. Server holds socket open indefinitely.

Diagnosis:
```bash
# Find potentially stale ESTABLISHED connections
ss -tn state established | head -20
# Look for connections with no recent activity

# Check keepalive settings
sysctl net.ipv4.tcp_keepalive_time
# Default: 7200 (2 hours) - too long

# Fix: reduce keepalive to detect dead connections faster
sysctl -w net.ipv4.tcp_keepalive_time=60
sysctl -w net.ipv4.tcp_keepalive_interval=10
sysctl -w net.ipv4.tcp_keepalive_probes=3
# Dead connections detected within: 60 + 3*10 = 90s
```

> **Code walkthrough:** With default keepalive of 7200 seconds, a crashed client can hold server socket state (buffers, file descriptor) for 2 hours before the kernel detects it. At scale, this means a brief connectivity event can leave hundreds of zombie connections consuming file descriptors (each open socket uses one FD; default Linux limit: 1024 per process, 65,536 system-wide). Reducing `tcp_keepalive_time` to 60 seconds means detection within 90 seconds. Application-level heartbeats (periodic no-op request/response, 5-10 second intervals) are faster and more reliable than kernel TCP keepalive because they work at Layer 7 and aren't affected by intermediate firewalls that may not forward TCP keepalive probes.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | Handshake, reliability, TIME_WAIT |
| Application | 2 | TCP_NODELAY, keepalive diagnosis |
| Behavioral | 1 | TCP production incident |
| Trade-off | 1 | Congestion control tradeoffs |

---

**[JUNIOR] Q1 - [MECHANISM] Explain the TCP 3-way handshake step by step.**

Step 1 - SYN: client picks a random Initial Sequence Number (ISN) and sends a SYN segment with that ISN. This tells the server "I want to connect, and my data stream starts at this sequence number." Step 2 - SYN-ACK: server receives SYN, picks its own random ISN, and replies with SYN-ACK. The ACK field = client's ISN + 1 (acknowledging the client's SYN). The SYN flag carries the server's ISN. Both ISNs are now exchanged. Step 3 - ACK: client sends ACK = server's ISN + 1, acknowledging the server's SYN. The client may include application data (piggybacked). Connection is established. Total cost: 1.5 RTTs (SYN takes 0.5 RTT to reach server; SYN-ACK returns = 1 RTT elapsed; ACK takes 0.5 RTT = 1.5 RTTs total). Why random ISNs? To prevent sequence prediction attacks where an attacker guesses sequence numbers and injects forged packets (TCP session hijacking). ISNs are pseudo-random and change per connection.

*What separates good from great:* The ISN randomization security purpose, and explaining that the client can include data in the final ACK (important for TLS False Start and HTTP pipelining understanding).

---

**[JUNIOR] Q2 - [MECHANISM] What is the difference between flow control and congestion control in TCP?**

Flow control protects the receiver. The receiver advertises available buffer space in the "window size" field of every ACK. The sender may not have more than this many unacknowledged bytes in-flight. If the application on the receiver reads slowly, buffer fills, window shrinks to zero, and sender pauses. This is a signal from receiver to sender only. Congestion control protects the network. The sender maintains a congestion window (cwnd) based on estimates of available network capacity. It infers congestion from packet loss (CUBIC) or increasing RTT (BBR). After loss, cwnd is halved (AIMD). This is the sender self-limiting to avoid overloading intermediate routers. Effective throughput = min(receive window, congestion window) / RTT. Both constraints are on the sender; the receive window is reported by the receiver; the congestion window is computed by the sender. In practice: high-bandwidth WAN links are often congestion-window-limited (BBR helps); slow applications on the receiving side cause flow control pauses (fix: increase receive buffer, speed up the consuming application).

*What separates good from great:* The combined throughput formula (min of both windows divided by RTT), and the practical diagnosis: zero window probe = flow control; small cwnd = congestion control.

---

**[MID] Q3 - [MECHANISM] What is TIME_WAIT and why does it exist?**

After a TCP connection is closed by the active closer (the side that sends FIN first), the connection enters TIME_WAIT for 2*MSL (Maximum Segment Lifetime, typically 60-120 seconds on Linux). Two reasons: (1) Handle lost final ACK: the active closer sends ACK for the passive closer's FIN. If this ACK is lost, the passive closer retransmits its FIN. The active closer, still in TIME_WAIT, can respond with a new ACK. Without TIME_WAIT, the port is freed and a new SYN on the same 4-tuple would receive a spurious FIN. (2) Prevent stale segments: network equipment may retain old segments for up to MSL seconds. TIME_WAIT ensures all old segments for this 4-tuple expire before the port can be reused, preventing a new connection from receiving them. Production problem: at high connection rates (~466 new connections/second per the math: 28K ports / 60s), the ephemeral port pool exhausts. Fixes in order of preference: (1) connection pooling - avoid creating new connections; (2) expand port range: `net.ipv4.ip_local_port_range = 1024 65535`; (3) `tcp_tw_reuse=1` - safe reuse with TCP timestamps. Never use `tcp_tw_recycle` - removed in kernel 4.12 for breaking NAT.

*What separates good from great:* The calculation showing exactly when TIME_WAIT becomes a problem (connection rate threshold), and the ordered list of fixes with the warning about `tcp_tw_recycle`.

---

**[SENIOR] Q4 - [MECHANISM] Explain TCP's congestion control and why it matters for production services.**

TCP CUBIC (default Linux) uses packet loss as the congestion signal. On packet loss: halve cwnd. In congestion avoidance: grow cwnd cubically. This causes sawtooth throughput: grow, lose, shrink, grow again. With 0.1% packet loss and 80ms RTT, the Mathis formula gives throughput = sqrt(0.75/loss) * MSS/RTT = ~3.5MB/s on a 1Gbps link. Far below the link capacity. TCP BBR (Google, 2016) models bottleneck bandwidth and RTT directly. It backs off when RTT starts increasing (buffer filling up), not when loss occurs. Benefits: higher throughput on lossy links, lower latency (doesn't fill buffers), more stable throughput. Production implications: (1) First request on new connection: slow start begins with 10 MSS (~15KB). For HTTP/1.1 with per-request connections, every request starts in slow start. HTTP/2 one connection grows its cwnd over many requests. (2) Cross-region replication: BBR dramatically outperforms CUBIC on transatlantic links with any packet loss. (3) Enable BBR: `sysctl -w net.ipv4.tcp_congestion_control=bbr`. Verify: `ss -ti` and observe cwnd stays high even with occasional loss.

*What separates good from great:* The Mathis formula result showing a 1Gbps link achieving only 3.5MB/s at 0.1% loss under CUBIC, and the HTTP/2 single-connection congestion window advantage.

---

**[SENIOR] Q5 - [BEHAVIORAL] Describe a TCP-related production issue you resolved.**

At a job board, our search API had 5% of requests taking 200-400ms instead of the expected 20ms during peak hours. Application profiling showed normal query times. Investigation: `ss -ti dst search-service:8080` showed some connections with `retrans:1` and `cwnd:2` - they'd experienced packet loss and entered slow start with a tiny congestion window. The connections with low cwnd were being reused from the HTTP connection pool for new search requests. Root cause: during search traffic spikes, the network switch's buffers filled and dropped packets. TCP backed off on those specific TCP connections. Since the HTTP client reused those connections (connection pooling), subsequent requests on the "damaged" connections still operated with a tiny cwnd. Fix: configured the HTTP connection pool to discard connections with high retransmit counts (checking the connection health before returning it to the pool). Also deployed TCP BBR to reduce cwnd collapse under burst drops. Result: p99 latency dropped from 400ms to 28ms. Lesson: connection pool health must account for TCP congestion state, not just TCP connectivity (is the connection ESTABLISHED) - a connected but congestion-damaged connection is worse than a fresh one.

*What separates good from great:* The "damaged connection reuse" insight - a pooled TCP connection carries its congestion state across requests, meaning a connection that experienced loss is slower for subsequent requests until cwnd recovers.

---

**[STAFF] Q6 - [TRADE-OFF] When would you use QUIC instead of TCP, and what does QUIC fix?**

QUIC (HTTP/3's transport) runs over UDP and replicates TCP's reliability while fixing specific limitations. What QUIC fixes: (1) Head-of-line blocking: HTTP/2 multiplexes streams over one TCP connection. A lost packet blocks ALL streams until retransmitted. QUIC implements per-stream reliability - a lost packet blocks only its own stream. Other streams deliver immediately. (2) Faster establishment: QUIC combines transport handshake and TLS 1.3 into one round trip (1-RTT first connection). TCP+TLS 1.3 needs 2.5 RTT. Resumed connections use 0-RTT. (3) Connection migration: QUIC identifies connections by a 64-bit Connection ID, not the 4-tuple. A mobile user switching Wi-Fi to cellular keeps the same QUIC connection; TCP requires reconnection. (4) User-space congestion control: deployable without kernel changes, enabling faster protocol innovation. When to use QUIC: mobile clients with network changes, high-latency/lossy last-mile (cellular, satellite), many concurrent HTTP streams. When to stick with TCP: non-HTTP protocols (databases, queues), environments where UDP is blocked (corporate firewalls), or when QUIC's user-space overhead is measurable vs kernel TCP.

*What separates good from great:* Connection migration (mobile network switching without reconnection - the practical user-facing benefit), and the UDP-blocking concern (enterprise firewalls that force HTTP/3 fallback to TCP).

---

**[STAFF] Q7 - [DESIGN] How does TCP behavior affect the design of a high-performance cache service?**

A high-performance cache (Redis, Memcached) serves many small requests with strict latency requirements (<1ms p99). TCP behavior shapes the entire design: (1) TCP_NODELAY mandatory: Nagle's 40ms coalescing delay is catastrophic for sub-millisecond requirements. All Redis clients set TCP_NODELAY. Custom cache clients must too. (2) Connection pooling required: 1.5 RTT handshake on a 0.5ms RTT connection = 0.75ms per new connection, before any data. Pool 10-50 persistent connections per client instance. (3) Pipelining for throughput: Redis pipelining sends 100 commands in one TCP segment and reads one bulk response - 1 RTT for 100 commands vs 100 RTTs. This fully utilizes the TCP congestion window. (4) TCP keepalive: reduce to 60s to detect crashed clients quickly, release server FDs. (5) Accept queue: `net.core.somaxconn` must be large enough for connection storm handling. Default 128 is too small; use 4096+. (6) Backlog-aware servers: Redis `bind` + `listen` with backlog large enough for connection bursts during deployments (when all clients reconnect simultaneously after server restart). Accept queue overflow drops SYNs silently - clients see timeouts.

*What separates good from great:* The accept queue overflow as a silent failure (SYNs dropped, clients see timeouts not connection refused) during connection storms on server restart.

---

### ⚖️ Comparison Table

| TCP Mechanism | Purpose | Default | Tuning |
|---|---|---|---|
| Nagle algorithm | Reduce small-packet overhead | Enabled | TCP_NODELAY to disable |
| Keepalive | Detect dead connections | 7200s first probe | Lower tcp_keepalive_time |
| TIME_WAIT | Safe connection teardown | 60-120 seconds | tcp_tw_reuse, expand port range |
| Congestion control | Protect network | CUBIC | BBR for high-latency paths |
| Flow control | Protect receiver buffer | Auto | Increase SO_RCVBUF |
| SACK | Efficient loss recovery | Enabled (default) | Keep enabled |

---

### 🏛️ System Design

*(Omit: ★☆☆ difficulty.)*

---

### 📊 Diagram

*(Included in Concept Explanation section above.)*

---
---

# UDP and When to Choose It

**Interview Weight:** Moderate - UDP knowledge differentiates engineers who understand protocol trade-offs from those who default to TCP for everything.

---

## Quick Reference

**One-line definition:** UDP (User Datagram Protocol) is a connectionless, unreliable transport providing low-overhead datagram delivery without connection setup, ordering, or retransmission - leaving all reliability to the application when needed.

**Difficulty:** ★☆☆ | **Asked at:** Junior-Senior | **Seniority:** Junior-Senior

---

### 🎯 Model Answer

**30 seconds:**
UDP has no connection setup, no acknowledgments, no retransmission, no ordering. You fire datagrams and they either arrive or don't. The correct choice for UDP: DNS (query-response, retry is trivial), video/audio streaming (a dropped frame is better than a stalled stream), gaming (stale positions are worse than no update), and QUIC (which builds its own reliability on top of UDP). The wrong choice: anything requiring every byte in order - databases, file transfer, API calls.

**3 minutes (Senior):**
UDP has two key advantages: no per-connection state and no head-of-line blocking. No state means a UDP server handles millions of clients without tracking connection state - a DNS server serves tens of thousands of queries per second from millions of IPs with zero setup overhead. No HOL blocking: if one datagram is lost, subsequent datagrams are delivered independently. Applications that need UDP reliability implement exactly what they need: QUIC implements per-stream reliability, DTLS adds TLS security, online games use sequence numbers with interpolation for game state, RTP (Real-time Transport Protocol) adds its own timestamps for audio/video. Rule: use UDP when (1) latency beats reliability, (2) the application tolerates or self-manages loss, or (3) you're building a custom transport with specific reliability requirements.

**Framework:** CONNECTIONLESS → NO-OVERHEAD DELIVERY → APPLICATION-MANAGED RELIABILITY → USE CASES

**Blank Mind Recovery:**

**(1) Restate:** "UDP - the protocol without guarantees. Why would anyone use it?"

**(2) First principles:** "TCP reliability costs 1.5 RTT handshake, per-packet ACK overhead, retransmission delays, and HOL blocking. For some use cases, these costs exceed the benefit."

**(3) Bridge:** "UDP is like shouting across a room: fast, no setup, but no guarantee you were heard. TCP is like a phone call: you establish connection first and verify every sentence."

---

### 📘 Concept Explanation

**What it is:**
UDP adds port-based demultiplexing and an optional checksum to IP. No connection state, no sequence numbers, no ACKs, no retransmission, no flow/congestion control.

**The problem it solves:**
TCP's reliability machinery adds overhead and constraints. For use cases where stale data is worse than no data (real-time audio/video), where the application implements its own retransmission (QUIC), or where connection state overhead is unacceptable (DNS), UDP provides the right foundation.

**UDP vs TCP headers:**

```
UDP header (8 bytes total):
  Source Port     (16 bits)
  Destination Port(16 bits)
  Length          (16 bits)
  Checksum        (16 bits)

TCP header (20-60 bytes):
  Source Port     (16 bits)
  Destination Port(16 bits)
  Sequence Number (32 bits)   <- ordering guarantee
  Ack Number      (32 bits)   <- reliability
  Flags/Window    (variable)  <- flow control
  Options (0-40 bytes)        <- SACK, timestamps

Message boundary behavior:
  UDP: send(1000 bytes) -> recv() = 1000 bytes exactly
       (message boundaries preserved)
  TCP: send(1000 bytes) -> recv() may return 400 bytes
       (byte stream, application must frame messages)
```

> **Diagram walkthrough:** The header comparison shows the size difference: 8 bytes (UDP) vs 20-60 bytes (TCP). TCP's additional fields implement reliability (sequence/ack numbers) and flow control (window size). UDP has none of these. The message boundary behavior is a key practical difference: UDP's `recv()` returns one complete datagram - the OS preserves boundaries. TCP's `recv()` returns an arbitrary slice of the byte stream, requiring length-prefix or delimiter-based framing at the application layer. This difference means TCP applications need explicit message framing (length-prefix headers), while UDP applications get natural message framing from the protocol.

**When to use UDP:**

```
Protocol    Why UDP
DNS         Query-response; retry if timeout; no state
DHCP        Bootstrap protocol; client has no IP yet
SNMP        Polling; loss = wait for next poll
NTP         Time sync; one-way; statistical averaging
VoIP/RTP    Stale audio useless; latency > reliability
Gaming      Old position useless; discard and continue
QUIC        Reimplements reliable delivery without HOL
Metrics     Fire-and-forget; loss is statistical noise
```

> **Code walkthrough:** This reference table organises the UDP vs TCP choice by application type. WHAT IT SHOWS: each row names a protocol or use case and explains why packet loss is acceptable or expected. KEY MECHANISM: UDP's lack of retransmission means the sender never slows down waiting for ACKs - at the cost of possible delivery gaps. WHY IT MATTERS: choosing TCP for DNS or metrics adds latency and can create cascading failures (TCP back-pressure halting your own application). WHAT BREAKS: using UDP for bank transfers or order processing loses transactions silently. TAKEAWAY: use UDP only when the application layer can tolerate or detect loss itself.

---

### 💻 Code Example

**BAD: TCP for fire-and-forget metrics with back-pressure risk**

```python
# BAD: Sending metrics over a TCP connection.
# If the metrics server slows down, TCP flow
# control back-pressures to the application.
# Application slows to match metrics ingestion rate.
# The observability path is now a bottleneck.

import socket

_tcp_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
_tcp_sock.connect(('metrics', 2003))

def record_counter(name, value):
    # If metrics server buffer is full:
    # sendall() blocks here. Application latency
    # increases to match metrics server speed.
    _tcp_sock.sendall(
        f"{name} {value}\n".encode()
    )
```

> **Code walkthrough:** TCP's flow control means the sender blocks when the receiver's buffer is full. If the metrics server slows down (GC pause, disk I/O, overload), its TCP receive buffer fills. The application's `sendall()` blocks, waiting for buffer space. The application's request-handling threads are now stuck in metrics code. This is exactly the wrong failure mode for observability infrastructure - the monitoring system should never affect the monitored system's latency.

**GOOD: UDP for fire-and-forget metrics**

```python
# GOOD: UDP metrics - fire and forget.
# The application never blocks on metrics delivery.
# Occasional metric loss is acceptable noise in
# aggregated monitoring data.

import socket

# One UDP socket per process.
_udp_sock = socket.socket(
    socket.AF_INET,
    socket.SOCK_DGRAM  # UDP
)
# Optional: set default destination with connect()
# (Does NOT send a packet - just sets dest address)
_udp_sock.connect(('metrics', 8125))

def record_counter(name, value, tags=""):
    try:
        # Fire and forget. Never blocks.
        # If OS send buffer full: EAGAIN (drop, continue)
        # If server unreachable: ICMP (ignored)
        payload = f"{name}:{value}|c|#{tags}"
        _udp_sock.send(payload.encode())
    except OSError:
        pass  # Silently discard. Correct behavior.

# StatsD/DogStatsD protocol uses this exact pattern.
# Datadog, Prometheus, Telegraf all support UDP
# metric ingestion for this reason.
```

> **Code walkthrough:** UDP `send()` is non-blocking by default. If the OS send buffer is full, it raises EAGAIN which is silently caught and the metric is dropped. If the metrics server is unreachable, the kernel may receive an ICMP port-unreachable which raises an OSError that is similarly discarded. The application never blocks, never slows down, never exhausts threads waiting for metric delivery. Losing 0.1% of metrics in a monitoring system that aggregates over 60-second windows is mathematically negligible. This is why every production metrics protocol (StatsD, DogStatsD, collectd, InfluxDB line protocol over UDP) is UDP-based.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
UDP is connectionless and unreliable - no handshake, no ACKs, no retransmission. Use it when latency or simplicity beats completeness: DNS, streaming, gaming, metrics. Use TCP when every byte must arrive in order. The mental model: if missing one packet makes subsequent packets useless (a paused video stream), use TCP. If missing one packet is minor (a skipped video frame, one failed DNS query that will retry), UDP is fine.

---

**Senior / Staff (5+ years):**
At senior level, understanding UDP's role in modern protocols matters. QUIC uses UDP specifically to avoid OS-TCP's constraints - HOL blocking and connection migration cannot be fixed in kernel TCP because the OS provides a fixed implementation. By building on UDP in user space, QUIC's developers implemented custom per-stream reliability and connection IDs. WebRTC uses UDP (via ICE/DTLS/SRTP) for peer-to-peer real-time communication. Knowing when NOT to use UDP: any protocol requiring ordered delivery without wanting to reimplement sequencing, any protocol where loss is catastrophic (financial transactions), and enterprise environments that block UDP except port 53 (causing HTTP/3 to fall back to HTTP/2).

---

### ⚠️ Common Misconceptions

**Misconception 1: "UDP is always faster than TCP"**

UDP saves the 1.5-RTT handshake per connection. But for bulk data after a warm TCP connection, TCP's throughput matches or exceeds naive UDP senders because TCP has congestion control. An unconstrained UDP sender floods the network, causing drops that require app-level retransmission - potentially worse than TCP. UDP is faster for connection setup and for use cases that don't need retransmission; TCP is fine for bulk streaming on established connections.

---

**Misconception 2: "You can't build reliable applications on UDP"**

Many reliable protocols use UDP: QUIC (HTTP/3), DTLS (TLS for datagrams), game networking protocols, and TFTP all implement reliability at the application layer. UDP is the foundation, not the ceiling. Building on UDP lets you implement exactly the reliability semantics you need - QUIC's per-stream reliability, for example, is something TCP cannot provide.

---

**Misconception 3: "UDP has no security"**

UDP itself has no encryption, but DTLS (Datagram TLS) provides equivalent security to TLS for UDP datagrams. QUIC uses TLS 1.3 integrated into its handshake. WebRTC uses SRTP (Secure RTP) over UDP. UDP protocols are not inherently less secure than TCP - they require the same TLS layer. The misconception comes from comparing bare UDP (no crypto) to TCP+TLS (with crypto), rather than comparing UDP+DTLS to TCP+TLS.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: UDP Receive Buffer Overflow Silently Dropping Packets**

Symptom: application sending UDP metrics or events loses data with no application-level error; downstream shows gaps.

Cause: UDP receive buffer on the server fills faster than the application reads. OS silently drops new incoming datagrams.

Diagnosis:
```bash
# Check UDP receive buffer errors
cat /proc/net/snmp | grep Udp
# RcvbufErrors counter increments per dropped datagram

# Or:
netstat -su | grep "receive buffer errors"

# Increase UDP buffer size
sysctl -w net.core.rmem_max=26214400  # 25MB
sysctl -w net.core.rmem_default=26214400

# Application: set SO_RCVBUF on the socket
import socket
sock = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET,
    socket.SO_RCVBUF, 26214400)
```

> **Code walkthrough:** UDP buffer drops are invisible to the sender (no ACK mechanism). The kernel increments `RcvbufErrors` each time it drops a datagram due to buffer overflow. Monitoring this counter as a metric reveals when the server is overwhelmed. The fix: larger receive buffers (more room before drops) and a faster consuming application. Unlike TCP (which would back-pressure the sender before drops), UDP drops are unilateral and silent. Always monitor `RcvbufErrors` for UDP-based services receiving high-rate data streams.

---

**Failure 2: UDP Fragmentation Causing Silent Packet Loss**

Symptom: UDP-based service works for small messages but silently fails for large ones; no errors reported.

Cause: UDP datagrams exceeding the path MTU are fragmented at Layer 3. Firewalls or routers blocking IP fragments silently drop them. The datagram never reassembles at the destination.

Diagnosis:
```bash
# Test if large UDP datagrams get through
hping3 --udp -p 12345 -d 1472 <destination>
# 1472 bytes payload + 28 bytes header = 1500 (Ethernet MTU)
# If fails but small datagrams succeed: fragmentation issue

# Fix: keep UDP payloads under ~1200 bytes
# (accounts for possible VPN overhead reducing path MTU)
# Or: implement PMTUD in the application
```

> **Code walkthrough:** Fragmentation occurs when a UDP datagram exceeds the path MTU (1500 bytes for standard Ethernet minus 28 bytes of IP+UDP headers = 1472 byte max payload). VPN tunnels reduce this further (often to 1360-1460 bytes). Firewalls commonly block IP fragments as a security measure. DNS over UDP limits responses to 512 bytes (historical) or 1232 bytes (RFC 8906 recommendation) specifically to avoid fragmentation on the global internet. For custom UDP protocols: keep datagrams under 1200 bytes to safely avoid fragmentation on any path including IPv6 (minimum MTU 1280 bytes) and VPN-reduced paths.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | UDP characteristics, use case selection |
| Application | 2 | Protocol selection, metrics pattern |
| Behavioral | 1 | UDP usage story |
| Trade-off | 2 | UDP vs TCP, QUIC on UDP |

---

**[JUNIOR] Q1 - [MECHANISM] What does UDP NOT provide compared to TCP?**

UDP does not provide: (1) Connection establishment - no 3-way handshake; datagrams sent immediately. (2) Reliability - no ACKs; lost datagrams not detected or retransmitted. (3) Ordering - datagrams may arrive out of order; no sequence numbers to sort them. (4) Duplication prevention - the same datagram may arrive twice (rare but possible with some routing loops). (5) Flow control - no receive window; sender can overwhelm receiver. (6) Congestion control - no congestion window; UDP can flood the network, causing collateral damage to other flows. UDP provides: (1) Port-based demultiplexing (same as TCP). (2) Checksum for data integrity. (3) Message boundary preservation - `recv()` on UDP returns one complete datagram (unlike TCP where `recv()` returns an arbitrary byte slice requiring application-level framing). This last point is important: UDP applications naturally get message framing for free; TCP applications must implement length-prefix or delimiter-based framing.

*What separates good from great:* The message boundary preservation (UDP `recv()` always returns exactly one datagram; TCP `recv()` may return partial application messages) - a key behavioral difference that affects application design.

---

**[MID] Q2 - [TRADE-OFF] When would you choose UDP over TCP for a new service?**

Choose UDP when: (1) Request-response with trivial retry: DNS. A query retries in 500ms with no state to manage. (2) Stale data is worse than no data: real-time audio/video, gaming position updates. A retransmitted 200ms-old audio frame causes a stutter worse than silence. (3) Broadcast or multicast needed: UDP supports multiple recipients; TCP is always point-to-point. (4) Fire-and-forget with acceptable loss: metrics (StatsD), syslog, telemetry. (5) Custom transport protocol: QUIC, WebRTC - UDP provides the socket without TCP's kernel-enforced constraints. Stick with TCP when: (1) Ordered, complete delivery is required: database drivers, file transfer, API calls. (2) The application cannot tolerate or work around loss. (3) The network blocks UDP: enterprise firewalls commonly allow TCP 80/443 and UDP 53 only - QUIC falls back to TCP when UDP is blocked. (4) You don't want to reimplement reliability - TCP handles it at no code cost.

*What separates good from great:* The enterprise firewall concern (UDP often blocked except port 53, making QUIC fall back to TCP) and the custom protocol rationale (UDP as the foundation for protocols that need non-TCP delivery semantics).

---

**[SENIOR] Q3 - [MECHANISM] How does QUIC use UDP to improve on TCP?**

QUIC runs over UDP and reimplements TCP's reliability while fixing specific TCP limitations: (1) Head-of-line blocking: HTTP/2 over TCP - a lost packet blocks all streams sharing the connection. QUIC implements per-stream delivery: a lost QUIC packet blocks only its stream ID. Other streams deliver immediately. (2) Faster establishment: QUIC combines transport and TLS 1.3 into 1 RTT (first connection). Resumed: 0-RTT. TCP+TLS 1.3 = 2.5 RTT. (3) Connection migration: QUIC identifies connections by Connection ID (64-bit opaque value), not the 4-tuple (source IP, source port, dest IP, dest port). Mobile user switches Wi-Fi to cellular: new IP, same Connection ID - QUIC session persists. TCP requires reconnection. (4) User-space implementation: no kernel changes needed to deploy new congestion control algorithms or fix bugs - faster iteration than waiting for OS kernel patches. Why UDP and not a new protocol? The internet has firewalls, NATs, and middleboxes that understand TCP/UDP/ICMP. A new Layer 4 protocol would be blocked by most firewalls. UDP port 443 is typically allowed (looks like DNS-over-HTTPS traffic), enabling QUIC to traverse existing infrastructure.

*What separates good from great:* The middlebox/firewall reason for choosing UDP over a new protocol (firewalls would block unknown protocols; UDP 443 passes most), and the user-space congestion control advantage.

---

**[SENIOR] Q4 - [APPLICATION] How would you implement selective reliability over UDP for a game?**

Game positions update 20-30 times/second. Old positions are useless. But "player fired" events must not be lost. Implementation: (1) Unreliable channel (positions): timestamp + sequence number per datagram. Receiver: discard if seq <= last_received. Latest state wins. No ACKs. (2) Reliable channel (events): sender assigns increasing message IDs to events. Maintains unACK'd queue. Retransmits after 2*measured_RTT (not TCP's 200ms RTO). Max 3 retries, then disconnect. Receiver: buffer out-of-order, ACK received, deliver in order. (3) Piggybacked ACKs: append a bitmap of recent reliable message IDs in every outgoing unreliable datagram. "Last 32 received reliable IDs" in a 32-bit field. No dedicated ACK packets - reduces overhead. (4) Jitter buffer: buffer 3 frames (~100ms at 30fps) before rendering, smoothing over network jitter. (5) Encryption: DTLS or per-packet ChaCha20-Poly1305 with per-packet nonces. (6) MTU: keep max datagram <1200 bytes. This is essentially what Valve's GameNetworkingSockets library implements. Prefer it over rolling your own.

*What separates good from great:* The piggybacked ACK technique (encoding ACKs in outgoing data packets to avoid dedicated ACK round trips), and the recommendation to use existing libraries.

---

**[SENIOR] Q5 - [BEHAVIORAL] Give a production example where UDP was the right choice.**

At a monitoring company, we collected system metrics (CPU, memory, I/O) from 10,000 servers every 5 seconds. Initial TCP implementation: each agent maintained a persistent TCP connection to the aggregation cluster. Problems: (1) 10,000 persistent TCP connections consumed significant RAM on the aggregation server (each TCP socket has send/receive buffers, socket struct - ~150KB total per connection = 1.5GB just for connection state). (2) Aggregation server restarts caused thundering herd: all 10,000 agents reconnected simultaneously. The TCP accept queue (default 128) overflowed. Clients saw timeouts, retried immediately, making it worse. Recovery took 60+ seconds. (3) Network partition: half-open connections held for 2 hours before keepalive detected them. Server accumulated ghost connections. UDP rewrite: agents fire UDP datagrams to the aggregation cluster (3 nodes with consistent hashing). No connection state, no reconnection on restart, no keepalive needed. Server restart: agents' next datagrams simply hit the new server. Recovery time: instantaneous. Acceptable metric loss: 5-second samples, aggregated to 1-minute windows. Statistically insignificant. The rewrite eliminated three separate failure modes by eliminating connection state entirely.

*What separates good from great:* The thundering herd accept queue overflow on restart (a specific TCP failure mode that UDP eliminates), and the memory arithmetic (10K connections x 150KB = 1.5GB just for TCP state).

---

**[STAFF] Q6 - [DESIGN] Design a low-latency multiplayer game networking stack using UDP.**

Requirements: position updates 30/s per player, game events (reliable), state snapshots (reliable). Architecture: Transport: raw UDP sockets, receive buffer 1MB+ for burst absorption. Message format: 2-byte type + 4-byte sequence + 2-byte length + payload. Channels: (1) Unreliable (positions): sequence number, no tracking. Receiver accepts if seq > last_received, discards older. (2) Reliable ordered (events): sender tracks unACK'd messages in a ring buffer, resends at 2*RTT_estimate, 3 retries then disconnect. Receiver buffers out-of-order, delivers in-order. ACK: 32-bit bitmap piggybacked on outgoing unreliable packets (bit N set = received message ID N). No dedicated ACK packets. RTT estimation: EWMA of (receive_timestamp - send_timestamp) from ACK round trips. Congestion control: track loss rate over 100 packets. If >10%: halve position update rate. Encryption: ChaCha20-Poly1305 with per-packet 8-byte nonce (monotonically increasing, replay protection). MTU: enforce max payload 1100 bytes (safe for IPv6 + VPN). Jitter buffer: 100ms smoothing window (3 frames at 30fps). Anti-cheat: server-side authoritative simulation; client sends inputs, not positions. Alternatives: use Valve's GameNetworkingSockets or ENet instead of rolling this from scratch.

*What separates good from great:* The server-authoritative simulation note (clients send inputs not positions, which is the anti-cheat design - not just a networking concern), and the recommendation to use existing libraries.

---

**[STAFF] Q7 - [TRADE-OFF] Compare TCP, UDP, and QUIC for an internal microservices RPC framework.**

For internal microservice RPC: TCP-based (HTTP/2 gRPC) - the correct default. HTTP/2 multiplexes request/response and streaming over one connection. gRPC provides schema (protobuf), code generation, and retries. TLS for mTLS. Works everywhere (no UDP blocking risk). Latency: 2.5 RTT first connection, near-zero per request on warm pooled connections. QUIC-based (HTTP/3 gRPC) - better for cross-region or edge-to-origin paths. 1-RTT first connection, 0-RTT resume, per-stream loss isolation reduces HOL blocking on high-volume streaming RPCs. Overhead: user-space QUIC (gRPC-QUIC via quiche, ngtcp2) adds CPU vs kernel TCP. Immaturity: fewer production deployments for internal RPC. UDP custom protocol - only justified if gRPC overhead is measured and you require sub-0.5ms p99 latency at very high RPS (trading systems, game backends). Requires implementing security, framing, and reliability. Recommendation: start with gRPC over HTTP/2. Measure actual latency and throughput. If cross-region streaming calls show HOL blocking, migrate those specific endpoints to QUIC. Custom UDP only for extreme latency requirements with measured justification.

*What separates good from great:* The selective migration strategy (move specific high-volume streaming endpoints to QUIC, not the entire service), and the requirement for measured justification before custom UDP.

---

### ⚖️ Comparison Table

| Characteristic | TCP | UDP | QUIC |
|---|---|---|---|
| Connection setup | 1.5 RTT + TLS | None | 1 RTT (includes TLS) |
| Reliability | Built-in | None | Per-stream |
| Ordering | Global stream order | None | Per-stream order |
| HOL blocking | Yes (per connection) | No | No (per stream) |
| Flow/congestion control | Yes | No | Yes |
| Connection migration | No | N/A | Yes (Connection ID) |
| Middlebox compatibility | Universal | Good (port 53 always) | Good (UDP 443) |
| Use cases | Reliable everything | DNS, gaming, RTP | HTTP/3, mobile |

---

### 🏛️ System Design

*(Omit: ★☆☆ difficulty.)*

---

### 📊 Diagram

*(See Concept Explanation above; the UDP use-case table and walkthrough appear in that section.)*

---
---

# IP Addressing, Subnets, and CIDR

**Interview Weight:** Moderate-High - IP addressing is tested in DevOps/SRE roles and increasingly for backend engineers working with cloud VPCs, security groups, and network configuration.

---

## Quick Reference

**One-line definition:** IP addressing assigns unique 32-bit (IPv4) identifiers to network interfaces; CIDR (Classless Inter-Domain Routing) notation (e.g., 10.0.0.0/24) specifies both the network prefix and subnet size; subnets group IPs using a prefix mask to enable hierarchical routing and network segmentation.

**Difficulty:** ★☆☆ | **Asked at:** All levels | **Seniority:** Junior through Senior

---

### 🎯 Model Answer

**30 seconds:**
IPv4 addresses are 32 bits written as four octets (192.168.1.5). CIDR notation 192.168.1.0/24 means the first 24 bits (192.168.1) are the network; the last 8 bits (0-255) identify hosts. A /24 has 254 usable IPs (256 minus network address and broadcast). Private ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 are not routed on the internet. In cloud work: VPCs have a CIDR block (10.0.0.0/16); subnets carve that space; security group rules use CIDR to define allowed source IPs.

**3 minutes (Senior):**
CIDR replaced classful addressing in 1993. Classful wasted space (Class A gave one org 16 million IPs). CIDR allows any prefix length for efficient allocation. Subnetting math: /24 = 256 addresses, 254 usable. /16 = 65,536. /30 = 4 addresses (2 usable) for point-to-point links. /32 = one host. In AWS: VPC is typically /16. Each AZ gets /20 subnets (4,096 IPs). Public subnets (with internet gateway) for load balancers; private subnets for databases and backend services. Security groups control which CIDRs reach which ports. Route tables specify next hops per CIDR destination. Engineers configure security group rules (allow 10.0.0.0/8 on 5432 for database access), VPC CIDR blocks, and NAT gateway routes constantly in cloud infrastructure work.

**Framework:** ADDRESS BITS → CIDR PREFIX → NETWORK/HOST SPLIT → SUBNET DESIGN → CLOUD APPLICATION

**Blank Mind Recovery:**

**(1) Restate:** "IP addressing and CIDR - how do we assign addresses to machines and organize them into networks?"

**(2) First principles:** "We have 4 billion IPv4 addresses. We need hierarchy (like postal codes) so routers aggregate ranges into one route - 10.0.0.0/8 covers 16 million IPs with one routing entry."

**(3) Bridge:** "Like apartment numbering: building address is the network (192.168.1), apartment number is the host (.5). The CIDR prefix length tells you how many digits are the building number and how many are the apartment number."

---

### 📘 Concept Explanation

**What it is:**
IPv4 uses 32-bit addresses. Subnets group IPs using a prefix mask. CIDR notation (10.0.0.0/24) combines the network address and prefix length. This replaced classful addressing (Class A/B/C) in 1993, enabling efficient IP allocation.

**The problem it solves:**
Without subnets, every router would need individual routes to billions of IPs. Subnets enable hierarchical aggregation: one route for 10.0.0.0/8 covers 16 million addresses.

**How it works:**

```
IPv4 address (32 bits):
  192.168.1.5
  = 11000000.10101000.00000001.00000101
    ^octet1  ^octet2  ^octet3  ^octet4

CIDR: 192.168.1.0/24
  /24 prefix = first 24 bits are the NETWORK
  remaining 8 bits = HOST space (0-255)

  Network address:  192.168.1.0   (all host bits = 0)
  Broadcast:        192.168.1.255 (all host bits = 1)
  Usable range:     192.168.1.1 - 192.168.1.254
  Usable count:     256 - 2 = 254

Subnet size quick reference:
  /8  = 16,777,216 IPs (10.0.0.0/8 = all 10.x.x.x)
  /16 = 65,536 IPs    (AWS VPC default)
  /20 = 4,096 IPs     (AWS subnet per AZ)
  /24 = 256 IPs       (small department subnet)
  /28 = 16 IPs        (14 usable)
  /30 = 4 IPs         (2 usable, point-to-point)
  /32 = 1 IP          (single host, security rule)

Private (RFC 1918) ranges:
  10.0.0.0/8        (16M IPs, enterprise/cloud)
  172.16.0.0/12     (1M IPs, Docker default: 172.17.x.x)
  192.168.0.0/16    (65K IPs, home routers)
```

> **Diagram walkthrough:** The bit-level breakdown shows how the /24 prefix splits 32 bits into 24 network bits (fixed for all hosts in the subnet) and 8 host bits (varying 0-255). Network address (all zeros) and broadcast (all ones) are reserved, leaving 254 usable. The subnet size table shows the exponential relationship - each extra prefix bit halves the number of hosts. The private ranges are the three RFC 1918 blocks not routed on the public internet; packets from private IPs are dropped at internet routers, allowing any organization to use these ranges internally without conflict.

**CIDR in cloud infrastructure:**

```
AWS VPC design (10.0.0.0/16):
  VPC:              10.0.0.0/16  (65,534 usable)
  us-east-1a public:  10.0.0.0/20  (4,094 IPs)
  us-east-1a private: 10.0.16.0/20 (4,094 IPs)
  us-east-1b public:  10.0.32.0/20 (4,094 IPs)
  us-east-1b private: 10.0.48.0/20 (4,094 IPs)
  Reserved:           10.0.64.0/18 (future AZs)

Security group rule examples:
  Inbound 5432 from 10.0.0.0/16  -> whole VPC
  Inbound 443  from 0.0.0.0/0    -> internet
  Inbound 5432 from sg-app-tier   -> SG reference

Route table (private subnet):
  Destination     Target
  10.0.0.0/16     local       (VPC internal)
  0.0.0.0/0       nat-gateway (internet via NAT)
```

> **Diagram walkthrough:** The VPC design shows hierarchical CIDR allocation: /16 VPC carved into /20 subnets per AZ per tier. Public subnets have internet gateway routes (bidirectional internet); private subnets route internet-bound traffic through NAT (outbound only, no inbound internet connections). Security group rules using CIDR (`10.0.0.0/16`) allow any host in the VPC, while security group ID references (`sg-app-tier`) allow only instances in that group regardless of IP. The route table's longest-prefix-match rule: `10.0.0.0/16 -> local` is more specific than `0.0.0.0/0 -> NAT`, so intra-VPC traffic routes locally and only truly external traffic goes to NAT. The senior insight: plan VPC CIDRs at organization level before creating any VPCs - overlapping CIDRs prevent VPC peering and are painful to change.

---

### 💻 Code Example

**BAD: Hardcoding individual /32 IPs in security rules**

```python
# BAD: Individual IPs in security group rules.
# Must update manually for every new/replaced instance.
# Autoscaling makes this unmanageable.

import boto3
ec2 = boto3.client('ec2')

# Manually adding each backend instance IP
ec2.authorize_security_group_ingress(
    GroupId='sg-db-postgres',
    IpPermissions=[{
        'IpProtocol': 'tcp', 'FromPort': 5432, 'ToPort': 5432,
        'IpRanges': [
            {'CidrIp': '10.0.16.5/32'},  # instance 1
            {'CidrIp': '10.0.16.6/32'},  # instance 2
            # New autoscaling instance: forget to add it?
            # Database is inaccessible from new instances.
        ]
    }]
)
```

> **Code walkthrough:** /32 rules tie security to specific IPs. When autoscaling launches a new instance with a new IP, it's excluded until someone manually adds the /32 rule. In practice, this creates intermittent failures during scaling events - some requests hit new instances (blocked) and some hit old ones (allowed). The configuration is also expensive to audit: 100 instances means 100 rules, making it hard to identify whether an IP is still valid or was from a terminated instance.

**GOOD: CIDR range or security group reference**

```python
# GOOD: CIDR range covers entire subnet.
# All current and future instances in the subnet
# are covered by one rule.

import boto3
ec2 = boto3.client('ec2')

# Option 1: CIDR range - covers all IPs in subnet
ec2.authorize_security_group_ingress(
    GroupId='sg-db-postgres',
    IpPermissions=[{
        'IpProtocol': 'tcp', 'FromPort': 5432, 'ToPort': 5432,
        'IpRanges': [{
            'CidrIp': '10.0.16.0/20',
            'Description': 'App private subnet (AZ-a)'
        }]
    }]
)

# Option 2: Security group reference (AWS-preferred).
# Only instances WITH sg-app-tier can reach DB.
# Works regardless of IP. Handles autoscaling.
ec2.authorize_security_group_ingress(
    GroupId='sg-db-postgres',
    IpPermissions=[{
        'IpProtocol': 'tcp', 'FromPort': 5432, 'ToPort': 5432,
        'UserIdGroupPairs': [{
            'GroupId': 'sg-app-tier',
            'Description': 'App tier security group'
        }]
    }]
)
```

> **Code walkthrough:** CIDR range `10.0.16.0/20` covers 4,094 IPs - all current and future instances in the private subnet are automatically covered. No manual updates needed when autoscaling adds instances. Security group references go further: identity is the group membership, not the IP. An autoscaled instance gets `sg-app-tier` attached; it can immediately reach the database. A misconfigured instance that doesn't have `sg-app-tier` cannot reach the database even if it's in the same subnet. Security group references provide least-privilege access control at the application layer, not at the network layer. In Terraform or CloudFormation, both patterns are idiomatic - prefer security group references where available.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
IPv4 addresses are 32 bits as four 0-255 numbers. CIDR /24 means 24 network bits, 8 host bits, 254 usable hosts. Private ranges (10.x.x.x, 172.16-31.x.x, 192.168.x.x) are not internet-routable. In cloud: VPCs have a CIDR block; subnets carve it up; security groups use CIDR to define access. The common operations: calculate subnet size (2^(32-prefix) addresses, minus 2 for network/broadcast), determine if an IP is in a subnet (AND the IP with the mask, compare to network address), and choose appropriate CIDR blocks for new VPCs.

---

**Senior / Staff (5+ years):**
At senior level, IP addressing informs multi-account architecture. VPC CIDR block planning is critical and difficult to change: use /16 per VPC account for room to grow. Across accounts, use non-overlapping /16 blocks from a central IP plan (10.0.0.0/16, 10.1.0.0/16, etc.) because VPC peering requires non-overlapping CIDRs. For IPv6: dual-stack VPCs give each instance both IPv4 and IPv6; IPv6 subnets are always /64; no NAT needed (IPv6 has enough space for every device to have a public address). Security consideration: IP-based security rules (CIDR) are weaker than identity-based rules (security group references, IAM-based access) because IPs can be spoofed on internal networks by compromised instances. Prefer security group references for internal service-to-service access.

---

### ⚠️ Common Misconceptions

**Misconception 1: "192.168.x.x is the only private IP range"**

Three RFC 1918 private ranges exist: 10.0.0.0/8 (16M IPs, used by most enterprises and cloud VPCs), 172.16.0.0/12 (1M IPs, used by Docker's default bridge network: 172.17.0.0/16), and 192.168.0.0/16 (65K IPs, used by home routers). Engineers who don't know 10.0.0.0/8 are confused when cloud instances show 10.x.x.x addresses.

---

**Misconception 2: "/24 and 'Class C' are the same thing"**

In the old classful system, Class C was exactly /24. CIDR allows any prefix length. /23 spans two adjacent /24s (512 addresses). /25 is half a /24 (128 addresses). The prefix can be any length from /0 (all IPs) to /32 (one IP). Saying "I need a Class C" usually means /24 is fine, but understanding CIDR allows requesting appropriately-sized blocks (/22 for 1,000 hosts, /26 for 60 hosts).

---

**Misconception 3: "Longer prefix always wins in routing"**

Longest prefix match wins in IP routing - /24 beats /16 for a packet destined to an IP matching both. But within the same prefix length, routing metrics (BGP attributes, OSPF cost, administrative distance) determine the winner. In AWS route tables: more specific routes take precedence. If you have 10.0.0.0/16 via VPC peering and 10.0.1.0/24 via Transit Gateway, traffic to 10.0.1.x goes to Transit Gateway (more specific), and all other 10.0.x.x traffic goes to VPC peering.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Overlapping VPC CIDRs Preventing Peering**

Symptom: VPC peering creation fails with "CIDR block conflict"; or peered VPCs cannot communicate despite correct routing tables.

Cause: VPC peering requires non-overlapping CIDRs. If both VPCs use 10.0.0.0/16, peering is rejected.

Diagnosis:
```bash
# Check all VPC CIDR blocks in an account
aws ec2 describe-vpcs \
  --query 'Vpcs[].{ID:VpcId,CIDR:CidrBlock}' \
  --output table

# Python: check for overlaps before creating VPC
import ipaddress

def cidrs_overlap(a, b):
    return ipaddress.ip_network(a, strict=False).overlaps(
           ipaddress.ip_network(b, strict=False))

# Prevention: allocate from a global IP plan
# Account 1: 10.0.0.0/16
# Account 2: 10.1.0.0/16
# Account 3: 10.2.0.0/16
# Use AWS IPAM (IP Address Manager) for automation
```

> **Code walkthrough:** AWS IPAM (IP Address Management) automates the non-overlap guarantee by maintaining a central pool and allocating CIDRs from it. Without IPAM, teams create VPCs independently and inevitably choose the same CIDR (10.0.0.0/16 is the most common default). The Python `ipaddress.ip_network.overlaps()` check can be run in a VPC provisioning Lambda or Terraform module as a guard. When overlap is already in place, options are: re-CIDR one VPC (requires destroying and recreating), use Transit Gateway with NAT (complex), or use AWS PrivateLink (service-specific, not network-level).

---

**Failure 2: Subnet IP Exhaustion in Autoscaling**

Symptom: new EC2 instances fail to launch with "not enough free IPs in subnet"; autoscaling events fail silently; health checks fail on new instances.

Cause: subnet's IP range is exhausted. AWS reserves 5 IPs per subnet (network address, VPC router, DNS, future use, broadcast). A /24 subnet has 251 usable IPs (256-5), not 254.

Diagnosis:
```bash
# Check available IPs per subnet
aws ec2 describe-subnets \
  --query 'Subnets[].{ID:SubnetId,
                      CIDR:CidrBlock,
                      Available:AvailableIpAddressCount}' \
  --output table

# Alert: CloudWatch metric SubnetAvailableIPs
# Alert when < 20% of subnet capacity remaining

# Fix: add a secondary CIDR to the VPC and
# create new subnets in the same AZ
aws ec2 associate-vpc-cidr-block \
  --vpc-id vpc-12345 \
  --cidr-block 10.1.0.0/16
```

> **Code walkthrough:** AWS reserves 5 IPs per subnet (not 2 like standard subnets), so a /24 has 251 usable IPs, a /28 has only 11. In production autoscaling environments, subnet IP exhaustion is a silent failure - new instances fail to acquire IPs during launch, and the failure is reported in EC2 launch logs, not in application logs. The CloudWatch `SubnetAvailableIPs` metric (built-in) enables proactive alerting. Adding a secondary VPC CIDR block and creating new subnets in existing AZs is the fix that doesn't require VPC recreation.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | CIDR notation, subnet calculation |
| Application | 2 | VPC design, security group rules |
| Behavioral | 1 | Production IP addressing experience |
| Design | 2 | Multi-account IP planning, IPv6 |

---

**[JUNIOR] Q1 - [MECHANISM] What does 192.168.1.0/24 mean and how many hosts can it have?**

The /24 prefix means the first 24 bits of the 32-bit IPv4 address are the network portion; the remaining 8 bits are the host portion. 192.168.1 is the network (three octets = 24 bits, all fixed). The last octet (0-255) identifies hosts in this subnet. 256 total addresses. Reserved: 192.168.1.0 is the network address (all host bits zero) and 192.168.1.255 is the broadcast address (all host bits one). Usable: 256 - 2 = 254 (192.168.1.1 through 192.168.1.254). The equivalent subnet mask is 255.255.255.0: bitwise AND of any IP in the range with 255.255.255.0 gives the network address 192.168.1.0. Quick rule: for prefix /N, number of addresses = 2^(32-N). For /24: 2^8 = 256. For /20: 2^12 = 4096. For /16: 2^16 = 65536.

*What separates good from great:* The formula 2^(32-N) for calculating subnet size, the subnet mask equivalence (/24 = 255.255.255.0), and noting that AWS reserves 5 addresses per subnet (not 2) for cloud-specific infrastructure.

---

**[MID] Q2 - [APPLICATION] Design the IP addressing scheme for a 3-tier AWS application.**

VPC CIDR: 10.0.0.0/16 (65,534 usable IPs, room for future subnets). Three availability zones, three tiers each: AZ-a (10.0.0.0/18 reserved): web public 10.0.0.0/24 (254 IPs for ALB ENIs), app private 10.0.4.0/22 (1,022 IPs for application instances), DB private 10.0.8.0/24 (254 IPs for RDS instances). AZ-b (10.0.64.0/18): same pattern starting at .64.x. AZ-c (10.0.128.0/18): starting at .128.x. Reserved: 10.0.192.0/18 for future use. Security groups: web-sg allows 443 from 0.0.0.0/0; app-sg allows 8080 from web-sg ID only; db-sg allows 5432 from app-sg ID only. Route tables: public subnets route 0.0.0.0/0 to Internet Gateway (bidirectional); private subnets route 0.0.0.0/0 to NAT Gateway (outbound only). NAT Gateway in each public subnet per AZ for AZ-local redundancy. The DB tier has no internet route at all - no NAT, no IGW - providing defense in depth.

*What separates good from great:* Using security group ID references rather than CIDRs for inter-tier access (works during autoscaling), the DB tier having no internet route (true network isolation, not just security group filtering), and the per-AZ NAT Gateway placement.

---

**[SENIOR] Q3 - [MECHANISM] Explain NAT and why it's necessary for private IP addresses.**

NAT (Network Address Translation) allows devices with private (RFC 1918) IPs to communicate with the internet. Private IPs are not globally routable: a packet from 10.0.1.5 is dropped at the first internet router. NAT mechanism: outgoing packet from 10.0.1.5:34567 to 93.184.216.34:443 arrives at the NAT gateway. NAT gateway replaces source IP:port with its public IP:port (52.10.1.5:45000) and records the mapping. The server receives the packet as if from 52.10.1.5. Server responds to 52.10.1.5:45000. NAT gateway receives the response, looks up the mapping, rewrites destination to 10.0.1.5:34567, and forwards internally. The NAT table is the state: for each mapping (public IP:port ↔ private IP:port), the NAT device holds state for the connection's duration. NAT limitation: inbound connections require no prior mapping. A client on the internet cannot initiate a connection to 10.0.1.5 through NAT - there's no mapping in the NAT table to translate to. This is why internet-facing services (web servers) need public IPs or an internet-facing load balancer with a public IP; NAT only allows outbound-initiated connections.

*What separates good from great:* The NAT table as stateful connection tracking (each TCP connection has a 5-tuple → 5-tuple mapping in the table), and the explicit inbound connection limitation with the solution (public load balancer in front of NAT'd private instances).

---

**[SENIOR] Q4 - [APPLICATION] How do you calculate if two CIDR blocks overlap?**

Two CIDRs overlap if any IP address appears in both ranges. The algorithm: for CIDRs A/a and B/b, they overlap if the start of one range falls within the other range, or if one range entirely contains the other. Python implementation:

```python
import ipaddress

def cidrs_overlap(cidr1: str, cidr2: str) -> bool:
    net1 = ipaddress.ip_network(cidr1, strict=False)
    net2 = ipaddress.ip_network(cidr2, strict=False)
    return net1.overlaps(net2)

# Test cases:
print(cidrs_overlap("10.0.0.0/16", "10.0.1.0/24"))  # True
print(cidrs_overlap("10.0.0.0/24", "10.0.1.0/24"))  # False
print(cidrs_overlap("10.0.0.0/8",  "10.50.0.0/16")) # True
print(cidrs_overlap("192.168.0.0/24", "10.0.0.0/8"))# False
```

> **Code walkthrough:** This helper uses Python's `ipaddress` standard library to compute CIDR overlap. WHAT IT SHOWS: the `ip_network.overlaps()` method returns True when any IP is shared between two subnets. KEY MECHANISM: Python converts both CIDR strings to network objects (start address + prefix length), then checks whether their address ranges intersect. WHY IT MATTERS: overlapping subnets in a VPC cause routing ambiguity - packets for an IP matching two subnets go to the more-specific route, silently bypassing intended security group rules. WHAT BREAKS: VPC peering fails at creation time if CIDRs overlap; AWS rejects the peering request. TAKEAWAY: validate CIDR overlap in your IaC before apply to prevent deployment failures.

Manual check: CIDR A/a overlaps with B/b if any of these conditions hold: B's network address is within A's range, OR A's network address is within B's range. For routing: subnets in the same VPC cannot overlap. For VPC peering: VPCs cannot overlap. Build this check into Terraform modules and VPC provisioning automation.

*What separates good from great:* The Python `ipaddress.ip_network.overlaps()` method as the standard library solution, and the use case in provisioning automation.

---

**[SENIOR] Q5 - [BEHAVIORAL] Describe a production incident related to IP addressing or subnets.**

At a fintech company with ~800 EC2 instances, the application subnet (10.0.4.0/22, 1,022 IPs, but AWS reserves 5 = 1,017 usable) started causing intermittent launch failures. About 2% of API calls failed with connection errors during business hours. Investigation: the failures correlated exactly with autoscaling scale-out events. New instances were failing to launch - EC2 console showed "InsufficientInstanceCapacity" and then "NetworkInterfaceNotFoundException" - the subnet had no available IPs. Root cause: 800 instances + load balancer ENIs + VPC endpoint ENIs + NAT gateway ENIs = ~1,010 consumed IPs. The subnet was 99% full with no monitoring alert. Fix: immediately created a new /22 subnet in the same AZ (10.0.16.0/22) and added it to the autoscaling group's subnet list. Autoscaling now uses both subnets, effectively doubling capacity. Long-term: added CloudWatch alarm on `SubnetAvailableIPs < 200` with a 4-hour alert window. Lesson: subnet IP exhaustion is silent - AWS doesn't alert by default when a subnet is nearly full; instances simply fail to launch.

*What separates good from great:* The ENI consumers beyond application instances (load balancers, VPC endpoints, NAT gateways consume subnet IPs), and the monitoring gap (no built-in AWS alert for subnet IP exhaustion).

---

**[STAFF] Q6 - [DESIGN] Design an IP addressing scheme for a 50-account AWS organization.**

Goal: non-overlapping CIDRs across all accounts and regions to enable any-to-any VPC peering or Transit Gateway mesh. Address plan: allocate one /16 per account from 10.0.0.0/8 (which has 256 /16 blocks): Account 1 = 10.0.0.0/16, Account 2 = 10.1.0.0/16, ..., Account 50 = 10.49.0.0/16. Reserve 10.50-255.0.0/16 for future accounts. Within each /16, allocate by region: first /18 for us-east-1 (10.X.0.0/18), second for us-west-2 (10.X.64.0/18), third for eu-west-1 (10.X.128.0/18), fourth reserved. Within each /18 region block, allocate /20 per AZ (6 AZs maximum fit in /18). Governance: deploy AWS IPAM with organizational scope. IPAM pools map to this hierarchy (org pool → account pool → region pool → AZ/subnet pool). All VPC creations via Terraform use IPAM data sources to allocate the next available CIDR from the correct pool. Compliance: AWS Config rule `vpc-sg-open-only-to-authorized-ports` plus custom rule checking VPC CIDRs match IPAM allocations.

*What separates good from great:* The AWS IPAM integration for automated allocation (not manual tracking), and the Config rule for compliance enforcement - the plan only works if it's enforced through automation.

---

**[STAFF] Q7 - [DESIGN] How does IPv6 change IP addressing, and what does an engineer need to know?**

IPv6 uses 128-bit addresses (vs IPv4's 32 bits), written as 8 groups of 4 hex digits: 2001:db8:0:1::1. Key differences: (1) No NAT required: IPv6 has 2^128 addresses - every device gets a globally unique address. NAT was invented because IPv4 address space ran out. IPv6 eliminates scarcity. (2) SLAAC (Stateless Address Autoconfiguration): devices auto-assign IPv6 addresses using the router's advertised prefix + their MAC address (EUI-64) or a privacy-random suffix. No DHCP required (though DHCPv6 exists). (3) Subnet prefix: all user-facing subnets are /64 (2^64 addresses). This seems wasteful but IPv6's address space is designed for this. /128 is a single host. (4) Link-local addresses (fe80::/10): automatically assigned to every interface for same-link communication. Replaces ARP with NDP (Neighbor Discovery Protocol). (5) No broadcast: IPv6 uses multicast for neighbor discovery instead of broadcast, reducing network noise. For cloud engineers: AWS dual-stack VPCs assign both IPv4 and IPv6. IPv6 subnets are /56 per VPC, /64 per subnet. Security groups apply identically. IPv6 traffic uses Internet Gateway directly (no NAT). Practical implication: accept connections from IPv6-only clients (growing on mobile networks) by enabling dual-stack on your load balancers and endpoints.

*What separates good from great:* The NAT elimination as the architectural consequence of IPv6 (not just a size difference), and SLAAC as stateless autoconfiguration that eliminates DHCP for most deployments.

---

### ⚖️ Comparison Table

| Subnet Size | Total IPs | Usable (standard) | Usable (AWS) | Common Use |
|---|---|---|---|---|
| /8 | 16,777,216 | 16,777,214 | 16,777,211 | Enterprise org block |
| /16 | 65,536 | 65,534 | 65,531 | AWS VPC |
| /20 | 4,096 | 4,094 | 4,091 | AWS subnet per AZ |
| /24 | 256 | 254 | 251 | Small team subnet |
| /28 | 16 | 14 | 11 | Small service subnet |
| /30 | 4 | 2 | N/A | Point-to-point link |
| /32 | 1 | 1 | N/A | Single host or SG rule |

---

### 🏛️ System Design

*(Omit: ★☆☆ difficulty.)*

---

### 📊 Diagram

*(See Concept Explanation above; the CIDR bit-mask diagram and subnet walkthrough appear in that section.)*
