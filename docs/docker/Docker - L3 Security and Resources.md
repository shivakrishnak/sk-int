---
layout: default
title: "Docker - L3 Security and Resources"
parent: "Docker"
grand_parent: "SK Interview"
nav_order: 9
permalink: /docker/l3-security-and-resources/
---

# Docker - L3 Security and Resources

## Docker Security Hardening Fundamentals

### 🎯 Model Answer

**30 seconds:**
> Docker security: five layers. (1) Image: non-root user, minimal
> base, no secrets in layers. (2) Runtime: `--cap-drop=ALL`,
> `--read-only`, `--no-new-privileges`. (3) Daemon: socket protection,
> rootless mode, content trust. (4) Network: user-defined networks,
> no host mode unless required. (5) Registry: scan images, enforce
> signed images, registry immutability. Each layer is independent:
> a defense-in-depth posture.

**3 minutes (Senior):**
> Runtime security controls: (1) **Linux capabilities**: the full
> capability set includes `CAP_NET_ADMIN` (change routes, iptables),
> `CAP_SYS_PTRACE` (attach to processes), `CAP_SYS_ADMIN` (nearly
> root). Docker default: grants a subset. `--cap-drop=ALL --cap-add=
> NET_BIND_SERVICE`: only keep binding to ports <1024. (2)
> **`--no-new-privileges`**: prevents container processes from gaining
> new privileges via setuid/setgid binaries. Without it: an attacker
> exploiting a setuid binary inside the container gains elevated
> privileges. (3) **Read-only filesystem**: `--read-only --tmpfs /tmp`.
> Container filesystem is immutable. Attacker cannot write scripts
> or modify config. Application must be designed for this: write
> only to tmpfs or mounted volumes. (4) **`--security-opt=no-new-
> privileges`**: same as `--no-new-privileges` for `docker run`.
> In Kubernetes: `securityContext.allowPrivilegeEscalation: false`.
> (5) **Rootless Docker**: the entire Docker daemon runs as a non-root
> user. Container escapes: limited to the daemon user's privileges.
> Trade-offs: some features unavailable (host networking at low ports).
> Production: increasingly adopted for highest-security environments.

**Blank Mind Recovery:**

**(1) Restate:** "Five layers: image, runtime, daemon, network,
registry. Runtime: cap-drop ALL, read-only, no-new-privileges. These
three: standard hardening checklist. For K8s: securityContext mirrors
all of these."

**(2) First principles:** "Principle of least privilege: give each
container exactly the capabilities and access it needs, nothing more.
Defense-in-depth: when one layer fails (app CVE), the attacker hits
the next layer (no write access, no capabilities)."

**(3) Bridge:** "Container security hardening is like a bank vault:
multiple locks. Image security: what's in the vault. Runtime caps:
what the guard can do inside. Read-only filesystem: the vault walls
can't be modified. No-new-privileges: the guard can't pick up
the manager's keys. Rootless daemon: the building itself is not owned
by the vault company."

---

### 📘 Concept Explanation

**Linux capabilities, seccomp, AppArmor, rootless, Kubernetes securityContext:**
```
LINUX CAPABILITIES:

  # View capabilities granted to a running container:
  docker inspect mycontainer | grep -A20 '"CapAdd"'
  # Or inside the container:
  docker exec mycontainer cat /proc/1/status | grep Cap
  # CapPrm: 00000000a80425fb  <- hex bitmask of permitted caps
  
  # Decode:
  capsh --decode=00000000a80425fb
  # cap_chown, cap_dac_override, cap_fowner, cap_kill, cap_net_bind_service, ...
  
  # Default Docker capabilities (subset of root, but still significant):
  # cap_chown: change file ownership
  # cap_dac_override: bypass file permission checks
  # cap_net_bind_service: bind to ports <1024
  # cap_net_raw: raw socket (used for ping, also by network attack tools)
  # cap_setuid, cap_setgid: change process uid/gid
  
  # Minimal hardening: drop all, add back only what's needed:
  docker run \
    --cap-drop=ALL \
    --cap-add=NET_BIND_SERVICE \
    --no-new-privileges \
    myapp
  
  # For most web apps: NET_BIND_SERVICE not needed if running on port > 1024.
  # Truly minimal: docker run --cap-drop=ALL --no-new-privileges myapp

SECCOMP PROFILES:

  # seccomp: syscall filtering. Blocks specific Linux system calls.
  # Docker default: applies a seccomp profile blocking ~60+ dangerous syscalls.
  # (kexec_load, reboot, mount, etc.)
  
  # Check if seccomp is enabled:
  docker inspect mycontainer | grep -i seccomp
  
  # Custom restrictive seccomp profile:
  cat > seccomp-profile.json <<'EOF'
  {
    "defaultAction": "SCMP_ACT_ERRNO",
    "syscalls": [
      {
        "names": ["read", "write", "close", "stat", "fstat",
                  "mmap", "mprotect", "munmap", "brk", "ioctl",
                  "access", "exit_group", "futex", "gettid",
                  "getpid", "clock_gettime", "nanosleep",
                  "openat", "socket", "connect", "accept",
                  "sendto", "recvfrom", "sendmsg", "recvmsg",
                  "shutdown", "bind", "listen", "getsockname",
                  "getpeername", "setsockopt", "getsockopt",
                  "clone", "execve", "wait4", "kill", "sigaltstack",
                  "rt_sigaction", "rt_sigprocmask", "rt_sigreturn",
                  "pread64", "pwrite64", "readv", "writev",
                  "pipe2", "epoll_create1", "epoll_ctl", "epoll_wait",
                  "prctl", "arch_prctl", "set_tid_address",
                  "set_robust_list", "rseq"],
        "action": "SCMP_ACT_ALLOW"
      }
    ]
  }
  EOF
  
  docker run --security-opt seccomp=seccomp-profile.json myapp
  # Only the listed syscalls are allowed. All others: EPERM.

APPARMOR PROFILES:

  # AppArmor: Mandatory Access Control (MAC). Path-based policies.
  # Docker default: applies docker-default AppArmor profile.
  
  # Check active AppArmor profile:
  docker inspect mycontainer | grep AppArmorProfile
  # "AppArmorProfile": "docker-default"
  
  # Custom AppArmor profile (restrict file writes):
  #include <tunables/global>
  profile myapp-profile flags=(attach_disconnected,mediate_deleted) {
    # Deny all network raw sockets:
    deny network raw,
    deny network packet,
    
    # Allow read of app files:
    /app/** r,
    # Allow write only to /tmp:
    /tmp/** rw,
    deny /etc/** w,
    deny /var/** w,
  }
  
  # Load: apparmor_parser -r myapp-profile
  # Apply: docker run --security-opt apparmor=myapp-profile myapp

READ-ONLY FILESYSTEM:

  # container filesystem is immutable:
  docker run \
    --read-only \
    --tmpfs /tmp \
    --tmpfs /var/run \
    myapp
  
  # --tmpfs /tmp: in-memory writable filesystem for temp files.
  # --tmpfs /var/run: for PID files and unix sockets.
  
  # Application requirements for read-only mode:
  # 1. All runtime writes must go to mounted volumes or tmpfs.
  # 2. No writing to config files in /etc.
  # 3. No log files written to /var/log (use stdout/stderr instead).
  
  # In Docker Compose:
  services:
    app:
      read_only: true
      tmpfs:
        - /tmp
        - /var/run
      volumes:
        - appdata:/data  # persistent writable data

KUBERNETES SECURITY CONTEXT:

  # Pod-level security context:
  spec:
    securityContext:
      runAsNonRoot: true      # fail if container runs as root
      runAsUser: 1000         # explicit UID
      runAsGroup: 1000        # explicit GID
      fsGroup: 1000           # volumes owned by this group
      seccompProfile:
        type: RuntimeDefault  # default seccomp
    
    containers:
      - name: myapp
        securityContext:
          allowPrivilegeEscalation: false  # no-new-privileges
          readOnlyRootFilesystem: true     # read-only
          capabilities:
            drop: ["ALL"]                  # drop all caps
            add: []                        # add none back

DOCKER SOCKET SECURITY:

  # /var/run/docker.sock: if mounted inside a container -> root on host.
  # Docker API: full control over the Docker daemon.
  # An attacker with access to docker.sock: can run privileged containers,
  # mount the host filesystem, escape the container entirely.
  
  # BAD: mounting docker.sock (common for CI agents, but dangerous):
  docker run -v /var/run/docker.sock:/var/run/docker.sock dind
  
  # If you MUST give Docker socket access (DinD, CI agents):
  # Use a Docker socket proxy (Tecnativa/docker-socket-proxy):
  # Limits which API endpoints are accessible.
  # Only exposes: /containers/*, /images/* (not /exec, not /swarm).
  
  # Or: use rootless Docker / kaniko / buildah for CI:
  # No Docker socket access needed.
```

---

### 💻 Code Example

> **Code walkthrough:** A hardened `docker run` command and its
> Kubernetes security context equivalent.

```bash
# BAD: default docker run (all Docker defaults, some are too permissive):
docker run myapp
# Root user (if no USER in Dockerfile).
# Cap_net_raw: can send raw packets (ping + network probing tools).
# Can write to entire container filesystem.
# Can escalate via setuid binaries.

# GOOD: hardened docker run:
docker run \
  --user 1000:1000 \           # non-root UID:GID
  --cap-drop=ALL \             # drop ALL Linux capabilities
  --no-new-privileges \        # no privilege escalation
  --read-only \                # immutable container filesystem
  --tmpfs /tmp:size=50m \      # writable temp dir (RAM, limited size)
  --security-opt seccomp=default \ # default Docker seccomp profile
  --memory=256m \              # OOM protection (next section)
  --cpus=0.5 \                 # CPU limit
  --pids-limit=50 \            # limit process count (fork bombs)
  -p 127.0.0.1:3000:3000 \    # bind to localhost only (not 0.0.0.0)
  myapp:1.2.3
```

> **Code walkthrough:** Each flag addresses a specific attack vector.
> `--cap-drop=ALL`: removes all 37 Linux capabilities; an attacker
> with RCE cannot use networking, file ownership changes, or process
> inspection. `--no-new-privileges`: prevents exploitation of setuid
> binaries (like `sudo` or `su` if they exist in the image).
> `--read-only`: even with code execution, the attacker cannot write
> scripts, modify config, or install tools on the container filesystem.
> `--pids-limit=50`: prevents a fork bomb from consuming the host.
> `-p 127.0.0.1:3000:3000`: only accessible from the host's loopback
> (useful for services behind a reverse proxy on the same host).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Docker security basics: run as non-root (`USER` in Dockerfile),
> don't store secrets in images, use user-defined networks (not host
> mode), scan images with Trivy. Keep base images minimal.

---

**Senior / Staff (5+ years):**
> Defense in depth across five layers is the production security model.
> Image hardening: non-root, minimal base, no secrets, distroless.
> Runtime: cap-drop, no-new-privileges, read-only. These runtime
> controls are the second line of defense: if a CVE in the application
> gives RCE, the attacker hits cgroup limits, capability restrictions,
> and a read-only filesystem. In Kubernetes: PSP (deprecated) is
> replaced by Pod Security Admission (PSA). Enforce the `restricted`
> profile in production namespaces: it enforces all of the above.
> `kubectl label namespace production pod-security.kubernetes.io/enforce=restricted`.
> Teams with legacy workloads that don't pass `restricted`: use
> `baseline` (no privileged, no hostPath, no host network) as an
> intermediate step.

---

### ⚠️ Common Misconceptions

**Misconception: "Containers are secure by default because they're isolated."**
Container isolation (namespaces + cgroups) provides process-level
isolation, not VM-level isolation. The kernel is shared. A container
kernel exploit (not application exploit): can break out to the host.
Historical CVEs: CVE-2019-5736 (runc), Dirty Pipe (CVE-2022-0847),
cgroups namespace escape. Container isolation is strong but not
equivalent to a VM's hardware boundary. The Linux capabilities granted
by default are significant: `cap_net_raw` enables network probing
from inside the container, `cap_sys_chroot` enables filesystem pivots.
The security posture of a container depends entirely on what you
configure. Default settings are a starting point, not a security
guarantee. The hardening checklist: cap-drop, no-new-privileges,
read-only, seccomp, non-root. These must be explicitly applied.

---

### ⚖️ Comparison Table

| Security Control | What It Prevents | Performance Impact | Complexity |
|---|---|---|---|
| Non-root user | Post-exploitation escalation | Zero | Low |
| cap-drop ALL | Capability-based escalation | Negligible | Low |
| --no-new-privileges | setuid escalation | Negligible | Low |
| Read-only filesystem | Post-exploitation writes | Zero | Medium |
| seccomp | Dangerous syscall exploitation | <1% CPU | Medium |
| AppArmor | File access, network raw | <1% CPU | High |
| Rootless Docker | Daemon compromise → host escape | Low-medium | High |

---

### 🏛️ System Design

*(Omit: security hardening is operational configuration, not system architecture.)*

---

### 📊 Diagram

*(Omit: security controls are enumerated clearly in the concept explanation above.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Container exits immediately after adding --cap-drop=ALL.**
```
Symptom: Container starts then exits with "Operation not permitted"
  or "Permission denied" errors in docker logs.
  Or: application works without --cap-drop but exits with it.

Root cause: application requires a specific Linux capability
  that was dropped. Common examples:
  - ping: requires cap_net_raw (raw socket)
  - Binding to port 80: requires cap_net_bind_service
  - chown: requires cap_chown
  - Setting process priority (nice): requires cap_sys_nice

Diagnosis:
  # Run with --cap-drop=ALL and check the error:
  docker run --cap-drop=ALL myapp 2>&1 | head -20
  # "bind: address already in use" + port < 1024 -> add cap_net_bind_service
  # "Operation not permitted" in app logs -> capability check
  
  # Run strace to find which syscall fails:
  docker run --cap-add=SYS_PTRACE --cap-drop=ALL myapp strace myapp 2>&1 | grep EPERM
  # Shows exact syscall that returned EPERM.
  
  # Check capability requirements with capsh:
  docker run --cap-drop=ALL myapp capsh --print
  # Shows current + available capabilities in the container.

Fixes:
  # Add back ONLY the required capability:
  docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE myapp
  
  # Better: avoid needing the capability:
  # Instead of binding to port 80 (requires NET_BIND_SERVICE):
  # Bind to port 3000, use reverse proxy (nginx, Kubernetes Service) for 80.
  # No capability needed. Cleaner architecture.
  
  # For healthchecks that use ping:
  # Replace ping with curl or nc (TCP check) - no cap_net_raw needed.
  HEALTHCHECK CMD nc -z localhost 3000 || exit 1
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Linux capabilities in Docker | 2 minutes |
| --no-new-privileges | 1 minute |
| Read-only filesystem | 1 minute |
| Docker socket security risk | 2 minutes |
| seccomp profile purpose | 1 minute |
| Kubernetes securityContext | 2 minutes |
| cap-drop breaks app: diagnosis | 1 minute |

---

**Q1 (security): A developer asks why their container can't ping other services after you added cap-drop=ALL. How do you explain and resolve it?**

A: `ping` uses raw sockets (`SOCK_RAW`) which require the `CAP_NET_RAW`
capability. `--cap-drop=ALL` removes this. The intent: raw sockets
can be used for network scanning, crafting malicious packets, and
ARP spoofing. Removing `cap_net_raw`: prevents this attack vector.
Resolution options: (1) Add back only `cap_net_raw` if ping is
genuinely needed: `--cap-add=NET_RAW`. (2) Better: replace ping with
a TCP connectivity check: `nc -z hostname port` or `curl -o
/dev/null http://hostname:port`. These use TCP sockets (no raw
socket required). `nc -z` just tests if the port is open: more
useful than ping (confirms the service is listening, not just the
host is reachable). (3) For healthchecks: `HEALTHCHECK CMD curl -sf
http://service:port/health || exit 1`. No ping, no raw socket.
The underlying lesson: remove the capability, fix the tool, not the
capability check.

*What separates good from great:* In Kubernetes production clusters,
add a PodSecurity admission webhook that enforces `restricted` policy.
This automatically blocks `cap_net_raw` in all pods in the
`production` namespace. Developers get a clear error when trying to
deploy a container that needs raw sockets. This creates a feedback
loop: developers learn to design for minimal capabilities because
deployment fails otherwise. The policy as code: much more effective
than a guideline document.

---

---

## Container Resource Limits and Quotas

### 🎯 Model Answer

**30 seconds:**
> Resource limits: memory (`--memory`), CPU (`--cpus`), and PID
> (`--pids-limit`). Without limits: a single container can consume
> all host resources (OOM, CPU starvation). Memory: if container
> exceeds the limit, the Linux OOM killer terminates it. CPU: hard
> limit (`--cpus`) or shares (`--cpu-shares`). In Kubernetes:
> `resources.requests` (scheduling) and `resources.limits` (enforcement).

**3 minutes (Senior):**
> Memory and CPU interaction: (1) **Memory limits**: `--memory=256m`
> sets the hard limit. OOM killer: terminates the container if
> exceeded. In Kubernetes: `limits.memory: 256Mi`. JVM: auto-detects
> cgroup memory limit with `-XX:+UseContainerSupport` (JDK 10+).
> Without this flag: JVM sizes its heap based on total host memory
> (not the container limit). A 256MB container + 64GB host = JVM
> thinks it has 64GB. Sets heap to ~16GB. First GC: OOM kill.
> (2) **Memory reservation**: `--memory-reservation=128m` is a soft
> limit. Docker tries to stay below this when the host is under
> memory pressure. No hard OOM kill. (3) **CPU**: `--cpus=0.5`
> gives the container at most 0.5 CPU cores. `--cpu-shares=512` is
> relative priority (1024 = 1x, 512 = 0.5x relative to 1024 default).
> CPU throttling (vs OOM): container is throttled (paused), not killed.
> Application: responds slowly under CPU throttle. (4) **Kubernetes
> QoS classes**: Guaranteed (request=limit), Burstable (request<limit),
> BestEffort (no request/limit). OOM kill order: BestEffort first,
> then Burstable, then Guaranteed.

**Blank Mind Recovery:**

**(1) Restate:** "Memory: hard limit, OOM kill if exceeded. JVM:
must use UseContainerSupport. CPU: hard cpus limit or cpu-shares
(relative priority). PID limit: fork bomb protection. K8s: requests
(scheduling) + limits (enforcement). QoS classes: Guaranteed last
to be OOM killed."

**(2) First principles:** "The host has finite resources. Without
limits: any container can starve others. Limits: guarantee resource
isolation. JVM was designed before containers: it reads /proc/meminfo
(host). Container limits via cgroup: JVM must be told to read cgroup
instead."

**(3) Bridge:** "Container resource limits are like a data plan.
Memory limit: your monthly data cap (OOM kill = service cut off).
CPU limit: your network speed cap (throttling = slower, not cut off).
Without a plan limit: you share the building's internet and one
person's 4K video streaming kills everyone else's connection."

---

### 📘 Concept Explanation

**Memory, CPU, PID, JVM container awareness, K8s requests/limits:**
```
MEMORY LIMITS:

  # Set hard memory limit:
  docker run --memory=256m myapp
  # Container can use up to 256MB RAM.
  # Exceeds limit: Linux OOM killer terminates the process.
  # Container exits with OOM kill status.
  
  # Set soft memory limit (reservation):
  docker run --memory=512m --memory-reservation=256m myapp
  # Hard: 512MB. Soft: 256MB (Docker tries to keep under this when host is busy).
  
  # Check memory usage:
  docker stats mycontainer --no-stream
  # MEM USAGE / LIMIT: 128MiB / 256MiB (50%)
  
  # Check OOM kills:
  docker inspect mycontainer | grep OOMKilled
  # "OOMKilled": true  <- memory limit was hit

JVM CONTAINER AWARENESS:

  # Problem: JVM reads /proc/meminfo for heap sizing. Pre-JDK 10.
  # /proc/meminfo: reports HOST total memory (e.g., 64GB).
  # JVM: sizes heap to 1/4 of total. 64GB / 4 = 16GB heap.
  # Container limit: 512MB. JVM tries to allocate 16GB. OOM kill immediately.
  
  # Check JVM heap sizing:
  docker exec mycontainer java -XX:+PrintFlagsFinal -version \
    | grep -i heapsize
  # InitialHeapSize = 1073741824  <- 1GB. BAD if container limit is 512MB.
  
  # Fix: add -XX:+UseContainerSupport (JDK 10+ enables by default):
  docker run --memory=512m myapp \
    java -XX:+UseContainerSupport \
         -XX:MaxRAMPercentage=75.0 \
         -jar app.jar
  # -XX:+UseContainerSupport: JVM reads cgroup memory limit (512MB).
  # -XX:MaxRAMPercentage=75.0: heap = 75% of container limit.
  # 512MB * 75% = 384MB heap. 128MB left for: JVM overhead, threads, etc.
  
  # Default in JDK 10+: UseContainerSupport is ON.
  # But MaxRAMPercentage defaults to 25%. Wastes 75% of container memory.
  # Always set MaxRAMPercentage explicitly.

CPU LIMITS:

  # Hard CPU limit (CFS bandwidth control):
  docker run --cpus=0.5 myapp
  # Container gets at most 0.5 CPU cores.
  # Implementation: Linux CFS quota. 50ms quota per 100ms period.
  # During heavy load: container is paused after using 50ms CPU per 100ms.
  # Latency-sensitive apps: CPU throttling causes tail latency spikes.
  
  # CPU shares (relative priority, no hard limit):
  docker run --cpu-shares=512 myapp  # default is 1024
  # When host CPU is busy: this container gets 512/(512+1024) = 33% of CPU.
  # When host CPU is idle: this container can use 100% of CPU.
  # No throttling at low load. Only affects contention.
  
  # Check CPU throttling:
  docker exec mycontainer cat /sys/fs/cgroup/cpu/cpu.stat
  # nr_throttled: number of throttle events.
  # throttled_time: total nanoseconds throttled.
  # High values: app is being throttled. Increase --cpus.

PID LIMITS:

  # Prevent fork bombs:
  docker run --pids-limit=50 myapp
  # Container can have at most 50 processes.
  # Fork bomb: process forks infinitely -> exhausts host PID table.
  # PID limit: contains the damage to 50 PIDs.
  
  # Check current PID count:
  docker exec mycontainer cat /proc/loadavg | awk '{print $4}'
  # Or: docker exec mycontainer ps aux | wc -l

KUBERNETES REQUESTS AND LIMITS:

  # requests: used by the Kubernetes scheduler (node selection).
  # limits: enforced by cgroups (hard limit).
  
  spec:
    containers:
      - name: myapp
        resources:
          requests:
            memory: "128Mi"    # Scheduler: needs a node with 128Mi free
            cpu: "100m"        # Scheduler: needs 0.1 CPU core available
          limits:
            memory: "256Mi"    # OOM kill if container uses > 256Mi
            cpu: "500m"        # Throttled if container uses > 0.5 CPU
  
  # 1000m = 1 core. 100m = 0.1 core.
  # QoS classes:
  # Guaranteed: requests == limits (most stable, last OOM-killed)
  # Burstable: requests < limits (can burst to limit)
  # BestEffort: no requests or limits (first OOM-killed)
  
  # Production rule: always set both requests AND limits.
  # Guaranteed for critical services (request=limit).
  # Burstable for scalable services (small request, reasonable limit).
  
  # Namespace resource quotas:
  apiVersion: v1
  kind: ResourceQuota
  metadata:
    name: production-quota
    namespace: production
  spec:
    hard:
      requests.cpu: "10"        # total CPU requests in namespace
      requests.memory: "20Gi"   # total memory requests
      limits.cpu: "20"          # total CPU limits
      limits.memory: "40Gi"     # total memory limits
      pods: "100"               # max pods in namespace

MONITORING RESOURCE LIMITS:

  # Docker stats (real-time):
  docker stats  # all containers
  docker stats myapp --no-stream --format \
    "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
  
  # Check if OOM killed:
  docker inspect myapp | python -m json.tool | grep -i oom
  
  # Kubernetes:
  kubectl top pods -n production
  # NAME          CPU(cores)   MEMORY(bytes)
  # myapp-abc     45m          89Mi
  
  kubectl describe pod myapp-abc-xyz | grep -A5 "Limits\|Requests"
  
  # OOM events in Kubernetes:
  kubectl get events --field-selector reason=OOMKilling -A
  # Or in pod describe:
  kubectl describe pod myapp-abc-xyz | grep -i oom
```

---

### 💻 Code Example

> **Code walkthrough:** Diagnosing and fixing JVM heap misconfiguration
> in a containerized Spring Boot application.

```bash
# Symptom: Spring Boot pod OOM killed shortly after startup.
# Container memory limit: 512Mi. Pod keeps restarting.

# STEP 1: Check if OOM kill is the cause:
kubectl describe pod myapp-xyz | grep -A3 "Last State"
# Last State: Terminated
#   Reason: OOMKilled  <- confirmed

# STEP 2: Check what JVM thinks heap size is:
kubectl exec myapp-xyz -- java -XX:+PrintFlagsFinal \
  -XX:+UseContainerSupport -version 2>&1 | grep -i "heapsize\|ram"
# MaxHeapSize = 4294967296  <- 4GB! (reading host memory 16GB / 4)
# UseContainerSupport = false  <- not enabled!

# STEP 3: Check the current JVM launch command:
kubectl exec myapp-xyz -- cat /proc/1/cmdline | tr '\0' ' '
# java -jar app.jar
# No JVM memory flags. JVM uses host-based defaults.

# STEP 4: Fix - add container-aware JVM flags:
# In Kubernetes deployment:
spec:
  containers:
    - name: myapp
      image: myapp:1.2.3
      resources:
        requests:
          memory: "256Mi"
          cpu: "200m"
        limits:
          memory: "512Mi"  # hard limit
          cpu: "1000m"
      env:
        - name: JAVA_TOOL_OPTIONS
          value: >-
            -XX:+UseContainerSupport
            -XX:MaxRAMPercentage=75.0
            -XX:+ExitOnOutOfMemoryError
# -XX:MaxRAMPercentage=75.0: heap = 75% of 512Mi = 384Mi.
# -XX:+ExitOnOutOfMemoryError: clean crash instead of thrashing.
# JAVA_TOOL_OPTIONS: picked up by JVM automatically (no Dockerfile change).
```

> **Code walkthrough:** `JAVA_TOOL_OPTIONS` is a standard environment
> variable that the JVM reads on startup. It doesn't require modifying
> the Dockerfile or the startup command. `UseContainerSupport` tells
> the JVM to read the cgroup memory limit (`/sys/fs/cgroup/memory/
> memory.limit_in_bytes`): gets 512MB, not 16GB from `/proc/meminfo`.
> `MaxRAMPercentage=75.0` sets heap to 384MB, leaving 128MB for: JVM
> class metadata (Metaspace), JIT compiled code cache, thread stacks,
> and OS overhead. `ExitOnOutOfMemoryError`: the process exits cleanly
> instead of running indefinitely in a degraded state (Kubernetes
> then restarts the pod).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Always set resource limits for containers. `--memory=512m` prevents
> one container from using all available RAM. `--cpus=0.5` limits CPU.
> For Java apps: add `-XX:+UseContainerSupport -XX:MaxRAMPercentage=
> 75.0` so the JVM reads the container memory limit, not the host total.

---

**Senior / Staff (5+ years):**
> CPU throttling is the hidden performance killer. A container with
> `--cpus=0.5` will be throttled at 50ms per 100ms period. Under load:
> 50% of the time is wait time. For microservices: this manifests
> as P99 latency spikes during throttle events. `docker exec myapp
> cat /sys/fs/cgroup/cpu/cpu.stat` shows `nr_throttled` and
> `throttled_time`. High values: increase the CPU limit or optimize
> the application. In Kubernetes: right-size CPU limits using `kubectl
> top pods` data from production load, not estimates. Over-provisioned
> limits: waste cluster capacity. Under-provisioned: cause throttling.
> Tools: VPA (Vertical Pod Autoscaler) in recommendation mode: observes
> actual usage, recommends correct requests and limits.

---

### ⚠️ Common Misconceptions

**Misconception: "Setting a memory limit prevents the container from using more than that amount of RAM."**
The memory limit controls Linux cgroup memory accounting. What counts
toward the limit: anonymous memory (heap, stack), memory-mapped files,
and page cache. What often does NOT count as expected: shared memory
segments between processes, kernel memory in some configurations,
and memory that the OS has already reclaimed into the page cache.
A Java process: the heap is counted, the JVM native (Metaspace,
code cache, thread stacks) is also counted but often underestimated.
A 512MB Java container with `MaxHeapSize=384MB`: the remaining 128MB
must cover Metaspace (~100MB for Spring Boot), code cache (~50MB),
thread stacks (1MB per thread * 50 threads = 50MB). Total: 600MB.
OOM kill. The fix: either increase the limit or tune Metaspace/code
cache: `-XX:MetaspaceSize=64m -XX:MaxMetaspaceSize=100m
-XX:ReservedCodeCacheSize=64m`. Monitor `jstat -gcutil <pid>` for
actual Metaspace usage.

---

### ⚖️ Comparison Table

| Limit Type | Effect of Exceeding | Kubernetes Equivalent | Recovery |
|---|---|---|---|
| --memory | OOM kill (exit) | limits.memory | Container restart |
| --memory-reservation | Best-effort throttle | requests.memory | Gradual |
| --cpus | CPU throttle (pause) | limits.cpu | Automatic (throttle lifted) |
| --cpu-shares | Lower priority under contention | requests.cpu (approx) | Automatic |
| --pids-limit | New fork fails | Pod security policy | Manual |

---

### 🏛️ System Design

*(Omit: resource limits are operational configuration, not architecture.)*

---

### 📊 Diagram

*(Omit: resource limit mechanics are clearest in the annotated code above.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Node is under memory pressure, evicting pods unexpectedly.**
```
Symptom: Kubernetes evicts pods on a node. Not OOMKilled.
  kubectl get events shows "Evicted" reason.
  Node: 80%+ memory used.

Root cause: no resource requests set (BestEffort QoS).
  Kubernetes scheduler: places more pods on the node than it can handle.
  Node pressure: kubelet evicts BestEffort pods first.
  If requests set but limits much higher: pods burst above requests.
  Node: actual usage > total requests = evictions.

Diagnosis:
  kubectl describe node mynode | grep -A20 "Allocated resources"
  # CPU requests: 8/16 cores (50%)
  # Memory requests: 25Gi/32Gi (78%)  <- over-allocated
  
  kubectl get events --field-selector involvedObject.kind=Pod \
    --field-selector reason=Evicted -A
  
  kubectl describe pod myapp-xyz | grep -A5 "QoS Class"
  # QoS Class: BestEffort  <- no limits/requests set

Fix:
  Option 1: set requests and limits on all pods.
  Option 2: use LimitRange to set default limits per namespace:
  
  apiVersion: v1
  kind: LimitRange
  metadata:
    name: default-limits
    namespace: production
  spec:
    limits:
      - default:          # default limits if not specified:
          memory: "256Mi"
          cpu: "500m"
        defaultRequest:   # default requests if not specified:
          memory: "128Mi"
          cpu: "100m"
        type: Container
  
  # LimitRange: any pod without explicit limits gets these defaults.
  # No more BestEffort QoS in the namespace.
  
  Option 3: use VPA (Vertical Pod Autoscaler) in recommend mode
  to suggest appropriate requests based on actual usage.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Memory limit OOM kill | 1 minute |
| JVM container awareness | 2 minutes |
| CPU throttle vs OOM kill | 2 minutes |
| K8s requests vs limits | 2 minutes |
| QoS classes | 2 minutes |
| Node memory pressure + eviction | 2 minutes |
| LimitRange default limits | 1 minute |

---

**Q1 (production): How do you right-size CPU and memory requests and limits for a production Kubernetes deployment?**

A: Data-driven process with three steps. (1) **Measure first**:
deploy without limits (or with very high limits) using VPA in
recommendation-only mode. After 2 weeks of production traffic: VPA
has observed actual resource usage under load. `kubectl describe vpa
myapp-vpa` shows recommended requests and limits based on P95 and
P99 observed usage. (2) **Set conservative limits**: set memory limit
to 1.5-2x the P99 observed usage (headroom for traffic spikes).
Set CPU limit to 2x P99 CPU usage (CPU throttling is recoverable,
but headroom is important for latency). Set requests to P50 observed
usage (used for scheduling; nodes need enough requested capacity to
place the pod). (3) **Monitor and tune**: after applying limits, watch
`nr_throttled` in CPU stats and OOM events. If throttling is high:
increase CPU limit. If OOM events occur: increase memory limit. Repeat
every 3 months or after significant traffic changes.

*What separates good from great:* The P99 latency impact of CPU
throttling. CFS (Completely Fair Scheduler) CPU throttling: when a
container hits its quota (e.g., 50ms in 100ms), the Linux scheduler
pauses it until the next period. If a request arrives during the
pause: it waits in the network socket buffer. For P99 latency:
requests that hit during a throttle period see 50-100ms additional
latency. High-traffic services: this makes P99 latency unreliable.
The solution: set CPU limit generous enough that throttling occurs
only in exceptional cases (circuit breaker should have fired before
CPU is the bottleneck). Monitor `throttled_time` per container:
`cat /sys/fs/cgroup/cpu/cpu.stat`. If throttled_time is increasing:
the service is CPU-limited; scale horizontally or increase limit.

