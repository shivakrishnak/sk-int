---
layout: default
title: "Operating Systems - L3 Security"
parent: "Operating Systems"
nav_order: 9
permalink: /operating-systems/l3-security/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 20 | [OS Security Model and Privilege Escalation](#os-security-model-and-privilege-escalation) | high |
| 21 | [OS Anti-patterns: Resource Leaks and Race Conditions](#os-anti-patterns-resource-leaks-and-race-conditions) | high |

---

# OS Security Model and Privilege Escalation

🎯 Interview Weight: High - Understanding Unix privilege separation, capabilities, and privilege escalation vectors is required for senior backend engineers, especially those deploying containerized services. These concepts appear in security design interviews and container security discussions.

---

## 📋 Quick Reference

**One-line definition:** The OS security model enforces privilege separation through user IDs, capabilities, and system call filtering; privilege escalation exploits weaknesses in this model to gain permissions beyond those initially granted.

**Difficulty:** ★★☆ | **Asked at:** Senior | **Seniority:** Mid-Senior

---

### 🎯 Model Answer

**30 seconds:**
> Unix security rests on three pillars: user/group identity (UID/GID), file permissions (DAC - Discretionary Access Control), and privilege separation between user mode (ring 3) and kernel mode (ring 0). Privilege escalation means gaining capabilities beyond what was originally granted - either horizontal (access another user's data) or vertical (gain root/kernel access). Modern Linux adds capabilities (splitting root into fine-grained privileges) and seccomp (system call filtering) to limit the blast radius of a compromised process.

**3 minutes (Senior):**
> The Unix security model is built on the assumption that the kernel is trusted and user-space processes operate within their assigned privileges. Vertical privilege escalation typically exploits: setuid binaries (world-executable files owned by root that run as root), kernel vulnerabilities (memory corruption in kernel code), or misconfigured sudo rules. Horizontal escalation exploits: symlink attacks on world-writable directories, path traversal in setuid programs, and TOCTOU (Time-Of-Check-To-Time-Of-Use) race conditions. Modern hardening adds Linux capabilities: instead of requiring a process to be fully root to bind port 80, give it only `CAP_NET_BIND_SERVICE`. seccomp-bpf filters which syscalls a process may invoke - Docker containers default to a seccomp profile that blocks 44 dangerous syscalls. SELinux/AppArmor add mandatory access control (MAC) on top of DAC: even root cannot read files if the MAC policy forbids it. For production container security: run as non-root UID, drop all capabilities except those needed, apply seccomp profiles, and use read-only root filesystems.

**Framework:** UID/GID -> DAC -> CAPABILITIES -> MAC (SELinux/AppArmor) -> SECCOMP

*Adapting up:* Kubernetes RBAC, pod security contexts, admission controllers, and the security implications of privileged containers.

*Adapting down:* Think of Unix security as locked rooms. Every process carries a keycard (UID). Files have locks that accept specific keycards. The root keycard opens everything. Privilege escalation means stealing or counterfeiting a master keycard.

**Blank Mind Recovery:**

**(1) Restate:** "OS security model - who can do what. Privilege escalation - going beyond what you were allowed."

**(2) First principles:** "The OS must prevent processes from reading each other's memory, accessing each other's files, and calling privileged kernel functions. This requires the hardware (ring 0 vs ring 3), the OS (UID/GID enforcement), and the filesystem (permission bits) all working together."

**(3) Bridge:** "Container security is all about this: a container should run as a non-root UID with no extra capabilities and a seccomp profile that blocks unused syscalls. Container breakout attacks exploit gaps in this model."

---

### 📘 Concept Explanation

**What it is:**
The OS security model is the collection of mechanisms that enforce access control between processes, files, devices, and kernel resources. Privilege escalation is any technique that enables a process to gain capabilities beyond those it was initially granted.

**The Unix privilege model layers:**

```
UNIX SECURITY MODEL - LAYERS:
==============================
Layer 1: Hardware rings
  Ring 0 (kernel mode): unrestricted hardware access
  Ring 3 (user mode): protected; syscalls to enter ring 0

Layer 2: Process identity
  UID (real, effective, saved-set, filesystem)
  GID (group identity) + supplementary groups
  Root (UID=0): bypasses most DAC checks

Layer 3: File permissions (DAC)
  User/Group/Other * Read/Write/Execute
  Special bits: setuid, setgid, sticky

Layer 4: Linux Capabilities
  Split root power into 38 capabilities:
  CAP_NET_BIND_SERVICE: bind ports < 1024
  CAP_SYS_PTRACE: trace other processes
  CAP_DAC_OVERRIDE: bypass file permission checks
  CAP_SYS_ADMIN: broad system admin (dangerous)
  Processes can drop capabilities they do not need

Layer 5: Mandatory Access Control (MAC)
  SELinux: type enforcement on files+processes
  AppArmor: path-based profile restrictions
  MAC rules enforced EVEN for root processes

Layer 6: System call filtering (seccomp-bpf)
  Whitelist or blacklist syscalls per process
  Docker default: blocks ptrace, kexec, etc.
  seccomp-bpf can filter based on arguments
```

> **Diagram walkthrough:** The security model is defense-in-depth: each layer assumes the layers below may be compromised. Hardware rings protect the kernel from user-space bugs. UID/GID separate processes from each other. Capabilities split root's power into minimal grants. MAC enforces policy even if root is compromised. seccomp limits which syscalls a compromised process can invoke, limiting kernel attack surface. A production-hardened container uses all six layers.

**Privilege escalation attack surface:**

```
COMMON PRIVILEGE ESCALATION VECTORS:
======================================

SETUID BINARY EXPLOITATION:
  /usr/bin/passwd is setuid root
  Vulnerability: if passwd has a path traversal bug,
  attacker exploits it to run arbitrary commands as root
  Defence: minimize setuid binaries (ls -l /usr -perm -4000)

SUDO MISCONFIGURATION:
  user ALL=(ALL) NOPASSWD:/usr/bin/find
  Attack: sudo find / -exec /bin/sh \; -quit
  Result: root shell
  Defence: restrict sudo rules; use noexec where possible

TOCTOU RACE CONDITION:
  check: if (access("file", W_OK) == 0)  // runs as user
  use:   open("file", O_WRONLY)          // runs as root
  Attack: swap "file" with symlink to /etc/passwd
          between check and use
  Defence: use O_NOFOLLOW; use fstat not stat;
           use capabilities not setuid

KERNEL VULNERABILITY (CVE-style):
  Memory corruption in kernel code allows
  arbitrary code execution in ring 0
  Defence: kernel patches; seccomp reducing
           attack surface; KASLR; SMEP/SMAP
```

> **Diagram walkthrough:** This maps the four most common privilege escalation vectors. The setuid vector is most common in practice: `find / -perm -4000 -user root` reveals every setuid-root binary - each is a potential escalation vector if it has a bug. The TOCTOU vector is subtle and often missed in code review: any check-then-use pattern with a race window is vulnerable, especially in setuid programs. The mitigation pattern: use file descriptors (fd-based operations) instead of path-based operations to eliminate the race window between check and use.

**The key insight:**
Privilege escalation is fundamentally about exploiting a gap between identity (what UID/capability you have) and capability (what operations you can perform). Each Unix security layer narrows this gap: capabilities limit what root can do, seccomp limits which syscalls are reachable, and MAC limits what even root can touch. Defense in depth means an attacker must defeat all layers, not just one.

**When to apply:**
- Designing service account permissions (principle of least privilege)
- Container security configuration (seccomp profiles, capability dropping)
- Code review of setuid or privileged code paths
- Incident response when investigating potential privilege escalation

**When NOT to apply naively:**
- Do not equate "running as non-root" with "secure" - a process with CAP_SYS_ADMIN is effectively root regardless of UID
- Do not assume seccomp profiles protect against all attacks - they filter syscalls but not the use of permitted syscalls with malicious arguments

**Alternatives:**
- SELinux type enforcement (strongest MAC, complex to configure)
- AppArmor path profiles (simpler than SELinux, path-based)
- gVisor/Kata Containers (hardware VM isolation for container workloads)
- Capability-based security (Capsicum on BSD)

---

### 💻 Code Example

**BAD: TOCTOU race in a privileged file operation**

```c
// BAD: Classic TOCTOU - check then use with a race window
// If this runs setuid, attacker can swap "filename" to
// a symlink pointing to /etc/shadow between check and open

int vulnerable_write(const char *filename, const char *data) {
    // access() checks with REAL UID, not effective UID
    // This IS the right function to use for setuid check...
    if (access(filename, W_OK) != 0) {
        return -1; // RACE WINDOW STARTS HERE
    }
    // ...but between access() and open(), attacker
    // can replace filename with a symlink:
    //   rm user_file; ln -s /etc/shadow user_file
    int fd = open(filename, O_WRONLY | O_TRUNC);
    // Now writing to /etc/shadow as root!
    if (fd >= 0) {
        write(fd, data, strlen(data));
        close(fd);
    }
    return 0;
}
```

> **Code walkthrough:** This is the canonical TOCTOU (Time-Of-Check-To-Time-Of-Use) race condition. The `access()` call checks permission using the real UID - correct for a setuid program. But between access() returning success and open() executing, an attacker can replace the target file with a symlink to a sensitive file. The race window is microseconds wide, but a loop attack that replaces and restores the file continuously has a non-trivial hit probability. The kernel has no way to tell these two calls are meant to be atomic. The CVE equivalent: this exact pattern appeared in several sudo and su setuid vulnerabilities.

**GOOD: TOCTOU-safe privileged file operation**

```c
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

// GOOD: Open first, then verify - eliminates race window
// Once we have the fd, the path cannot be swapped

int safe_privileged_write(
        const char *filename,
        const char *data,
        size_t len) {

    // Step 1: Open with O_NOFOLLOW to refuse symlinks
    // This prevents the attacker's symlink replacement
    int fd = open(filename,
                  O_WRONLY | O_NOFOLLOW | O_TRUNC);
    if (fd < 0) return -1;

    // Step 2: fstat the fd, NOT the path
    // fd is immune to path replacement - checks the
    // actual file we opened, not whatever is at path now
    struct stat st;
    if (fstat(fd, &st) != 0) {
        close(fd); return -1;
    }

    // Step 3: Verify ownership and type on the fd
    if (!S_ISREG(st.st_mode)) {  // not a regular file?
        close(fd); return -1;    // could be device/socket
    }
    if (st.st_uid != getuid()) { // not owned by real user?
        close(fd); return -1;
    }

    // Now safe to write - we have verified the fd
    ssize_t written = write(fd, data, len);
    close(fd);
    return (written == (ssize_t)len) ? 0 : -1;
}
```

> **Code walkthrough:** This eliminates the TOCTOU race by inverting the order: open first (acquiring the fd), then verify. Once we have a file descriptor, the path can change without affecting the fd - the fd refers to a specific inode, not a path. `O_NOFOLLOW` refuses to open a symlink, blocking the attacker's symlink replacement attack. `fstat(fd, ...)` checks the stat of the actual file behind the fd (not the path), which is immune to replacement. This pattern - open first, verify on fd - is the correct approach for any privileged code that must validate file ownership.

**GOOD: Dropping capabilities in a service**

```java
// Java service that needs to bind port 80 but nothing else
// Using ProcessBuilder to launch a subprocess with reduced caps
// In production: set capabilities in systemd unit file

// systemd unit file approach (recommended):
// [Service]
// User=myservice
// AmbientCapabilities=CAP_NET_BIND_SERVICE
// CapabilityBoundingSet=CAP_NET_BIND_SERVICE
// NoNewPrivileges=true

// Verify capabilities from Java:
public class CapabilityCheck {
    public static void checkCaps() throws Exception {
        ProcessBuilder pb = new ProcessBuilder(
            "cat", "/proc/self/status"
        );
        pb.redirectErrorStream(true);
        Process p = pb.start();
        p.inputReader().lines()
            .filter(l -> l.startsWith("Cap"))
            .forEach(System.out::println);
        // CapInh: inherited caps
        // CapPrm: permitted caps
        // CapEff: effective caps (currently active)
        // CapBnd: bounding set (cannot gain above this)
        // CapAmb: ambient caps (survive exec)
    }
}
```

> **Code walkthrough:** Linux capabilities split root's power into 38 granular permissions. `CAP_NET_BIND_SERVICE` allows binding ports below 1024 without being root. The systemd unit file `CapabilityBoundingSet=CAP_NET_BIND_SERVICE` limits the process to only this capability, even if it calls `setuid(0)`. `NoNewPrivileges=true` is critical: it prevents the process from gaining new privileges through setuid exec or capability transitions, even if it somehow obtains a setuid binary. This is the correct pattern for any service that needs one specific privileged operation - grant exactly that capability and nothing else.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Unix security uses UID/GID to identify processes and file permissions to control access. Root (UID 0) bypasses most access checks. Privilege escalation is gaining permissions you were not supposed to have - commonly through exploiting setuid binaries or misconfigured sudo. Modern containers should run as non-root and drop unnecessary capabilities.

*Push deeper:* Linux capabilities as a finer-grained alternative to full root, seccomp syscall filtering, TOCTOU race conditions in privileged code, and MAC systems like AppArmor.

---

**Senior / Staff (5+ years):**
> The security model layers from hardware (ring 0 vs ring 3) through UID/GID and DAC to capabilities, seccomp, and MAC. Privilege escalation exploits gaps between these layers. In production containers, I enforce: run as UID > 1000 (not root), drop ALL capabilities and re-add only what is needed (`CAP_NET_BIND_SERVICE` for port binding, nothing else), apply a custom seccomp profile blocking unused syscalls, use read-only root filesystem with tmpfs mounts for writable paths, and set `NoNewPrivileges=true` in the systemd or container spec. For code review of privileged paths, I look specifically for TOCTOU patterns (access() then open()), and ensure fd-based operations (fstat not stat) are used after opening a file. Container breakout attacks typically target privileged containers (full root with all caps) or containers with `--privileged` - the `CAP_SYS_ADMIN` capability alone enables most container escape techniques.

*Push deeper:* Kubernetes pod security admission, OPA Gatekeeper policies blocking privileged containers, EBPF-based runtime security (Falco), and the security implications of exec syscalls in capability transitions.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Running as non-root means the process is unprivileged"**
A non-root process with `CAP_SYS_ADMIN` is effectively as powerful as root for most attack scenarios. `CAP_SYS_ADMIN` enables mounting filesystems, creating namespaces, and dozens of other privileged operations. Non-root is a necessary but not sufficient condition for a least-privilege deployment.

**Misconception 2: "seccomp blocks system calls, so the process cannot do anything dangerous"**
seccomp blocks specified syscalls but cannot inspect the arguments of allowed syscalls for malicious content. An allowed `write()` syscall can still write to a file that should be protected. seccomp reduces the kernel attack surface but does not replace DAC/MAC for data protection.

**Misconception 3: "setuid programs are always dangerous"**
setuid is not inherently dangerous - it is a mechanism that can be used safely when the setuid program is carefully written (input validation, no TOCTOU, dropping privileges after the privileged operation). The danger is complexity: every line of setuid code that runs before dropping privileges is an attack surface.

**Misconception 4: "Docker containers are isolated by default"**
Docker containers use Linux namespaces and cgroups for isolation, but the container root process runs as root (UID 0) in the container by default. A container running as root with the default capability set can exploit various techniques to escape the container namespace. Always specify `USER` in Dockerfiles and use `--security-opt no-new-privileges`.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Container Running as Root Escaping to Host**

Symptom: Container process writes to host filesystem paths; attacker reads /proc/1/root to access host.

```bash
# Check if a running container is running as root
docker inspect <container> | grep -A5 '"User"'
# Empty "User" means running as root (default)

# Check container capabilities
docker inspect <container> | \
  python3 -c "import json,sys; \
  c=json.load(sys.stdin)[0]['HostConfig']; \
  print('Add:', c.get('CapAdd'), \
        'Drop:', c.get('CapDrop'))"

# Harden: run container as non-root user
# In docker-compose.yml:
# security_opt:
#   - no-new-privileges:true
# user: "1000:1000"
# read_only: true

# Check for privileged mode (most dangerous):
docker inspect <container> | grep -i privileged
```

> **Code walkthrough:** A container running as root with default capabilities can use `CAP_SYS_ADMIN` to mount host filesystems, use `ptrace` to attach to host processes, or read from `/proc/1/root` (which points to the host's root filesystem when in the host PID namespace). The diagnosis is to inspect the container's user and capability configuration. The fix is defense in depth: non-root user, dropped capabilities, seccomp profile, read-only root filesystem, and no-new-privileges. Kubernetes enforces this through pod security contexts and admission controllers.

**Failure Mode 2: sudo Misconfiguration Enabling Root Shell**

Symptom: Unprivileged user can run arbitrary commands as root due to overly permissive sudo rule.

```bash
# Audit sudo rules for dangerous patterns
sudo -l -U username  # list all sudo rules for a user

# DANGEROUS patterns to look for:
# user ALL=(ALL) NOPASSWD: /usr/bin/vim
#   -> sudo vim, then :!sh in vim = root shell
# user ALL=(ALL) NOPASSWD: /usr/bin/find
#   -> sudo find / -exec /bin/bash \;  = root shell
# user ALL=(ALL) NOPASSWD: /usr/bin/python3
#   -> sudo python3 -c "import os; os.system('/bin/bash')"
# user ALL=(ALL) NOPASSWD: ALL
#   -> unrestricted root access

# GTFOBins (https://gtfobins.github.io) lists ALL binaries
# that can escalate privileges via sudo misconfiguration

# Safe sudo pattern: restrict to specific script,
# with NOEXEC to prevent shell spawning
# user ALL=(ALL) NOPASSWD,NOEXEC: /opt/scripts/safe-script.sh
```

> **Code walkthrough:** sudo misconfiguration is one of the most common privilege escalation vectors in enterprise Linux environments. The GTFOBins project catalogs every Unix binary that can be abused for privilege escalation via sudo - almost every scripting language and many text editors enable root shell access if granted unrestricted sudo. The NOEXEC option prevents the sudo'd process from spawning new processes, but it is limited (only works for binaries that use exec(); not effective against interpreted languages). The correct approach: sudo should only allow specific scripts that are tightly controlled and reviewed, never interactive tools like vim, python, or find.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | privilege model, capabilities, MAC |
| Debugging | 3 | container escape, sudo audit, TOCTOU |
| Trade-off | 2 | root vs capabilities, seccomp overhead |
| Behavioral | 1 | privilege escalation incident |

---

**[JUNIOR] Q1 - [TRADE-OFF] Explain the difference between Linux capabilities and traditional root privileges.**

Traditional Unix has a binary privilege model: root (UID 0) bypasses nearly all permission checks, while non-root is subject to all of them. This all-or-nothing model is the principle of least privilege's enemy: a service only needs to bind port 443, but to do so it must run as root - which also grants it the ability to read any file, kill any process, and load kernel modules. Linux capabilities (introduced in kernel 2.2) split root's power into 38 independent capabilities, each of which can be granted or revoked independently. `CAP_NET_BIND_SERVICE` allows binding privileged ports without any other root privilege. `CAP_DAC_READ_SEARCH` allows reading any file without other root powers. `CAP_SYS_PTRACE` allows tracing processes. A capability set has four components: permitted (the maximum set the process may claim), effective (currently active capabilities), inheritable (capabilities passed through exec), and bounding set (the ceiling - a process cannot gain capabilities above this set, even via setuid). For production services: grant only the specific capabilities needed, set the bounding set to match, and add `NoNewPrivileges=true` to prevent the process from gaining capabilities through exec transitions. The practical impact: a compromised service with only `CAP_NET_BIND_SERVICE` cannot read /etc/shadow, kill system processes, or escape a container - the blast radius is contained.

*What separates good from great:* Explaining all four capability sets (permitted/effective/inheritable/bounding) and their relationships, and the `NoNewPrivileges` flag as the mechanism that prevents capability escalation through exec.

---

**[JUNIOR] Q2 - [MECHANISM] What is a TOCTOU vulnerability and how do you eliminate it in privileged code?**

TOCTOU (Time-Of-Check-To-Time-Of-Use) is a race condition where the resource checked for a permission decision changes between the check and the subsequent use. In privileged code (setuid programs), an attacker controls their user-space environment and can race between two operations with nanosecond-level precision using a busy loop. The canonical example: a setuid program calls `access("file", W_OK)` to verify the real user has write permission, then calls `open("file", O_WRONLY)` to write. Between these two calls, the attacker replaces "file" with a symlink to `/etc/shadow`. The `access()` call saw a legitimate file; the `open()` call (running as root) opens the symlink target. The elimination techniques: (1) open the file first (acquiring an fd), then verify the fd with `fstat()` - once you have an fd, the path cannot affect the target inode; (2) use `O_NOFOLLOW` in the open call to refuse symlinks; (3) use `openat()` with `AT_FDCWD` and a directory fd to anchor the path; (4) use `O_PATH` to open a path-based fd without triggering permission checks, then verify with fstat. In kernel code, similar races are prevented with spinlocks and atomic operations that make check-and-modify atomic at the hardware level.

*What separates good from great:* Explaining the fd as TOCTOU-immune (inode bound, path irrelevant), O_NOFOLLOW as the symlink defense, and the kernel-level parallel (atomic check-and-modify primitives).

---

**[JUNIOR] Q3 - [MECHANISM] What is seccomp-bpf and what protection does it provide?**

seccomp (secure computing mode) is a Linux kernel feature that restricts which syscalls a process may invoke. seccomp-bpf uses BPF (Berkeley Packet Filter) programs to express policies: the BPF program runs on every syscall invocation, examining the syscall number and arguments, and returns ALLOW, KILL_PROCESS, TRAP, or ERRNO. Docker's default seccomp profile blocks 44 syscalls including `ptrace`, `kexec_load`, `mount`, `unshare`, and clock manipulation syscalls. This reduces the kernel attack surface exposed to a compromised container process. The protection model: a compromised process within seccomp constraints cannot invoke blocked syscalls even with root/capabilities - any attempt triggers an immediate SIGSYS or EPERM. This limits the attacker's options for kernel exploitation (fewer syscall entry points = fewer kernel code paths to corrupt). The limitations: seccomp can inspect syscall arguments but not memory they point to - it cannot validate that a permitted `write()` call is writing to a safe location; it can only check that `write` is in the allowed set and (optionally) that the fd argument falls in a range. For Java applications: the JVM uses many syscalls internally; applying a restrictive seccomp profile requires profiling which syscalls the JVM needs across all code paths (startup, GC, class loading, IO), which is non-trivial. Tools like `strace -c` and Docker's seccomp tracing mode help generate accurate profiles.

*What separates good from great:* The BPF program mechanism (not just "it blocks syscalls"), the specific dangerous syscalls Docker blocks, the limitation that seccomp cannot validate pointer arguments (only syscall number and scalar arguments), and the practical difficulty of profiling JVM syscalls.

---

**[JUNIOR] Q4 - [TRADE-OFF] How does AppArmor differ from SELinux and when would you choose each?**

SELinux (Security-Enhanced Linux) uses type enforcement: every file, process, socket, and device has a type label, and the policy specifies which process types may access which file types. A process labeled `httpd_t` can read files labeled `httpd_content_t` but not `shadow_t`. Labels are stored in extended attributes and are decoupled from paths - renaming a file does not change its label, so an attacker cannot defeat the policy by moving files to privileged locations. SELinux policy is comprehensive but complex: the reference policy has tens of thousands of rules, and writing a new policy for a custom application requires understanding the type system and policy language. AppArmor uses path-based profiles: a profile lists the paths a process may access and with what permissions. It is simpler to write and understand - you review a list of paths rather than a type graph. However, path-based enforcement means an attacker who moves a file to a path that is in the allowed set can defeat the policy. Choice criteria: SELinux for environments where policy correctness must be formally verifiable and where complexity is acceptable (e.g., RHEL/CentOS enterprise deployments with a dedicated security team); AppArmor for environments where ease of policy writing and maintenance is more important (e.g., Ubuntu deployments, Kubernetes node hardening). Docker supports both; Kubernetes PSA (Pod Security Admission) allows specifying either. In practice: AppArmor is easier to adopt correctly; a misconfigured SELinux policy in permissive mode provides false security.

*What separates good from great:* The label vs path distinction (SELinux labels survive moves; AppArmor paths are defeated by moves), the practical complexity comparison, and the specific use-case recommendation with reasoning.

---

**[MID] Q5 - [BEHAVIORAL] (Behavioral) Describe a security incident involving privilege escalation that you investigated or hardened against.**

During a container security audit, I was reviewing a microservices deployment and noticed that all 20 containers were running as root (no `USER` directive in Dockerfiles) with the default Docker capability set. A threat modeling session identified that if any of these services had a remote code execution vulnerability (a realistic risk for services parsing user-supplied content), the attacker would have root in the container with full default capabilities including `CAP_SYS_ADMIN` and `CAP_NET_RAW`. Container escape via `CAP_SYS_ADMIN` is well-documented (mounting the host's cgroupfs and using notify_on_release for code execution). My remediation approach: first, I added `USER 1001` to all Dockerfiles and created the corresponding non-root user in the build stage. Second, I added `--cap-drop=ALL --cap-add=NET_BIND_SERVICE` to the containers that needed port binding, and `--cap-drop=ALL` for the rest. Third, I added `--security-opt=no-new-privileges:true` to all containers. Fourth, I applied Docker's default seccomp profile explicitly (it was implicitly applied but making it explicit ensures it does not disappear if Docker's default changes). Fifth, I added `read_only: true` in docker-compose and configured tmpfs mounts for the directories that legitimately needed writable access. The attack surface reduction: from full-root-in-container with 14 capabilities to non-root with 0-1 capabilities. None of the containers were broken by this change because the application code had no privileged operation requirements beyond port binding.

*What separates good from great:* The threat model starting point (RCE is realistic for user-content parsers), naming the specific container escape technique (CAP_SYS_ADMIN + cgroupfs), the layered remediation (not just non-root but also cap-drop AND seccomp AND no-new-privileges), and confirming no functionality was broken.

---

**[MID] Q6 - [TRADE-OFF] What is the difference between DAC and MAC in access control?**

DAC (Discretionary Access Control) is the traditional Unix model: the owner of a resource decides who can access it. A file owner can set permissions to allow world-read, and no external policy can override that decision. Root can change any permission. DAC is flexible but weak: it relies entirely on users and root making correct permission decisions. If root is compromised, all DAC controls are bypassed. MAC (Mandatory Access Control) applies system-wide policies that override DAC decisions. A MAC policy can state: "httpd processes may NEVER read /etc/shadow, even if root tries to open it on httpd's behalf." SELinux and AppArmor implement MAC on Linux. Even if an attacker gains root (UID 0), they are still subject to MAC constraints if the MAC policy denies the operation. This is the fundamental security advantage of MAC: it contains the blast radius of a root compromise. The practical tradeoff: MAC requires a correct policy (complex to write), while a misconfigured MAC policy either provides false security (too permissive) or breaks the application (too restrictive). Production deployment pattern: run SELinux/AppArmor in permissive mode (log violations but do not block) until the policy is validated, then switch to enforcing mode. The audit log of permissive-mode violations is the input to policy refinement.

*What separates good from great:* The key insight that MAC overrides DAC even for root (explaining WHY MAC is superior for defense-in-depth), the false security risk of permissive mode policy deployment, and the permissive-then-enforcing adoption path.

---

**[MID] Q7 - [MECHANISM] How would you harden a Java Spring Boot service running in a Linux container?**

A production-hardened Spring Boot container has these properties: First, non-root user: `RUN adduser --disabled-password --gecos "" appuser` and `USER appuser` in the Dockerfile, running as UID 1000. Second, minimal capabilities: Spring Boot on port 8080 needs no capabilities - port 8080 is above 1024 (no `CAP_NET_BIND_SERVICE` needed); drop all: `--cap-drop=ALL`. Third, no-new-privileges: `--security-opt=no-new-privileges:true` prevents capability transitions through exec. Fourth, read-only filesystem: `--read-only` with `--tmpfs /tmp` for the JVM's temp files and `--tmpfs /app/logs` for log output. Fifth, custom seccomp profile: profile the JVM's syscall usage with `strace -c -f java ...` in a test environment, then build a minimal allow-list covering the ~40-60 syscalls the JVM actually uses (fork, clone, mmap, read, write, socket, etc.) and blocking the rest. Sixth, AppArmor profile: restrict file access to `/app/`, `/tmp/`, `/proc/self/`, and deny network raw socket access. Seventh, resource limits via cgroups: `--memory=512m --cpus=1` prevents resource exhaustion. Eighth: `JAVA_OPTS="-Djdk.serialFilter=!*"` to disable Java deserialization as a defense against deserialization attacks. The combination of non-root + no capabilities + seccomp + read-only filesystem means that even a successful RCE gives the attacker a limited shell with no persistence and no privilege escalation path.

*What separates good from great:* The complete multi-layer approach (7 distinct controls), the JVM-specific consideration (profiling syscalls with strace because JVM needs more than a minimal Linux program), the deserialization attack mitigation, and the defense-in-depth framing of what a successful RCE gives the attacker after hardening.

**[SENIOR] Q8 - [DEBUGGING] How would you audit a container for privilege escalation risks before production deployment?**

A container privilege escalation audit has three phases. Phase 1 - static analysis: run `docker inspect <image>` and check for `Privileged: true` (container escape is trivial if set), `CapAdd` entries (anything beyond minimal is suspicious), `SecurityOpt` for the absence of `no-new-privileges`, and user set to root (UID 0). Use `trivy config` or `checkov` to scan Dockerfile and Kubernetes YAML for misconfigurations. Check the base image for SUID binaries with `find / -perm /4000 -type f` - these allow privilege escalation if the binary has vulnerabilities. Phase 2 - runtime analysis: run the container with `--cap-drop=ALL --no-new-privileges --read-only --security-opt seccomp=<profile>` and verify the application still works. Check what capabilities it requests by running without any drops and strace/auditd what syscalls it makes: `strace -c -f <cmd>` or `ausyscall --dump` during a realistic workload. Phase 3 - network and filesystem: verify the container cannot reach the metadata API (169.254.169.254 in AWS/GCP) unless explicitly required; check that service account tokens are not over-privileged; verify /proc and /sys are not writable. The audit output: a capability allow-list, a seccomp profile, confirmed non-root execution, and a list of SUID binaries removed or justified.

*What separates good from great:* The three-phase structure (static, runtime, network/filesystem), the metadata API check (the most common container escape vector in cloud environments), and the concrete commands (`docker inspect`, `strace -c`, `find / -perm /4000`) rather than abstract advice.

---

**[SENIOR] Q9 - [TRADE-OFF] What are the performance costs of seccomp-bpf and when would you not use it?**

seccomp-bpf introduces a BPF program evaluation on every system call. The overhead breakdown: the BPF interpreter runs the filter program before the kernel processes the syscall. The filter must check the syscall number against the allow-list. For a minimal filter (10-20 rules), this adds approximately 100-400 ns per syscall on modern hardware. For syscall-intensive workloads - a JVM making 100K syscalls/second (file I/O, socket operations, clock reads) - this adds 10-40 ms/second of CPU overhead, or roughly 1-4% CPU. The more complex the BPF program (argument filtering, multiple rules), the higher the overhead. When NOT to use it: (1) High-frequency trading or latency-sensitive systems where sub-microsecond response matters - seccomp adds predictable latency to every syscall. (2) Legacy systems where the syscall profile cannot be determined without invasive profiling (risk of breaking production with an EPERM). (3) When the runtime frequently JIT-compiles code (JVM, V8) - the syscall profile changes dynamically. (4) When the application calls sys_rt_sigreturn and clone3 in unusual patterns (common JVM behavior that breaks many stock seccomp profiles). Alternative for high-performance: use cgroup-level restrictions and read-only filesystem instead of seccomp, combined with capabilities drop and no-new-privileges. The cost/benefit: seccomp is high value for user-facing web services (accepting untrusted input, JVM/Node.js runtimes) where the syscall profile is stable and the defense-in-depth benefit outweighs the latency cost.

*What separates good from great:* Quantifying the overhead (100-400 ns/syscall, 1-4% CPU for JVM workloads) rather than vague "some overhead", the JVM-specific complications (JIT changing syscall profiles), and the concrete alternative approach (cgroups + capabilities + no-new-privileges) for latency-sensitive cases.


---

### ⚖️ Comparison Table

| Mechanism | Scope | Enforced For | Bypassed By Root? | Complexity |
|---|---|---|---|---|
| DAC (chmod/chown) | File/dir permissions | All processes | Yes (UID 0 bypasses) | Low |
| Linux Capabilities | Per-capability grants | User processes | No (if bounds set) | Medium |
| seccomp-bpf | Syscall filter | Per-process | No (applies to root) | High |
| AppArmor | Path-based MAC | Per-process profile | No | Medium |
| SELinux | Type enforcement MAC | System-wide | No | High |

**The deciding factor:** DAC alone is insufficient for production security. Capabilities reduce root blast radius. seccomp + AppArmor/SELinux provide defense-in-depth that restricts even root processes.

---

### 🏛️ System Design

*(Omit: ★★☆ keyword - system design covered in the failure modes and code examples above)*

---

### 📊 Diagram

*(Omit: the layered security model ASCII diagram in the Concept Explanation section provides the primary visual; no additional diagram adds clarity for this keyword)*


---

# OS Anti-patterns: Resource Leaks and Race Conditions

🎯 Interview Weight: High - Resource leaks and race conditions are among the most common production OS-level failures. Diagnosing fd leaks, zombie processes, and file descriptor exhaustion are expected skills for senior backend engineers. These appear in debugging interview rounds and system design discussions.

---

## 📋 Quick Reference

**One-line definition:** Resource leaks and race conditions are OS-level anti-patterns where processes fail to release kernel-managed resources (file descriptors, processes, memory) or create unsafe concurrent access to shared kernel resources.

**Difficulty:** ★★☆ | **Asked at:** Mid-Senior | **Seniority:** Mid

---

### 🎯 Model Answer

**30 seconds:**
> Resource leaks at the OS level mean processes hold kernel resources they no longer need: open file descriptors, locked memory, named pipes, zombie processes. Each consumes kernel resources that are globally limited. File descriptor leaks are the most common - every open socket, file, or pipe that is not closed increments a per-process and system-wide fd count toward `ulimit -n` and `/proc/sys/fs/file-max`. Race conditions at the OS level involve concurrent access to shared kernel state without proper synchronization - classic examples are zombie process races, signal handler races (async-signal-safety), and fork-related lock inheritance.

**3 minutes (Senior):**
> The most common OS-level resource leak in backend Java applications is file descriptor leaks: connections or streams opened in a try block without proper finally/try-with-resources, or streams that are open()-ed but the exception path bypasses close(). Each leaked fd persists until the process exits. At 1024 fds/process default, a service that leaks one fd per request hits the limit quickly and starts returning EMFILE on every new connection. The diagnostic is: `ls -l /proc/<pid>/fd | wc -l` for a snapshot, or watching fd growth over time. The second most common is zombie processes: a parent that forks child processes but never calls wait() leaves the child's process table entry allocated indefinitely - the child is dead but not reaped. Zombie accumulation can exhaust the process table. The OS-level race condition that appears most in interviews is the classic signal handler race: if a signal handler accesses a global variable that the main thread is also modifying without atomic operations, the result is undefined. Only async-signal-safe functions (a subset of POSIX functions) may be called from a signal handler.

**Framework:** RESOURCE LIFECYCLE -> LEAK DETECTION -> ZOMBIE REAPING -> SIGNAL SAFETY

*Adapting up:* fd limits in containerized environments (cgroups do not limit fds by default), epoll fd management at scale (10K connections requires careful fd lifecycle management), and JVM finalizer-based resource management risks.

*Adapting down:* Every open file is like a borrowed library book. If you borrow books and never return them, eventually the library runs out of books to lend.

**Blank Mind Recovery:**

**(1) Restate:** "Resource leaks - kernel objects opened but never closed."

**(2) First principles:** "The OS kernel tracks every open file, socket, and process. These table entries have finite limits. Failing to close them when done exhausts the limit and the process (or system) starts failing new operations."

**(3) Bridge:** "Java's try-with-resources was specifically designed to prevent fd leaks by ensuring close() is always called. Connection pool implementations that do not properly return connections on exception are exactly this anti-pattern at the application layer."

---

### 📘 Concept Explanation

**What it is:**
OS resource leaks are failures to release kernel-managed resources (file descriptors, process entries, semaphores, shared memory segments) when they are no longer needed. OS-level race conditions are concurrent accesses to shared kernel state without appropriate synchronization, leading to corruption or undefined behavior.

**Resource leak taxonomy:**

```
OS RESOURCE LEAK TYPES:
==============================================
File Descriptor Leaks:
  open(), socket(), accept(), pipe() without close()
  Limit: per-process (ulimit -n, default 1024)
         system-wide (/proc/sys/fs/file-max)
  Symptom: EMFILE "Too many open files" on new open/accept
  Detection: ls /proc/PID/fd | wc -l  (rising count)

Zombie Process Leaks:
  fork() without wait() or waitpid()
  Child exits -> becomes zombie (Z state in ps)
  Entry in process table, no CPU/memory used
  Limit: system-wide PID limit (/proc/sys/kernel/pid_max)
  Detection: ps aux | grep defunct | wc -l

Memory Mapping Leaks (mmap):
  mmap() without munmap()
  Virtual address space consumed (less often physical)
  32-bit processes: VM exhaustion common
  Detection: /proc/PID/maps | wc -l  (region count)

IPC Resource Leaks:
  POSIX semaphores, message queues, shared memory
  Persist after process exit (unlike fds and mappings)
  Must be explicitly removed (sem_unlink, mq_unlink)
  Detection: ipcs -a  (SysV), /dev/shm (POSIX)
```

> **Diagram walkthrough:** Resource leaks fall into two categories: those that are automatically cleaned up when the process exits (fds, mappings) and those that persist beyond process death (POSIX IPC, SysV IPC). The fd leak is the most operationally critical for long-running services because the limit is hit during normal operation, not just at process exit. The IPC leak is most dangerous for systems that restart processes frequently - leaked semaphores and message queues accumulate system-wide until a reboot.

**Race condition taxonomy:**

```
OS-LEVEL RACE CONDITIONS:
==============================================
Signal Handler Race:
  main thread: global_var = compute_value()
  signal arrives between compute and assign
  handler reads partial state of global_var
  Fix: sigprocmask to block signals during critical
       section; use sig_atomic_t for simple flags;
       use write() pipe-trick (self-pipe) for complex

Fork + Mutex Race:
  Parent holds mutex, forks
  Child inherits locked mutex (owner PID changed)
  Child tries to acquire: DEADLOCK
  Fix: use pthread_atfork to release/reset mutexes

TOCTOU (covered in Security section):
  access() + open() race
  stat() + open() race on setuid code

Zombie Reaping Race:
  Parent in SIGCHLD handler calling waitpid()
  Multiple children exit simultaneously
  Handler called once, only reaps one
  Fix: loop waitpid(WNOHANG) until returns -1
       to drain all pending zombie children
```

> **Diagram walkthrough:** Signal handler races are the most subtle OS-level race condition. The signal handler runs asynchronously, potentially interrupting any instruction in the main flow. Only async-signal-safe functions (documented in signal(7)) may be called from handlers - most C library functions are NOT async-signal-safe because they use internal locks. The fork+mutex race is critical for applications that fork from a multi-threaded process: the child inherits all memory including locked mutexes, but the owning thread does not exist in the child. The correct diagnosis: deadlock shortly after fork in the child process; check `/proc/<pid>/task/` (only one thread in child) vs parent (multiple threads).

**The key insight:**
Resource leaks and race conditions share a root cause: assuming that an implicit protocol (the caller will always close; fork will never happen while holding a lock) is enforced. Explicit resource management (try-with-resources, RAII, pthread_atfork cleanup handlers) makes the protocol explicit and enforceable.

**When to apply:**
- Code review for any code that opens files, sockets, or launches processes
- Debugging EMFILE errors in production
- Debugging deadlocks in multi-threaded or multi-process code
- Container and process isolation design (each service has its own fd limits)

**When NOT to apply naively:**
- Fd limits per process are NOT the same as connection limits per server - a connection pool of 100 connections uses 100 fds but the limit is per process, not per server
- Zombie processes do NOT consume CPU or memory - only a process table entry - so a small number is not a crisis

**Alternatives:**
- Languages with automatic resource management (Java try-with-resources, Python with, C++ RAII) prevent most fd leaks
- Signal-safe IPC alternatives (eventfd, self-pipe) instead of complex signal handler code

---

### 💻 Code Example

**BAD: File descriptor leak on exception path**

```java
// BAD: File descriptor leaks when exception occurs
// on the read or processing path
public class FdLeakExample {

    public static String processFile(String path)
            throws IOException {
        // fd opened here
        FileInputStream fis = new FileInputStream(path);
        BufferedReader reader =
            new BufferedReader(new InputStreamReader(fis));

        // If readLine() throws IOException:
        // fis is NEVER closed - fd leaked
        String line = reader.readLine();
        if (line == null) {
            // Early return also leaks fd
            return "";
        }
        String result = processLine(line);

        // Only reached if no exception and no early return
        reader.close();
        return result;
    }

    // At 100 req/s with 0.1% error rate:
    // 0.1 fd leak/s -> hits 1024 fd limit in ~2.8 hours
    // Symptom: java.io.IOException: Too many open files
}
```

> **Code walkthrough:** This is the canonical fd leak pattern: resource opened before a try block with close() at the end of the happy path only. Exception paths and early returns skip the close(). The leak rate depends on the error rate: even a 0.1% error rate on a high-throughput service leaks enough fds to exhaust the per-process limit in hours. The symptom is sudden `java.io.IOException: Too many open files` that appears on all IO operations regardless of type - the service looks broken across the board, which makes it hard to identify fd exhaustion as the cause without checking `/proc/<pid>/fd`.

**GOOD: Proper resource management with try-with-resources**

```java
// GOOD: try-with-resources guarantees close() on all paths
// including exceptions and early returns
public class FdSafeExample {

    public static String processFile(String path)
            throws IOException {
        // AutoCloseable resources are closed in reverse order
        // on any exit from the try block (normal or exception)
        try (FileInputStream fis =
                 new FileInputStream(path);
             BufferedReader reader =
                 new BufferedReader(
                     new InputStreamReader(fis))) {

            String line = reader.readLine();
            if (line == null) return "";  // fis closed here
            return processLine(line);
                                          // fis closed here
        }   // and here on exception
    }
}
```

> **Code walkthrough:** Java's try-with-resources generates a `finally` block that calls close() on every `AutoCloseable` declared in the resource list, in reverse order, even when an exception occurs or an early return is executed. The JVM bytecode guarantees this - there is no execution path through the method that bypasses close(). If close() itself throws, the exception is "suppressed" and attached to the primary exception. This eliminates the entire class of fd leak from exception paths and early returns.

**BAD: Ignoring SIGCHLD causes zombie accumulation**

```c
// BAD: Default SIGCHLD handling does NOT auto-reap children.
// Each exited child becomes a zombie, consuming a PID slot
// until the parent exits or explicitly calls wait().

#include <unistd.h>
#include <stdio.h>

int main(void) {
    for (int i = 0; i < 100; i++) {
        pid_t pid = fork();
        if (pid == 0) {
            _exit(0);    // child exits immediately
        }
        sleep(1);        // parent never calls wait()
        // Each iteration: one more zombie in process table
        // ps aux shows 'Z' state; PID slots consumed
    }
    return 0;           // zombies cleaned only when parent exits
}
```

> **Code walkthrough:** The default SIGCHLD disposition (SIG_DFL) on Linux does NOT automatically reap children - it is ignored, but the zombie state persists until the parent calls waitpid(). Each fork creates a child; when the child calls _exit(), the kernel marks it TASK_ZOMBIE and sends SIGCHLD to the parent. Since the parent never calls wait(), the zombie entry stays in the process table. At high fork rates this exhausts the PID namespace (typically 32768 entries), causing EAGAIN on new fork() calls - which often manifests as inexplicable failures hours after the root cause.

**GOOD: Zombie process prevention with proper SIGCHLD handling**

```c
#include <signal.h>
#include <sys/wait.h>
#include <stdio.h>

// GOOD: Drain all zombie children in SIGCHLD handler
// WNOHANG prevents blocking; loop until no more zombies

static void sigchld_handler(int sig) {
    (void)sig;
    int status;
    pid_t pid;

    // Loop: multiple children can exit before one
    // SIGCHLD delivery (signals are not queued)
    while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
        // -1: wait for any child
        // WNOHANG: return immediately if no zombie

        if (WIFEXITED(status)) {
            // Child exited normally
            // printf unsafe in signal handler (not async-safe)
            // use write() if logging is needed:
            // write(STDERR_FILENO, "child exited\n", 13);
        }
        // Loop continues until no more zombies
    }
    // When waitpid returns -1 (no more children) or 0
    // (no zombie yet - should not happen with WNOHANG)
    // we stop
}

int setup_child_reaping(void) {
    struct sigaction sa;
    sa.sa_handler = sigchld_handler;
    sigemptyset(&sa.sa_mask);
    // SA_RESTART: restart interrupted syscalls
    // SA_NOCLDSTOP: only notify on exit, not stop/continue
    sa.sa_flags = SA_RESTART | SA_NOCLDSTOP;
    return sigaction(SIGCHLD, &sa, NULL);
}
```

> **Code walkthrough:** The critical pattern is `while (waitpid(-1, &status, WNOHANG) > 0)` - a loop, not a single call. POSIX does not guarantee a distinct SIGCHLD for each child exit when multiple children exit simultaneously; the handler may be called once for several exits. Without the loop, a single call to `waitpid()` reaps one zombie and misses the rest. `WNOHANG` prevents blocking if no zombie is available. Note: `printf()` is NOT async-signal-safe and must not be called from a signal handler - use `write()` for any handler-side logging. The SA_RESTART flag ensures that interrupted syscalls (like `accept()`) automatically retry rather than returning EINTR.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Resource leaks at the OS level mean not closing file descriptors, sockets, or not waiting for child processes. Every opened fd that is not closed accumulates until the process hits its limit (typically 1024) and all IO fails. In Java, always use try-with-resources to guarantee close(). Zombie processes accumulate when a parent forks but does not call wait() - fix it by calling waitpid() in a SIGCHLD handler.

*Push deeper:* Signal handler async-safety constraints, the fork+mutex deadlock race condition, and IPC resource leaks (semaphores and message queues that outlive the process).

---

**Senior / Staff (5+ years):**
> The OS resource lifecycle is: open -> use -> close (or explicit unlink for named IPC). Any path that exits without closing is a leak. In Java production services, I audit for fd leaks by monitoring `/proc/<pid>/fd` count growth over time in dashboards; a growing count indicates a leak. For multi-process services, I use `lsof -p <pid>` to inventory all open fds and identify which ones should be closed. For fork-based services, I always install a SIGCHLD handler that loops on waitpid with WNOHANG to reap zombies without risking missed exits. The subtle race I check for in code review: fork() called while a mutex is held in a multi-threaded process - the child inherits the locked mutex but the owning thread does not exist in the child, causing immediate deadlock on the first pthread_mutex_lock in the child. The fix is pthread_atfork handlers that unlock and reinitialize mutexes in the child.

*Push deeper:* epoll fd management at 10K connections (each connection is a fd; close() must be called before EPOLL_CTL_DEL to avoid epoll holding stale references), and JVM finalizer-based resource management risks (finalizers are not guaranteed to run before process exit).

---

### ⚠️ Common Misconceptions

**Misconception 1: "Zombie processes consume CPU and memory"**
Zombie processes consume only a process table entry. They hold no CPU time, no memory (the process's address space is freed on exit), and no open fds. A small number of zombies is harmless. The problem is when zombie count grows unboundedly - eventually exhausting the process table (`/proc/sys/kernel/pid_max`).

**Misconception 2: "Closing a Java BufferedReader also closes the underlying stream"**
In Java, closing a wrapper stream (BufferedReader) does close the underlying stream (FileInputStream). However, if the FileInputStream constructor throws (file not found), the BufferedReader is never created, and there is no stream to close - but also no stream to leak. The danger zone is when FileInputStream opens successfully but BufferedReader's constructor throws - at that point the FIS is open but the reference is inside the failed BufferedReader constructor call, which never returns. This is why try-with-resources lists BOTH resources separately.

**Misconception 3: "SIGCHLD is queued once per child exit"**
POSIX does not guarantee one SIGCHLD per child exit. Multiple child exits before the handler runs coalesce into a single SIGCHLD delivery. A SIGCHLD handler that calls waitpid() only once will miss all but one of the simultaneous exits. The fix is always looping with WNOHANG.

**Misconception 4: "printf() is safe to call from a signal handler"**
printf() is NOT async-signal-safe. It uses internal locks and non-reentrant internal state. If the signal interrupts a printf() in the main thread, calling printf() again from the signal handler causes undefined behavior (lock corruption). Only functions listed in POSIX signal(7) as async-signal-safe (write, read, malloc is NOT in the list) may be called from signal handlers.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: File Descriptor Exhaustion**

Symptom: Service suddenly fails all IO operations with "Too many open files" despite looking healthy in application metrics.

```bash
# 1. Check current fd usage
ls -l /proc/$(pgrep -f myapp)/fd | wc -l
# If > 80% of ulimit -n -> fd leak likely

# 2. Show current limit
cat /proc/$(pgrep -f myapp)/limits | grep "open files"

# 3. Inventory open fds - look for unusual patterns
lsof -p $(pgrep -f myapp) | sort -k9 | head -30
# Hundreds of entries to the same path or type = leak

# 4. Watch fd count growth over time
watch -n 5 'ls /proc/$(pgrep -f myapp)/fd | wc -l'
# Monotonically increasing = active leak

# 5. Fix immediately (without restart):
# Increase limit for the running process:
prlimit --pid $(pgrep -f myapp) --nofile=65536

# 6. Permanent fix in systemd unit:
# [Service]
# LimitNOFILE=65536
```

> **Code walkthrough:** The diagnosis sequence is: count -> inventory -> trend. A count near the limit confirms the problem; inventory reveals whether the fds are sockets (network leak), regular files (file IO leak), or pipes (internal process leak). Monotonically increasing count with no plateau confirms an active leak. The emergency fix (prlimit) buys time without a restart. The permanent fix is both increasing the limit AND finding the leak - otherwise you hit the higher limit eventually. `lsof -p PID | grep -c "(deleted)"` shows fds pointing to deleted files (a common pattern when temp files are deleted but not closed).

**Failure Mode 2: Fork Deadlock from Lock Inheritance**

Symptom: Child process hangs immediately after fork(); parent is multi-threaded; no CPU usage in child.

```bash
# 1. Identify deadlock in child
strace -p <child_pid>  # likely stuck in futex() (mutex wait)

# 2. Check parent thread count
ls /proc/<parent_pid>/task/ | wc -l  # > 1 = multithreaded

# 3. Check mutexes inherited by child
# No direct command; use gdb:
gdb -p <child_pid> -ex "thread apply all bt" -ex "detach"
# Look for threads waiting on pthread_mutex_lock

# Fix in code: use pthread_atfork
pthread_atfork(
    prepare_handler,  // runs in parent before fork
    parent_handler,   // runs in parent after fork
    child_handler     // runs in child after fork
);
// prepare: acquire all mutexes in a consistent order
// parent: release all mutexes
// child: re-initialize all mutexes (not release - they are
//        already "owned" by a non-existent thread)
```

> **Code walkthrough:** The fork+mutex deadlock is subtle because the child process has only one thread but the mutex thinks it is owned by a thread that does not exist. `pthread_mutex_lock` in the child will block waiting for the non-existent owner to release the lock - which never happens. `strace` shows the child stuck in `futex(FUTEX_WAIT)` - a mutex wait. The fix via `pthread_atfork` is the POSIX-specified mechanism: the child handler must call `pthread_mutex_init` to reinitialize the mutexes to an unlocked state (not `pthread_mutex_unlock` which would be wrong for a mutex the current thread does not own). This is why complex multi-threaded programs generally avoid fork() for process creation and use posix_spawn() or vfork()+exec() instead.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | fd lifecycle, zombie model, signal safety |
| Debugging | 3 | fd exhaustion, fork deadlock, zombie diagnosis |
| Trade-off | 2 | process vs thread models, signal vs pipe IPC |
| Behavioral | 1 | resource leak production incident |

---

**[JUNIOR] Q1 - [DEBUGGING] How do file descriptor leaks cause production failures and how do you diagnose them?**

File descriptor leaks cause failures when the process reaches its per-process fd limit (default 1024 on many systems, often 65536 on configured production systems). At that point, every call to open(), socket(), accept(), pipe(), and dup() returns EMFILE ("Too many open files"). For a web service, this means it cannot accept new connections, cannot open log files, and cannot read configuration - it appears completely broken. The misleading aspect: the error appears on ALL io operations, not just the one with the leak. The diagnosis sequence: first, check fd count (`ls /proc/<pid>/fd | wc -l`) against the limit (`cat /proc/<pid>/limits | grep "open files"`). If count is near the limit, a leak is likely. Second, inventory the types of open fds with `lsof -p <pid>` - hundreds of entries of the same type (all sockets, all to the same file path) indicates the leak source. Third, watch the count trend over time (`watch -n 10 'ls /proc/<pid>/fd | wc -l'`); a monotonically increasing count with no plateau confirms an active leak. For Java applications, `jstack <pid>` correlates with open fds: threads stuck in close() or showing unclosed stream stack traces identify the leak location.

*What separates good from great:* The counter-intuitive observation that fd exhaustion causes ALL io to fail (not just the type being leaked), the three-step diagnosis sequence, and correlating lsof output with Java stack traces.

---

**[JUNIOR] Q2 - [MECHANISM] What is a zombie process, what causes it, and how do you prevent and detect it?**

A zombie process is a process that has exited but whose exit status has not been collected by its parent. When a process exits, the kernel frees its memory, closes its file descriptors, and removes it from the CPU scheduler - but retains a minimal process table entry recording the PID, exit status, and CPU usage. This entry remains until the parent calls wait() or waitpid() to collect the exit status. A zombie process consumes no CPU, no memory beyond the process table entry, and no file descriptors - only a PID. The cause is a parent that forks child processes but never calls wait(). In server code, this commonly appears when using fork() for request handling without a SIGCHLD handler. Prevention: install a SIGCHLD handler that loops on `waitpid(-1, &status, WNOHANG)` until it returns -1 (no more children). The loop is essential because multiple simultaneous child exits may coalesce into one SIGCHLD delivery. Detection: `ps aux | awk '$8 ~ /Z/ {print}'` shows zombie processes (state Z = defunct). Long-term: `ps aux | grep -c defunct` monitored as a metric - a growing count indicates a parent not reaping its children. The nuclear fix for an already-accumulated zombie population: restart the parent process - all zombies are adopted by init (PID 1), which immediately reaps them.

*What separates good from great:* Clarifying that zombies consume NO CPU/memory (only a process table entry), explaining why the SIGCHLD handler must loop (signal coalescence), and the PID-1 adoption-and-reaping mechanism for the emergency cleanup.

---

**[JUNIOR] Q3 - [MECHANISM] What is async-signal-safety and why does it matter for signal handlers?**

A function is async-signal-safe if it can be safely called from a signal handler even if it was interrupted mid-execution in the same thread. The requirement exists because a signal handler executes asynchronously - it can interrupt any point in the main thread's execution, including the middle of a library function that holds internal locks. If the signal handler calls the same library function, it will try to acquire the already-held internal lock -> deadlock. Or it will corrupt the function's re-entered non-reentrant internal state. POSIX signal(7) defines a list of async-signal-safe functions: write(), read(), kill(), sigprocmask(), and a few others. Notably NOT on the list: printf(), malloc(), free(), any C++ STL function, most Java runtime calls. In practice, the rule is: signal handlers should do as little as possible - set a volatile sig_atomic_t flag for the main thread to check, or write one byte to a self-pipe (the self-pipe trick: main thread adds the read end of a pipe to epoll/select; signal handler writes to the write end; the main thread wakes up and handles the event safely). The self-pipe trick is the idiomatic solution for needing complex logic in response to signals.

*What separates good from great:* Explaining the mechanism (library functions hold internal locks that the re-entrant handler would deadlock on), naming the self-pipe trick as the idiomatic complex-signal-handling solution, and specifically knowing that malloc/free are NOT async-signal-safe (important because any heap allocation in a handler is undefined behavior).

---

**[JUNIOR] Q4 - [FAILURE] Explain the fork + mutex deadlock problem and how pthread_atfork solves it.**

In a multi-threaded process, when `fork()` is called, the child process gets an exact copy of the parent's address space - including all mutexes in their current locked/unlocked state. If any mutex is locked at the time of fork(), the child inherits the mutex in a locked state. However, the child has only one thread (the thread that called fork()); the thread that owns the locked mutex in the parent does not exist in the child. The mutex's owner field contains a thread ID that does not exist in the child. When the child calls `pthread_mutex_lock()` on that mutex, it either: (1) blocks forever waiting for a non-existent thread to release it, or (2) if it is a reentrant mutex checked by owner TID, returns EDEADLK. The fix is `pthread_atfork(prepare, parent, child)`: prepare runs in the parent before fork and should acquire all locks in a consistent order (preventing partial acquisition races); parent runs in the parent after fork and releases all locks; child runs in the child after fork and re-initializes all mutexes (using `pthread_mutex_init`, not `pthread_mutex_unlock` - you cannot unlock a mutex you do not own). The child handler must reinitialize rather than unlock because the mutex believes it is still owned by the parent thread's TID. The practical recommendation: avoid fork() in multi-threaded programs; use posix_spawn() instead, which combines fork+exec atomically without inheriting lock state.

*What separates good from great:* The precise mechanism (owner TID does not exist in child), the distinction between reinitializing (pthread_mutex_init) vs unlocking (pthread_mutex_unlock) in the child handler, and the posix_spawn() recommendation as the clean alternative.

---

**[MID] Q5 - [DEBUGGING] How would you debug a service that reports EMFILE errors in production?**

EMFILE ("Too many open files") means the process has reached its fd limit. My debugging sequence: First, immediately verify with `ls /proc/$(pgrep myapp)/fd | wc -l` and compare to the process limit from `cat /proc/$(pgrep myapp)/limits | grep "open files"`. If count equals limit, confirmed. Second, increase the limit temporarily without restart: `prlimit --pid $(pgrep myapp) --nofile=65536` - this buys time to investigate without the error recurring every few seconds. Third, inventory: `lsof -p $(pgrep myapp) 2>/dev/null | awk '{print $5}' | sort | uniq -c | sort -rn | head -20` - this shows fd types by count. Seeing thousands of `IPv4` or `IPv6` entries = network socket leak; thousands of `REG` entries to the same file path = file leak. Fourth, track growth: `watch -n 30 'ls /proc/$(pgrep myapp)/fd | wc -l'` for trend. Fifth, for Java: `jcmd <pid> VM.native_memory summary` shows direct buffer usage; heap dump analysis reveals unclosed stream objects. Sixth, code audit: grep for streams and connections opened outside try-with-resources. Seventh, review recent deployments - fd leaks in Java are frequently introduced by code changes that add a new IO path without proper resource management.

*What separates good from great:* The emergency prlimit fix (most engineers think restart is the only option), the lsof type-frequency analysis to identify the leak source, and the jcmd direct memory tracking for Java-specific leaks.

---

**[MID] Q6 - [TRADE-OFF] What is the difference between a file descriptor and a file description?**

These two closely related terms are often confused. A file descriptor (fd) is an integer index in the per-process file descriptor table. It is process-local: fd 4 in process A and fd 4 in process B refer to completely different resources. A file description (also called "open file description" or "open file object") is the kernel object that represents an open instance of a file. It lives in a system-wide table and contains: the current file offset (position for read/write), access mode (O_RDONLY/O_RDWR), file status flags (O_NONBLOCK, O_APPEND), and a pointer to the underlying inode. Multiple file descriptors can point to the same file description: `dup(fd)` creates a new fd in the same process pointing to the same description (they share the offset). `fork()` creates a child where every child fd points to the same description as the corresponding parent fd (parent and child share offset - reads in one process advance the offset seen by the other). `open()` on the same path twice creates two separate file descriptions (separate offsets). This distinction matters for: understanding why dup2() is needed to redirect stdout to a file (not just changing fd 1), why parent and child sharing fds after fork leads to offset corruption if both read sequentially, and why closing a duplicated fd does not close the underlying file (only the last fd referring to a description triggers the actual close and inode unlock).

*What separates good from great:* The fork + shared description offset bug (a common interview follow-up), and explaining that close() decrements the description reference count and only calls the underlying close when count reaches zero.

---

**[MID] Q7 - [BEHAVIORAL] (Behavioral) Describe a production resource leak incident you investigated.**

At a company running a Java HTTP service, we received an alert that a service was returning 503 errors on about 5% of requests every Monday morning. The errors were `java.io.IOException: Too many open files`. Checking fd count showed the process was at 1023/1024. But the service had been running for 3 days without issues - why only Monday? Inspecting lsof showed thousands of file descriptors pointing to a specific S3-backed file path pattern: the service made nightly batch jobs that read S3 files via an S3FileInputStream wrapper. Those streams were opened in a scheduled task. The scheduled task had a try-catch that caught all exceptions and logged them without rethrowing - and the stream was opened before the try block, so exception paths leaked the fd. Sunday night's batch was larger than usual (quarterly reporting data), and 700+ files left streams open. The fix: moved stream open inside try-with-resources. The immediate mitigation: increase the fd limit to 65536 in the systemd unit and add a monitoring alert when fd count exceeds 80% of the limit. The lesson: fd leaks in exception-handling code are invisible until a large enough volume hits the exception path. Code review checklists now include a specific check: "Is every resource opened in this path closed in all exception paths?"

*What separates good from great:* The time-correlation insight (why Monday - the weekly/quarterly batch pattern), the root cause of the silent exception swallowing hiding the leak, the lsof analysis identifying the specific file type, and the code review checklist as the preventive measure.

---

**[MID] Q8 - [TRADE-OFF] What happens at the OS level when a process calls exit() with open file descriptors?**

When a process calls exit() (or returns from main(), or is killed), the kernel performs resource cleanup in a specific sequence: (1) calls C library atexit() handlers, (2) flushes stdio buffers (fflush on all open FILE* streams), (3) for every open file descriptor, decrements the reference count on the underlying open file description; if the count reaches zero, flushes any pending writes (for regular files) and frees the description. For sockets: if the process held the only fd referencing the socket, the TCP/IP stack performs the connection teardown (FIN/RST sending). (4) Releases all virtual memory mappings (munmap is called for each mapping), decrementing page reference counts; pages with count zero become reclaimable. (5) Releases all locks (advisory locks via fcntl/flock; mandatory locks where configured). (6) Sends SIGCHLD to the parent process. (7) Changes the process state to zombie (TASK_ZOMBIE) in the process table - the entry persists until the parent calls wait(). The practical implication: if a process exits without closing a socket, the kernel does close it - but the remote end receives a TCP RST rather than a graceful FIN+FIN+ACK exchange. This disrupts in-flight request processing. Always close connections gracefully before exit() in server code.

*What separates good from great:* The TCP graceful close vs RST distinction on exit (most engineers do not know that exit() without close() sends RST), the zombie transition as the last step, and the page reference count decrement mechanism.

**[SENIOR] Q9 - [TRADE-OFF] What are the trade-offs between using file descriptors vs memory-mapped files for large data transfer?**

File descriptor I/O (`read()`/`write()`) and memory-mapped I/O (`mmap()`) have fundamentally different cost profiles. FD I/O copies data: `read()` invokes a syscall, the kernel copies data from the page cache to a user-space buffer (one copy), and the application processes it from there. `write()` copies from user buffer to the kernel socket buffer. Total: 2 copies plus 2 syscalls per read/write pair. For streaming, sendfile() eliminates the user-space copy (zero-copy for file-to-socket transfers): data moves directly from the page cache to the socket buffer. mmap() maps the file's pages directly into the process's virtual address space: reads access the page cache via virtual memory paging (no syscall after the initial mmap), and the CPU TLB handles the translation. For random access to large files, mmap() wins: reads cause page faults only for the accessed pages (demand paging), and the OS manages the cache efficiently. However, mmap() has hidden costs: page fault overhead for cold reads (each fault requires kernel entry + page table update, typically 1-5 microseconds), TLB invalidation on unmap (which on multi-core systems requires TLB shootdowns - expensive IPI to all cores), and fragmented virtual address space consumption. For large files (> RAM): mmap() triggers page eviction as pages are accessed, with each eviction potentially requiring disk I/O. FD I/O with read-ahead hints (`posix_fadvise(POSIX_FADV_SEQUENTIAL)`) often outperforms mmap() on sequential reads because the kernel's read-ahead logic is optimized for sequential FD I/O. Decision: use mmap() for random access to large files with reuse; use FD I/O with sendfile() for streaming pipelines; use the splice/sendfile family for zero-copy kernel-to-kernel transfers.

*What separates good from great:* The TLB shootdown cost of mmap unmap (an often-overlooked performance cliff), the sendfile/splice distinction for zero-copy, and the `posix_fadvise` optimization for sequential FD I/O outperforming mmap().


---

---

### ⚖️ Comparison Table

| Anti-pattern | Resource Consumed | Symptom | Fix |
|---|---|---|---|
| FD leak | Per-process fd table entries | EMFILE on new open/accept | try-with-resources; close() on all paths |
| Zombie accumulation | Process table entries | Fork failures when PID table full | SIGCHLD handler with waitpid loop |
| mmap leak | Virtual address space | ENOMEM on new mmap | Explicit munmap; track mapping count |
| IPC resource leak | Kernel IPC tables | Persistent /dev/shm or ipcs entries | sem_unlink, mq_unlink before exit |
| Signal handler race | Shared signal state | Sporadic corruption | sig_atomic_t flags; self-pipe pattern |
| Fork+mutex | Thread state | Child deadlock on first mutex acquire | pthread_atfork reinit in child handler |

**The deciding factor:** Most OS resource anti-patterns are detectable with `/proc/<pid>/fd`, `ps`, `lsof`, and `vmstat`. Instrument these as metrics and alert before limits are reached.

---

### 🏛️ System Design

*(Omit: both keywords are ★★☆, not ★★★)*

---

### 📊 Diagram

*(Omit: the taxonomy tables and code examples provide sufficient visual structure for these keywords; a separate diagram does not add clarity)*
