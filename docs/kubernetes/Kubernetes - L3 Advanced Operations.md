---
layout: default
title: "Kubernetes - L3 Advanced Operations"
parent: "Kubernetes"
nav_order: 5
permalink: /kubernetes/l3-advanced-operations/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Kubernetes Operators and CRDs](#kubernetes-operators-and-crds) | expert |
| 2 | [Network Policies and Security](#network-policies-and-security) | expert |
| 3 | [Pod Security Standards](#pod-security-standards) | expert |
| 4 | [Resource Quota and Limit Ranges](#resource-quota-and-limit-ranges) | expert |
| 5 | [Custom Scheduling and Affinity Rules](#custom-scheduling-and-affinity-rules) | expert |

---

# Kubernetes Operators and CRDs

**Interview Weight:** expert - Operators are the pattern for extending
Kubernetes to manage stateful applications. Senior engineers are expected
to understand the operator pattern, CRD design, and controller reconciliation
loops, especially for managing Java-heavy stateful infrastructure.

---

### 🎯 Model Answer

**30 seconds:**

> A CRD (Custom Resource Definition) extends the Kubernetes API with new resource
> types. An Operator is a controller that watches CRDs and implements operational
> logic - encoding the knowledge of how to deploy and manage a specific application.
> The pattern: you define a desired state via a custom resource (e.g., KafkaCluster
> with replicas: 3), and the operator reconciles the actual Kubernetes resources
> to match. Operators replace manual operational procedures with automated,
> Kubernetes-native management.

**3 minutes (Senior):**

> The Operator pattern extends the Kubernetes control loop to custom resources.
> The reconciliation model is identical to built-in controllers: watch for
> desired state changes, compare to actual state, take action to converge.
>
> CRD design: a CRD registers a new API type with the Kubernetes API server.
> After creating the CRD, you can create, list, and watch instances of that type
> using standard kubectl and client-go calls. The CRD defines the schema (OpenAPI
> v3) for validation. Admission webhooks add custom validation beyond what the
> schema can express.
>
> Operator development frameworks: Operator SDK (Go-based, most mature),
> Kubebuilder (Go, very similar to Operator SDK, widely used), KOPF (Python),
> Java Operator SDK (Quarkus and Spring Boot compatible). For Java teams: Java
> Operator SDK allows writing operators in Java using the same frameworks the
> team already knows.
>
> Real-world operators: Strimzi (Apache Kafka), CloudNativePG (PostgreSQL),
> CrunchyData PostgreSQL Operator, Prometheus Operator, Argo CD, Cert-Manager.
> These operators encode years of operational knowledge: Strimzi knows how to
> perform rolling upgrades of Kafka brokers while maintaining partition leadership.
>
> When to build vs buy: build an operator when you have a complex stateful
> application that requires domain-specific reconciliation (a proprietary system
> with specific HA semantics). Use existing operators for standard infrastructure
> (PostgreSQL, Kafka, Redis, Prometheus).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Kubernetes Operators - how to extend
Kubernetes to manage custom applications."

**(2) First principles:** "Kubernetes built-in controllers manage built-in
resources (Deployment, ReplicaSet). Operators apply the same pattern to
custom resources."

**(3) Bridge:** "CRD is the vocabulary. The Operator is the interpreter that
acts on that vocabulary. Define KafkaCluster, and the Kafka Operator knows
how to create, scale, upgrade, and recover Kafka clusters from that declaration."

---

### 📘 Concept Explanation

**What it is:**
Custom Resource Definitions extend the Kubernetes API with new resource types.
Operators are controllers that manage these custom resources by encoding
operational knowledge (deployment, scaling, backup, recovery) into a
reconciliation loop.

**The problem it solves:**
Complex stateful applications (Kafka, Cassandra, PostgreSQL) require domain-specific
operational procedures (leader election, quorum management, partition rebalancing).
These procedures cannot be expressed in Kubernetes built-in resources. Operators
encode this knowledge as automated reconciliation.

**How it works:**

```
Operator Architecture:

  CRD Registration:
    kubectl apply -f kafkacluster-crd.yaml
    kubectl api-resources | grep kafka
    # KafkaCluster  strimzi.io/v1beta2

  Custom Resource (user creates):
    apiVersion: kafka.strimzi.io/v1beta2
    kind: KafkaCluster
    metadata:
      name: my-kafka
    spec:
      kafka:
        replicas: 3
        storage:
          type: persistent-claim
          size: 100Gi

  Operator Reconciliation Loop:
    Watch KafkaCluster objects
    For each change:
      1. Read desired state from KafkaCluster
      2. Read actual state from Kubernetes
         (StatefulSets, Services, PVCs)
      3. Compute diff
      4. Apply changes:
         - Create missing StatefulSets
         - Update config in running pods
         - Execute rolling upgrade safely
         - Update status sub-resource

  Status Sub-resource:
    kubectl get kafkacluster my-kafka
    # NAME      READY   BROKERS  STATUS
    # my-kafka  True    3        Running

Java Operator SDK Example:
  @Controller
  public class KafkaClusterReconciler
      implements Reconciler<KafkaCluster> {

    public UpdateControl<KafkaCluster> reconcile(
        KafkaCluster kafkaCluster,
        Context<KafkaCluster> context) {
      // 1. Read desired state from kafkaCluster.getSpec()
      // 2. Create/update StatefulSet
      // 3. Create/update Service
      // 4. Return UpdateControl.patchStatus(...)
    }
  }
```

**The key insight:**
Operators are the mechanism for encoding "Day 2 operations" as code. Day 1
operations (initial deployment) are often easy. Day 2 operations (scaling,
upgrade, backup, recovery, certificate rotation) are where the value lies.
Strimzi's Kafka Operator encodes Kafka-specific knowledge: how to upgrade
brokers without losing partitions, how to rebalance after scaling, how to
handle zone failures.

**When to write a custom operator:**
A proprietary application requires custom HA management. A configuration
management pattern repeats across 20+ applications (a custom abstraction
reduces YAML duplication). An existing operator lacks a specific feature
needed in your environment.

**First-principles derivation:**
The operator pattern is the logical extension of the controller pattern.
Built-in controllers manage built-in resources. CRDs allow defining any
resource. Operators manage those custom resources using the identical
reconciliation pattern. The Kubernetes API server handles: authentication,
authorization, schema validation, watch distribution, etcd persistence.
The operator implements only the domain logic.

---

### 💻 Code Example

**Example 1: Custom CRD for a Java microservice configuration**

```yaml
# CRD: JavaMicroservice custom resource
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: javamicroservices.company.io
spec:
  group: company.io
  names:
    kind: JavaMicroService
    plural: javamicroservices
    singular: javamicroservice
    shortNames: ["jms"]
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required: ["image", "jvmMemoryMi"]
            properties:
              image:
                type: string
              jvmMemoryMi:
                type: integer
                minimum: 256
                maximum: 8192
              replicas:
                type: integer
                default: 2
                minimum: 1
              springProfile:
                type: string
                default: "production"
    subresources:
      status: {}    # Allow status updates
      scale:        # Support kubectl scale
        specReplicasPath: .spec.replicas
        statusReplicasPath: .status.replicas

---
# Usage: teams create JavaMicroService instances
apiVersion: company.io/v1
kind: JavaMicroService
metadata:
  name: payment-service
  namespace: team-a
spec:
  image: "myregistry.io/payment-service:v2.1.0"
  jvmMemoryMi: 1024  # Operator computes limit = 1024/0.75
  replicas: 3
  springProfile: "production"
# Operator creates: Deployment, Service, HPA, ConfigMap
# with all golden path defaults applied
```

> **Code walkthrough:** The CRD defines a JavaMicroService resource with
> an OpenAPI v3 schema that validates input (jvmMemoryMi minimum 256, maximum
> 8192). The schema with required fields catches missing configuration at
> admission time - before the operator even runs. The scale subresource allows
> `kubectl scale jms payment-service --replicas=5` to work natively. The status
> subresource enables the operator to update the resource's status without
> triggering a reconciliation loop (status updates use a separate API path,
> preventing infinite reconciliation triggers). When a team creates this
> JavaMicroService, the operator computes the container memory limit (1024 /
> 0.75 = 1365Mi), creates a Deployment with all golden path security contexts
> and probes, creates a Service, and creates an HPA.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> A CRD adds a new resource type to Kubernetes. An Operator watches those
> resources and creates or manages standard Kubernetes resources based on them.
> For example: the Strimzi Kafka Operator watches KafkaCluster resources and
> creates StatefulSets, Services, and ConfigMaps to run Kafka.

*Push deeper:* "The operator pattern encodes operational knowledge that would
otherwise require human intervention. Without a Postgres Operator, upgrading
a PostgreSQL StatefulSet from version 14 to 15 requires manual: pg_upgrade,
backup, validate, promote new replica, redirect traffic. With the CloudNativePG
Operator, you change version: 15 in the Cluster resource and the operator
performs the upgrade safely with automated rollback on failure."

---

**Senior / Staff (5+ years):**

> I have used Java Operator SDK to build internal platform operators. The pattern
> I use: a JavaMicroService CRD that teams create instead of raw Kubernetes YAML.
> The operator generates all required Kubernetes resources (Deployment, HPA, Service,
> NetworkPolicy, PodDisruptionBudget) from a 10-line CRD instance, enforcing
> platform standards automatically.
>
> The reconciliation loop pitfalls: (1) handle ResourceVersion conflicts (return
> and requeue when a resource is updated concurrently), (2) use finalizers for
> resources that require cleanup on deletion, (3) set requeue intervals instead
> of busy-looping on expected-to-be-slow operations, (4) implement idempotent
> reconciliation (running reconcile multiple times produces the same result).

*Push deeper:* "The status sub-resource is critical for operator quality.
The status.conditions pattern mirrors built-in Kubernetes resources: a Conditions
array with type, status, reason, message, and lastTransitionTime. This makes
operator status readable by kubectl and by platform tooling that monitors
conditions. Avoid using the top-level status fields arbitrarily - follow the
Kubernetes condition pattern for consistency."

---

### ⚖️ Comparison Table

| Approach | Operator | Manual StatefulSet | Managed Cloud Service |
|---|---|---|---|
| **Operational automation** | Full (Day 2 encoded) | None (manual) | Full (vendor) |
| **Cost** | Time to develop/maintain | Human ops time | Service premium |
| **Customization** | Full control | Full control | Limited |
| **Time to production** | Months to develop | Days (but ongoing ops) | Hours |

**The deciding factor:** Use existing operators for standard infrastructure.
Build custom operators only for proprietary systems requiring complex lifecycle
management that no existing operator covers.

---

### ⚠️ Common Misconceptions

**"Any complex Kubernetes configuration should become an Operator."**

Operators are appropriate when the application requires domain-specific
automated reconciliation (not just templating). For generating standard
Kubernetes resources from a simpler interface: Helm charts or Kustomize
patches are lower complexity. Reserve operators for genuine operational
automation (backup, failover, scaling procedures).

**"CRDs replace existing Kubernetes resources."**

CRDs extend the Kubernetes API; they do not replace built-in resources.
The Kafka Operator's KafkaCluster CRD creates StatefulSets, Services, and
PVCs under the hood. CRDs are a higher-level abstraction layer that still
relies on built-in resources.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Operator CrashLoopBackOff | Custom resources not reconciled | `kubectl logs operator-pod` for error | Fix operator code; check RBAC for operator ServiceAccount |
| Schema validation failure | kubectl apply fails with validation error | Error message shows field schema violation | Fix CRD spec; check openAPIV3Schema |
| Reconciliation loop | Operator constantly reconciling, high API calls | Operator metrics: reconcile_total increasing rapidly | Fix idempotency; check for unconditional updates |
| Operator lacks RBAC | Resources not created | `kubectl logs operator-pod` shows Forbidden | Add required verbs to operator ClusterRole |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | CRD concept, operator purpose |
| Mid | 6 min | Reconciliation loop, real-world operators |
| Senior | 10 min | Status sub-resource, finalizers, Java Operator SDK |
| Staff | 12 min | Custom operator design, condition pattern |

---

**[STAFF] Q1 - ARCHITECTURE: Design an internal
Kubernetes Operator that standardizes Spring Boot
deployments for a platform team.**

*Why they ask:* Platform engineering and operator design thinking.

*Likely follow-up:* "How do you handle teams that need to override defaults?"

Design for a SpringBootService Operator:

Goal: application teams create a 10-line YAML, operator generates all
required Kubernetes resources with platform standards enforced.

CRD Design (SpringBootService):
```yaml
spec:
  image:         string (required)
  version:       string (required)
  jvmMemoryMi:   integer (256-8192, default 512)
  replicas:      integer (1-20, default 2)
  autoscaling:
    enabled:     boolean (default false)
    minReplicas: integer (default 2)
    maxReplicas: integer (default 10)
  ingress:
    enabled:     boolean (default false)
    host:        string
  database:
    required:    boolean (default false)
    secretName:  string
  overrides:     # Escape hatch for advanced config
    deploymentAnnotations: map[string]string
    envFrom:     []EnvFromSource
```

Generated Resources (operator creates all of these):
- Deployment: with probes, resource limits (jvmMemoryMi / 0.75),
  security context (non-root, readOnly filesystem), labels
- Service: ClusterIP
- HPA: if autoscaling.enabled
- Ingress: if ingress.enabled, using org cert-manager issuer
- NetworkPolicy: deny all ingress except from ingress namespace
- PodDisruptionBudget: minAvailable: 1
- ServiceAccount: with automountServiceAccountToken: false

Overrides design: the overrides section provides an escape hatch for teams
with legitimate needs that deviate from standards. This prevents teams from
forking the chart or bypassing the operator entirely. Log overrides usage
to metrics so platform team can identify patterns that should become first-class
spec fields.

Status design:
```yaml
status:
  conditions:
  - type: Available
    status: "True"
    reason: AllReplicasReady
    lastTransitionTime: "2024-01-15T10:00:00Z"
  observedGeneration: 2
  readyReplicas: 3
  desiredReplicas: 3
  deploymentName: payment-service
```

*What separates good from great:* The overrides escape hatch - preventing
teams from bypassing the operator by providing a structured way to handle
edge cases within the operator's control.

---

**[BEHAVIORAL] Q2 - Tell me about a time you used
or evaluated a Kubernetes Operator in production.**

*Why they ask:* Practical operator experience.

*Likely follow-up:* "What were the trade-offs?"

Pattern for a strong behavioral answer:

Situation: "We were running PostgreSQL on Kubernetes via a StatefulSet managed
by our platform team. Backup and failover were manual scripts, which meant
on-call engineers needed PostgreSQL expertise to execute recovery procedures."

Task: "I evaluated CloudNativePG Operator as a replacement that would encode
these operational procedures."

Action: "I tested CloudNativePG in staging: created a Cluster resource with
3 replicas (1 primary, 2 replicas), configured the ScheduledBackup resource
for nightly S3 backups, and ran a chaos test (deleted the primary pod).
CloudNativePG automatically promoted a replica, updated the readwrite Service
endpoint to the new primary, and notified via events. Total failover: 15 seconds.
Previous manual process: 10-15 minutes."

Result: "Deployed to production. On-call burden for PostgreSQL reduced
significantly - most incidents are handled automatically. Manual recovery
procedures only needed for cluster-level issues."

*What separates good from great:* Specific numbers (15-second failover,
10-15 minutes previously) and a concrete chaos test story.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Java platform engineer | Operator SDK | Java Operator SDK, reconciliation patterns |
| SRE | Operations | Strimzi, CloudNativePG, operational reduction |
| Staff architect | Design | CRD design, status conditions |
| Backend engineer | Usage | How to use existing operators |

---
---

# Network Policies and Security

**Interview Weight:** expert - Network Policies are the Kubernetes mechanism
for network segmentation. Production security requires Network Policies that
restrict pod-to-pod communication. Interviewers test practical configuration
and the default-allow vs default-deny model.

---

### 🎯 Model Answer

**30 seconds:**

> By default, all pods in Kubernetes can communicate with all other pods
> (including across namespaces). Network Policies restrict this: a NetworkPolicy
> selects pods by label and defines allowed ingress and egress. The default
> model is additive: no NetworkPolicy = allow all. Adding a policy that selects
> a pod restricts it to only what the policy allows. The most important policy:
> a default-deny-all policy that blocks everything, then explicit allow policies
> for required communication.

**3 minutes (Senior):**

> Network Policies are enforced by the CNI plugin (Calico, Cilium, Weave).
> The standard CNI (Flannel, kubenet) does NOT enforce Network Policies - you
> need a CNI that supports them.
>
> Policy model: Network Policies are namespaced. They select pods using
> podSelector (label matching within the namespace). Ingress rules allow traffic
> from (podSelector from another namespace, namespaceSelector) to the selected
> pod. Egress rules allow traffic from the selected pod to destinations.
>
> Important: if no NetworkPolicy selects a pod, all traffic is allowed
> (including cross-namespace). When at least one NetworkPolicy selects a pod,
> only traffic explicitly allowed by policies is permitted. This means adding
> a Network Policy makes the pod more restrictive, not less.
>
> Default deny pattern: create a policy that selects all pods (empty
> podSelector matches everything in the namespace) and has no ingress or egress
> rules. This blocks all traffic. Then create explicit allow policies for each
> required communication path.
>
> Limitations: Network Policies operate at L3/L4 (IP + port). They cannot
> filter by HTTP method, path, or headers. For L7 filtering: use a service
> mesh (Istio AuthorizationPolicy) or an external L7 policy engine (OPA,
> Cilium Network Policy with L7 support).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Kubernetes Network Policies - how
to restrict pod-to-pod network communication."

**(2) First principles:** "Zero-trust networking: deny all by default, allow
only what is required. Network Policies implement this at the Kubernetes
pod level."

**(3) Bridge:** "Network Policy is like a firewall rule set for pods. Default:
allow all. After adding a policy: only what the policy explicitly allows."

---

### 📘 Concept Explanation

**What it is:**
NetworkPolicy is a Kubernetes resource that restricts pod-to-pod (and pod-to-external)
network communication using label selectors for pod and namespace matching and
port/protocol specifications.

**The problem it solves:**
Kubernetes default networking allows all pods to communicate with all other pods.
In a shared cluster with multiple teams and services, this means a compromised
pod can reach any other pod. Network Policies enforce segmentation.

**How it works:**

```
Default Kubernetes Networking:
  No NetworkPolicy: ANY pod -> ANY pod (no restriction)

NetworkPolicy Enforcement:
  Policy selects pod A (via podSelector)
  -> Pod A is now restricted
  -> Only traffic matching at least one policy is allowed

  Policy does NOT select pod B
  -> Pod B is still unrestricted (allow all)

Default Deny (baseline):
  Select all pods, no ingress/egress rules:
    podSelector: {}  # Matches ALL pods in namespace
    policyTypes:
    - Ingress
    - Egress
  -> All pods blocked (nothing allowed)

Then add explicit allows:
  Allow ingress-controller -> payment-service
  Allow payment-service -> postgres:5432
  Allow all pods -> kube-dns:53 (DNS resolution)
  Allow all pods -> kubernetes API server (if needed)

CNI Support Matrix:
  Calico:   Network Policy + CIDR-based rules
  Cilium:   Network Policy + L7 policy (HTTP paths)
  Weave:    Network Policy
  Flannel:  NO Network Policy support
  kubenet:  NO Network Policy support
```

**The key insight:**
Network Policies are additive only. You cannot create a policy that explicitly
DENIES traffic. You can only create policies that ALLOW traffic (and everything
not explicitly allowed is denied once a policy selects the pod). The way to
deny specific traffic is to not have a policy that allows it.

**When to use Cilium L7 policies:**
When you need HTTP-level control: allow GET /api/* but deny POST /api/admin/*.
Cilium extends NetworkPolicy to support L7 rules (HTTP method, path, header)
using its own CRDs (CiliumNetworkPolicy).

**First-principles derivation:**
Zero-trust networking requires: deny by default, allow explicitly, verify
identity. Network Policies provide deny-by-default (default deny policy)
and allow-explicitly (ingress/egress rules). Identity verification (mTLS
service-to-service) requires a service mesh. Together: network policies +
mTLS implement the zero-trust model.

---

### 💻 Code Example

**Example 1: Default deny + explicit allow for microservices**

```yaml
# Step 1: Default deny ALL in namespace
# Applies to all pods (empty podSelector)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}    # Selects ALL pods in namespace
  policyTypes:
  - Ingress
  - Egress
# No ingress/egress rules = deny all for all pods

---
# Step 2: Allow DNS (required for any service name resolution)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}  # All pods
  policyTypes: [Egress]
  egress:
  - ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP

---
# Step 3: Allow Ingress Controller -> payment-service
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-payment
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-service
  policyTypes: [Ingress]
  ingress:
  - from:
    # Allow from nginx-ingress namespace
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ingress-nginx
      podSelector:
        matchLabels:
          app.kubernetes.io/name: ingress-nginx
    ports:
    - port: 8080
      protocol: TCP

---
# Step 4: Allow payment-service -> postgres (DB)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-payment-to-postgres
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-service
  policyTypes: [Egress]
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - port: 5432
      protocol: TCP
```

> **Code walkthrough:** The default-deny-all policy selects all pods (empty
> podSelector) and specifies both Ingress and Egress policy types with no rules.
> This blocks all traffic for all pods in the namespace. Without the allow-dns
> policy, pod hostnames would not resolve (CoreDNS on port 53). The ingress
> controller policy uses both namespaceSelector and podSelector together (AND
> logic) - traffic is only allowed if it comes from a pod in the ingress-nginx
> namespace that also has the ingress-nginx pod label. Using only namespaceSelector
> would allow any pod in that namespace. The payment-to-postgres egress policy
> restricts payment-service to only being able to connect to postgres pods on
> port 5432, preventing lateral movement even if payment-service is compromised.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Network Policies restrict pod-to-pod communication. By default, all pods
> can reach all pods. A NetworkPolicy selects pods by label and defines
> allowed ingress (incoming) and egress (outgoing) traffic. The most important
> practice: create a default deny policy (empty selector, no rules) then
> explicitly allow required traffic.

*Push deeper:* "The CNI plugin must support Network Policies for them to
be enforced. Flannel does not support Network Policies. If you apply a
NetworkPolicy to a cluster running Flannel, the policy is stored in etcd
but has no effect on actual traffic. Always verify your CNI supports
Network Policies: Calico, Cilium, and Weave all do."

---

**Senior / Staff (5+ years):**

> The namespaceSelector + podSelector combination is the most important
> operator to understand. When you write `from: [namespaceSelector: A, podSelector: B]`
> as two entries in the list, it is OR logic (from namespace A OR from pod B).
> When you write `from: [{namespaceSelector: A, podSelector: B}]` as a single
> entry with both selectors, it is AND logic (from pod B in namespace A).
> This distinction causes subtle security misconfigurations.
>
> For production compliance: I recommend Cilium over Calico for clusters
> that need L7 network policies (HTTP-level access control). Cilium's
> eBPF implementation provides better performance than Calico's iptables
> implementation and supports CiliumNetworkPolicy for HTTP path and method
> filtering. The performance difference is significant at high connection rates
> (>10k connections/second per node).

*Push deeper:* "Network Policy debugging is difficult because there is no
built-in tool to show which policies are affecting a pod. Approaches: (1)
kubectl get networkpolicy -n namespace and trace manually, (2) Cilium Hubble
CLI shows dropped packets with the policy rule that dropped them (the most
useful debugging tool), (3) Calico calicoctl tool shows which policies match
a specific pod."

---

### ⚖️ Comparison Table

| Approach | Layer | Enforcement | Logging | Use Case |
|---|---|---|---|---|
| **Kubernetes NetworkPolicy** | L3/L4 | CNI plugin | None (CNI-specific) | Basic pod segmentation |
| **Cilium NetworkPolicy** | L3/L4/L7 | eBPF | Hubble flow logs | HTTP-level control |
| **Istio AuthorizationPolicy** | L7 (mTLS) | Envoy sidecar | Access log | Service identity auth |
| **OPA Gatekeeper** | API admission | Webhook | Audit log | Policy as code |

**The deciding factor:** Kubernetes NetworkPolicy for baseline pod segmentation.
Cilium for L7 HTTP-level policies. Istio AuthorizationPolicy when already using
Istio for mTLS and need service-identity-based access control.

---

### ⚠️ Common Misconceptions

**"Network Policies work with any CNI plugin."**

Network Policies require a CNI plugin that implements the Network Policy spec.
Flannel, AWS VPC CNI (without Calico or Cilium overlay), and kubenet do NOT
enforce Network Policies. Applying a Network Policy to a cluster with an
unsupported CNI has no effect - all traffic still flows.

**"namespaceSelector and podSelector in the same `from` entry is AND logic."**

This is correct AND it is the most common source of Network Policy security bugs.
When both selectors are in the same `from` entry: AND logic (both must match).
When they are separate entries in the `from` list: OR logic (either can match).
Double-check policy intent against the Kubernetes Network Policy documentation.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| DNS blocked | Pods cannot resolve service names | All connections fail (not just specific pods); test `kubectl exec nslookup` | Add allow-dns NetworkPolicy for port 53 |
| Missing ingress rule | Service unreachable (connection timeout) | `kubectl get networkpolicy` shows policy selects pod; no matching ingress | Add ingress rule for the traffic source |
| CNI not enforcing | Policy exists but no effect | Flannel CNI; traffic flows despite policy | Install Calico/Cilium overlay |
| OR vs AND logic mistake | Wrong pods allowed through | Policy allows from any pod in namespace | Fix: use single dict entry with both selectors for AND |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Default allow model, NetworkPolicy purpose |
| Mid | 6 min | Default deny pattern, DNS exception |
| Senior | 10 min | CNI support, selector AND/OR logic |
| Staff | 12 min | L7 policies, zero-trust architecture |

---

**[SENIOR] Q1 - SECURITY: A pod was compromised.
What Network Policy configurations could have
limited the blast radius?**

*Why they ask:* Security posture and defense-in-depth.

*Likely follow-up:* "What could the attacker still do?"

Scenario: payment-service pod is compromised by a RCE vulnerability.
What the attacker can do WITHOUT Network Policies:
- Reach any other pod in the cluster (database, auth service, secrets)
- Scan the entire pod CIDR (typically 10.0.0.0/8)
- Exfiltrate data to any external IP
- Access the Kubernetes API server (if no RBAC)

What Network Policies limit:

Egress restrictions:
If payment-service has an egress policy that only allows:
- postgres:5432 (database)
- kafka:9092 (message broker)
- DNS:53 (hostname resolution)
Then the attacker CANNOT:
- Reach other microservices (no path to auth-service, user-service)
- Scan the pod CIDR for additional targets
- Connect to external IPs (no public IP egress)
- Connect to internal metadata service (169.254.169.254)

What the attacker CAN still do (with policies):
- Exfiltrate data through the allowed egress paths
  (exfiltrate via postgres, Kafka topics)
- Access the Kubernetes API if it is in the allowed CIDR
- Perform attacks on the allowed endpoints (postgres, Kafka)

Additional mitigations:
- automountServiceAccountToken: false (no K8s API access)
- Read-only root filesystem (no malware persistence)
- Network Policy blocking metadata service (169.254.169.254)
  to prevent SSRF-based credential theft

*What separates good from great:* Identifying what Network Policies
CANNOT prevent (exfiltration through allowed paths) and what
additional controls are needed.

---

**[SENIOR] Q2 - DEBUGGING: You added a default-deny
NetworkPolicy but now some services are broken.
How do you triage?**

*Why they ask:* Network Policy debugging in production.

*Likely follow-up:* "What if Cilium Hubble is not installed?"

Systematic triage after default-deny breaks services:

Step 1: Identify affected services
Which services are returning errors? What error type?
- Connection refused (port blocked) vs
- DNS resolution failure (DNS port blocked)
Both indicate Network Policy issues but require different fixes.

Step 2: Check DNS first
DNS is always broken by default-deny unless explicitly allowed.
Test: `kubectl exec <pod> -- nslookup kubernetes.default`
If this fails: add allow-dns egress policy (UDP/TCP port 53 to kube-dns).

Step 3: Test specific service connectivity
`kubectl exec <source-pod> -- nc -zv <dest-service> <port>`
(nc = netcat, tests TCP connection)
If connection times out: Network Policy is blocking.
If DNS resolves but connection times out: egress policy missing on source
or ingress policy missing on destination.

Step 4: List NetworkPolicies and trace
`kubectl get networkpolicy -n production`
For each affected pod:
- Does the pod have a policy that selects it? (any ingress policy?)
- Does the source have an egress policy that allows the connection?

Step 5: Cilium Hubble (if available)
`hubble observe --pod-from payment-service --verdict DROPPED`
Shows exactly which packets are dropped and which policy rule dropped them.
This is the fastest diagnostic tool.

Without Hubble: check Cilium logs:
`kubectl logs -n kube-system -l k8s-app=cilium | grep DROP`

*What separates good from great:* DNS is ALWAYS the first thing to check
after adding a default-deny policy. Most engineers forget it.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Security engineer | Zero-trust | Default deny, blast radius |
| Platform engineer | Architecture | CNI choice, Cilium vs Calico |
| SRE | Operations | Debugging (Hubble), DNS exception |
| Developer | Usage | Basic policy structure |

---
---

# Pod Security Standards

**Interview Weight:** expert - Pod Security Standards replaced the deprecated
PodSecurityPolicy in Kubernetes 1.25. Every production cluster should enforce
them. Interviewers test knowledge of the three policy levels and how to
migrate Java services to comply.

---

### 🎯 Model Answer

**30 seconds:**

> Pod Security Standards (PSS) define three policy levels enforced by the
> PodSecurity admission controller. baseline: prevents known privilege
> escalations (no privileged containers, no hostNetwork, no hostPID).
> restricted: implements security best practices (non-root user, read-only
> filesystem, drop all capabilities, no hostPath). privileged: no restrictions.
> Each namespace is labeled with the enforcement level. Java services should
> run under restricted with specific exemptions (non-root user requirement
> is satisfied by setting runAsNonRoot: true in securityContext).

**3 minutes (Senior):**

> PSS replaced PodSecurityPolicy (PSP) in Kubernetes 1.25 (PSP was deprecated
> in 1.21, removed in 1.25). The key difference: PSP was a complex admission
> policy per-pod. PSS is a simple namespace label that enforces one of three
> predefined profiles.
>
> The three profiles:
> - privileged: no restrictions (for infrastructure pods: kube-system, Cilium
>   DaemonSet, monitoring agents)
> - baseline: prevents the most dangerous configurations (no privileged containers,
>   no hostNetwork, no hostPID, no seccomp profiles required, no most dangerous
>   capabilities). Suitable for most general-purpose workloads.
> - restricted: hardened security following pod security best practices.
>   Requirements: non-root user (runAsNonRoot: true), non-root group (runAsGroup > 0),
>   seccompProfile set, no privilege escalation (allowPrivilegeEscalation: false),
>   capabilities: drop ALL (and only add allowed subset), read-only filesystem.
>
> Three enforcement modes per namespace:
> - enforce: reject non-compliant pods
> - warn: allow but show warning
> - audit: allow but log to audit log
> Use audit/warn first to identify violations, then switch to enforce.
>
> Java service compliance for restricted profile:
> Most Spring Boot services can comply with restricted by adding:
> runAsNonRoot: true, runAsUser: 1000, allowPrivilegeEscalation: false,
> capabilities: drop ALL, seccompProfile: RuntimeDefault.
> The main challenge: some services write to /tmp (for heap dumps, temp files).
> Solution: emptyDir volume mounted at /tmp with readOnlyRootFilesystem: true
> on the rest of the filesystem.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Pod Security Standards - how Kubernetes
enforces security profiles on pods in a namespace."

**(2) First principles:** "Containers running as root can escape to the host.
Privileged containers bypass kernel isolation. PSS prevents these high-risk
configurations by default."

**(3) Bridge:** "PSS is like a building's safety code: Level 1 (baseline) prevents
the most dangerous practices. Level 2 (restricted) enforces all best practices.
Some rooms (kube-system) are exempt for necessary maintenance access."

---

### 📘 Concept Explanation

**What it is:**
Pod Security Standards define three security profiles (privileged, baseline,
restricted) enforced at the namespace level via labels. The built-in PodSecurity
admission controller validates pods against the profile before admission.

**The problem it solves:**
Container escape vulnerabilities are most dangerous when containers run as root,
have privileged mode, or mount host filesystems. PSS prevents these configurations
as a platform-enforced baseline, ensuring that even poorly configured application
pods cannot escalate to host-level access.

**How it works:**

```
PSS Enforcement:

  Namespace labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/audit: restricted

  Profile Comparison:
  Policy                    | privileged | baseline | restricted
  ---------------------------------------------------------------
  Privileged containers     | Allowed    | Denied   | Denied
  hostNetwork               | Allowed    | Denied   | Denied
  hostPID / hostIPC         | Allowed    | Denied   | Denied
  hostPath volumes          | Allowed    | Denied   | Denied
  Running as root           | Allowed    | Allowed  | Denied
  Privilege escalation      | Allowed    | Allowed  | Denied
  Capabilities (arbitrary)  | Allowed    | Restricted | Drop ALL
  seccomp                   | Allowed    | Allowed  | Required
  readOnlyRootFilesystem    | Allowed    | Allowed  | Required*
  (* seccompProfile Required, filesystem optional)

  Java Service - restricted compliant securityContext:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: [ALL]
```

**The key insight:**
Enforcing restricted profile requires addressing the writable filesystem problem.
Java services often write to /tmp (heap dumps, Logback rolling appenders, Tomcat
temp directory). With readOnlyRootFilesystem: true, these writes fail. The
solution: emptyDir volumes mounted at specific paths (/tmp, /var/log, /app/temp).

**When to use baseline vs restricted:**
baseline for workloads that need some flexibility (writing to the filesystem,
using standard capabilities). restricted for all user-facing services and
any pod handling sensitive data. privileged only for infrastructure pods in
kube-system namespace.

**First-principles derivation:**
Container security risk is proportional to container privileges. Root containers
with capabilities can mount host filesystems and exploit kernel vulnerabilities
to escape the container. PSS profiles represent points on the privilege continuum.
Restricted removes all optional privileges, maximizing isolation. The tradeoff
is application compatibility (apps that need root or write access require changes).

---

### 💻 Code Example

**Example 1: Spring Boot pod compliant with restricted PSS**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  template:
    spec:
      # Pod-level security context
      securityContext:
        runAsNonRoot: true     # Required: restricted
        runAsUser: 1000        # Non-root UID
        runAsGroup: 1000       # Non-root GID
        fsGroup: 1000          # Volume ownership
        seccompProfile:
          type: RuntimeDefault # Required: restricted

      # emptyDir for JVM temporary file writes
      volumes:
      - name: tmp
        emptyDir: {}
      - name: heap-dumps
        emptyDir: {}

      containers:
      - name: app
        image: payment-service:v2.0
        # Container-level security context
        securityContext:
          allowPrivilegeEscalation: false  # Required
          readOnlyRootFilesystem: true     # Required
          capabilities:
            drop: [ALL]                    # Required
        env:
        # JVM temp dir -> /tmp (emptyDir)
        - name: JAVA_OPTS
          value: >-
            -Djava.io.tmpdir=/tmp
            -XX:+HeapDumpOnOutOfMemoryError
            -XX:HeapDumpPath=/heap-dumps
            -XX:MaxRAMPercentage=75.0
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: heap-dumps
          mountPath: /heap-dumps
```

> **Code walkthrough:** runAsNonRoot: true requires that the container's
> user ID is not 0 (root). The Docker image must have a non-root user defined
> or the runAsUser: 1000 override sets it at the pod level. readOnlyRootFilesystem:
> true prevents any writes to the container filesystem, which is the most
> impactful security control for preventing persistence after a breach. The
> emptyDir volumes at /tmp and /heap-dumps provide writable space for JVM
> temporary files and OOM heap dumps. The JAVA_OPTS configuration redirects
> java.io.tmpdir to /tmp (the emptyDir mount) so Spring Boot and Tomcat internal
> temp file operations work correctly. capabilities: drop: [ALL] removes all
> Linux capabilities from the container.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Pod Security Standards define three levels: privileged (no restrictions),
> baseline (prevents dangerous configs), restricted (hardened). Labels on
> namespaces enforce the policy. For Java services: add runAsNonRoot: true,
> allowPrivilegeEscalation: false, and capabilities: drop: ALL to comply
> with restricted.

*Push deeper:* "The migration path from no PSS to restricted: first apply
the namespace label with mode audit/warn (not enforce). This logs/warns about
violations without rejecting pods. Collect violations for 2-4 weeks. Fix
all violations. Then switch to enforce mode. Skipping the warn phase and
jumping straight to enforce will break production workloads."

---

**Senior / Staff (5+ years):**

> PSP migration to PSS was a significant operational effort. PSP was extremely
> flexible (per-pod policies, wildcard matching) but complex - most PSP
> configurations had subtle security bypasses. PSS is simpler, harder to
> misconfigure, and has clear profiles.
>
> The main challenge for Java services in restricted: Logback and Log4j2
> write to the filesystem for rolling log files. With readOnlyRootFilesystem:
> true, this fails. Solutions: (1) log only to stdout/stderr (Kubernetes collects
> these), (2) mount emptyDir at the log directory, (3) use a sidecar log
> shipper that writes to a shared emptyDir.
>
> I recommend stdout logging for Kubernetes-native deployments. Kubernetes
> captures stdout/stderr and makes them available via kubectl logs. Centralized
> log aggregation (Fluentd -> Elasticsearch, Loki) collects from the node's
> log files without application-level file logging.

*Push deeper:* "The seccompProfile: RuntimeDefault restricts which syscalls
the container can make. This prevents containers from exploiting less-common
kernel syscalls even if they escape the pod. The RuntimeDefault profile is
based on Docker's default seccomp profile, which blocks ~44 dangerous syscalls
while allowing everything needed for typical application operation."

---

### ⚖️ Comparison Table

| Profile | RunAsRoot | Capabilities | Host Access | Use Case |
|---|---|---|---|---|
| **privileged** | Allowed | All | Allowed | kube-system, Cilium, CSI drivers |
| **baseline** | Allowed | Restricted | No host net/PID | General workloads (legacy) |
| **restricted** | Denied | Drop ALL | None | Production services (target) |

**The deciding factor:** restricted for all user-facing services. baseline
for infrastructure components that need more flexibility. privileged only
for cluster-level infrastructure that legitimately needs host access.

---

### ⚠️ Common Misconceptions

**"readOnlyRootFilesystem means the container has no writable storage."**

readOnlyRootFilesystem: true makes the container's root filesystem read-only.
emptyDir volumes mounted at specific paths (like /tmp) are still writable.
The combination provides both write restriction (reduces attack surface)
and functional writable space where needed.

**"Pod Security Standards are enforced by RBAC."**

PSS is enforced by the PodSecurity Admission Controller (a built-in admission
plugin). RBAC controls API access (who can create pods). PSS controls what
those pods can do. They are complementary, independent mechanisms.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Non-root violation | Pod rejected: must not run as root | `kubectl describe pod` shows PSS admission error | Set runAsNonRoot: true; ensure image has non-root user |
| Filesystem write failure | Spring Boot fails to start (tmp write) | App logs show Permission denied on /tmp | Add emptyDir volume at /tmp; set java.io.tmpdir=/tmp |
| Capability restriction | App needs NET_BIND_SERVICE for port <1024 | `kubectl describe pod` shows PSS caps violation | Use port > 1024 in container; drop need for capability |
| readOnlyRootFilesystem write | Log rotation fails silently | No log files; Logback errors | Switch to stdout logging; or emptyDir at /logs |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Three profile levels, namespace labeling |
| Mid | 6 min | Restricted requirements, Java compliance |
| Senior | 10 min | Filesystem issue, stdout logging pattern |
| Staff | 12 min | PSP migration, seccomp profiles |

---

**[SENIOR] Q1 - How do you make a Spring Boot service
comply with the restricted Pod Security Standard?**

*Why they ask:* Practical security hardening.

*Likely follow-up:* "What breaks and how do you fix it?"

Step-by-step compliance for restricted:

1. Set pod-level security context:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
```

2. Set container-level security context:
```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: [ALL]
```

3. Fix image: ensure the Docker image runs as non-root:
```dockerfile
FROM eclipse-temurin:21-jre
# Create non-root user
RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser appuser
USER 1000
COPY --chown=appuser:appuser target/app.jar /app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
```

4. Add emptyDir for JVM temp writes:
```yaml
volumes:
- name: tmp
  emptyDir: {}
- name: logs
  emptyDir: {}
volumeMounts:
- mountPath: /tmp
  name: tmp
- mountPath: /var/log/app
  name: logs
env:
- name: JAVA_OPTS
  value: "-Djava.io.tmpdir=/tmp"
```

5. Configure Logback/Log4j2 for stdout (no file rotation):
```xml
<!-- logback-spring.xml -->
<appender name="CONSOLE"
    class="ch.qos.logback.core.ConsoleAppender">
  <encoder>
    <pattern>%d{ISO8601} %-5level %logger: %msg%n</pattern>
  </encoder>
</appender>
<!-- Remove file appender - use only CONSOLE -->
```

What typically breaks and the fix:
- Tomcat temp directory: set java.io.tmpdir=/tmp
- Spring Boot banner file: ensure /tmp/banner.txt writable
- JVM JIT compilation artifacts: /tmp or TMPDIR env

*What separates good from great:* The Dockerfile change (non-root user)
is often forgotten. The container security context alone is insufficient
if the image's default user is root.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Security engineer | Compliance | PSP vs PSS migration, seccomp |
| Java engineer | Practical | Spring Boot compliance steps |
| Platform engineer | Enforcement | Namespace labeling, audit/warn migration |
| SRE | Operations | What breaks at restricted, remediation |

---
---

# Resource Quota and Limit Ranges

**Interview Weight:** expert - Resource Quotas prevent teams from overconsuming
shared cluster resources. LimitRanges enforce default resource settings and
bounds. Both are required for multi-tenant cluster governance. Interviewers
test the interaction between these controls and how they apply to Java services.

---

### 🎯 Model Answer

**30 seconds:**

> ResourceQuota limits the total resources (CPU, memory, pod count) a namespace
> can consume. LimitRange sets default requests/limits for pods that do not
> specify them, and enforces min/max bounds. Together: ResourceQuota prevents
> namespace overconsumption, LimitRange prevents individual pods from being
> incorrectly sized. For Java services: LimitRange defaults ensure all pods
> have resource requests set (required for HPA and efficient scheduling).

**3 minutes (Senior):**

> ResourceQuota enforces aggregate limits at the namespace level. It tracks:
> total CPU requests and limits consumed by all pods, total memory requests
> and limits, count of objects (pods, services, PVCs). When a pod creation
> would exceed the quota, the API server rejects the request with a quota
> exceeded error.
>
> LimitRange works differently: it is applied to individual pods/containers.
> It provides: default values (if a pod does not specify requests/limits, the
> LimitRange's default is injected), min/max bounds (a pod requesting more
> than the LimitRange maximum is rejected), and ratio limits (max/min ratio
> prevents setting limit 100x larger than request).
>
> The interaction matters: a LimitRange with default requests ensures all
> pods have requests set (required for quota accounting). Without default
> requests, a pod with no resource requests does not consume quota (quota
> only tracks specified resources). A ResourceQuota without a LimitRange default
> allows pods with no requests to bypass quota counting.
>
> For Java services: set LimitRange defaults matching typical Spring Boot sizing.
> ResourceQuota for each team namespace prevents one team's memory leak from
> consuming cluster resources and starving other teams.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about ResourceQuota and LimitRange - how
Kubernetes controls resource consumption at namespace and pod levels."

**(2) First principles:** "Shared clusters need fairness: each team gets a
portion of cluster resources. ResourceQuota enforces the portion. LimitRange
ensures individual pods are correctly sized."

**(3) Bridge:** "ResourceQuota is like a data cap plan: 100GB/month per team.
LimitRange is like minimum and maximum usage per application: no app can use
less than 10GB (practical minimum) or more than 50GB (prevent one app from
using the whole cap)."

---

### 📘 Concept Explanation

**What it is:**
ResourceQuota limits aggregate resource consumption and object counts per
namespace. LimitRange enforces default, minimum, and maximum resource settings
per container, pod, or PersistentVolumeClaim within a namespace.

**The problem it solves:**
Without quotas: a single team can consume all cluster CPU/memory, starving other
teams. Without LimitRange defaults: pods without resource specifications bypass
quota accounting and the scheduler cannot place them efficiently.

**How it works:**

```
ResourceQuota - Namespace Level:
  Tracks:
    requests.cpu    = sum(all pod CPU requests)
    limits.cpu      = sum(all pod CPU limits)
    requests.memory = sum(all pod memory requests)
    limits.memory   = sum(all pod memory limits)
    count/pods      = count of pods
    count/services  = count of services

  Enforcement:
    New pod creation checked against quota
    If creation would exceed quota: REJECTED
    Existing pods NOT evicted (quota only gates creation)

  Example:
    Quota: requests.memory: 16Gi
    Used:  requests.memory: 14Gi
    New pod requests 3Gi -> REJECTED (14+3 > 16)

LimitRange - Pod/Container Level:
  type: Container
  default:          # Injected if not specified
    cpu: 250m
    memory: 512Mi
  defaultRequest:
    cpu: 100m
    memory: 256Mi
  max:              # Maximum allowed
    cpu: 4
    memory: 8Gi
  min:              # Minimum required
    cpu: 50m
    memory: 64Mi
  maxLimitRequestRatio:  # limit / request ratio
    memory: 4      # limit must be <= 4x request

  Enforcement:
    Pod with no requests: LimitRange injects defaultRequest
    Pod exceeding max: REJECTED
    Pod below min: REJECTED
    Pod with limit/request > ratio: REJECTED
```

**The key insight:**
ResourceQuota only counts resources that are explicitly specified. If a pod
has no CPU requests, it consumes 0 of the CPU quota (it is BestEffort QoS).
The LimitRange default injection is what ensures all pods are tracked by quota.
Without a LimitRange default, BestEffort pods bypass quota entirely.

**When to use priority classes with quota:**
PriorityClass allows high-priority pods (critical services) to consume quota
ahead of low-priority pods (batch jobs, development). A ResourceQuota can be
scoped to a specific PriorityClass: production services use the production-quota,
batch jobs use the batch-quota. During node pressure: batch jobs are evicted
first.

**First-principles derivation:**
Multi-tenant resource management requires both aggregate limits (fair share
between tenants) and per-workload limits (prevent individual runaway processes).
ResourceQuota addresses aggregate fairness. LimitRange addresses per-workload
governance. Neither alone is sufficient: quota without LimitRange allows bypasses,
LimitRange without quota allows aggregate overconsumption.

---

### 💻 Code Example

**Example 1: Team namespace with quota and LimitRange**

```yaml
# Namespace for team (applied by platform team)
apiVersion: v1
kind: Namespace
metadata:
  name: team-payments
  labels:
    pod-security.kubernetes.io/enforce: restricted
    team: payments

---
# ResourceQuota: limits total namespace consumption
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-payments-quota
  namespace: team-payments
spec:
  hard:
    # Total CPU and memory for the namespace
    requests.cpu: "8"
    requests.memory: 16Gi
    limits.cpu: "16"
    limits.memory: 32Gi
    # Object count limits
    count/pods: "40"
    count/services: "20"
    count/persistentvolumeclaims: "10"
    # Only allow PVCs on this StorageClass
    gp3-encrypted.storageclass.storage.k8s.io/requests.storage: 500Gi

---
# LimitRange: defaults and bounds for containers
apiVersion: v1
kind: LimitRange
metadata:
  name: team-payments-limits
  namespace: team-payments
spec:
  limits:
  - type: Container
    # Defaults injected if not specified
    default:
      cpu: 500m
      memory: 1Gi
    defaultRequest:
      cpu: 250m      # Required for HPA, quota tracking
      memory: 512Mi
    # Bounds
    max:
      cpu: "4"
      memory: 8Gi    # Max per container (not per pod)
    min:
      cpu: 50m
      memory: 64Mi
    maxLimitRequestRatio:
      memory: 4      # Limit must be <= 4x request
  - type: PersistentVolumeClaim
    max:
      storage: 200Gi  # No PVC can exceed 200Gi
    min:
      storage: 1Gi
```

> **Code walkthrough:** The ResourceQuota hard limits total CPU (8 requests,
> 16 limits) and memory (16Gi requests, 32Gi limits) consumable by the entire
> namespace. Object count limits (40 pods, 20 services) prevent namespace sprawl.
> The StorageClass-specific quota (`gp3-encrypted.storageclass.storage.k8s.io/
> requests.storage: 500Gi`) limits total PVC storage on this specific class to
> 500Gi, preventing a single team from requesting terabytes of EBS. The LimitRange
> defaultRequest ensures all containers have CPU and memory requests set even if
> the team forgets - critical for quota accounting and HPA functionality. The
> maxLimitRequestRatio: 4 prevents extreme limit/request ratios (a container
> requesting 256Mi but with a 10Gi limit, which would consume minimal quota
> but could use 10Gi if it misbehaves).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> ResourceQuota limits total resource consumption for a namespace (total
> CPU, memory, pod count). LimitRange sets defaults for containers that
> do not specify resources and enforces min/max bounds. Together they prevent
> a team from over-consuming cluster resources and ensure all pods are
> correctly sized.

*Push deeper:* "The LimitRange default injection is critical for quota
to work correctly. If a pod has no resource requests, it is BestEffort QoS
and consumes 0 from the namespace quota. A LimitRange with defaultRequest
ensures every pod has requests set (even if the deployment YAML is missing
them), which makes quota accurately track all consumption."

---

**Senior / Staff (5+ years):**

> The production quota pattern I use:
> (1) ResourceQuota per team namespace based on team SLA tier
>     (Tier 1: 16 cores, 32Gi; Tier 2: 8 cores, 16Gi)
> (2) LimitRange with conservative defaults (250m CPU, 512Mi memory request)
>     and generous limits (4 CPU, 8Gi memory)
> (3) maxLimitRequestRatio: memory 4 to prevent memory limit manipulation
>
> Quota evolution: start with generous quotas and use quota usage metrics
> (kube_resourcequota from kube-state-metrics in Prometheus) to understand
> actual consumption before tightening. Alert when any resource hits 80%
> of quota: this gives teams advance notice before hard failures.
>
> The escalation path: a team needing more quota creates a platform ticket.
> This creates an audit trail and ensures the platform team reviews overall
> cluster capacity before approving quota increases.

*Push deeper:* "Scoped resource quotas allow different limits for different
pod priority classes. Example: batch jobs get a separate quota (count/pods
scoped to PriorityClass: batch). This prevents batch jobs from consuming
production quota and avoids the situation where a batch job backlog prevents
production pods from scheduling in the same namespace."

---

### ⚖️ Comparison Table

| Control | Scope | When Enforced | What It Controls |
|---|---|---|---|
| **ResourceQuota** | Namespace total | At pod creation | Aggregate consumption |
| **LimitRange** | Per container/pod | At pod creation | Individual sizing |
| **HPA** | Per Deployment | Continuously | Scale for utilization |
| **VPA** | Per container | Recommendation or auto | Right-size requests |

**The deciding factor:** ResourceQuota + LimitRange for cluster governance.
HPA for dynamic scaling. VPA in recommendation mode for right-sizing requests
based on actual usage data.

---

### ⚠️ Common Misconceptions

**"ResourceQuota evicts pods when the quota is exceeded."**

ResourceQuota prevents new pods from being created once the quota is reached.
It does NOT evict existing pods. If a namespace is at quota and you try to
scale up a Deployment, the new pods are rejected (Pending with "insufficient
quota" error), but existing running pods are unaffected.

**"LimitRange defaults apply to existing pods."**

LimitRange defaults are injected at pod admission time (when the pod is
created). Existing pods that were created before the LimitRange was added
are not retroactively updated. The LimitRange only affects newly created pods.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Quota exceeded | Pods stuck Pending | `kubectl describe pod` shows "exceeded quota: requests.memory" | Reduce existing pod requests; request quota increase |
| LimitRange injection fails | Pod created with no resources | No LimitRange default; pod is BestEffort | Add LimitRange with defaultRequest |
| LimitRange max violation | Pod rejected: exceeds max limit | `kubectl describe pod` shows LimitRange exceeded | Reduce container limits to below LimitRange max |
| Storage quota exceeded | PVC creation rejected | `kubectl describe pvc` shows quota exceeded | Reduce PVC request; request storage quota increase |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | ResourceQuota purpose, LimitRange defaults |
| Mid | 6 min | Quota interaction with LimitRange |
| Senior | 10 min | BestEffort bypass, scoped quotas |
| Staff | 12 min | Multi-team governance, quota metrics |

---

**[SENIOR] Q1 - ARCHITECTURE: How do you design
ResourceQuota for a multi-team shared Kubernetes
cluster?**

*Why they ask:* Multi-tenant platform design.

*Likely follow-up:* "How do you handle teams that need burst capacity?"

Multi-team quota design:

Namespace-per-team model:
- team-payments: production + staging namespaces
- team-orders: production + staging namespaces
- team-catalog: production + staging namespaces

Tier-based quota allocation:
Define tiers based on service criticality and expected scale:

Tier 1 (critical services, high availability):
  requests.cpu: "16"
  requests.memory: 32Gi
  limits.cpu: "32"
  limits.memory: 64Gi
  count/pods: "60"

Tier 2 (standard services):
  requests.cpu: "8"
  requests.memory: 16Gi
  limits.cpu: "16"
  limits.memory: 32Gi
  count/pods: "30"

Dev/staging namespaces:
  requests.cpu: "4"
  requests.memory: 8Gi
  limits.cpu: "8"
  limits.memory: 16Gi
  count/pods: "20"

Burst capacity:
For teams that occasionally need more (peak sale events, batch runs):
Option 1: temporary quota increase (platform team approves, time-limited,
creates a JIT quota object, reverts after event)
Option 2: burst namespace (separate namespace for burst workloads with
separate quota, burst budget, auto-cleanup after event)

Monitoring:
Alert when any resource hits 80% of quota:
`kube_resourcequota{type="used"} /
kube_resourcequota{type="hard"} > 0.80`

Automated quota reporting: weekly report to team leads showing quota
utilization. Teams consistently under 30% utilization may get quota
reduced to free capacity for teams that need more.

*What separates good from great:* The burst capacity mechanism - recognizing
that fixed quotas are too rigid for real-world usage patterns without a
controlled overflow mechanism.

---

**[BEHAVIORAL] Q2 - Describe a time resource quotas
prevented a production incident or performance issue.**

*Why they ask:* Real-world quota operations experience.

*Likely follow-up:* "What quota settings would you change based on that experience?"

Answer pattern:

Situation: "We had a shared cluster with 5 teams. One team was working on
a batch processing feature and ran a test that spawned 200 pods simultaneously."

Impact: "The 200 pods consumed 80% of cluster CPU requests instantly. Other
teams' pods could not scale (HPA triggers but pods stuck Pending). A critical
payment service could not add replicas during a traffic spike."

Root cause: "No ResourceQuota on the batch team's namespace. The batch test
was not intended to reach that scale - a bug in the test loop."

Resolution: "Immediately added ResourceQuota to all namespaces: batch namespace
limited to 20 pods and 8 cores. Production namespaces given priority quota
(more resources). Added Prometheus alert for namespace quota > 70% utilization."

Lesson: "Quotas should be provisioned from day 1 of namespace creation, not
added reactively. The platform team now creates quotas as part of namespace
provisioning."

*What separates good from great:* Describing the reactive fix (adding quotas)
AND the process change (quota from day 1 in namespace provisioning).

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Platform engineer | Architecture | Multi-team design, quota tiers |
| SRE | Operations | Quota monitoring, escalation path |
| Engineering manager | Fairness | Tier allocation, burst capacity |
| Developer | Day-to-day | What happens when quota is exceeded |

---
---

# Custom Scheduling and Affinity Rules

**Interview Weight:** expert - Affinity rules control pod placement for
performance (co-locate with related services), availability (spread across
zones), and compliance (place on specific nodes). Senior engineers are
expected to understand node affinity, pod affinity, anti-affinity, taints,
and tolerations.

---

### 🎯 Model Answer

**30 seconds:**

> Kubernetes scheduling placement is controlled by four mechanisms: node affinity
> (schedule pod on nodes matching labels), pod affinity (co-locate with pods
> matching labels), pod anti-affinity (spread away from pods matching labels),
> and taints/tolerations (nodes taint themselves as restricted; pods that tolerate
> the taint can schedule there). For Java services: anti-affinity across zones
> (spread replicas across availability zones) is the most important rule for HA.

**3 minutes (Senior):**

> Node affinity vs node selector: node selector is a simple label matching
> requirement. Node affinity is more expressive (In, NotIn, Exists, DoesNotExist,
> Gt, Lt operators), supports required vs preferred rules, and supports weight-based
> preferences.
>
> Pod affinity/anti-affinity: operates on the topology domain (topologyKey).
> For zone spreading: topologyKey: topology.kubernetes.io/zone means Kubernetes
> distributes pods across different zones. For node spreading: topologyKey:
> kubernetes.io/hostname spreads pods across different nodes.
>
> Required vs preferred: required (requiredDuringSchedulingIgnoredDuringExecution)
> prevents scheduling if no matching node/pod exists - the pod stays Pending.
> Preferred (preferredDuringSchedulingIgnoredDuringExecution) hints but schedules
> anywhere if preference cannot be satisfied. Use required only when the constraint
> is genuinely non-negotiable.
>
> Topology spread constraints (newer API): more expressive and efficient than
> pod anti-affinity for spreading across zones. `maxSkew: 1` means at most one
> pod difference between zones. Combined with whenUnsatisfiable: DoNotSchedule
> (preferred) or ScheduleAnyway (degraded mode), this provides controlled zone
> distribution with known failure behavior.
>
> Taints/tolerations: nodes taint themselves (key=value:effect). Effect options:
> NoSchedule (do not schedule unless tolerated), PreferNoSchedule (prefer not,
> but will if needed), NoExecute (evict existing pods that do not tolerate).
> Use cases: dedicated GPU nodes (taint: gpu:NoSchedule), spot instance nodes
> (taint spot:NoExecute for graceful handling), control plane nodes (NoSchedule
> by default).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Kubernetes pod placement rules - how
to control which nodes pods are scheduled on."

**(2) First principles:** "The scheduler needs hints about: which nodes are
eligible, which pods should be near each other, and which nodes are restricted.
Affinity/anti-affinity + taints/tolerations encode these hints."

**(3) Bridge:** "Node affinity is like a job requirement: must have a GPU.
Pod anti-affinity is like a seating rule: do not seat rivals at the same table.
Taints are like VIP ropes: node says 'restricted access'; toleration is the
VIP pass."

---

### 📘 Concept Explanation

**What it is:**
Kubernetes scheduling rules allow precise control of pod placement via node
affinity (which nodes), pod affinity/anti-affinity (which pods are neighbors),
topology spread constraints (distribution across topology domains), and
taints/tolerations (node restriction and pod exemption).

**The problem it solves:**
Default scheduling optimizes for resource availability but ignores: HA requirements
(spread across zones), performance (co-locate latency-sensitive pods), cost (prefer
spot nodes for batch), and compliance (workloads must run on specific node types).

**How it works:**

```
Placement Rules:

Node Affinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      - key: topology.kubernetes.io/zone
        operator: In
        values: [us-east-1a, us-east-1b, us-east-1c]
  # Must be in these zones (Required = hard constraint)
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    preference:
      matchExpressions:
      - key: node-type
        operator: In
        values: [compute-optimized]
  # Prefer compute-optimized nodes (Preferred = soft)

Pod Anti-Affinity (zone spreading):
  podAntiAffinity:
    requiredDuringScheduling...:
      labelSelector:
        matchLabels:
          app: payment-service
      topologyKey: topology.kubernetes.io/zone
  # payment-service pods MUST be in different zones

Topology Spread Constraints (preferred):
  topologySpreadConstraints:
  - maxSkew: 1              # Max 1 pod difference between zones
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: payment-service
  # Preferred over anti-affinity: handles uneven zone counts

Taints and Tolerations:
  Node taint (add to specific nodes):
    kubectl taint nodes node1 dedicated=gpu:NoSchedule

  Pod toleration (allows scheduling on tainted node):
    tolerations:
    - key: dedicated
      operator: Equal
      value: gpu
      effect: NoSchedule
```

**The key insight:**
Topology spread constraints are generally preferred over pod anti-affinity for
zone distribution. Anti-affinity with requiredDuringScheduling prevents scheduling
if zones are not available (pod stays Pending). Topology spread constraints with
whenUnsatisfiable: ScheduleAnyway fall back to suboptimal placement instead of
blocking - useful when you prefer distribution but cannot afford to block scaling.

**When to use required vs preferred constraints:**
Required (hard) for: compliance requirements (must not run on spot instances for
stateful services), zone isolation (multi-region partition), workload separation
(GPU pods must be on GPU nodes). Preferred (soft) for: optimization hints that
should not prevent pod scheduling when the preference cannot be satisfied.

**First-principles derivation:**
The Kubernetes scheduler's objective function is: find the best node that satisfies
all required constraints, then choose among eligible nodes using weighted preferences.
Affinity rules add terms to the required constraints and preference weights. Taints
add explicit node exclusion. Understanding these as components of an optimization
problem clarifies when to use required vs preferred.

---

### 💻 Code Example

**Example 1: Production Java service with HA affinity rules**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  replicas: 3
  template:
    spec:
      # Spread across availability zones (preferred)
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: ScheduleAnyway  # Degrade, don't block
        labelSelector:
          matchLabels:
            app: payment-service
      # Spread across different nodes (hard)
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule  # Must be different nodes
        labelSelector:
          matchLabels:
            app: payment-service

      affinity:
        # Do not run on spot instances (unreliable for payments)
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node.kubernetes.io/lifecycle
                operator: NotIn
                values: [spot]

        # Prefer to co-locate with order-service (low latency)
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 50
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: order-service
              topologyKey: kubernetes.io/hostname

      containers:
      - name: app
        image: payment-service:v2.0
```

> **Code walkthrough:** The first topologySpreadConstraint distributes pods
> across availability zones with ScheduleAnyway - if zones have uneven pod
> counts (maxSkew > 1), the pod still schedules to prevent blocking scale-out.
> The second constraint spreads pods across different nodes with DoNotSchedule
> - this is a hard constraint because having two payment-service pods on the same
> node is a single-node failure risk we cannot accept. The node affinity ensures
> payment-service never runs on spot instances (spot instances can be reclaimed
> with 2-minute notice - unacceptable for payment processing). The pod affinity
> preference co-locates payment-service with order-service to reduce network
> latency for their high-frequency calls.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Node affinity schedules pods on nodes with specific labels. Pod anti-affinity
> spreads pods away from each other across zones or nodes. Topology spread
> constraints are the modern way to ensure zone distribution. Taints mark nodes
> as restricted; tolerations allow pods to schedule on tainted nodes.

*Push deeper:* "The topologySpreadConstraints maxSkew: 1 with whenUnsatisfiable:
ScheduleAnyway vs DoNotSchedule is an important choice. ScheduleAnyway degrades
gracefully: if you have 3 zones but pods can only fit in 2 zones (zone 3 at
capacity), pods schedule in the available zones. DoNotSchedule strictly enforces
even distribution, but pods stay Pending if the constraint cannot be satisfied."

---

**Senior / Staff (5+ years):**

> The scheduling rules that matter most in production:
> (1) Topology spread across zones: prevents a single AZ failure from taking
>     down all replicas. Use topologySpreadConstraints over pod anti-affinity
>     because topology spread handles uneven zone distributions better.
> (2) Node lifecycle affinity: prevent stateful or payment services from
>     running on spot instances. Spot termination gives 2 minutes notice - not
>     enough for graceful shutdown of a payment transaction.
> (3) Soft pod affinity for latency: co-locate services with high RPC rates
>     on the same node (100-200 microsecond local pod communication vs 1-5ms
>     cross-node). Use preferredDuringScheduling so it is a hint, not a blocker.
>
> Scheduling anti-pattern I have seen: required pod anti-affinity with 3 replicas
> and 2 zones. Pods stuck Pending because Kubernetes could not spread 3 pods across
> 3 different zones (only 2 zones available). Fix: switch to topology spread
> with ScheduleAnyway.

*Push deeper:* "The cluster autoscaler interacts with affinity rules in important
ways. If you have a required node affinity for a specific label and no nodes with
that label are available, the autoscaler will not add new nodes unless the node
group has that label. Ensure your autoscaler node group templates include the
labels referenced in your node affinity rules. Otherwise: pods stay Pending, the
autoscaler adds nodes, but the new nodes do not have the required labels."

---

### ⚖️ Comparison Table

| Mechanism | Direction | Scope | Flexibility |
|---|---|---|---|
| **nodeSelector** | Node selection | Node labels | Simple (exact match) |
| **nodeAffinity** | Node selection | Node labels | Expressive (operators, required/preferred) |
| **podAffinity** | Co-location | Pod labels + topology | Medium |
| **podAntiAffinity** | Spreading | Pod labels + topology | Medium |
| **topologySpreadConstraints** | Distribution | Topology domains | High (maxSkew, fallback) |
| **taints/tolerations** | Node exclusion | Node-initiated | Binary (tolerate or not) |

**The deciding factor:** topologySpreadConstraints for zone/node distribution
(preferred over anti-affinity for flexibility). nodeAffinity for hardware
requirements (GPU, specific instance type). taints/tolerations for node
reservation (dedicated nodes for critical workloads).

---

### ⚠️ Common Misconceptions

**"Pod anti-affinity guarantees pods run in different zones."**

Pod anti-affinity with topologyKey: zone requires different zones only if zones
are available. With 3 replicas and 2 zones: the third pod stays Pending (required
anti-affinity cannot be satisfied). Topology spread constraints with ScheduleAnyway
gracefully handles this by accepting uneven distribution.

**"Taints prevent all workloads from running on the node."**

Taints prevent workloads that do not tolerate the taint. Pods with matching
tolerations can still schedule on tainted nodes. Taints are a two-sided mechanism:
the node sets the taint, the pod specifies the toleration.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Pods stuck Pending (affinity) | All pods in same zone, one zone full | `kubectl describe pod` shows topology spread unsatisfied | Switch to ScheduleAnyway or add nodes in zone |
| Anti-affinity deadlock | Replicas > zones, pods Pending | Required anti-affinity on zone; insufficient zones | Reduce replicas or switch to topology spread |
| Spot instance termination | Pods evicted mid-request | Node removed; pod evicted | Add nodeAffinity: NotIn spot for critical services |
| Taint prevents infrastructure pods | DaemonSet pod Pending on new node | New node has taint; DaemonSet lacks toleration | Add appropriate tolerations to DaemonSet |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Node affinity, anti-affinity purpose |
| Mid | 6 min | Topology spread, required vs preferred |
| Senior | 10 min | Spot instance handling, autoscaler interaction |
| Staff | 12 min | Scheduling pipeline, topology spread vs anti-affinity |

---

**[SENIOR] Q1 - ARCHITECTURE: How do you configure
pod placement for a 3-replica Java service to
survive a single AZ failure?**

*Why they ask:* HA design for production services.

*Likely follow-up:* "What if your cluster only has 2 availability zones?"

Zone failure HA configuration:

Requirement: payment-service with 3 replicas must survive the failure of
any one availability zone.

Solution 1 - topologySpreadConstraints (recommended):
```yaml
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: DoNotSchedule  # Strictly spread
  labelSelector:
    matchLabels:
      app: payment-service
```
With 3 zones and 3 replicas: 1 pod per zone. AZ failure: 2 pods continue
(2/3 = 67% capacity). HPA can add pods to the remaining zones.
With 2 zones and 3 replicas: 2 pods in zone A, 1 pod in zone B (maxSkew:1
allows this). AZ failure: either 2 or 1 pod survives. Not ideal but acceptable.

Solution 2 - Increase replicas for zone redundancy:
With 6 replicas and 3 zones: 2 pods per zone. AZ failure: 4 pods continue
(67% capacity with better throughput during failure). This is the safer
approach for payment services.

Solution 3 - Combined node anti-affinity (belt and suspenders):
```yaml
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: DoNotSchedule
  # Spread across zones
- maxSkew: 1
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: DoNotSchedule
  # Also spread across nodes within zones
```
This ensures no two pods on the same node AND distribution across zones.

PodDisruptionBudget (companion resource):
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: payment-service-pdb
spec:
  minAvailable: 2  # Always keep 2 pods serving
  selector:
    matchLabels:
      app: payment-service
```
PDB prevents node draining (for upgrades) from taking more than 1 pod at a time.

*What separates good from great:* Mentioning PodDisruptionBudget alongside
topology spread - PDB enforces HA during voluntary disruptions (node upgrades,
cluster operations) while topology spread handles scheduling distribution.

---

**[BEHAVIORAL] Q2 - Describe a production scheduling
issue you diagnosed and resolved.**

*Why they ask:* Practical scheduling debugging experience.

*Likely follow-up:* "What did you change to prevent recurrence?"

Strong behavioral answer pattern:

Situation: "Our order-service (10 replicas) had all pods scheduled on
3 of our 12 nodes. This caused those nodes to run at high CPU while
9 nodes were underutilized."

Diagnosis: "kubectl describe pod showed the pod anti-affinity was set
with podAffinityTerm topologyKey: kubernetes.io/hostname for a different
service (db-service), not order-service. The order-service selector was
wrong - it was anti-affining against db-service pods, not itself. So all
order-service pods saw no db-service pods on most nodes and happily stacked."

Root cause: "Copy-paste error: the labelSelector in the podAntiAffinity
referenced app: db-service instead of app: order-service."

Fix: "Corrected the labelSelector. Added topology spread constraints as
the authoritative placement rule instead of anti-affinity."

Result: "Pods redistributed across 10+ nodes on next rollout. Node CPU
evened out from 3 overloaded nodes to even distribution."

Prevention: "Added a LimitRange check and scheduling validation to our
Helm chart CI pipeline."

*What separates good from great:* The specific bug (wrong labelSelector)
and the switch from anti-affinity to topology spread as a more robust solution.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| SRE | Operations | Zone failure scenario, PDB |
| Platform engineer | Architecture | Topology spread vs anti-affinity |
| Java engineer | Practical | When to use, common rules |
| Staff architect | Design | Scheduling pipeline, Cluster Autoscaler |
