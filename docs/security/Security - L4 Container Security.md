---
layout: default
title: "Security - L4 Container Security"
parent: "Security"
nav_order: 12
permalink: /security/l4-container-security/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Container and Kubernetes Security Hardening](#container-and-kubernetes-security-hardening) | high |

---

# Container and Kubernetes Security Hardening

---
id: SEC-023
title: "Container and Kubernetes Security Hardening"
category: Security
difficulty: "★★★"
interview_weight: high
asked_at: Senior+
seniority: senior
tags: [security, containers, kubernetes, docker, k8s]
status: draft
sd: true
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Container security covers hardening at three layers: the image (minimal base,
> no root, vulnerability scanning), the container runtime (seccomp, AppArmor,
> read-only filesystem, no privileged mode), and the orchestrator (Kubernetes RBAC,
> network policies, Pod Security Standards, secrets management). The most common
> production mistakes are running containers as root, using `:latest` tags, and
> running privileged pods.

**3 minutes (Senior):**
> Container security is defense-in-depth across the build-run-orchestrate stack.
> Image hardening: use distroless or minimal base images (Alpine); scan with Trivy in CI;
> run as non-root user (UID 1000+). Container runtime hardening: `securityContext`
> in Kubernetes sets runAsNonRoot, readOnlyRootFilesystem, drop ALL Linux capabilities,
> add only what is needed. Network segmentation: Kubernetes NetworkPolicy denies all
> traffic by default; allows only explicit paths (pod-to-pod, pod-to-service).
> RBAC: service accounts with minimum permissions; disable token automounting for
> pods that do not need API server access. Secrets: never put secrets in container
> images or environment variables; use Kubernetes secrets mounted as files or
> External Secrets Operator with Vault. Pod Security Standards replace deprecated
> PodSecurityPolicy; enforce `restricted` profile in production namespaces.
> Node security: nodes should not run workloads as root; use dedicated node pools for
> high-sensitivity workloads.

**Framework:** Image -> Runtime -> Network -> RBAC -> Secrets -> Monitoring

**Blank Mind Recovery:**

**(1) Restate:** "Container security is about running workloads with minimum
privileges: non-root user, read-only filesystem, no unnecessary capabilities,
isolated network, least-privilege service accounts."

**(2) First principles:** "Every container shares the host kernel. Any privilege
given to the container (root, privileged mode, host namespace access) is a potential
path from the container to the host."

**(3) Bridge:** "Container security is like the principle of least privilege for
a contractor in an office: you give them a keycard that only opens the specific
rooms they need, not a master key. And you put them in a monitored workspace."

---

### 📘 Concept Explanation

**What it is:**
Container and Kubernetes security hardening is the application of security controls
at every layer of the container stack: base image, build process, container runtime,
Kubernetes configuration, network, and secrets management - to reduce the attack surface
and limit blast radius when a container is compromised.

**Why it matters:**
Containers share the host kernel. A container escape - exploiting a kernel vulnerability
from inside a container - gives an attacker access to the host, and from there to all
other containers on the same node. Hardening makes container escapes significantly
harder and limits what an attacker can do even if they get inside a container.

**Attack surfaces and controls:**

```
CONTAINER ATTACK SURFACE MAP:

  IMAGE:
    Vulnerabilities in base OS packages
      -> scan with Trivy
    Secrets baked into image layers
      -> multi-stage build, no secrets in env
    Running as root
      -> USER directive, runAsNonRoot: true
    Unnecessary tools (curl, bash)
      -> distroless; multi-stage

  CONTAINER RUNTIME:
    Linux capabilities (SYS_ADMIN etc)
      -> drop ALL; add only needed
    Privileged mode (=root on host)
      -> never privileged: true
    Writable filesystem
      -> readOnlyRootFilesystem: true
    Shared host namespaces
      -> hostPID/hostNetwork: false
    Seccomp / AppArmor
      -> apply profiles

  KUBERNETES:
    RBAC over-privilege
      -> least-privilege ClusterRoles
    Default service account tokens
      -> automountServiceAccountToken: false
    No NetworkPolicy
      -> deny-all default + explicit allows
    Secrets in env vars
      -> mount as files; use Vault/ESO
    Images from any registry
      -> ImagePolicyWebhook

  NODE:
    Node OS unpatched
      -> managed node pools; auto-upgrades
    Unrestricted pod scheduling
      -> node taints + dedicated pools
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the complete container attack surface across four layers - image, runtime, Kubernetes, and node - with the corresponding control for each attack vector. (2) KEY MECHANISM: attacks move up the privilege hierarchy; starting in the container, the goal is to escape to the node; from the node, to adjacent pods; from there, potentially the control plane. Each control blocks a rung in this escalation ladder. (3) WHY IT MATTERS: a container running as root with host PID namespace shared is functionally equivalent to running as root on the host; a single application CVE would give an attacker host-level access. (4) WHAT BREAKS: dropping capabilities breaks applications that need specific system calls (e.g., `NET_BIND_SERVICE` for binding to port 80); test with `securityContext` in staging before production. (5) TAKEAWAY: the highest-value controls are runAsNonRoot + readOnlyRootFilesystem + drop ALL capabilities; these three settings eliminate the majority of container escape paths.

---

### 💻 Code Example

```yaml
# BAD: Kubernetes Deployment with no security hardening

apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-bad
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    spec:
      containers:
      - name: myapp
        image: myapp:latest   # never use :latest
        env:
        - name: DB_PASSWORD
          value: "s3cr3t"     # secret in env var
        # no securityContext - runs as root
        # no resource limits
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a Kubernetes Deployment with four common security anti-patterns: `:latest` tag, secret in environment variable, no securityContext, and no resource limits. (2) KEY MECHANISM: `:latest` means the image pulled may differ between deployments; secret in env var is visible in Kubernetes Events, to any process in the container, and in CI logs; no securityContext means the container runs as root (UID 0) with all Linux capabilities. (3) WHY IT MATTERS: running as root means any application vulnerability gives an attacker UID 0 inside the container; combined with a kernel CVE, this is a direct path to host compromise. (4) WHAT BREAKS: changing from root to non-root often breaks applications that write to `/tmp` or assume writable directories; test with `runAsNonRoot: true` in staging first. (5) TAKEAWAY: never use `:latest`; never put secrets in environment variables; always define a securityContext; always define resource limits and requests.

```yaml
# GOOD: Hardened Kubernetes Deployment

apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-good
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    spec:
      # Do not mount service account token unless needed
      automountServiceAccountToken: false

      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
        fsGroup: 1000

      containers:
      - name: myapp
        # Pin image by digest (not :latest or semver)
        image: myapp@sha256:abc123...
        ports:
        - containerPort: 8080

        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
            # add: ["NET_BIND_SERVICE"] if needed

        volumeMounts:
        - name: db-creds
          mountPath: /run/secrets/db
          readOnly: true
        - name: tmp
          mountPath: /tmp

        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "100m"

      volumes:
      - name: db-creds
        secret:
          secretName: myapp-db-creds
          defaultMode: 0400   # owner read-only
      - name: tmp
        emptyDir:
          medium: Memory
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a fully hardened Kubernetes Deployment with eight security controls active: image digest pinning, automountServiceAccountToken disabled, runAsNonRoot with specific UID, readOnlyRootFilesystem, allowPrivilegeEscalation denied, capabilities drop ALL, secrets as volume files with 0400 permissions, and resource limits. (2) KEY MECHANISM: `readOnlyRootFilesystem: true` prevents an attacker who gets code execution from writing to disk; `capabilities: drop: ["ALL"]` removes all 40+ Linux capabilities so even root-equivalent operations are denied; `allowPrivilegeEscalation: false` prevents setuid binaries from being used to gain elevated privileges. (3) WHY IT MATTERS: the combination of read-only filesystem + drop ALL capabilities means even a remote code execution vulnerability gives the attacker only process-level access with no persistence capability; the blast radius is contained to the pod. (4) WHAT BREAKS: applications that write lock files or caches to the root filesystem will fail with read-only; add explicit `emptyDir` volumes for writable paths (`/tmp`, `/var/run`, `/var/cache`). (5) TAKEAWAY: use this template as the baseline for all production Kubernetes deployments; deviations (privilege escalation, host namespaces, root) require explicit security review and documentation.

```yaml
# NetworkPolicy: deny-all default + explicit allows

# Step 1: Deny ALL ingress and egress for namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}    # applies to all pods
  policyTypes:
  - Ingress
  - Egress
---
# Step 2: Allow specific traffic paths
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-myapp-traffic
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Only accept traffic from the ingress controller
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  # Allow DNS
  - ports:
    - protocol: UDP
      port: 53
  # Allow traffic to the database service only
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a Kubernetes NetworkPolicy setup with a default-deny-all policy followed by explicit allow rules that restrict ingress to only the ingress controller and egress to only DNS and the database. (2) KEY MECHANISM: Kubernetes NetworkPolicy is implemented at the CNI level by plugins like Calico or Cilium; pods that match the `podSelector` can only communicate on explicitly permitted paths; all other traffic is dropped at the kernel level. (3) WHY IT MATTERS: without NetworkPolicy, any compromised pod can reach any other pod in the cluster, any database, and any external service; with default-deny, a compromised `myapp` pod can only reach the postgres pod on port 5432 and DNS. (4) WHAT BREAKS: the default-deny policy must be applied carefully; existing services that rely on unrestricted pod communication will fail immediately; audit all pod-to-pod communication paths before applying default-deny. (5) TAKEAWAY: apply NetworkPolicy in enforcement mode only after a 2-week audit period in observation/logging mode; sudden default-deny in production without auditing causes widespread outages.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Container security starts with running as non-root: add `USER 1000` to the Dockerfile
> and `runAsNonRoot: true` to the Kubernetes securityContext. Never use `:latest` images -
> pin by version or digest. Scan container images with Trivy in CI. Never put secrets
> in environment variables or image layers; use Kubernetes Secrets mounted as files.

---

**Senior / Staff (5+ years):**
> My Kubernetes security baseline is enforced through Pod Security Standards at the
> namespace level (restricted profile), which automatically requires runAsNonRoot,
> readOnlyRootFilesystem, and drop ALL capabilities. Network: default-deny NetworkPolicy
> with explicit allow rules - every service knows exactly which pods can reach it.
> Secrets: External Secrets Operator syncs from Vault; rotation is automated.
> Supply chain: all images scanned in CI (Trivy); production cluster uses an
> ImagePolicyWebhook that rejects images without a valid cosign signature.
> For audit: Falco detects runtime anomalies (unexpected syscalls, spawning a shell
> inside a production container).

---

### ⚠️ Common Misconceptions

**Misconception 1: "Containers provide isolation equivalent to virtual machines."**

Containers share the host OS kernel; VMs have isolated kernels. A kernel CVE
(Dirty Pipe: CVE-2022-0847, runc escape: CVE-2019-5736) exploited from inside
a container gives host-level access. VMs with a type-1 hypervisor require a separate
hypervisor escape. Container isolation is a namespaces/cgroups boundary, not a
hypervisor boundary. For highest-security workloads: use gVisor or kata containers
(VM-based container runtimes).

**Misconception 2: "Kubernetes Secrets are encrypted and secure."**

Kubernetes Secrets are base64-encoded, not encrypted, and stored in etcd by default.
Without encryption at rest configured: etcd on disk is plaintext; any principal with
`kubectl get secret` permission reads all secrets; node logs may contain secret values
if passed as environment variables.
Hardening: enable etcd encryption at rest; use External Secrets Operator with Vault
or AWS Secrets Manager; apply RBAC to restrict `get`/`list`/`watch` on secrets.

**Misconception 3: "`privileged: true` is fine for containers that need system access."**

A privileged container has full access to all host kernel features, devices, and
namespaces. It is functionally root on the host. `privileged: true` requires explicit
security review: does the use case require full host access, or just a specific
capability? Almost every legitimate use case can be served by adding specific
capabilities (e.g., `NET_ADMIN` for network tools) instead of full privilege.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Container running as root (UID 0) is compromised.**

Symptom: application CVE gives attacker RCE; attacker has full read/write to container
filesystem, can read all environment variables (including secrets), and may attempt kernel exploit.
Diagnosis: `kubectl exec -it <pod> -- id` shows `uid=0(root)`.
Fix: add `USER 1000:1000` to Dockerfile; set `runAsNonRoot: true` and `runAsUser: 1000`
in securityContext; run image in staging with non-root and fix any filesystem permission errors.

**Failure Mode 2: Production secrets rotated but old secret still in environment variable.**

Symptom: secret rotated in Vault; application still uses old credential because it reads
from environment variable set at pod startup; pod not restarted.
Diagnosis: `kubectl describe pod <name>` shows environment variables; compare timestamp
with Vault rotation time.
Fix: mount secrets as files via External Secrets Operator; application reads file on each
request; Vault rotation updates the Secret object; pod file is updated without restart.

**Failure Mode 3: Lateral movement via pod-to-pod communication in compromised cluster.**

Symptom: attacker escapes application container; scans cluster network; reaches database
pods directly.
Diagnosis: no NetworkPolicy applied (`kubectl get networkpolicy -A` shows empty list).
Fix: apply default-deny NetworkPolicy to all namespaces; verify with Cilium or Calico
network visualization tools before enabling in enforcement mode.

---

### ⚖️ Comparison Table

| Control | Protection | Risk if Skipped | Implementation |
|---|---|---|---|
| **runAsNonRoot** | App CVE: no root access | RCE as root; host escape via kernel CVE | Dockerfile USER + securityContext |
| **readOnlyRootFilesystem** | No malware persistence | Attacker writes backdoor to disk | securityContext + emptyDir for /tmp |
| **drop ALL capabilities** | Limits kernel interaction | Raw socket attacks; kernel module load | capabilities.drop: ["ALL"] |
| **NetworkPolicy** | Limits lateral movement | Compromised pod reaches all others | CNI plugin + deny-all + allow rules |
| **Image scan in CI** | Known CVE prevention | Known CVE deployed to production | Trivy / Grype in CI pipeline |
| **Secrets as files** | No secret in env var | Secret in process listing, logs | ESO + Vault + volume mount |
| **Image signing** | Prevents tampered images | Malicious image deployed | cosign + ImagePolicyWebhook |

---

### 🏛️ System Design

**Container Security Defense-in-Depth Architecture**

```
  REGISTRY         CLUSTER             RUNTIME
  +---------+       +----------+       +--------+
  | Trivy   |       | Admission|       | Falco  |
  | scan CI |       | Webhook  |       | runtime|
  |         |       | (ImagePW)|       | detect |
  | cosign  |-----> | PSS:     |-----> |        |
  | sign    |       | restricted       | seccomp|
  +---------+       | RBAC     |       | AppArmr|
                    | NetPol   |       +--------+
                    +----------+
                         |
                   +------+------+
                   | Node Security|
                   | Patched OS  |
                   | CIS Bench.  |
                   +-------------+
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: three-layer container security architecture from image registry through Kubernetes admission controls to runtime monitoring. (2) HOW TO READ IT: left to right represents the deployment pipeline; each layer independently enforces security controls; a successful attack at one layer is still blocked at the next. (3) KEY RELATIONSHIP: the Admission Webhook (ImagePolicyWebhook) is the enforcement gate in the cluster; it rejects pods that use unsigned images or violate Pod Security Standards. (4) EDGE CASE: the admission webhook itself must be highly available; if the webhook is down and its `failurePolicy` is `Fail`, all pod scheduling stops; use `failurePolicy: Fail` with the webhook deployed as a highly available service. (5) INSIGHT: a senior engineer notices that Falco at runtime is the last line of defense; it detects post-exploitation activity not known at image build time.

---

### 📊 Diagram

```
PRIVILEGE ESCALATION PATH AND CONTROLS:

  [Internet]
      |
  [Ingress Controller]
      |  (only port 443 allowed)
  [App Pod] <-- hardened
      |
  Attacker achieves RCE in App Pod:
  
  UID 1000, not root
    -> privileged ops BLOCKED

  Can't write to FS
    -> persistence BLOCKED

  Can't call SYS_ADMIN
    -> kernel access BLOCKED

  NetworkPolicy: only -> DB:5432
    -> lateral movement BLOCKED

  If kernel CVE attempted:
    -> Seccomp blocks unknown syscalls
    -> Falco alerts on exploit attempt

  Least-privilege service account:
    -> Cannot call Kubernetes API: BLOCKED
    -> Cannot read other namespaces: BLOCKED
```

> **Code walkthrough:** (1) WHAT IT SHOWS: how each security control stops an attacker at each step of the container escape escalation path. (2) KEY MECHANISM: the controls work additively; even if one control has a gap, the next layer stops the attack; depth of defense means the attacker must bypass 5-7 independent controls to reach the host. (3) WHY IT MATTERS: in an unprotected cluster, an app CVE that gives RCE gives the attacker a path to the host and the control plane in minutes; with all controls active, the attack is contained to the pod with no persistence and no lateral movement. (4) WHAT BREAKS: aggressive seccomp profiles can block legitimate syscalls; start with `RuntimeDefault` profile; graduate to custom profiles using Falco's syscall audit output. (5) TAKEAWAY: layered controls mean defense-in-depth; no single control is perfect; the goal is to raise the attack cost above the attacker's willingness to invest.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Security controls, attack surface |
| Mechanism | 3 | Linux capabilities, seccomp, kernel isolation |
| Application | 2 | Hardening Kubernetes, Dockerfile |
| Scenario | 3 | Compromised container, privileged remediation, NetworkPolicy |
| Trade-off | 1 | VMs vs containers |
| Behavioral | 1 | Program building |

---

**[MID] Q1 (Definition): What are the most important security controls for Kubernetes pod security?**

The most critical pod security controls in priority order:

`runAsNonRoot: true` and `runAsUser: 1000`: run the container process as a non-root user.
This is the single highest-value control - a container running as root (UID 0) with
a kernel vulnerability is a one-step host escape.

`readOnlyRootFilesystem: true`: make the container filesystem read-only. Prevents
an attacker with code execution from writing malware to disk, modifying application
code, or creating persistence mechanisms.

`allowPrivilegeEscalation: false`: prevent processes in the container from using
setuid/setgid binaries to gain elevated privileges.

`capabilities: drop: ["ALL"]`: remove all 40+ Linux capabilities from the container.
Linux capabilities are fine-grained slices of root privileges; dropping all of them
eliminates: raw socket access, kernel module loading, filesystem mounting, and many
other kernel interfaces that container escapes rely on.

`seccompProfile: type: RuntimeDefault`: apply a default seccomp profile that blocks
300+ risky syscalls while allowing common application syscalls.

Pod Security Standards (cluster enforcement): enforce these controls at the namespace level
via PSS `restricted` profile; no individual pod can opt out without explicit namespace-level
admission.

*What separates good from great:* Understanding that `automountServiceAccountToken: false`
is equally important. Every pod gets a Kubernetes service account token by default; if
an attacker gets code execution, they immediately have a token to call the Kubernetes
API. For pods that do not need Kubernetes API access, disable token mounting.

---

**[MID] Q2 (Application): How do you harden a Dockerfile?**

Dockerfile hardening applies security controls at the image build stage.

Use a minimal base image: Alpine (~5MB) instead of Ubuntu (~80MB); distroless
(Google's minimal runtime images with no shell, no package manager) for production.
Fewer OS packages = fewer CVEs. Distroless images have no attack surface for
post-exploitation (no bash, no curl, no package manager).

Multi-stage build: use a full build image (with build tools, SDKs) for compilation;
copy only the artifact to a minimal runtime image. Build tools do not belong in
the production image.

Non-root user: create a dedicated application user in the Dockerfile:
`RUN addgroup -S appgroup && adduser -S appuser -G appgroup`
`USER appuser`
The final image runs as a non-root user by default.

No secrets in Dockerfile: do not use `ENV DB_PASSWORD=...` or `COPY .env .`;
build-time secrets should use Docker BuildKit secrets (`--mount=type=secret`) which
do not persist in the image layers.

Pin base image by digest: `FROM alpine@sha256:abc123` instead of `FROM alpine:3.19`.
A digest guarantees the exact image content; a tag can be overwritten.

Scan in CI: run Trivy against the built image before pushing to the registry.
Fail the build if critical CVEs are found in base OS packages or application dependencies.

*What separates good from great:* Removing unnecessary tools. Production images
should not contain: bash, curl, wget, netcat. These tools are useful for debugging
but give attackers post-exploitation capabilities. For debugging in production:
use ephemeral debug containers (`kubectl debug`) that attach to the pod namespace
temporarily; remove them when done.

---

**[SENIOR] Q3 (Mechanism): Explain Linux capabilities and why dropping them all matters.**

Linux capabilities divide the all-or-nothing root privilege into 40+ specific abilities:

- `CAP_NET_BIND_SERVICE`: bind to ports below 1024
- `CAP_NET_RAW`: send raw network packets (ping, ARP spoofing)
- `CAP_SYS_ADMIN`: perform system administration operations (mount filesystems, change namespaces, ptrace processes) - enables dozens of privilege escalation techniques
- `CAP_SYS_PTRACE`: trace arbitrary processes (useful for debuggers, also for privilege escalation)
- `CAP_SYS_MODULE`: load kernel modules (complete kernel compromise)
- `CAP_DAC_OVERRIDE`: bypass filesystem permission checks

By default, Docker grants 14 capabilities to containers. `SYS_ADMIN` was one of
the default capabilities; it alone enables dozens of privilege escalation techniques.

`capabilities: drop: ["ALL"]`: removes all capabilities from the container process.
The container process has UID N but cannot perform any privileged kernel operations
even if it becomes root via a setuid binary or privilege escalation exploit.

Why this matters: most container escape exploits rely on capabilities. The runc escape
(CVE-2019-5736) required the container process to be able to overwrite the runc binary.
Dirty COW (CVE-2016-5195) required the ability to write to `/proc/self/mem`.

After dropping ALL capabilities: add back only what the application specifically needs.
Typical web application: no capabilities needed. Applications binding to port 80:
add `NET_BIND_SERVICE` (or better: run on port 8080 and use a Service to expose port 80).

*What separates good from great:* The capability audit. Run the production application with
`strace -e trace=process` and review all capability-related syscalls. The required set
is a small, documented list. This audit reveals if any dependency or framework uses
unexpected capabilities; address at the dependency level, not by adding back capabilities.

---

**[SENIOR] Q4 (Scenario): A security audit finds a container running in privileged mode. How do you remediate?**

Step 1 - Understand the requirement: `privileged: true` is used because the application
believed it needed host-level access. The first question: what specifically does it need?
Common answers: (a) needs to mount host filesystems (storage drivers, monitoring agents),
(b) needs to run iptables or network configuration, (c) developer added it for debugging
and it was never removed, (d) someone copied a stack overflow answer.

Step 2 - Map capabilities to the actual need:
- Mount filesystems: requires `SYS_ADMIN` specifically; or use a CSI driver so the
  orchestrator handles mounting on behalf of the pod.
- Network configuration: requires `NET_ADMIN` specifically.
- Monitoring agent (Datadog, Falco): typically needs `SYS_PTRACE` and/or `SYS_ADMIN`;
  use DaemonSet with specific capabilities rather than privileged mode.
- No real requirement: remove `privileged: true` immediately.

Step 3 - Replace with minimum capabilities:
Change from `privileged: true` to `capabilities: add: ["NET_ADMIN"]` (or the specific
capability needed). This reduces blast radius from "full host access" to "specific kernel function."

Step 4 - Test in staging: run integration tests with the reduced privilege configuration.

Step 5 - Documentation: document why the specific capability is needed, which workload
uses it, who approved it, and the next review date. Privileged capabilities must be
audited quarterly.

*What separates good from great:* Recognizing that some legitimate use cases exist
for elevated privileges (DaemonSets for node-level monitoring, CNI plugins, storage CSI
drivers). These should run in dedicated namespaces with strict monitoring. The goal is
not to eliminate all privileged workloads but to ensure each one is justified, documented,
and minimally privileged for its specific function.

---

**[SENIOR] Q5 (Application): How do you implement secrets management for Kubernetes workloads?**

The Kubernetes Secrets problem: Kubernetes Secrets are stored in etcd as base64-encoded
data by default. Anyone with `kubectl get secret` access reads them. This is insufficient
for production secrets.

Three-tier secrets architecture:

Tier 1 - At-rest encryption: enable Kubernetes secrets encryption at rest by configuring
the API server with an encryption provider (AES-CBC with a key from a KMS provider like
AWS KMS). This encrypts secrets in etcd on disk.

Tier 2 - External secrets management: use External Secrets Operator (ESO) to sync
secrets from a trusted source (HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager)
into Kubernetes Secrets. The actual secret values live only in Vault; the Kubernetes
Secret is a synchronized copy. ESO refreshes the Secret on a configurable interval;
Vault rotation propagates automatically.

Tier 3 - Pod-level access control: mount secrets as files (not environment variables);
`defaultMode: 0400` (owner read-only); set `readOnly: true` on the volume mount.
Environment variables are visible in `/proc/PID/environ` to any process in the container;
files with strict permissions are not.

Implementation workflow:
1. Application needs a database password.
2. ESO ExternalSecret resource references `vault/secret/myapp/db-creds`.
3. ESO syncs value to `Kubernetes Secret myapp-db-creds`.
4. Pod mounts the secret at `/run/secrets/db/password` (read-only, mode 0400).
5. Application reads `/run/secrets/db/password` at startup.
6. When DBA rotates the password in Vault, ESO updates the Secret; pod file is updated
   without restart (application must handle credential refresh).

*What separates good from great:* Secret version pinning during deployments. When
deploying a new version of an application, the secret version should be pinned to
the Vault version tested in staging. If Vault rotates a secret during a deployment,
the new pod may get a different credential than staging tested. Pin the Vault secret
version in the ExternalSecret resource; bump the pin intentionally when rotating.

---

**[SENIOR] Q6 (Mechanism): What is seccomp and how does it protect containers?**

Seccomp (secure computing mode) is a Linux kernel security mechanism that restricts
which system calls a process can make. It operates at the kernel level: if a process
attempts a blocked syscall, the kernel returns `EPERM` or kills the process depending
on the action configured.

In container security: a seccomp profile defines an allowlist or denylist of Linux
system calls for the container process. The `RuntimeDefault` profile (provided by
the container runtime) allows ~400 common syscalls and blocks 340+ dangerous or
rarely-used syscalls.

Why seccomp matters: container escapes typically use unusual syscalls not needed by
normal applications: `keyctl` (kernel keyring), `unshare` (create new namespaces),
`ptrace` (trace other processes), `bpf` (load eBPF programs with kernel access).
Blocking these at the kernel level makes kernel exploits significantly harder.

Configuring in Kubernetes:

```yaml
securityContext:
  seccompProfile:
    type: RuntimeDefault
```

> **Code walkthrough:** (1) WHAT IT SHOWS: applying the RuntimeDefault seccomp profile in Kubernetes pod securityContext. (2) KEY MECHANISM: this one line instructs the container runtime (containerd/CRI-O) to apply the built-in seccomp profile that blocks 340+ risky syscalls; it applies to all containers in the pod. (3) WHY IT MATTERS: without this, all ~400 Linux syscalls are available to the container process; attackers rely on unusual syscalls for privilege escalation and container escape. (4) WHAT BREAKS: a minority of applications call unusual syscalls for legitimate reasons; if the application crashes or hangs after applying RuntimeDefault, check `dmesg` for seccomp denials and add a custom profile that allows the specific needed syscall. (5) TAKEAWAY: always apply `type: RuntimeDefault` as the baseline; it costs nothing in performance for I/O-bound workloads and eliminates hundreds of potential kernel attack vectors.

Difference from AppArmor: seccomp restricts syscalls; AppArmor restricts file paths,
network access, and capabilities. Both are complementary; use both for defense-in-depth.

*What separates good from great:* Building a custom seccomp profile. Tools like
`sysdig` or `strace` capture all syscalls made by the application during normal operation.
This becomes the exact allowlist. A custom profile is narrower than RuntimeDefault
and provides stronger protection. The maintenance cost: custom profiles must be
updated when the application starts using new syscalls.

---

**[SENIOR] Q7 (Trade-off): How does container security compare to VM security?**

Isolation model:
- Containers: shared host kernel; isolated by Linux namespaces and cgroups. A kernel
  vulnerability escapes all containers on the host.
- VMs: isolated kernel per VM; hypervisor mediates all hardware access. A kernel
  vulnerability in a guest VM requires a separate hypervisor escape to reach the host.

In practice: VMs provide stronger isolation guarantees. For multi-tenant environments
(cloud providers, platform teams running untrusted workloads), VM-level isolation is
the standard. For single-tenant workloads with trusted code, hardened container
security is sufficient and offers faster startup and higher density.

Hybrid approaches: gVisor (Google) and kata containers (CNCF) provide VM-level isolation
with container tooling. They run each container in a lightweight VM or with an
intercepting kernel; `runsc` (gVisor) intercepts syscalls and translates them through
a sandboxed Go kernel. Cost: 10-30% performance overhead.

Use container security hardening (PSS restricted, seccomp, capabilities) for standard
workloads; use gVisor/kata containers for high-risk workloads (untrusted code execution,
public-facing AI inference, multi-tenant SaaS platforms).

*What separates good from great:* The breakout path analysis for the specific threat model.
An organization running customer code (serverless, notebook environments) cannot trust
container isolation; gVisor or per-customer VMs are required. An organization running
only its own trusted applications with hardened securityContext has a very different
threat model; standard containers with strong controls are appropriate.

---

**[SENIOR] Q8 (Scenario): Your Kubernetes cluster has no NetworkPolicy. A pod is compromised. What is the blast radius?**

Without NetworkPolicy, a compromised pod can:
1. Reach every other pod in the cluster (no network segmentation).
2. Call any Service, including the Kubernetes API server (with the default service account token).
3. Reach databases, message queues, internal admin services.
4. Exfiltrate data to the internet (no egress restriction).
5. Spread to other pods by exploiting vulnerabilities in services it can now reach.

In a cluster with 200 pods, a single compromised pod can pivot to all 200 pods within
minutes. This is a full cluster compromise, not an isolated incident.

Remediation steps:

Step 1 - Audit current communication: enable network flow logging (Cilium Hubble or
Calico flow logs); run for 2 weeks to capture all legitimate pod-to-pod communication.

Step 2 - Build NetworkPolicy from flow data: use Cilium Network Policy Editor or
`kubectl-np-viewer` to generate NetworkPolicy definitions from observed flows.
This ensures allow rules match reality, not assumptions.

Step 3 - Apply in enforcement mode: start with a non-blocking namespace (staging);
verify no legitimate traffic is blocked; then apply to production namespace by namespace.

Step 4 - Apply default-deny: once allow rules are complete, apply a `podSelector: {}`
default-deny NetworkPolicy. Traffic not matching explicit allow rules is now blocked.

Step 5 - Monitor: set up alerts for NetworkPolicy violations to detect lateral movement attempts.

*What separates good from great:* The Kubernetes API server access problem. Even with
NetworkPolicy, every pod with `automountServiceAccountToken: true` (the default) has a
token to call the Kubernetes API. An attacker can list all namespaces, describe all pods,
and read all secrets using the pod's service account token. NetworkPolicy + disabling
service account token automounting are both required.

---

**[SENIOR] Q9 (Application): How do you detect post-compromise activity in a running Kubernetes cluster?**

Runtime security monitoring uses behavioral detection: observe what containers actually
do and alert on anomalies, not just known bad signatures.

Falco (CNCF): monitors system calls from all containers using eBPF probes.
Pre-built rules detect: shell spawned inside a production container, unexpected process
execution, sensitive file reads (`/etc/shadow`, `~/.ssh/`), network connections to
unexpected external IPs, writing to `/proc` or `/sys`, loading a kernel module.

Alert rule example: "shell spawned in container" triggers if `execve` is called with
`sh` or `bash` as the target binary in a non-development container. Severity HIGH -
legitimate production containers do not spawn shells; this is almost always an attacker
or a debug command run in production by mistake.

Kubernetes Audit Logs: every API call (kubectl exec, kubectl get secrets, pod creation)
is logged in the Kubernetes API server audit log. Configure audit policy to log: secret
reads, exec into pods, ClusterRole changes, and service account token requests.
Alert on: `kubectl exec` in production, reading secrets by unexpected service accounts,
new cluster admin bindings.

Container image baseline: compare running processes in the container against an expected
list at startup; alert if new processes appear (indicates post-exploitation tool execution).

*What separates good from great:* Combining Falco with audit logs. Falco sees process-level
activity inside containers (syscalls, file access). Kubernetes audit logs see the Kubernetes
API activity (what the compromised pod or its service account is doing with Kubernetes APIs).
Together they provide a complete picture: Falco shows the attack in the container; audit
logs show what the attacker is doing with the Kubernetes control plane.

---

**[SENIOR] Q10 (Scenario): A developer claims they need `privileged: true` for a debugging tool. How do you respond?**

Initial response: challenge the assumption before accepting it. "Privileged" is often
added because it was the easiest path, not the minimum necessary.

Investigation: ask for specifics. What exact system call or resource does the tool need?
Common answers:
- "It needs to see all processes": requires `SYS_PTRACE` or `shareProcessNamespace: true`
  on the pod, not full privilege.
- "It needs to access host network": requires `hostNetwork: true` or `NET_ADMIN` capability.
- "It needs to read kernel metrics": requires access to `/proc` or `/sys` host paths via
  hostPath volume with read-only mount, not privilege.

Options for legitimate debugging needs:
1. Use ephemeral containers (`kubectl debug -it <pod> --image=debug-tools`): attaches
   a debug container to the running pod's namespace temporarily; the debug container can
   have elevated capabilities without making the production container privileged.
2. Dedicated debug DaemonSet: run a monitoring/debugging daemon on each node with the
   minimum capabilities it needs; applications do not need privilege.
3. Specific capability: if `SYS_PTRACE` is genuinely needed, add exactly that capability
   to the pod with documented justification.

Policy: `privileged: true` requires: security team review, documented business reason,
time-limited annotation (expires in 90 days), and is not permitted in production namespaces
by Pod Security Standards restricted profile.

*What separates good from great:* Recognizing that debugging needs are often temporary
and should not affect production security posture permanently. Ephemeral debug containers
(added in Kubernetes 1.23) were specifically designed to solve this problem: attach a
privileged debug container temporarily to diagnose an issue, then remove it. The production
container's security configuration remains unchanged.

---

**[SENIOR] Q11 (Application): How do you enforce container security standards across a large Kubernetes fleet?**

Enforcing at scale requires policy-as-code, not per-team checklists.

Pod Security Standards (PSS): Kubernetes 1.25+ built-in policy. Three profiles:
privileged (no restrictions), baseline (prevents obvious privilege escalation), restricted
(enforces all hardening controls). Apply at namespace level:
`pod-security.kubernetes.io/enforce: restricted` label on namespace.
Any pod violating the restricted profile is rejected at admission.

OPA/Gatekeeper (if custom policies needed): for policies PSS does not cover (required
labels, image registry allowlist, required resource limits), use OPA/Gatekeeper with
ConstraintTemplates. Example: reject all pods that use an image from a registry
other than `registry.company.internal`.

Kyverno: an alternative to Gatekeeper with simpler YAML-based policies; excellent for
teams without Rego knowledge.

Policy management workflow:
- All SecurityContext policies are defined in a central policy repository.
- Applied to all clusters via GitOps (ArgoCD or Flux syncs the policy repo).
- New clusters automatically get all security policies.
- Policy exemptions require: PR to the policy repo, security team review, time-limited
  annotation on the namespace.

*What separates good from great:* The policy exception process. Every large organization
has legitimate exceptions (a DaemonSet that needs `SYS_ADMIN` for node monitoring).
Without a formal exception process, teams disable policy enforcement globally to
unblock their workload. A formal exception process: exception PR, security review,
time-limited (90-day) annotation; reviewed quarterly. This keeps the fleet at high
security compliance (95%+) without creating a culture of global policy bypass.

---

**[STAFF] Q12 (Behavioral): How do you build a container security program from scratch for an organization moving to Kubernetes?**

Container security program in three phases (6-month plan):

Phase 1 - Baseline (month 1-2): measurement and quick wins.
Actions:
- Run CIS Kubernetes Benchmark (kube-bench) against the cluster; fix Critical and High
  findings (often: API server flags, kubelet configuration, etcd encryption).
- Run Trivy against all production images; catalog critical CVEs; prioritize by service exposure.
- Apply resource limits and requests to all pods (prevents node resource exhaustion).
Metrics: CIS benchmark score, number of critical CVEs in production images.

Phase 2 - Hardening (month 2-4): apply controls.
Actions:
- Enable Pod Security Standards (restricted profile) in staging namespaces.
- Fix all PSS violations (runAsNonRoot, readOnlyRootFilesystem, drop ALL caps).
- Apply NetworkPolicy (default-deny + explicit allows) starting with highest-risk
  namespaces (databases, auth services).
- Deploy External Secrets Operator; migrate secrets from env vars to mounted files.
Metrics: PSS restricted compliance percentage (target: 100% before production rollout).

Phase 3 - Monitoring and automation (month 4-6):
Actions:
- Deploy Falco with standard ruleset; integrate alerts with SIEM.
- Implement image signing with cosign; ImagePolicyWebhook rejects unsigned images.
- OPA/Gatekeeper for custom policies (approved registry, required labels, resource limits).
- Developer enablement: internal hardened Helm chart templates with security controls
  pre-configured; developers get security for free by using the template.
Metrics: "mean time to detect post-compromise activity" (Falco alert latency, target: < 5 minutes).

*What separates good from great:* Developer enablement as the strategy. Security controls
that require developers to add 30 lines of YAML to every Deployment create friction and
compliance debt. Provide a pre-hardened Helm chart template (securityContext pre-configured,
NetworkPolicy boilerplate, ESO ExternalSecret template) and document it as the default way
to deploy. Security compliance becomes the path of least resistance, not an additional burden.
