---
layout: default
title: "Containers - Fundamentals"
parent: "Containers"
grand_parent: "Interview Mastery"
nav_order: 1
permalink: /interview/containers/fundamentals/
topic: Containers
subtopic: Fundamentals
keywords:
  - Containerization
  - Docker vs VM
  - Docker Image
  - Dockerfile
  - Docker Compose
  - Container Orchestration
difficulty_range: easy
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Containerization](#containerization)
- [Docker vs VM](#docker-vs-vm)
- [Docker Image](#docker-image)
- [Dockerfile](#dockerfile)
- [Docker Compose](#docker-compose)
- [Container Orchestration](#container-orchestration)

# Containerization

**TL;DR** - Containerization packages an application with all its dependencies into an isolated, portable unit that runs consistently across any environment.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
You develop on macOS, CI runs on Ubuntu, production is Amazon Linux. Your app works locally but crashes in staging because the system has OpenSSL 1.1 instead of 3.0. The ops team spends days debugging "works on my machine" issues. Every server is a snowflake with different library versions.

**THE BREAKING POINT:**
A single dependency mismatch causes a production outage at 2 AM. The fix takes 6 hours because nobody knows exactly what's installed on the prod server.

**THE INVENTION MOMENT:**
"This is exactly why containerization was created."

**EVOLUTION:**
chroot (1979) gave process isolation. FreeBSD jails (2000) added networking isolation. LXC (2008) combined namespaces and cgroups. Docker (2013) made containers developer-friendly with images and registries. OCI standardized the format (2015+). Today containers are the default deployment unit.
---

### 📘 Textbook Definition

Containerization is an OS-level virtualization method that packages application code, runtime, system tools, libraries, and settings into a standalone executable unit called a container. Containers share the host kernel but run in isolated user spaces using Linux namespaces and cgroups for resource isolation and limitation.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
A container is a lightweight, isolated box for running an app with everything it needs.

**One analogy:**

> Think of shipping containers. Before standardization, goods were loaded loosely onto ships - breakage, theft, delays. The shipping container standardized the unit of transport: pack once, ship anywhere, unpack identically. Software containers do the same for code.

**One insight:**
The key insight is that containers share the host OS kernel. They're NOT separate operating systems. This is why they start in milliseconds (vs minutes for VMs) and why a single server can run hundreds of containers (vs dozens of VMs).
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. A container is a process (or group of processes) with isolated namespaces
2. The container sees its own filesystem, network, and PID space
3. The host kernel is shared - containers don't carry their own OS

**DERIVED DESIGN:**
Because containers share the kernel, they're lightweight (MBs not GBs). Because they have isolated filesystems, they're portable. Because they're just processes, they start instantly.

**THE TRADE-OFFS:**
**Gain:** Portability, density, fast startup, reproducibility
**Cost:** Weaker isolation than VMs (shared kernel = shared attack surface), Linux-only workloads on Linux hosts

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Some isolation mechanism is needed to prevent processes from interfering with each other
**Accidental:** Docker's daemon requirement, image layer complexity, networking setup
---

### 🧠 Mental Model / Analogy

> A container is like an apartment in a building. Each apartment has its own locked door, its own address, its own utilities meter - but they all share the building's foundation, plumbing infrastructure, and structural walls.

- "Building foundation" -> host OS kernel
- "Apartment walls" -> Linux namespaces (isolation)
- "Utilities meter" -> cgroups (resource limits)
- "Locked door" -> process isolation
- "Building address" -> shared network stack

Where this analogy breaks down: apartments can't be instantly replicated and moved to another building, but containers can.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
A container is a way to package software so it runs the same everywhere. It's like a sealed lunch box - everything the app needs is inside, and it doesn't leak into or depend on what's outside.

**Level 2 - How to use it (junior developer):**
Write a Dockerfile that describes your app's environment. Build it into an image. Run the image as a container. Use `docker run`, `docker build`, `docker ps`. Containers are ephemeral - they can be stopped and restarted from the same image.

**Level 3 - How it works (mid-level engineer):**
Containers use Linux namespaces (PID, NET, MNT, UTS, IPC, USER) for isolation and cgroups for resource limiting. The container filesystem is a union of read-only image layers plus a writable layer on top. The container runtime (containerd/runc) sets up these kernel primitives and executes the entrypoint process.

**Level 4 - Mastery (senior/staff+ engineer):**
Container security depends on the shared kernel - a kernel exploit escapes ALL containers. Rootless containers (user namespaces) and sandboxed runtimes (gVisor, Kata) add defense layers. In production, container density planning requires understanding cgroup memory accounting (RSS vs cache), CPU throttling (CFS bandwidth), and the OOM killer's container-awareness. The choice between containerd and CRI-O affects cold-start latency and image pull strategies.




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### ⚙️ How It Works

1. **Build time:** Dockerfile instructions execute sequentially, each creating a filesystem layer (copy-on-write)
2. **Image storage:** Layers are content-addressed (SHA256), deduplicated, and cached
3. **Runtime setup:** Container runtime creates namespaces, sets cgroup limits, mounts filesystem
4. **Process execution:** Entrypoint process runs as PID 1 inside the container's PID namespace
5. **Networking:** Virtual ethernet pair connects container to bridge network
6. **Lifecycle:** Container runs until PID 1 exits. Writable layer is discarded (unless committed)

```
+-------------------------------------------+
| Host OS Kernel (shared)                   |
+--------+---------+---------+--------------+
| Container A      | Container B           |
| +------+         | +------+              |
| | App  |         | | App  |              |
| | Libs |         | | Libs |              |
| | Conf |         | | Conf |              |
| +------+         | +------+              |
| Namespaces       | Namespaces            |
| Cgroups          | Cgroups               |
+------------------+-----------------------+
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
Developer writes code -> Dockerfile defines environment -> `docker build` creates image -> Push to registry -> `docker pull` on target -> `docker run` starts container <- YOU ARE HERE -> App serves traffic

**FAILURE PATH:**
Container OOM killed -> orchestrator restarts it -> if crash loop, marked unhealthy -> traffic rerouted -> alert fires

**WHAT CHANGES AT SCALE:**
At 100+ containers, you need orchestration (Kubernetes). At 1000+, image pull becomes a bottleneck (use pre-pulling, registry mirrors). At 10,000+, kernel resource limits and network namespace overhead become factors.
---

### 💻 Code Example

**Example 1 - BAD vs GOOD Dockerfile:**

```dockerfile
# BAD: 1.2GB image, installs everything, runs as root
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk maven git curl wget vim
COPY . /app
WORKDIR /app
RUN mvn package
CMD ["java", "-jar", "target/app.jar"]
```

```dockerfile
# GOOD: 200MB image, multi-stage, non-root
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

FROM eclipse-temurin:17-jre-alpine
RUN addgroup -S app && adduser -S app -G app
USER app
COPY --from=build /app/target/app.jar /app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app.jar"]
```

**Example 2 - Running and inspecting containers:**

```bash
# Run with resource limits
docker run -d --name myapp \
  --memory=512m --cpus=1.0 \
  -p 8080:8080 \
  myapp:1.0

# Check resource usage
docker stats myapp

# Inspect namespaces from host
docker inspect --format \
  '{{.State.Pid}}' myapp
# Then: ls -la /proc/<PID>/ns/
```

**How to test / verify correctness:**
Build image, run container, verify process isolation with `docker exec`, confirm resource limits with `docker stats`, test networking with `curl localhost:8080`.
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

1. Containers share the host kernel - they're processes with isolated namespaces, NOT mini-VMs
2. Images are immutable layered filesystems; containers add a writable layer on top
3. Fast startup + high density = containers win for microservices; weaker isolation = VMs win for multi-tenant security

**Interview one-liner:**
"A container is a process running in isolated Linux namespaces with cgroup resource limits, sharing the host kernel but seeing its own filesystem, network, and PID space - giving VM-like isolation at process-level speed and density."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Most container "security breaches" aren't container escapes - they're misconfiguration: running as root, mounting the Docker socket, using `--privileged` mode, or exposing the Docker API without TLS. The container boundary itself is rarely the weak point; the human decisions around it are.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Containerization. Otherwise remove this section.]
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

**Q1: What's the difference between a container and a VM? When would you choose one over the other?**

_Why they ask:_ Tests fundamental understanding and decision-making ability.

**Answer:**
A VM virtualizes hardware - it has its own kernel, boot process, and OS. A container virtualizes the OS - it shares the host kernel and isolates at the process level.

Key differences:
| Aspect | VM | Container |
|--------|-----|-----------|
| Startup | 30-60 seconds | < 1 second |
| Size | GBs | MBs |
| Isolation | Hardware-level | Process-level |
| Density | 10-50 per host | 100-1000 per host |
| Overhead | Full OS overhead | Minimal |

Choose VMs when: you need strong multi-tenant isolation, run different OS kernels (Windows + Linux), or have compliance requirements mandating hardware-level separation.

Choose containers when: you want fast scaling, high density, consistent environments, CI/CD pipeline integration, or microservices architecture.

In practice, most teams use both: containers run inside VMs in cloud environments (EC2 instances running Docker, or EKS nodes).

---

**Q2: A container in production is being OOM-killed repeatedly. Walk me through your diagnosis.**

_Why they ask:_ Tests operational debugging skills with containers.

**Answer:**
Step 1 - Confirm OOM kill:

```bash
docker inspect <container> | grep OOMKilled
# Or check kernel logs
dmesg | grep -i "oom\|killed"
```

Step 2 - Check memory limits vs actual usage:

```bash
docker stats <container> --no-stream
# Look at MEM USAGE / LIMIT
```

Step 3 - Identify what's consuming memory inside the container:

```bash
docker exec <container> top -o %MEM
# For JVM apps, check heap settings
docker exec <container> \
  jcmd 1 VM.native_memory summary
```

Root causes:

1. **Memory limit too low** - increase the limit (but verify it's not a leak first)
2. **Memory leak in application** - heap dump, profiler, monitor over time
3. **JVM heap misconfiguration** - `-Xmx` set higher than container limit (JVM doesn't see cgroups by default in older versions; use `-XX:+UseContainerSupport`)
4. **Off-heap growth** - native memory, thread stacks, mapped files

Key insight: In Java containers, always set `-XX:MaxRAMPercentage=75` instead of `-Xmx`, leaving 25% for non-heap memory. Newer JVMs (11+) are cgroup-aware by default.

---

**Q3: Explain Docker image layers and how they affect build performance and image size.**

_Why they ask:_ Tests understanding of Docker internals and optimization skills.

**Answer:**
Each Dockerfile instruction creates a new layer. Layers are:

- **Immutable** - once created, never modified
- **Content-addressed** - identified by SHA256 hash
- **Cached** - rebuilt only when inputs change
- **Shared** - multiple images sharing a base share those layers on disk

Build performance optimization:

1. **Order matters** - put rarely-changing layers first (OS, dependencies), frequently-changing last (source code)
2. **Dependency caching** - copy `pom.xml`/`package.json` first, install dependencies, THEN copy source
3. **Multi-stage builds** - build in one stage, copy only artifacts to runtime stage

Size impact: Each `RUN` creates a layer. If you `apt install` then `apt clean` in separate RUNs, the installed files exist in one layer even though they're deleted in the next. Combine into one `RUN` to keep size small.

```dockerfile
# BAD: 3 layers, cleanup doesn't reduce size
RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# GOOD: 1 layer, cleanup actually saves space
RUN apt-get update && \
    apt-get install -y build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

---

**Q4: How do you handle secrets in containers? What's wrong with putting them in the image?**

_Why they ask:_ Tests security awareness - a common mistake in practice.

**Answer:**
Putting secrets in images is dangerous because:

1. Images are pushed to registries - anyone with pull access sees secrets
2. Image layers are immutable - even if you delete a secret in a later layer, it exists in the history
3. `docker history` and layer extraction reveal everything

Proper approaches (ranked by maturity):

1. **Environment variables** - basic, visible in `docker inspect` (acceptable for dev)
2. **Docker secrets** (Swarm) - mounted as tmpfs files, encrypted at rest
3. **Volume-mounted secrets** - mount from host or secret store
4. **Init containers** - fetch secrets at startup, write to shared volume
5. **Sidecar vault agent** - HashiCorp Vault agent injects secrets dynamically
6. **CSI secrets driver** (K8s) - mount secrets as volumes from external stores

Key principle: secrets should never be in the image build context. Use `.dockerignore`, multi-stage builds, and build-time `--secret` flag (BuildKit).

---

**Q5: Your Docker build takes 15 minutes. How do you speed it up?**

_Why they ask:_ Tests practical optimization experience.

**Answer:**
Diagnosis approach - identify what's slow:

```bash
DOCKER_BUILDKIT=1 docker build \
  --progress=plain . 2>&1 | \
  grep -E "^#[0-9]+ (DONE|CACHED)"
```

Common fixes:

1. **Layer caching** - reorder Dockerfile (dependencies before source code)
2. **BuildKit** - parallel stage execution, better caching
3. **Multi-stage builds** - smaller context, fewer layers in final image
4. **`.dockerignore`** - exclude `node_modules/`, `.git/`, test files from build context
5. **Cache mounts** - `RUN --mount=type=cache,target=/root/.m2` for Maven/Gradle
6. **Registry caching** - `--cache-from` pulls cached layers from registry
7. **Base image selection** - alpine/slim over full Ubuntu
8. **Parallel builds** - BuildKit builds independent stages concurrently

The biggest wins are usually: (1) fixing .dockerignore (reduces context transfer), (2) dependency caching (skip re-downloading), (3) BuildKit parallelism.
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

# Docker vs VM

**TL;DR** - Docker containers share the host kernel for process-level isolation with millisecond startup, while VMs virtualize hardware with separate kernels for stronger isolation but higher overhead.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT BOTH:**
Every application runs directly on bare metal. Installing two apps that need different library versions is impossible without conflicts. Scaling means buying new servers.

**THE BREAKING POINT:**
VMs solved isolation but introduced massive overhead - minutes to boot, GBs of memory per instance. When microservices require 50+ services, VM overhead becomes the bottleneck.

**THE INVENTION MOMENT:**
"This is exactly why Docker (containers) was created."

**EVOLUTION:**
Bare metal (1960s-1990s) -> Hardware virtualization/VMware (1999) -> Paravirtualization/Xen (2003) -> Cloud VMs/EC2 (2006) -> Containers/Docker (2013) -> Serverless (2014+). Today most workloads use containers-inside-VMs in cloud environments.
---

### 📘 Textbook Definition

A virtual machine emulates a complete hardware environment including CPU, memory, and I/O devices, running a full guest operating system on a hypervisor. A container provides OS-level process isolation using kernel namespaces and cgroups, sharing the host kernel while presenting an isolated userspace to applications.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
VMs virtualize hardware; containers virtualize the OS.

**One analogy:**

> A VM is like renting a separate house (own foundation, walls, plumbing). A container is like renting an apartment (shared building infrastructure, private living space). Houses offer more privacy but cost more to build and maintain.

**One insight:**
The shared kernel is the fundamental trade-off. It gives containers their speed (no boot) and density (no OS overhead) but limits their isolation - a kernel vulnerability affects all containers on the host.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. VMs run their own kernel; containers share the host kernel
2. VM isolation is enforced by hardware (CPU rings); container isolation is enforced by the kernel (namespaces)
3. Overhead scales with abstraction level - more isolation = more resources

**DERIVED DESIGN:**
VMs pay the cost of a full OS (500MB-2GB RAM) for each instance. Containers pay only the application footprint. This is why a 16GB server runs ~10 VMs but ~100 containers.

**THE TRADE-OFFS:**
**Gain (containers):** 10x density, sub-second startup, smaller images, better CI/CD integration
**Cost (containers):** Weaker isolation, Linux-only (on Linux hosts), kernel sharing risks

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Some form of isolation is needed to run untrusted workloads
**Accidental:** Docker's daemon architecture, networking complexity, storage driver quirks
---

### 🧠 Mental Model / Analogy

> VMs = separate houses on a street. Containers = apartments in a building.

- "House foundation" -> hypervisor providing hardware abstraction
- "Building foundation" -> shared host kernel
- "House utilities" -> full guest OS per VM
- "Shared plumbing" -> shared kernel services
- "House walls" -> hardware-level isolation (VM escape is very rare)
- "Apartment walls" -> namespace isolation (thinner barrier)

Where this analogy breaks down: containers can be created in milliseconds; you can't build a house that fast.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
A VM is a complete simulated computer running inside another computer. A container is a lightweight isolated environment that shares the main computer's core system. VMs are heavier but more isolated; containers are lighter but share more.

**Level 2 - How to use it (junior developer):**
Use containers (Docker) for application deployment - fast, portable, CI/CD friendly. Use VMs for different OS requirements, legacy apps, or security-sensitive multi-tenant isolation. In cloud environments, you typically run containers inside VMs (EKS nodes are EC2 instances).

**Level 3 - How it works (mid-level engineer):**
VMs use a hypervisor (Type 1: bare metal like ESXi, or Type 2: hosted like VirtualBox). The hypervisor manages hardware allocation and trap-and-emulate for privileged instructions. Containers use the Linux kernel's namespace subsystem (PID, NET, MNT, UTS, IPC, USER) for isolation and cgroups for resource limits. No hypervisor needed.

**Level 4 - Mastery (senior/staff+ engineer):**
The VM vs container boundary is blurring. Kata Containers and Firecracker run each container in a lightweight microVM (100ms boot, 5MB overhead) - giving container ergonomics with VM isolation. gVisor intercepts syscalls in userspace, providing a middle ground. In practice, the decision is about threat model: same-trust workloads use containers; different-trust workloads use VMs or microVMs.




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### ⚙️ How It Works

```
VM Architecture:
+------------------------------------+
| VM 1        | VM 2        | VM 3  |
| +--------+  | +--------+  | +--+  |
| | App    |  | | App    |  | |A |  |
| | Bins   |  | | Bins   |  | |B |  |
| | Guest  |  | | Guest  |  | |G |  |
| | Kernel |  | | Kernel |  | |K |  |
| +--------+  | +--------+  | +--+  |
+------------------------------------+
|          Hypervisor                 |
+------------------------------------+
|          Host OS / Hardware         |
+------------------------------------+

Container Architecture:
+------------------------------------+
| Ctr 1  | Ctr 2  | Ctr 3  | Ctr 4 |
| +----+  | +----+  | +----+ | +--+  |
| |App |  | |App |  | |App | | |A |  |
| |Bins|  | |Bins|  | |Bins| | |B |  |
| +----+  | +----+  | +----+ | +--+  |
+------------------------------------+
|    Container Runtime (containerd)   |
+------------------------------------+
|    Host OS Kernel (shared)          |
+------------------------------------+
|    Hardware                         |
+------------------------------------+
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
Developer chooses deployment model -> Containers for microservices <- YOU ARE HERE -> Container runs on VM in cloud -> VM provides hardware isolation from other tenants

**FAILURE PATH:**
Container kernel exploit -> all containers on host compromised -> VM boundary still holds (cloud provider isolation intact)

**WHAT CHANGES AT SCALE:**
At small scale (< 10 services), the choice barely matters. At 50+ services, container startup speed and density become critical. At 1000+ pods, even the overhead of Kubernetes control plane on VMs matters for cost.
---

### 💻 Code Example

```bash
# Compare startup time
time docker run --rm alpine echo "hello"
# real: 0.4s

time vagrant up  # typical VM
# real: 45-120s
```

```bash
# Compare resource usage
# Container: ~5MB overhead
docker run -d --memory=128m alpine sleep 3600
docker stats --no-stream

# VM: ~512MB minimum even idle
# (Vagrant/VirtualBox equivalent consumes
#  512MB RAM before your app even starts)
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

1. Containers share the kernel (fast, dense, weaker isolation); VMs have their own kernel (slow, heavy, strong isolation)
2. In cloud, it's not either/or - containers run INSIDE VMs (EKS nodes = EC2 instances)
3. For same-trust microservices use containers; for multi-tenant isolation use VMs or microVMs (Firecracker)

**Interview one-liner:**
"VMs virtualize hardware with separate kernels giving strong isolation at higher cost; containers virtualize the OS namespace giving process isolation at near-zero overhead - in practice we use both, with containers running inside cloud VMs for defense in depth."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

AWS Lambda, the poster child of "serverless," actually runs each function invocation inside a Firecracker microVM - a tiny VM that boots in 125ms with 5MB memory overhead. The industry is converging on "container ergonomics with VM isolation" rather than choosing one over the other.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Docker vs VM. Otherwise remove this section.]
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

**Q1: Your company runs sensitive financial workloads alongside less-critical internal tools. How would you architect the isolation?**

_Why they ask:_ Tests ability to make security architecture decisions with containers.

**Answer:**
Defense in depth approach:

1. **Network segmentation:** Separate VPCs for financial vs internal workloads
2. **Node isolation:** Dedicated node pools for financial containers (K8s node affinity/taints) - never co-locate with untrusted workloads on same kernel
3. **Runtime hardening:** Financial containers use gVisor or Kata Containers for additional syscall-level isolation
4. **Container security:** Read-only root filesystem, non-root users, dropped capabilities, seccomp profiles
5. **VM boundary:** Each node pool runs on separate VM instances - kernel exploit in internal workload can't reach financial nodes

The key principle: containers alone don't provide sufficient isolation for different trust levels. You need the VM boundary between trust domains, containers within a trust domain.

---

**Q2: When would you recommend NOT using containers?**

_Why they ask:_ Tests critical thinking - knowing limits matters more than knowing benefits.

**Answer:**
Containers are wrong when:

1. **Legacy Windows apps** - older .NET Framework apps with COM dependencies, registry requirements
2. **Kernel-dependent workloads** - apps needing specific kernel modules, custom kernel parameters
3. **GPU/hardware access** - while possible (nvidia-docker), it adds complexity for minimal benefit in some cases
4. **Stateful singleton services** - databases that need direct disk access, specific filesystem tuning
5. **Tiny teams with no ops capability** - container orchestration overhead exceeds the benefit for 2 services
6. **Compliance mandates** - some regulated industries require VM-level isolation documentation

The "when NOT to use" signal of mastery: containers introduce complexity (networking, storage, orchestration). If you have a monolith with 3 developers, a simple VM with Ansible might be the better choice. Containers shine at scale with many services.
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

# Docker Image

**TL;DR** - A Docker image is an immutable, layered filesystem template containing everything needed to run an application - built once, run identically anywhere.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Deploying means SSHing into a server, running install scripts, hoping nothing changed since last time. Each server drifts from the others. "It worked in staging" is a daily occurrence because staging doesn't match production.

**THE BREAKING POINT:**
A production server was patched but staging wasn't. The configuration drift caused a deployment failure that took hours to diagnose.

**THE INVENTION MOMENT:**
"This is exactly why Docker images were created."

**EVOLUTION:**
Tarball archives -> VM images (AMIs, VMDKs) -> Docker images with layers (2013) -> OCI Image Spec standardization (2017) -> Multi-arch images, image signing, and SBOM (2022+).
---

### 📘 Textbook Definition

A Docker image is a read-only, ordered collection of filesystem layers and metadata that together form a complete filesystem for running a container. Each layer represents a set of filesystem changes, layers are content-addressed by their SHA256 digest, and they're assembled at runtime using union mount (overlay2) to present a unified view.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
An image is a frozen, layered snapshot of everything your app needs to run.

**One analogy:**

> An image is like a recipe that has already been cooked and vacuum-sealed. You don't need to gather ingredients or follow steps - just open and serve. You can serve the same meal to 100 tables simultaneously from the same sealed package.

**One insight:**
Images are immutable. When a container writes files, those writes go to a thin writable layer on top - the image layers below never change. This is why the same image always produces identical behavior regardless of what a previous container did.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Image layers are immutable and content-addressed (SHA256)
2. Layers are stacked in order using union filesystem (overlay2)
3. Identical layers are shared across images (deduplication)

**DERIVED DESIGN:**
Immutability enables caching (rebuild only changed layers), sharing (common base layers stored once), and reproducibility (same hash = same content forever).

**THE TRADE-OFFS:**
**Gain:** Reproducibility, fast distribution (only pull changed layers), deduplication
**Cost:** Larger than just the application binary, layer ordering affects build cache efficiency

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** You must bundle dependencies somehow for portability
**Accidental:** Layer ordering optimization, multi-platform image manifests, storage driver differences
---

### 🧠 Mental Model / Analogy

> An image is like a stack of transparent sheets (overhead projector slides). Each sheet adds something new on top of the ones below. You can't modify a sheet once it's printed - only add a new one on top.

- "Bottom sheet" -> base OS layer (alpine, ubuntu)
- "Middle sheets" -> dependency installation layers
- "Top sheet" -> application code layer
- "Stack of all sheets" -> complete image
- "Viewing the stack" -> union mount presenting unified FS

Where this analogy breaks down: layers can delete files from lower layers (whiteout files), which transparent sheets can't do.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
A Docker image is like a template for creating containers. It contains your app plus everything it needs. You build it once and can create many identical containers from it.

**Level 2 - How to use it (junior developer):**
Build with `docker build -t myapp:1.0 .`. Push to a registry with `docker push`. Pull on target with `docker pull`. Tag properly for versioning. Use `.dockerignore` to exclude unnecessary files.

**Level 3 - How it works (mid-level engineer):**
Each Dockerfile instruction creates a layer. Layers use overlay2 filesystem - lowerdir (read-only image layers) + upperdir (container writes). Image manifests contain the ordered list of layer digests. Multi-platform manifests (manifest lists) point to architecture-specific images. Layer caching uses input hashing - if the instruction and context haven't changed, the cached layer is reused.

**Level 4 - Mastery (senior/staff+ engineer):**
Image supply chain security requires: content trust (Notary/cosign for signing), SBOM generation (Syft), vulnerability scanning in CI (Trivy/Grype), and base image pinning (digest-based references, not tags). At scale, image pull is the biggest cold-start contributor - solutions include pre-pulling on nodes, lazy-loading (Stargz/Nydus), and image streaming. Layer design affects CI speed: isolate dependency layers from code layers for maximum cache hits.




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### ⚙️ How It Works

```
Image Layer Stack (overlay2):
+----------------------------------+
| Writable Layer (container only)  | <- upperdir
+----------------------------------+
| Layer 4: COPY app.jar            | <- image
| Layer 3: RUN mvn package         | <- image
| Layer 2: COPY pom.xml            | <- image
| Layer 1: FROM eclipse-temurin:17 | <- image
+----------------------------------+

Registry stores each layer as a blob:
  sha256:a1b2c3... -> Layer 1 (50MB)
  sha256:d4e5f6... -> Layer 2 (2KB)
  sha256:g7h8i9... -> Layer 3 (80MB)
  sha256:j0k1l2... -> Layer 4 (30MB)

Image Manifest (JSON):
  { layers: [sha256:a1.., sha256:d4..],
    config: sha256:xyz... }
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
Dockerfile -> `docker build` -> layers created <- YOU ARE HERE -> image tagged -> pushed to registry -> pulled by runtime -> container created with writable layer on top

**FAILURE PATH:**
Base image has CVE -> scanner detects in CI -> build blocked -> fix: update base image, rebuild, re-push

**WHAT CHANGES AT SCALE:**
At 100+ images, registry storage and network bandwidth matter. Deduplication of shared base layers saves 60-80% storage. At 1000+ nodes pulling simultaneously, you need registry mirrors and image pre-pulling strategies.
---

### 💻 Code Example

```bash
# Inspect image layers
docker history myapp:1.0 --no-trunc

# Check image size breakdown
docker image inspect myapp:1.0 \
  --format '{{.Size}}'

# Dive into layers (using dive tool)
dive myapp:1.0

# Pin to digest (immutable reference)
docker pull myapp@sha256:abc123...

# Check image for vulnerabilities
trivy image myapp:1.0
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

1. Layers are immutable, content-addressed, and shared - this enables caching, deduplication, and reproducibility
2. Order Dockerfile instructions: rarely-changing (base, deps) first, frequently-changing (code) last for cache efficiency
3. Tag images with versions (never rely on `:latest` in production) and pin critical base images by digest

**Interview one-liner:**
"A Docker image is an ordered stack of immutable, content-addressed filesystem layers assembled via union mount - enabling reproducible builds, efficient layer sharing across images, and guaranteed identical behavior from dev through production."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

A `:latest` tag is NOT special in Docker - it's just a convention. It doesn't auto-update, it doesn't mean "newest," and it's not immutable. If someone pushes a different image to the same tag, your `docker pull` gets completely different code. This is why production deployments must use version tags or SHA digests.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Docker Image. Otherwise remove this section.]
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

**Q1: Your production image is 2.1GB. Walk me through how you'd reduce it.**

_Why they ask:_ Tests practical optimization skills and Docker internals knowledge.

**Answer:**
Investigation first:

```bash
# See layer sizes
docker history myapp:latest
# Find large files
docker run --rm myapp:latest \
  du -sh /* 2>/dev/null | sort -rh | head
```

Reduction strategies (ordered by impact):

1. **Multi-stage build** - build in full SDK image, copy only runtime artifacts to slim image (typically 60-80% reduction)
2. **Smaller base image** - `eclipse-temurin:17-jre-alpine` (200MB) vs `ubuntu + JDK` (800MB+)
3. **Distroless** - `gcr.io/distroless/java17` (no shell, no package manager, ~100MB)
4. **Layer consolidation** - combine RUN commands, clean package manager cache in same layer
5. **Remove build artifacts** - test files, documentation, source code
6. **Dependency tree audit** - remove unused transitive dependencies

For a Java app, typical progression: 2.1GB (JDK + Ubuntu) -> 400MB (JRE + Alpine) -> 250MB (distroless) -> 180MB (with dependency audit).

---

**Q2: How do you ensure supply chain security for your container images?**

_Why they ask:_ Tests security maturity and awareness of modern threats (SolarWinds-style attacks).

**Answer:**
Defense layers:

1. **Base image provenance** - use official images, pin by digest, track upstream CVEs
2. **Build integrity** - reproducible builds, signed commits trigger CI, no manual image pushes
3. **Scanning** - Trivy/Grype in CI pipeline, block deployment on critical CVEs
4. **Signing** - cosign/Notary signs images after CI passes, admission controller verifies signatures before deployment
5. **SBOM** - generate with Syft, attach to image, enables CVE notification for deployed images
6. **Runtime** - read-only filesystem, non-root, minimal capabilities

Key: shift-left scanning catches 90% of issues. The remaining 10% requires runtime monitoring (Falco) for zero-day detection.
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

# Dockerfile

**TL;DR** - A Dockerfile is a declarative script defining step-by-step how to build a Docker image from a base, installing dependencies and configuring the application environment.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Building images requires running manual commands in a container, committing the result, and hoping you remember every step. No reproducibility, no version control, no code review of your build process.

**THE BREAKING POINT:**
A new team member can't build the image because the setup steps were in someone's head. The production image was built with an undocumented flag.

**THE INVENTION MOMENT:**
"This is exactly why Dockerfiles were created."

**EVOLUTION:**
Manual image creation -> Dockerfiles (2013) -> Multi-stage builds (2017) -> BuildKit with advanced features (2018+) -> Heredocs, cache mounts, secret mounts (2021+).
---

### 📘 Textbook Definition

A Dockerfile is a text file containing an ordered sequence of instructions that Docker uses to automatically build an image. Each instruction creates a layer in the image, and the complete file describes the transformation from a base image to a fully configured application environment.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
A Dockerfile is the recipe for building a container image.

**One analogy:**

> Like a cooking recipe - start with ingredients (FROM), add seasonings (RUN apt install), add the main dish (COPY app), set the oven temperature (ENV/EXPOSE), and specify how to serve (CMD/ENTRYPOINT).

**One insight:**
Every instruction creates a layer that's cached. If you change line 5, lines 1-4 use cache but 5+ are rebuilt. This is why instruction ordering is critical for build speed.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Instructions execute top-to-bottom, each creating one layer
2. Each layer is cached based on instruction + input hash
3. FROM establishes the base; everything else modifies it

**DERIVED DESIGN:**
The caching model means: put stable things (apt install) early, volatile things (COPY source) late. Multi-stage builds separate build-time from runtime dependencies.

**THE TRADE-OFFS:**
**Gain:** Reproducible builds, version-controlled, cacheable, reviewable
**Cost:** Learning curve for optimization, layer ordering sensitivity, BuildKit feature complexity

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** You must describe how to assemble your environment
**Accidental:** Platform-specific quirks, cache invalidation subtleties, build context confusion
---

### 🧠 Mental Model / Analogy

> A Dockerfile is like assembly instructions for IKEA furniture. Each step (instruction) builds on the previous. If you redo step 5, steps 1-4 don't need redoing. The final product is deterministic - same instructions, same furniture.

- "Instruction manual" -> Dockerfile
- "Starting materials" -> FROM (base image)
- "Assembly steps" -> RUN instructions
- "Adding accessories" -> COPY/ADD files
- "Final setup" -> CMD/ENTRYPOINT

Where this analogy breaks down: you can have multiple instruction manuals (multi-stage) and copy specific parts from one build to another.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
A file that tells Docker how to build an image step by step - what OS to start from, what software to install, what files to include, and what command to run when the container starts.

**Level 2 - How to use it (junior developer):**
Key instructions: `FROM` (base image), `RUN` (execute commands), `COPY` (add files), `WORKDIR` (set directory), `EXPOSE` (document port), `ENV` (set variables), `CMD`/`ENTRYPOINT` (startup command). Always have a `.dockerignore`.

**Level 3 - How it works (mid-level engineer):**
Use multi-stage builds to separate build (SDK, tests, tools) from runtime (JRE only). Use BuildKit features: `--mount=type=cache` for dependency caches, `--mount=type=secret` for build-time secrets. Understand that `CMD` is overridable by `docker run` args but `ENTRYPOINT` isn't (without `--entrypoint`). Use `HEALTHCHECK` for container self-monitoring.

**Level 4 - Mastery (senior/staff+ engineer):**
Optimize for CI cache hit rate: use `COPY --link` (BuildKit) to make layer independent of previous layers. Use heredoc syntax for multi-line scripts without shell escaping. Design base images as a hierarchy: `company-base -> language-base -> app-image`. Monitor layer sizes with `dive`. Implement image-as-code: Dockerfiles in version control, reviewed like application code, with CI enforcing best practices (hadolint linting).




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### ⚙️ How It Works

```dockerfile
# Production-ready Dockerfile example
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests -B

FROM eclipse-temurin:17-jre-alpine AS runtime
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q --spider http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", \
  "-XX:MaxRAMPercentage=75", \
  "-jar", "app.jar"]
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
Write Dockerfile -> `docker build .` <- YOU ARE HERE -> BuildKit parses instructions -> executes layers sequentially -> caches each -> produces final image -> tags and pushes

**FAILURE PATH:**
`RUN` command fails -> build stops at that layer -> debug with `docker run <last-good-layer> sh` -> fix instruction -> rebuild (uses cache up to failure point)

**WHAT CHANGES AT SCALE:**
At team scale: standardize base images, lint Dockerfiles (hadolint), enforce non-root. At org scale: internal base image registry, automated CVE patching of base images, build reproducibility guarantees.
---

### 💻 Code Example

```dockerfile
# BAD: Common anti-patterns
FROM ubuntu:latest              # Unpinned!
RUN apt-get update              # Cached stale
RUN apt-get install -y nodejs   # Separate layer
COPY . /app                     # Invalidates ALL cache
RUN npm install                 # Re-runs every time
CMD node /app/server.js         # Runs as root
```

```dockerfile
# GOOD: Production-grade
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --chown=app:app src/ ./src/
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q --spider \
  http://localhost:3000/health || exit 1
ENTRYPOINT ["node", "src/server.js"]
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

1. Order matters: put rarely-changing instructions (FROM, deps) first, frequently-changing (COPY source) last for cache efficiency
2. Use multi-stage builds: build in SDK image, copy only artifacts to slim runtime image
3. Never run as root: add `USER` instruction; never use `:latest` in FROM

**Interview one-liner:**
"A Dockerfile is a versioned build script where each instruction creates a cached, immutable layer - I optimize by ordering stable layers first for cache hits, using multi-stage builds to separate build dependencies from runtime, and following security best practices like non-root execution and pinned base images."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

`COPY` and `ADD` are NOT the same. `ADD` can extract tarballs and fetch URLs - which makes builds non-reproducible (URL content can change). Docker's own best practices now recommend NEVER using `ADD` unless you specifically need tar extraction. Yet it remains in 90% of tutorial Dockerfiles.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Dockerfile. Otherwise remove this section.]
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

**Q1: Explain the difference between CMD and ENTRYPOINT. When do you use each?**

_Why they ask:_ Commonly confused - tests precise Docker knowledge.

**Answer:**
Both define what runs when the container starts, but they interact differently:

- **ENTRYPOINT** - defines the executable. Not easily overridden (requires `--entrypoint` flag).
- **CMD** - provides default arguments to ENTRYPOINT. Overridden by anything after `docker run <image> [args]`.

Combined pattern:

```dockerfile
ENTRYPOINT ["java", "-jar", "app.jar"]
CMD ["--server.port=8080"]
```

- `docker run myapp` -> runs with port 8080
- `docker run myapp --server.port=9090` -> overrides to 9090
- ENTRYPOINT stays the same both times

Use ENTRYPOINT when your container IS a specific tool/app. Use CMD when you want flexible defaults. Use both for "tool with default flags" pattern.

Shell form (`CMD node app.js`) vs exec form (`CMD ["node", "app.js"]`): exec form doesn't invoke a shell, receives signals directly (important for graceful shutdown with SIGTERM).

---

**Q2: A developer says "my build cache keeps getting invalidated even though I only changed one line of code." What's wrong?**

_Why they ask:_ Tests debugging skills and layer caching understanding.

**Answer:**
Most likely cause: `COPY . /app` appears before `RUN npm install` (or equivalent dependency install).

The cache invalidation cascade: when ANY file in the build context changes (including source code), the `COPY .` layer's hash changes, which invalidates it AND every subsequent layer.

Fix: copy dependency manifests first, install dependencies, THEN copy source:

```dockerfile
# Dependencies rarely change - cached
COPY package.json package-lock.json ./
RUN npm ci

# Source changes frequently - only this rebuilds
COPY src/ ./src/
```

Other common culprits:

- `.dockerignore` missing -> `.git/`, `node_modules/`, IDE files in context
- Timestamp-based changes (git checkout changes mtimes)
- BuildKit vs legacy builder (different cache key calculation)
- Docker Compose with `build.context` too broad
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

# Docker Compose

**TL;DR** - Docker Compose defines and runs multi-container applications from a single YAML file, managing networking, volumes, and dependencies between services.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Running a web app with a database, cache, and message broker requires 4 separate `docker run` commands with complex networking flags, volume mappings, and environment variables. Restarting means remembering the exact order and flags.

**THE BREAKING POINT:**
A developer joins the team and takes 2 days to get the local environment working because the README has 47 steps to run 6 containers with specific flags.

**THE INVENTION MOMENT:**
"This is exactly why Docker Compose was created."

**EVOLUTION:**
Shell scripts with docker commands -> Fig (2013, acquired by Docker) -> Docker Compose v1 (Python, `docker-compose` CLI) -> Docker Compose v2 (Go, `docker compose` subcommand, 2022) -> Compose with watch, build profiles, and includes (2023+).
---

### 📘 Textbook Definition

Docker Compose is a tool for defining and managing multi-container Docker applications using a declarative YAML file (docker-compose.yml). It handles container lifecycle, networking (auto-creates a default network), volume management, and service dependencies from a single configuration.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Compose lets you define your entire multi-container application stack in one file.

**One analogy:**

> Compose is like a restaurant setup checklist. Instead of the chef, dishwasher, and host each setting up independently, one document says: "Start oven first, then prep station, connect them via the pass-through window, and here are today's specials."

**One insight:**
Compose isn't for production orchestration - it's for local development and CI. For production, Kubernetes handles the same problem with vastly more features. Compose's value is simplicity: one command (`docker compose up`) to replicate a production-like environment locally.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. All services defined in one file share a default network (can reach each other by service name)
2. Services can declare dependencies (`depends_on`) for startup ordering
3. Volumes persist data across container restarts

**DERIVED DESIGN:**
By creating a shared network automatically, Compose eliminates manual `--network` flags. By using service names as DNS, it eliminates hardcoded IPs.

**THE TRADE-OFFS:**
**Gain:** One-command local environment, version-controlled infrastructure, reproducible setups
**Cost:** Limited to single-host (no clustering), no self-healing, limited production features

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Multi-container apps need configuration for networking and ordering
**Accidental:** YAML syntax quirks, version confusion (v1 vs v2 vs v3), Compose CLI version differences
---

### 🧠 Mental Model / Analogy

> Compose is like a blueprint for a model train layout. It defines where each piece goes (services), how they connect (networks), and what persists when you pack it away (volumes).

- "Train cars" -> services (containers)
- "Tracks connecting them" -> networks
- "Station storage" -> volumes
- "Layout blueprint" -> docker-compose.yml
- "Setting up the layout" -> `docker compose up`

Where this analogy breaks down: containers can be scaled to multiple instances; model trains can't be duplicated instantly.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
A single file that describes all the containers your app needs and how they connect. Run one command and everything starts together.

**Level 2 - How to use it (junior developer):**
Define services in `docker-compose.yml`. Use `docker compose up -d` to start, `docker compose down` to stop, `docker compose logs -f` to watch. Services talk to each other by service name (e.g., `postgres:5432`).

**Level 3 - How it works (mid-level engineer):**
Use profiles for optional services, health checks for startup ordering (not just `depends_on`), override files for environment-specific config (`docker-compose.override.yml`), `docker compose watch` for hot-reload in development. Understand that `depends_on` only waits for container start, not readiness - use `condition: service_healthy`.

**Level 4 - Mastery (senior/staff+ engineer):**
Design Compose files as development contracts: they define the service topology that mirrors production. Use Compose in CI for integration testing (spin up full stack, run tests, tear down). Separate concerns with `include` (Compose v2.20+) for modular stacks. Understand limitations: no rolling updates, no self-healing, no distributed scheduling - these are why production uses Kubernetes.




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### ⚙️ How It Works

```yaml
# docker-compose.yml - production-like local dev
services:
  api:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DB_URL=jdbc:postgresql://db:5432/app
      - REDIS_URL=redis://cache:6379
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: app
      POSTGRES_PASSWORD: localdev
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5

  cache:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  pgdata:
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
Write docker-compose.yml -> `docker compose up` <- YOU ARE HERE -> Creates network -> Starts services in dependency order -> Services discover each other by name -> Application stack running

**FAILURE PATH:**
Service crashes -> `docker compose ps` shows unhealthy -> `docker compose logs <service>` for diagnosis -> fix code/config -> `docker compose up --build` to rebuild

**WHAT CHANGES AT SCALE:**
Compose doesn't scale. Beyond local dev and CI, you need Kubernetes (distributed scheduling, self-healing, rolling updates, service mesh). Compose's value ceiling is ~20 services on one machine for development.
---

### 💻 Code Example

```bash
# Start everything in background
docker compose up -d

# View running services and health
docker compose ps

# Follow logs from specific service
docker compose logs -f api

# Rebuild and restart one service
docker compose up -d --build api

# Run one-off command in service
docker compose exec db psql -U postgres

# Scale a service (stateless only)
docker compose up -d --scale api=3

# Full teardown including volumes
docker compose down -v
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

1. Compose creates a shared network automatically - services reach each other by service name (DNS)
2. Use `depends_on` with `condition: service_healthy` (not just `service_started`) for reliable ordering
3. Compose is for dev/CI, not production orchestration - Kubernetes handles production concerns

**Interview one-liner:**
"Docker Compose declaratively defines multi-container stacks in YAML - I use it for reproducible local development environments and CI integration tests, with service health checks ensuring proper startup ordering, while production uses Kubernetes for the scaling and resilience features Compose lacks."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

`depends_on` without health checks is almost useless. It only waits for the container to START (PID 1 running), not for the application inside to be READY. Your database container starts in 200ms but takes 5 seconds to accept connections. Without `condition: service_healthy`, your app will crash-loop trying to connect to a not-yet-ready database.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Docker Compose. Otherwise remove this section.]
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

**Q1: How do you handle secrets in Docker Compose without putting them in the YAML file?**

_Why they ask:_ Tests security practices in development environments.

**Answer:**
Multiple approaches:

1. **`.env` file** (basic): `docker-compose.yml` references `${DB_PASSWORD}`, value in `.env` (gitignored)
2. **Docker secrets** (Swarm mode): `secrets:` section references external files
3. **Environment variable substitution**: CI injects vars, Compose interpolates
4. **External secret management**: docker compose with `env_file:` pointing to generated file from vault

Best practice for teams:

```yaml
# docker-compose.yml
services:
  api:
    env_file:
      - .env.local # gitignored, developer-specific
      - .env # committed, non-sensitive defaults
```

Key: `.env.local` in `.gitignore`, `.env.example` committed as template. CI generates its own env file from vault/parameter store.

---

**Q2: Your Compose stack starts but the app can't connect to the database. How do you debug?**

_Why they ask:_ Tests debugging skills with container networking.

**Answer:**
Systematic approach:

```bash
# 1. Check all services are actually running
docker compose ps
# Look for "unhealthy" or "exited" status

# 2. Check if DB is ready (not just started)
docker compose exec db pg_isready -U postgres

# 3. Test network connectivity from app
docker compose exec api \
  wget -q --spider http://db:5432 || \
  echo "Cannot reach db"

# 4. Verify DNS resolution
docker compose exec api nslookup db

# 5. Check environment variables in app
docker compose exec api env | grep DB

# 6. Check logs for the real error
docker compose logs db | tail -20
docker compose logs api | tail -20
```

Common causes:

- DB not ready (needs healthcheck + `condition: service_healthy`)
- Wrong service name in connection string (must match YAML service key)
- Port confusion: use container port (5432), not mapped host port
- Network isolation: services in different Compose files need explicit shared network
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

# Container Orchestration

**TL;DR** - Container orchestration automates deployment, scaling, networking, and lifecycle management of containers across a cluster of machines, with Kubernetes as the dominant solution.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
You have 50 microservices in containers. One crashes at 3 AM - nobody restarts it. Traffic spikes and you need 10 more instances - you SSH into servers and manually run `docker run`. A server dies and 20 containers vanish.

**THE BREAKING POINT:**
Manual container management becomes impossible beyond ~10 containers. You need automatic restart, scaling, load balancing, rolling updates, and service discovery.

**THE INVENTION MOMENT:**
"This is exactly why container orchestration was created."

**EVOLUTION:**
Manual + scripts -> Mesos/Marathon (2013) -> Docker Swarm (2014) -> Kubernetes (2014, from Google's Borg) -> K8s wins (2018+) -> Managed K8s (EKS, GKE, AKS) becomes default -> Serverless containers (Fargate, Cloud Run) for simple workloads.
---

### 📘 Textbook Definition

Container orchestration is the automated management of containerized application lifecycles across distributed infrastructure, handling scheduling (placing containers on appropriate nodes), scaling (adjusting replica counts), networking (service discovery and load balancing), and self-healing (restarting failed containers and rescheduling from failed nodes).
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Orchestration is the autopilot for running containers at scale.

**One analogy:**

> An orchestra conductor doesn't play instruments but ensures every musician plays the right note at the right time, handles someone getting sick (substitute player), adjusts volume for the audience size, and keeps everything in sync. Container orchestration does the same for services.

**One insight:**
The fundamental abstraction is "desired state." You declare "I want 3 replicas of service X" and the orchestrator continuously reconciles reality to match. You never say "start a container" - you say "ensure 3 are running."
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Desired state declaration - you specify WHAT, not HOW
2. Continuous reconciliation - the system detects drift and corrects it
3. Distributed scheduling - containers placed across multiple machines for resilience

**DERIVED DESIGN:**
Because you declare desired state, the system can self-heal (restart failed containers), auto-scale (adjust replicas to load), and perform rolling updates (gradually replace old with new).

**THE TRADE-OFFS:**
**Gain:** Self-healing, auto-scaling, rolling updates, service discovery, resource efficiency
**Cost:** Complexity (networking, storage, RBAC, observability stack), operational overhead, learning curve

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Distributed systems need coordination (scheduling, failure detection, load balancing)
**Accidental:** Kubernetes YAML verbosity, networking plugin choices, storage driver configuration
---

### 🧠 Mental Model / Analogy

> An orchestrator is like an air traffic controller. Planes (containers) need to land on runways (nodes). The controller decides which runway has capacity, handles emergencies (container crashes), reroutes during congestion (load balancing), and ensures safe spacing (resource limits).

- "Air traffic controller" -> orchestrator control plane
- "Planes" -> containers/pods
- "Runways" -> nodes/servers
- "Flight plan" -> deployment manifest (desired state)
- "Radar" -> monitoring/health checks

Where this analogy breaks down: orchestrators can create new planes (auto-scaling), which air traffic controllers definitely cannot do.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Instead of manually starting and managing containers, orchestration software does it automatically - restarting crashed ones, adding more when busy, and balancing work across servers.

**Level 2 - How to use it (junior developer):**
Write a deployment YAML specifying your container image, replica count, and resource limits. Apply it to a Kubernetes cluster. K8s handles scheduling, networking, and restarts. Use `kubectl` to inspect and manage.

**Level 3 - How it works (mid-level engineer):**
The control plane (API server, scheduler, controller manager, etcd) stores desired state and continuously reconciles. The scheduler assigns pods to nodes based on resource requests, affinity rules, and constraints. Kubelet on each node runs the assigned containers. Services provide stable networking endpoints backed by iptables/IPVS rules.

**Level 4 - Mastery (senior/staff+ engineer):**
Orchestration choice is an architecture decision: Kubernetes for complex microservices, ECS/Fargate for simpler workloads, Cloud Run/Lambda for stateless functions. The hidden costs of K8s: operational team, networking expertise (CNI, service mesh), storage complexity (CSI, StatefulSets), and upgrade management. Platform engineering exists because raw K8s is too complex for most developers - the platform team builds golden paths on top.




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### ⚙️ How It Works

```
Kubernetes Architecture:
+----------------------------------+
|        Control Plane             |
| +------+ +--------+ +--------+  |
| | API  | |Scheduler| |Ctrl Mgr| |
| |Server| |        | |        |  |
| +------+ +--------+ +--------+  |
|            +------+              |
|            | etcd |              |
|            +------+              |
+----------------------------------+
        |           |           |
+-------+   +-------+   +-------+
| Node 1|   | Node 2|   | Node 3|
|kubelet|   |kubelet|   |kubelet|
| Pod A |   | Pod B |   | Pod C |
| Pod D |   | Pod E |   | Pod F |
+-------+   +-------+   +-------+
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
Deploy manifest -> API server stores desired state -> Scheduler picks nodes -> Kubelet starts pods <- YOU ARE HERE -> Service routes traffic -> HPA monitors load -> scales up/down automatically

**FAILURE PATH:**
Node dies -> controller detects missing pods -> schedules replacements on healthy nodes -> service endpoint updates -> traffic reroutes (seconds, not minutes)

**WHAT CHANGES AT SCALE:**
At 10 services, orchestration may be overkill (Docker Compose suffices). At 50+, orchestration is essential. At 1000+ pods, etcd performance, scheduler throughput, and network policy complexity require dedicated platform teams.
---

### 💻 Code Example

```yaml
# Kubernetes Deployment (desired state)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-server
  template:
    spec:
      containers:
        - name: api
          image: myapp:1.2.3
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
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

1. Orchestration = desired state + continuous reconciliation (you declare WHAT, it figures out HOW)
2. Kubernetes is the industry standard but has high operational cost - evaluate simpler alternatives (Fargate, Cloud Run) for straightforward workloads
3. Self-healing is the killer feature: crashed containers restart, failed nodes trigger rescheduling, all automatically

**Interview one-liner:**
"Container orchestration automates the full lifecycle - scheduling, scaling, networking, and self-healing - through desired-state declaration and continuous reconciliation, with Kubernetes as the dominant but operationally complex choice, and managed alternatives like Fargate for simpler workloads."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Google ran Borg (Kubernetes' predecessor) for 15 years before open-sourcing Kubernetes in 2014. But Kubernetes is NOT Borg - it's a clean-room reimplementation of Borg's concepts. Borg handles millions of containers at Google; most K8s clusters struggle past 5,000 nodes without significant tuning. The gap between Google's internal system and what the industry runs is still enormous.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Container Orchestration. Otherwise remove this section.]
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

**Q1: Your team is evaluating Kubernetes vs ECS/Fargate vs Cloud Run. What's your decision framework?**

_Why they ask:_ Tests architecture decision-making - not just "K8s is great."

**Answer:**
Decision matrix:

| Factor      | Kubernetes            | ECS/Fargate   | Cloud Run      |
| ----------- | --------------------- | ------------- | -------------- |
| Complexity  | High                  | Medium        | Low            |
| Control     | Full                  | Moderate      | Minimal        |
| Cost (ops)  | 2-3 engineers         | 0.5 engineer  | Near-zero      |
| Scaling     | Manual HPA config     | Built-in      | Automatic      |
| Stateful    | Yes (StatefulSets)    | Limited       | No             |
| Multi-cloud | Yes                   | AWS only      | GCP only       |
| Use case    | Complex microservices | AWS workloads | Stateless APIs |

Choose Kubernetes when: 50+ services, multi-cloud requirement, need service mesh, complex networking, stateful workloads, or strong in-house platform team.

Choose Fargate/ECS when: AWS-only, 10-30 services, want less operational overhead, no custom networking needs.

Choose Cloud Run/Lambda when: stateless request-response workloads, variable traffic (scale-to-zero saves money), small team with no dedicated ops.

The key insight: Kubernetes is only worth it if you have enough services AND enough engineers to justify the operational investment. For 5 services with a 3-person team, K8s is usually over-engineering.

---

**Q2: How does Kubernetes self-healing actually work at the pod level?**

_Why they ask:_ Tests understanding of reconciliation loops and health mechanisms.

**Answer:**
Three layers of self-healing:

1. **Kubelet restart policy** - if PID 1 exits, kubelet restarts the container (with exponential backoff for crash loops)

2. **Liveness probe** - kubelet periodically checks container health. If probe fails N times, kubelet kills and restarts the container:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  failureThreshold: 3
  periodSeconds: 10
```

3. **Controller reconciliation** - the Deployment controller watches replica count. If a pod is evicted (node failure, resource pressure), the controller creates a new pod. Scheduler places it on a healthy node.

Important distinction:

- **Liveness** = "is this container alive?" (restart if not)
- **Readiness** = "can this container serve traffic?" (remove from service endpoints if not, but don't restart)
- **Startup** = "has this container finished starting?" (don't check liveness until startup passes)

The reconciliation loop runs every ~10 seconds. Total recovery time for a node failure: detection (40s default) + rescheduling (seconds) + pull image + startup = typically 1-2 minutes.
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
