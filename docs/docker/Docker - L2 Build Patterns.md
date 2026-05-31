---
layout: default
title: "Docker - L2 Build Patterns"
parent: "Docker"
grand_parent: "SK Interview"
nav_order: 4
permalink: /docker/l2-build-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Docker - L2 Build Patterns](#docker---l2-build-patterns) | medium |

---

# Docker - L2 Build Patterns

## Multi-Stage Builds

---

### 🎯 Model Answer

**30 seconds:**
> Multi-stage builds: multiple `FROM` instructions in one Dockerfile.
> Earlier stages: compile, build, test. Final stage: copy only the
> artifacts into a minimal runtime image. Result: small production
> image without build tools, compilers, or intermediate files. A
> Java app built with Maven: ~900MB with JDK+Maven vs ~200MB with
> only JRE + JAR in the final stage.

**3 minutes (Senior):**
> Multi-stage patterns: (1) **Build + runtime split**: builder stage
> uses full JDK/node/Go toolchain. Runtime stage: minimal Alpine or
> distroless. `COPY --from=builder /app/dist /app` copies only
> the needed artifacts. Build dependencies (compilers, test frameworks,
> intermediate files) never reach the runtime image. (2) **Test stage**:
> add a `test` stage that runs unit tests during `docker build`.
> `docker build --target test .` runs only up to the test stage.
> CI: `docker build --target test .` first (fail fast on tests).
> Then `docker build --target runtime .` for the production image.
> (3) **Secrets in builds**: secret files (SSH keys for private git
> repos, npm auth tokens) should NOT be in any layer. Use BuildKit
> `--mount=type=secret`: file is available during the `RUN` instruction
> but NOT persisted in any layer. (4) **Cache mounts**: `--mount=
> type=cache,target=/root/.m2` persists the Maven local repository
> between builds. Dependency downloads: cached across builds without
> being in the image.

**Blank Mind Recovery:**

**(1) Restate:** "Multi-stage: multiple FROM instructions. Build tools
in earlier stages. Final stage: copy only artifacts. Smaller image,
no build tools in production. BuildKit secrets: not in any layer.
Cache mounts: faster builds via persistent package caches."

**(2) First principles:** "The build environment needs tools the
runtime doesn't. Tools in runtime image: increase attack surface,
image size, pull time. Multi-stage: separate environments. Only
the product moves forward, not the tools."

**(3) Bridge:** "Multi-stage build is like a car assembly line.
Stamping stage: heavy presses, metal. Assembly stage: all tools
and workers. Final quality check: only the car leaves the factory.
The factory equipment stays inside. The customer only gets the car."

---

### 📘 Concept Explanation

**Build stages, cache mounts, secrets, distroless:**
```
BASIC MULTI-STAGE BUILD:

  # Stage 1: builder (has Maven + JDK, large image)
  FROM maven:3.9-eclipse-temurin-17 AS builder
  WORKDIR /app
  COPY pom.xml .
  RUN mvn dependency:go-offline  # download dependencies (cacheable)
  COPY src ./src
  RUN mvn package -DskipTests -q  # build JAR
  
  # Stage 2: runtime (minimal JRE only, small image)
  FROM eclipse-temurin:17-jre-alpine AS runtime
  WORKDIR /app
  # Copy ONLY the JAR from the builder stage:
  COPY --from=builder /app/target/myapp-1.0.0.jar app.jar
  # builder stage (~800MB) vs runtime stage (~180MB)
  EXPOSE 8080
  USER 65534  # nobody user (non-root)
  CMD ["java", "-jar", "app.jar"]
  
  # Build:
  docker build -t myapp:1.0.0 .
  # Only the "runtime" stage is in the final image.

TEST STAGE PATTERN:

  FROM node:18-alpine AS base
  WORKDIR /app
  COPY package*.json ./
  RUN npm ci
  COPY . .
  
  FROM base AS test
  RUN npm test        # tests run in this stage
  RUN npm run lint    # linting
  
  FROM base AS runtime
  RUN npm run build   # production build
  USER node
  CMD ["node", "dist/server.js"]
  
  # CI pipeline:
  docker build --target test .     # run tests (fail fast)
  docker build -t myapp:1.2.3 .   # build final image (implicitly uses runtime target)

BUILDIT SECRETS (no credentials in layers):

  # Problem: private npm registry requires auth token.
  # BAD: token embedded in image:
  FROM node:18-alpine
  ARG NPM_TOKEN
  ENV NPM_TOKEN=$NPM_TOKEN
  RUN echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > .npmrc
  RUN npm install
  # .npmrc with token is now in the image layer. docker history shows it.
  
  # GOOD: BuildKit secret (not in any layer):
  # syntax=docker/dockerfile:1
  FROM node:18-alpine
  WORKDIR /app
  COPY package*.json ./
  # Secret mounted during RUN, NOT persisted in layer:
  RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
      npm ci
  COPY . .
  
  # Build:
  docker buildx build --secret id=npmrc,src=.npmrc -t myapp .
  # .npmrc: never in the image. Not visible in docker history.

CACHE MOUNTS (faster builds):

  # Maven: cache ~/.m2 between builds:
  # syntax=docker/dockerfile:1
  FROM maven:3.9 AS builder
  WORKDIR /app
  COPY pom.xml .
  COPY src ./src
  RUN --mount=type=cache,target=/root/.m2 \
      mvn package -DskipTests
  # /root/.m2: persisted on the Docker BuildKit cache. Not in image.
  # First build: downloads ~300MB of dependencies.
  # Subsequent builds: cache hit. Download time: 0.
  
  # pip: cache pip download cache:
  RUN --mount=type=cache,target=/root/.cache/pip \
      pip install -r requirements.txt

DISTROLESS AND SCRATCH IMAGES:

  # Distroless: Google's minimal images. No shell, no package manager.
  # Only the language runtime + app.
  FROM gcr.io/distroless/java17-debian12
  COPY --from=builder /app/target/app.jar /app.jar
  CMD ["/app.jar"]
  # No /bin/sh: attackers cannot run arbitrary shell commands.
  # No package manager: no apt-get install to download attack tools.
  # Attack surface: minimal.
  
  # Scratch: truly empty image. For statically compiled binaries.
  FROM golang:1.21 AS builder
  WORKDIR /app
  COPY . .
  RUN CGO_ENABLED=0 GOOS=linux go build -o myapp .  # static binary
  
  FROM scratch
  COPY --from=builder /app/myapp /myapp
  COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
  CMD ["/myapp"]
  # Image size: ~10MB (just the binary + TLS certs). vs ~600MB with Go base.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** A Java multi-stage Dockerfile with BuildKit
> cache and distroless runtime shows the complete production pattern.

```dockerfile
# BAD: everything in one stage - build tools in production image:
FROM maven:3.9-eclipse-temurin-17
WORKDIR /app
COPY . .
RUN mvn package
CMD ["java", "-jar", "target/app.jar"]
# Image size: ~800MB. Contains Maven, JDK, source code, test classes.
# Security: full JDK + Maven in production = large attack surface.

# GOOD: multi-stage with cache and distroless:
# syntax=docker/dockerfile:1
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
# Copy POM first (changes less often than source):
COPY pom.xml .
# Download dependencies: cached until pom.xml changes:
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -q
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn package -DskipTests -q

# Test stage (optional: run in CI before building runtime):
FROM builder AS test
RUN --mount=type=cache,target=/root/.m2 \
    mvn test

# Runtime: minimal, no build tools:
FROM gcr.io/distroless/java17-debian12 AS runtime
WORKDIR /app
COPY --from=builder /app/target/app-*.jar app.jar
EXPOSE 8080
USER nonroot:nonroot
CMD ["app.jar"]
# Final image: ~180MB vs ~800MB. Only JRE + app JAR. No Maven. No JDK.
```

> **Code walkthrough:** Three stages work together. The `builder`
> stage downloads dependencies into a cache mount (`/root/.m2`)
> that persists between Docker builds but is not in the image. The
> `test` stage extends `builder` to run tests. The `runtime` stage
> uses distroless (no shell, no OS tools) and copies only the JAR.
> `USER nonroot:nonroot` on distroless: run as non-root (UID 65532).
> The cache mount eliminates Maven dependency re-download on every
> build: the most time-consuming step.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Multi-stage builds use multiple FROM instructions. Earlier stages:
> compile and build. Final stage: copy only the compiled artifact.
> Result: small runtime image without build tools. Example: compile
> a Go binary in a Go builder stage, copy the binary to a scratch
> (empty) image. Production image: just the binary.

---

**Senior / Staff (5+ years):**
> The test stage pattern integrates testing into the Docker build
> itself. CI/CD: `docker build --target test .` first (fail fast).
> Then `docker build .` for the production image. If tests fail: no
> production image is built. Benefit: tests are reproducible in any
> environment that has Docker (no "install test dependencies"
> step in CI). BuildKit secrets: replace the old pattern of `ARG
> BUILD_SECRET` (visible in image metadata) with `--mount=type=
> secret` (never in any layer). Any secret that needs to be used
> during build (npm token, git credentials): always use BuildKit
> secrets in production pipelines.

---

### ⚠️ Common Misconceptions

**Misconception: "Multi-stage builds are only useful for compiled languages."**
Multi-stage builds provide value for any language. For Node.js:
builder stage with devDependencies (webpack, TypeScript, testing
libraries), build the dist, copy dist + production node_modules to
runtime stage. For Python: builder stage with pip install + virtual
environment, copy the venv to a minimal runtime image. For shell
scripts: builder stage to validate, lint, and test the scripts.
Runtime stage: minimal Alpine with only the scripts and required
tools. The benefit is universal: remove anything from the production
image that is not needed at runtime. Build tools, test frameworks,
documentation generators, and intermediate files: these have no
place in a production image. Multi-stage is the tool to enforce this
regardless of language.

---

### ⚖️ Comparison Table

| Approach | Image Size | Build Tools in Image | Security | Build Speed |
|---|---|---|---|---|
| Single stage | Large | Yes | Poor | Fast (no copy) |
| Multi-stage | Small | No | Good | Slightly slower (copy) |
| Multi-stage + distroless | Minimal | No | Excellent | Same |
| Multi-stage + scratch | Tiny | No | Maximum | Same |

---

### 🏛️ System Design

*(Omit: multi-stage builds are a build pipeline pattern, not a system design component.)*

---

### 📊 Diagram

*(Omit: multi-stage build flow is clearest in the annotated Dockerfile above.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Production image contains credentials from build process.**
```
Symptom: Security scanner reports credentials in Docker image layers.
  Or: docker history myapp:latest reveals NPM_TOKEN or SSH key.

Root cause: credential set via ARG or ENV (visible in metadata),
  or embedded in a layer via a .npmrc or .ssh file that was not
  deleted in the same RUN instruction.

Diagnosis:
  # Check build arguments and environment:
  docker history --no-trunc myapp:latest | grep -i token
  docker inspect myapp:latest | grep -i -A5 '"Env"'
  
  # Check all layers for credential files:
  dive myapp:latest  # interactive layer explorer
  # Look for .npmrc, .gitconfig, .ssh/ in any layer.
  
  # Check ARG values (visible in BuildKit build logs):
  docker build --progress=plain ...  # shows all RUN commands

Fix:
  Replace ARG/ENV-based credentials with BuildKit secrets:
  RUN --mount=type=secret,id=npmtoken \
      NPM_TOKEN=$(cat /run/secrets/npmtoken) \
      npm ci
  
  For already-leaked images:
  1. Rotate the credential immediately (revoke the old token).
  2. Rebuild the image with the credential removed.
  3. Remove all versions of the image from the registry.
  4. Audit which systems pulled the compromised image.
  
  Prevention: add credential scanning to CI/CD:
  trufflesecurity/trufflehog or gitleaks on image layers.
  Or: docker scout in CI (Docker's own advisory scanning).
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Multi-stage build purpose | 1 minute |
| Build + runtime image size comparison | 1 minute |
| Test stage pattern | 2 minutes |
| BuildKit secrets | 2 minutes |
| Cache mounts | 2 minutes |
| Distroless vs alpine vs scratch | 1 minute |
| Credential leak diagnosis | 2 minutes |

---

**Q1 (architecture): How do you handle secrets that are needed during the build process (e.g., private npm registry token)?**

A: BuildKit secrets. The BuildKit secret mount (`--mount=type=secret`)
provides the secret file during a specific `RUN` instruction but
does NOT persist it in any image layer or metadata. The build command:
`docker buildx build --secret id=npmtoken,env=NPM_TOKEN .`. The
Dockerfile: `RUN --mount=type=secret,id=npmtoken NPM_TOKEN=$(cat
/run/secrets/npmtoken) npm ci`. The secret file exists at
`/run/secrets/npmtoken` only during that `RUN` instruction. After
the instruction completes: the file is gone. It does not appear in
the layer, in `docker history`, in `docker inspect`, or in any image
manifest. For SSH keys (private git repos during build): `--mount=
type=ssh` provides the SSH agent socket without embedding the key.
`RUN --mount=type=ssh git clone git@github.com:private/repo.git`.

*What separates good from great:* The `ARG` credential pattern is
still common in older Dockerfiles and tutorials. It's insecure:
`docker history` shows all ARG values. Even if the ARG is unset
at the end of the Dockerfile, it's in the build metadata. Audit
all Dockerfiles for `ARG *SECRET*`, `ARG *TOKEN*`, `ARG *KEY*`,
`ARG *PASSWORD*`. Any match: replace with BuildKit secrets. For
teams with many Dockerfiles: add a CI check that fails if `ARG`
names match credential patterns. This preventive control is faster
than remediation after a credential leak.

---

**Q2 (production): How do you reduce a Java Spring Boot application image from 900MB to under 200MB?**

A: Five steps. (1) Multi-stage build: build with Maven+JDK in the
builder stage. Runtime stage: JRE only (not JDK). JDK includes
compiler, tools, javadoc. JRE: only runtime. Switch from
`eclipse-temurin:17` (JDK, ~500MB) to `eclipse-temurin:17-jre-alpine`
(JRE, ~180MB). (2) Alpine base: Alpine Linux vs Debian/Ubuntu. Same
JRE on Alpine: ~60% smaller OS layer. (3) Distroless: switch from
Alpine JRE to `gcr.io/distroless/java17`: no shell, no APK, just
JRE. Smaller attack surface AND smaller size. (4) Layered JAR: instead
of a fat JAR (dependencies + app bundled), use Spring Boot's layered
JAR mode. `COPY --from=builder /app/target/app.jar app.jar` + Spring
Boot layered extraction. Most layers: the dependencies layer (changes
rarely). The application layer (changes every build): small. Better
layer caching on pull. (5) JVM optimization: configure JVM for
container awareness: `-XX:+UseContainerSupport -XX:MaxRAMPercentage=70.0`.
JVM auto-detects container memory limits (cgroup) and scales heap
accordingly.

*What separates good from great:* The Spring Boot layered JAR
approach optimizes pull time, not just image size. A fat JAR: one
large layer that changes on every build. Pull: downloads the entire
fat JAR. Layered JAR: dependencies layer (stable), Spring framework
layer (stable), application layer (small, changes every build). Pull:
only the changed application layer. For a 300MB fat JAR: every
deployment pulls 300MB. For a layered JAR with 280MB of dependencies
and 20MB of app code: every deployment pulls 20MB (dependencies
cached). In a rolling deployment with 50 pods: 300MB vs 20MB per
pod = 7.5GB vs 500MB total pull traffic per deployment.

---

---

## Docker Compose for Local Development

---

### 🎯 Model Answer

**30 seconds:**
> Docker Compose: a tool for defining and running multi-container
> applications with a single YAML file. Key file: `docker-compose.yml`.
> One command: `docker compose up` starts all services. Core concepts:
> services (containers), networks (inter-service communication),
> volumes (persistent data), environment variables, and health checks.
> Use case: local development environment that mirrors production
> topology.

**3 minutes (Senior):**
> Compose best practices for local dev: (1) **Override files**:
> `docker-compose.yml` (base, production-like settings), `docker-compose.
> override.yml` (auto-applied, developer-specific: bind mounts for
> live reload, debug ports, relaxed resource limits). `docker compose
> up` merges both. CI uses only the base file. (2) **Profiles**:
> `docker compose --profile debug up` only starts services tagged
> with `profiles: [debug]`. Optional components (admin tools, load
> generators) only started when needed. (3) **Depends_on with
> condition**: `condition: service_healthy` waits for a healthcheck
> to pass before starting the dependent service. Without this:
> app starts before DB is ready = connection errors on startup.
> (4) **Secrets and environment**: never hardcode secrets in
> compose files. Use `.env` file (not committed) or environment
> variable substitution. (5) **Named volumes**: persist DB data
> across `docker compose down` (without `-v` flag).

**Blank Mind Recovery:**

**(1) Restate:** "Compose: YAML to define services, networks, volumes.
`docker compose up` starts all. Override files: base + developer
overrides. Profiles: optional services. depends_on + condition:
service_healthy = ordered startup. .env: secrets not in compose file."

**(2) First principles:** "Running multiple containers manually:
error-prone, hard to reproduce. Compose: declarative definition.
Networks: auto-created, services discover each other by name. The
goal: one command to start an entire local environment."

**(3) Bridge:** "Docker Compose is like a recipe for a multi-course
meal. Each course (service) has its ingredients (image, config) and
preparation order (depends_on). The kitchen (network): all courses
share. The pantry (volume): ingredients persist between meals."

---

### 📘 Concept Explanation

**Compose file structure, override, profiles, healthchecks:**
```
DOCKER COMPOSE FILE STRUCTURE:

  # docker-compose.yml:
  version: "3.9"
  
  services:
    db:
      image: postgres:15-alpine
      environment:
        POSTGRES_DB: myapp
        POSTGRES_USER: myapp
        POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      volumes:
        - pgdata:/var/lib/postgresql/data
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U myapp"]
        interval: 5s
        timeout: 5s
        retries: 5
      networks:
        - backend
    
    redis:
      image: redis:7-alpine
      healthcheck:
        test: ["CMD", "redis-cli", "ping"]
        interval: 5s
      networks:
        - backend
    
    app:
      build:
        context: .
        target: runtime            # build to 'runtime' stage
      environment:
        DATABASE_URL: postgresql://myapp:${DB_PASSWORD}@db:5432/myapp
        REDIS_URL: redis://redis:6379
      depends_on:
        db:
          condition: service_healthy    # wait for DB healthcheck
        redis:
          condition: service_healthy
      ports:
        - "3000:3000"
      networks:
        - backend
  
  volumes:
    pgdata: {}
  
  networks:
    backend: {}

OVERRIDE FILES (development ergonomics):

  # docker-compose.override.yml (auto-applied locally, not in CI):
  version: "3.9"
  services:
    app:
      build:
        target: development       # use dev stage with nodemon
      volumes:
        - .:/app                  # bind mount for live reload
        - /app/node_modules       # keep node_modules from image
      environment:
        NODE_ENV: development
        DEBUG: "myapp:*"
      ports:
        - "9229:9229"             # Node.js debug port

PROFILES (optional services):

  services:
    app: ...                      # always started
    
    mailhog:                      # only started with --profile tools
      image: mailhog/mailhog
      profiles: [tools]
      ports:
        - "8025:8025"
    
    pgadmin:                      # only started with --profile admin
      image: dpage/pgadmin4
      profiles: [admin]
  
  # docker compose up               -> starts app only
  # docker compose --profile tools up -> starts app + mailhog
  # docker compose --profile admin --profile tools up -> all

USEFUL COMPOSE COMMANDS:

  docker compose up -d            # start all services in background
  docker compose up --build       # rebuild images before starting
  docker compose down             # stop and remove containers (keeps volumes)
  docker compose down -v          # stop + remove containers AND volumes
  docker compose ps               # list running services
  docker compose logs -f app      # follow app logs
  docker compose exec app /bin/sh # shell into app service
  docker compose restart app      # restart one service
  docker compose scale app=3      # run 3 instances of app service
  docker compose config           # show merged compose config (with overrides)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** A Node.js + PostgreSQL + Redis Compose setup
> with health checks and override files shows production-like local
> development configuration.

```yaml
# BAD: no healthchecks, hardcoded secrets, no volume persistence:
version: "3"
services:
  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: hardcoded_secret  # BAD: committed to git
  app:
    image: myapp
    depends_on:
      - db  # only waits for DB to START, not to be ready
# App: fails on startup because DB needs ~3 seconds to be ready.

# GOOD: health checks, env file, named volumes:
version: "3.9"

services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-myapp}  # from .env or default
      POSTGRES_DB: ${POSTGRES_DB:-myapp}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD} # REQUIRED (no default)
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-myapp}"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 10s  # give DB time to initialize on first start
    restart: unless-stopped

  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER:-myapp}:${POSTGRES_PASSWORD}@db/myapp
    depends_on:
      db:
        condition: service_healthy  # app only starts when DB is ready
    restart: unless-stopped

volumes:
  pgdata: {}
```

> **Code walkthrough:** `${POSTGRES_USER:-myapp}` reads from the
> environment or `.env` file, with `myapp` as a default if not set.
> `${POSTGRES_PASSWORD}` (no default): will fail with an error if
> not set, preventing accidental use of empty passwords. The
> `depends_on` with `condition: service_healthy` waits for the
> healthcheck to pass (not just container start). `start_period: 10s`
> gives the DB time to initialize before health checks count as
> failures. The `pgdata` named volume: persists across `docker
> compose down` (data not lost when stopping for the day).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Docker Compose: define multiple containers in one YAML file. `docker
> compose up` starts everything. Services connect via their name
> (DNS). volumes: persist data. `docker compose down` stops everything.
> The main benefit: one command to start a complete local environment
> instead of multiple `docker run` commands.

---

**Senior / Staff (5+ years):**
> The `docker-compose.override.yml` pattern is the key to balancing
> dev ergonomics with production parity. Base file: production-like
> settings (no bind mounts, no debug ports, proper resource limits).
> Override file: developer comforts (live reload, debug ports, verbose
> logging). CI: runs with the base file only (no override). Developers:
> automatically get the override. This means: "it works in Compose"
> is close to "it works in production" because the base configuration
> matches. The override is transparent: developers don't need to think
> about it. `docker compose config` shows the merged result for
> debugging.

---

### ⚠️ Common Misconceptions

**Misconception: "depends_on guarantees the service is ready when the dependent starts."**
`depends_on` (without a condition) only waits for the dependent
container to START (not to be READY). A database container starts in
~0.1 seconds (the process launches). But the database may take 3-10
seconds to be ready for connections. Without `condition: service_healthy`,
the app container starts immediately after the DB container starts.
The first connection attempt: fails with "Connection refused" because
the DB is still initializing. The fix: add a healthcheck to the DB
service and use `condition: service_healthy` in depends_on. The
healthcheck polls until the DB is accepting connections.
Alternative: implement retry logic in the application startup code
(exponential backoff). This is more resilient: handles cases where
the DB becomes unavailable AFTER startup, not just at startup.

---

### ⚖️ Comparison Table

| Feature | Without Compose | With Compose |
|---|---|---|
| Start multi-service app | 5+ docker run commands | docker compose up |
| Service discovery | Manual IP management | Automatic DNS |
| Dependency ordering | Manual coordination | depends_on + healthcheck |
| Environment config | Repeated -e flags | YAML + .env file |
| Volume management | Separate docker volume commands | Declared in YAML |
| Override for dev | Separate files, manual merging | docker-compose.override.yml |

---

### 🏛️ System Design

*(Omit: Docker Compose is a local development and small-scale deployment tool, not an architecture pattern.)*

---

### 📊 Diagram

*(Omit: Docker Compose topology is clearest in the YAML configuration above.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: App fails on startup because DB is not ready.**
```
Symptom: app container exits with:
  "Error: connect ECONNREFUSED 127.0.0.1:5432"
  Or: "FATAL: database 'myapp' does not exist"
  
  Docker logs: app starts, fails to connect, exits with error.
  docker ps: app container is stopped or restarting.

Root cause: app starts before DB is ready to accept connections.
  depends_on: [db] only waits for DB container to start, not be ready.
  PostgreSQL initialization: takes 3-10 seconds on first run.

Diagnosis:
  docker compose logs db | tail -30
  # Look for: "database system is ready to accept connections"
  # When does this message appear vs when app started?
  
  docker compose ps
  # DB: "Up". App: "Exit 1" or "Restarting".

Fix:
  Option A: healthcheck + condition (preferred):
    db:
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U myapp"]
        interval: 3s
        retries: 10
    app:
      depends_on:
        db:
          condition: service_healthy
  
  Option B: entrypoint wait script:
    app:
      entrypoint: ["/bin/sh", "-c", "while ! nc -z db 5432; do sleep 1; done; exec node server.js"]
    # Waits until port 5432 is open, then starts the app.
    # Less precise than healthcheck (port open != DB ready for queries).
  
  Option C: application-level retry (most resilient):
    // In app code: retry DB connection with exponential backoff.
    // Handles: startup race AND production DB restarts.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Docker Compose purpose | 1 minute |
| depends_on limitation | 2 minutes |
| Healthcheck + condition pattern | 2 minutes |
| Override files strategy | 2 minutes |
| Secrets in Compose | 1 minute |
| Profiles feature | 1 minute |
| App fails to connect to DB | 1 minute |

---

**Q1 (production): How do you manage secrets in Docker Compose for local development?**

A: Two approaches. (1) `.env` file: create a `.env` file in the
same directory as `docker-compose.yml`. Docker Compose automatically
loads it. Variables in `.env`: available in the compose file as
`${VARIABLE_NAME}`. Add `.env` to `.gitignore`: never committed to
git. Provide a `.env.example` with placeholder values (committed):
tells developers which variables to set. (2) Docker Compose secrets
(for more control): use the `secrets` top-level key. Secrets: mounted
as files at `/run/secrets/secretname` inside the container. Not
visible in environment (docker inspect). More aligned with production
secrets management (Kubernetes secrets, Docker Swarm secrets). For
local dev: the `.env` approach is simpler and sufficient. For a
shared staging environment running on Docker (not Kubernetes): Compose
secrets are more secure. The critical rule: NEVER hardcode secrets
in `docker-compose.yml`. They will be committed to git and exposed.

*What separates good from great:* The `.env` security boundary. Even
though `.env` is not committed, it may still be visible to anyone
with filesystem access to the developer's machine. For a team using
a shared development environment: team members should each have
their own `.env` with their own credentials (not a shared team
secret). Production-equivalent secrets (prod database passwords):
should NEVER be in `.env`. Use the real secret management system
(Vault, AWS Secrets Manager) even locally for production-equivalent
testing. Developer secrets for local dev databases: low-risk if the
dev database is isolated and disposable.

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




