---
layout: default
title: "Docker - L2 Operations"
parent: "Docker and Containers"
nav_order: 4
permalink: /docker/l2-operations/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Container Health Checks](#container-health-checks) | critical |
| 2 | [Docker Volumes and Persistent Storage](#docker-volumes-and-persistent-storage) | high |
| 3 | [Container Logging Strategies](#container-logging-strategies) | high |
| 4 | [Docker Registry and Image Management](#docker-registry-and-image-management) | high |
| 5 | [Container Environment Variables and Config](#container-environment-variables-and-config) | high |

---

# Container Health Checks

**Interview Weight:** critical - The most frequently misunderstood
operational Docker topic. Directly connected to Kubernetes readiness
and liveness probes. Getting this wrong causes rolling deploy failures
and cascading production outages.

---

### 🎯 Model Answer

**30 seconds:**

> A Docker health check is a command the Docker daemon runs periodically
> inside the container. If it exits 0, the container is healthy. If it
> exits non-zero three consecutive times, the container is marked
> unhealthy. In Kubernetes, this maps to three probe types: liveness
> (restart if unhealthy), readiness (remove from load balancer if not
> ready), and startup (extra time for slow-starting apps). Getting these
> three wrong is the most common cause of rolling deploy failures.

**3 minutes (Senior):**

> Health checks serve three distinct purposes in production. Liveness
> probes detect stuck processes - a deadlocked JVM that is not
> responding but has not exited. When the liveness probe fails, the
> container is restarted. Readiness probes detect unready services -
> the JVM is running but the Spring context is still initializing or
> the app is under heavy load. When readiness fails, the pod is removed
> from the service endpoint list, so no traffic is sent to it.
> Startup probes handle slow-starting applications - if you use a
> liveness probe alone on an app that takes 45 seconds to start,
> Kubernetes kills it before it finishes starting.
>
> The most dangerous mistake is using the same liveness and readiness
> configuration without understanding the consequence: an overly
> aggressive liveness probe will restart a pod that is merely slow
> (high GC, cold start), causing a restart loop under load. Under load
> is exactly when you need stability, not restarts. The correct pattern
> is a conservative liveness probe (only fails for truly stuck processes)
> and a sensitive readiness probe (fails quickly when the app cannot
> handle traffic). A startup probe with a long deadline handles the
> initial slow start, after which the tighter liveness and readiness
> probes take over.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff discusses health check design for Java services
(Spring Actuator /health vs TCP vs command), the startup probe + liveness
+ readiness three-probe pattern, and how probe failures trigger cascading
restarts under load.

*Adapting down:* Junior: "Health checks tell the orchestrator if the
app is working. Kubernetes uses three types: startup (initial), liveness
(restart if stuck), readiness (remove from load balancer if not ready)."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about container health checks -
let me think through what problem they solve for orchestrators."

**(2) First principles:** "An orchestrator cannot route traffic to a
broken container. It needs a signal. The container knows best whether
it is healthy - the health check provides that signal."

**(3) Bridge:** "This is like a load balancer health check - same
concept. Kubernetes extends it to three signals: initial readiness,
ongoing health, and availability for traffic."

---

### 📘 Concept Explanation

**What it is:**
A container health check is a periodic command executed inside the
container by the runtime. The exit code determines health status.
Kubernetes extends this to three probe types with different actions.

**The problem it solves:**
Without health checks, an orchestrator routes traffic to containers
that appear running but are actually broken (deadlocked, out of memory,
unresponsive). Health checks provide a feedback signal beyond "process is
running."

**How it works:**

```
Docker HEALTHCHECK:
  interval: 30s  (check every 30s)
  timeout: 10s   (fail if takes > 10s)
  retries: 3     (unhealthy after 3 fails)
  start_period: 10s (grace period at start)

States: starting -> healthy -> unhealthy

Kubernetes Probes:
  startupProbe:    while failing, liveness/readiness skip
                   failure -> restart container
  livenessProbe:   run after startup passes
                   failure -> restart container
  readinessProbe:  run throughout lifecycle
                   failure -> remove from Service endpoint
```

```mermaid
sequenceDiagram
    participant K8s as Kubernetes
    participant P as Pod
    participant SP as startupProbe
    participant LP as livenessProbe
    participant RP as readinessProbe
    K8s->>P: Container starts
    K8s->>SP: Check every 10s (max 30 attempts = 5 min)
    SP-->>K8s: FAIL (JVM starting)
    SP-->>K8s: FAIL (Spring initializing)
    SP-->>K8s: PASS (app ready)
    K8s->>LP: Check every 30s
    K8s->>RP: Check every 10s
    RP-->>K8s: FAIL (high load)
    K8s->>P: Remove from Service endpoints
    RP-->>K8s: PASS (load normalized)
    K8s->>P: Re-add to Service endpoints
```

> **Diagram walkthrough:** The startup probe runs exclusively until the
> first pass, giving the JVM time to initialize without triggering liveness
> restarts. After startup passes, both liveness and readiness run concurrently.
> A readiness failure is handled gracefully - the pod stays running but
> receives no traffic until it recovers. A liveness failure is destructive -
> the container is killed and restarted. These must use different endpoints
> or different thresholds to avoid using readiness to trigger restarts.

**The key insight:**
Liveness and readiness are NOT the same probe with different names.
Liveness failure = container restart. Readiness failure = traffic pause.
Using the same endpoint for both means any temporary overload restarts
the container instead of pausing traffic - the worst possible behavior
under load.

**When to use startup probe:**
Any Java application with JVM warm-up time over 30 seconds. Spring Boot
on JDK 21 with a moderate number of beans takes 5-10 seconds on JRE-alpine
but can take 30-60 seconds on first deployment in Kubernetes.

**When to NOT make liveness too sensitive:**
Never make the liveness probe sensitive to application load or database
connectivity. If the database is slow, you want readiness to fail (stop
traffic) but liveness to pass (keep the container running to serve requests
when the database recovers).

**Alternatives:**
- Spring Boot Actuator health endpoints (/health/liveness, /health/readiness)
  provide out-of-the-box probe implementations
- TCP probes - simpler than HTTP but only test port reachability
- exec probes - run a command, useful for non-HTTP services

**First-principles derivation:**
An orchestrator routes work to containers. It must know: (1) is this
container done starting? (startup probe), (2) is this container stuck
and should be restarted? (liveness probe), (3) is this container ready
to handle more work? (readiness probe). Three questions, three probes.

---

### 💻 Code Example

**Example 1: Dockerfile HEALTHCHECK**

```dockerfile
FROM eclipse-temurin:21-jre-alpine
COPY app.jar app.jar

# Health check: curl the Spring Boot actuator
HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=60s \
    --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health \
        || exit 1

ENTRYPOINT ["java", \
  "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
```

> **Code walkthrough:** The HEALTHCHECK instruction uses curl to call
> the Spring Boot actuator health endpoint. `--start-period=60s` gives
> the JVM 60 seconds to start before health check failures count toward
> the unhealthy threshold. `--retries=3` means three consecutive failures
> mark the container unhealthy. The `|| exit 1` ensures the health check
> fails if curl fails for any reason (connection refused, non-200 response).

**Example 2: Kubernetes three-probe pattern for Spring Boot**

```yaml
# Kubernetes deployment probe configuration
containers:
  - name: myapp
    image: myapp:latest
    readinessProbe:
      httpGet:
        path: /actuator/health/readiness
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 10
      failureThreshold: 3
      successThreshold: 1
    livenessProbe:
      httpGet:
        path: /actuator/health/liveness
        port: 8080
      initialDelaySeconds: 60
      periodSeconds: 30
      failureThreshold: 3
    startupProbe:
      httpGet:
        path: /actuator/health/liveness
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
      failureThreshold: 30
      # Max startup time: 5 + (30 * 10) = 305 seconds
```

> **Code walkthrough:** Spring Boot 2.3+ provides separate /health/liveness
> and /health/readiness endpoints that integrate with Kubernetes probes.
> Liveness uses /health/liveness (a simple alive check) with a conservative
> 60-second initial delay - the startup probe handles initial slow start.
> Readiness uses /health/readiness which Spring populates with all health
> indicators (database, cache, disk). The startup probe runs before liveness
> kicks in, giving the app 305 seconds maximum to pass the first check.

**Example 3: Custom health indicator for Java service**

```java
// Spring Boot custom readiness indicator
@Component
public class WarmupReadinessIndicator
    implements HealthIndicator {

    private final AtomicBoolean warmedUp =
        new AtomicBoolean(false);
    private volatile long requestCount = 0;

    // Mark warmed up after 100 requests
    // (JIT compiled the hot paths)
    public void recordRequest() {
        if (++requestCount >= 100) {
            warmedUp.set(true);
        }
    }

    @Override
    public Health health() {
        if (!warmedUp.get()) {
            return Health.down()
                .withDetail("status",
                    "warming up: " + requestCount
                    + " of 100 requests complete")
                .build();
        }
        return Health.up().build();
    }
}
```

> **Code walkthrough:** This custom health indicator keeps the readiness
> probe failing until 100 requests have been processed - ensuring JIT
> compilation has warmed up the hot code paths before the pod receives
> production load. This prevents the first users after a rolling deploy
> from experiencing high latency due to interpreted JVM bytecode.
> The warmedUp flag is atomic to ensure thread safety. Once set, the
> readiness probe passes permanently (JIT state is preserved).

---

### ⚖️ Comparison

| Probe Type | On Failure | Use For | Typical Threshold |
|---|---|---|---|
| **startupProbe** | Restart container | Initial JVM startup | 30 retries x 10s = 5 min |
| livenessProbe | Restart container | Deadlock detection | 3 retries x 30s |
| readinessProbe | Remove from LB | Load/dependency issues | 3 retries x 10s |
| Docker HEALTHCHECK | Mark unhealthy | Compose and standalone | 3 retries x 30s |

**The deciding factor:**
Always use all three Kubernetes probes for Java services. Use startup
probe to accommodate JVM warm-up. Make liveness conservative (only
truly broken processes). Make readiness sensitive (quickly remove
overloaded or dependency-broken pods from rotation).

---

### 🔥 Field Q&A

#### Production Failures

Q: Rolling deployment causes a cascade restart loop in production.
All new pods start, fail their liveness probe, get restarted, and the
deployment never completes.

A: The liveness probe is too aggressive for the startup time.
When the startupProbe is absent or too short, the livenessProbe fires
during JVM initialization and kills the pod. Fix: add a startup probe
with a generous failureThreshold (failureThreshold x periodSeconds
must exceed your worst-case startup time). Set startupProbe
failureThreshold=30 periodSeconds=10 for a 5-minute startup budget.
Verify by checking pod events: kubectl describe pod will show
"Liveness probe failed" with the error.

Q: After a database outage, all pods became unhealthy and were
restarted by Kubernetes liveness probes. The database recovered but
pods were in a restart loop.

A: The liveness probe is checking database connectivity. Liveness
probes should ONLY check whether the JVM process is alive and not
deadlocked - they should NOT check external dependencies. If the
liveness probe checks the database, a database outage restarts all
pods simultaneously, causing a thundering herd when the database
recovers. The fix is to separate concerns: liveness checks only
the application process (/actuator/health/liveness - which Spring Boot
configures with only internal checks), readiness checks dependencies
(/actuator/health/readiness - which includes datasource health).
During a database outage, readiness fails (pods removed from LB) but
liveness passes (pods stay running). When the database recovers,
readiness passes and traffic is restored without restarts.

Q: Service is under heavy load and readiness probe fails intermittently,
causing traffic to be redistributed to already-overloaded pods.

A: Readiness probe timeout is too short for high-load scenarios. When
load is high, the Spring Boot actuator /health endpoint takes longer
to respond. If the timeout is 1s and the app is at 95% capacity, the
health endpoint may take 2s, failing the probe and removing the pod
from rotation - making remaining pods more loaded, causing them to
also fail. Fix: increase the readiness probe timeout to 5-10 seconds.
Also implement circuit breaker logic in the health endpoint so it
reports down when above a load threshold rather than just being slow.

#### Candidate Mistakes

Q: Candidate uses the same probe configuration for liveness and readiness.

**What NOT to say:** "They both just check if the app is healthy."

**Say instead:** "Liveness and readiness have different consequences.
Liveness failure restarts the container. Readiness failure removes
it from the load balancer without restarting. Using the same endpoint
and threshold for both means any readiness issue (high load, slow
database) also triggers a restart - the worst behavior under production
stress. Liveness should check only JVM liveness, readiness should
check application health including dependencies."

Q: Candidate configures liveness with a 5-second initial delay for
a Spring Boot service.

**What NOT to say:** "The app should start in 5 seconds."

**Say instead:** "Spring Boot typically takes 5-15 seconds to start in
a JRE container. A 5-second initial delay for liveness means the probe
fires before the app finishes starting. The correct pattern is a startup
probe that gives the app up to 5 minutes (30 attempts x 10 seconds)
before handing over to the liveness probe."

Q: Candidate makes the liveness probe check database connectivity.

**What NOT to say:** "If the database is down, the service is not healthy."

**Say instead:** "Liveness probes should only check if the process is
alive and not deadlocked. Checking database connectivity in liveness
means a database outage restarts all pods simultaneously. Instead,
put database health in the readiness probe - it removes unhealthy
pods from traffic without restarting them."

Q: Candidate is unaware of the startup probe.

**What NOT to say:** "I increase the initial delay to handle slow starts."

**Say instead:** "The startup probe is the right solution for slow-starting
Java applications. It has its own failureThreshold that controls the maximum
startup time. While the startup probe is failing, the liveness and readiness
probes are suspended - no early liveness kills. Once the startup probe passes,
the regular probes take over with their tighter thresholds."

#### Questions to Ask the Interviewer

Q: "How do you configure startup, liveness, and readiness probes for
your Java services in Kubernetes?"

*Why:* Reveals probe sophistication and whether the team has experienced
rolling deploy failures from probe misconfiguration.

*If asked back:* "We use the three-probe pattern with Spring Boot Actuator
endpoints: startup probe on liveness endpoint with 30 retries (5-minute
budget), liveness on the same endpoint with conservative thresholds, and
readiness on the readiness endpoint which includes datasource and cache health."

Q: "Have you seen restart loops caused by probe misconfiguration in production?"

*Why:* Tests production experience with the most common health check failure mode.

*If asked back:* "Yes - we had a deployment failure where the liveness probe
fired during JVM startup and restarted pods before they finished initializing.
Adding the startup probe with a 5-minute budget resolved it. The startup probe
is often missing from teams new to Kubernetes."

Q: "What happens to in-flight requests when a pod's readiness probe fails?"

*Why:* Tests understanding of graceful pod removal from load balancing.

*If asked back:* "When readiness fails, the pod is removed from the Service
endpoint slice. New requests are not routed to it. In-flight requests are not
interrupted - they complete normally. This is why readiness (not liveness) is
the right probe for load-shedding: no disruption to existing requests."

Q: "Do you use a JVM warm-up health indicator before marking pods ready?"

*Why:* Tests awareness of JIT warm-up and readiness implications.

*If asked back:* "For latency-sensitive services, we add a custom readiness
indicator that tracks request count and marks the pod ready only after
100 requests have been processed. This ensures JIT compilation has
completed the hot paths before production traffic is sent."

#### Live Coding Context

Coding question template: "Design the health check configuration for
a Spring Boot service that takes 30 seconds to start, checks a Postgres
database as a dependency, and needs graceful handling of temporary
database outages."

What the interviewer watches:
- Whether you use separate liveness and readiness probes
- Whether you use a startup probe for the 30-second start time
- Whether liveness checks only JVM health, not database
- Whether readiness includes database health
- Whether you specify appropriate initial delays and thresholds

Most common implementation mistake:
Using a single /actuator/health endpoint for both liveness and readiness,
causing database outages to trigger pod restarts instead of traffic pauses.

*Why this signals:* This is a production reliability question. The
correct three-probe pattern requires understanding the failure modes
of each probe type.

---
---

# Docker Volumes and Persistent Storage

**Interview Weight:** high - Understanding volume types is prerequisite
for running stateful workloads. Interviewers ask this to verify you can
design storage for databases, file uploads, and logs in containers.

---

### 🎯 Model Answer

**30 seconds:**

> Docker has three storage types: named volumes (managed by Docker,
> persistent, the right choice for databases), bind mounts (specific
> host path mapped into a container, good for dev source code mounting),
> and tmpfs mounts (in-memory only, good for secrets that should not
> touch disk). Container filesystems are ephemeral - anything written
> to the container's writable layer is lost when the container is removed.
> Named volumes persist across container removal and restart.

**3 minutes (Senior):**

> The fundamental principle is that containers are stateless by design.
> The container's writable layer is discarded when the container exits
> or is removed. Any state that must survive a container restart must
> be externalized - either to a named volume, a bind mount, or an
> external service (database, object store).
>
> Named volumes are the production-grade choice for persistent data.
> Docker manages the lifecycle: creating, backing up, and pruning named
> volumes separately from containers. For a Postgres container, you mount
> /var/lib/postgresql/data to a named volume. If the container is removed
> and recreated (e.g., for an image update), the data volume persists.
>
> Bind mounts map a host directory directly into the container filesystem.
> They are transparent and convenient for development - mount your source
> code directory so changes are reflected in the running container without
> rebuilding the image. In production, bind mounts create a tight coupling
> between the container and host filesystem paths, which is fragile in
> Kubernetes where pods can be scheduled on any node.
>
> For Kubernetes, Docker named volumes are replaced by PersistentVolumeClaims
> (PVCs), which abstract the storage provisioner. The concept is the same
> but the lifecycle is cluster-scoped, not daemon-scoped.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff discusses Kubernetes PVCs, StorageClasses, and
dynamic provisioning. Also the trade-off between stateful containers
(StatefulSets) vs externalizing state to managed services.

*Adapting down:* Junior: "Named volumes persist data between container
restarts. Bind mounts map a host folder to a container folder."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Docker storage - let me think
through what happens to data written by a container."

**(2) First principles:** "Containers are ephemeral - their filesystem
is discarded. To persist data, you need storage that lives outside
the container lifecycle."

**(3) Bridge:** "This is like the database vs application server
distinction. State lives in the database (volume), which persists
even when the application server (container) is replaced."

---

### 📘 Concept Explanation

**What it is:**
Docker storage allows containers to persist data beyond the container's
lifecycle. Three types: named volumes (Docker-managed), bind mounts
(host path), and tmpfs (memory-only).

**The problem it solves:**
Container filesystems are ephemeral - all writes go to the writable
layer that is discarded on removal. Databases, uploaded files, logs,
and configuration need persistent or shared storage.

**How it works:**

```
Storage Types:
  Named Volume:
    /var/lib/docker/volumes/pgdata/_data
    -> mounted at /var/lib/postgresql/data
    Persists: yes (separate lifecycle)
    Scope: local to daemon

  Bind Mount:
    /home/dev/src/ (host path)
    -> mounted at /app/src
    Persists: yes (on host)
    Scope: host-specific (not portable)

  tmpfs:
    memory only (no host path)
    -> mounted at /run/secrets
    Persists: no (lost on container stop)
    Scope: per-container
```

**The key insight:**
Named volumes decouple storage lifecycle from container lifecycle.
A named volume survives `docker rm` of the container that used it.
You must explicitly `docker volume rm` to delete it.

**When to use named volumes:**
Databases (Postgres, MySQL, MongoDB) and any persistent application
data that should survive container updates.

**When to use bind mounts:**
Development only - mounting source code, configuration files, or
test fixtures from the host into the container.

**When to use tmpfs:**
Secrets, tokens, and sensitive data that must not be written to disk.
Also for high-frequency temp writes where disk I/O is a bottleneck.

**Alternatives:**
- Kubernetes PersistentVolumeClaims - production multi-host volumes
- Cloud object storage (S3, GCS) - for files that need global access
- Distributed filesystems (NFS, Ceph) - for shared mutable state

**First-principles derivation:**
Data persistence requires storage that outlives the process that
created it. In Docker, containers are processes. Named volumes are
the persistence layer that the daemon manages independently of the
container lifecycle. This separation of storage from compute is the
same design principle as databases being separate from application servers.

---

### 💻 Code Example

**Example 1: Named volumes for Postgres**

```bash
# Create and use a named volume
docker volume create pgdata

# Run Postgres with persistent data
docker run -d \
    --name postgres \
    --mount type=volume,src=pgdata,dst=/var/lib/postgresql/data \
    -e POSTGRES_PASSWORD=secret \
    postgres:16-alpine

# Stop and remove container - data persists in volume
docker stop postgres && docker rm postgres

# New container uses same data
docker run -d \
    --name postgres \
    --mount type=volume,src=pgdata,dst=/var/lib/postgresql/data \
    -e POSTGRES_PASSWORD=secret \
    postgres:16-alpine

# Inspect volume location
docker volume inspect pgdata
# "Mountpoint": "/var/lib/docker/volumes/pgdata/_data"
```

> **Code walkthrough:** The --mount syntax is preferred over the older
> -v flag because it is explicit about the mount type (volume vs bind).
> After docker rm, the pgdata volume still exists and contains all the
> Postgres data. The second docker run with the same volume name reconnects
> to the existing data. `docker volume inspect` shows where the data
> actually lives on the host - useful for manual backups.

**Example 2: Bind mount for development**

```bash
# Mount source code for live reload in development
docker run -d \
    --name devapp \
    # Bind mount: host path -> container path
    --mount type=bind,\
src=$(pwd)/src,\
dst=/app/src,\
readonly \
    # Named volume for compiled classes (not bind)
    --mount type=volume,\
src=target-cache,\
dst=/app/target \
    myapp-dev:latest

# Changes to ./src on host are immediately visible
# in container - no rebuild needed
```

> **Code walkthrough:** The bind mount maps the host source directory
> into the container as read-only - preventing the container from
> accidentally modifying source files. The target directory uses a
> named volume (not a bind mount) so the container's compiled classes
> are not mixed with the host's target directory. This pattern enables
> live reload: when source changes on the host, the container sees
> the changes immediately.

**Example 3: Backing up and restoring volumes**

```bash
# Backup a named volume to a tar archive
docker run --rm \
    --mount type=volume,src=pgdata,dst=/data,readonly \
    --mount type=bind,src=$(pwd)/backups,dst=/backup \
    alpine tar czf /backup/pgdata-backup.tar.gz \
    -C /data .

# Restore a volume from archive
docker run --rm \
    --mount type=volume,src=pgdata-restored,dst=/data \
    --mount type=bind,src=$(pwd)/backups,dst=/backup,readonly \
    alpine sh -c \
    "cd /data && tar xzf /backup/pgdata-backup.tar.gz"
```

> **Code walkthrough:** The backup pattern uses a temporary alpine
> container with two mounts: the source volume (read-only) and a bind
> mount to the backup directory on the host. tar creates the archive
> to the bind-mounted host directory. The restore reverses this: a new
> volume receives the extracted data. This portable backup technique
> does not depend on Postgres being stopped - for a consistent backup,
> use pg_dump instead for a live database.

---

### ⚖️ Comparison

| Storage Type | Persistence | Portability | Performance | Use When |
|---|---|---|---|---|
| **Named Volume** | Yes (daemon) | Low (daemon-local) | Best | Production databases, app data |
| Bind Mount | Yes (host) | None (host-specific) | Best | Dev source code, local config |
| tmpfs | No (memory only) | None | Best (RAM) | Secrets, temp high-speed writes |
| Kubernetes PVC | Yes (cluster) | High (dynamic provisioner) | Varies | Production Kubernetes workloads |

**The deciding factor:**
Named volumes for production Docker single-host. PVCs for Kubernetes.
Never bind mounts in production - they create host path dependencies
that break when containers move. Never write persistent data to the
container layer - it is lost on container removal.

---

### 🔥 Field Q&A

#### Production Failures

Q: A Postgres container was updated (docker rm + docker run new image)
and all data was lost.

A: The data was written to the container's writable layer, not to a
named volume. When docker rm was called, the writable layer was discarded.
The fix is to mount /var/lib/postgresql/data to a named volume BEFORE
any data is written. For recovery: if the container image is still
present, docker diff old-container shows the changed files in the
writable layer. If the container was removed with -v (volume removal),
the data is unrecoverable. Lesson: never run stateful containers without
named volumes.

Q: A container writing to a named volume has poor write performance.
iostat shows high I/O wait on the host.

A: Named volume I/O goes through the host filesystem and the container
overlay filesystem stacking. For write-intensive workloads (databases,
Kafka), the overlay filesystem adds latency. Solutions: (1) Use the
host-native filesystem directly with a bind mount (though this couples
to the host path), (2) Use Docker's volume driver with native storage
(the local volume driver with ext4 or xfs directly), (3) For Kubernetes,
use a high-performance StorageClass backed by SSD with direct block device
access. For Postgres specifically, disable synchronous commits during bulk
loads and tune checkpoint settings.

Q: All container data on a node was lost after docker system prune -a -v.

A: The -v flag removes all volumes not currently in use by a container.
If containers were stopped (not running) at the time, their volumes were
pruned. Recovery: check if the data directory was also backed up by any
other mechanism. Prevention: never use -v with system prune in production.
Use targeted cleanup: docker image prune for images, docker container prune
for stopped containers, but avoid docker volume prune in production.

#### Candidate Mistakes

Q: Candidate stores database data in the container without a volume.

**What NOT to say:** "The data stays in the container as long as it's running."

**Say instead:** "Container filesystems are ephemeral. Any write to the container's
writable layer is lost when the container is removed. For a database like Postgres,
I always mount the data directory to a named volume:
--mount type=volume,src=pgdata,dst=/var/lib/postgresql/data.
The named volume persists independently of the container lifecycle."

Q: Candidate uses bind mounts for production data storage.

**What NOT to say:** "Bind mounts are simpler and give the same persistence."

**Say instead:** "Bind mounts create a tight coupling to a specific host path.
In Kubernetes, pods can be scheduled on any node, so a bind mount to /data/pgdata
breaks unless that path exists on every node. Named volumes (and Kubernetes PVCs)
abstract the storage location, making the deployment portable."

Q: Candidate runs docker volume prune in a cleanup script.

**What NOT to say:** "This removes old volumes to free up space."

**Say instead:** "docker volume prune removes all volumes not currently used by
a running container. If a container is stopped (not running), its volumes are
pruned. This is a data loss risk. I use docker volume ls to identify orphaned
volumes manually and remove only those I know are safe to delete."

Q: Candidate is unaware that the --mount syntax is preferred over -v.

**What NOT to say:** "-v flag works the same as --mount."

**Say instead:** "Both work, but --mount is more explicit. The -v syntax accepts
both volume names and host paths with different behavior: -v pgdata:/data
creates a named volume, -v /host/path:/data creates a bind mount. This ambiguity
has caused production mistakes. The --mount flag requires explicit type=volume
or type=bind, making the intent clear."

#### Questions to Ask the Interviewer

Q: "How do you back up named volumes for your stateful containers?"

*Why:* Reveals operational maturity for stateful container management.

*If asked back:* "For Postgres, we use pg_dump for logical backups and
store them in S3. For Docker volumes in general, we use the temporary
alpine container pattern: run a container that mounts the volume read-only
and another container that mounts a backup destination, then tar the data."

Q: "For Kubernetes stateful workloads, which StorageClass and provisioner
do you use?"

*Why:* Tests Kubernetes storage maturity beyond Docker volumes.

*If asked back:* "For databases, we use a high-performance StorageClass
backed by SSDs with ReadWriteOnce access mode. For shared file storage,
we use ReadWriteMany via NFS or EFS. The default gp2 EBS volumes on AWS
are too slow for databases under write load."

Q: "What is your policy on using containers for stateful workloads?"

*Why:* Tests architectural philosophy on stateful vs stateless container design.

*If asked back:* "For most new projects, we prefer managed services
(RDS, ElastiCache) over stateful containers. Managed services handle
backups, failover, and patching. Containers for databases make sense
for development environments and batch jobs but require significant
operational overhead in production."

Q: "How do you handle volume migration when upgrading a stateful container?"

*Why:* Tests operational experience with stateful container updates.

*If asked back:* "The pattern is: backup the volume, stop the old container,
start the new container with the same named volume. For Postgres major versions,
data directory format changes require pg_dump/restore instead of just reconnecting
the volume to the new container."

#### Live Coding Context

Coding question template: "Set up a docker-compose.yml for a Spring Boot
application with Postgres that persists database data across container restarts."

What the interviewer watches:
- Whether you use a named volume for Postgres data
- Whether you mount the volume at the correct Postgres data path
- Whether you use docker-compose volumes: declaration at the file level
- Whether you include a healthcheck for Postgres before starting the app

Most common implementation mistake:
Declaring -v ./data:/var/lib/postgresql/data (bind mount) instead of
a named volume, which couples the setup to the developer's current directory.

*Why this signals:* Understanding named volumes vs bind mounts in compose
shows awareness of portability and the correct production storage pattern.

---
---

# Container Logging Strategies

**Interview Weight:** high - Container logging is the operational
visibility question. Interviewers ask this to verify you understand
stdout-first logging, structured logging, and how logs flow to
aggregation systems in Kubernetes.

---

### 🎯 Model Answer

**30 seconds:**

> The container logging model is stdout-first: containers write logs
> to stdout and stderr, the container runtime captures them, and a
> log driver or agent ships them to a centralized system. For Java
> services, this means configuring Logback or Log4j2 to write JSON-
> structured logs to stdout. Structured logs with consistent fields
> (traceId, serviceName, level) enable efficient querying in Elasticsearch
> or CloudWatch. Never write logs to a file inside the container - the
> file disappears when the container stops.

**3 minutes (Senior):**

> The design principle is the 12-factor app factor XI: logs as event
> streams. The application writes to stdout, treating logs as an event
> stream, not a file. The container runtime handles collection and routing.
> This separation of concerns means the application does not need to know
> where logs go - a change from stdout-to-file to stdout-to-Kafka requires
> zero application changes.
>
> For Java containers, the practical configuration is Logback with the
> logstash-logback-encoder library, which formats every log line as JSON:
> timestamp, level, logger, message, MDC context (traceId, userId), and
> any key-value pairs. JSON-structured logs are parseable by any log
> aggregation system without regex parsing rules.
>
> In Kubernetes, the DaemonSet log collector (Fluentd, Fluent Bit) runs
> on every node and collects container stdout/stderr from
> /var/log/containers/. This requires no changes to the application -
> the log collection infrastructure is separate from the application image.
> The critical operational parameter is log retention: Kubernetes rotates
> logs based on file size and count, but logs from deleted pods are gone.
> Ensure your log aggregation system ships logs faster than rotation.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff discusses observability strategy (logs + metrics +
traces unified), structured log schemas, log sampling for high-volume
services, and cost management for log storage.

*Adapting down:* Junior: "Log to stdout so docker logs works and
Kubernetes can collect the logs. Use JSON format for easier parsing."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about container logging strategies -
let me think through where logs go in a container environment."

**(2) First principles:** "A container is ephemeral. Its filesystem is
gone when it stops. Logs written to files inside containers are lost.
The solution is to write logs to stdout where the runtime collects them."

**(3) Bridge:** "This is the 12-factor app principle - treat logs as
event streams, not files. The container runtime is the stream consumer."

---

### 📘 Concept Explanation

**What it is:**
Container logging is the pattern of writing application logs to stdout
and stderr, having the container runtime capture them, and using an
aggregation pipeline to ship them to a centralized store.

**The problem it solves:**
Container filesystems are ephemeral. Log files written inside a container
disappear when the container stops. Applications need a logging strategy
that works with the container lifecycle without requiring file system access.

**How it works:**

```
Log flow:
  App writes to stdout
    |
  Container runtime captures
    |
  Log driver writes to host
    /var/log/containers/app-*.log
    |
  DaemonSet collector (Fluent Bit)
    reads host log files
    |
  Log aggregation (Elasticsearch/CloudWatch)
    |
  Dashboard (Kibana / Grafana)

Alternative: sidecar container
  App writes to shared volume
  Sidecar reads + ships to aggregator
```

**The key insight:**
The application logs to stdout. The collection infrastructure is
deployed separately (DaemonSet). The application image has zero
knowledge of where logs go. This is the correct separation of concerns.

**When to use file-based logging inside containers:**
Never for production containers. The only valid use case is a volume-
mounted log file shared with a sidecar container for processing.

**When to use sidecar collectors:**
When the log source cannot write to stdout (legacy app that only writes
to files, log aggregation requiring pre-processing before shipping).

**Alternatives:**
- Direct application shipping (app writes to Kafka/Elasticsearch) - couples
  application to log infrastructure
- Sidecar pattern - volume-shared log files collected by a separate container
- Node log agent DaemonSet (Fluent Bit) - recommended Kubernetes pattern

**First-principles derivation:**
Logs must outlive the process that created them. In containers, the
process is ephemeral. stdout/stderr is a POSIX standard that all
container runtimes capture and persist. Writing to stdout is the only
guaranteed-persistent log channel in a container environment.

---

### 💻 Code Example

**Example 1: Java Logback JSON configuration**

```xml
<!-- logback-spring.xml for structured JSON logging -->
<configuration>
  <!-- Import Spring defaults first -->
  <springProfile name="!local">
    <appender name="STDOUT"
        class="ch.qos.logback.core.ConsoleAppender">
      <encoder
          class="net.logstash.logback.encoder.LogstashEncoder">
        <!-- Add service identification fields -->
        <customFields>
          {"service":"order-service",
           "env":"${SPRING_PROFILES_ACTIVE}"}
        </customFields>
        <!-- Include MDC fields (traceId, userId, etc.) -->
        <includeMdcKeyName>traceId</includeMdcKeyName>
        <includeMdcKeyName>spanId</includeMdcKeyName>
        <includeMdcKeyName>userId</includeMdcKeyName>
      </encoder>
    </appender>
    <root level="INFO">
      <appender-ref ref="STDOUT" />
    </root>
  </springProfile>

  <!-- Human-readable format for local development -->
  <springProfile name="local">
    <appender name="STDOUT"
        class="ch.qos.logback.core.ConsoleAppender">
      <encoder>
        <pattern>%d{HH:mm:ss} %-5level %logger{36}
          %X{traceId} - %msg%n</pattern>
      </encoder>
    </appender>
    <root level="DEBUG">
      <appender-ref ref="STDOUT" />
    </root>
  </springProfile>
</configuration>
```

> **Code walkthrough:** The LogstashEncoder formats every log line as JSON.
> The customFields add static service identification to every log entry -
> essential in Elasticsearch when logs from 50 services arrive in the same
> index. MDC fields (traceId, spanId) enable distributed trace correlation:
> when a request spans multiple services, all log lines for that request
> share the same traceId. The local profile uses human-readable format for
> developer ergonomics - JSON is hard to read in a terminal.

**Example 2: Adding trace context to logs with OpenTelemetry**

```java
// Spring Boot + Micrometer Tracing (Bridge to OTel)
// Auto-populates MDC with traceId and spanId

@RestController
public class OrderController {

    private static final Logger log =
        LoggerFactory.getLogger(OrderController.class);

    @PostMapping("/orders")
    public ResponseEntity<Order> createOrder(
            @RequestBody OrderRequest req) {
        // MDC is auto-populated by Micrometer Tracing
        // {"traceId":"abc123","spanId":"def456"}
        log.info("Creating order for user={}",
            req.getUserId());
        // Log line in JSON:
        // {"level":"INFO","message":"Creating order
        //  for user=user123","traceId":"abc123",
        //  "spanId":"def456","service":"order-service"}
        Order order = orderService.create(req);
        log.info("Order created orderId={}", order.getId());
        return ResponseEntity.ok(order);
    }
}
```

> **Code walkthrough:** Micrometer Tracing (with the OTel bridge) automatically
> populates MDC with the current trace and span IDs on every request thread.
> The Logback JSON encoder includes MDC fields in every log line. The result
> is that all log lines for one HTTP request share the same traceId, enabling
> cross-service trace correlation in Jaeger or Zipkin. This requires zero
> per-log-call MDC management in application code.

**Example 3: Kubernetes log collection configuration**

```yaml
# Fluent Bit DaemonSet config (simplified)
# Deployed once per node - collects all container logs
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
data:
  fluent-bit.conf: |
    [INPUT]
        Name tail
        Path /var/log/containers/*.log
        multiline.parser docker, cri
        Tag kube.*
        Mem_Buf_Limit 5MB

    [FILTER]
        Name kubernetes
        Match kube.*
        Merge_Log On  # merge JSON logs from app
        K8S-Logging.Parser On

    [OUTPUT]
        Name es
        Match *
        Host elasticsearch.logging
        Port 9200
        Index docker-logs
        Logstash_Format On
```

> **Code walkthrough:** Fluent Bit runs on every Kubernetes node and
> tails /var/log/containers/ which is where Kubernetes writes container
> stdout/stderr. The kubernetes filter enriches each log line with pod
> metadata (namespace, pod name, labels). The Merge_Log option parses
> the app's JSON log output and merges fields into the log document.
> The result in Elasticsearch is a document with both the Kubernetes
> metadata and the application's structured fields as first-class fields.

---

### ⚖️ Comparison

| Strategy | Coupling | Ops Overhead | Reliability | Use When |
|---|---|---|---|---|
| **stdout + node DaemonSet** | None | Low | High | All Kubernetes deployments |
| stdout + sidecar collector | Low | Medium | High | Multi-format logs, pre-processing needed |
| File in volume + agent | Medium | High | Medium | Legacy apps that can't log to stdout |
| Direct app shipping to Kafka | High | Low | Low | Never (couples app to infra) |

**The deciding factor:**
stdout + Kubernetes DaemonSet (Fluent Bit or Fluentd) for all new containers.
Use sidecar only for legacy applications that cannot write to stdout.
Never write logs to files inside the container - they are ephemeral.

---

### 🔥 Field Q&A

#### Production Failures

Q: Pod logs are empty in kubectl logs even though the application
is clearly running and processing requests (metrics show active traffic).

A: The application is logging to a file inside the container, not
to stdout. kubectl logs only shows stdout and stderr captured by the
container runtime. The logs exist inside the container at the file
path. Short-term fix: docker exec or kubectl exec into the pod and
cat the log file. Long-term fix: configure the logger to write to stdout
(ConsoleAppender in Logback). Also check that the logging level is not
accidentally set to OFF.

Q: Log volume in Elasticsearch has exploded after enabling DEBUG
logging on one service. The cluster is running out of disk space.

A: DEBUG logging in production is almost always a mistake. Fix:
change the log level back to INFO or WARN via Spring Boot's actuator
endpoint without restarting: POST /actuator/loggers/com.example
{"configuredLevel":"INFO"}. For preventing future incidents, add
log sampling for high-frequency debug paths or use structured log
filtering to drop logs below a severity threshold at the collector level.
In Fluent Bit, add a filter to drop DEBUG logs before shipping to Elasticsearch.

Q: Logs from deleted pods are missing in Elasticsearch. Need to
investigate an incident from 2 hours ago.

A: When a pod is deleted, its log files in /var/log/containers/ are
also deleted. If Fluent Bit has not shipped those logs to Elasticsearch
before deletion, they are lost. Prevention: ensure Fluent Bit's
memory_buf_limit and flush interval are set to ship logs quickly.
Also consider increasing Kubernetes log rotation settings to keep more
log history on the node. For incident investigation, check if your log
aggregation system received the logs before deletion - the problem is
Fluent Bit collection latency, not the logs themselves being absent.

#### Candidate Mistakes

Q: Candidate configures a rolling file appender in Logback for a container.

**What NOT to say:** "Rolling files manage log size automatically."

**Say instead:** "Log files written inside a container are ephemeral -
they disappear when the container is removed. For containers, I configure
Logback with a ConsoleAppender writing JSON to stdout. The container runtime
captures stdout and the Kubernetes DaemonSet collector ships it to
Elasticsearch. Log rotation is handled at the collection layer, not
the application layer."

Q: Candidate does not use structured (JSON) logging.

**What NOT to say:** "Plain text logs are easier to read."

**Say instead:** "Plain text logs require the log aggregation system to
parse log lines with regex patterns. Every format change breaks the parser.
JSON-structured logging writes machine-parseable key-value pairs: timestamp,
level, message, traceId. Any log aggregation system can ingest JSON without
parser configuration. The tradeoff is readability - I use a human-readable
format for local development and switch to JSON in all deployed environments."

Q: Candidate is unaware of distributed trace correlation in logs.

**What NOT to say:** "I search logs by service name and time range."

**Say instead:** "For microservice debugging, I use trace correlation.
Micrometer Tracing with OpenTelemetry propagates a traceId across service
boundaries and adds it to MDC. The Logback JSON encoder includes the traceId
in every log line. In Elasticsearch, I can query all log lines for a single
HTTP request across multiple services by filtering on traceId."

Q: Candidate suggests writing logs to a volume for persistence.

**What NOT to say:** "Mount a volume for the log directory so logs survive restarts."

**Say instead:** "Writing logs to a volume works for survival across restarts,
but creates operational complexity - you need to manage volume lifecycle,
rotation, and cleanup separately. The correct pattern is stdout-to-DaemonSet:
the application writes to stdout, the Fluent Bit DaemonSet ships logs to
Elasticsearch in real time. If a pod is deleted, the logs are already in
Elasticsearch."

#### Questions to Ask the Interviewer

Q: "How do you correlate logs across microservices for distributed
request tracing?"

*Why:* Tests observability sophistication.

*If asked back:* "We use OpenTelemetry with Micrometer Tracing to propagate
traceId across service boundaries via HTTP headers. Every log line includes
the traceId in the MDC, so we can query Kibana for all log lines across
all services for a single request."

Q: "What is your log retention policy and how do you manage log costs?"

*Why:* Shows awareness of log economics at scale.

*If asked back:* "We retain hot logs in Elasticsearch for 7 days for fast
querying, then move to cold storage (S3) for 90 days at 1/10th the cost.
For high-volume services, we sample DEBUG and INFO logs (keep 10%) and
retain all ERROR and WARN logs. This reduced our log ingestion costs by 60%."

Q: "How do you prevent log loss in Kubernetes when pods are deleted quickly?"

*Why:* Tests operational depth around log collection reliability.

*If asked back:* "Fluent Bit has a memory buffer that retains logs if the
output plugin is backpressured. We set mem_buf_limit=50MB and use the
filesystem storage type to spill to disk. We also alert when Fluent Bit's
buffer usage exceeds 80%, which indicates Elasticsearch is not accepting
logs fast enough."

Q: "Do you log at DEBUG level in production for any services?"

*Why:* Tests production hygiene.

*If asked back:* "No - DEBUG logging in production costs too much in I/O,
log storage, and parsing. For incident investigation, we temporarily enable
DEBUG for specific logger names via the Spring Actuator log endpoint without
restarting the service. We disable it within 30 minutes."

#### Live Coding Context

Coding question template: "Configure a Spring Boot service for production
logging in Kubernetes with trace correlation support."

What the interviewer watches:
- Whether you use ConsoleAppender (stdout) not rolling file appender
- Whether you configure JSON output format
- Whether you include traceId in log output
- Whether you mention the Fluent Bit DaemonSet for collection

Most common implementation mistake:
Configuring a file appender in logback-spring.xml, which writes logs
to the container filesystem that are lost on pod deletion.

*Why this signals:* This is a production container operations question.
Writing to files in a container is a common mistake made by teams
transitioning from VM-based deployments.

---
---

# Docker Registry and Image Management

**Interview Weight:** high - Registries are the distribution mechanism
for container images. Interviewers ask this to verify you understand
the image promotion pipeline, tagging strategies, and registry security.

---

### 🎯 Model Answer

**30 seconds:**

> A Docker registry stores and distributes container images. Docker Hub
> is the default public registry. For production, teams use private
> registries: AWS ECR, GCR, Azure ACR, or self-hosted Harbor. An image
> promotion pipeline builds once, pushes to a dev registry, and promotes
> the same image by digest to staging and production registries. Tagging
> strategy matters: use semantic version tags for stable releases, and
> never rely on the latest tag for production deployments.

**3 minutes (Senior):**

> The registry is the artifact store for the container supply chain.
> The core principle is immutability: once an image is pushed and tested,
> the same artifact (identified by its SHA256 digest) should be deployed
> to all environments. Re-building the image for each environment
> introduces the possibility of non-deterministic builds producing
> different artifacts.
>
> An image promotion pipeline: CI builds the image, pushes to a dev
> registry (or dev namespace in the same registry), runs tests against
> that specific image (referenced by digest), then promotes (copies,
> not rebuilds) to a staging tag, tests again, promotes to a production
> tag. At each stage, the image digest is recorded as a pipeline artifact
> for auditability.
>
> Registry security has two dimensions: authentication (who can push)
> and image scanning (what CVEs are in the image). AWS ECR integrates
> with IAM for authentication and AWS Inspector for scanning. Harbor
> adds policy enforcement - you can configure a rule that blocks images
> with critical CVEs from being pulled by production deployments.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff discusses software supply chain security (SLSA
framework, image signing with Cosign), SBOM generation, and multi-
registry replication for multi-region deployments.

*Adapting down:* Junior: "Registries store images. Push with docker push,
pull with docker pull. Use private registries for your own images."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Docker registries - let me think
through how images get distributed from build to deployment."

**(2) First principles:** "Images need to be stored somewhere and
distributed to nodes that run them. That is a registry. The question
is public vs private, tagging strategy, and security."

**(3) Bridge:** "A registry is like Maven Central for containers.
You push your artifact (image), and consumers pull it from anywhere."

---

### 📘 Concept Explanation

**What it is:**
A Docker registry is a server that stores and distributes Docker
(OCI) images. Images consist of layer blobs and a manifest. The
registry provides pull and push APIs for image distribution.

**The problem it solves:**
Docker images built on a CI server need to be accessible to production
nodes, which may be in different data centers. Registries provide
centralized storage, distribution, and access control for images.

**How it works:**

```
Image Promotion Pipeline:
  CI Build
    | docker build -t myapp:commit-abc123
    |
    v
  Dev Registry
    dev.registry.io/myapp:commit-abc123
    | Run tests against this exact image
    | docker push prod.registry.io/myapp:1.0.0
    v
  Staging Registry
    staging.registry.io/myapp:1.0.0
    | Run integration tests
    | Promote (copy manifest, not rebuild)
    v
  Production Registry
    prod.registry.io/myapp:1.0.0 (same digest)
```

**The key insight:**
Tags are mutable aliases to digests. The same tag can point to
different images after a push. Promotion pipelines must record
and verify the digest at each stage to guarantee the same image
is deployed everywhere.

**When to use a private registry:**
Any production workload with proprietary code. All registries
for Kubernetes production clusters should be private and authenticated.

**When to use the latest tag:**
Development convenience only. Never in CI/CD pipelines or production
deployments. `latest` pointing to different images on different
pulls is a source of non-reproducible deployments.

**Alternatives:**
- Docker Hub (public) - open source projects, public images
- AWS ECR - AWS-integrated, IAM authentication, scanning
- Google Artifact Registry - GCP-integrated
- Harbor - self-hosted, open-source with policy enforcement
- JFrog Artifactory - enterprise multi-format artifact registry

**First-principles derivation:**
CI/CD requires artifacts to be stored durably between pipeline stages.
Container images are the artifact. Registries are the artifact store
for images, providing the same function as Maven Nexus for JARs but
optimized for the layer-based OCI image format.

---

### 💻 Code Example

**Example 1: Image tagging and promotion strategy**

```bash
# Build with Git commit hash for traceability
GIT_SHA=$(git rev-parse --short HEAD)
docker build \
    -t myregistry.io/myapp:${GIT_SHA} \
    -t myregistry.io/myapp:latest \
    .

# Push to registry
docker push myregistry.io/myapp:${GIT_SHA}
docker push myregistry.io/myapp:latest

# Record the immutable digest for promotion
DIGEST=$(docker inspect --format \
    '{{index .RepoDigests 0}}' \
    myregistry.io/myapp:${GIT_SHA})
echo "Image digest: ${DIGEST}"
# myregistry.io/myapp@sha256:abc123def456...

# Promote to production by tag (mutable alias)
docker tag myregistry.io/myapp:${GIT_SHA} \
    myregistry.io/myapp:v1.2.0
docker push myregistry.io/myapp:v1.2.0

# Pull by digest for guaranteed reproducibility
docker pull myregistry.io/myapp@sha256:abc123...
```

> **Code walkthrough:** The commit hash tag (${GIT_SHA}) is the primary
> traceability tag - it links every image to the exact source commit.
> The digest is extracted and stored as a pipeline artifact. Promoting
> to a version tag (v1.2.0) creates a mutable human-friendly reference
> that points to the same image. In Kubernetes deployment manifests,
> using the digest ensures the exact tested image is deployed regardless
> of tag mutations.

**Example 2: Registry cleanup and lifecycle management**

```bash
# List images in registry (AWS ECR example)
aws ecr list-images \
    --repository-name myapp \
    --filter tagStatus=UNTAGGED \
    --query 'imageIds[*].imageDigest' \
    --output text

# Delete untagged images (dangling layers)
aws ecr batch-delete-image \
    --repository-name myapp \
    --image-ids imageTag=UNTAGGED

# ECR lifecycle policy to retain only last 10 tagged
# (set via AWS console or CLI)
aws ecr put-lifecycle-policy \
    --repository-name myapp \
    --lifecycle-policy-text '{
      "rules":[{
        "rulePriority":1,
        "selection":{
          "tagStatus":"tagged",
          "tagPrefixList":["v"],
          "countType":"imageCountMoreThan",
          "countNumber":10
        },
        "action":{"type":"expire"}
      }]
    }'
```

> **Code walkthrough:** Registry cleanup prevents unbounded growth.
> Untagged images are dangling layers from previous builds - they can
> be deleted without affecting running deployments (tagged images still
> reference their layers). ECR lifecycle policies automate cleanup -
> the policy above keeps the last 10 version-tagged images. For a
> high-frequency deployment pipeline, this prevents registry storage
> costs from growing without bound.

---

### ⚖️ Comparison

| Registry | Auth | Scanning | Multi-Region | Cost |
|---|---|---|---|---|
| **AWS ECR** | IAM | AWS Inspector | Replication | Per GB + API calls |
| Docker Hub | Docker accounts | Basic (paid) | None | Free/paid tiers |
| Google Artifact Registry | IAM/Workload Identity | Binary Authorization | Yes | Per GB |
| Harbor | OIDC/LDAP | Trivy integration | Via replication | Free (self-hosted ops cost) |
| JFrog Artifactory | Enterprise SSO | Xray integration | Yes | Commercial license |

**The deciding factor:**
Use the registry from your cloud provider for authentication simplicity.
Use Harbor when you need policy enforcement (block CVE-containing images
from being pulled) or when cloud-vendor lock-in is a concern.

---

### 🔥 Field Q&A

#### Production Failures

Q: CI pipeline succeeds and pushes an image but the Kubernetes deployment
fails to pull it from the private registry.

A: Authentication failure between Kubernetes nodes and the registry.
Kubernetes uses an image pull secret to authenticate to private registries.
Diagnosis: kubectl describe pod shows "ErrImagePull: unauthorized".
Fix: create a Kubernetes secret with registry credentials:
kubectl create secret docker-registry regcred
--docker-server=myregistry.io --docker-username=... --docker-password=...
and reference it in the deployment spec with imagePullSecrets. For AWS ECR,
the better approach is IAM role for service account (IRSA) which provides
credential rotation automatically.

Q: Two services deployed on the same commit hash behave differently.
The same image tag shows different behavior on different nodes.

A: Tag mutation - the image tag was pushed with different content between
the two node pulls. One node pulled the old content, the other pulled the new.
This is the mutable tag problem. The fix is to deploy by digest, not tag.
In Kubernetes, specify the full image reference with digest:
image: myregistry.io/myapp@sha256:abc123. The digest guarantees the exact
image content regardless of when the pull happens. Also, Kubernetes's
imagePullPolicy: IfNotPresent (the default) means nodes use the cached image
if the same tag is already present - preventing this class of bug.

Q: Registry storage costs are growing 10x per month. CI creates 50 images per day.

A: Each CI build creates a new image with a unique tag. Without lifecycle
management, the registry accumulates thousands of images. Fix: implement a
lifecycle policy that retains images by age (delete images older than 30 days)
and count (keep last 20 per branch). In the CI pipeline, after a successful
deployment, tag the deployed image with the environment name and run cleanup
of old environment-specific tags. The lifecycle policy must keep release-tagged
images (v1.0.0, v1.1.0) permanently but prune commit-hash images aggressively.

#### Candidate Mistakes

Q: Candidate uses the :latest tag for production deployments.

**What NOT to say:** ":latest always has the newest version."

**Say instead:** "The :latest tag is mutable - it points to whatever was last
pushed with that tag. If a bad push overwrites :latest, all nodes that pull
will get the broken image. I use either a specific version tag (v1.2.3) or
an image digest for production deployments. The digest guarantees the exact
image is deployed."

Q: Candidate rebuilds the image separately for each environment.

**What NOT to say:** "Each environment needs its own build with the right configuration."

**Say instead:** "Rebuilding the image per environment means different environments
run different artifacts even if the same code was used. Environment-specific
configuration should be injected via environment variables or ConfigMaps at
runtime, not baked into the image at build time. The principle is: build once,
configure at deploy time."

Q: Candidate is unaware of image scanning in the registry.

**What NOT to say:** "We scan images with Trivy in CI."

**Say instead:** "CI scanning catches CVEs at build time, but new CVEs are
discovered daily. Registry-integrated scanning (AWS Inspector for ECR, Trivy
in Harbor) continuously rescans all stored images and alerts when new CVEs
are found against images already in the registry. This catches CVEs in images
that were clean when built but have since become vulnerable."

Q: Candidate does not clean up old images in the registry.

**What NOT to say:** "Storage is cheap - we keep everything."

**Say instead:** "Registry storage grows with every build. A CI system pushing
50 images per day accumulates 1500 images per month. Without lifecycle policies,
costs grow linearly. I configure lifecycle policies to retain the last N images
per major branch and delete images older than 30 days, keeping only the images
that could realistically be needed for rollback."

#### Questions to Ask the Interviewer

Q: "What is your image promotion strategy - do you build once or rebuild
per environment?"

*Why:* Tests understanding of immutable artifact pipelines.

*If asked back:* "We build once in CI and promote the same image by
digest through dev, staging, and production. Environment configuration
is injected at deploy time via Kubernetes ConfigMaps and environment
variables. The image itself contains only the compiled application code."

Q: "How do you manage registry access from Kubernetes nodes?"

*Why:* Tests Kubernetes-registry authentication knowledge.

*If asked back:* "For AWS ECR, we use IAM Roles for Service Accounts
(IRSA). Each pod assumes an IAM role that has ECR pull permissions.
No credential rotation needed - IAM handles it automatically. We avoid
long-lived registry credentials in Kubernetes secrets."

Q: "What is your policy when a critical CVE is found in a base image
used by production containers?"

*Why:* Tests security operational maturity.

*If asked back:* "We have an automated pipeline triggered by registry
scanning alerts. When a critical CVE is detected in any production
image, the pipeline rebuilds the image with an updated base, runs all
tests, and deploys to production within 24 hours. For zero-day CVEs,
we have a manual fast-track that bypasses the full test suite and goes
directly to a smoke-test-verified production deploy."

Q: "Do you use image signing in your pipeline?"

*Why:* Tests supply chain security awareness.

*If asked back:* "We use Cosign to sign images with a key managed by
AWS KMS. Our Kubernetes admission controller (OPA Gatekeeper) rejects
unsigned images. This ensures only images built by our CI pipeline and
signed with our key can run in production."

#### Live Coding Context

Coding question template: "Design a CI/CD pipeline stage for building
and pushing a Java Docker image with proper tagging for traceability and
promoting to production."

What the interviewer watches:
- Whether you tag with a unique identifier (commit hash) not just latest
- Whether you record the image digest for promotion
- Whether you deploy by digest in production
- Whether you mention registry authentication (not hardcoded credentials)

Most common implementation mistake:
Using docker push myimage:latest and then deploying with image: myimage:latest
in Kubernetes - no traceability, mutable tag, non-reproducible deployments.

*Why this signals:* This distinguishes teams with mature CI/CD practices
from those that have "it works" pipelines without reproducibility guarantees.

---
---

# Container Environment Variables and Config

**Interview Weight:** high - Configuration management in containers
is the 12-factor app applied to Kubernetes. Interviewers ask this to
verify you understand the separation of config from image, secret
management, and how to avoid leaking credentials.

---

### 🎯 Model Answer

**30 seconds:**

> Container configuration is injected at runtime via environment variables,
> not baked into the image. The 12-factor app principle is: the same image
> runs in dev, staging, and production with only the environment variables
> changing. In Kubernetes, ConfigMaps hold non-sensitive config and Secrets
> hold sensitive values. The critical security rule is to never set credentials
> in Dockerfile ENV instructions - they appear in docker inspect and image
> history for anyone with image access.

**3 minutes (Senior):**

> The configuration hierarchy for containers has four levels. First, Dockerfile
> defaults (ENV instructions) set compile-time defaults that are baked into
> the image - appropriate only for non-sensitive defaults like the server port.
> Second, docker run or compose file environment variables override the Dockerfile
> defaults at container creation - good for development. Third, Kubernetes
> ConfigMaps inject configuration from the cluster without rebuilding the image.
> Fourth, Kubernetes Secrets inject sensitive values from a secrets store.
>
> The security concern with environment variables is their visibility: they
> are visible in docker inspect, kubernetes describe pod, and application
> memory dumps. For highly sensitive values (encryption keys, OAuth private keys),
> file-based secrets (mounted as volumes from Kubernetes Secrets) or external
> secrets managers (AWS Secrets Manager, HashiCorp Vault via the Vault agent
> sidecar) are more secure because they are not in the process environment.
>
> Spring Boot's externalized configuration supports all four levels natively:
> application.properties < application-{profile}.properties < ENV variables
> < command-line arguments. The Spring Cloud Config Server adds a fifth level
> for centralized configuration management across many services.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff discusses secret rotation without pod restarts (external
secret store + Vault agent sidecar), ConfigMap hot reload, and the security
threat model for each configuration injection method.

*Adapting down:* Junior: "Inject config via environment variables, not baked
into the image. In Kubernetes, use ConfigMaps for non-sensitive and Secrets
for passwords."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about container configuration management -
let me think through the 12-factor app configuration principle."

**(2) First principles:** "An image is an immutable artifact. Config changes
per environment. They must be separated. Environment variables are the
standard interface for injecting config at runtime."

**(3) Bridge:** "This is like Java's externalized configuration - you
have defaults in code, overrides in properties files, and further overrides
in environment variables. Same hierarchy, applied to containers."

---

### 📘 Concept Explanation

**What it is:**
Container environment configuration is the set of runtime values
(database URLs, credentials, feature flags) injected into a container
at startup via environment variables, volume-mounted files, or ConfigMaps
and Secrets in Kubernetes.

**The problem it solves:**
Baking environment-specific configuration into images means rebuilding
for each environment - defeating the "build once, deploy anywhere" principle.
External configuration enables the same image to run in dev, staging, and production.

**How it works:**

```
Configuration priority (Spring Boot):
  Low priority:
  1. Dockerfile ENV defaults
  2. docker-compose env: values
  3. .env file (compose)
  4. Kubernetes ConfigMap (env from)
  5. Kubernetes Secret (env from)
  6. Command-line arguments
  High priority

Spring Boot resolution:
  application.properties (in JAR) -> profile props
  -> env vars (SPRING_DATASOURCE_URL maps to
              spring.datasource.url)
  -> command-line args
```

**The key insight:**
Environment variables are visible to anyone who can run docker inspect
or kubectl describe pod. They are not a secure channel for highly sensitive
values. For cryptographic keys and OAuth private keys, use file-based
secrets mounted from Vault or Kubernetes Secrets with RBAC.

**When to use environment variables:**
Non-sensitive configuration: database hostnames (not passwords), feature
flags, log levels, server ports, timeout values.

**When to use Kubernetes Secrets:**
Passwords, API keys, TLS certificates. Remember: Kubernetes Secrets
are only base64-encoded by default (not encrypted). Use sealed-secrets
or external secret operators for at-rest encryption.

**Alternatives:**
- Spring Cloud Config Server - centralized config management
- HashiCorp Vault - proper secrets management with rotation
- AWS Secrets Manager - managed secrets with automatic rotation
- Azure Key Vault / GCP Secret Manager - cloud-native equivalents

**First-principles derivation:**
A container image is immutable code. Configuration is mutable state that
changes per environment. Mixing immutable code with mutable config makes
both harder to reason about. Separation (config via env or secret injection)
is the only design that enables the same artifact to be verified in one
environment and trusted to behave identically in another.

---

### 💻 Code Example

**Example 1: Environment variable injection patterns**

```dockerfile
# BAD: sensitive values baked into image
FROM eclipse-temurin:21-jre-alpine
# These appear in docker history and docker inspect!
ENV DB_PASSWORD=secret123
ENV API_KEY=abc123

# GOOD: non-sensitive defaults in image
FROM eclipse-temurin:21-jre-alpine
# Only non-sensitive defaults in Dockerfile
ENV SERVER_PORT=8080
ENV LOG_LEVEL=INFO
# Sensitive values injected at runtime:
# docker run -e DB_PASSWORD=$SECRET ...
```

> **Code walkthrough:** The BAD pattern bakes credentials into every
> image layer permanently. Anyone with `docker pull` access can run
> `docker history myimage` and see the ENV values. The GOOD pattern
> keeps only non-sensitive defaults in the image. Sensitive values are
> passed at runtime via -e flags or Kubernetes Secrets. The docker history
> command will not show runtime-injected values.

**Example 2: Kubernetes ConfigMap and Secret injection**

```yaml
# ConfigMap for non-sensitive configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  SPRING_DATASOURCE_URL: >
    jdbc:postgresql://postgres:5432/appdb
  LOG_LEVEL: INFO
  SERVER_PORT: "8080"
---
# Secret for sensitive configuration
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
type: Opaque
# Values are base64-encoded (not encrypted!)
data:
  DB_PASSWORD: c2VjcmV0MTIz
  API_KEY: YWJjMTIz
---
# Deployment referencing config
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - name: myapp
          image: myapp:v1.0.0
          envFrom:
            - configMapRef:
                name: myapp-config
            - secretRef:
                name: myapp-secrets
          # OR: mount secret as file
          volumeMounts:
            - mountPath: /etc/secrets
              name: app-secrets
              readOnly: true
      volumes:
        - name: app-secrets
          secret:
            secretName: myapp-secrets
```

> **Code walkthrough:** envFrom injects all ConfigMap and Secret keys
> as environment variables. Spring Boot automatically maps environment
> variable names to property names (SPRING_DATASOURCE_URL maps to
> spring.datasource.url with relaxed binding). The Secret volume mount
> alternative writes each secret key as a file in /etc/secrets - the
> application reads the file contents. File-based secrets are not visible
> in `kubectl describe pod`, reducing exposure.

**Example 3: Spring Boot profile-based configuration**

```yaml
# docker-compose.yml - local development
services:
  app:
    image: myapp:latest
    environment:
      SPRING_PROFILES_ACTIVE: local
      SPRING_DATASOURCE_URL: >
        jdbc:postgresql://postgres:5432/appdb
      SPRING_DATASOURCE_PASSWORD: localpass
      # Local: override with local service names

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: localpass
```

```
# Kubernetes production: same image, different config
# SPRING_PROFILES_ACTIVE=prod injected from ConfigMap
# DB password injected from sealed Secret
# Same image binary behaves differently per profile
```

> **Code walkthrough:** The same Docker image runs locally with
> SPRING_PROFILES_ACTIVE=local (pointing to the local compose Postgres)
> and in production with SPRING_PROFILES_ACTIVE=prod (pointing to RDS).
> The image contains no environment-specific URLs or credentials. Spring Boot's
> profile resolution means application-local.properties or application-prod.properties
> are loaded based on the profile, and environment variables override those.

---

### ⚖️ Comparison

| Method | Security | Visibility | Rotation | Use When |
|---|---|---|---|---|
| **ENV in Dockerfile** | Low | In image history | Requires rebuild | Non-sensitive defaults only |
| docker run -e | Low | In process env | Per container | Development, non-sensitive |
| Kubernetes ConfigMap | Low | kubectl describe | ConfigMap update | Non-sensitive cluster config |
| Kubernetes Secret | Medium | Base64-encoded | Secret update | Passwords, API keys |
| Vault + Agent Sidecar | High | Never in process env | Automatic rotation | Crypto keys, HSM-protected |
| AWS Secrets Manager | High | IAM-gated | Automatic rotation | Production secrets |

**The deciding factor:**
ConfigMap for non-sensitive config, Kubernetes Secret for passwords and
API keys in development and low-risk prod. For regulated workloads and
cryptographic keys, use an external secrets manager with automatic rotation.

---

### 🔥 Field Q&A

#### Production Failures

Q: Developer accidentally committed a docker-compose.yml with database
credentials to the public GitHub repository.

A: This is a credential exposure incident. Immediate steps: rotate the
credential (change the database password NOW - assume it is compromised),
revoke any API keys. For GitHub: use GitHub's Secret Scanning to detect
more leaks; remove the commit history if possible (git rebase or BFG
Repo Cleaner). Prevention: use .env files for local secrets (not committed),
add .env to .gitignore, use pre-commit hooks that detect secret patterns
(truffleHog, detect-secrets). In the compose file, reference secrets
as ${VARIABLE} from .env files, not as literal values.

Q: Production service cannot read a Kubernetes Secret that was just updated.
The pod is still using the old credential.

A: Environment variables are copied at pod creation time. Updating a
Kubernetes Secret does not automatically update running pods that use
envFrom or env valueFrom. The pod must be restarted to pick up new Secret
values. Fix: use `kubectl rollout restart deployment myapp`. For zero-
downtime rotation, the better pattern is volume-mounted secrets: Kubernetes
updates the mounted file without restarting the pod (within a minute).
Application must re-read the file periodically or watch it with inotify.
Spring Cloud Kubernetes Config Watcher provides this automatically.

Q: Application is logging the database password in startup logs
("Connecting to: jdbc:postgresql://user:SECRET@host...").

A: Never include credentials in JDBC URLs. Use separate datasource
properties: spring.datasource.url (no credentials) + spring.datasource.username
+ spring.datasource.password. JDBC URL with embedded credentials
appears in logs, error messages, and thread dumps. The separate password
property is handled by the JDBC driver and not logged. Also review the
application for any log.debug(config.toString()) patterns that might
serialize the full config including sensitive fields.

#### Candidate Mistakes

Q: Candidate puts database password in Dockerfile ENV instruction.

**What NOT to say:** "It is easier to configure everything in the Dockerfile."

**Say instead:** "ENV instructions in Dockerfiles are baked into the image
layer permanently. Anyone who can pull the image can run docker history
to see the values. Sensitive values like passwords must never be in
Dockerfile ENV. They should be injected at runtime via Kubernetes Secrets
or an external secrets manager."

Q: Candidate treats Kubernetes Secrets as "secure."

**What NOT to say:** "Kubernetes Secrets are encrypted."

**Say instead:** "Kubernetes Secrets are base64-encoded, not encrypted,
by default. Anyone with kubectl get secret permission can decode them.
Kubernetes 1.7+ supports encryption at rest via the encryption provider,
but it must be explicitly enabled. For truly sensitive credentials, use
sealed-secrets for at-rest encryption in Git, or use an external
secrets manager like Vault or AWS Secrets Manager."

Q: Candidate is unaware of the restart-required behavior for env-var secrets.

**What NOT to say:** "Update the Secret and the app will pick it up automatically."

**Say instead:** "Environment variables are set at pod creation time and do not
update automatically when the Secret changes. To pick up a new Secret value,
you must restart the pod. If zero-downtime rotation is required, use volume-
mounted secrets instead - Kubernetes syncs the volume file without restarting
the pod. The application must be designed to re-read the file after updates."

Q: Candidate rebuilds the image with new database credentials for production.

**What NOT to say:** "We rebuild the image for each environment with the right config."

**Say instead:** "Baking environment-specific credentials into an image defeats
the immutable artifact principle. The image tested in staging must be the exact
same binary deployed to production. Configuration is injected at deploy time
via environment variables or Kubernetes Secrets, not at build time."

#### Questions to Ask the Interviewer

Q: "How do you manage secrets rotation for production services without
downtime?"

*Why:* Tests understanding of secret lifecycle management.

*If asked back:* "We use AWS Secrets Manager with Vault agent sidecar in
Kubernetes. The sidecar writes the secret to a volume-mounted file and
refreshes it before expiry. The application is designed to re-read the
file on each connection attempt, so rotation is transparent."

Q: "Do you have any credentials in your Git repository - even in old commits?"

*Why:* Tests security hygiene and awareness of credential scanning.

*If asked back:* "We run gitleaks and truffleHog as pre-commit hooks and
in CI. We also use GitHub Advanced Security secret scanning on all repos.
Any detected credential is rotated immediately regardless of whether it
was committed recently or years ago."

Q: "What happens when a Kubernetes Secret is updated while the application
is running?"

*Why:* Tests understanding of Secret update propagation.

*If asked back:* "Environment-variable-injected secrets require a pod restart.
Volume-mounted secrets are refreshed by Kubernetes within a minute without
restart. For high-availability rotation, we use volume mounts and design
the application to re-read the secret file rather than caching the value
at startup."

Q: "How do you handle different configurations for dozens of microservices
across multiple environments?"

*Why:* Tests configuration management at scale.

*If asked back:* "We use Spring Cloud Config Server for centralized config,
backed by a Git repository. Each service has a config file per environment.
Sensitive values are stored in Kubernetes Secrets or Vault, not in the config
repository. The Config Server handles refresh notifications, so services
can hot-reload config without restarts."

#### Live Coding Context

Coding question template: "Set up configuration management for a Spring Boot
service that needs a database password in Kubernetes without putting it in
the image or Git repository."

What the interviewer watches:
- Whether you use Kubernetes Secret (not ConfigMap) for the password
- Whether you reference the Secret with secretRef or valueFrom (not literal)
- Whether you mention that Kubernetes Secrets are base64-encoded, not encrypted
- Whether you mention an external secrets manager for higher security

Most common implementation mistake:
Putting the database password as a literal value in the Kubernetes Deployment
YAML, which is checked into Git and violates secret management principles.

*Why this signals:* The distinction between ConfigMap and Secret, and the
awareness that Secrets are base64-encoded not encrypted, shows Kubernetes
security depth beyond basic usage.
