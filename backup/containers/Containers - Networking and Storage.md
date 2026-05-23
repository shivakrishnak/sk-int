---
layout: default
title: "Containers - Networking and Storage"
parent: "Containers"
grand_parent: "Interview Mastery"
nav_order: 3
permalink: /interview/containers/networking-and-storage/
topic: Containers
subtopic: Networking and Storage
keywords:
  - Container Networking
  - Volume Mounts
  - Docker Networking Modes
  - Port Mapping
  - DNS in Containers
  - Docker Compose Networking
difficulty_range: medium-hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Container Networking](#container-networking)
- [Volume Mounts](#volume-mounts)
- [Docker Networking Modes](#docker-networking-modes)
- [Port Mapping](#port-mapping)
- [DNS in Containers](#dns-in-containers)
- [Docker Compose Networking](#docker-compose-networking)

# Container Networking

**TL;DR** - Container networking connects isolated containers to each other and the outside world using virtual network interfaces, bridges, and network namespaces - providing connectivity while maintaining isolation.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Containers have isolated network namespaces (by design). Without networking, they can't talk to each other, the host, or the internet. Your microservice architecture is useless if services can't communicate.

**THE INVENTION MOMENT:**
"This is exactly why container networking was created."

**EVOLUTION:**
Host networking (no isolation) -> Docker bridge networks (2013) -> Overlay networks for Swarm (2015) -> CNI standard for Kubernetes (2016) -> Service mesh (Istio/Linkerd, 2017+) -> eBPF-based networking (Cilium, 2020+).
---

### 📘 Textbook Definition

Container networking provides connectivity between containers using virtual networking constructs - virtual ethernet pairs (veth), bridges, NAT rules, and overlay networks - while preserving the isolation benefits of network namespaces.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Container networking creates virtual networks so isolated containers can communicate.

**One analogy:**

> Container networking is like a phone system in an office building. Each office (container) has its own phone number (IP). The building's PBX (bridge network) routes internal calls. External calls go through the switchboard (NAT/port mapping) to the outside world.

**One insight:**
Every container gets its own network namespace with its own IP address, routing table, and port space. Two containers can both listen on port 8080 without conflict because they're in different namespaces. The bridge network or port mapping determines how traffic reaches them.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Each container has its own network namespace (isolated network stack)
2. Virtual ethernet pairs (veth) connect container namespace to bridge
3. Bridge acts as Layer 2 switch for container-to-container communication
4. NAT/iptables handle container-to-external communication

**DERIVED DESIGN:**
Isolation provides security (containers can't sniff each other's traffic by default). Bridges provide discovery (containers on same bridge can communicate). Port mapping provides external access (host port -> container port).

**THE TRADE-OFFS:**
**Gain:** Network isolation, port space independence, software-defined networking
**Cost:** Overhead (veth + bridge + NAT), complexity (debugging requires understanding virtual networking), performance (vs host networking)
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Docker Bridge Networking:

Host Network Stack
+------------------------------------------+
|  eth0: 192.168.1.100                     |
|                                          |
|  docker0 bridge: 172.17.0.1             |
|  +----------+  +----------+             |
|  | veth-a   |  | veth-b   |             |
|  +----+-----+  +----+-----+             |
|       |              |                   |
+-------+--------------+------------------+
        |              |
   +----+-----+  +----+-----+
   | Container A | | Container B |
   | eth0:      | | eth0:      |
   | 172.17.0.2 | | 172.17.0.3 |
   | Port: 8080 | | Port: 8080 |
   +------------+ +------------+

Traffic flow (A -> B):
  A sends to 172.17.0.3:8080
  -> through veth-a to bridge
  -> bridge forwards to veth-b
  -> arrives at B's eth0

Traffic flow (External -> A via port mapping):
  Client sends to 192.168.1.100:80
  -> iptables DNAT: 192.168.1.100:80 -> 172.17.0.2:8080
  -> through docker0 bridge to veth-a
  -> arrives at A's eth0:8080
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
Container starts -> Docker creates veth pair -> one end in container namespace, one on bridge <- YOU ARE HERE -> container gets IP from bridge subnet -> iptables rules added for port mapping -> container can communicate

**FAILURE PATH:**
Container can't reach external network -> check iptables NAT rules (`iptables -t nat -L`) -> check IP forwarding (`sysctl net.ipv4.ip_forward`) -> check bridge connectivity (`docker network inspect`)

**WHAT CHANGES AT SCALE:**
Single-host bridge works for Docker Compose. Multi-host requires overlay networks (VXLAN) or CNI plugins. At 1000+ pods in K8s, eBPF (Cilium) replaces iptables for performance (O(1) vs O(n) rule lookup). Service mesh adds L7 observability and mTLS.
---

### 💻 Code Example

```bash
# Create a custom bridge network
docker network create --subnet=10.0.0.0/24 mynet

# Run containers on custom network
docker run -d --name api --network mynet myapp
docker run -d --name db --network mynet postgres

# Containers reach each other by name
docker exec api ping db  # Works! DNS resolves

# Inspect network
docker network inspect mynet
# Shows containers, IPs, subnet

# Debug connectivity
docker exec api ip addr    # Container's IP
docker exec api ip route   # Container's routes
docker exec api nslookup db # DNS resolution
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Each container gets its own network namespace (IP, ports, routes) - two containers CAN listen on the same port
2. Bridge networks provide container-to-container communication; port mapping (`-p`) provides external access
3. Custom networks enable DNS-based service discovery (containers reach each other by name)

**Interview one-liner:**
"Container networking uses network namespaces for isolation, virtual ethernet pairs connected via a bridge for L2 connectivity, and iptables NAT for external access - with custom networks enabling DNS-based service discovery between containers."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Docker's default bridge network does NOT support DNS-based container discovery - you must use `--link` (deprecated) or IP addresses. Only custom/user-defined bridge networks get automatic DNS. This catches many beginners who expect `docker run --name db` to be resolvable by name on the default network.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Container Networking. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: Container A can't reach Container B on the same Docker host. Walk me through your debugging steps.**

_Why they ask:_ Tests systematic network debugging skills.

**Answer:**
Systematic approach:

1. **Same network?**

   ```bash
   docker network inspect bridge | grep -A5 "Containers"
   # Both containers must be on the same network
   ```

2. **IP connectivity:**

   ```bash
   docker exec containerA ping <containerB_IP>
   # If this fails: bridge or veth issue
   ```

3. **DNS resolution (custom network only):**

   ```bash
   docker exec containerA nslookup containerB
   # Fails on default bridge - use custom network
   ```

4. **Port listening:**

   ```bash
   docker exec containerB ss -tlnp
   # Is the app actually listening on the expected port?
   ```

5. **Firewall/iptables:**
   ```bash
   sudo iptables -L DOCKER -n
   # Check for blocking rules
   ```

Common causes: different networks, default bridge (no DNS), app bound to localhost (not 0.0.0.0), firewall rules, port mismatch.
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Volume Mounts

**TL;DR** - Volumes provide persistent storage for containers, surviving container restarts and removal by mounting host or managed storage into the container filesystem.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Container filesystem is ephemeral - when the container is removed, all data is lost. Your database container loses all records on restart. Your app's uploaded files vanish on redeployment.

**THE INVENTION MOMENT:**
"This is exactly why Docker volumes were created."

**EVOLUTION:**
Data in container layer (lost on removal) -> Bind mounts from host (fragile, host-dependent) -> Named volumes (Docker-managed, portable) -> Volume plugins (network storage, cloud EBS/EFS) -> CSI drivers in Kubernetes (2018+).
---

### 📘 Textbook Definition

A Docker volume is a mechanism for persisting data generated by and used by Docker containers. Volumes are stored outside the container's union filesystem layer, either managed by Docker (named volumes) or mapped directly from the host filesystem (bind mounts).
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Volumes are persistent storage that outlives the container.

**One analogy:**

> A volume is like an external USB drive plugged into a laptop (container). The laptop can be replaced (container restarted), but the USB drive (volume) keeps all files. Multiple laptops can share the same USB drive (multiple containers mounting the same volume).

**One insight:**
There are three types: (1) Named volumes (Docker-managed, `docker volume create`), (2) Bind mounts (host path directly), (3) tmpfs mounts (RAM-only, for secrets). Named volumes are preferred because they're portable and Docker manages the lifecycle.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Three storage types:

1. Named Volume (Docker-managed):
   docker run -v pgdata:/var/lib/postgresql/data
   Stored: /var/lib/docker/volumes/pgdata/_data
   Lifecycle: survives container removal
   Use: databases, persistent state

2. Bind Mount (host directory):
   docker run -v /host/src:/app/src
   Stored: directly on host path
   Lifecycle: host filesystem lifecycle
   Use: development (live code reload)

3. tmpfs (RAM-only):
   docker run --tmpfs /run/secrets
   Stored: in memory only
   Lifecycle: gone when container stops
   Use: secrets, temp files

Container filesystem:
+--------------------------------+
| Writable Layer (ephemeral)     |
+--------------------------------+
| Image Layers (read-only)       |
+--------------------------------+
    |             |           |
  [volume]    [bind mount]  [tmpfs]
  /data       /app/src      /secrets
  (persistent) (host sync)  (memory)
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```bash
# Named volume (preferred for data)
docker volume create pgdata
docker run -d --name db \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16

# Bind mount (for development)
docker run -d --name dev \
  -v $(pwd)/src:/app/src \
  node:20

# tmpfs mount (for secrets)
docker run -d --name app \
  --tmpfs /run/secrets:size=64m \
  myapp:1.0

# Inspect volume
docker volume inspect pgdata

# Backup a volume
docker run --rm -v pgdata:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/pgdata.tar.gz /data
```

```yaml
# Docker Compose volumes
services:
  db:
    image: postgres:16
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql

volumes:
  pgdata: # Named volume
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Container layer is ephemeral - use volumes for ANY data that must survive restarts
2. Named volumes for persistent data (databases), bind mounts for development (live reload), tmpfs for secrets
3. Volumes are independent of containers - they persist after `docker rm` (unless you use `docker rm -v` or `docker volume prune`)

**Interview one-liner:**
"I use named volumes for persistent data like databases (Docker-managed, portable, survives container removal), bind mounts for development (host code synced into container for live reload), and tmpfs for sensitive data that should never touch disk."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

`docker rm` does NOT remove volumes. `docker system prune` does NOT remove volumes either. Volumes accumulate silently, potentially consuming hundreds of GBs. Only `docker volume prune` or explicit `docker volume rm` cleans them up. This is by design (safety), but it catches teams by surprise when disk fills up.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Volume Mounts. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: Your containerized PostgreSQL database lost all data after a deployment. What happened and how do you prevent it?**

_Why they ask:_ Tests understanding of container storage lifecycle.

**Answer:**
Most likely causes:

1. **No volume mount** - data was in the writable container layer, lost on `docker rm`
2. **Anonymous volume** - `docker run -v /var/lib/postgresql/data` creates an anonymous volume that may not be reattached after `docker rm` and `docker run`
3. **docker-compose down -v** - the `-v` flag removes named volumes (data gone)
4. **Wrong mount path** - volume mounted to wrong directory, data written to container layer instead

Prevention:

```yaml
# Always use named volumes for databases
services:
  db:
    image: postgres:16
    volumes:
      - pgdata:/var/lib/postgresql/data
volumes:
  pgdata: # Named, explicit, survives `down`
```

Additionally:

- Backup volumes to external storage (S3, backup service)
- For production: use managed database services (RDS) instead of containerized databases
- Document that `docker-compose down -v` is destructive
- Use `external: true` for volumes that should never be auto-removed
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Docker Networking Modes

**TL;DR** - Docker provides four networking modes - bridge (default, isolated), host (no isolation), none (no networking), and overlay (multi-host) - each with different isolation, performance, and use case trade-offs.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
One-size-fits-all networking can't satisfy all needs: some containers need isolation, some need maximum performance, some need to be completely disconnected, and some need to span multiple hosts.

**THE INVENTION MOMENT:**
"This is exactly why Docker offers multiple networking modes."
---

### 📘 Textbook Definition

Docker networking modes define how a container's network namespace is configured: bridge (virtual switch with isolated subnet), host (shares host network namespace directly), none (no network interfaces), and overlay (VXLAN-based multi-host networking for Docker Swarm/K8s).
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Four modes: bridge (isolated), host (fast, no isolation), none (disconnected), overlay (multi-host).

**One analogy:**

> Bridge = apartment with its own mail slot. Host = living in the post office itself. None = no address, no mail. Overlay = mail system connecting buildings across a city.

**One insight:**
Bridge mode adds ~5% network overhead from NAT/bridge traversal. Host mode eliminates this but sacrifices port isolation (if the host already uses port 8080, the container can't). The right choice depends on whether you value isolation or performance.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Mode comparison:

| Mode    | Isolation | Performance | Use Case       |
|---------|-----------|-------------|----------------|
| bridge  | High      | Good (~5%   | Default, most  |
|         |           | overhead)   | apps           |
| host    | None      | Best (no    | High-throughput|
|         |           | NAT/bridge) | monitoring     |
| none    | Complete  | N/A         | Batch jobs,    |
|         |           |             | security       |
| overlay | High      | Moderate    | Multi-host,    |
|         |           | (VXLAN)     | Swarm/K8s      |

bridge (default):
  container -> veth -> docker0 bridge -> NAT -> host eth0

host:
  container -> host eth0 directly (no namespace)

none:
  container -> loopback only (no external network)

overlay (VXLAN):
  container A (host 1) -> VXLAN tunnel -> container B (host 2)
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```bash
# Bridge (default)
docker run -d --network bridge -p 8080:8080 myapp

# Host (container uses host network directly)
docker run -d --network host myapp
# No port mapping needed - app binds to host ports

# None (no networking)
docker run -d --network none batch-job
# Only loopback available

# Custom bridge with DNS
docker network create mynet
docker run -d --network mynet --name api myapp
docker run -d --network mynet --name db postgres
# api can reach db by name on custom network
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Bridge: default, isolated, requires port mapping (`-p`), custom bridges get DNS
2. Host: maximum performance (no NAT), but no port isolation - use for monitoring agents, high-throughput apps
3. Overlay: multi-host communication via VXLAN tunnels - used by Docker Swarm and Kubernetes

**Interview one-liner:**
"Bridge mode provides isolated networking with virtual bridges and NAT at ~5% overhead; host mode eliminates the overhead for high-throughput workloads but sacrifices isolation; overlay mode extends networking across multiple hosts via VXLAN encapsulation for orchestrated clusters."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Docker Networking Modes. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: When would you use host networking instead of bridge?**

_Why they ask:_ Tests decision-making about performance vs isolation.

**Answer:**
Host networking makes sense when:

1. **High-throughput networking** (>10Gbps): bridge NAT overhead is measurable
2. **Monitoring agents** (Prometheus node exporter): needs access to host network metrics
3. **Service mesh sidecars**: sometimes need host network for iptables manipulation
4. **Legacy apps**: requiring specific network interfaces or multicast

NOT recommended when:

- Port conflicts possible (multiple containers needing same port)
- Security isolation required (container sees all host traffic)
- Portability needed (host networking is Linux-specific)

The trade-off: ~5% better throughput vs complete loss of network isolation. For most microservices, bridge is the right choice. For infrastructure daemons, host is appropriate.
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Port Mapping

**TL;DR** - Port mapping exposes container ports to the host using NAT (iptables DNAT rules), translating `host_port:container_port` to enable external access to containerized services.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Containers have their own network namespace. A service listening on port 8080 inside a container is unreachable from outside because the container's port 8080 is isolated from the host's port space.

**THE INVENTION MOMENT:**
"This is exactly why port mapping was created."
---

### 📘 Textbook Definition

Port mapping (publishing) creates a NAT rule that forwards traffic arriving at a specific host port to a container's port, bridging the network namespace boundary and enabling external access to containerized services.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```bash
# Explicit mapping: host 80 -> container 8080
docker run -d -p 80:8080 myapp
# Clients access http://host:80
# Traffic NAT'd to container's 8080

# Random host port
docker run -d -p 8080 myapp
docker port myapp  # Shows assigned host port

# Bind to specific interface
docker run -d -p 127.0.0.1:80:8080 myapp
# Only accessible from localhost

# Multiple ports
docker run -d -p 80:8080 -p 443:8443 myapp
```

```
NAT flow:
  Client -> host:80
    -> iptables DNAT rule
      -> 172.17.0.2:8080 (container)
        -> response follows reverse path
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Format: `-p host_port:container_port` - HOST is what external clients use, CONTAINER is what the app listens on
2. Binding to `0.0.0.0` (default) exposes to ALL interfaces - use `127.0.0.1:port:port` for localhost-only
3. In Kubernetes, Services handle port mapping instead of Docker's `-p` flag

**Interview one-liner:**
"Port mapping creates iptables DNAT rules to forward host-port traffic into the container's network namespace - I always bind to specific interfaces in production and use Kubernetes Services rather than Docker port mapping for orchestrated deployments."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Port Mapping. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# DNS in Containers

**TL;DR** - Docker provides automatic DNS resolution for containers on custom networks, enabling service discovery by container/service name instead of hardcoded IP addresses.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Container IPs are dynamic - they change on every restart. Hardcoding `172.17.0.3` in your app's database connection string breaks when the database container restarts with a new IP.

**THE INVENTION MOMENT:**
"This is exactly why DNS-based container discovery was created."
---

### 📘 Textbook Definition

Docker's embedded DNS server (127.0.0.11) resolves container names and service aliases to their current IP addresses on user-defined networks, providing dynamic service discovery without external DNS infrastructure.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
DNS resolution in Docker:

User-defined bridge network:
  Container "api" -> DNS query "db"
    -> Docker DNS server (127.0.0.11)
      -> Resolves to 172.18.0.3
        -> Connection to 172.18.0.3

Compose DNS:
  Service name = DNS name
  docker-compose.yml:
    services:
      api:        <- resolvable as "api"
      db:         <- resolvable as "db"
      cache:      <- resolvable as "cache"

  api connects to "db:5432" and "cache:6379"
  DNS handles IP changes on restart

Default bridge network:
  NO automatic DNS! Must use --link (deprecated)
  or IP addresses directly.
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```yaml
# Docker Compose - DNS is automatic
services:
  api:
    image: myapp:1.0
    environment:
      # Use service names, not IPs
      - DB_HOST=db
      - REDIS_HOST=cache
  db:
    image: postgres:16
  cache:
    image: redis:7
```

```bash
# Verify DNS resolution
docker exec api nslookup db
# Server: 127.0.0.11 (Docker DNS)
# Name: db  Address: 172.18.0.3

# Custom DNS configuration
docker run --dns 8.8.8.8 \
  --dns-search example.com myapp

# Debug DNS issues
docker exec api cat /etc/resolv.conf
# nameserver 127.0.0.11
# ndots: 0
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. DNS works automatically on user-defined networks (NOT on the default bridge network)
2. Service name = DNS name in Docker Compose - use `db:5432` not `172.18.0.3:5432`
3. Docker's embedded DNS is at 127.0.0.11 - check `/etc/resolv.conf` inside the container to verify

**Interview one-liner:**
"Docker's embedded DNS server automatically resolves container names to IPs on user-defined networks, enabling dynamic service discovery - in Compose, the service name IS the hostname, so connection strings use service names that automatically resolve even when container IPs change on restart."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for DNS in Containers. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Docker Compose Networking

**TL;DR** - Docker Compose automatically creates an isolated network for each project where services discover each other by name, with optional custom networks for multi-project or advanced topology control.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Running `docker-compose up` for 5 services requires manually creating networks, connecting containers, and managing DNS. Each developer would need to run networking commands before services can communicate.

**THE INVENTION MOMENT:**
"This is exactly why Compose's automatic networking was created."
---

### 📘 Textbook Definition

Docker Compose networking automatically creates a default bridge network named `<project>_default` for each Compose project, connects all services to it, and provides DNS-based service discovery using service names defined in the YAML file.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```yaml
# docker-compose.yml
services:
  api:
    image: myapp:1.0
    ports:
      - "8080:8080"
    networks:
      - frontend
      - backend

  db:
    image: postgres:16
    networks:
      - backend # Only accessible from backend

  nginx:
    image: nginx
    ports:
      - "80:80"
    networks:
      - frontend # Can reach api but NOT db

networks:
  frontend:
  backend:
```

```
Network topology:
                    [External]
                       |
              +--------+--------+
              |     nginx       |
              | (frontend only) |
              +--------+--------+
                       |
  frontend: -----------+-----------
                       |
              +--------+--------+
              |      api        |
              | (frontend +     |
              |  backend)       |
              +--------+--------+
                       |
  backend:  -----------+-----------
                       |
              +--------+--------+
              |       db        |
              | (backend only)  |
              +-----------------+

  nginx can reach api (both on frontend)
  api can reach db (both on backend)
  nginx CANNOT reach db (different networks)
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```bash
# Default behavior (auto-created network)
docker compose up -d
# Creates: myproject_default network
# All services connected, discoverable by name

# Inspect created networks
docker network ls | grep myproject

# Cross-project communication
# In project A:
networks:
  shared:
    name: shared-network
# In project B:
networks:
  shared:
    external: true
    name: shared-network
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Compose auto-creates a `<project>_default` network - all services connected, discoverable by name
2. Use custom networks to control which services can reach each other (network segmentation)
3. For cross-project communication, use named external networks shared between Compose files

**Interview one-liner:**
"Compose automatically creates an isolated bridge network per project with DNS-based service discovery - I use custom networks to segment frontend from backend services and external named networks for cross-project communication."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Docker Compose Networking. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: How would you design Compose networking for a microservices app with a frontend, API, database, and cache?**

_Why they ask:_ Tests network segmentation and security thinking.

**Answer:**

```yaml
services:
  frontend:
    networks: [public]
  api:
    networks: [public, internal]
  db:
    networks: [internal]
  cache:
    networks: [internal]

networks:
  public: # frontend <-> api
  internal: # api <-> db, api <-> cache
```

Design principles:

1. **Least privilege**: DB/cache only on internal network - unreachable from frontend
2. **API as gateway**: only service on both networks - controls all data access
3. **External access**: only frontend and API expose ports to host
4. **Defense in depth**: even if frontend is compromised, attacker can't reach DB directly

This mirrors production network architecture where DMZ (public), application tier, and data tier have firewall rules between them.
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]
