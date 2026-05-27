---
layout: default
title: "Docker - L6 Theory"
parent: "Docker and Containers"
nav_order: 8
permalink: /docker/l6-theory/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Container Isolation Formal Models](#container-isolation-formal-models) | high |
| 2 | [OCI Specification Design and Evolution](#oci-specification-design-and-evolution) | medium |

---

# Container Isolation Formal Models

**Interview Weight:** high - This tests theoretical depth. Architects
and staff engineers are expected to understand WHY containers provide
the isolation they do and WHERE that isolation breaks down formally.

---

### 🎯 Model Answer

**30 seconds:**

> Container isolation is implemented via Linux namespaces (visibility
> isolation - each container sees only its own resources) and cgroups
> (resource accounting and limits). Formally: a container is a process
> group where each resource dimension is either namespaced (isolated
> completely) or cgroup-bounded (shared but limited). The isolation
> is a property of the Linux kernel, not of Docker or any container runtime.
> Docker is just tooling for managing these kernel primitives.

**3 minutes (Senior):**

> Container isolation is a composition of Linux namespace isolation and
> cgroup resource control. Understanding the formal model explains both
> what containers isolate and what they do not.
>
> Namespace isolation: Linux has seven namespace types. Each namespace
> provides a distinct view of a specific kernel resource:
> - Mount namespace: visible filesystem tree (each container has its own)
> - PID namespace: visible process IDs (container's PID 1 is not host PID 1)
> - Network namespace: network interfaces, routing tables (each container
>   has its own eth0 with its own IP)
> - UTS namespace: hostname (container can have its own hostname)
> - IPC namespace: System V IPC objects and POSIX message queues
> - User namespace: UID/GID mapping (container root UID 0 maps to
>   unprivileged host UID)
> - cgroup namespace: view of the cgroup hierarchy
>
> A container is a process that has been placed in new instances of all
> these namespaces. The process cannot see resources in other namespaces.
>
> Cgroup resource control: namespaces control visibility (what the process
> can see), but they do not limit consumption. A container process in its
> own PID namespace can still consume 100% of host CPU. Cgroups (control
> groups) impose resource limits: CPU quota (CFS scheduler), memory limit
> (kernel OOM killer), block I/O throttle.
>
> Where isolation fails formally:
> - Kernel shared surface: all containers share the host kernel. A kernel
>   vulnerability can escape namespace isolation. This is why containers
>   are not equivalent to VMs for security.
> - User namespace not enabled: if the container runtime does not use
>   user namespaces, container root UID 0 IS host root UID 0. A container
>   escape gives root on the host.
> - /proc and /sys: some kernel pseudo-filesystems expose host-level
>   information even inside containers. Certain /proc files leak host PID
>   and memory information.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the formal isolation model of
containers - the kernel mechanisms that make containers isolated."

**(2) First principles:** "Isolation requires visibility isolation and
resource isolation. Namespaces provide visibility isolation. Cgroups
provide resource isolation. Together they define what a container is
at the kernel level."

**(3) Bridge:** "Like rooms in a hotel: each room (namespace) is private
and separate. But the hotel has a shared heating system (host kernel)
with a thermostat (cgroup) per room. If the heating system breaks,
all rooms are affected."

---

### 📘 Concept Explanation

**What it is:**
The formal isolation model of containers describes how Linux kernel
mechanisms (namespaces and cgroups) provide resource visibility isolation
and consumption limits to create the container abstraction.

**The problem it solves:**
Understanding the formal model enables predicting where container isolation
holds, where it breaks, and what the security properties of containers
actually are vs VMs.

**How it works:**

```
Seven Linux Namespace Types:

+------------------+---------------------------+
| Namespace        | What it isolates          |
+------------------+---------------------------+
| mnt              | Filesystem mount points   |
| pid              | Process ID number space   |
| net              | Network stack + interfaces|
| uts              | Hostname, domainname      |
| ipc              | SysV IPC, POSIX queues    |
| user             | UID/GID mappings          |
| cgroup           | cgroup hierarchy view     |
+------------------+---------------------------+

Cgroup Resource Control:

CPU: cfs_quota_us / cfs_period_us
  Limits: CPU time per scheduling period
  Enforcement: CFS scheduler throttles when quota exhausted

Memory: memory.limit_in_bytes
  Limits: total RSS + page cache
  Enforcement: kernel OOM killer kills processes over limit

Block I/O: blkio.throttle.{read,write}_bps_device
  Limits: I/O bandwidth per block device
  Enforcement: blkio cgroup throttle

Network: (not natively in cgroups v1)
  Limited via iptables or tc (traffic control)
```

**The key insight:**
Container isolation is software isolation via kernel primitives, not hardware
isolation. All containers share one host kernel. A kernel vulnerability
bypasses ALL namespace isolation simultaneously. VM isolation uses a
hypervisor (hardware virtualization) that provides a separate kernel per
guest - a fundamentally stronger isolation boundary.

**The formal isolation boundary:**

```
VM Isolation:
  +--[Hardware Hypervisor]--+
  |  VM: kernel A           |
  |  VM: kernel B           |
  +------------------------+
  Kernel vulnerability in A
  does NOT affect B

Container Isolation:
  +--[Shared Host Kernel]--+
  |  Container A (ns, cg)   |
  |  Container B (ns, cg)   |
  +------------------------+
  Kernel vulnerability
  can escape BOTH containers
```

**When containers are sufficient vs insufficient:**
Sufficient: multi-tenancy where tenants are trusted (internal microservices).
Insufficient: multi-tenancy with untrusted code (public cloud compute,
SaaS with customer code execution). For untrusted multi-tenancy: use
gVisor (user-space kernel) or Kata Containers (lightweight VMs) for
stronger isolation.

**First-principles derivation:**
"Container" as a concept emerges from the composition of namespace isolation
and cgroup accounting. The namespace provides a view: what the process sees.
The cgroup provides a budget: how much the process can consume. Together,
they create the illusion of isolation. The illusion holds as long as the
shared kernel is uncompromised.

---

### 💻 Code Example

**Example 1: Observing namespace isolation directly**

```bash
# Start a container - observe PID namespace
docker run -d --name demo alpine sleep 1000

# Host view: container processes visible with HOST PIDs
ps aux | grep sleep
# Output: root 12345 alpine sleep 1000 (host PID 12345)

# Container view: PID namespace isolates PIDs
docker exec demo ps aux
# Output: PID 1 sleep 1000 (container PID 1)
# The same process: host sees PID 12345, container sees PID 1

# Network namespace isolation
# Host: container has its own IP
docker inspect demo --format '{{.NetworkSettings.IPAddress}}'
# Output: 172.17.0.2

# Container: eth0 exists inside the namespace
docker exec demo ip addr show eth0
# Output: eth0: inet 172.17.0.2/16

# Mount namespace isolation
docker exec demo ls /
# Output: container's filesystem root (its own mnt namespace)

# cgroup verification
docker exec demo cat /sys/fs/cgroup/memory/memory.limit_in_bytes
# Or on cgroups v2:
docker exec demo cat /sys/fs/cgroup/memory.max
# Shows: 2147483648 (container memory limit = 2 GB)
```

> **Code walkthrough:** This sequence demonstrates namespace isolation
> in action. The same sleep process has PID 12345 on the host but PID 1
> inside the container's PID namespace. The network namespace gives the
> container its own IP address separate from the host. The mount namespace
> gives the container its own root filesystem. The cgroup file shows the
> memory limit enforced by the kernel, readable from inside the container.
> None of these are Docker abstractions - they are direct Linux kernel
> mechanism observations.

**Example 2: Namespace isolation boundary: what leaks**

```bash
# Even inside a container, some host info is visible
# without strict hardening

# /proc/meminfo shows HOST memory (not container limit)
docker run --rm alpine cat /proc/meminfo | head -3
# MemTotal:       65536000 kB  <- HOST total RAM
# Container memory limit is 512MB but sees host 64GB

# Fix: this is why JVM historically read host RAM
# and sized heap incorrectly

# Check user namespace (by default NOT enabled in Docker)
docker run --rm alpine id
# uid=0(root) gid=0(root) - root in container

# Is this host root?
cat /proc/1/status | grep CapEff
# Inside default container: CapEff high bits set = host root!
# Without user namespaces: container root = host root

# With user namespaces (rootless Docker / Podman):
podman run --rm alpine id
# uid=0(root) gid=0(root)  <- STILL root inside container
# But: on host it maps to: uid=100000 (unprivileged)
# Container escape = unprivileged user on host
```

> **Code walkthrough:** /proc/meminfo is NOT namespaced by default in
> Linux (it shows host values). This is why the JVM must read cgroup
> limit files rather than /proc/meminfo for memory detection in containers.
> User namespaces provide UID mapping: root inside the container maps to
> an unprivileged UID on the host. Without user namespaces (the Docker default),
> container root IS host root. This is the core security gap that makes
> container-root = host-root in default Docker setups.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Container isolation is provided by Linux namespaces (process, network,
> filesystem isolation) and cgroups (CPU, memory, I/O limits). Containers
> share the host kernel - they are not VMs. A kernel vulnerability can
> escape container isolation.

*Push deeper:* "The user namespace is the most important namespace for
security. Without user namespace mapping, a container running as root
(UID 0) is the same UID as the host root. With user namespace mapping
(rootless Docker), root in the container maps to an unprivileged user
on the host. Container escape then gives unprivileged access, not host root."

---

**Senior / Staff (5+ years):**

> The formal isolation model defines exactly what containers isolate
> (process visibility, network, filesystem, hostname) and what they do
> not (kernel vulnerabilities, /proc/meminfo, shared kernel attack surface).
>
> For production security assessments, I evaluate the isolation model
> against the workload type. Internal microservices: standard container
> isolation is sufficient. Multi-tenant workloads where tenants provide
> code: Kata Containers (lightweight VM per container) or gVisor (user-space
> kernel) provide stronger isolation at a performance cost.
>
> The cgroup v2 migration is significant for production Java:
> cgroup v2 (unified hierarchy) changed the location of memory limit files.
> Java 8u372+ and Java 11.0.16+ support cgroup v2. Older JDKs read cgroup v1
> paths, find them empty on a cgroup v2 host, and fall back to host memory.

*Push deeper:* "seccomp profiles complement namespace isolation by filtering
system calls. A process in a PID namespace can still make arbitrary syscalls
to the kernel. seccomp restricts the syscall set. RuntimeDefault blocks
~100 high-risk syscalls while permitting all normal Java operations.
The combination (namespace + cgroup + seccomp + capabilities drop) is
defense-in-depth at the kernel level."

---

### ⚖️ Comparison Table

| Isolation Technology | Mechanism | Kernel Shared | Performance | Use Case |
|---|---|---|---|---|
| **Linux containers** | Namespace + cgroup | Yes (host kernel) | ~0% overhead | Trusted multi-tenancy |
| gVisor | User-space kernel (Go) | No (own syscall handler) | 10-30% overhead | Semi-trusted multi-tenancy |
| Kata Containers | Lightweight VM (KVM) | No (own kernel per container) | 5-10% overhead | Untrusted code execution |
| Full VMs | Hypervisor | No (own kernel) | 2-5% overhead | Maximum isolation |

**The deciding factor:** Linux containers for internal services. Kata
or gVisor for workloads executing untrusted code. VMs only when regulatory
or compliance requirements mandate hardware-level isolation.

---

### ⚠️ Common Misconceptions

**"Containers are as secure as VMs."**

VMs use hardware virtualization with a hypervisor providing separate kernels
per guest. A kernel exploit in one VM does not affect other VMs or the host.
Containers share the host kernel. A kernel exploit in one container can
affect all containers on the host and the host itself. The security models
are fundamentally different.

**"Namespace isolation prevents information leakage between containers."**

Not all kernel resources are namespaced. /proc/meminfo, /proc/cpuinfo,
and some /sys paths show host-level information even inside containers.
This is why JVM container detection reads cgroup files, not /proc/meminfo.

**"cgroup limits prevent a container from seeing host resources."**

cgroup limits prevent a container from consuming more than its quota.
They do not prevent the container from seeing (reading) host resource
information from /proc. cgroups and namespaces serve different purposes:
namespaces control visibility, cgroups control consumption.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| JVM reads host memory (no cgroup detection) | JVM heap = 25% of host RAM; OOMKill | `java -XX:+PrintFlagsFinal -version` shows large MaxHeapSize | Upgrade to JDK 11+; add MaxRAMPercentage |
| Root container = host root | Container escape gives host root | `id` inside container = uid=0; no user namespace | Enable rootless Docker; add USER to Dockerfile |
| Shared kernel vulnerability | Container escape CVE (runc, Dirty Pipe) | CVE disclosure against kernel or runc version | Patch host kernel; upgrade runc/containerd |
| seccomp blocks JVM syscall | Container crashes; seccomp audit log | `dmesg | grep seccomp` shows blocked syscall | Add custom seccomp profile; use RuntimeDefault |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Namespaces vs cgroups, containers vs VMs |
| Mid | 6 min | Seven namespace types, cgroup resource types |
| Senior | 10 min | Where isolation breaks, user namespaces |
| Staff | 14 min | gVisor/Kata trade-offs, cgroup v2, seccomp composition |

---

**[MID] Q1 - What is the difference between namespace
isolation and cgroup resource control?**

*Why they ask:* Tests fundamental container theory.

*Likely follow-up:* "What happens if you remove all resource limits?"

Namespace isolation and cgroup resource control solve different problems.

Namespace isolation controls WHAT a container can SEE:
- PID namespace: the container's `ps aux` shows only processes in that namespace
- Network namespace: the container has its own network interfaces
- Mount namespace: the container has its own filesystem view
Without namespaces, all processes on the host would see each other's processes
and filesystems - no separation at all.

cgroup resource control limits HOW MUCH a container can CONSUME:
- CPU: the container can use at most N milliseconds per 100ms period
- Memory: if the container uses more than M bytes, the kernel kills it
- I/O: the container can read/write at most N MB/s from disk
Without cgroups, a container could use 100% of host CPU, exhaust all RAM,
or saturate disk I/O, affecting all other containers.

The combination:
Namespaces: container A cannot see container B's processes (visibility isolated)
cgroups: container A cannot consume all CPU and starve container B (resources limited)

Together they produce the container abstraction. Neither alone is sufficient.

*What separates good from great:* The observation that namespaces control
visibility (what you see) while cgroups control consumption (how much you
use) - the conceptual split that makes the container model coherent.

---

**[STAFF] Q2 - ARCHITECTURE: Why are containers not
equivalent to VMs for security, and when would you
use stronger isolation?**

*Why they ask:* Threat model depth.

*Likely follow-up:* "What is the performance trade-off of Kata Containers?"

The formal security difference:

VM isolation:
  - Each guest has its own kernel (Linux kernel, Windows kernel)
  - The hypervisor (KVM, Xen, VMware) provides hardware virtualization
  - A kernel exploit in one VM does not affect the hypervisor or other VMs
  - Attack surface: the hypervisor itself (much smaller than a kernel)

Container isolation:
  - All containers share the host kernel
  - Namespace + cgroup isolation is enforced by the kernel
  - A kernel vulnerability (Dirty Pipe CVE-2022-0847, runc CVE-2019-5736)
    can bypass namespace isolation
  - Attack surface: the entire Linux kernel

Quantifying the difference:
Linux kernel has ~30 million lines of code. The hypervisor (KVM module)
has ~150,000 lines. The attack surface of containers is 200x larger.

When to use stronger isolation:

Kata Containers (hardware VM per container):
  - Each container runs in a lightweight KVM VM (50ms startup overhead)
  - Full kernel isolation (container exploit cannot escape to host)
  - 5-10% performance overhead (hardware virtualization)
  - Use for: FaaS/serverless, untrusted code execution, PCI DSS requirement

gVisor (user-space kernel):
  - The container's kernel syscalls are intercepted by a Go user-space kernel
  - No shared kernel syscalls to the host (most syscalls are handled in user space)
  - 10-30% performance overhead (syscall interception)
  - Use for: SaaS multi-tenancy where tenants run their own code

Standard containers with seccomp + capabilities:
  - Reduces attack surface from 350+ syscalls to ~50
  - Does not provide full kernel isolation but significantly reduces CVE impact
  - Zero performance overhead
  - Use for: internal microservices with trusted code

*What separates good from great:* The syscall count reduction argument for
seccomp (350+ -> ~50) and the quantitative attack surface difference between
VMs and containers.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Security engineer | Isolation boundaries | What breaks isolation, user namespaces |
| Platform engineer | Practical implications | cgroup v2 detection, JVM impact |
| Staff engineer | Architecture | gVisor vs Kata trade-offs, threat model |
| Academic/theory | Formal model | Namespace taxonomy, cgroup hierarchy |

---
---

# OCI Specification Design and Evolution

**Interview Weight:** medium - Knowing the OCI spec shows deep
understanding of the container ecosystem. Principal engineers
and architects who work on container tooling are expected to know
the OCI boundaries and how they enable interoperability.

---

### 🎯 Model Answer

**30 seconds:**

> The OCI (Open Container Initiative) defines three specifications: the
> Image spec (how container images are formatted), the Distribution spec
> (how images are pushed and pulled from registries), and the Runtime spec
> (how a container runtime executes an image). These three specs mean any
> OCI-compliant image can be stored in any OCI registry and run by any
> OCI runtime. Docker, containerd, and Podman are all OCI-compliant
> implementations.

**3 minutes (Senior):**

> The OCI was formed in 2015 when Docker donated its image format and
> runtime specification to a neutral governance body (Linux Foundation).
> The goal: prevent vendor lock-in in the container ecosystem by specifying
> standard interfaces that tools can implement independently.
>
> The three specs:
>
> Image spec: defines how an OCI image is structured - a JSON manifest
> listing layers, each layer being a content-addressable gzipped tar archive.
> The manifest includes the config blob (which contains environment variables,
> entry point, and ports) and layer digests. Any tool that produces an
> OCI-compliant image can be run by any OCI-compliant runtime.
>
> Runtime spec (runC): defines the container_config.json format that a runtime
> must accept to start a container. This includes namespace configuration,
> cgroup configuration, the root filesystem path, and lifecycle hooks.
> containerd, CRI-O, and Kata Containers all implement this spec.
>
> Distribution spec: standardizes the registry API (originally Docker Registry
> v2). Any OCI-compliant registry exposes push/pull endpoints that OCI clients
> can use. ECR, GCR, GitHub Container Registry, and Harbor all implement this.
>
> The CRI (Container Runtime Interface) relationship: Kubernetes uses CRI to
> communicate with container runtimes. CRI is NOT an OCI spec but a Kubernetes
> extension. CRI implementations (containerd, CRI-O) call OCI runtimes (runC)
> to start containers. This layering (K8s -> CRI -> OCI runtime -> Linux kernel)
> is how Kubernetes achieves pluggability.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about OCI specifications - the standards
that make container tools interoperable."

**(2) First principles:** "Standards enable interoperability. Without OCI,
a Docker image could only run on Docker. With OCI, any compliant image runs
on any compliant runtime. Standards reduce vendor lock-in."

**(3) Bridge:** "Like USB-C: many devices (runtimes) from different manufacturers
accept the same connector (OCI image format). You do not need different tools
for Docker images vs Podman images."

---

### 📘 Concept Explanation

**What it is:**
The Open Container Initiative (OCI) is a set of specifications (Image,
Distribution, Runtime) that standardize the format and lifecycle of
container images and the runtime interface for executing them.

**The problem it solves:**
Before OCI, Docker's proprietary image format and runtime created ecosystem
fragmentation. OCI provides a neutral standard, enabling tool substitution
and preventing lock-in.

**How it works:**

```
OCI Spec Relationships:

  Developer
    |
    | docker build / buildkit / buildah
    v
  OCI Image (layers + manifest + config)
    |
    | push (Distribution API)
    v
  OCI Registry (ECR / Harbor / GHCR)
    |
    | pull
    v
  OCI Runtime (runC / crun / gVisor)
    |
    | config.json (Runtime Spec)
    v
  Linux Kernel (namespaces + cgroups)

Kubernetes CRI Layer:
  kubelet
    |
    | CRI (gRPC)
    v
  containerd / CRI-O (CRI implementation)
    |
    | OCI Runtime Interface
    v
  runC / gVisor / Kata (OCI runtime)
```

**The key insight:**
The CRI-to-OCI boundary is where Kubernetes achieves runtime pluggability.
Kubernetes does not call runC directly - it calls containerd via CRI.
containerd then calls OCI runtimes. This allows replacing the OCI runtime
(e.g., with Kata for VM isolation) without changing Kubernetes.

**When OCI matters for practitioners:**
Using tools beyond Docker (Podman, Buildah, Kaniko, ko).
Building OCI images from non-Docker build systems.
Storing non-container artifacts in OCI registries (SBOM, signatures, Helm charts).

**OCI referrers (added 2023):**
The OCI 1.1 spec added the referrers API: the ability to attach artifacts
to an image manifest. This enables storing SBOMs and Cosign signatures as
OCI artifacts in the same registry as the image, with a standardized
discovery mechanism.

**First-principles derivation:**
Standardization reduces ecosystem coordination costs. Before OCI, adding a
new container runtime required understanding and implementing Docker's
proprietary format. With OCI, a new runtime only needs to implement the
Runtime spec (config.json parsing + Linux namespace/cgroup setup). The
open specification lowered the barrier for competing implementations.

---

### 💻 Code Example

**Example 1: OCI Image structure inspection**

```bash
# Pull and inspect OCI image structure
docker save myapp:latest -o myapp.tar
tar -xf myapp.tar

# OCI Image structure:
# manifest.json - list of layers and config
# <sha256>.json - image config (env, entrypoint)
# <sha256>/   - each layer as a tar archive

# More detailed: use crane (OCI-native tool)
crane manifest myregistry.io/myapp:v1.0.0
# Output: OCI manifest JSON
# {
#   "schemaVersion": 2,
#   "mediaType": "application/vnd.oci.image.manifest.v1+json",
#   "config": {
#     "mediaType": "application/vnd.oci.image.config.v1+json",
#     "digest": "sha256:abc123...",
#     "size": 7023
#   },
#   "layers": [
#     {
#       "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
#       "digest": "sha256:def456...",
#       "size": 32109876
#     }
#   ]
# }

# List OCI referrers (SBOM, signatures)
oras discover myregistry.io/myapp:v1.0.0
# artifact type             digest
# sbom/cyclonedx           sha256:789ghi...
# application/vnd.cosign   sha256:jkl012...
```

> **Code walkthrough:** The OCI image is a collection of content-addressable
> blobs: a manifest JSON file listing the image config and layers, each
> layer as a gzipped tar, and a config JSON blob with runtime metadata.
> All blobs are identified by SHA256 digest. The manifest's digest is the
> image's immutable identity - changing any layer changes the manifest
> digest. oras discover shows OCI referrers: SBOM and Cosign signatures
> attached to the image via the OCI 1.1 referrers API. This standardized
> structure makes the supply chain artifacts (SBOM, signature) portable
> across OCI-compliant registries.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> OCI defines the standard format for container images and how runtimes
> execute them. Docker, Podman, and containerd are all OCI-compliant.
> An image built by Buildah can run with containerd - OCI compatibility
> guarantees this interoperability.

*Push deeper:* "The practical benefit: you can replace Docker in CI with
Buildah (no Docker daemon required, useful for Kubernetes-based CI) and
the resulting image runs on your containerd-based Kubernetes cluster.
OCI compliance is what makes this substitution possible."

---

**Senior / Staff (5+ years):**

> OCI specs are the foundation of container tool interoperability. The
> Distribution spec standardized the registry API so ECR, GCR, Harbor,
> and GitHub Container Registry all work with the same push/pull commands.
>
> The OCI referrers API (1.1 spec, 2023) is the most impactful recent
> evolution. It enables storing arbitrary artifacts (SBOM, signatures,
> provenance attestations) alongside images in any OCI registry. Before
> referrers, teams stored SBOMs in separate S3 buckets with custom tooling.
> With referrers: `cosign sign` and `syft attest` store artifacts in the
> registry, discovered via the referrers API. This makes supply chain
> tooling registry-native.

*Push deeper:* "The CRI-to-OCI layering is important for runtime pluggability
in Kubernetes. When deploying Kata Containers for stronger isolation, you
replace the OCI runtime (runC -> Kata) without touching containerd or
Kubernetes. RuntimeClass in Kubernetes specifies which OCI runtime to use
per pod. This is the extensibility point that lets Kata coexist with standard
containers in the same cluster."

---

### ⚖️ Comparison Table

| OCI Spec | What It Defines | Key Tool Implementations |
|---|---|---|
| **Image Spec** | Layer format, manifest, config blob | docker, buildah, kaniko, ko |
| **Distribution Spec** | Registry push/pull API | ECR, GCR, Harbor, GHCR |
| **Runtime Spec** | config.json for container execution | runC, crun, gVisor, Kata |
| **Referrers API (1.1)** | Artifact attachment to image digest | cosign, syft, oras |

**The deciding factor:** OCI compliance enables tool substitution at each
layer without breaking interoperability. Understanding the spec boundaries
identifies which tools can be exchanged and which cannot.

---

### ⚠️ Common Misconceptions

**"Docker images and OCI images are different formats."**

Docker image format (v2 schema 2) and OCI Image spec are nearly identical
and mutually compatible. Most registries and runtimes accept both.
docker buildx by default builds OCI-compliant images. The formats diverged
slightly in 2015-2016 and have converged since.

**"CRI is part of OCI."**

CRI (Container Runtime Interface) is a Kubernetes API extension, not
an OCI specification. The OCI specifies what a container runtime must
accept (config.json). CRI specifies how Kubernetes talks to container
runtimes (gRPC API). These are different levels: CRI is Kubernetes-specific,
OCI is container-ecosystem-wide.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Image not OCI-compliant | Cannot pull in non-Docker environment | `oras manifest get` shows legacy schema | Rebuild with docker buildx |
| Registry lacks referrers API | Cosign signature cannot be stored | `oras discover` returns empty | Upgrade registry to OCI 1.1 |
| RuntimeClass misconfigured | Kata pod runs on runC instead | `kubectl get pod -o json | grep runtimeclass` | Add RuntimeClass name to pod spec |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 2 min | What OCI is, why it matters |
| Mid | 4 min | Three specs, interoperability implication |
| Senior | 8 min | CRI relationship, referrers API, runtime pluggability |
| Staff | 12 min | SLSA and OCI referrers, RuntimeClass for Kata |

---

**[SENIOR] Q1 - How does the OCI Runtime Spec enable
pluggable container runtimes in Kubernetes?**

*Why they ask:* Architecture understanding of K8s runtime model.

*Likely follow-up:* "How would you deploy Kata Containers for a specific namespace?"

The pluggability chain works through two interfaces:

CRI (Container Runtime Interface) - Kubernetes level:
kubelet communicates with container runtimes via CRI (a gRPC interface).
containerd and CRI-O are CRI implementations. They receive RunPodSandbox
and CreateContainer gRPC calls from kubelet.

OCI Runtime Spec - Container runtime level:
containerd (and CRI-O) spawn container processes by calling OCI runtimes.
They generate a config.json (OCI Runtime Spec format) and pass it to
the OCI runtime binary. The OCI runtime reads config.json and creates
namespaces, cgroups, and starts the container process.

The pluggability point:
containerd supports multiple runtime handlers via RuntimeClass.
RuntimeClass "runc" -> calls runC binary
RuntimeClass "kata-qemu" -> calls kata-runtime binary (starts a KVM VM)
RuntimeClass "gvisor" -> calls runsc binary (gVisor user-space kernel)

All three runtimes speak OCI Runtime Spec. containerd does not need
to know the internals of Kata or gVisor - it only needs to write config.json
and invoke the binary.

Deploying per-namespace:
RuntimeClass is a cluster-scoped resource. Pods specify a runtimeClassName.
To enforce Kata for a namespace, use a Kyverno policy that mutates all
pods in the namespace to add runtimeClassName: kata-qemu.

*What separates good from great:* Understanding that the pluggability
is at the containerd -> OCI runtime boundary (not at the CRI boundary),
and that Kyverno can enforce runtime class per namespace without developer
involvement.

---

**[STAFF] Q2 - TRADE-OFF: What are the implications of
OCI referrers for supply chain tooling? How does it
change how you store and retrieve SBOMs?**

*Why they ask:* Deep OCI knowledge for principal engineers.

*Likely follow-up:* "What registries support OCI 1.1 referrers?"

Before OCI referrers (pre-2023):
SBOM and Cosign signatures were stored as separate OCI artifacts with a
naming convention: image sha256:abc123 -> SBOM tag sha256-abc123.sbom.
Discovery required knowing the naming convention. No standardized API.
Tools needed registry-specific knowledge to discover SBOMs.

With OCI 1.1 referrers API:
The referrers API endpoint (/v2/<name>/referrers/<digest>) returns all
artifacts attached to an image digest.
`oras discover myimage@sha256:abc123` - discovers all referrers.
`cosign sign` - stores signature as a referrer automatically.
`syft attest` - stores SBOM as a referrer automatically.
Discovery is registry-agnostic via the standard API.

Practical implications:
1. Portability: SBOM follows the image wherever it goes (registry replication,
   cross-registry moves). Previously, SBOMs were stored separately and could
   become orphaned.

2. Access control: SBOM access is controlled by registry ACLs on the image
   repository. Previously required separate ACLs for SBOM storage bucket.

3. Audit: a single registry API call discovers all supply chain artifacts
   for any image. Useful for compliance audits: "show me all evidence
   for production image sha256:abc123" -> referrers API returns everything.

Registry support: ECR (partial), GCR, GHCR, Zot, Harbor 2.7+.
ECR support requires OCI referrers flag enabled per repository.

Trade-off: referrers API adoption is still incomplete. Some registries
implement a fallback (tag-based) mechanism. Tools like Cosign handle both.

*What separates good from great:* Knowing the specific registries and
that ECR requires explicit enablement, plus the portability implication
(SBOM travels with the image in registry replication).

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Platform engineer | Tooling | CRI-OCI layering, RuntimeClass |
| Security engineer | Supply chain | Referrers API, SBOM discovery |
| Staff engineer | Architecture | OCI 1.1 evolution, Kata pluggability |
| Academic/researcher | Specification | OCI governance, spec evolution process |
