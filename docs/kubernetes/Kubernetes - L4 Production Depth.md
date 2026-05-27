---
layout: default
title: "Kubernetes - L4 Production Depth"
parent: "Kubernetes"
grand_parent: "SK Interview"
nav_order: 7
permalink: /kubernetes/l4-production-depth/
---

# Kubernetes Debugging and Troubleshooting

🎯 Interview Weight: very high - Every production Kubernetes
operator needs a systematic debugging mental model. Tested at
senior+ level.

---

### 🎯 Model Answer

**30 seconds:**
> Kubernetes debugging follows a top-down approach: check pod
> status, describe the pod (events), check logs, exec into the
> container if needed, then check cluster-level issues (nodes,
> network, RBAC). Common commands: `kubectl get pods`,
> `kubectl describe pod`, `kubectl logs`, `kubectl exec`,
> `kubectl events`, and `kubectl top pods/nodes`.

**3 minutes (Senior):**
> Kubernetes debugging decision tree:
>
> Step 1 - Pod not running:
> `kubectl get pods -n <namespace>` - check phase and status.
> Phase: Pending, Running, Succeeded, Failed, Unknown.
> Status: CrashLoopBackOff, OOMKilled, ImagePullBackOff,
> Terminating, ContainerCreating, Init:N/M.
>
> Step 2 - Describe the pod:
> `kubectl describe pod <pod> -n <namespace>`
> Shows: Events (scheduling failure, image pull error),
> resource requests vs limits, node assignment,
> probe failures, volume mounts.
>
> Step 3 - Logs:
> `kubectl logs <pod> -n <namespace> --previous` (crashed pod)
> `kubectl logs <pod> -n <namespace> -c <container>` (multi-container)
> `kubectl logs <pod> -n <namespace> --tail=100 -f` (stream)
>
> Step 4 - Exec into the container:
> `kubectl exec -it <pod> -n <namespace> -- /bin/sh`
> Check: network connectivity (curl, nslookup), file system,
> environment variables, process state.
>
> Step 5 - Service connectivity:
> `kubectl get endpoints <svc>` - is the service finding pods?
> Empty endpoints = selector mismatch or pods not ready.
> `kubectl run debug --rm -it --image=curlimages/curl -- sh`
> Test service DNS: `nslookup my-service.namespace.svc.cluster.local`
>
> Step 6 - Resource issues:
> `kubectl top pods -n <namespace>` - CPU/memory usage.
> `kubectl top nodes` - node resource pressure.
> `kubectl describe node <node>` - node conditions, allocatable.

**Blank Mind Recovery:**

**(1) Restate:** "Debug pods top-down: status -> describe -> logs
-> exec -> cluster level."

---

### 💻 Code Example

```bash
# Kubernetes debugging cheatsheet

# 1. Broad scan
kubectl get pods -A | grep -v Running

# 2. Inspect failing pod
kubectl describe pod <pod> -n <ns>
# Key sections to read:
#   Events: (bottom) - scheduler, image pull, probe failures
#   Conditions: Ready, ContainersReady
#   Containers.State: Reason, Message, ExitCode

# 3. Logs
kubectl logs <pod> -n <ns> --previous  # crashed pod
kubectl logs <pod> -n <ns> -f --tail=50  # live

# 4. Test service DNS resolution
kubectl run -it debug --rm \
  --image=curlimages/curl \
  --restart=Never -- sh
# Then: curl http://my-service.mynamespace.svc.cluster.local

# 5. Check endpoints (is service finding pods?)
kubectl get endpoints my-service -n <ns>
# Empty = no matching pods (selector mismatch or NotReady)

# 6. Resource usage
kubectl top pods -n <ns> --sort-by=memory

# 7. Recent events (last 1 hour)
kubectl events -n <ns> --for pod/<pod>

# 8. Node health
kubectl describe node <node> | grep -A5 Conditions
# Look for: MemoryPressure, DiskPressure, PIDPressure

# 9. Port-forward for local debugging
kubectl port-forward <pod> 8080:8080 -n <ns>
# Access: localhost:8080/actuator/health
```

> **Code walkthrough:** The cheatsheet follows the debugging
> hierarchy. `get pods -A | grep -v Running` quickly finds all
> non-healthy pods cluster-wide. `describe pod` is the most
> informative single command - read the Events section last
> (most recent). `get endpoints` is the fastest way to diagnose
> service routing failures (empty endpoints = no pods selected).
> `kubectl run debug` creates a temporary pod in the same network
> namespace to test DNS and HTTP connectivity.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> The most time-saving K8s debug technique: ephemeral debug
> containers (K8s 1.23+). `kubectl debug -it <pod> --image=
> ubuntu --target=<container>` attaches a debug container to
> a running pod, sharing the process namespace. You can use
> `strace`, `tcpdump`, and other tools that are not in the
> production image - without restarting the pod. For a
> CrashLoopBackOff pod (exits immediately), use `kubectl debug
> <pod> --copy-to=debug-pod --set-image=*=busybox -- sleep 3600`
> to copy the pod spec with a replacement image that stays alive.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | Status phases + describe + logs workflow |
| Senior | 8 min | Service endpoints + ephemeral containers |
| Staff | 12 min | Network debugging + cluster-level diagnosis |

---

---

# OOMKilled and Resource Problems

🎯 Interview Weight: very high - OOMKilled is one of the most
common Kubernetes production issues. Deep diagnosis expected.

---

### 🎯 Model Answer

**30 seconds:**
> OOMKilled means the Linux kernel's OOM killer terminated the
> container process because its memory usage exceeded the cgroup
> memory limit. In Kubernetes, this appears as container status
> `OOMKilled` with exit code 137. Fix: increase memory limit
> OR reduce actual memory usage (fix leak, tune JVM, cap
> non-heap). Never just increase limits without understanding
> why memory grew.

**3 minutes (Senior):**
> OOMKilled diagnosis and resolution:
>
> Verify OOMKilled:
> `kubectl describe pod <pod>` -> Containers -> Last State:
> `Reason: OOMKilled`, `Exit Code: 137`.
> `dmesg | grep -i oom` on the node (if accessible): shows
> which process was killed and its memory usage at kill time.
>
> Identify the memory consumer:
> Memory types that contribute to cgroup RSS:
> (a) JVM heap: check `/actuator/metrics/jvm.memory.used`
>     histogram - was heap growing before kill?
> (b) Metaspace: check `jvm.memory.used{area=nonheap}`
> (c) Direct buffers: `-XX:NativeMemoryTracking=summary` +
>     `jcmd <pid> VM.native_memory` (if accessible before kill)
> (d) Thread stacks: growing thread count from thread pool leak
> (e) Native memory (JNI, Netty, gRPC): hardest to diagnose.
>     Enable `-XX:+NativeMemoryTracking=detail` and dump.
>
> Common root causes:
> Memory leak: class loading leak, listener not removed,
> cache without eviction, connection pool not closed.
> Misconfiguration: no MaxRAMPercentage, JVM using host RAM stats.
> Workload increase: same config, more traffic, more memory.
> Libraries: Netty direct buffers, gRPC frame buffers.
>
> OOM vs OOMKilled difference:
> `java.lang.OutOfMemoryError: Java heap space` = JVM heap full.
> JVM may throw OOM and survive (if caught), or exit.
> `OOMKilled` = kernel killed the process because cgroup limit
> exceeded. Can happen without any Java OOMError if off-heap
> grows.
>
> Resolution strategy:
> 1. Add `-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp`
>    for next occurrence.
> 2. Analyze heap dump with Eclipse MAT or IntelliJ.
> 3. Fix the root cause (not just increase the limit).
> 4. Increase limit as temporary measure while fixing root cause.

**Blank Mind Recovery:**

**(1) Restate:** "OOMKilled = kernel killed container for exceeding
memory limit. Check JVM heap vs non-heap vs native memory."

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> The Netty off-heap surprise: gRPC and Spring WebFlux use Netty,
> which allocates direct (off-heap) ByteBuffers for network
> I/O. These do not appear in JVM heap metrics. Under high load
> with 10,000 concurrent requests, Netty may allocate 500MB of
> direct buffers, pushing total RSS above the container limit.
> No Java OOMError is thrown. The container is simply killed.
> Fix: set `-XX:MaxDirectMemorySize=256m` and limit concurrent
> gRPC streams. Monitor `DirectMemory` via Micrometer's
> `jvm.buffer.memory.used{id=direct}`.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | OOMKilled vs OOMError + exit code 137 |
| Senior | 7 min | Heap vs non-heap diagnosis + heap dump analysis |
| Staff | 10 min | Netty direct buffers + NativeMemoryTracking |

---

---

# Pod Scheduling and Eviction Issues

🎯 Interview Weight: high - Pending pods and unexpected evictions
are common production issues. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Pending pods fail to schedule because no node satisfies the
> constraints. Common reasons: insufficient CPU/memory, taint
> not tolerated, affinity/anti-affinity rules, unschedulable
> node. Pod eviction occurs when a node is under memory or disk
> pressure - Kubernetes evicts lowest-priority pods first.
> Fix pending: check node resources and pod constraints.
> Fix eviction: increase node capacity or reduce pod requests.

**3 minutes (Senior):**
> Scheduling failure diagnosis:
>
> `kubectl describe pod <pending-pod>` -> Events section:
> `0/3 nodes are available: 3 Insufficient cpu.`
> `0/3 nodes are available: 1 node(s) had taint ...`
> `0/3 nodes are available: 3 node(s) didn't match Pod's
> node affinity/selector.`
>
> Common causes:
> (a) Resource exhaustion: all nodes' allocatable CPU/memory
>     is fully claimed by existing pod requests.
>     `kubectl describe node <node>` -> Allocated resources.
>     Note: allocatable ≠ actual usage. Pods can have high
>     requests with low actual usage - "wasted" reserved capacity.
>
> (b) Taint/toleration mismatch: node has a taint (e.g.,
>     `spot=true:NoSchedule`), pod does not tolerate it.
>     Fix: add toleration to pod spec.
>
> (c) Node affinity: pod requires a label the nodes do not have.
>     `kubectl get nodes --show-labels` to verify.
>
> (d) Anti-affinity: pods cannot co-locate. If rule is
>     `requiredDuringSchedulingIgnoredDuringExecution` and
>     there are 3 replicas but only 3 nodes and one already
>     has a copy, the 4th replica is stuck pending.
>
> Eviction causes:
> Node memory pressure: Kubelet detects node memory below
> threshold. Evicts BestEffort pods first (no requests set),
> then Burstable (requests < limits), then Guaranteed last.
> Priority class affects eviction order within each QoS class.
>
> Pod disruption budget (PDB): controls how many pods can be
> evicted simultaneously. `minAvailable: 2` means at least 2
> pods must be running during evictions/rolling updates.
> Without PDB: all pods could be evicted simultaneously.

**Blank Mind Recovery:**

**(1) Restate:** "Pending = no node fits. Check resources,
taints, affinity. Eviction = node pressure removes lower-priority pods."

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> The cluster autoscaler adds nodes when pods are pending due
> to resource constraints. It DOES NOT add nodes for Pending
> pods blocked by affinity/taints/PodAntiAffinity. Engineers
> often wonder why the autoscaler is not triggering - it is
> because the pod is not schedulable even on a new node of
> the same type. `kubectl describe pod` Events show the exact
> reason. The autoscaler only triggers when the scheduling
> failure reason is resource exhaustion.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Pending causes + describe pod events |
| Senior | 7 min | QoS eviction order + PDB + autoscaler limitations |
| Staff | 10 min | Priority classes + preemption + cluster-wide scheduling |

---

---

# Kubernetes Networking Diagnosis

🎯 Interview Weight: high - Networking failures are among the
hardest K8s issues to debug. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Kubernetes networking failures: service not reachable
> (check endpoints, selector, kube-proxy), DNS resolution
> failure (check CoreDNS pods), pod-to-pod communication failure
> (check NetworkPolicy, CNI plugin health), external ingress failure
> (check ingress controller logs, TLS config). Every K8s service
> is a virtual IP (ClusterIP) backed by iptables/IPVS rules
> managed by kube-proxy.

**3 minutes (Senior):**
> Kubernetes networking layers:
>
> Pod network: every pod gets a unique IP (via CNI plugin:
> Calico, Flannel, Cilium). Pods on different nodes communicate
> via overlay network (VXLAN, BGP). Pod IPs are ephemeral
> (change on restart) - never connect to pod IPs directly.
>
> Service (ClusterIP): stable virtual IP + DNS name.
> `my-service.namespace.svc.cluster.local` resolves to ClusterIP.
> kube-proxy writes iptables/IPVS rules to forward ClusterIP
> traffic to pod endpoints.
>
> Service DNS resolution failure:
> `nslookup my-service.namespace.svc.cluster.local` from a pod.
> If it fails: check CoreDNS pods (`kubectl get pods -n kube-system`).
> CoreDNS CrashLoopBackOff = DNS broken cluster-wide.
>
> Service endpoints empty:
> `kubectl get endpoints my-service -n <ns>` shows `<none>`.
> Cause: label selector mismatch, pods not Ready.
> `kubectl get pods -l app=my-service -n <ns>` - do pods
> match the service selector and are they Ready?
>
> NetworkPolicy blocking traffic:
> If a pod cannot reach another pod and there are NetworkPolicies
> in the namespace, test by temporarily removing them.
> `kubectl get networkpolicy -n <ns>` - list active policies.
> Cilium: `cilium connectivity test` - built-in connectivity check.
> Calico: `calicoctl policy` - inspect active allow/deny rules.
>
> Service type and external access:
> ClusterIP: internal only.
> NodePort: accessible via node IP + port.
> LoadBalancer: creates cloud load balancer (AWS ELB, GCP LB).
> Ingress: HTTP/HTTPS routing via ingress controller.
> Ingress 502 Bad Gateway: ingress controller cannot reach backend pods.

**Blank Mind Recovery:**

**(1) Restate:** "K8s networking: pods get IPs, services get
stable VIPs, kube-proxy does iptables routing, CoreDNS does DNS."

---

### 💻 Code Example

```bash
# K8s networking diagnosis toolkit

# 1. Test service DNS from inside a pod
kubectl run dns-test --rm -it \
  --image=curlimages/curl \
  --restart=Never -- \
  sh -c "nslookup my-service.my-ns.svc.cluster.local"
# Expected: returns ClusterIP
# Failure: ; connection timed out -> CoreDNS problem

# 2. Check service endpoints
kubectl get endpoints my-service -n my-ns
# Expected: 10.0.0.5:8080,10.0.0.6:8080
# Failure: <none> -> selector/readiness issue

# 3. Verify pod labels match service selector
kubectl get pods -n my-ns --show-labels
kubectl get svc my-service -n my-ns -o jsonpath=\
  '{.spec.selector}'

# 4. Check CoreDNS health
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 5. Test pod-to-pod connectivity
kubectl exec -it pod-a -n my-ns -- \
  curl http://10.0.0.5:8080/health
# Direct pod IP test (bypasses service/kube-proxy)

# 6. List NetworkPolicies
kubectl get networkpolicy -n my-ns
# If any exists: check they allow the needed traffic

# 7. Check kube-proxy iptables rules for a service
# SSH to node, then:
iptables -L -t nat | grep <service-name>
# Should see DNAT rules for the ClusterIP -> pod endpoints
```

> **Code walkthrough:** The diagnosis flows from DNS (Layer 7)
> down to raw pod IP connectivity (Layer 3). `nslookup` tests
> CoreDNS. `get endpoints` tests the service controller's
> label matching. `curl` to the pod IP tests the CNI overlay
> network directly. NetworkPolicy inspection rules out firewall
> issues. The `iptables` check on the node confirms kube-proxy
> has programmed the DNAT rules correctly.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> Cilium eBPF mode replaces iptables entirely with eBPF programs
> loaded into the kernel. At scale (10,000+ services), iptables
> has O(N) lookup time (linear scan of rules). eBPF provides
> O(1) lookup via hash tables. Cilium also provides built-in
> Hubble observability: `cilium hubble observe` shows real-time
> network flows between pods. This dramatically reduces
> networking diagnosis time - you can see exactly which policy
> is dropping packets without guessing.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | DNS diagnosis + endpoints check |
| Senior | 7 min | NetworkPolicy debugging + kube-proxy internals |
| Staff | 10 min | eBPF/Cilium + multi-cluster networking |

---

---

# Kubernetes Security Hardening

🎯 Interview Weight: high - Security in K8s is expected at
senior level. Pod security, RBAC, and secrets management.

---

### 🎯 Model Answer

**30 seconds:**
> Kubernetes security layers: RBAC (who can do what to which
> resources), Pod Security Standards (what containers can do),
> Network Policies (what pods can communicate with whom), Secrets
> management (how sensitive data is stored and accessed), and
> supply chain security (verified container images). The principle
> of least privilege applies at every layer: pods should have
> the minimum permissions necessary.

**3 minutes (Senior):**
> Security hardening checklist:
>
> RBAC:
> Avoid `ClusterRoleBinding` with broad permissions. Use
> namespace-scoped `RoleBinding`. Service accounts should
> bind to roles with only the verbs they need.
> Anti-pattern: pod with `cluster-admin` service account.
> Fix: create a dedicated ServiceAccount with a Role that
> permits only the required verbs on required resources.
>
> Pod Security Standards (PSS):
> Replaces PodSecurityPolicy (deprecated K8s 1.21+).
> Three levels: Privileged (no restrictions), Baseline
> (blocks privileged containers), Restricted (most secure).
> Enforce at namespace level:
> `pod-security.kubernetes.io/enforce: restricted`
>
> Key security settings in pod spec:
> `securityContext.runAsNonRoot: true` - no root containers.
> `securityContext.readOnlyRootFilesystem: true` - immutable FS.
> `securityContext.allowPrivilegeEscalation: false` - no sudo.
> `capabilities.drop: [ALL]` - drop all Linux capabilities.
> `capabilities.add: [NET_BIND_SERVICE]` - add only needed ones.
>
> Secrets management:
> K8s Secrets are base64-encoded, not encrypted (by default).
> In etcd, Secrets are stored unencrypted unless encryption
> at rest is configured.
> Production options:
> (1) K8s encryption at rest: `--encryption-provider-config`
>     in kube-apiserver. Encrypts Secrets in etcd.
> (2) External Secrets Operator: pulls secrets from AWS
>     Secrets Manager, Vault, GCP Secret Manager into K8s Secrets.
> (3) Vault Agent Sidecar: injects secrets directly into pod
>     filesystem without storing in K8s Secrets at all.
>
> Image security:
> Sign images with Cosign (sigstore). Admission controller
> (Kyverno, OPA Gatekeeper) verifies signatures before
> scheduling. Block unsigned or unverified images.

**Blank Mind Recovery:**

**(1) Restate:** "K8s security: RBAC for identity, PSS for
container constraints, NetworkPolicy for network, Vault for secrets."

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> The most common Kubernetes security vulnerability in the wild:
> overly permissive service accounts. A pod with a ClusterAdmin
> service account can list all secrets cluster-wide, create
> pods in any namespace, and read any ConfigMap. If the pod is
> compromised (SSRF, RCE), the attacker has full cluster access.
> Audit with: `kubectl auth can-i --list --as=system:serviceaccount:<ns>:<sa>`
> to see all permissions of a service account. The fix is
> always scoped RoleBindings with minimal verbs.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | RBAC basics + pod security contexts |
| Senior | 7 min | PSS + secrets encryption + External Secrets |
| Staff | 10 min | Supply chain + admission controllers + audit |

**[DEBUGGING] A pod is CrashLoopBackOff. kubectl logs shows
nothing. How do you debug it?**
`[MID]`

*Why they ask:* Tests practical debugging experience beyond
the happy path.

*Likely follow-up:* "The describe shows no useful events either."

Step 1: `kubectl describe pod <pod>` - read Events and Container
State. If state shows `Reason: Error` with `ExitCode: 1`, the
app exited with error. If `ExitCode: 137` = OOMKilled.
Step 2: `kubectl logs <pod> --previous` - logs from the previous
container instance. If it crashed before writing any logs,
there may be nothing.
Step 3: Check the exit code. ExitCode 1 = application error
(crash before logging). ExitCode 2 = misuse of shell. ExitCode
127 = command not found (entrypoint wrong). ExitCode 137 =
OOMKilled. ExitCode 143 = SIGTERM not handled.
Step 4: Temporarily override the entrypoint to keep the
container alive: `kubectl debug <pod> --copy-to=debug --set-image
=*=busybox -- sleep 3600` and exec in to manually run the
entrypoint and see the error.
Step 5: Check for missing environment variables, ConfigMaps,
or Secrets the app expects. `kubectl get secret` and
`kubectl get configmap` in the namespace.
Step 6: Check init containers - if an init container fails,
the main container never starts. `kubectl describe pod` shows
init container status.

*What separates good from great:* Knowing exit codes, using
`--previous` flag, and the debug container override technique.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Debugging methodology + exit codes |
| K8s/Platform | OOMKilled + security hardening |
| Bar Raiser | Systematic diagnosis + cluster-level thinking |
