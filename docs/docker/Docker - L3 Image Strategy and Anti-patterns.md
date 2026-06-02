---
layout: default
title: "Docker - L3 Image Strategy and Anti-patterns"
parent: "Docker"
nav_order: 8
permalink: /docker/l3-image-strategy-and-anti-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Docker - L3 Image Strategy and Anti-patterns](#docker---l3-image-strategy-and-anti-patterns) | medium |

---

# Docker - L3 Image Strategy and Anti-patterns

## Image Tagging and Versioning Strategy

---

### 🎯 Model Answer

**30 seconds:**
> Image tags are mutable pointers to image digests. `myapp:latest`
> can point to different images over time. Production rule: never
> deploy by tag alone. Deploy by digest (`myapp@sha256:abc123`) or
> by an immutable semantic version tag that is never overwritten.
> Strategy: `myapp:1.2.3` (SemVer, immutable), `myapp:1.2` (minor
> float, updated on patch), `myapp:latest` (CI convenience, never
> use in production manifests).

**3 minutes (Senior):**
> Three-tier tagging: (1) **Immutable (SemVer)**: `myapp:1.2.3`.
> Once pushed: never overwritten. Required for production deployments.
> `docker push myapp:1.2.3` blocked if tag already exists (registry
> policy). Enables rollback: `kubectl set image deployment myapp
> myapp=myapp:1.2.2`. (2) **Floating (channel)**: `myapp:1.2`,
> `myapp:1`, `myapp:stable`. Updated on each release. Used for
> non-critical dependencies that want to auto-receive patches.
> (3) **CI convenience**: `myapp:latest`, `myapp:main`, `myapp:
> commit-${SHA}`. Used internally in CI to identify recent builds.
> Never used in production Kubernetes manifests. Commit SHA tags
> (`myapp:a1b2c3d`): immutable in practice (a commit hash never
> changes), good for tracing which code is deployed. (4) **Registry
> policies**: enforce immutability at the registry level. ECR:
> enable "image tag mutability: IMMUTABLE" for production repositories.
> GCR/Artifact Registry: IAM policies that prevent tag overwrites.
> Result: even if CI accidentally tries to push the same tag twice:
> the registry rejects it. (5) **Digest-based deployment**: the
> most reliable. K8s manifest: `image: myapp@sha256:abc...`. The
> digest is stable and unique regardless of tag. This is what
> production should use.

**Blank Mind Recovery:**

**(1) Restate:** "Tags are mutable. Use SemVer immutable tags for
production. Float minor/patch tags for channel subscribers. latest:
CI only. Commit SHA tag: immutable in practice. Registry: enforce
immutability to prevent accidental overwrites. K8s: use digest or
exact SemVer tag."

**(2) First principles:** "A tag is a bookmark. Bookmarks can move.
A digest is the content's fingerprint. It cannot change. Deploy by
fingerprint: you always get exactly what you tested."

**(3) Bridge:** "Image tags are like music album versions. `latest`:
the current front-of-shelf record (changes as new albums come out).
`1.2.3`: the specific pressing from that date (vinyl collectors
never confuse editions). Digest: the content fingerprint (identical
bytes always). Deploy from the vinyl catalog number, not the shelf
label."

---

### 📘 Concept Explanation

**Tag semantics, SemVer strategy, registry immutability, digest deployment:**

```
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

{% raw %}
```
TAG SEMANTICS:

  # Tags are mutable references:
  docker pull myapp:latest    # pulls current "latest" image
  docker push myapp:latest    # moves "latest" to a new image
  # Tomorrow: docker pull myapp:latest gets a different image.
  # No error. No warning. Silent.
  
  # Digest is immutable:
  docker pull myapp@sha256:a1b2c3d4...
  # Always this exact image. Forever.
  # Even if the image is overwritten by tag, the digest still works.
  
  # Get the digest of an image:
  docker inspect myapp:1.2.3 --format '{{.RepoDigests}}'
  # ["myapp@sha256:a1b2c3d4e5f6..."]
  
  # Or from the registry after push:
  docker push myapp:1.2.3
  # Output includes: "sha256: a1b2c3d4e5f6..."

THREE-TIER TAGGING STRATEGY:

  # Given: new release of version 1.2.3
  
  # Tier 1: Immutable SemVer (production):
  docker tag myapp:build-123 myapp:1.2.3
  docker push myapp:1.2.3   # once. NEVER overwrites.
  
  # Tier 2: Floating channel (optional):
  docker tag myapp:1.2.3 myapp:1.2  # patch float
  docker tag myapp:1.2.3 myapp:1    # minor float
  docker push myapp:1.2             # points to 1.2.3 now
  docker push myapp:1               # points to 1.2.3 now
  
  # When 1.2.4 releases:
  docker tag myapp:1.2.4 myapp:1.2  # 1.2 now points to 1.2.4
  docker tag myapp:1.2.4 myapp:1    # 1 now points to 1.2.4
  # docker tag myapp:1.2.4 myapp:1.2.3  -> BLOCKED by registry policy
  
  # Tier 3: CI convenience (internal CI pipelines only):
  docker tag myapp:build-123 myapp:latest  # moves on every build
  docker tag myapp:build-123 myapp:main-a1b2c3d  # commit SHA
  
  # Git tag-based tagging in CI (GitHub Actions):
  on:
    push:
      tags:
        - 'v*.*.*'
  
  jobs:
    build:
      steps:
        - name: Build and push
          uses: docker/build-push-action@v5
          with:
            tags: |
              myapp:${{ github.ref_name }}       # v1.2.3
              myapp:latest
            # Automatically tags with the git tag and latest.

REGISTRY IMMUTABILITY ENFORCEMENT:

  # AWS ECR: enable immutable tags:
  aws ecr put-image-tag-mutability \
    --repository-name myapp \
    --image-tag-mutability IMMUTABLE
  # Now: pushing to an existing tag returns:
  # "ImageTagAlreadyExistsException"
  
  # Google Artifact Registry: use IAM to prevent overwrites.
  # DockerHub: paid plans can protect specific tags.
  
  # Policy: production repositories = IMMUTABLE.
  # Dev/staging repositories = MUTABLE (ok to overwrite latest).
  
  # When is overwrting OK?
  # - "latest" tag in dev/CI environments.
  # - Image signing: rebuilding with same content for security scan.
  # When is overwriting NEVER OK?
  # - Any tag referenced in a production Kubernetes manifest.
  # - SemVer release tags (1.2.3).

KUBERNETES DEPLOYMENT BEST PRACTICE:

  # BAD: mutable tag in manifest:
  spec:
    containers:
      - image: myapp:latest
      # "latest" changes. Pods restarted: may get different version.
      # Also: imagePullPolicy defaults to "Always" for latest.
      # Continuous pull overhead.
  
  # GOOD: immutable reference:
  spec:
    containers:
      - image: myapp:1.2.3  # or by digest:
      - image: myapp@sha256:a1b2c3d4e5f6...
      imagePullPolicy: IfNotPresent  # don't re-pull same digest
  # Rollback: kubectl set image deployment/myapp myapp=myapp:1.2.2
  
  # Why digest over SemVer tag?
  # A SemVer tag can theoretically be overwritten (human error).
  # A digest cannot. Maximum safety: use digest.
  # Tooling (Flux, ArgoCD): can auto-update digest in GitOps manifests.

IMAGE RETENTION POLICIES:

  # Old images accumulate in registry. Must clean up.
  
  # ECR lifecycle policy: keep only last 10 production tags:
  {
    "rules": [{
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["v"],
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {"type": "expire"}
    }]
  }
  
  # Keep untagged (intermediate) images for only 1 day:
  {
    "rules": [{
      "rulePriority": 2,
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {"type": "expire"}
    }]
  }
```
{% endraw %}

> **Code walkthrough:** BAD pattern: This Keep untagged (intermediate) images for only 1 day: example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **WHAT BREAKS: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** A GitHub Actions workflow using Docker Buildxice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> metadata action for proper multi-tier tagging.


```yaml
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

{% raw %}
```yaml
# BAD: only tags with 'latest', loses version traceability:
- name: Build and push
  run: |
    docker build -t myapp:latest .
    docker push myapp:latest
# All builds look the same. No rollback history.

# GOOD: proper multi-tier tagging with docker/metadata-action:
name: Build and Push
on:
  push:
    branches: [main]
    tags: ['v*.*.*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Docker meta
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/myorg/myapp
          tags: |
            # Immutable SemVer tag from git tag:
            type=semver,pattern={{version}}      # 1.2.3
            type=semver,pattern={{major}}.{{minor}}  # 1.2 (float)
            # SHA tag for traceability:
            type=sha,format=short               # sha-a1b2c3d
            # latest only on main branch:
            type=raw,value=latest,enable=${{github.ref == 'refs/heads/main'}}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          # Cache from registry:
          cache-from: type=registry,ref=ghcr.io/myorg/myapp:buildcache
          cache-to: type=registry,ref=ghcr.io/myorg/myapp:buildcache,mode=max
```
{% endraw %}

> **Code walkthrough:** `docker/metadata-action` generates tagsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> based on git context. On a push to main: generates `latest` and
> `sha-a1b2c3d`. On a git tag `v1.2.3`: generates `1.2.3`, `1.2`,
> and `sha-a1b2c3d`. The `labels` output includes OCI standard labels
> (creation time, revision, source URL): appear in `docker inspect`.
> The `buildcache` tag: used for BuildKit registry cache. This is
> a separate tag from production image tags to avoid confusion.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Tags are mutable labels on images. `latest` changes over time.
> Always pin to a specific version for production. Use SemVer tags
> (`1.2.3`) that match git tags. Digest (`sha256:...`) is immutable
> and the most reliable reference.

---

**Senior / Staff (5+ years):**
> Tag strategy is a reliability and auditability concern. In a GitOps
> workflow (ArgoCD, Flux): the Kubernetes manifests in git reference
> specific image tags. If tags are mutable: git shows no change but
> the running code changes. This breaks the fundamental GitOps
> invariant: git is the source of truth. Solution: either use
> immutable SemVer tags with registry-enforced immutability, OR
> use image digests in manifests (Flux can auto-update digest
> references in git when a new image is pushed). The combination:
> immutable tags + digest in manifests + registry lifecycle policies
> for cleanup = a complete, production-grade tagging system.

---

### ⚠️ Common Misconceptions

**Misconception: "Using the commit SHA as a tag makes it immutable."**
SHA tags are immutable in PRACTICE (a git commit hash never changes).
But they are NOT enforced as immutable by the registry unless you
enable registry immutability. Someone can still push a different
image to the same SHA tag (if the registry allows tag mutation and
they generate the same short SHA prefix). More importantly: short
SHA tags (7 characters) can collide in very large repositories.
The Git probability of a 7-character collision approaches 50% after
about 100,000 commits (birthday paradox). Larger teams: use longer
SHA prefixes (12+ characters). For true immutability guarantees in
production: use image digest references. Digest is a cryptographic
hash of the image manifest: guaranteed unique, cannot collide,
cannot be overwritten.

---

### ⚖️ Comparison Table

| Tag Type | Immutable | Rollback | Use In Prod | CI Convenience |
|---|---|---|---|---|
| latest | No | No | Never | Yes (dev/CI) |
| SemVer (1.2.3) | If enforced | Yes | Yes | Yes |
| Minor float (1.2) | No | No | Only for non-critical | Yes |
| Short SHA | In practice | Yes (with registry) | Acceptable | Yes |
| Digest | Yes (cryptographic) | Yes | Preferred | No (opaque) |

---

### 🏛️ System Design

*(Omit: tagging strategy is an operational practice, not a system architecture decision.)*

---

### 📊 Diagram

*(Omit: tag strategy is clearest in the three-tier explanation and CI workflow above.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Production rollback failed because old tag was overwritten.**
```
Symptom: kubectl rollout undo fails or results in same broken version.
  Or: docker pull myapp:1.2.2 returns the new version, not 1.2.2.

Root cause: tag was overwritten in the registry.
  "1.2.2" now points to 1.2.3's image.
  Rollback to 1.2.2: deploys 1.2.3 (the broken version).

Diagnosis:
  # Check when the tag was last pushed:
  # ECR: aws ecr describe-images --repository-name myapp
  #   --image-ids imageTag=1.2.2
  # Verify imagePushedAt timestamp.
  
  # Check image manifest hash:
  docker manifest inspect myapp:1.2.2 | grep "digest"
  # Is this the same digest as 1.2.3? If yes: tags were overwritten.

Immediate recovery:
  # Option 1: roll forward to a newer known-good version.
  kubectl set image deployment/myapp myapp=myapp:1.2.4  # next patch
  
  # Option 2: if you have the digest from when 1.2.2 was working:
  # (from CI logs, git history, or Kubernetes event history)
  kubectl set image deployment/myapp myapp=myapp@sha256:a1b2c3...
  
  # Option 3: rebuild from the git tag "v1.2.2":
  git checkout v1.2.2
  docker build -t myapp:1.2.2-rebuilt .
  docker push myapp:1.2.2-rebuilt
  kubectl set image deployment/myapp myapp=myapp:1.2.2-rebuilt

Prevention:
  Enable registry immutability for production repositories:
  aws ecr put-image-tag-mutability \
    --repository-name myapp \
    --image-tag-mutability IMMUTABLE
  
  Add CI check: fail if attempting to push a tag that already exists.
  CI: docker manifest inspect myapp:$TAG 2>/dev/null && exit 1 || true
```

> **Code walkthrough:** This Option 3: rebuild from the git tag "v1.2.2": example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Tag mutability explanation | 1 minute |
| Three-tier tagging strategy | 2 minutes |
| SemVer vs digest in K8s manifest | 2 minutes |
| Registry immutability policy | 1 minute |
| Rollback failed diagnosis | 2 minutes |
| GitOps + digest auto-update | 1 minute |
| Image retention policy | 1 minute |

---

**Q1 (architecture): How do you implement zero-trust image verification for a Kubernetes production cluster?**

A: Four controls. (1) **Image signing**: sign images with cosign
(Sigstore project). CI: `cosign sign --key cosign.key myapp:1.2.3`.
Policy: Kubernetes admission controller rejects unsigned images or
images with invalid signatures. Tools: Kyverno or OPA Gatekeeper.
(2) **Admission webhook policy**: webhook intercepts every pod creation.
Checks: is the image from an approved registry? Is the tag signed?
Is the digest format (not mutable tag) used? Unsigned or unrecognized
registry: pod rejected. (3) **Runtime SBOM verification**: every
deployed image has a Software Bill of Materials (SBOM). When a new
CVE is published: scan all running SBOMs. Identify affected workloads
in minutes. Trigger rebuild of affected images. (4) **Continuous
scanning**: Snyk, Trivy, or AWS Inspector continuously scan running
images. New CVE discovered in a library: alert fires for all pods
using an image with that library. The alert: includes the pod name,
namespace, and remediation (update base image or dependency).

*What separates good from great:* The supply chain attack vector.
The SolarWinds and Log4Shell incidents: compromised build pipelines
and dependencies. Defense: (1) Pin all base images to digests. (2)
Pin all dependencies to exact versions with checksums (npm lockfile,
pip hash-checking, Maven checksum verification). (3) Use a private
proxy registry that caches and scans public images before they enter
your CI. Public images (Docker Hub, GCR): may be altered after you
first use them. Private proxy: caches the image at first pull, serves
the cached version to all subsequent builds. You own the cache:
upstream changes don't affect you.

---

---

## Dockerfile Anti-patterns

---

### 🎯 Model Answer

**30 seconds:**
> Common Dockerfile anti-patterns: (1) Running as root (no USER
> directive), (2) `COPY . .` before dependency install (breaks cache
> on every code change), (3) No `.dockerignore` (large build context),
> (4) Multiple RUN instructions that should be combined (separate
> layers, larger image), (5) Secrets in ENV or ARG (visible in
> history), (6) No HEALTHCHECK, (7) Using `latest` tag for base image,
> (8) Not using multi-stage builds (build tools in production image).

**3 minutes (Senior):**
> Systematic anti-pattern analysis: (1) **RUN chaining failure**: `RUN
> apt-get update` (layer 1) then `RUN apt-get install -y curl` (layer
> 2). If layer 2 is rebuilt (added a new package): layer 1 (apt-get
> update) is cached and stale. apt-get install tries to install
> packages that may not exist in the stale index. Solution: always
> combine update + install in one RUN instruction. (2) **Credential
> via ARG**: `ARG BUILD_TOKEN` is visible in `docker history --no-trunc`.
> Even if unset at the end: the value is in the build cache and
> metadata. Use BuildKit secrets instead. (3) **`ADD` instead of
> `COPY`**: `ADD` has hidden magic: it unpacks tar archives and can
> fetch URLs. Most uses should be `COPY` (explicit, predictable).
> `ADD` is only appropriate for its special cases. (4) **Ignoring
> exit codes**: `RUN curl http://example.com/setup.sh | bash`.
> If curl fails silently: bash runs with empty input. No error.
> The image is built without the setup. Always use `set -eo pipefail`
> or `&&` chaining. (5) **`CMD` in shell form**: `CMD myapp --port
> 3000`. Shell form wraps in `/bin/sh -c`. PID 1 is `/bin/sh`, not
> `myapp`. Signals (SIGTERM) go to `/bin/sh`. App may not receive
> graceful shutdown signals. Use exec form: `CMD ["myapp", "--port",
> "3000"]`. PID 1 is `myapp`. SIGTERM received directly.

**Blank Mind Recovery:**

**(1) Restate:** "Top 8: root user, wrong COPY order, no .dockerignore,
separate RUN layers, secrets in ENV/ARG, no HEALTHCHECK, `latest`
base tag, no multi-stage. CMD exec form vs shell form: PID 1 signal
issue. ADD vs COPY: use COPY."

**(2) First principles:** "Each anti-pattern has a concrete cost:
security risk, image size, build speed, or operational reliability.
Know the WHY for each, not just the pattern."

**(3) Bridge:** "Dockerfile anti-patterns are like kitchen shortcuts
that cause accidents later. Using the default 'root' user: leaving
the master key in the door. COPY before install: baking the cake
before adding flour (have to restart from scratch every time). CMD
in shell form: speaking through an interpreter who drops your
emergency signal."

---

### 📘 Concept Explanation

**Each anti-pattern with mechanism, symptom, and fix:**

```
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

```plaintext
ANTI-PATTERN 1: apt-get update and install in separate RUN:

  # BAD:
  RUN apt-get update
  RUN apt-get install -y curl wget git  # separate layer
  # Problem: "update" layer is cached. When adding "vim" later:
  # RUN apt-get install -y curl wget git vim
  # -> update layer is cached (stale).
  # -> install may fail: vim not in cached index.
  
  # GOOD: always combine:
  RUN apt-get update && \
      apt-get install -y --no-install-recommends \
        curl wget git && \
      rm -rf /var/lib/apt/lists/*  # clean up apt cache (smaller layer)
  # One layer. Update always paired with install. Cache correct.
  # --no-install-recommends: don't install suggested packages.
  # rm -rf /var/lib/apt/lists/*: clean up apt cache from the layer.

ANTI-PATTERN 2: ADD instead of COPY:

  # BAD: using ADD for simple file copy:
  ADD . /app           # copies everything (like COPY) but has side effects
  ADD myfile.tar.gz /  # automatically unpacks the tarball. Surprising!
  ADD http://example.com/file /tmp  # downloads from URL. Risky.
  
  # GOOD: use COPY for file copies:
  COPY . /app          # explicit. No side effects.
  # Use ADD ONLY when you specifically need tar auto-extraction:
  ADD jdk-17.tar.gz /opt/  # intentional: want the archive extracted.

ANTI-PATTERN 3: ignoring pipe failures:

  # BAD: silent failure:
  RUN curl https://example.com/setup.sh | bash
  # If curl fails (network issue): bash receives empty stdin.
  # bash runs (no error). Empty script = no-op.
  # Image is built without the setup. No error reported.
  
  # GOOD: explicit failure handling:
  RUN set -eo pipefail && \
      curl -fsSL https://example.com/setup.sh | bash
  # -e: exit on any error. -o pipefail: pipe failures are errors.
  # curl -f: fail if HTTP error (4xx/5xx). -s: silent. -S: show errors. -L: follow redirects.
  # If curl fails: entire RUN fails. Build fails. Explicit.

ANTI-PATTERN 4: shell form CMD (PID 1 signal problem):

  # BAD: CMD in shell form:
  CMD myapp --port 3000
  # Equivalent to: CMD ["/bin/sh", "-c", "myapp --port 3000"]
  # PID 1: /bin/sh. myapp: a child process.
  # docker stop sends SIGTERM to PID 1 (/bin/sh).
  # /bin/sh: may not forward SIGTERM to myapp.
  # docker: waits 10s (grace period). Then sends SIGKILL.
  # myapp: killed without graceful shutdown.
  
  # GOOD: CMD in exec form:
  CMD ["myapp", "--port", "3000"]
  # PID 1: myapp directly. SIGTERM goes directly to myapp.
  # Application: can handle SIGTERM for graceful shutdown.
  # Close connections. Flush writes. Exit cleanly.
  
  # For Java: the JVM handles SIGTERM by default.
  # But shell form: JVM never receives the signal.
  CMD ["java", "-jar", "app.jar"]  # exec form, not "java -jar app.jar"

ANTI-PATTERN 5: WORKDIR not set (or pwd):

  # BAD: no WORKDIR (or using RUN cd ...):
  FROM node:18
  RUN cd /app   # WRONG: RUN creates a new shell. This "cd" is lost.
  COPY . .      # copies to /. Messy.
  
  # GOOD: use WORKDIR:
  FROM node:18
  WORKDIR /app        # creates /app if missing. All subsequent commands use /app.
  COPY . .            # copies to /app. Predictable.

ANTI-PATTERN 6: using ENV for secrets:

  # BAD: secret in ENV:
  ENV DB_PASSWORD=mysecretpassword
  # Permanently in image. docker inspect: visible.
  # docker history: visible. Image manifest: visible.
  
  # BAD: ARG for secret (passed at build time):
  ARG DB_PASSWORD
  ENV DB_PASSWORD=$DB_PASSWORD
  # ARG values: visible in docker history --no-trunc.
  
  # GOOD: BuildKit secret mount:
  RUN --mount=type=secret,id=db_password \
      export DB_PASSWORD=$(cat /run/secrets/db_password) && \
      ./setup-database.sh
  # Not in any layer. Not in history. Not in inspect.

ANTI-PATTERN 7: EXPOSE is not a port forward:

  # Common misconception:
  EXPOSE 3000
  # This does NOT publish the port to the host.
  # It is documentation only.
  # Container is NOT accessible on host port 3000.
  
  # To publish: use -p at runtime:
  docker run -p 8080:3000 myapp
  # Or in Compose:
  ports:
    - "8080:3000"
  
  # EXPOSE: documents that the container listens on 3000.
  # Used by -P (publish all exposed ports to random host ports).
  # Always include EXPOSE for documentation. Always add -p at runtime.

ANTI-PATTERN 8: inconsistent package pinning:

  # BAD: unpinned package versions:
  RUN apt-get install -y python3  # which version? Changes daily.
  RUN pip install flask            # latest. May break with new version.
  
  # GOOD: pin versions:
  RUN apt-get install -y python3=3.11.0-1  # specific version
  RUN pip install flask==3.0.0             # exact version
  
  # Better for Python: use requirements.txt with hash checking:
  COPY requirements.txt .
  RUN pip install --require-hashes -r requirements.txt
  # requirements.txt: generated by pip-compile with --generate-hashes.
  # Every package: exact version + sha256 hash. Verified on install.
```

> **Code walkthrough:** BAD pattern: This Every package: exact version + sha256 hash. Verified on install. example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **WHAT BREAKS: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** A before-and-after Dockerfile showing 6ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> anti-patterns fixed in one rewrite.

```dockerfile
# BAD: multiple anti-patterns in one Dockerfile:
FROM ubuntu:latest          # 1. unpinned latest
WORKDIR /app
ADD . .                     # 2. ADD instead of COPY
RUN apt-get update          # 3. update without install (separate RUN)
RUN apt-get install -y nodejs npm  # 4. separate from update
ARG NPM_TOKEN               # 5. secret via ARG
ENV NPM_TOKEN=$NPM_TOKEN    # 6. secret in ENV
RUN npm install             # installs devDependencies too
CMD npm start               # 7. shell form CMD (PID 1 issue)
# Runs as root. ~850MB image. Credentials in history. Broken cache.

# GOOD: anti-patterns fixed:
# syntax=docker/dockerfile:1
FROM node:20-bookworm-slim AS deps
# No ubuntu:latest. Official slim image, pinned major version.
WORKDIR /app

# COPY dependency files BEFORE source (cache optimization):
COPY package*.json ./

# Install with BuildKit secret (no ARG/ENV for secrets):
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm ci --omit=dev

# Separate stage for production:
FROM node:20-bookworm-slim AS runtime
WORKDIR /app

# Copy only production dependencies + built app:
COPY --from=deps /app/node_modules ./node_modules
COPY --chown=node:node src/ ./src/

# Non-root user:
USER node

# Document the port:
EXPOSE 3000

# Exec form CMD (PID 1 = node, receives SIGTERM directly):
CMD ["node", "src/server.js"]
```

> **Code walkthrough:** Every anti-pattern from the bad version isice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> addressed. `node:20-bookworm-slim` is a pinned official image (not
> `latest`, not `ubuntu`). `COPY package*.json` before `npm ci`:
> protects the install layer from cache invalidation on source changes.
> BuildKit `--mount=type=secret`: npmrc credentials not in any layer.
> Multi-stage: production image contains only runtime and production
> dependencies. `--chown=node:node`: files owned by the `node` user
> before `USER node`. `CMD ["node", "src/server.js"]` in exec form:
> `node` is PID 1, receives SIGTERM directly for graceful shutdown.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Key Dockerfile mistakes: running as root, COPY all files before
> installing dependencies (breaks cache), using `latest` base image,
> putting secrets in ENV or ARG. Use exec form `CMD ["myapp"]` instead
> of shell form `CMD myapp` for proper signal handling.

---

**Senior / Staff (5+ years):**
> The signal handling anti-pattern is the most operationally impactful.
> Shell form CMD: the application never receives SIGTERM. `docker stop`
> waits 10 seconds (default) then SIGKILL. Application: abruptly
> killed. In-flight requests: dropped. Database connections: abruptly
> closed (can cause connection pool exhaustion on the database side).
> For Kubernetes rolling deployments: pods are replaced one-by-one
> with 30-second grace period. If the app doesn't handle SIGTERM:
> every pod replacement drops active connections. In a 3-pod deployment
> being updated: 3 connection drops. In a 50-pod deployment: 50
> connection drops. The fix: exec form CMD + SIGTERM handler in the
> application (drain active requests, close DB connections). This is
> the difference between a zero-downtime deployment and a deployment
> that causes user-visible errors.

---

### ⚠️ Common Misconceptions

**Misconception: "EXPOSE in the Dockerfile publishes the port to the host."**
`EXPOSE` is metadata only. It documents which port the application
inside the container listens on. It does NOT publish the port. It
does NOT make the port accessible from the host or from other
containers on different networks. The port only becomes accessible
via: (1) `docker run -p hostport:containerport` (publish to host),
(2) `ports: - "hostport:containerport"` in docker-compose.yml,
(3) Containers on the SAME user-defined network (they can access
each other's exposed ports WITHOUT `-p`). The confusion: `docker run
-P` (capital P) publishes ALL `EXPOSE`d ports to random host ports.
This makes `EXPOSE` suddenly "work." But in most production usage:
specific port mappings are used, not `-P`. `EXPOSE` is still valuable
as documentation: it tells other developers and tools (Kubernetes,
Compose) which port to expect. Always include it.

---

### ⚖️ Comparison Table

| Anti-pattern | Impact | Fix | Severity |
|---|---|---|---|
| Root user | Security: escalation | USER nonroot | Critical |
| COPY before dependencies | Performance: cache miss | COPY deps first | Medium |
| Shell form CMD | Reliability: signal loss | Exec form | High |
| Separate apt update/install | Build: stale cache | Combine in one RUN | Medium |
| Secret in ENV/ARG | Security: credential leak | BuildKit secrets | Critical |
| No .dockerignore | Performance: large context | Add .dockerignore | Medium |
| ADD instead of COPY | Correctness: unexpected behavior | Use COPY | Low |
| Unpinned base tag | Reproducibility: drift | Pin to digest/version | High |

---

### 🏛️ System Design

*(Omit: Dockerfile anti-patterns are implementation-level, not system architecture decisions.)*

---

### 📊 Diagram

*(Omit: anti-patterns are clearest in the annotated code examples above.)*

---

### 🚨 Failure Modes and Diagnosis

**Failure: Application in Docker container drops connections during deployment.**

{% raw %}
```
Symptom: During a rolling deployment, active users see connection errors.
  Or: database shows sudden spike in connection errors during deployment.
  After deployment: everything works. Only during rollout.

Root cause: CMD in shell form. Application not receiving SIGTERM.
  Docker stop sends SIGTERM to PID 1 (/bin/sh, not the app).
  App continues processing until SIGKILL (10s timeout).
  Kubernetes: 30s grace period, then SIGKILL.
  During these seconds: app is killed mid-request.
  
Diagnosis:
  # Check Dockerfile CMD:
  docker inspect myapp --format '{{json .Config.Cmd}}'
  # ["/bin/sh", "-c", "node server.js"] <- SHELL FORM. BUG.
  # ["node", "server.js"]               <- EXEC FORM. OK.
  
  # Check if app responds to SIGTERM:
  docker exec myapp kill -SIGTERM 1  # signal to PID 1
  docker logs myapp  # does app log "graceful shutdown started"?
  # No log, then sudden stop -> SIGTERM not handled.
  
  # Check PID 1 inside container:
  docker exec myapp ps aux | head -5
  # PID 1: sh -c node server.js  <- shell form (BAD)
  # PID 1: node server.js         <- exec form (GOOD)

Fix:
  1. Fix Dockerfile: change CMD to exec form:
     CMD ["node", "server.js"]
  
  2. Add SIGTERM handler in application:
     process.on('SIGTERM', () => {
       console.log('SIGTERM received. Closing HTTP server...');
       server.close(() => {
         console.log('HTTP server closed. Exiting.');
         pool.end(() => process.exit(0));  // close DB connections
       });
     });
  
  3. Kubernetes: configure preStop hook for additional drain time:
     lifecycle:
       preStop:
         exec:
           command: ["/bin/sh", "-c", "sleep 5"]
     # Kubernetes: sends preStop, then SIGTERM, then waits grace period.
     # preStop sleep: gives load balancer time to remove pod from endpoints
     # before SIGTERM is sent to the app.
```
{% endraw %}

> **Code walkthrough:** This before SIGTERM is sent to the app. example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Shell form vs exec form CMD | 2 minutes |
| apt-get update stale cache | 2 minutes |
| Secret in ARG/ENV | 2 minutes |
| ADD vs COPY | 1 minute |
| EXPOSE misconception | 1 minute |
| Connection drops during deployment | 2 minutes |
| Graceful shutdown implementation | 2 minutes |

---

**Q1 (production): Describe how you would audit an inherited set of 30 Dockerfiles for anti-patterns.**

A: Automated + manual review in three layers. (1) **Static analysis**:
`hadolint` (Dockerfile linter): runs in CI and locally. Checks:
no latest tag, COPY order, RUN apt-get pattern, ADD vs COPY, USER
instruction. Run: `hadolint Dockerfile` or in CI with `hadolint/
hadolint-action`. Generates exit code 0 (pass) or non-zero (fail).
Integrate as required CI check. (2) **Image scanning**: build all
images, run `trivy image` on each. Check for: CVEs, running as root
(`RunsAsRoot` finding in Trivy), no HEALTHCHECK, writable filesystem.
trivy can also scan Dockerfiles directly for misconfigurations:
`trivy config Dockerfile`. (3) **Runtime audit**: for running
containers, check `docker inspect`: `User` field (should not be
empty/root), `Mounts` (databases should have volumes), `Config.Cmd`
(exec form, not shell form). Script: `for id in $(docker ps -q);
do docker inspect $id --format "{{.Name}}: user={{.Config.User}}
cmd={{json .Config.Cmd}}"; done`.

*What separates good from great:* The organizational anti-pattern:
Dockerfiles not reviewed in code review. Most engineers review
application code carefully but accept Dockerfiles without scrutiny.
Fix: add `hadolint` as a required status check. Add `trivy` image
scan as a required CI check with severity threshold (fail on HIGH+).
Create a Dockerfile review checklist: WORKDIR set? USER directive?
CMD exec form? No secrets in ENV? Multi-stage? These are 5 checks
that catch 80% of anti-patterns. Make the checklist a PR template
section. After 3 months: the team writes correct Dockerfiles without
the checklist because the patterns are internalized.

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




