---
layout: default
title: "Docker - L2 Configuration and Health"
parent: "Docker"
grand_parent: "SK Interview"
nav_order: 5
permalink: /docker/l2-configuration-and-health/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Docker - L2 Configuration and Health](#docker---l2-configuration-and-health) | medium |

---

# Docker - L2 Configuration and Health

## Container Health Checks and Restart Policies

---

### 🎯 Model Answer

**30 seconds:**
> Docker healthchecks: periodic tests that determine if a container
> is "healthy" or "unhealthy". Configured in Dockerfile (`HEALTHCHECK`)
> or docker-compose.yml. States: starting, healthy, unhealthy. Used
> by orchestrators (Compose depends_on, Docker Swarm, Kubernetes
> liveness probes) to route traffic only to healthy containers.
> Restart policies: `no`, `always`, `on-failure[:N]`, `unless-stopped`.

**3 minutes (Senior):**
> Healthcheck mechanics: (1) **Configuration**: `HEALTHCHECK --interval
> =30s --timeout=5s --start-period=10s --retries=3 CMD curl -f
> http://localhost:3000/health || exit 1`. Interval: how often to
> check. Timeout: max time the command can take. Start-period: grace
> period before failures count (DB initialization). Retries: consecutive
> failures before marking unhealthy. (2) **Healthcheck endpoint
> design**: the `/health` endpoint must check actual service readiness:
> DB connection, downstream dependencies. Not just "is the HTTP
> server running" (too shallow). Not a full integration test (too
> slow). Balance: check enough to confirm readiness without causing
> overhead. (3) **Restart policy interaction**: if a container is
> unhealthy and `--restart on-failure`: Docker DOES NOT restart
> unhealthy containers (only containers that exit). Unhealthy: the
> container is still running but not passing health checks. Orchestrators
> (Kubernetes): use liveness probe (restart if unhealthy) + readiness
> probe (stop routing traffic if unhealthy). Docker standalone:
> healthchecks affect Docker Swarm service routing.

**Blank Mind Recovery:**

**(1) Restate:** "Healthcheck: periodic CMD in container. States:
starting/healthy/unhealthy. Interval, timeout, start-period, retries
= four tuning knobs. /health endpoint: check DB connection + key
dependencies. Restart policy: separate from healthcheck (restart on
exit, not on unhealthy in standalone Docker)."

**(2) First principles:** "Is the service ready to handle requests?
Not just 'is it running?' (process check) but 'is it functional?'
(dependency check). Healthcheck: the bridge between container running
and container ready. Critical for zero-downtime rolling deployments."

**(3) Bridge:** "Container health is like a restaurant open sign.
Process running (container started): lights are on. Healthcheck
passing: the kitchen is ready, tables are set, and the chef is in.
Both needed before putting out the 'Open' sign (routing traffic)."

---

### 📘 Concept Explanation

**Healthcheck configuration, /health endpoint design, Kubernetes comparison:**
```
HEALTHCHECK IN DOCKERFILE:

  # Basic HTTP healthcheck:
  HEALTHCHECK \
    --interval=30s \    # check every 30 seconds
    --timeout=5s \      # command must complete in 5 seconds
    --start-period=15s \ # grace period before failures count
    --retries=3 \       # 3 consecutive failures -> unhealthy
    CMD curl -f http://localhost:3000/health || exit 1
  
  # -f flag: curl exits with non-zero if HTTP 4xx/5xx.
  # || exit 1: explicit failure if curl fails (connection refused, etc.).
  
  # For services without curl (distroless): use wget or native tools:
  HEALTHCHECK CMD wget -qO- http://localhost:3000/health || exit 1
  
  # For Java (no curl in distroless): use native JVM HTTP:
  HEALTHCHECK CMD ["/usr/local/bin/health-check"]
  # health-check: custom binary that makes HTTP request and exits 0/1.
  # Or: configure Actuator and use Spring Boot's built-in healthcheck.

HEALTHCHECK IN DOCKER COMPOSE:

  services:
    app:
      image: myapp:1.2.3
      healthcheck:
        test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
        interval: 10s
        timeout: 5s
        retries: 3
        start_period: 15s
    
    db:
      image: postgres:15
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U myapp"]
        interval: 5s
        timeout: 3s
        retries: 10
        start_period: 10s  # postgres takes time on first init

MONITORING HEALTHCHECK STATUS:

  docker inspect mycontainer | grep -A5 '"Health"'
  # Output:
  # "Status": "healthy",
  # "FailingStreak": 0,
  # "Log": [
  #   {"Start": "...", "End": "...", "ExitCode": 0, "Output": "OK"}
  # ]
  
  docker ps
  # STATUS column: Up X minutes (healthy) or Up X minutes (unhealthy)
  
  # Watch healthcheck status in real time:
  watch 'docker inspect mycontainer | grep -A3 '"'"'"Health"'"'"''

HEALTHCHECK ENDPOINT DESIGN:

  # BAD: always returns 200 (useless healthcheck):
  @GetMapping("/health")
  public ResponseEntity<String> health() {
      return ResponseEntity.ok("OK");  // does not check anything
  }
  
  # GOOD: checks actual dependencies:
  @GetMapping("/health")
  public ResponseEntity<Map<String, Object>> health() {
      Map<String, Object> result = new LinkedHashMap<>();
      boolean allHealthy = true;
      
      // Check DB connection:
      try {
          jdbcTemplate.queryForObject("SELECT 1", Integer.class);
          result.put("database", "healthy");
      } catch (Exception e) {
          result.put("database", "unhealthy: " + e.getMessage());
          allHealthy = false;
      }
      
      // Check cache:
      try {
          redisTemplate.opsForValue().get("health-check-probe");
          result.put("cache", "healthy");
      } catch (Exception e) {
          result.put("cache", "unhealthy: " + e.getMessage());
          allHealthy = false;
      }
      
      result.put("status", allHealthy ? "healthy" : "degraded");
      return ResponseEntity
          .status(allHealthy ? 200 : 503)
          .body(result);
  }
  
  // Healthcheck: checks DB + cache. Returns 503 if either is down.
  // Docker: marks container unhealthy -> orchestrator stops routing traffic.

RESTART POLICIES:

  # docker run --restart=on-failure:3 myapp
  # Restart up to 3 times if exits with non-zero exit code.
  
  # --restart=always: restart always, including after daemon restart.
  # Use for: production services that must auto-recover.
  
  # --restart=unless-stopped: like always, but NOT restarted if manually stopped.
  # Most practical for production: auto-recovers from crashes, respects manual stops.
  
  # --restart=no (default): no automatic restart.
  # Use for: batch jobs (should not retry infinitely), short-lived tasks.
  
  # Note: restart policies do NOT trigger on unhealthy healthcheck.
  # They trigger on: container process exit with non-zero exit code.
  # A container that is "unhealthy" but whose process is still running:
  # is NOT restarted by Docker restart policy.
  # Kubernetes: liveness probe kills and restarts unhealthy pods.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** A Spring Boot health endpoint with structured
> checks and a Docker Compose healthcheck configuration shows the
> complete integration.

```java
// BAD: shallow health endpoint that gives false confidence:
@RestController
class HealthController {
    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP");  // always UP, checks nothing
    }
}

// GOOD: health endpoint that actually validates service readiness:
@RestController
@RequiredArgsConstructor
class HealthController {
    private final DataSource dataSource;
    private final StringRedisTemplate redis;
    
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        var checks = new HashMap<String, Object>();
        var healthy = new AtomicBoolean(true);
        
        // Database check (required for readiness):
        try (var conn = dataSource.getConnection()) {
            conn.createStatement().execute("SELECT 1");
            checks.put("database", "OK");
        } catch (Exception e) {
            checks.put("database", "FAIL: " + e.getMessage());
            healthy.set(false);
        }
        
        // Redis check (non-critical: degraded but not down):
        try {
            redis.opsForValue().get("probe");
            checks.put("cache", "OK");
        } catch (Exception e) {
            checks.put("cache", "DEGRADED: " + e.getMessage());
            // Don't set healthy=false for non-critical dependency.
        }
        
        var status = healthy.get() ? 200 : 503;
        checks.put("status", healthy.get() ? "UP" : "DOWN");
        return ResponseEntity.status(status).body(checks);
    }
}
```

> **Code walkthrough:** The health endpoint distinguishes between
> critical dependencies (database: failure = 503, container marked
> unhealthy) and non-critical dependencies (Redis: failure = degraded
> but 200, container stays healthy). This models the real business
> impact: without a database, the service cannot function. Without
> Redis (cache), it can fall back to direct DB reads (slower but
> functional). The orchestrator's healthcheck uses the HTTP status
> code: 200 = healthy, 503 = unhealthy (stop routing traffic).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Healthchecks: periodic commands that test if a container is working.
> Result: healthy, unhealthy, or starting. Useful for `depends_on:
> condition: service_healthy` in Docker Compose (ensures DB is ready
> before app starts) and for Kubernetes liveness/readiness probes.
> Always add a `/health` endpoint to services.

---

**Senior / Staff (5+ years):**
> The `/health` endpoint has two roles that should be separated:
> liveness (is the process alive and not deadlocked?) and readiness
> (is the service ready to accept traffic?). Kubernetes: two separate
> probes. Liveness: if failing, Kubernetes kills and restarts the
> pod. Checks: only detect deadlocks (never fail for downstream
> unavailability - that would cause restart storms when a shared
> dependency is down). Readiness: if failing, Kubernetes removes
> the pod from the load balancer (stops traffic) but does NOT restart.
> Use for: dependency checks (DB down = not ready, but don't restart
> the pod). Separate endpoints: `/health/live` and `/health/ready`.
> Spring Boot Actuator: provides both out of the box.

---

### ⚠️ Common Misconceptions

**Misconception: "An unhealthy container is automatically restarted by Docker."**
Docker's restart policy (`--restart on-failure`) triggers when the
container's main process exits with a non-zero exit code. It does NOT
trigger when the container is marked "unhealthy" by the healthcheck.
An unhealthy container: its process is still running (no exit), so
the restart policy does not apply. The container sits there, unhealthy,
serving no traffic (in Swarm mode) but not restarting. In standalone
Docker: you need external monitoring to detect and act on unhealthy
containers (e.g., a script that checks `docker ps` for `(unhealthy)`
status and calls `docker restart`). In Docker Swarm: Swarm will
replace unhealthy service tasks with new ones. In Kubernetes: the
liveness probe handles this (failure triggers container restart).

---

### ⚖️ Comparison Table

| Restart Policy | Triggers On | Does Not Restart On | Use Case |
|---|---|---|---|
| no | Nothing | All | One-shot tasks |
| always | Any exit | Manual stop | All production services |
| on-failure[:N] | Non-zero exit | Zero exit, manual stop | Services that crash-loop |
| unless-stopped | Non-zero exit, daemon restart | Manual stop | Production services (preferred) |

---

### 🏛️ System Design

*(Omit: healthcheck configuration is operational, not architectural.)*

---

### 📊 Diagram

*(Omit: healthcheck states are expressed clearly in the concept explanation.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Container marked unhealthy immediately on startup.**
```
Symptom: docker ps shows "(unhealthy)" status.
  Container: running but healthcheck failing.
  Application: may actually be working fine.

Root cause: start-period not configured (default: 0s).
  Healthcheck starts immediately. DB/app initialization takes 5-10s.
  First 3 healthchecks (interval=5s = 15s): all fail.
  After retries (default 3): marked unhealthy.
  
  Or: healthcheck command not available in minimal image (no curl).

Diagnosis:
  docker inspect mycontainer | grep -A20 '"Health"'
  # Look at "Log" array: what is the "Output" of failed checks?
  # "Output": "/bin/sh: curl: not found" -> curl missing in image.
  # "Output": "curl: (7) Failed to connect" -> app not yet listening.
  
  # Check the healthcheck exit code:
  docker inspect mycontainer --format '{{range .State.Health.Log}}{{.ExitCode}} {{.Output}}{{end}}'

Fix:
  Add start_period to give app time to initialize:
  healthcheck:
    start_period: 30s  # no failures counted for first 30 seconds
    retries: 3
    interval: 10s
  
  If curl missing: use wget, or add curl to the image:
  # For Alpine (small):
  RUN apk add --no-cache curl
  # Or: switch to HTTP check without curl (use /bin/sh + /dev/tcp):
  HEALTHCHECK CMD echo > /dev/tcp/localhost/3000 2>/dev/null || exit 1
  # TCP check: verifies port is listening. No curl needed.
  
  For distroless: build a custom health-check binary.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Healthcheck configuration options | 2 minutes |
| /health endpoint design | 2 minutes |
| Liveness vs readiness probe | 2 minutes |
| Restart policy vs healthcheck | 2 minutes |
| "Container unhealthy immediately" diagnosis | 1 minute |
| start_period purpose | 1 minute |
| Healthcheck in distroless images | 1 minute |

---

**Q1 (architecture): What is the difference between liveness and readiness probes in Kubernetes, and how does this differ from Docker healthchecks?**

A: Kubernetes has two distinct probe types. Liveness: is the container
alive? If it fails: the container is killed and restarted (if the
restart policy allows). Checks: deadlocks, hung processes. Should
NEVER check external dependencies (DB down = liveness fails = restart
storm when DB is down). Readiness: is the container ready to serve
traffic? If it fails: the pod is removed from the Endpoints (load
balancer). Container stays running. When readiness recovers: pod
is added back to Endpoints. Checks: external dependencies (DB,
downstream services). Failing readiness: traffic stops, no restart.
Docker healthcheck: a single concept without this distinction. The
healthcheck result affects: Compose `depends_on: condition:
service_healthy`, Docker Swarm routing, and `docker ps` status.
But standalone Docker: a healthcheck failure does NOT restart the
container (unlike Kubernetes liveness failure).

*What separates good from great:* The third probe type: startup probe.
Kubernetes 1.16+. Startup probe: used for slow-starting containers.
It disables liveness and readiness until it succeeds. After it
succeeds: liveness and readiness take over. Use case: legacy Java
applications that take 60+ seconds to start. Without startup probe:
liveness probe would kill the container before it finishes starting.
With startup probe (long threshold): liveness probe only kicks in
after startup is confirmed. This replaces the `initialDelaySeconds`
workaround (guessing how long startup takes). Startup probe: checks
actively until success. More reliable than a static delay.

---

---

## Environment Variables and Configuration Injection

---

### 🎯 Model Answer

**30 seconds:**
> Configuration injection in Docker: environment variables (`-e` or
> `ENV`), `.env` files, volume-mounted config files, Docker secrets
> (files at `/run/secrets/`), and external config stores (AWS
> Parameter Store, Vault). Rule: 12-factor app. Configuration varies
> between deploys (dev/staging/prod). Config: environment, not code.
> Secrets: never in images or environment variables (visible in
> `docker inspect`).

**3 minutes (Senior):**
> Configuration patterns: (1) **Environment variables**: simple
> key-value config. Easy to override per deployment. Visible in
> `docker inspect` and process environment (`/proc/1/environ`).
> Not suitable for secrets. (2) **`.env` file**: Compose-specific.
> Auto-loaded. Developer convenience. Not production-grade for secrets.
> (3) **Docker secrets**: mounted as files at `/run/secrets/`. Not
> in environment. Not in `docker inspect`. Best for sensitive values.
> Application reads from file. (4) **Mounted config files**: bind
> mount or volume with config file. The application reads its native
> config format (YAML, TOML). Kubernetes: ConfigMap mounted as files.
> (5) **External config store**: Vault, AWS Parameter Store, GCP
> Secret Manager. Application fetches config at startup. Centralized,
> audited, rotatable without container restart. Most secure but adds
> startup latency and a dependency. Production: combine approaches.
> Non-sensitive: env vars. Sensitive: Docker secrets or external
> store. Never: hardcoded in image.

**Blank Mind Recovery:**

**(1) Restate:** "Three tiers: env vars (non-sensitive, easy), Docker
secrets (sensitive, file-based, not in inspect), external config
store (most secure, centralized, rotatable). Never in image. 12-factor:
config in environment."

**(2) First principles:** "Config varies by deployment (dev/prod).
Code does not. Config must be external. Secrets: a subset of config
that must be protected from exposure. Exposure: image layer, inspect,
process env, logs. Each storage method has different exposure risk."

**(3) Bridge:** "Config injection is like a hotel key card. ENV:
the room number on a sticky note (visible to anyone). Docker secret:
the key card (functional, but not showing the room code). External
vault: a key card generated on demand by the front desk (auditable,
revocable, centralized)."

---

### 📘 Concept Explanation

**Env vars, secrets, config files, 12-factor app:**
```
ENVIRONMENT VARIABLE METHODS:

  # Method 1: docker run -e (inline):
  docker run -e DATABASE_URL=postgres://db:5432/myapp myapp
  # Simple. All values visible in docker inspect and process env.
  
  # Method 2: --env-file (from file):
  docker run --env-file .env.production myapp
  # .env.production: not committed. Better than inline for many vars.
  # Still visible in process env (/proc/1/environ on Linux).
  
  # Method 3: Dockerfile ENV (baked in):
  ENV NODE_ENV=production
  # Good for non-sensitive defaults (NODE_ENV, PORT).
  # Overrideable at runtime with -e.
  # Visible in docker inspect.
  
  # View env vars of running container:
  docker inspect mycontainer --format '{{json .Config.Env}}'
  # Shows ALL env vars including sensitive ones if set via -e.

DOCKER SECRETS (FILE-BASED, SECURE):

  # In Docker Swarm:
  echo "my-secure-password" | docker secret create db_password -
  docker service create \
    --secret db_password \
    myapp
  # Inside container: /run/secrets/db_password (file with value)
  
  # In Docker Compose (for Swarm or v3.1+ compose):
  services:
    app:
      image: myapp
      secrets:
        - db_password
  
  secrets:
    db_password:
      file: ./secrets/db_password.txt  # local file for dev
      # Or: external: true (from Docker Swarm secret store)
  
  # Inside container: /run/secrets/db_password
  # Application reads: String password = Files.readString(Path.of("/run/secrets/db_password"));
  # NOT visible in docker inspect. NOT in process env.

KUBERNETES EQUIVALENT (for context):

  # ConfigMap: non-sensitive configuration (as files or env vars):
  kubectl create configmap myapp-config --from-file=config.yaml
  # Mount in pod:
  volumeMounts:
    - name: config
      mountPath: /app/config
  
  # Secret: sensitive values (base64, not encrypted by default):
  kubectl create secret generic db-creds --from-literal=password=secret
  # Mount as env var:
  env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-creds
          key: password
  # Or: mount as file (like Docker secrets).
  # Note: Kubernetes secrets are base64-encoded, not encrypted.
  # Encryption at rest: requires etcd encryption configuration.
  # External secrets operator: integrates Vault/AWS Secrets Manager.

EXTERNAL CONFIG STORE PATTERN:

  # Application reads config from AWS Parameter Store on startup:
  # (AWS SDK auto-discovers region and credentials from EC2/ECS/EKS role)
  
  @Configuration
  class DatabaseConfig {
      @Value("${DB_PASSWORD:#{null}}")  // optional env var override
      String dbPasswordEnv;
      
      @Bean
      DataSource dataSource() {
          String password = dbPasswordEnv;
          
          if (password == null) {
              // Fetch from AWS Parameter Store:
              SsmClient ssm = SsmClient.create();
              GetParameterResponse response = ssm.getParameter(
                  GetParameterRequest.builder()
                      .name("/myapp/prod/db_password")
                      .withDecryption(true)
                      .build());
              password = response.parameter().value();
          }
          
          return DataSourceBuilder.create()
              .password(password)
              .build();
      }
  }
  // Benefit: password rotated in SSM without container restart.
  // Audit: every fetch logged in CloudTrail.
  // No password in any config file, env var, or Docker secret.

12-FACTOR APP CONFIGURATION PRINCIPLE:

  The 12-factor app (https://12factor.net): configuration is stored
  in the environment. "Environment" = everything that varies between
  deploys (dev, staging, production). Not in code (committed), not
  in config files committed to the repo.
  
  Practical rules:
  1. Database URLs: environment variable. Different per deploy.
  2. Feature flags: environment variable.
  3. Passwords and API keys: Docker secrets or external store.
  4. Default values: Dockerfile ENV (non-sensitive) or code defaults.
  5. Static config (immutable): baked into image (e.g., application.yaml).
  6. Dynamic config (changes without deploy): external store.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** A Spring Boot application reading secrets
> from `/run/secrets/` files shows the Docker secrets pattern with
> POJO configuration.

```java
// BAD: password as environment variable (visible in docker inspect):
@Configuration
class SecurityConfig {
    @Value("${DB_PASSWORD}")
    String password;  // From ENV var. Visible to docker inspect, ps -e.
    
    // Also bad: hardcoded in application.properties:
    // spring.datasource.password=hardcoded_secret
}

// GOOD: password from Docker secret file:
@Configuration
class SecurityConfig {
    
    private static final Path SECRETS_DIR =
        Path.of("/run/secrets");
    
    // Read secret from file (Docker secret or Kubernetes secret volume):
    private String readSecret(String name) {
        Path secretFile = SECRETS_DIR.resolve(name);
        if (Files.exists(secretFile)) {
            try {
                return Files.readString(secretFile).strip();
                // .strip(): remove trailing newline from secret file.
            } catch (IOException e) {
                throw new IllegalStateException(
                    "Cannot read secret: " + name, e);
            }
        }
        // Fallback: environment variable (for local dev without secrets):
        String envValue = System.getenv(name.toUpperCase());
        if (envValue != null) return envValue;
        
        throw new IllegalStateException(
            "Secret '" + name + "' not found in " + SECRETS_DIR +
            " and no env var " + name.toUpperCase() + " set");
    }
    
    @Bean
    DataSource dataSource() {
        return DataSourceBuilder.create()
            .url(System.getenv("DATABASE_URL"))  // non-sensitive
            .password(readSecret("db_password")) // from /run/secrets/db_password
            .build();
    }
}
```

> **Code walkthrough:** The `readSecret()` method first checks
> `/run/secrets/{name}` (Docker Secrets or Kubernetes Secret volume
> mount). Falls back to environment variable for local development
> (where Docker secrets may not be configured). `.strip()` removes
> the trailing newline that Docker appends to secret files. The dual
> path (file -> env var) allows: production uses Docker/K8s secrets
> (secure), local dev uses env vars (convenient). The application
> code does not change between environments.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Configuration: pass as environment variables (`-e` or `.env` file).
> Secrets: use Docker secrets (mounted as files in `/run/secrets/`)
> or external secret managers. Never hardcode secrets in Dockerfiles
> or docker-compose.yml. 12-factor principle: config in the environment,
> not in the code.

---

**Senior / Staff (5+ years):**
> The env var vs file secret distinction matters for compliance.
> Secrets in environment variables: visible in `docker inspect`,
> in the process environment (`/proc/1/environ`), and in many logging
> systems that capture process state. For PCI-DSS or SOC 2: this is
> a finding. Docker secrets (files in `/run/secrets/`): not in
> inspect, not in process env. Harder to accidentally leak. The best
> production pattern: secrets ONLY via Docker/Kubernetes secrets or
> external secret manager (Vault, AWS SSM). Environment variables:
> only for non-sensitive config. Enforce with a CI policy that fails
> if `*PASSWORD*`, `*SECRET*`, `*KEY*`, or `*TOKEN*` appear as env
> var names in compose files or K8s manifests.

---

### ⚠️ Common Misconceptions

**Misconception: "Secrets in Docker environment variables are safe because the container is isolated."**
Container isolation protects from NETWORK access between containers.
It does NOT protect secrets from: (1) `docker inspect` - any user
with Docker daemon access (which is essentially root) can read all
env vars of any container. (2) `/proc/1/environ` - if an attacker
achieves code execution inside the container: they can read all env
vars. (3) Application logs - if the application accidentally logs
an env var in a stack trace or debug output: the secret appears in
log files shipped to centralized logging. (4) Container image
inspection - if env vars are set with `ENV` in the Dockerfile: they
appear in `docker history` and the image manifest. Environment
variable secrets: have a large exposure surface. Files (Docker
secrets): much smaller surface. The value is never in process memory
except during the brief read at startup.

---

### ⚖️ Comparison Table

| Method | Visibility | Secrets Safe? | Dynamic Update | Complexity |
|---|---|---|---|---|
| ENV in Dockerfile | docker inspect, image history | No | No (rebuild) | Lowest |
| -e / --env-file | docker inspect, /proc/1/environ | No | Restart only | Low |
| Docker secrets | File at /run/secrets/, not in inspect | Yes | Rotation needs update | Medium |
| Mounted config file | Only if container compromised | Partial | Without restart | Medium |
| Vault / SSM | Only if app or store compromised | Yes | Dynamic (rotation) | High |

---

### 🏛️ System Design

*(Omit: configuration injection is operational, not architectural.)*

---

### 📊 Diagram

*(Omit: config injection methods are clearest in the code examples above.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Secret leaked in container logs or image history.**
```
Symptom: Security scanner or SIEM alerts: credentials found in logs.
  Or: developer accidentally views docker history and sees tokens.
  
Root cause options:
  1. Secret set via ARG in Dockerfile: visible in docker history.
  2. Application code logs the secret (debug log statement).
  3. Secret injected via ENV: visible in docker inspect and /proc/environ.
  4. Exception stack trace includes connection string with password.

Diagnosis:
  # Check Dockerfile ARG usage:
  grep -i "ARG.*TOKEN\|ARG.*SECRET\|ARG.*PASSWORD\|ARG.*KEY" Dockerfile
  
  # Check image history for credentials:
  docker history --no-trunc myimage:tag | grep -i "token\|secret\|password"
  
  # Check running container env vars:
  docker inspect mycontainer | grep -i "Env" -A 30 | grep -i "token\|pass\|secret"
  
  # Check application logs:
  docker logs mycontainer | grep -i "token\|password\|secret" | head -20

Immediate response:
  1. Rotate the compromised credential immediately.
  2. Audit who may have seen the secret (who has docker inspect access?).
  3. Remove the image from the registry.
  4. Rebuild with the credential removed from all layers.
  5. Update deployment with the new credential.

Prevention:
  - Replace ARG credentials with BuildKit secrets.
  - Replace ENV credentials with Docker secrets or external store.
  - Add log scrubbing in the application (mask known secret patterns).
  - CI: scan image layers with trufflehog or docker scout.
  - Application: never log configuration values during startup.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| 12-factor app config principle | 1 minute |
| ENV vs Docker secret | 2 minutes |
| Secret exposure vectors | 2 minutes |
| /run/secrets/ pattern | 1 minute |
| External config store | 2 minutes |
| Kubernetes ConfigMap vs Secret | 1 minute |
| Secret leaked in logs diagnosis | 1 minute |

---

**Q1 (security): How do you handle configuration that changes frequently without requiring container restarts?**

A: External configuration store with live reload. The pattern:
application polls or subscribes to a config store for changes.
Implementations: (1) AWS AppConfig: managed config store with
deployment controls. SDK polls for changes. When config changes:
the SDK delivers it to the application in memory. No container
restart. (2) Consul: key-value store with watch mechanism.
Application: uses Consul SDK to watch specific keys. On change:
callback invoked in application. (3) Spring Cloud Config + Bus: Spring
Boot app polls Spring Cloud Config Server. Config Server: backed by
git. On git push: webhook triggers Config Server refresh. Application:
Spring Actuator `/actuator/refresh` endpoint, or auto-refresh via
Spring Cloud Bus. (4) Environment variable + SIGHUP: some applications
re-read config on SIGHUP. `docker kill --signal=SIGHUP mycontainer`.
Config: still from env vars or files. But the application re-reads
on signal. Limited by what the application supports.

*What separates good from great:* Feature flags are the most
important use case for dynamic configuration. Feature flags: enable/
disable code paths without redeployment. Backing store: LaunchDarkly,
Unleash, or a simple DB table. The application reads feature flag
state on each request (or caches for 1 second). Deploying a risky
feature: set flag=false. Enable for 1% of users (A/B test). Ramp
up. If issues: disable in <1 second without redeployment. This is
the safest deployment pattern: feature flags decouple deployment
from release. The container image: deployed weeks before the feature
is enabled. This requires zero-restart dynamic configuration as a
prerequisite.

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




