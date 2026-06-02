---
layout: default
title: "DevOps CI/CD - L2 Deployment Patterns"
parent: "DevOps CI/CD"
nav_order: 5
permalink: /devops-cicd/l2-deployment-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Docker Integration in CI/CD](#docker-integration-in-cicd) | medium |
| 2 | [Deployment Strategies - Blue-Green and Canary](#deployment-strategies---blue-green-and-canary) | medium |

---

# Docker Integration in CI/CD

🎯 Interview Weight: high - Docker is the standard artifact format
in modern CI/CD; interviewers probe whether candidates can build
efficient, secure Docker pipelines.

---

### 🎯 Model Answer

**30 seconds:**
> Docker integration in CI/CD means the CI pipeline builds a Docker
> image, publishes it to a registry with an immutable tag, and CD
> deploys that image to each environment. The key principle is:
> build the image once in CI, promote the same image through dev,
> staging, and production. Never rebuild per environment. Use
> multi-stage builds to keep production images lean and secure.

**3 minutes (Senior):**
> Docker integration in CI/CD centers on three practices: efficient
> image building with layer caching, secure image publishing with
> proper authentication, and artifact promotion using immutable tags.
>
> The most impactful optimization is leveraging Docker's layer cache.
> A Dockerfile that copies all source code before running Maven
> dependencies invalidates the dependency layer on every source
> change - which is every commit. Ordering the Dockerfile to copy
> only the dependency manifest (pom.xml) first, then run dependency
> download, then copy source code means the expensive dependency
> download step hits the cache on most builds.
>
> Multi-stage builds are the standard pattern for production images.
> The build stage has the full JDK, Maven, and all build tooling.
> The production stage has only a minimal JRE and the application
> JAR. This typically reduces image size from 800MB to 100MB and
> eliminates all build tooling from the attack surface.
>
> For security, OIDC authentication with AWS ECR or GitHub Container
> Registry eliminates long-lived registry credentials. The CI pipeline
> never stores a Docker password - it exchanges a short-lived OIDC
> token for temporary registry credentials on each pipeline run.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* "The architecture decision at scale: who builds the
base image and how often? If 50 services all depend on a custom
base image with your company's security configuration, that base
image is a shared dependency that needs its own build pipeline,
testing, and update process. Base image staleness is a security
risk."

*Adapting down:* "Docker in CI means: CI builds the image,
pushes it to a registry, and CD deploys it. The image tag links
the build to the deployment."

**Blank Mind Recovery:**

**(1) Restate:** "Docker in CI/CD - how the image gets built,
published, and deployed."

**(2) First principles:** "You need to package the application for
deployment. Docker is the standard packaging format. CI should build
it; a registry should store it; CD should deploy it. Each step must
be secure and efficient."

**(3) Bridge:** "Like manufacturing and distribution. CI is the
factory (builds the product). The registry is the warehouse (stores
the product). CD is distribution (delivers the product to each
market/environment)."

---

### 📘 Concept Explanation

**What it is:**
Docker integration in CI/CD refers to the set of practices for
building Docker images in CI, storing them in artifact registries,
and deploying them via CD pipelines. It covers Dockerfile authoring
practices, CI pipeline image build steps, registry authentication,
tagging strategy, and deployment integration.

**The problem it solves:**
Before Docker as the CI/CD artifact format, deployments involved
copying files to servers, managing process daemons, handling
environment-specific configurations in JAR manifests, and managing
conflicting dependencies on shared servers. Docker encapsulates
the application and all its dependencies in a self-contained image
that runs identically across all environments.

**How it works:**

**Dockerfile structure (multi-stage build):**

Stage 1 (builder): full build environment
- JDK 21 with Maven/Gradle
- Copy dependency manifests first (cache-friendly)
- Download all dependencies (cached layer)
- Copy source code
- Build application artifact

Stage 2 (runtime): minimal production image
- Minimal JRE (not JDK)
- Copy only the built artifact from stage 1
- Configure non-root user
- Define entrypoint

**CI pipeline Docker steps:**
1. Authenticate to registry (OIDC, no stored credentials)
2. Enable BuildKit for layer caching
3. Build the image (with cache from/to configuration)
4. Tag with commit SHA (immutable tag)
5. Push to registry
6. Optionally: run vulnerability scan on the built image
7. Output image tag for downstream CD pipeline consumption

**Registry tagging conventions:**
- Primary: commit SHA (`myapp:a3f5c2d`) - immutable, traceable
- Optional alias: branch name (`myapp:main`) - mutable reference
- Never in production: `myapp:latest` or any mutable tag

**The key insight:**
Docker layer caching is the primary performance lever in image builds.
Understanding which operations invalidate the cache - and ordering
Dockerfile instructions to maximize cache reuse - can cut image
build time from 5 minutes to 30 seconds.

**When to use it:**
Any application deployed to a Kubernetes cluster, ECS, or any
container runtime should build a Docker image in CI. This is the
standard for all new services.

**When NOT to use it:**
Applications deployed as Lambda functions (ZIP package), static
sites (CDN asset upload), or serverless frameworks may not benefit
from Docker-based CI/CD. Native desktop applications have different
packaging requirements.

**Alternatives:**
- OCI images (not Docker-specific): built with Buildah, Podman,
  Kaniko, or Buildkit. OCI-compatible containers run everywhere
  Docker images run.
- Buildpacks (Cloud Native Buildpacks): automatically detect the
  application type and build an optimized image without a Dockerfile.
  Less control, more convention.

**First-principles derivation:**
The CI/CD pipeline must produce a deployment artifact. The artifact
must be: portable (runs anywhere without environment-specific
modifications), reproducible (same source = same artifact), and
minimal (small attack surface, fast deployment). Docker satisfies
all three: the container image is a complete runtime, tagged by
content hash, and multi-stage builds minimize size.

---

### 💻 Code Example

**BAD: Naive Dockerfile that invalidates cache on every source
change**

```dockerfile
# ANTI-PATTERN: Layer ordering kills cache efficiency

FROM eclipse-temurin:21-jdk as builder

WORKDIR /app

# WRONG: copy everything first
# This invalidates ALL subsequent layers on EVERY source change
COPY . .

# Dependency download is re-done on every commit
# Even if pom.xml did not change
RUN mvn -B dependency:resolve

# Build the application
RUN mvn -B package -DskipTests

FROM eclipse-temurin:21-jre
COPY --from=builder /app/target/myapp.jar /app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]

# Problems:
# 1. No multi-stage build optimization (JDK in production image)
# 2. Cache invalidated on every source change
# 3. Running as root (security risk)
# 4. Full JDK (larger attack surface, 800MB vs 200MB)
# 5. No .dockerignore (copies test files, git history)
```

> **Code walkthrough:** The fatal mistake is `COPY . .` before theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> Maven dependency resolution. Docker's layer cache is key-addressed
> by the checksum of each layer's inputs. Copying all source code
> before downloading dependencies means that any source change
> (even a comment) invalidates the dependency download layer.
> Maven then re-downloads all dependencies from the internet on
> every single build. On a cold cache, Maven downloads can take
> 3-8 minutes. With proper Dockerfile ordering, this drops to
> under 10 seconds.

**GOOD: Cache-optimized multi-stage Dockerfile with security
hardening**

```dockerfile
# .dockerignore (prevents unnecessary files from being in context)
# .git/
# target/
# **/*.md
# **/test/
# Dockerfile
```

> **Code walkthrough:** This Dockerfile example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

```dockerfile
# Multi-stage: lean production image, optimized build cache

# Stage 1: Dependency download (rarely invalidated)
FROM eclipse-temurin:21-jdk-jammy as deps

WORKDIR /build

# COPY ONLY pom.xml first
# This layer is only invalidated when dependencies change
# (pom.xml changes), not on every source code change
COPY pom.xml .
COPY .mvn/ .mvn/
COPY mvnw .

# Download all dependencies into a dedicated layer
# On cache hit: 10 seconds. On cache miss: 3-8 minutes.
RUN ./mvnw -B dependency:resolve dependency:resolve-plugins

# Stage 2: Build (invalidated on source code changes)
FROM deps as builder

# Copy source code AFTER dependencies are resolved
COPY src/ src/

# Build - fast because dependencies are already in the layer above
RUN ./mvnw -B package -DskipTests

# Stage 3: Runtime (minimal production image)
FROM eclipse-temurin:21-jre-jammy

# Security: create a non-root user for the application
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup \
    --no-create-home appuser

WORKDIR /app

# Copy ONLY the built artifact from the builder stage
# No JDK, no Maven, no source code, no test files
COPY --from=builder /build/target/myapp.jar /app/app.jar

# Security: set ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Health check for Kubernetes liveness/readiness probes
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080
ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-jar", \
    "/app/app.jar"]
```

> **Code walkthrough:** This Health check for Kubernetes liveness/readiness probes example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

{% raw %}
```yaml
# .github/workflows/docker.yml
name: Docker Build and Push

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx (required for BuildKit caching)
        uses: docker/setup-buildx-action@v3

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.ECR_PUSH_ROLE_ARN }}
          aws-region: us-east-1

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push with layer caching
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ steps.login-ecr.outputs.registry }}/myapp:
            ${{ github.sha }}
          # GitHub Actions cache for Docker layers
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Scan image for vulnerabilities
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: >
            ${{ steps.login-ecr.outputs.registry }}/myapp:
            ${{ github.sha }}
          severity: 'CRITICAL,HIGH'
          exit-code: '1'  # Gate: fail on critical/high CVEs
```
{% endraw %}

> **Code walkthrough:** Three-stage Dockerfile maximizes cacheice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> efficiency. Stage 1 (`deps`) copies only `pom.xml` - this layer
> is only invalidated when dependencies change. Stage 2 (`builder`)
> copies source code and builds - this layer is invalidated on source
> changes but benefits from the cached dependency layer. Stage 3
> (`runtime`) is the actual production image - only the JAR is
> copied, giving a minimal 200MB image instead of an 800MB JDK image.
> Non-root user (`appuser`) prevents container breakout privilege
> escalation. JVM flags `UseContainerSupport` and `MaxRAMPercentage`
> let the JVM use container memory limits correctly rather than
> defaulting to 25% of the host's RAM. GitHub Actions layer caching
> (`type=gha`) persists Docker build layers across CI runs.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> "In CI/CD, Docker is what we use to package applications. CI builds
> the Docker image from the Dockerfile, tags it with the commit SHA,
> and pushes it to a registry like ECR. CD then deploys that specific
> image to each environment. I know about multi-stage builds - they
> keep production images smaller by not including the build tools."

*Push deeper:* "The cache ordering in the Dockerfile was a big
learning for me. I didn't know that copying source code before
downloading dependencies would kill the cache on every build until
I noticed our builds were downloading 500MB of dependencies on every
run."

---

**Senior / Staff (5+ years):**
> "Docker integration in CI/CD is a well-understood pattern now, but
> there are still significant differences between teams that do it
> well and teams that just make it work.
>
> The critical production concerns: image size (smaller = faster
> pull, smaller attack surface), cache efficiency (bad Dockerfile
> ordering is the single biggest cause of slow CI), security
> (non-root users, read-only filesystems, minimal base images),
> and supply chain (signed images, SBOM generation, base image
> update automation).
>
> The pattern I enforce in all teams: Dockerfile is reviewed with
> the same rigor as application code. A Dockerfile that runs as root,
> includes a JDK in the production image, or bakes secrets into a
> layer is a security incident waiting to happen. We lint Dockerfiles
> with Hadolint in CI and fail the build on security violations."

*Push deeper:* "At the architect level, the question is base image
management. If 50 services use `eclipse-temurin:21-jre-jammy` and
a critical CVE is found in that base image, how long does it take
to update all 50 services? The answer for most organizations is
'months' - which means 50 services are running a vulnerable base
image for months. The solution: automated base image update PRs
via Dependabot or Renovate, with a policy that base image updates
must be deployed within 72 hours of a critical CVE patch."

---

### ⚖️ Comparison Table

| Build Tool | Daemon Needed | Rootless | Cache | K8s Native | Best For |
|------------|--------------|----------|-------|------------|----------|
| Docker BuildKit | Yes (or remote) | With rootless mode | Excellent | No | Standard CI |
| Kaniko | No | Yes | Good | Yes (runs in pod) | K8s-native CI |
| Buildah | No | Yes | Good | Yes | OpenShift, podman shops |
| Cloud Native Buildpacks | No | Yes | Good | Yes | Convention over config |
| Jib (Java) | No | Yes | Excellent | Yes | Java-only, no Dockerfile |

**The deciding factor:**
For most teams: Docker BuildKit with GitHub Actions is the standard
choice. For Kubernetes-native CI (Tekton, GitHub Actions on self-hosted
K8s runners): Kaniko eliminates the Docker daemon requirement. For
Java teams that want zero-Dockerfile builds: Jib produces highly
optimized images and runs without Docker.

---

### ⚠️ Common Misconceptions

**Misconception 1: CI image builds are identical to local Docker builds.**

Local builds rely on your existing layer cache and local daemon state. CI runners start fresh every run - or share a cache that requires explicit configuration. Without `--cache-from` or BuildKit inline caching, CI builds pull every layer from scratch, making a 2-minute local build take 15 minutes in CI. BuildKit's registry-based cache export (`--cache-to type=registry`) is required to make CI builds comparable to local ones.

**Misconception 2: Multi-stage builds are only about reducing image size.**

Image size is one benefit, but the primary value is separation of concerns: build-time dependencies (compilers, test runners, source code) never reach the production image. A 500MB JDK in a build stage produces a 150MB runtime image containing only the JRE and the compiled artifact. This also prevents credential leaks - any `--secret` or `ARG` used during build cannot appear in the final production layer.

**Misconception 3: Running containers as root is acceptable for internal services.**

Over 60% of container privilege escalation attacks exploit root-running containers. The one-line fix (`USER appuser`) in your Dockerfile eliminates this class of risk. Cloud provider security scanners (Trivy, Snyk) flag root-running containers as HIGH severity by default, which blocks automated deployments in security-conscious organizations.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Secrets baked into Docker image layers**
Symptom: Security scan detects credentials in Docker image history.
`docker history myapp:tag` shows environment variables with secrets.
Cause: `--build-arg MY_SECRET=value` in docker build command. Build
ARGs are stored in image metadata.
Diagnosis: `docker inspect myapp:tag | grep -i secret` and
`docker history myapp:tag`.
Fix: never pass secrets as build ARGs. Use multi-stage builds where
secrets needed only at build time (private Maven registry credentials)
exist only in the builder stage, which is discarded. Use BuildKit
secret mounts: `RUN --mount=type=secret,id=mvn_token`.

**Failure Mode 2: Production image size bloat**
Symptom: Docker image is 800MB+. Kubernetes pod startup takes 3+
minutes on new nodes due to slow image pull. OOM kills in production
because the JVM thinks it has access to the full node's RAM.
Cause: Single-stage Dockerfile using JDK instead of JRE. No
`.dockerignore`. JVM not configured for container memory limits.
Fix: multi-stage build with JRE-only production stage. Add
`.dockerignore` to exclude test files, git history, and build
artifacts. Add `-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0`
to the JVM flags in the entrypoint.

**Failure Mode 3: BuildKit cache miss on every run**
Symptom: Docker build takes 5+ minutes on every CI run. Logs show
dependencies being downloaded from Maven Central on every build.
Cause: Cache layer invalidated by early COPY of source files.
The gha cache is not configured, or the cache key changes too
frequently.
Diagnosis: run `docker build --no-cache` once and compare to
a cached run. If times are similar, caching is broken.
Fix: reorder Dockerfile (copy dependency manifests first), configure
`cache-from: type=gha` and `cache-to: type=gha,mode=max` in the
build-push-action, verify the gha cache is not being evicted.

---

### 🎯 Interview Deep-Dive

| Format | Time | Focus |
|--------|------|-------|
| Screener | 2 min | Describe CI Docker workflow + tagging |
| Panel | 8 min | Multi-stage builds + cache + security |
| Senior | 12 min | Registry security + SBOM + base image policy |

---

**Q1 (Definition): Why should Docker images be tagged with the
Git commit SHA rather than semantic versions or 'latest'?**

The commit SHA tag (`myapp:a3f5c2d`) is immutable by definition.
Once a Docker image is built from a specific commit, that SHA can
never refer to a different image. This immutability is the foundation
of reliable CI/CD.

Semantic version tags (`myapp:1.4.2`) are human-readable and
communicate release significance. They are useful as an alias but
should not be the primary deployment reference in production. If
the same version tag is pushed multiple times (a rebuild from the
same version number), the tag changes meaning and you lose
traceability.

The `latest` tag is always problematic in production contexts. It
changes on every new build. "Deploy latest" means "deploy whatever
was most recently built," which may include changes from multiple
unrelated PRs. You cannot reproduce the state from two weeks ago
by pulling `latest`. Two environments with `latest` may be running
different images simultaneously.

The commit SHA tag provides direct traceability: given a running
container, `kubectl describe pod | grep Image` shows the SHA tag.
Looking up that SHA in Git shows the exact commit, the author,
the PR, the test results, and the deployment approval. The complete
audit trail is derivable from the image tag.

The recommended practice: tag every image with the commit SHA
(primary, used in deployments), and optionally also tag with a
semantic version (secondary, for human discoverability). Never
use the semantic version tag in Kubernetes deployment specs - use
the SHA tag.

*What separates good from great:* Explaining the ECR immutability
setting. AWS ECR has a per-repository setting that prevents pushing
a new image to an existing tag. Enabling this enforces immutability
at the infrastructure level, not just by convention. Even if a
developer tries to overwrite a tag, the push fails.

---

**Q2 (Mechanism): How does a multi-stage Docker build work and
what are its security benefits?**

A multi-stage Docker build uses multiple `FROM` instructions in a
single Dockerfile. Each `FROM` starts a new stage. Artifacts from
earlier stages can be copied to later stages using `COPY --from=
stage-name`. The final image is the last stage - it does not include
any filesystem content from earlier stages, only what was explicitly
copied.

The canonical Java example has three stages. The dependency stage
copies only the build manifest and downloads dependencies - this
layer is expensive but cached. The build stage copies source code
and compiles the application. The runtime stage starts from a
minimal JRE base image and copies only the compiled JAR.

Security benefits:

First, attack surface reduction. The production image contains a
JRE, the application JAR, and minimal OS packages. It does not
contain Maven, the full JDK, source code, test files, or build
scripts. Every additional component is an additional attack vector.
Removing the JDK eliminates all JDK tools that an attacker could
use if they gained code execution in the container.

Second, elimination of build credentials. Maven authentication
tokens, npm tokens, and private registry credentials are often
needed during the build but must never be in the production image.
In a multi-stage build, these credentials exist only in the builder
stage. The final image has no record of them.

Third, explicit content. A single-stage build that runs `apt-get
install` for build tools makes those tools available in production.
A multi-stage build makes it explicit exactly what the production
image contains - only what was explicitly copied.

*What separates good from great:* Understanding that multi-stage
builds also enable using different base images for different stages.
The builder might use `eclipse-temurin:21-jdk-jammy`. The runtime
might use `gcr.io/distroless/java21-debian12` - a distroless image
with no shell, no package manager, and minimal OS. Distroless images
are the smallest and most secure runtime base available.

---

**Q3 (Scenario): How would you reduce a Docker image build time
from 8 minutes to under 1 minute in GitHub Actions?**

An 8-minute Docker build is almost always caused by cache misses on
the dependency download layer. Here is my systematic optimization:

Step 1: Enable BuildKit. Standard Docker builds do not support
cache mounts or GitHub Actions cache. BuildKit does.
```yaml
- uses: docker/setup-buildx-action@v3
```

> **Code walkthrough:** This Unknown example demonstrates YAML configuration pattern using container. **KEY MECHANISM:** YAML parsers are whitespace-sensitive; indentation errors cause silent value misinterpretation. **WHY IT MATTERS:** unquoted strings starting with special chars (*, &, ?, |) trigger YAML parser errors. **TAKEAWAY: quote strings containing YAML special chars; validate YAML before deploying to production.**

Step 2: Configure layer caching with GitHub Actions cache:
```yaml
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

> **Code walkthrough:** This Unknown example demonstrates YAML configuration pattern using container. **KEY MECHANISM:** YAML parsers are whitespace-sensitive; indentation errors cause silent value misinterpretation. **WHY IT MATTERS:** unquoted strings starting with special chars (*, &, ?, |) trigger YAML parser errors. **TAKEAWAY: quote strings containing YAML special chars; validate YAML before deploying to production.**

Step 3: Audit the Dockerfile for cache order. The dependency
download step must come before source code copying:
```dockerfile
# 1. Copy ONLY pom.xml (rarely changes)
COPY pom.xml .
# 2. Download dependencies (cached unless pom.xml changes)
RUN mvn dependency:resolve
# 3. Copy source code (changes on every commit)
COPY src/ src/
# 4. Compile (fast: dependencies are already cached)
RUN mvn package -DskipTests
```

> **Code walkthrough:** This 4. Compile (fast: dependencies are already cached) example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Step 4: Add a .dockerignore file. Without it, `COPY . .` includes
the entire git history, all test reports, and other files that
change on every run, busting the cache.

Result: on a cache hit (typical for 90% of commits), steps 1-2
are cache hits and take 10 seconds. Step 3-4 take 30-60 seconds.
Total: under 1 minute. On a cache miss (when pom.xml changes),
full build takes 3-4 minutes.

*What separates good from great:* Proposing pre-warming the cache
on schedule. A nightly workflow that builds the image on the main
branch warms the GitHub Actions layer cache. Monday morning builds
hit the cache from Friday's nightly build rather than starting cold.

---

**Q4 (Trade-off): What are the trade-offs of Kaniko vs Docker
daemon for building images in Kubernetes CI runners?**

This choice matters for teams running CI in Kubernetes pods rather
than on VMs.

Docker daemon in Kubernetes: requires the CI pod to mount the host's
Docker socket (`/var/run/docker.sock`). This is a critical security
risk - any pod that mounts the Docker socket has root access to the
host node because it can run privileged containers via Docker.
In security-conscious environments, this is a non-starter.

Kaniko runs entirely in user space, as an unprivileged container.
It reads the Dockerfile and builds the image layer by layer without
a Docker daemon, then pushes to the registry. No host socket needed.
Advantages: no security risk from socket mounting, works in any
Kubernetes environment, good layer caching support.
Disadvantages: slightly slower than BuildKit (no parallel layer
building), some Dockerfile features have compatibility gaps (though
these are rare).

DinD (Docker in Docker) is a middle ground: run a Docker daemon
inside the CI container rather than mounting the host socket. This
requires a privileged container, which is still a security concern
in shared clusters but less severe than socket mounting.

BuildKit daemon (as a separate pod): run BuildKit as a dedicated
daemon pod with `buildkitd`. CI pods connect to this remote BuildKit
daemon over TCP. This gives full BuildKit performance (parallel
builds, excellent caching) without socket mounting.

Recommendation: for Kubernetes-native CI in shared clusters, use
Kaniko. For dedicated CI nodes where Docker daemon is acceptable,
use BuildKit with GitHub Actions runners. Avoid Docker socket
mounting in shared Kubernetes clusters unconditionally.

*What separates good from great:* Mentioning that this is a security
vs. convenience trade-off with organizational risk tolerance as the
deciding factor. In PCI-DSS or SOC2 environments, Docker socket
mounting is likely a compliance violation.

---

**Q5 (Debugging): How do you investigate a Docker build that
produces different images on successive runs with the same
Dockerfile and source code?**

Non-deterministic Docker builds are a serious CI/CD reliability
problem. The root causes are nearly always one of a small set.

Step 1: Compare image digests. `docker inspect image1 image2`
shows the layer hashes. If any layer hash differs, identify which
Dockerfile instruction produced the different layer.

Step 2: Check for time-based non-determinism. Common causes:
`RUN apt-get update` fetches the latest package versions available
at build time. If package versions changed between builds, the
layer hash changes. Fix: pin package versions: `apt-get install
wget=1.21.2-1`.

Step 3: Check for wildcard file copies. `COPY target/*.jar /app.jar`
includes the file modification timestamp in the layer hash on some
Docker versions. Fix: use explicit file names: `COPY target/myapp-
1.0.jar /app.jar`.

Step 4: Check for dynamic content in build scripts. A build script
that embeds the current timestamp or the build machine hostname
in a configuration file will produce a different image on every run.
Fix: remove all time-dependent or machine-dependent content from
build-time operations.

Step 5: Check base image digest pinning. `FROM eclipse-temurin:21`
pulls the current SHA of that tag. If the base image was updated
between two builds, the base layer hash changes. Fix: pin to a
specific digest: `FROM eclipse-temurin:21@sha256:abc123...`.

The ultimate fix for reproducible builds: use Buildkit's
`--no-cache` mode for a reference build and compare digests with
a regular build. Reproducible builds require pinning everything:
base image digests, package versions, and build tool versions.

*What separates good from great:* Connecting this to supply chain
security. A Docker build that produces different images from the
same source on different CI runners is a reproducibility failure
that makes SBOM attestation meaningless. Reproducible builds are
a supply chain security best practice.

---

**Q6 (Deep Dive): How do you implement Docker image vulnerability
scanning in a CI pipeline and what CVE severity policy is
appropriate?**

Docker vulnerability scanning in CI involves scanning the built
image's layers for known CVEs in the OS packages and application
dependencies before it is pushed to the production registry.

Standard scanning tools: Trivy (Aqua Security, open source, fast),
Grype (Anchore, open source), Snyk Container (commercial), ECR
Enhanced Scanning (Amazon Inspector, AWS-native). All integrate
with GitHub Actions.

Implementation pattern:

{% raw %}
```yaml
- name: Scan image for vulnerabilities
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail CI on critical/high CVEs

- name: Upload scan results to GitHub Security
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: 'trivy-results.sarif'
```
{% endraw %}

> **Code walkthrough:** This 4. Compile (fast: dependencies are already cached) example demonstrates YAML configuration pattern. **KEY MECHANISM:** YAML parsers are whitespace-sensitive; indentation errors cause silent value misinterpretation. **WHY IT MATTERS:** unquoted strings starting with special chars (*, &, ?, |) trigger YAML parser errors. **TAKEAWAY: quote strings containing YAML special chars; validate YAML before deploying to production.**

The SARIF upload makes vulnerability results visible directly in
the PR's Security tab, linking findings to the specific files that
introduced them.

CVE severity policy design: the hardest question is where to draw
the line. Common policies:

Strict: block on CVSS >= 7.0 (High, Critical). Appropriate for
financial services, healthcare, public-facing services.

Moderate: block on CVSS >= 9.0 (Critical only). Appropriate for
internal tools, lower-risk services. Reduces false-positive
blocking.

Tiered: block on Critical immediately, block on High after 72-hour
grace period. Allows teams to respond to newly published CVEs
without immediate deployment disruption.

The false positive problem: many CVEs in OS packages affect code
paths not used by the application. Trivy supports `.trivyignore`
files with documented justification for suppressed CVEs - similar
to `// nolint` in Go. Suppression should require documentation of
why the CVE is not exploitable in the application's context.

*What separates good from great:* Separating the scanning gate from
the visibility mechanism. The scanning gate blocks promotion on high
severity CVEs. A separate reporting mechanism sends a weekly digest
of all medium/low CVEs to the security team. Both are important:
the gate prevents critical CVEs from reaching production; the report
tracks the organization's overall vulnerability posture.

---

**Q7 (Security): What are the security risks of running containers
as root and how do you prevent it?**

Running containers as root is one of the most common and most
impactful container security mistakes. Understanding the specific
risks and how they materialize in real attacks is essential.

Risk 1: Container breakout privilege escalation. If an attacker
achieves code execution inside a container running as root (via
a CVE in the application), and a container escape vulnerability
exists in the container runtime, the attacker gains root on the
host. Root in the container + container escape = root on the node.
Non-root in the container + container escape = limited user on the
node (much less dangerous).

Risk 2: Unnecessary capabilities. By default, Docker grants a set
of Linux capabilities to containers, even non-root ones. But root
containers retain additional capabilities. Dropping unnecessary
capabilities is easier to reason about for non-root users.

Risk 3: Volume mount access. A root container can read and write
any files in a bind-mounted host directory. A non-root container
in the same scenario is limited by Unix file permissions.

Mitigation in Dockerfile:
```dockerfile
# Create a dedicated non-root user
RUN useradd --uid 1001 --gid 1001 \
    --no-create-home appuser
# Set ownership on application files
COPY --chown=appuser:appuser target/app.jar /app.jar
# Switch to non-root user
USER appuser
```

> **Code walkthrough:** This Switch to non-root user example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Mitigation in Kubernetes:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  readOnlyRootFilesystem: true  # Further hardens
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```

> **Code walkthrough:** This Switch to non-root user example demonstrates YAML configuration pattern. **KEY MECHANISM:** YAML parsers are whitespace-sensitive; indentation errors cause silent value misinterpretation. **WHY IT MATTERS:** unquoted strings starting with special chars (*, &, ?, |) trigger YAML parser errors. **TAKEAWAY: quote strings containing YAML special chars; validate YAML before deploying to production.**

Enforcement: the Kubernetes `PodSecurity` admission controller can
be set to `Restricted` policy for namespaces, which automatically
blocks containers that run as root.

*What separates good from great:* Understanding that `runAsNonRoot`
in the Kubernetes SecurityContext is a runtime enforcement, but the
Dockerfile must also specify a non-root USER for the image to be
compliant. Both layers are needed. Hadolint (Dockerfile linter) will
flag a Dockerfile missing a `USER` instruction.

---

---

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


# Deployment Strategies - Blue-Green and Canary

🎯 Interview Weight: critical - deployment strategies are probed
in nearly every senior DevOps/SRE interview as they directly affect
availability, rollback speed, and risk.

---

### 🎯 Model Answer

**30 seconds:**
> Blue-green deployment maintains two identical environments: blue
> is production (live traffic), green is the new version (being
> validated). You test on green, then flip the load balancer to
> point all traffic to green instantly. Rollback is instant - flip
> back to blue. Canary deployment releases the new version to a small
> percentage of traffic (1-5%) first, monitors for errors, and
> gradually increases traffic if metrics look good. Canary catches
> real-world problems before full exposure.

**3 minutes (Senior):**
> Blue-green and canary are the two primary deployment strategies
> for zero-downtime production deployments, and they solve different
> problems.
>
> Blue-green provides an instant cutover and instant rollback. By
> maintaining a complete second environment, you can test the new
> version under real production conditions (same infrastructure,
> same configuration) before directing traffic to it. The rollback
> is load-balancer level - seconds, not minutes. The cost is running
> two full production environments simultaneously.
>
> Canary is more sophisticated: it gradually shifts production traffic
> from old to new, monitoring error rates, latency, and business
> metrics at each step. A problem that only manifests under real
> traffic (a specific user segment, a specific data pattern) is caught
> by the canary before it affects all users. Canary requires good
> observability - you need real-time metrics to make the
> "advance/rollback" decision. The trade-off: complexity. You need
> traffic splitting infrastructure and a decision mechanism.
>
> In Kubernetes, canary is commonly implemented via Argo Rollouts or
> Flagger, which integrate with service mesh (Istio) or ingress
> controllers for traffic splitting. Blue-green is simpler to
> implement manually: two Deployments, a Service that points to the
> active one, flipped by updating the Service selector.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* "The architectural question is whether your database
schema changes are compatible with both old and new application
versions simultaneously. Blue-green and canary both require backward-
compatible migrations during the transition period - a non-trivial
constraint that shapes how migrations are written."

*Adapting down:* "Blue-green: have two copies of production, test
on the new one, then switch traffic all at once. Canary: send a
little traffic to the new version first, watch for problems,
then send more."

**Blank Mind Recovery:**

**(1) Restate:** "Blue-green and canary - these are ways to deploy
new versions without taking the service down."

**(2) First principles:** "Deployments are risky. New code might
have bugs. You want to minimize user impact if there is a problem.
Both strategies limit exposure to the new version before you have
evidence it is working."

**(3) Bridge:** "Canary is named after the canary in a coal mine.
Miners sent a canary in first to detect dangerous gases. You send
a small percentage of traffic to the new version first to detect
dangerous bugs."

---

### 📘 Concept Explanation

**What it is:**
Blue-green and canary are zero-downtime deployment strategies that
manage the risk of production releases by controlling when and how
users are exposed to new application versions.

Blue-green deployment maintains two complete, identical production
environments. At any time, one is live (blue) and the other is idle
(green). New versions deploy to the idle environment, and traffic
switches via load balancer cutover.

Canary deployment routes a small initial percentage of production
traffic (1-5%) to the new version, monitors for degraded behavior,
and progressively increases the percentage to 100% if metrics remain
healthy.

**The problem it solves:**
Traditional "big bang" deployments (take the service down, deploy
new version, bring it back up) have two problems: downtime (users
experience unavailability) and slow rollback (reversing requires
another deployment cycle). Blue-green and canary address both.

**How it works:**

**Blue-green in Kubernetes:**
```
Blue Deployment (current/stable) ← Service selector: version=blue
Green Deployment (new/candidate)

1. Deploy Green alongside Blue (both running simultaneously)
2. Test Green directly (by port-forward or direct endpoint)
3. Validate health, run smoke tests
4. Cutover: update Service selector to version=green
5. Blue remains running for instant rollback
6. After validation period, delete Blue
```

> **Code walkthrough:** This Blue-Green and Canary example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Canary in Kubernetes with Argo Rollouts:**
```
Traffic split:
  - 95% → Stable (old version)
  - 5%  → Canary (new version)

Analysis:
  - Monitor error rate, latency, business metrics
  - If metrics healthy after 10 minutes: advance to 20%
  - If metrics degraded: pause or rollback

Progression: 5% → 20% → 50% → 80% → 100%
Each step: wait N minutes, analyze metrics, auto-advance or pause
```

> **Code walkthrough:** This Blue-Green and Canary example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Database migration compatibility requirement:**
Both strategies require the new application version to be able to
run alongside the old version during the transition. This means:
- Database migrations must add columns (not remove)
- New columns must be nullable or have defaults
- Old column removal happens in a separate later deployment
- API changes must be backward-compatible during the transition

**The key insight:**
These strategies are not about deployment mechanics - they are about
risk management. The question they answer is: "How quickly can we
detect and reverse a bad deployment?" Blue-green: seconds (instant
rollback). Canary: minutes (automated rollback on metric thresholds).

**When to use it:**
Blue-green: for services where instant rollback is critical (payment
systems, authentication services). Simple to reason about, clear
cutover moment.
Canary: for high-traffic services where a subtle bug (incorrect
calculation, edge-case error) might only appear for a specific user
segment. Better risk management at the cost of complexity.

**When NOT to use it:**
Batch jobs or queue processors that are stateful are harder to
blue-green (two versions simultaneously processing the same queue
may cause duplication). Databases do not support blue-green directly.
Services with session affinity (users are stuck to a server) require
special handling in blue-green.

**Alternatives:**
- Rolling update (Kubernetes default): replace pods one at a time.
  Simple, no extra infrastructure. Rollback is slow (another rolling
  update in reverse). No traffic control.
- Feature flags: decouple deployment from feature release. Deploy
  the new code everywhere but only enable it for a small percentage
  of users via a flag. Canary at the application level.

**First-principles derivation:**
Risk = probability of failure × impact of failure. Deployment
risk is proportional to: the size of the change, the untested
conditions in production, and the rollback time. Blue-green and
canary both reduce impact: blue-green by enabling instant rollback,
canary by limiting initial user exposure. Both are valid risk
reduction strategies with different profiles.

---

### 💻 Code Example

**BAD: Naive rolling deployment with no rollback strategy**

```yaml
# No strategy configuration = default rolling update
# Default strategy has serious problems for production:
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 5
  # No strategy configured - defaults to:
  # maxSurge: 25%, maxUnavailable: 25%
  # This means: 1-2 old pods are terminated before new pods
  # are verified healthy. Brief availability reduction.
  # Rollback is another rolling update = minutes, not seconds.
  # No traffic control during rollout.
  template:
    spec:
      containers:
        - name: myapp
          image: myapp:latest  # Also wrong - mutable tag
          # No readinessProbe = traffic sent to unhealthy pods
```

> **Code walkthrough:** Default rolling deployments have threeice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> production-dangerous properties. The `maxUnavailable: 25%` setting
> terminates old pods before replacement pods are healthy, creating
> brief capacity reduction under load. No `readinessProbe` means
> Kubernetes cannot know when the new pod is ready to serve traffic
> - it starts sending requests immediately on container start, when
> the JVM is still warming up. And the mutable `latest` tag means
> you cannot determine what code is actually running.

**GOOD: Blue-green with Kubernetes Service selector cutover**

```yaml
# Blue Deployment (current stable version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
  labels:
    app: myapp
    version: blue
spec:
  replicas: 5
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
        - name: myapp
          image: myregistry/myapp:a3f5c2d  # Immutable tag
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8080
            initialDelaySeconds: 20
            periodSeconds: 5
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
---
# Production Service - currently pointing to Blue
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
    version: blue  # ← CHANGE THIS FOR CUTOVER
  ports:
    - port: 80
      targetPort: 8080
---
# Green Deployment (new version being deployed)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
  labels:
    app: myapp
    version: green
spec:
  replicas: 5
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
        - name: myapp
          image: myregistry/myapp:b4g6d8f  # New version tag
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8080
            initialDelaySeconds: 20
            periodSeconds: 5
```

> **Code walkthrough:** This Green Deployment (new version being deployed) example demonstrates YAML configuration pattern using SQL. **KEY MECHANISM:** YAML parsers are whitespace-sensitive; indentation errors cause silent value misinterpretation. **WHY IT MATTERS:** unquoted strings starting with special chars (*, &, ?, |) trigger YAML parser errors. **TAKEAWAY: quote strings containing YAML special chars; validate YAML before deploying to production.**

```bash
#!/bin/bash
# blue-green-cutover.sh

set -euo pipefail

NAMESPACE="production"
SERVICE="myapp"
NEW_VERSION="green"  # or "blue" for rollback
NEW_IMAGE="myregistry/myapp:b4g6d8f"

echo "=== Blue-Green Deployment Cutover ==="
echo "Target version: ${NEW_VERSION}"
echo "Target image: ${NEW_IMAGE}"

# Step 1: Verify new version is healthy (all pods ready)
echo "Verifying ${NEW_VERSION} deployment health..."
kubectl rollout status deployment/myapp-${NEW_VERSION} \
  -n ${NAMESPACE} --timeout=300s

# Step 2: Run pre-cutover smoke tests against new version
# (direct port-forward, not via Service)
echo "Running pre-cutover smoke tests..."
kubectl port-forward deployment/myapp-${NEW_VERSION} 8081:8080 \
  -n ${NAMESPACE} &
PF_PID=$!
sleep 2
curl -f http://localhost:8081/actuator/health
kill ${PF_PID}

# Step 3: Instant traffic cutover (atomic operation)
echo "Cutting over traffic to ${NEW_VERSION}..."
kubectl patch service ${SERVICE} \
  -n ${NAMESPACE} \
  -p "{\"spec\":{\"selector\":{\"version\":\"${NEW_VERSION}\"}}}"

echo "Cutover complete. Monitoring for 5 minutes..."
sleep 300

# Step 4: Check error rate post-cutover (placeholder)
ERROR_RATE=$(curl -s prometheus:9090/api/v1/query?query=\
  'rate(http_requests_total{status=~"5.."}[5m])' | \
  jq '.data.result[0].value[1]')

if (( $(echo "${ERROR_RATE} > 0.01" | bc -l) )); then
  echo "ERROR: Error rate elevated. Rolling back..."
  kubectl patch service ${SERVICE} \
    -n ${NAMESPACE} \
    -p "{\"spec\":{\"selector\":{\"version\":\"blue\"}}}"
  exit 1
fi

echo "Deployment successful. Old version remains for rollback."
```

> **Code walkthrough:** The blue-green implementation has twoice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> Kubernetes Deployments running simultaneously, each with a distinct
> `version` label. The Service selector determines which version
> receives traffic. The cutover script is a `kubectl patch` on the
> Service - atomic and instantaneous. All pods in the green deployment
> have readiness probes, ensuring Kubernetes waits until they are
> truly ready before the Service starts routing to them. The 5-minute
> post-cutover monitoring window catches error rate spikes before
> the blue deployment is torn down. Rollback is the same `patch`
> command pointing back to `blue` - executes in under 5 seconds.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> "Blue-green keeps two identical environments. You deploy to the
> inactive one (green), test it, then switch the load balancer so
> all traffic goes to green. Rollback is switching back to blue.
> Canary sends a small percentage of traffic to the new version
> first - if errors increase, you roll back. If everything looks
> good, you increase the percentage."

*Push deeper:* "The main thing I learned about these strategies
is that they require your database schema changes to be backward-
compatible with both versions running at once. I once had to redo
a migration because it dropped a column that the old version still
needed during the blue-green transition."

---

**Senior / Staff (5+ years):**
> "I use blue-green for services where instant rollback is critical
> - authentication, payment processing, anything where a bad
> deployment could cause a revenue-impacting outage. The Service
> selector cutover in Kubernetes takes 5 seconds. That is the
> rollback time.
>
> For high-traffic services with subtle feature bugs (incorrect
> business logic that only manifests for a specific user segment),
> I prefer canary with Argo Rollouts. The automated analysis step
> queries Prometheus for error rate and latency. If p99 latency
> increases above the baseline during the canary phase, the rollout
> is automatically paused or rolled back.
>
> The database compatibility requirement is the constraint that
> teams consistently underestimate. Blue-green and canary both
> require the ability to run old and new code against the same
> database simultaneously. This means expand-contract migrations:
> step 1 adds the new column (backward compatible), step 2 deploys
> new code that writes to both old and new, step 3 backfills, step
> 4 deploys code that only uses new, step 5 drops the old. A blue-
> green deployment cannot skip steps."

*Push deeper:* "At the staff level, I care about the organizational
alignment around deployment strategy. If the strategy is canary
with automated analysis, someone must own the metric definitions.
What constitutes 'healthy' for this service? Error rate? Latency?
A business metric like order completion rate? Defining the analysis
metrics is a product + engineering decision, not just an ops decision."

---

### ⚖️ Comparison Table

| Strategy | Rollback Time | Infrastructure Cost | Traffic Control | Complexity | Best For |
|----------|--------------|---------------------|-----------------|------------|----------|
| Rolling Update | Minutes | 1x | None | Low | Simple services, stateless |
| Blue-Green | Seconds | 2x | All-at-once | Medium | Stateless services needing instant rollback |
| Canary | Minutes (auto) | ~1.1x | Fine-grained % | High | High-traffic, subtle-bug detection |
| Feature Flags | Seconds (flag flip) | 1x | Fine-grained (users) | Medium | Feature decoupling, A/B testing |

**The deciding factor:**
Choose blue-green for services where instant rollback (seconds)
is non-negotiable. Choose canary for services with high traffic
where production testing under real load matters. Use rolling update
for internal tools or services tolerant of brief rollback latency.

---

### ⚠️ Common Misconceptions

**Misconception 1: Blue-green deployment requires permanently running double the infrastructure.**

The idle (non-active) environment only needs to run during the deployment window. After traffic cutover is confirmed stable (typically 15-30 minutes), the old environment can be scaled to zero. Cost is only doubled during the deployment window itself. Modern cloud environments make this instant - scale the green environment up before deployment, scale the blue environment down after validation.

**Misconception 2: Canary deployments are only valuable for high-traffic services.**

Canary analysis is equally valuable for low-traffic services where a bug would affect 100% of a small user base. The key is using RELATIVE traffic split (e.g., 5% canary), not absolute request count. Even at 10 requests/minute total, routing 1 request/minute to canary catches most regression patterns within 30-60 minutes.

**Misconception 3: Blue-green rollback is instant and without risk.**

Switching the load balancer pointer back IS instant, but the risk lies in shared state. If the green deployment wrote to the database using a new schema, rolling back to blue may cause blue to encounter incompatible data. Any deployment touching the data layer requires backward-compatible migrations first, making the database the real gating concern - not the application deployment itself.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Database migration incompatibility during
blue-green cutover**
Symptom: After cutover from blue to green, blue instances start
logging database errors. Old pods (still running for potential
rollback) are accessing columns or tables that the new migration
removed.
Cause: Migration dropped a column before old application version
was fully retired.
Fix: always use expand-contract migration pattern. New column
is added, but old column stays until the old version is fully
retired. Validate backward compatibility in staging with both
versions running simultaneously.

**Failure Mode 2: Canary stuck at low traffic percentage**
Symptom: Argo Rollouts shows the rollout paused at 5% for hours.
The analysis step shows no data or inconclusive results.
Cause: Analysis metrics are not configured correctly. Prometheus
query returns no results because the metric name changed, or the
service does not have enough traffic at 5% to reach statistical
significance.
Diagnosis: `kubectl argo rollouts get rollout myapp` shows the
analysis state. `kubectl argo rollouts logs myapp` shows the
analysis run output.
Fix: verify Prometheus queries return data in the Prometheus UI
before configuring them in Argo Rollouts. Set minimum traffic
thresholds for the analysis step to handle low-traffic services.

**Failure Mode 3: Blue-green cutover causes session loss**
Symptom: After blue-green cutover, users see authentication
errors or lose their shopping cart contents.
Cause: Sessions were stored in application memory (not in Redis or
a shared session store). When traffic moved from blue to green,
the green instances had no knowledge of existing sessions.
Fix: sessions must be stored externally (Redis, database) for
blue-green to work correctly. Any stateful data that must persist
across the cutover must be in a shared store, not in-memory.

---

### 🎯 Interview Deep-Dive

| Format | Time | Focus |
|--------|------|-------|
| Screener | 2 min | Define blue-green vs canary + use cases |
| Panel | 8 min | Trade-offs + database compatibility + Kubernetes |
| Senior | 12 min | Automated analysis + failure recovery + cost |

---

**Q1 (Definition): What is the difference between blue-green and
canary deployment? When would you choose each?**

Blue-green and canary are both zero-downtime deployment strategies
that differ primarily in how they expose users to the new version.

Blue-green maintains two complete environments. At any time, one
(blue) serves 100% of production traffic. The new version is deployed
to the idle environment (green). You validate green in isolation,
then perform an instant, all-or-nothing traffic cutover by updating
the load balancer. Rollback is equally instant: flip traffic back
to blue. The cost is 2x infrastructure during the deployment period.

Canary routes a small initial percentage of production traffic (1-5%)
to the new version while the rest continues on the old version. You
monitor the canary's behavior under real traffic, and if metrics
remain healthy, you progressively increase the percentage (5% → 20%
→ 50% → 100%). If metrics degrade, the rollout automatically pauses
or rolls back. The infrastructure cost is minimal (a few extra pods).

When to choose blue-green: when you need instant, guaranteed rollback
(seconds). For high-value transactional services (payment processing,
authentication). When the deployment is infrequent and the 2x
infrastructure cost during deployment is acceptable.

When to choose canary: when you have high traffic volume where a bug
might only affect a specific user segment. When you want production
validation under real traffic before full exposure. When you have
automated metric analysis infrastructure (Prometheus + Argo Rollouts).

The situations where neither is appropriate: state-heavy services
that store data in the application process (sessions, caches) where
running two versions simultaneously creates consistency problems
(though the solution is to fix the state problem, not abandon
progressive deployment strategies).

*What separates good from great:* Understanding that the choice is
also organizational. Blue-green is simpler to understand and operate.
Canary requires metric definition, analysis configuration, and
operational knowledge of the progressive delivery toolchain. A team
new to progressive delivery should start with blue-green before
attempting canary.

---

**Q2 (Mechanism): How does Argo Rollouts implement canary deployment
in Kubernetes?**

Argo Rollouts is a Kubernetes controller that extends the standard
Deployment resource with advanced deployment strategies including
canary and blue-green.

The `Rollout` resource replaces the standard `Deployment` and adds
a `strategy` field:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      steps:
        - setWeight: 5    # 5% to canary
        - pause: {duration: 10m}
        - analysis:
            templates:
              - templateName: success-rate
            args:
              - name: service-name
                value: myapp-canary
        - setWeight: 20   # 20% to canary
        - pause: {duration: 10m}
        - setWeight: 50
        - pause: {duration: 10m}
        - setWeight: 80
```

> **Code walkthrough:** This Unknown example demonstrates YAML configuration pattern. **KEY MECHANISM:** YAML parsers are whitespace-sensitive; indentation errors cause silent value misinterpretation. **WHY IT MATTERS:** unquoted strings starting with special chars (*, &, ?, |) trigger YAML parser errors. **TAKEAWAY: quote strings containing YAML special chars; validate YAML before deploying to production.**

Traffic splitting: Argo Rollouts works with Ingress controllers
(Nginx, Traefik) and service meshes (Istio, Linkerd) to split
traffic at the specified percentages. With Istio, a VirtualService
is updated to route the configured percentage to the canary pods.

Analysis templates define the Prometheus queries that determine
success or failure:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
spec:
  metrics:
    - name: success-rate
      interval: 1m
      successCondition: result[0] >= 0.99
      provider:
        prometheus:
          query: |
            sum(rate(http_requests_total{
              app="myapp",
              status!~"5.*"
            }[5m])) /
            sum(rate(http_requests_total{
              app="myapp"
            }[5m]))
```

> **Code walkthrough:** This Unknown example demonstrates YAML configuration pattern. **KEY MECHANISM:** YAML parsers are whitespace-sensitive; indentation errors cause silent value misinterpretation. **WHY IT MATTERS:** unquoted strings starting with special chars (*, &, ?, |) trigger YAML parser errors. **TAKEAWAY: quote strings containing YAML special chars; validate YAML before deploying to production.**

If the success rate falls below 99%, the analysis fails, the rollout
pauses, and the operator (or automation) decides whether to rollback.

*What separates good from great:* Understanding that Argo Rollouts
also provides a preview service that gives direct access to the
canary pods without traffic splitting - enabling testing of the new
version in production infrastructure before routing any real user
traffic to it.

---

**Q3 (Scenario): During a canary deployment to 10% traffic, you
notice a 20% increase in checkout errors. What do you do?**

This is a real production scenario that tests incident response
judgment. A 20% increase in checkout errors during a canary is
a signal, but the response depends on context.

Immediate action: pause the rollout. In Argo Rollouts: `kubectl
argo rollouts pause rollout/myapp`. This stops the progression to
higher traffic percentages while I investigate. Do NOT roll back
yet - I need information first.

Investigation steps:

Step 1: Correlate the error spike with the canary deployment timing.
Was the error rate increase exactly concurrent with the canary
starting? Or did it predate the deployment? Check Prometheus for
the exact timestamp of the spike vs. the deployment timestamp.

Step 2: Are the errors exclusively from canary pods? In Argo Rollouts
with Istio, metrics can be split by `app.kubernetes.io/version` label
to see whether errors are from canary pods only or from all pods.
If stable pods have the same error rate, the deployment is not the
cause.

Step 3: Examine error logs from canary pods. `kubectl logs -l
version=canary --tail=100` - what type of errors are occurring?
NullPointerExceptions? Database connection errors? Business logic
validation failures?

Step 4: Check external dependencies. Was there a database slowdown,
a third-party API outage, or a cache flush at the same time?

Decision matrix:
- Errors are exclusively from canary pods + caused by new code:
  rollback immediately
- Errors are from all pods + caused by external dependency: monitor,
  not a deployment issue
- Errors from canary only + unclear cause: keep paused, investigate
  with debug logs

Rollback command: `kubectl argo rollouts abort rollout/myapp` -
sends 100% traffic back to stable.

*What separates good from great:* Not panic-rolling back without
investigation. A premature rollback is also disruptive and destroys
the evidence in the canary logs. The structured approach - pause,
investigate, decide - is the professional response.

---

**Q4 (Trade-off): What are the database migration constraints
imposed by blue-green and canary deployments?**

Database migration compatibility is the most overlooked constraint
in progressive deployment strategies. Both blue-green and canary
require the ability to run old and new application code against the
same database simultaneously.

The problem: during a blue-green deployment, both the blue (old)
and green (new) versions are potentially reading and writing to the
same database. During canary, the stable (old) and canary (new)
pods are doing the same. If a migration adds a column that the old
version does not know about, the old version might fail to insert
rows or might set the column to null in violation of a NOT NULL
constraint.

The expand-contract pattern solves this:

Phase 1 (Expand): add new column as nullable. Both old and new code
can run simultaneously. Old code ignores the new column. New code
starts writing to it.

Phase 2 (Migrate): after the new version is at 100% traffic, backfill
existing rows in the new column. This can be a background job.

Phase 3 (Contract): after all old versions are retired, tighten
the constraint (add NOT NULL) and remove the old column that is no
longer needed.

Specific migration incompatibilities to avoid:
- Dropping a column while old code still reads it
- Renaming a column without alias support in both versions
- Changing a column type in ways that are not backward-compatible
- Adding a NOT NULL constraint to a new column before old code stops
  writing null values

Tools that help: Flyway's `BASELINE` and `UNDO` concepts, Liquibase
`rollback` commands, and the `spring.flyway.validate-migration-
naming` setting. Frameworks that enforce additive migrations.

*What separates good from great:* Articulating that this constraint
shapes how teams write migrations in general, not just for blue-
green/canary deployments. Teams that routinely use additive-only
migrations develop the discipline that makes progressive deployment
strategies work.

---

**Q5 (Debugging): How do you diagnose a blue-green deployment
where the new version is unhealthy after cutover?**

A blue-green deployment where green becomes unhealthy after cutover
is one of the most stressful production scenarios. The response
must be fast and structured.

Step 1: Rollback immediately. The rollback command (`kubectl patch
service myapp -p '{"spec":{"selector":{"version":"blue"}}}'`) is
the first action, not the last. Blue is verified healthy - restoring
traffic to it is always safe. This limits user impact while I
investigate. Total time: 5 seconds.

Step 2: After rollback, preserve the green deployment for investigation.
Do not delete it immediately - the logs and state are evidence.

Step 3: Investigate what failed. Common causes:
- Green pods are not healthy (all pods crashing, failing readiness
  probe): check pod logs: `kubectl logs -l version=green --tail=200`
- Green works for some requests but not others: check for specific
  error patterns (500 errors on certain endpoints, specific user
  segments affected)
- Database compatibility issue (Step 1 should have caught this in
  pre-cutover smoke tests, but missed cases do occur)

Step 4: Reproduce in staging. If the problem is reproducible in
staging, it can be investigated and fixed safely.

Step 5: After identifying and fixing the root cause in green, redeploy
the fixed green version. Run pre-cutover smoke tests more thoroughly
this time. Retry the cutover.

Post-incident: add a test or monitoring check that would have caught
the failure in pre-cutover validation. Every production incident
should make the next deployment safer.

*What separates good from great:* Having a practiced rollback
procedure that does not require on-call heroics. The team should be
able to execute the rollback in under 30 seconds from detection.
This requires runbooks, practiced drills, and clear ownership.

---

**Q6 (Deep Dive): How do feature flags complement progressive
deployment strategies?**

Feature flags and progressive deployment strategies (blue-green,
canary) solve related but different problems, and they work
powerfully in combination.

Progressive deployment strategies (blue-green, canary) address
infrastructure-level risk: the risk that a new deployment is unstable,
has performance issues, or crashes. They work at the deployment unit
level - a Docker image, a Kubernetes Deployment.

Feature flags address feature-level risk: the risk that a new business
feature has unexpected user impact, performs poorly for a specific
segment, or contains a business logic error. They work at the code
level - a conditional statement that enables or disables a code path
based on runtime configuration.

The combination is powerful because they operate independently:
You can deploy new code with a feature flag disabled (no user impact),
enable the flag for a small beta user segment (canary at the user
level), monitor, and gradually expand the rollout. Meanwhile, the
infrastructure deployment itself can be managed with blue-green for
independent, instant infrastructure rollback.

This separation enables two independent rollback mechanisms:
1. Infrastructure rollback (blue-green): rolls back the entire
   deployment. Effective for crashes, performance degradation.
2. Feature flag rollback (feature off): disables the specific
   feature. Effective for business logic errors that only affect
   users using the new feature.

Feature flag infrastructure: LaunchDarkly, Split.io, Unleash
(open source), and AWS AppConfig are the common choices. They
support targeting (enable for specific user IDs, email domains,
percentages, geographic regions), real-time updates (no deployment
needed to change flag state), and A/B testing integration.

*What separates good from great:* Understanding the maintenance
burden of feature flags. A codebase with 200 live feature flags
is a tangled mess of conditionals. Every feature flag should have
a removal date - once the feature is fully rolled out, the flag
is removed from the code in the next sprint. "Temporary" feature
flags that become permanent are a code quality problem.

---

**Q7 (Trade-off): What are the cost implications of blue-green
deployment in a cloud environment?**

The cost implication of blue-green is the most common objection
to adopting it, and it is worth addressing precisely.

The direct cost: blue-green requires running two full production
environments simultaneously during the deployment period. For a
service with 10 pods running at $0.10/hour each, running 20 pods
during a deployment that takes 2 hours costs $2 extra. This is
negligible.

For services with heavy database instances or expensive node types,
the math changes. A deployment of a database-backed service where
the "environment" includes a $500/month RDS instance would cost $33
for a 2-hour blue-green window. Still manageable.

The more realistic cost concern: if the team treats blue-green as
"always have two full environments running" rather than "run two
environments only during the deployment window," the cost doubles
permanently. This is a process misunderstanding, not an inherent
cost of blue-green.

Optimization strategies:
- Use Kubernetes labels and a single shared infrastructure: both
  blue and green are Deployments in the same cluster, same namespace.
  The "two environments" are just two Deployment objects with
  different labels. Total overhead: the new version's pods running
  during the validation window.
- Scale down (but do not delete) the old environment after cutover
  validation: `kubectl scale deployment myapp-blue --replicas=0`.
  Blue is still recoverable (scale back up) but not costing money.
  Full deletion can happen after 24 hours of stable production.

The comparison: compare blue-green cost to incident cost. One
30-minute production outage requiring a slow rollback at $5,000/
minute in lost revenue costs $150,000. The blue-green overhead
for a year of deployments is tens of dollars.

*What separates good from great:* Framing the cost conversation
correctly. The relevant comparison is not "cost of blue-green vs.
rolling update" but "cost of blue-green overhead vs. cost of slow
rollback in the incident it prevents."

---

**Q8 (Behavioral): Tell me about a time a deployment strategy
prevented or minimized a production incident.**

I was on a team deploying a new pricing calculation feature to our
B2B SaaS platform. The new feature changed how multi-user discounts
were applied. We used canary deployment via Argo Rollouts, starting
at 5% traffic.

At 5%, the canary analysis step triggered: our business metric -
order value per transaction - dropped by 8% on canary pods. No
errors. No latency increase. The standard engineering metrics (error
rate, latency) looked fine. But we had configured a business metric
analysis that showed revenue per order was lower on canary pods.

We paused the rollout immediately and investigated the canary logs.
The bug: the new discount calculation was applying the discount to
the subtotal before tax rather than after, resulting in larger
discounts than intended on orders in certain tax jurisdictions. No
error was thrown - it was silently producing wrong outputs.

Had we deployed with a rolling update (no canary), this bug would
have reached 100% of traffic before anyone noticed. Our customers
would have received incorrectly priced invoices. The correction
would have required issuing credit notes and explaining the error
to enterprise customers - a significant customer trust issue.

At 5% canary traffic, approximately 5% of orders for that day had
the wrong calculation. We could identify the exact orders, correct
them, and communicate proactively before most customers even saw
the invoice.

The lesson I learned: business metric analysis in canary deployments
catches bugs that engineering metrics miss. A bug that silently
produces wrong numbers is invisible to error rates and latency.
Configure canary analysis to include business metrics, not just
infrastructure metrics.

*What separates good from great:* Articulating that the canary
strategy's value was not just in detecting the bug but in limiting
its blast radius. The architecture decision (canary + business
metric analysis) made the difference between a minor correctable
error and a major customer trust incident.

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



