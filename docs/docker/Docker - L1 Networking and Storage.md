---
layout: default
title: "Docker - L1 Networking and Storage"
parent: "Docker"
nav_order: 3
permalink: /docker/l1-networking-and-storage/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Docker - L1 Networking and Storage](#docker---l1-networking-and-storage) | medium |

---

# Docker - L1 Networking and Storage

## Docker Networking Basics

---

### 🎯 Model Answer

**30 seconds:**
> Docker networking: containers communicate via virtual networks.
> Default driver: bridge. Types: bridge (isolated, containers
> communicate by name on user-defined networks), host (share host
> network namespace, no isolation), none (no networking), overlay
> (multi-host, for Docker Swarm/distributed). For inter-container
> communication: use user-defined bridge networks with DNS-based
> service discovery (container name = hostname).

**3 minutes (Senior):**
> Network drivers and when to use each: (1) **Bridge (default)**: a
> software virtual switch (Linux bridge). Containers on the same
> user-defined bridge network can reach each other by container name
> (Docker DNS). Containers on the default bridge network: only by IP.
> Always use user-defined bridges in production for DNS discovery.
> (2) **Host**: container shares the host's network namespace. No
> port mapping needed. Use for: network-intensive workloads (high-
> frequency trading, network proxies) where the NAT overhead of bridge
> networking is unacceptable. Drawback: no network isolation. (3)
> **None**: no network interface except loopback. Use for: batch jobs
> with no network requirement, security-sensitive workloads. (4)
> **Overlay**: multi-host networking via VXLAN tunnels. Required for
> Docker Swarm services. Not commonly used outside Swarm (Kubernetes
> uses its own CNI plugins). Port publishing: `-p hostPort:containerPort`
> creates an iptables rule mapping host port to container port via NAT.
> Each published port: an iptables rule in the `DOCKER` chain.

**Blank Mind Recovery:**

**(1) Restate:** "Bridge: default, containers talk by name on user-
defined networks. Host: no isolation, best performance. None: no
network. Overlay: multi-host Swarm. Port mapping: -p host:container.
Always use user-defined bridge networks (not default bridge) for DNS."

**(2) First principles:** "Containers: isolated network namespaces.
Communication: virtual network between namespaces. DNS: Docker daemon
manages resolution within a user-defined network. Port mapping:
NAT rules (iptables) to translate host port to container port."

**(3) Bridge:** "Docker networking is like office floor plans. Bridge
network = separate office rooms connected by a shared corridor (the
bridge). Host network = everyone sits in the same open-plan office
(shared namespace). None = isolated booth (no connection). DNS =
the company directory (call by name, not extension number)."

---

### 📘 Concept Explanation

**Network drivers, port mapping, DNS resolution:**

{% raw %}
```plaintext
NETWORK TYPES:

  # List networks:
  docker network ls
  # Default networks: bridge, host, none.
  
  # Create a user-defined bridge network:
  docker network create myapp-net
  
  # Connect containers to network:
  docker run -d --name db --network myapp-net postgres:15
  docker run -d --name web --network myapp-net \
    -e DATABASE_URL=postgres://db:5432/app myapp
  # "web" can reach "db" by hostname "db" (Docker DNS).
  # On default bridge: containers can only reach each other by IP.
  # On user-defined bridge: container name = DNS hostname.

PORT MAPPING:

  # Map host port 8080 to container port 3000:
  docker run -p 8080:3000 myapp
  # Access: curl http://localhost:8080
  
  # Bind to specific host interface:
  docker run -p 127.0.0.1:8080:3000 myapp  # localhost only
  docker run -p 0.0.0.0:8080:3000 myapp    # all interfaces (default)
  
  # Random host port:
  docker run -p 3000 myapp  # Docker assigns a random host port
  docker port myapp          # show mapped ports
  
  # Underlying mechanism:
  # Docker adds iptables rules in DOCKER chain for each published port.
  # Incoming packets on host:8080 -> DNAT to containerIP:3000.

NETWORK INSPECTION:

  docker network inspect myapp-net
  # Shows: containers attached, subnet, gateway, options.
  
  # Get container's IP on a network:
  docker inspect web --format '{{.NetworkSettings.Networks.myapp-net.IPAddress}...
  
  # Test connectivity between containers:
  docker exec web ping db
  docker exec web curl http://db:8080/health

HOST NETWORKING:

  docker run --network host myapp
  # Container: uses host's eth0, lo, etc.
  # Listening on port 3000: exposed directly on host port 3000.
  # No port mapping needed (or allowed - ignored).
  # Use: lowest possible network latency, direct socket access.
  # Security: container can access all host network services.

NETWORK ISOLATION:

  # Containers on DIFFERENT networks cannot communicate (by default):
  docker network create frontend-net
  docker network create backend-net
  
  docker run --network frontend-net nginx   # public web
  docker run --network backend-net postgres # private DB
  
  # nginx cannot reach postgres (different networks). 
  # App server: connect to both networks:
  docker run --network frontend-net --network backend-net myapp
  # Or: connect a running container to additional network:
  docker network connect backend-net myapp
```
{% endraw %}

> **Code walkthrough:** This Or: connect a running container to additional network: example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** A Docker Compose network configuration showsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> how frontend, backend, and database are isolated with only
> necessary cross-network connections.


```yaml
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

```yaml
# BAD: all containers on default bridge, no DNS, no isolation:
version: "3"
services:
  web:
    image: nginx
  app:
    image: myapp
  db:
    image: postgres
# All on default bridge. DNS: not available (container name not resolvable).
# No isolation: web can directly reach db.

# GOOD: user-defined networks with isolation:
version: "3.9"
services:
  web:
    image: nginx:alpine
    networks:
      - frontend
    ports:
      - "80:80"
  
  app:
    image: myapp:1.2.3
    networks:
      - frontend   # reachable by web
      - backend    # can reach db
    environment:
      - DATABASE_URL=postgresql://db:5432/myapp
  
  db:
    image: postgres:15-alpine
    networks:
      - backend    # ONLY reachable from backend network
    volumes:
      - pgdata:/var/lib/postgresql/data

networks:
  frontend: {}  # web + app
  backend: {}   # app + db

volumes:
  pgdata: {}
```

> **Code walkthrough:** The `web` service is only on `frontend`:ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> it cannot directly connect to `db`. The `app` service bridges both
> networks: it serves `web` requests and connects to `db`. The `db`
> service is only on `backend`: completely isolated from web traffic.
> Docker Compose creates user-defined networks automatically. Services
> can use the service name as hostname: `app` resolves to the app
> container's IP, `db` resolves to the db container's IP.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Docker creates a virtual network for containers. Default: bridge
> network. Use user-defined networks so containers can reach each
> other by name. Port mapping (`-p 8080:3000`): makes a container
> port accessible on the host. Containers on the same network can
> communicate internally without port mapping.

---

**Senior / Staff (5+ years):**
> Default bridge network: anti-pattern in production. Docker DNS is
> NOT available on the default bridge. Containers on default bridge:
> must use IP addresses for communication (IPs change on restart).
> All user-created networks: bridge type by default, with Docker DNS.
> Always create named networks explicitly. Network isolation: defense
> in depth. DB containers: only on backend network. Not reachable
> from internet-facing containers. Port binding to `0.0.0.0`: makes
> the port accessible on all network interfaces (including external).
> Bind to `127.0.0.1` for development (localhost-only). In production:
> the load balancer or ingress should be the only publicly exposed port.

---

### ⚠️ Common Misconceptions

**Misconception: "Containers on the same host can always communicate."**
Containers on different Docker networks cannot communicate by default.
Network segmentation is a security feature. Even on the same host:
`web` container on `frontend` network and `db` container on `backend`
network cannot reach each other unless a container is explicitly
connected to both networks. `docker network connect` or a shared
network in Docker Compose: required. This is by design. Implicit
cross-network communication would defeat the isolation purpose. If
you find yourself adding `--network host` "to make things work": you
are bypassing all network isolation. Investigate which network
connection is actually needed and create a specific user-defined
network instead.

---

### ⚖️ Comparison Table

| Network Driver | Isolation | Multi-host | Use Case |
|---|---|---|---|
| bridge (default) | No DNS (use user-defined) | No | Dev (avoid default bridge) |
| bridge (user-defined) | DNS + isolation | No | Standard production |
| host | None | No | High-performance, network proxies |
| none | Complete | No | Batch jobs, security-sensitive |
| overlay | Yes | Yes (Swarm) | Docker Swarm services |
| macvlan | Yes | No | Legacy LAN, custom MAC addresses |

---

### 🏛️ System Design

*(Omit: Docker networking basics is operational, not architectural.)*

---

### 📊 Diagram

*(Omit: network topology is better shown in Docker Compose config above.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Container cannot reach another container by hostname.**

{% raw %}
```plaintext
Symptom: app container: "getaddrinfo ENOTFOUND db"
  Or: "Connection refused: db:5432"
  
Root cause:
  - Using default bridge network (no DNS) instead of user-defined.
  - Containers on different networks.
  - Container name mismatch (typo in hostname vs --name).

Diagnosis:
  # Check which network the containers are on:
  docker inspect web --format '{{json .NetworkSettings.Networks}}' | python3...
  docker inspect db --format '{{json .NetworkSettings.Networks}}' | python3 -m...
  # If both are on "bridge" (default): switch to user-defined network.
  # If on different user-defined networks: connect or use shared network.
  
  # Test DNS resolution from the container:
  docker exec app nslookup db
  # Should return db's container IP. If "can't resolve": DNS not available.
  
  # Test connectivity:
  docker exec app ping db
  docker exec app nc -zv db 5432  # test port connectivity

Fix:
  Create a user-defined network and connect both containers:
  docker network create myapp-net
  docker network connect myapp-net app
  docker network connect myapp-net db
  # Or: recreate containers with --network myapp-net.
  # In Compose: define a named network and assign services to it.
```
{% endraw %}

> **Code walkthrough:** This In Compose: define a named network and assign services to it. example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Bridge vs host networking | 2 minutes |
| DNS on user-defined networks | 1 minute |
| Port mapping mechanics | 1 minute |
| Network isolation strategy | 2 minutes |
| "Container can't reach container" diagnosis | 2 minutes |
| Default bridge limitation | 1 minute |
| Network security hardening | 1 minute |

---

**Q1 (fundamentals): Why should you use user-defined bridge networks instead of the default bridge?**

A: The default bridge network (created automatically by Docker) does
not support automatic DNS resolution. Containers on the default bridge
can only reach each other by IP address. IP addresses change every
time a container is recreated. This makes the default bridge
impractical for multi-container applications. User-defined bridge
networks: Docker automatically configures DNS so each container's
name resolves to its IP. When a container restarts with a new IP:
DNS updates automatically. Application configuration (`DATABASE_URL=
postgres://db:5432/app`): uses hostnames, not IPs. The application
works without any changes when the DB container restarts.

*What separates good from great:* User-defined networks also provide
better isolation. All containers on the default bridge can potentially
communicate with each other (unless `icc=false` is configured on the
daemon). User-defined networks: containers can only communicate with
other containers on the SAME user-defined network. A web container
and a monitoring container: both on different user-defined networks:
no cross-communication without explicit network connection. This is
defense in depth at the network layer. In Docker Compose: all services
get a default user-defined network (the compose project network) but
you can define additional networks for explicit isolation.

---

---

## Docker Volumes and Persistent Storage

---

### 🎯 Model Answer

**30 seconds:**
> Containers are ephemeral: when removed, their writable layer is
> deleted. Persistent storage: Docker volumes. Three types: named
> volumes (Docker-managed, `docker volume create`), bind mounts
> (host directory mounted into container), tmpfs mounts (in-memory,
> no persistence). Named volumes: preferred for production data.
> Bind mounts: for development (live code reload) and config files.

**3 minutes (Senior):**
> Storage options and trade-offs: (1) **Named volumes**: Docker manages
> the storage location (`/var/lib/docker/volumes/`). Portable:
> volumes can be backed up, migrated, and managed independent of
> the host path. Volume drivers: plug in cloud storage (AWS EFS, Azure
> Files) or distributed storage (NFS, Ceph) as volume backends. (2)
> **Bind mounts**: map a specific host path to a container path. Fast
> for development (code changes reflected immediately). Risk: the
> container has access to whatever is at the host path. A bind mount
> of `/etc` or `/root`: gives the container (potentially an attacker)
> access to sensitive host data. Production: use named volumes for
> data. Bind mounts only for config files with a specific known path.
> (3) **tmpfs**: in-memory, not persisted to disk. Use for: temporary
> files (session data, caches) that should not survive restart AND
> should not be written to disk (security: sensitive in-memory data).
> Combined with `--read-only`: the only writable path is tmpfs.

**Blank Mind Recovery:**

**(1) Restate:** "Named volumes: Docker-managed, persistent, portable.
Bind mounts: host path -> container path, fast dev, risky for prod.
tmpfs: in-memory, no persistence, secure. Backup: docker volume backup
via tar or volume driver. Persistence: required for databases and
stateful services."

**(2) First principles:** "Container writable layer = deleted on rm.
External storage = persists. Three categories: Docker-managed (named
volume), host-managed (bind mount), memory-managed (tmpfs). Choose
based on: persistence need, portability, security."

**(3) Bridge:** "Storage types are like writing surfaces. Named
volume: a locked filing cabinet (Docker manages the key). Bind mount:
a desk drawer (you choose which drawer = host path). tmpfs: a
whiteboard (erased on restart, never saved to disk)."

---

### 📘 Concept Explanation

**Named volumes, bind mounts, tmpfs, backup:**
```
NAMED VOLUMES:

  # Create a named volume:
  docker volume create pgdata
  
  # Use in run command:
  docker run -d \
    --name postgres \
    -v pgdata:/var/lib/postgresql/data \
    postgres:15
  
  # Volume location on host:
  /var/lib/docker/volumes/pgdata/_data/
  
  # Inspect volume:
  docker volume inspect pgdata
  
  # Volumes persist when container is removed:
  docker rm postgres          # container gone
  docker volume ls            # pgdata still exists
  docker run -d -v pgdata:/var/lib/postgresql/data postgres:15
  # Data restored! New container, same data.

BIND MOUNTS:

  # Mount current directory to /app (development hot-reload):
  docker run -v $(pwd):/app node:18 npm start
  # Changes to source files on host: immediately visible in container.
  
  # Mount specific config file (read-only):
  docker run -v /etc/myapp/config.yaml:/app/config.yaml:ro myapp
  # :ro = read-only inside container.
  
  # Security risk: privileged bind mounts:
  docker run -v /:/host myimage   # BAD: entire host filesystem mounted
  docker run -v /var/run/docker.sock:/var/run/docker.sock myimage
  # WARNING: docker.sock = full Docker API access = root-equivalent.
  # Only for Docker-in-Docker, CI/CD agents where explicitly needed.
  # Never in production application containers.

TMPFS MOUNTS:

  # In-memory mount, not persisted:
  docker run --tmpfs /tmp myapp
  docker run --tmpfs /run:rw,noexec,nosuid,size=256m myapp
  # Options: rw (read-write), noexec (no executables), nosuid, size limit.
  
  # Combine with --read-only for maximum security:
  docker run --read-only --tmpfs /tmp --tmpfs /run myapp
  # Root filesystem: read-only. /tmp and /run: writable in memory.
  # Any write to other paths: permission denied.

VOLUME OPERATIONS:

  # List all volumes:
  docker volume ls
  
  # Remove unused volumes:
  docker volume prune
  
  # Backup a named volume:
  docker run --rm \
    -v pgdata:/data \
    -v $(pwd)/backup:/backup \
    alpine tar czf /backup/pgdata.tar.gz -C /data .
  # Creates pgdata.tar.gz in current directory.
  
  # Restore from backup:
  docker run --rm \
    -v pgdata:/data \
    -v $(pwd)/backup:/backup \
    alpine tar xzf /backup/pgdata.tar.gz -C /data

DOCKER COMPOSE VOLUMES:

  services:
    db:
      image: postgres:15
      volumes:
        - pgdata:/var/lib/postgresql/data      # named volume
        - ./init-scripts:/docker-entrypoint-initdb.d:ro  # bind mount
    
    app:
      image: myapp:1.2.3
      volumes:
        - app-logs:/app/logs                   # named volume for logs
        - type: tmpfs                          # in-memory cache
          target: /app/cache
  
  volumes:
    pgdata: {}     # top-level declaration (Docker creates if absent)
    app-logs: {}
```

> **Code walkthrough:** BAD pattern: This Restore from backup: example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **WHAT BREAKS: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** A production database volume setup withice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> backup demonstrates named volumes for persistence and bind mounts
> for initialization scripts.


```bash
# BAD: unsafe shell scripting pattern
```

```bash
# BAD: data in container writable layer - lost on container removal:
docker run -d --name db postgres:15
docker rm db  # All data gone.

# GOOD: named volume for persistence + bind mount for init scripts:
docker volume create postgres-data

docker run -d \
  --name db \
  -v postgres-data:/var/lib/postgresql/data \
  -v "$(pwd)/sql:/docker-entrypoint-initdb.d:ro" \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/pg_password \
  --tmpfs /run/secrets \
  postgres:15

# Data in postgres-data volume:
# - Survives container removal
# - Can be backed up independently
# - Can be migrated to a new container

# Backup (online, consistent with pg_dump is better for live DB):
docker exec db pg_dump -U postgres mydb > backup.sql

# Or: volume-level backup (offline):
docker stop db
docker run --rm \
  -v postgres-data:/data \
  -v "$(pwd):/backup" \
  alpine tar czf /backup/pg-backup-$(date +%Y%m%d).tar.gz /data
docker start db
```

> **Code walkthrough:** `postgres-data` is a named volume managedice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> by Docker. The `sql/` directory bind mount (`:ro`) injects
> initialization scripts that Postgres runs on first start. The
> `--tmpfs /run/secrets` (combined with `POSTGRES_PASSWORD_FILE`)
> is a pattern for injecting secrets into the container's memory
> without leaving them on disk. The volume backup: stops the DB
> briefly (for consistency), creates a compressed tar of the volume
> data, then restarts. For production: use `pg_dump` for logical
> backups or a volume snapshot (cloud provider snapshot of the EBS
> volume).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Docker containers are ephemeral: data is lost when the container
> is removed. Volumes solve this: named volumes (`-v myvolume:/data`)
> persist data. Bind mounts (`-v /host/path:/container/path`): mount
> a host directory. Use named volumes for databases and stateful data.
> Use bind mounts for development (live code changes).

---

**Senior / Staff (5+ years):**
> The docker.sock bind mount is the most dangerous bind mount in
> common use. Mounting `/var/run/docker.sock` into a container:
> gives that container full control of the Docker daemon (run any
> container, access any volume, modify any container). Equivalent
> to giving the container root on the host. Common in CI/CD agents
> (Jenkins, GitLab Runner): often necessary. But: these agents must
> be isolated (dedicated nodes, not production nodes) and must never
> run untrusted code. Container breakout via docker.sock: one of
> the most straightforward container escape techniques.

---

### ⚠️ Common Misconceptions

**Misconception: "bind mounts and named volumes are interchangeable."**
They serve different purposes. Bind mounts: dependent on the host
filesystem path. A bind mount of `./data:/app/data` requires the
`./data` directory to exist on the host. If the host changes (new
machine, different path): the bind mount breaks. Named volumes:
Docker abstracts the storage location. The volume is identified by
name, not host path. Named volumes work on any Docker host without
path dependencies. Named volumes also support volume drivers (NFS,
EFS, S3-compatible storage) that bind mounts cannot. For production
databases: ALWAYS named volumes. Bind mounts for databases: work
locally but break in deployment (different host paths in CI, staging,
production). Using named volumes: the same `docker run` command
works on any host.

---

### ⚖️ Comparison Table

| Storage Type | Persistence | Host Dependency | Security | Use Case |
|---|---|---|---|---|
| Named volume | Yes | No (Docker-managed) | Good | DB data, production |
| Bind mount | Yes | Yes (host path) | Risk if sensitive path | Dev, config files |
| tmpfs | No (memory only) | No | Excellent | Temp files, secrets |
| Container layer | No (deleted on rm) | No | N/A | Non-persistent scratch |

---

### 🏛️ System Design

*(Omit: volume fundamentals is operational, not architectural.)*

---

### 📊 Diagram

*(Omit: storage types are most clearly shown via the concept explanation code blocks.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Volume data missing after container restart or migration.**

{% raw %}
```
Symptom: Database container starts but data is gone.
  Application: behaving as if fresh installation.

Root cause options:
  1. Container was run without -v (no volume mount). Data in writable layer.
     Container removed (docker rm): writable layer deleted.
  2. Named volume specified but volume was also pruned.
  3. Bind mount path doesn't exist on new host (migration scenario).
  4. Volume mounted at wrong path inside container.

Diagnosis:
  # Check if volume exists:
  docker volume ls | grep pgdata
  # If missing: data is gone (or never existed as a volume).
  
  # Check if container had a volume at runtime:
  docker inspect {stopped-container} | grep -A20 '"Mounts"'
  # If Mounts is empty []: no volume was mounted. Data was in writable layer.
  
  # Check volume mount path:
  docker inspect {container} --format '{{range .Mounts}}{{.Source}}...
  # Verify the Destination matches where the database expects data.
  # postgres:15 data path: /var/lib/postgresql/data
  # mysql:8 data path: /var/lib/mysql
  # If mounted to wrong path: DB writes to wrong location.

Prevention:
  Always specify -v in docker run for stateful containers.
  Use docker-compose.yml to document volumes declaratively.
  Never run docker volume prune without verifying no active services need those volumes.
  Backup named volumes before any major operations.
  Test the restore procedure: take a backup, create a new container, restore, verify.
```
{% endraw %}

> **Code walkthrough:** This If mounted to wrong path: DB writes to wrong location. example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Named volumes vs bind mounts | 2 minutes |
| Volume persistence on container removal | 1 minute |
| docker.sock security risk | 2 minutes |
| tmpfs use cases | 1 minute |
| Volume backup strategy | 2 minutes |
| "Data missing after restart" diagnosis | 1 minute |
| Volume drivers | 1 minute |

---

**Q1 (security): What are the security risks of bind mounts and how do you mitigate them?**

A: Three bind mount security risks. (1) Sensitive host path exposure:
mounting `/etc`, `/root`, or `/var/run/docker.sock` gives the
container (and any process running inside it) read and possibly write
access to those paths. A container compromise becomes a host compromise.
Mitigation: mount only the specific file or directory needed, always
with `:ro` (read-only) unless writes are required. (2) Container
escape via docker.sock: mounting the Docker daemon socket gives the
container full Docker API access. It can create new privileged
containers, bind-mount the entire host filesystem, and escape the
container. Mitigation: never mount docker.sock in production
application containers. For CI/CD that requires Docker access: use
Kaniko or Buildah (rootless, no Docker daemon required). (3) Path
traversal in bind mounts: if a container can write to a bind-mounted
path that is also used by the host, it could modify host files.
Example: bind-mounting the host's nginx config directory. A
compromised container: writes a malicious config. Host nginx:
picks it up on next reload. Mitigation: use named volumes instead
of bind mounts for application data. Bind mounts only for explicitly
needed config injection.

*What separates good from great:* The principle of least privilege
applies to volume mounts. Never use absolute host paths like `/app`
if you can use a named volume. If you must use a bind mount: always
specify `:ro` unless the container explicitly needs to write.
Regularly audit running containers for bind mounts to sensitive paths:
`docker inspect $(docker ps -q) | grep -A5 '"Mounts"' | grep Source`.
Any bind mount to system directories: investigate and remove.

---

---

## Docker Registries and Image Distribution

---

### 🎯 Model Answer

**30 seconds:**
> A Docker registry: a server for storing and distributing Docker
> images. Docker Hub: default public registry. Private registries:
> AWS ECR, Google Artifact Registry, Azure Container Registry, or
> self-hosted (Harbor, Nexus, Docker Registry). Pull: `docker pull
> image:tag`. Push: `docker push`. Registry authentication: `docker
> login`. Images are identified by: `registry/namespace/name:tag`.

**3 minutes (Senior):**
> Registry architecture: images are stored as manifests (JSON
> metadata) and blobs (layer content). Pull: client downloads the
> manifest, checks which layers are cached locally, downloads only
> missing layers. Push: same in reverse. Docker Hub free tier:
> rate limits (100 pulls/6h for anonymous, 200 for authenticated).
> In production: use a private registry to avoid rate limits and
> keep images internal. Pull-through cache: configure a local registry
> to cache Docker Hub pulls (reduces rate limit impact, improves
> build speed). Image scanning: registries like ECR, Harbor, and
> Artifact Registry offer built-in vulnerability scanning (Trivy,
> Clair) on push. Enforce: block deployment of images with CRITICAL
> vulnerabilities. Signing: Docker Content Trust (DCT) or Cosign
> (Sigstore) to sign and verify images. Ensures: only signed images
> from trusted sources can be pulled and deployed.

**Blank Mind Recovery:**

**(1) Restate:** "Registry: image storage server. Public: Docker Hub.
Private: ECR, GCR, ACR, Harbor. Image ID: registry/namespace/name:tag.
Operations: pull, push, login. Production concerns: rate limits,
private registry, vulnerability scanning, image signing."

**(2) First principles:** "An image is a collection of layer blobs +
a manifest. The registry stores and serves these. Docker Hub: the
public registry. Private: your own controlled registry. Authentication:
registry-specific. Scanning: check layers for known CVEs."

**(3) Bridge:** "A Docker registry is like npm for containers. Docker
Hub = npmjs.com (public packages). Private registry = private npm
registry (internal packages). `docker pull` = `npm install`. Image
tag = package version. Rate limiting = npm download limits for
anonymous users."

---

### 📘 Concept Explanation

**Registry types, authentication, pull-through cache, scanning:**
```
IMAGE NAMING CONVENTION:

  Full format: registry/namespace/repository:tag@digest
  
  Examples:
    ubuntu:22.04                    # Docker Hub official image
    library/ubuntu:22.04            # Same (library = Docker Hub official namespace)
    docker.io/library/ubuntu:22.04  # Fully qualified
    mycompany.azurecr.io/myapp:v1.2.3  # Azure Container Registry
    123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.2.3  # AWS ECR
    gcr.io/myproject/myapp:v1.2.3   # Google Container Registry
    ghcr.io/username/myapp:v1.2.3   # GitHub Container Registry

REGISTRY AUTHENTICATION:

  # Docker Hub:
  docker login
  docker login -u username -p token docker.io  # with access token
  
  # AWS ECR (token-based, expires every 12 hours):
  aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    123456789.dkr.ecr.us-east-1.amazonaws.com
  # In CI/CD: use IAM role for ECR pull (no credentials needed for ECR in same account).
  
  # GCP Artifact Registry:
  gcloud auth configure-docker us-central1-docker.pkg.dev
  
  # Kubernetes (ImagePullSecrets):
  kubectl create secret docker-registry regcred \
    --docker-server=myregistry.example.com \
    --docker-username=myuser \
    --docker-password=mypass
  # Reference in pod spec:
  # imagePullSecrets:
  #   - name: regcred

DOCKER HUB RATE LIMITING:

  # Anonymous: 100 pulls per 6 hours (per IP).
  # Authenticated (free): 200 pulls per 6 hours.
  # Pro/Team: unlimited.
  
  # Check remaining rate limit:
  TOKEN=$(curl -s \
    "https://auth.docker.io/token?service=registry.docker.io\
&scope=repository:ratelimitpreview/test:pull" | jq -r .token)
  curl -s --head -H "Authorization: Bearer $TOKEN" \
    https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest \
    | grep -i ratelimit
  # Output: RateLimit-Remaining: 75;w=21600
  
  # Solution: authenticate all pulls. Or: use a pull-through cache.

PULL-THROUGH CACHE:

  # Configure Docker daemon to proxy Docker Hub through a local registry:
  # /etc/docker/daemon.json:
  {
    "registry-mirrors": ["https://myregistry.example.com"]
  }
  
  # All docker pulls: check local cache first. On miss: pull from Docker Hub.
  # Rate limit: applies to the cache (one IP), not each developer.
  # Build speed: images pulled from local cache (LAN speed vs internet).
  
  # Harbor: enterprise registry with pull-through cache built in.
  # Configure a Docker Hub proxy project. All team pulls: through Harbor.

IMAGE SCANNING:

  # Trivy (open source, widely used):
  trivy image myapp:1.2.3
  # Output: CVE list, severity (CRITICAL/HIGH/MEDIUM/LOW), fixed version.
  
  # AWS ECR enhanced scanning:
  # Automatically scans on push. Findings: in ECR console and Security Hub.
  
  # Block deployment of vulnerable images:
  # CI/CD: fail pipeline if trivy finds CRITICAL vulnerabilities.
  trivy image --exit-code 1 --severity CRITICAL myapp:1.2.3
  # Exit code 1: vulnerabilities found. CI: fails build.
  
  # Image signing (Cosign / Sigstore):
  # Sign after build:
  cosign sign --key cosign.key myapp:1.2.3
  # Verify before deployment:
  cosign verify --key cosign.pub myapp:1.2.3
  # Kubernetes: admission controller verifies signature before allowing pod creation.
```

> **Code walkthrough:** This Kubernetes: admission controller verifies signature before allowing pod creation. example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** A CI/CD pipeline snippet shows the full imageice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> lifecycle: build, scan, push to private registry, and verify.


```bash
# BAD: unsafe shell scripting pattern
```

{% raw %}
```bash
# BAD: push to Docker Hub with :latest, no scanning:
docker build -t mycompany/myapp:latest .
docker push mycompany/myapp:latest
# :latest is mutable. No security scanning. Public registry: everyone can pull.

# GOOD: build, scan, tag with digest, push to private registry:
IMAGE_NAME="123456789.dkr.ecr.us-east-1.amazonaws.com/myapp"
GIT_SHA=$(git rev-parse --short HEAD)
IMAGE_TAG="${IMAGE_NAME}:${GIT_SHA}"

# Build:
docker build --no-cache -t "${IMAGE_TAG}" .

# Scan: fail if CRITICAL vulnerabilities found:
trivy image --exit-code 1 --severity CRITICAL "${IMAGE_TAG}"
if [ $? -ne 0 ]; then
  echo "CRITICAL vulnerabilities found. Aborting push."
  exit 1
fi

# Authenticate to ECR:
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  "123456789.dkr.ecr.us-east-1.amazonaws.com"

# Push:
docker push "${IMAGE_TAG}"

# Get the immutable digest:
DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "${IMAGE_TAG}")
echo "Deployed image digest: ${DIGEST}"

# Update deployment manifest with digest (not tag):
sed -i "s|image:.*|image: ${DIGEST}|" k8s/deployment.yaml
git commit -am "ci: update image to ${GIT_SHA}"
```
{% endraw %}

> **Code walkthrough:** Git SHA as the image tag: unique per commit,ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> never overwritten. Trivy scan: fails the build on CRITICAL
> vulnerabilities before any push occurs. ECR authentication: short-
> lived token (12 hours), no long-lived credentials. The final step
> extracts the immutable digest from the pushed image and uses it
> in the Kubernetes manifest. This enables GitOps: the manifest
> change is auditable, reversible, and deterministic.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Docker Hub is the default public registry. To use a private registry:
> `docker login registry.example.com` first, then `docker pull/push`.
> Images are named `registry/namespace/image:tag`. Best practice:
> use a private registry in production (avoid Docker Hub rate limits,
> keep images internal).

---

**Senior / Staff (5+ years):**
> Registry selection affects security posture. ECR, GCR, and ACR:
> integrate with their cloud's IAM. ECR: no credentials needed when
> running in the same AWS account with an appropriate IAM role.
> This is zero-credential pull: no image pull secrets to rotate or
> leak. ECR enhanced scanning (powered by Amazon Inspector) scans
> every image push and continually re-scans as new CVEs are discovered.
> A fresh image with no vulnerabilities today may have CRITICAL
> vulnerabilities 3 months later without any code change (dependency
> CVE discovered). Continuous scanning: essential. Regular base image
> rebuilds: even without code changes, rebuild on a schedule to pick
> up patched base images.

---

### ⚠️ Common Misconceptions

**Misconception: "A private registry is always more secure than Docker Hub."**
A private registry prevents unauthorized external access but does
NOT automatically provide better security than Docker Hub if the
images themselves contain vulnerabilities. Security of a registry:
two separate concerns. (1) Access control: private registry = only
authorized users can pull. Better than public Docker Hub for
proprietary software. (2) Image content security: the images in
your private registry may contain vulnerable packages. Hosting
a Node.js image with a critical npm dependency CVE in a private
registry: the vulnerability is just as dangerous as it would be
on Docker Hub. Private registry: solves access control. Image scanning:
solves content security. BOTH are required. A common mistake: teams
move to a private registry, feel "secure," and skip image scanning.
The result: private registry full of unscanned, potentially vulnerable
images.

---

### ⚖️ Comparison Table

| Registry | Cost | Scanning | IAM Integration | Rate Limits |
|---|---|---|---|---|
| Docker Hub (free) | Free | Optional (paid) | No | 100-200/6h |
| Docker Hub (Pro) | $5/mo | Yes | No | Unlimited |
| AWS ECR | ~$0.10/GB | Yes (enhanced) | Yes (IAM) | No |
| GCP Artifact Registry | ~$0.10/GB | Yes (Artifact Analysis) | Yes (IAM) | No |
| Azure Container Registry | $5-50/mo | Yes (Microsoft Defender) | Yes (AAD) | No |
| Harbor (self-hosted) | Free (infra cost) | Yes (Trivy/Clair) | LDAP/OIDC | No |
| GitHub Container Registry | Free (public) | Optional | Yes (GitHub token) | No |

---

### 🏛️ System Design

*(Omit: registry is a component-level concern.)*

---

### 📊 Diagram

*(Omit: registry workflow is clearest in the code example above.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: `docker pull` failing with "429 Too Many Requests".**
```plaintext
Symptom: CI/CD pipeline fails with:
  "Error response from daemon: toomanyrequests: You have reached
  your pull rate limit. You may increase the limit by authenticating
  and upgrading: https://www.docker.com/increase-rate-limit"

Root cause: Docker Hub rate limiting. Multiple CI/CD jobs pulling
  from Docker Hub anonymously (or as the same authenticated user)
  from the same IP within 6 hours. 100 pulls/6h for anonymous.
  In a large CI/CD environment: easily exceeded.

Immediate fix:
  Authenticate all Docker Hub pulls in CI/CD:
  echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME"...
  # Increases limit to 200 pulls/6h per authenticated account.
  
  Or: pull the base image ONCE and cache in ECR/private registry:
  docker pull ubuntu:22.04
  docker tag ubuntu:22.04 123456789.dkr.ecr.us-east-1.amazonaws.com/cache/ubuntu:22.04
  docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/cache/ubuntu:22.04
  # Update Dockerfiles to use the ECR-hosted copy.

Long-term fix:
  Set up a pull-through cache registry (Harbor, AWS ECR pull-through cache, Nexus).
  ECR pull-through cache: built-in feature.
    aws ecr create-pull-through-cache-rule \
      --ecr-repository-prefix docker-hub \
      --upstream-registry-url registry-1.docker.io
  Update Dockerfiles:
    FROM 123456789.dkr.ecr.us-east-1.amazonaws.com/docker-hub/ubuntu:22.04
    # Pulls from ECR cache. On miss: ECR fetches from Docker Hub (using 1 IP).
```

> **Code walkthrough:** This Pulls from ECR cache. On miss: ECR fetches from Docker Hub (using 1 IP). example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Private vs public registry | 1 minute |
| Docker Hub rate limiting | 2 minutes |
| ECR vs Docker Hub | 1 minute |
| Image vulnerability scanning | 2 minutes |
| Image signing | 1 minute |
| Pull-through cache | 1 minute |
| Registry IAM integration | 1 minute |

---

**Q1 (production): How do you prevent vulnerable images from reaching production?**

A: Defense in depth at multiple pipeline stages. (1) Base image
selection: start with minimal base images (`distroless`, `alpine`,
`scratch`). Fewer packages = fewer potential CVEs. Don't use `latest`
tags for base images. Pin to a specific version. (2) Dependency
scanning: in the build process, run `trivy fs .` or `snyk test`
on the source code to catch vulnerable dependencies BEFORE building
the image. (3) Image scanning: after build, before push, run `trivy
image --exit-code 1 --severity CRITICAL myapp:tag`. Exit code 1:
fail the CI pipeline. The image is not pushed. (4) Registry scanning:
ECR, GCR, Harbor: scan images on push AND continuously rescan as
new CVEs are discovered. (5) Admission control: Kubernetes OPA/Gatekeeper
or Kyverno policies that require images to have a clean scan result
or a Cosign signature before a Pod can be created. (6) Regular rebuild:
schedule weekly base image rebuilds even without code changes. The
rebuilt image: picks up patched packages. Automatic PR to update
image tags in deployment manifests.

*What separates good from great:* Vulnerability management is a
continuous process, not a one-time gate. A critical CVE discovered
after an image is deployed: requires remediation within hours for
CVSS score 9+. Process: (1) Registry alerts: when a new CRITICAL
CVE is found in a deployed image, trigger a notification. (2) Automatic
PR: CI/CD creates a PR to rebuild with the patched base image. (3)
SLA: CRITICAL CVEs remediated within 24 hours in production. HIGH:
within 7 days. Treat unpatched CRITICAL CVEs like production incidents:
they are a security incident waiting to happen.

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*




