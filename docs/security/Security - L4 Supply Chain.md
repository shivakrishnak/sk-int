---
layout: default
title: "Security - L4 Supply Chain"
parent: "Security"
nav_order: 11
permalink: /security/l4-supply-chain/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Software Supply Chain Security: SBOM and Dependency Auditing](#software-supply-chain-security-sbom-and-dependency-auditing) | high |

---

# Software Supply Chain Security: SBOM and Dependency Auditing

---
id: SEC-022
title: "Software Supply Chain Security: SBOM and Dependency Auditing"
category: Security
difficulty: "★★★"
interview_weight: high
asked_at: Senior+
seniority: senior
tags: [security, supply-chain, sbom, dependencies, sca]
status: draft
sd: true
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Software supply chain security addresses vulnerabilities introduced through
> dependencies, build tools, and CI/CD pipelines. An SBOM (Software Bill of Materials)
> is a machine-readable inventory of all components in a software artifact. Dependency
> auditing (OWASP Dependency Check, Snyk, GitHub Dependabot) identifies known CVEs
> in dependencies. The SolarWinds and Log4Shell incidents demonstrated that supply
> chain attacks can affect thousands of organizations via a single compromised component.

**3 minutes (Senior):**
> Supply chain attack surface: open source dependencies (transitive), build tools,
> CI/CD pipelines, container base images, infrastructure-as-code modules. Log4Shell
> (CVE-2021-44228) showed that a single transitive dependency (log4j-core) affected
> thousands of Java applications; many teams did not know they had it because it was
> 4 levels deep in the dependency tree. SBOM (SPDX, CycloneDX formats) provides a
> complete inventory, enabling rapid impact assessment when a new CVE is published.
> Dependency auditing in CI: OWASP Dependency Check or Snyk block the build on new
> critical CVEs. Artifact signing (Sigstore, cosign) ensures build artifacts are not
> tampered with between build and deployment. Supply chain hardening: pin dependency
> versions (hash pinning, not semver), vet new dependencies before adoption, use
> allowlisting for permitted packages.

**Framework:** Inventory (SBOM) → Audit (SCA) → Harden (signing, pinning) → Respond (CVE triage)

**Blank Mind Recovery:**

**(1) Restate:** "Supply chain security is about what your code depends on. SBOM
inventories everything; dependency auditing finds known vulnerabilities;
signing verifies integrity."

**(2) First principles:** "Software is not just the code you write - it includes
everything you import. Attackers attack the weakest link in the chain, which is
often a widely-used open source library."

**(3) Bridge:** "Supply chain security is like a restaurant's food safety program -
you audit every supplier, not just your own kitchen. A contaminated ingredient from
a supplier causes harm in every dish that uses it."

---

### 📘 Concept Explanation

**What it is:**
Software supply chain security encompasses practices and tools to identify, track,
and mitigate risks introduced through external software components (libraries,
frameworks, tools) used in building and running an application.

**The problem it solves:**
Modern applications are 80-90% third-party code by line count. Log4Shell demonstrated
that a critical vulnerability in a widely-used library can be in production for years
before discovery, affecting thousands of organizations simultaneously.

**Supply chain attack surface:**

```
SOFTWARE SUPPLY CHAIN ATTACK SURFACE:

  SOURCE CODE:
    - Open source dependencies (direct + transitive)
    - Typosquatting attacks (malicious packages with
      names similar to popular packages)
    - Dependency confusion (internal package names
      published to public registry with higher version)

  BUILD PIPELINE:
    - Compromised build tools (e.g., XZ Utils backdoor)
    - CI/CD credentials exposed in logs
    - Build script injection (Makefile, Gradle plugin)
    - Artifact tampering between build and deploy

  CONTAINER IMAGES:
    - Base image CVEs (Ubuntu, Alpine dependencies)
    - Multi-stage build pulling from compromised registries
    - Image digest not pinned - latest tag changes
    - Container registry credentials

  INFRASTRUCTURE-AS-CODE:
    - Terraform provider plugins
    - Ansible Galaxy roles
    - Helm charts from public repos

  DEPLOYMENT:
    - Package manager supply chain
      (npm, pip, Maven Central compromises)
    - Checksums not verified on download
    - Dependencies pulled from internet at runtime
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the complete software supply chain attack surface across five layers - source, build, container, IaC, and deployment. (2) KEY MECHANISM: each layer is a trust boundary where an attacker can inject malicious code or tamper with artifacts; the key insight is that most production incidents come from the source code and container layers (the most overlooked). (3) WHY IT MATTERS: the SolarWinds breach inserted a backdoor into the build pipeline; any customer who installed the SolarWinds software update received the backdoor regardless of their own code's security. (4) WHAT BREAKS: auditing only direct dependencies; transitive dependencies (libraries your dependencies import) are where most supply chain CVEs appear because they are invisible without SBOM tooling. (5) TAKEAWAY: audit each layer of the supply chain independently; do not assume transitive dependencies are safe because you did not explicitly choose them.

**SBOM overview:**

```
SBOM (Software Bill of Materials):

  FORMATS:
    SPDX  - Linux Foundation standard
            ISO/IEC 5962:2021
    CycloneDX - OWASP standard
                machine-readable, JSON/XML

  CONTENTS:
    - Component name + version
    - License type (GPL, MIT, Apache...)
    - Download URL + checksum
    - Dependencies (direct + transitive)
    - Known vulnerabilities (VEX data)
    - Author/supplier

  GENERATION:
    Maven: cyclonedx-maven-plugin
    Gradle: cyclonedx-gradle-plugin
    Python: cyclonedx-bom
    Container: syft, trivy sbom

  USE CASES:
    1. CVE triage: when Log4j CVE announced,
       query SBOM: which services use log4j-core?
       -> Identify affected services in minutes,
          not days
    2. License compliance: identify GPL dependencies
       that require source disclosure
    3. Export control: identify components with
       export control restrictions
```

> **Code walkthrough:** (1) WHAT IT SHOWS: SBOM format options (SPDX, CycloneDX), contents, generation tools, and use cases for rapid CVE triage. (2) KEY MECHANISM: an SBOM is generated at build time and stored alongside the artifact; when a new CVE is published, the SBOM enables instant query of all artifacts that contain the vulnerable component at any version. (3) WHY IT MATTERS: without SBOM, the Log4Shell response required engineers to manually search all repositories for log4j; with SBOM, the query is "which services have log4j-core >= 2.0 and <= 2.16.0 in their SBOM?" answered in seconds. (4) WHAT BREAKS: SBOM only for new artifacts; legacy applications without SBOM are invisible; include SBOM generation in the existing build pipeline for all applications, not just new ones. (5) TAKEAWAY: generate SBOM in CI and store with every artifact in the artifact registry; SBOM enables instant CVE blast-radius assessment.

**The key insight:**
The value of SBOM is not in its existence but in the query capability. An SBOM stored
on a file share without indexing is useless for emergency CVE triage. SBOM must be
indexed in a vulnerability database (Dependency Track, Grype) to be operational.

---

### 💻 Code Example

```xml
<!-- Maven: integrate SBOM generation and CVE scanning -->
<!-- BAD: No dependency auditing in build pipeline -->

<!-- GOOD: pom.xml with OWASP Dependency Check
     and CycloneDX SBOM generation -->
<build>
  <plugins>

    <!-- SBOM generation (CycloneDX format) -->
    <plugin>
      <groupId>org.cyclonedx</groupId>
      <artifactId>cyclonedx-maven-plugin</artifactId>
      <version>2.7.9</version>
      <executions>
        <execution>
          <phase>package</phase>
          <goals>
            <goal>makeAggregateBom</goal>
          </goals>
        </execution>
      </executions>
      <configuration>
        <outputFormat>json</outputFormat>
        <outputName>bom</outputName>
      </configuration>
    </plugin>

    <!-- Dependency vulnerability scan (OWASP DC) -->
    <plugin>
      <groupId>org.owasp</groupId>
      <artifactId>
        dependency-check-maven
      </artifactId>
      <version>9.0.7</version>
      <executions>
        <execution>
          <goals>
            <goal>check</goal>
          </goals>
        </execution>
      </executions>
      <configuration>
        <!-- Fail on CVSS >= 8.0 -->
        <failBuildOnCVSS>8</failBuildOnCVSS>
        <!-- Suppress false positives -->
        <suppressionFile>
          owasp-suppressions.xml
        </suppressionFile>
        <!-- NVD API key for faster updates -->
        <nvdApiKey>${env.NVD_API_KEY}</nvdApiKey>
      </configuration>
    </plugin>

  </plugins>
</build>
```

> **Code walkthrough:** (1) WHAT IT SHOWS: Maven POM configuration integrating both CycloneDX SBOM generation and OWASP Dependency Check CVE scanning into the standard package phase. (2) KEY MECHANISM: the CycloneDX plugin generates a complete bill of materials JSON at package time; the OWASP Dependency Check plugin queries the NVD (National Vulnerability Database) against all dependencies and fails the build if any dependency has a CVSS score >= 8.0. (3) WHY IT MATTERS: without this, a dependency with a critical CVE introduced via a transitive update passes all tests and deploys to production; with this, the build fails and the team is notified immediately. (4) WHAT BREAKS: `failBuildOnCVSS` with no suppression file causes false positives to block all builds; maintain a suppression file for investigated false positives with an expiry date and rationale. (5) TAKEAWAY: integrate SBOM generation and CVE scanning in CI as package-phase plugins; fail the build on critical/high CVEs; maintain a suppression file with documentation for accepted exceptions.

```yaml
# GitHub Actions: dependency scanning + SBOM
# in CI pipeline

name: Security Scanning

on: [push, pull_request]

jobs:
  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Generate SBOM with Syft (all ecosystems)
      - name: Generate SBOM
        uses: anchore/sbom-action@v0
        with:
          artifact-name: sbom.spdx.json
          format: spdx-json

      # Scan SBOM for vulnerabilities with Grype
      - name: Scan for CVEs
        uses: anchore/scan-action@v3
        with:
          sbom: sbom.spdx.json
          fail-build: true
          severity-cutoff: high

      # Container image scan
      - name: Scan Docker image
        if: github.ref == 'refs/heads/main'
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:latest
          format: sarif
          exit-code: 1
          severity: CRITICAL,HIGH
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a GitHub Actions CI pipeline that generates an SPDX SBOM with Syft, scans it for CVEs with Grype, and additionally scans the Docker image with Trivy. (2) KEY MECHANISM: Syft generates the SBOM from the repository contents (all ecosystems - npm, Maven, Python, Go, etc.); Grype queries the SBOM against its vulnerability database; Trivy scans the built container image for OS-level CVEs in the base image layers. (3) WHY IT MATTERS: a Maven dependency scan misses npm dependencies in a polyglot project; Syft scans all package manifests in the repository, providing complete cross-ecosystem coverage. (4) WHAT BREAKS: not scanning the Docker image; application dependencies may be clean but the Ubuntu base image has unpatched OS-level CVEs; Trivy catches these. (5) TAKEAWAY: use two-layer scanning: application dependencies (OWASP DC/Snyk) + container image (Trivy/Grype); SBOM enables cross-ecosystem inventory; store the generated SBOM as a build artifact for future CVE triage.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Supply chain security means securing not just your code but all the libraries you
> depend on. An SBOM lists all components in your software. Dependency auditing tools
> like OWASP Dependency Check or Snyk scan for known CVEs in your dependencies. Log4Shell
> was a major supply chain vulnerability - a critical CVE in a library that millions of
> Java applications used without knowing it was there.

---

**Senior / Staff (5+ years):**
> My supply chain security program covers four areas: inventory (generate SBOM in CI
> for every artifact), audit (Snyk or OWASP DC in CI gates on CVSS >= 8.0), verify
> (Sigstore/cosign for artifact signing to detect tampering), and respond (Dependency
> Track indexes SBOMs and alerts on new CVEs within 4 hours). The hardest part is
> transitive dependencies: direct dependencies are visible in pom.xml, but a critical
> CVE in a transitive dependency 3 levels deep is invisible without SBOM tooling.
> For new dependencies: require a security review for any new dependency before
> adoption (license, maintenance status, CVE history, download count as proxy for
> community vetting).

---

### ⚠️ Common Misconceptions

**Misconception 1: "Updating dependencies regularly is sufficient for supply chain security."**

Updating removes known CVEs from the previous version, but does not protect against:
new CVEs published between updates, malicious packages (typosquatting, dependency
confusion), compromised package maintainer accounts, or CVEs in transitive dependencies
your code never directly references. Regular updates are necessary but not sufficient.

**Misconception 2: "An SBOM is only useful for license compliance."**

License compliance is one use case. The primary security use case is CVE triage:
given a new CVE, which of my production services are affected? Without an SBOM,
answering this for a portfolio of 100 services takes days of manual investigation.
With indexed SBOMs in Dependency Track, it takes seconds.

**Misconception 3: "Private/internal packages are safe from supply chain attacks."**

Dependency confusion attacks publish a package with the same name as an internal
package to a public registry (npm, PyPI) with a higher version number. Package
managers that resolve from public registries first will download the attacker's
package instead of the internal one. Fix: configure package managers to prefer the
internal registry; use organization-scoped package names.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Critical CVE in production despite CVE scanning in CI.**

Symptom: Log4j CVE announced; teams do not know if they are affected.
Root cause: CVE scanning was configured but not blocking the build (detection mode
only); or the dependency was added after the last scan; or the SBOM was not kept
current.
Diagnosis: query SBOM index for the vulnerable component across all services.
Fix: set `failBuildOnCVSS` to blocking mode; scan on every PR, not just nightly;
use Dependency Track for continuous monitoring of deployed SBOMs against new CVEs.

**Failure Mode 2: Dependency confusion attack installs malicious package.**

Symptom: internal package `@company/auth-utils` downloaded from npm public registry
instead of private registry; malicious code executed in CI build.
Diagnosis: check npm/pip install logs for registry source; verify package checksums
against known-good hashes.
Fix: configure `.npmrc` / `pip.conf` to always use private registry; use namespace
scoping (`@company/`) that only exists in the private registry; verify checksums in CI.

**Failure Mode 3: Container base image CVEs accumulate over time.**

Symptom: container image built 6 months ago has 40 critical CVEs in the Ubuntu base layer.
Diagnosis: run `trivy image myapp:current` to see current CVEs.
Fix: rebuild base images weekly (not just on code changes); use minimal base images
(distroless, Alpine); pin base image by digest, not tag; automated PR to update
base image digest weekly via Dependabot or Renovate.

---

### ⚖️ Comparison Table

| Tool | Focus | Language | Blocking CI | SBOM support |
|---|---|---|---|---|
| **OWASP Dependency Check** | CVE scanning | Java, .NET, JS, Python | Yes | SPDX output |
| **Snyk** | CVE + license | All major | Yes | Yes (commercial) |
| **GitHub Dependabot** | Auto-PR updates | All major | No (PRs only) | No |
| **Trivy** | CVE + container | All + container | Yes | SPDX/CycloneDX |
| **Syft + Grype** | SBOM generation + scan | All major | Yes | SPDX/CycloneDX |
| **Dependency Track** | SBOM management | All (SBOM input) | Via webhook | Yes (central) |

---

### 🏛️ System Design

**Supply Chain Security Architecture**

```
  DEV             CI/CD              ARTIFACT       PRODUCTION
  +------+        +----------+       +---------+    +----------+
  | Code |--PR--->| - SAST   |       | Registry|    | Runtime  |
  |      |        | - Dep Scan|      | - Signed|    | - SBOM   |
  |      |        | - SBOM   |--push>| - SBOM  |    |   indexed|
  |      |        |   gen    |       |   stored|    | - CVE    |
  +------+        | - Image  |       +---------+    |   alerts |
                  |   scan   |            |         +----------+
                  +----------+            |
                                          v
                                  Dependency Track
                                  (SBOM index +
                                   CVE monitoring)
                                  - Alert on new CVE
                                  - Identify blast radius
                                  - Dashboard: % clean
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the complete supply chain security pipeline from code commit through artifact storage to production monitoring, with Dependency Track as the central SBOM registry. (2) HOW TO READ IT: left to right shows the delivery pipeline; each CI step adds a security check; the artifact registry stores signed artifacts with SBOMs; Dependency Track continuously monitors all deployed SBOMs against new CVE publications. (3) KEY RELATIONSHIP: the SBOM generated in CI flows through the registry to Dependency Track; when a new CVE is published (external trigger), Dependency Track queries all indexed SBOMs and raises alerts without requiring new builds or scans. (4) EDGE CASE: the SBOM must be re-generated when dependencies change; a SBOM generated 3 months ago is outdated if dependencies were updated since; generate SBOM on every build. (5) INSIGHT: a senior engineer notices Dependency Track's value is the proactive CVE alerting - it monitors the external CVE feed and correlates against your deployed artifact inventory; this is the difference between finding Log4Shell when it was published (4h) vs finding it when someone asked (days).

---

### 📊 Diagram

```
SUPPLY CHAIN THREAT LANDSCAPE:

  ATTACKER VECTORS:
  
  Typosquatting:
  npm install requesta   <- malicious
              (vs request)

  Dependency Confusion:
  Build pulls @company/utils v2.0
  from PUBLIC npm (attacker published)
  instead of PRIVATE registry v1.9

  Compromised Maintainer:
  Popular lib maintainer account hacked
  -> malicious version published
  -> auto-update installs it

  Build System Compromise:
  CI tool itself is modified
  (SolarWinds: build tool trojanized)

  DEFENSES:
  Pin versions (hash pinning > semver)
  Private registry with allowlist
  Verify package checksums
  Sign and verify build artifacts
  SBOM for blast radius assessment
```

> **Code walkthrough:** (1) WHAT IT SHOWS: four distinct supply chain attack vectors - typosquatting, dependency confusion, compromised maintainer, and build system compromise - with corresponding defenses. (2) KEY MECHANISM: each attack vector exploits a different trust assumption; typosquatting exploits human error (typo in package name); dependency confusion exploits package manager resolution order; compromised maintainer exploits trust in package identity; build compromise exploits trust in the build system itself. (3) WHY IT MATTERS: hash pinning defeats both typosquatting and compromised-maintainer attacks; the pinned hash will not match the malicious version regardless of version number or package name. (4) WHAT BREAKS: hash pinning creates friction for updates; use Renovate/Dependabot to automate hash updates while maintaining the security property of pinning. (5) TAKEAWAY: hash pinning is the highest-value supply chain control; combine with a private registry allowlist; monitor for new maintainer account takeovers via GitHub Advisory Database feed.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | SBOM, attack vectors |
| Mechanism | 2 | Dependency confusion, signing |
| Application | 2 | CI integration, CVE triage |
| Scenario | 3 | Log4Shell response, new CVE, audit |
| Trade-off | 2 | Blocking vs non-blocking, update strategy |
| Behavioral | 1 | Program building |

---

**[MID] Q1 (Definition): What is an SBOM and why is it critical for security?**

An SBOM (Software Bill of Materials) is a machine-readable inventory of all software
components that compose an application artifact. It lists: component name, version,
license, supplier, download URL, checksum, and dependencies (direct and transitive).

Two major formats: SPDX (ISO standard, Linux Foundation) and CycloneDX (OWASP standard,
JSON/XML). Both are machine-readable and supported by major tooling.

Why it is critical for security: two use cases drive the value.

CVE triage (primary): when Log4Shell was published (December 2021), every organization
needed to answer "which of my services use log4j-core 2.x?" Without SBOM, this
required engineers to search every repository manually; in large organizations, this
took 2-5 days. With indexed SBOMs in Dependency Track, the query returns results
in seconds and identifies every affected service with its version.

License compliance: production software must comply with open source licenses.
GPL requires source disclosure; AGPL has additional network use requirements.
SBOM enables automated license compliance checking across all dependencies.

*What separates good from great:* Understanding that SBOM without indexing is
insufficient. An SBOM JSON file in S3 cannot be queried at 2 AM when a critical CVE
is announced. Dependency Track or a similar SBOM management platform indexes SBOMs
and alerts automatically when new CVEs match any indexed component. The operational
value of SBOM is only realized with continuous monitoring infrastructure.

---

**[MID] Q2 (Definition): What is a dependency confusion attack and how do you prevent it?**

Dependency confusion attacks exploit how package managers resolve packages with the
same name from multiple registries. A company uses a private npm registry for internal
packages (e.g., `@company/auth-utils`). An attacker publishes a package with the
same name to the public npm registry with a higher version number (e.g., 3.0.0 vs
internal 1.9.0). Package managers configured to check public registries first download
the attacker's malicious 3.0.0 version.

Why it works: many organizations configure package managers to fall through to the
public registry when a package is not found in the private registry. The attacker
does not need to typosquat; they use the exact package name.

Prevention:
1. Configure npm to use only the private registry for packages in the company namespace.
   In `.npmrc`: `@company:registry=https://nexus.internal/repository/npm-private`
2. Set `npm config set prefer-offline true` to prefer cached/local versions.
3. Use namespace scoping exclusively: internal packages are `@company/name`; the
   namespace is owned in the public registry (even if packages are not published there)
   so the attacker cannot publish to it.
4. Verify package checksums: known-good checksums in the package-lock.json prevent
   a different version from being installed.

*What separates good from great:* Claiming the namespace in the public registry.
Register `@company` on npm as an organization even if you never publish public packages.
An attacker cannot then publish under your namespace. Zero cost, prevents the attack entirely.

---

**[SENIOR] Q3 (Mechanism): How does artifact signing with Sigstore work?**

Sigstore is a free public key infrastructure for signing software artifacts (container
images, binaries, SBOMs) without requiring key management by the signer.

Traditional signing problem: the signer needs a private key, which must be generated,
stored securely, rotated, and never lost. This operational burden causes most developers
not to sign.

Sigstore keyless signing:
1. The CI system (GitHub Actions) requests a short-lived certificate from Fulcio
   (Sigstore's certificate authority). The certificate contains the signer's OIDC
   identity (the GitHub Actions workflow URL + commit SHA).
2. The signing tool (cosign) signs the artifact with the short-lived private key.
3. The signature and certificate are stored in Rekor (an immutable public transparency log).
4. The private key is discarded after signing; it was only valid for minutes.

Verification:
1. The verifier queries Rekor for the signature and certificate.
2. Verifies the artifact hash matches the signature.
3. Verifies the certificate was issued by Fulcio to the expected workflow identity.
4. Verifies the signing event was recorded in Rekor before the certificate expired.

Result: the consumer can verify that this exact artifact was built by this exact
GitHub Actions workflow at this exact commit SHA, with an immutable audit trail.

*What separates good from great:* Understanding the supply chain trust anchor.
With Sigstore, trust anchors to the OIDC provider (GitHub) and the Rekor transparency
log. An attacker who compromises a developer's machine but not their GitHub account
cannot produce a valid signature. The trust is in the identity provider + transparency log,
not in a stored private key.

---

**[SENIOR] Q4 (Application): How would you respond to the announcement of a critical CVE in a library your organization uses?**

CVE response process (time-critical: first 4 hours matter):

0-30 minutes - Blast radius assessment: query your SBOM index (Dependency Track) for
all services that include the vulnerable component at a vulnerable version. Without
SBOM tooling, run `grep -r "log4j-core" */pom.xml` across all repositories. Output:
list of affected services with versions.

30-60 minutes - Risk assessment: not all services have the same exposure.
- Is the vulnerable code path reachable? (Log4Shell: is the application logging
  user-controlled input? Most were.)
- Is the service internet-facing or internal only?
- What data does the service handle?
Priority: internet-facing + vulnerable code path + sensitive data = immediate action.

1-4 hours - Immediate mitigations: apply vendor-recommended workarounds without
waiting for a fix. Log4Shell: set `log4j2.formatMsgNoLookups=true` as a JVM flag
or system property. Deploy to all affected services immediately.

4-48 hours - Patch and redeploy: update to the patched version. Test: unit tests,
integration tests, smoke tests. Deploy to staging; verify; deploy to production.
Roll out starting with highest-risk services.

Post-incident: update dependency scanning to catch this CVE (add if it was a gap);
add the vulnerability to the security training as a case study; review if the SBOM
coverage was complete (missed any services?).

*What separates good from great:* The workaround vs wait decision. Waiting for a
clean patch while an internet-exploitable critical CVE is public is not acceptable.
Apply the vendor workaround immediately even if it has functional trade-offs; patch
at the next deployment window. The risk of delay outweighs the risk of a temporary workaround.

---

**[SENIOR] Q5 (Mechanism): What is hash pinning and why is it more secure than semver pinning?**

Semver pinning (version range): `"lodash": "^4.17.21"` allows npm to install any
version `>= 4.17.21 < 5.0.0`. If lodash 4.17.22 is released (even if by an attacker
who compromised the maintainer account), `npm install` may install it automatically.

Hash pinning: `package-lock.json` contains SHA-512 checksums for each installed package.
`npm ci` (not `npm install`) verifies the checksum of each package against the lockfile
before installation. A malicious package at the same version number has a different
hash; the install fails.

Why hash pinning is more secure:
1. Compromised maintainer: attacker publishes malicious 4.17.22; semver range installs
   it; hash pinning: the install fails because the hash changed.
2. Registry tampering: attacker modifies the package contents in the registry without
   changing the version; hash pinning detects the tamper.
3. Man-in-the-middle during installation: modified package in transit; hash check fails.

Go modules: `go.sum` contains expected hashes for all modules; `go mod verify` checks.

Maven: artifact checksums in `maven-wrapper.properties` and SHA1/MD5 verification.

Implementation requirement: use `npm ci` (not `npm install`) in CI; `npm ci` always
uses the lockfile and fails if hashes do not match. `npm install` updates the lockfile,
bypassing the security property.

*What separates good from great:* Understanding the lockfile attack surface. The
lockfile itself can be tampered with (if a developer's machine is compromised and they
commit a modified lockfile). Protect the lockfile: code review for all lockfile changes
(any added dependency or hash change is a security-relevant change), and verify in CI
that the lockfile was generated from the package manifest without modifications.

---

**[SENIOR] Q6 (Scenario): You are performing a security audit of a Java microservices portfolio. What supply chain checks do you perform?**

Systematic supply chain audit for a Java microservices portfolio:

Step 1 - Dependency inventory: run `mvn dependency:tree` on each service. How many
direct dependencies? How many transitive? What is the total dependency count? Which
teams have dependency governance (approved dependency list)?

Step 2 - CVE scan: run OWASP Dependency Check against all services. Review findings:
how many critical? How many have been open for > 90 days? Unremiated critical CVEs
for > 90 days indicate a governance gap, not just a technical one.

Step 3 - SBOM coverage: does each service generate an SBOM in CI? Is it stored in
an artifact registry? Is there a central SBOM management platform (Dependency Track)?
If not, this is a gap: the organization cannot answer "are we affected by CVE-XXXX-XXXX"
for any new CVE.

Step 4 - Build pipeline security: review CI pipeline configuration. Are build steps
pulling from the internet at build time? (Should use pre-fetched dependencies from
a private registry.) Are secrets exposed in build logs? Are build artifacts signed?

Step 5 - Container image audit: run Trivy against all production container images.
How many OS-level CVEs? When were base images last rebuilt? Are base images pinned
by digest (not `:latest`)?

Step 6 - Dependency governance: is there a policy for adding new dependencies?
Who approves? Is license compatibility checked? Is the dependency actively maintained?

Findings report: SBOM coverage percentage, CVE backlog by severity, container image
age, dependency governance maturity (none/informal/enforced).

*What separates good from great:* The "abandoned dependency" audit. A dependency
with no commits in 3+ years and critical CVEs is a high-risk liability. Run
`libraries.io` or Snyk's dependency health score across all dependencies; flag
abandoned ones for replacement in the next sprint planning cycle.

---

**[SENIOR] Q7 (Trade-off): Should you block CI builds on all CVEs or only critical/high?**

Blocking strategy design:

Block on critical (CVSS >= 9.0): always. A critical CVE in a build means the artifact
should not be deployed. The risk of deploying a critical CVE is higher than the friction
of fixing it. If the build is blocked, the team fixes the dependency before proceeding.

Block on high (CVSS 7.0-8.9): generally yes, with a suppression mechanism. High CVEs
have significant impact but may have mitigating factors (not reachable code path,
mitigated by WAF, internal service with no internet exposure). Suppression file allows
documented exceptions with: CVE ID, rationale, mitigating controls, expiry date.
Suppression without documentation should not be permitted.

Do not block on medium/low (CVSS < 7.0): medium CVEs in transitive dependencies are
extremely common; blocking on all medium would make nearly every build fail. Track
medium CVEs in a register; remediate on a 90-day SLA; do not block CI.

Why not block on everything: false positives exist. OWASP Dependency Check has a
known false positive rate of 20-30% due to CPE matching being imprecise. Blocking
on all findings without a suppression mechanism creates alert fatigue and causes teams
to disable scanning entirely - the opposite of the intended outcome.

*What separates good from great:* The suppression review process. Suppressions added
6 months ago for a "not exploitable" reason must be reviewed: has the threat landscape
changed? Has the dependency been updated to a clean version? A suppression file that
grows without review becomes a graveyard of ignored CVEs. Monthly review of all
suppressions; auto-expire at 90 days.

---

**[SENIOR] Q8 (Application): How do you secure your CI/CD pipeline against supply chain attacks?**

CI/CD pipeline is a critical attack surface: a compromised build produces malicious
artifacts that look legitimate.

Credential security:
- Rotate CI credentials (API keys, deploy keys) regularly; audit unused credentials.
- Use OIDC-based CI credentials (GitHub Actions OIDC → AWS IAM role assumption)
  instead of stored secrets; ephemeral credentials eliminate long-lived secret exposure.
- Never log secrets; use `::add-mask::` in GitHub Actions.

Dependency security in build:
- Pull dependencies from a private registry (Nexus, Artifactory), not the public
  internet. The private registry caches approved packages; build does not call
  external servers.
- Hash pinning: `npm ci`, `mvn verify`, `pip install --require-hashes`.

Build environment isolation:
- Each build runs in an ephemeral, fresh environment; no state carried between builds.
- Build containers use a pinned, scanned base image.
- Build tools (Gradle wrapper, Maven wrapper) verified against checksums in the repo.

Artifact signing:
- Sign all produced artifacts with cosign/Sigstore.
- Deployment pipeline verifies signature before deploying.
- Prevents build artifact tampering between CI and production.

Pipeline-as-code security:
- CI pipeline files (`.github/workflows/*.yml`) are in source control; changes require
  PR review; branch protection prevents direct push.
- Review any workflow that uses `runs-on: self-hosted` carefully (self-hosted runners
  have persistent state that can carry malware between builds).

*What separates good from great:* The GitHub Actions permissions model. Every workflow
job should declare minimum permissions (`permissions: contents: read`). A workflow
with full `write-all` permissions that is compromised by a supply chain attack on a
dependency can modify repository code, delete releases, and push malicious artifacts.
Minimum permissions limit blast radius of a compromised build dependency.

---

**[SENIOR] Q9 (Scenario): A developer wants to add a popular open source library. What is your security review process?**

New dependency review is a security gate, not a formality. The review covers four areas.

Security history:
- Run the dependency through Snyk or OSS Review Toolkit: how many CVEs in the past
  24 months? Were they patched promptly (< 30 days for critical)?
- A library with multiple critical CVEs per year is a long-term liability even if
  currently clean.

Maintenance status:
- Last commit date: a library with no commits in 2+ years will not receive security
  patches. Avoid or plan to fork/replace.
- Dependency count: a library that pulls in 100+ transitive dependencies significantly
  expands the attack surface.
- Maintainer count: libraries maintained by a single person are high-risk (maintainer
  burnout, account takeover as seen in xz utils 2024).

License compatibility:
- What license is it? GPL, LGPL, MIT, Apache? Incompatible with proprietary products?
- Does the license require disclosure (GPL)? Attribution (MIT)?

Alternatives evaluation:
- Is there a more maintained alternative? Is there a standard library capability
  that covers the need without an external dependency?

Approval decision: approve (add to approved dependency list), approve with conditions
(review in 90 days), or reject (use alternative or build in-house).

*What separates good from great:* The maintainer trust surface. The xz-utils backdoor
(2024) was introduced by a malicious contributor who spent 2 years building trust with
the maintainer before inserting the backdoor. This cannot be detected by CVE scanning;
it requires: verifying that releases are signed by the original maintainer, monitoring
for unusual changes to low-level components (compression, crypto), and being skeptical
of aggressive new contributors to security-critical libraries.

---

**[SENIOR] Q10 (Behavioral): Your organization was not aware it was running Log4j 2.x until Log4Shell was announced. How do you prevent this from happening again?**

Root cause analysis: the organization had no dependency inventory process. Log4j was
a transitive dependency in several services (pulled in by another library); nobody
maintained visibility into transitive dependencies.

Immediate fix: implement SBOM generation in CI and deploy Dependency Track for
continuous CVE monitoring. Set up an alert that fires within 4 hours of a new critical
CVE being published against any component in the SBOM inventory.

Longer-term program changes:

Dependency governance: create an approved dependency list. Any new dependency outside
the list requires a security review. This prevents new unknown dependencies from
accumulating silently.

Dependency health scoring: monthly review of all direct and transitive dependencies.
Flag: abandoned (no commits > 2 years), high CVE rate (> 3 critical per year),
single-maintainer high-risk.

Transitive dependency visibility: require that the dependency:tree output be part of
the PR description for any dependency change. Developers see that adding library X
also adds 15 transitive dependencies; this drives better selection.

Metrics for success: "time to identify affected services after a critical CVE
announcement" - target: < 1 hour with Dependency Track. Without SBOM: 2-5 days.
This metric has a direct relationship to breach exposure time.

*What separates good from great:* The "known unknowns" principle. After Log4Shell, the
question is not just "are we patched?" but "what else are we running that we don't know
about?" A full dependency inventory audit - every service, every transitive dependency,
all versions - run immediately after a major supply chain incident is the standard
response of mature security programs. It finds the Log4Shell of next quarter before
it is announced.

---

**[SENIOR] Q11 (Trade-off): What are the trade-offs between Snyk, OWASP Dependency Check, and GitHub Dependabot?**

OWASP Dependency Check:
- Open source, free, self-hosted.
- Queries NVD (National Vulnerability Database) directly.
- Excellent Java/Maven support; good Python, .NET; limited others.
- Integrates as Maven/Gradle plugin (blocking CI).
- False positive rate: 20-30% (CPE matching imprecision).
- Maintenance: community-maintained; NVD API changes caused 2024 disruption.
- Best for: Java-centric shops that need self-hosted, no external data sharing.

Snyk:
- Commercial (free tier for small teams); SaaS.
- Curated vulnerability database (better signal-to-noise than NVD alone).
- Excellent polyglot support: Java, Python, Go, Ruby, PHP, .NET.
- PR blocking + automated fix PRs (suggest updated version).
- Developer-friendly UI: shows fix paths, not just CVE lists.
- Best for: teams wanting managed solution with automated fix PRs.

GitHub Dependabot:
- Free, integrated into GitHub.
- Creates PRs to update vulnerable dependencies automatically.
- Not a CI gate (creates PRs, does not block builds directly).
- Coverage: most package ecosystems.
- Best for: automated dependency updates with low friction; complement with OWASP DC
  or Snyk for CI gating.

Recommended combination: Dependabot for automated updates (keep dependencies fresh
automatically) + Snyk or OWASP DC as CI gate (block builds on critical/high CVEs
before they are merged).

*What separates good from great:* Running multiple scanners. NVD and Snyk have different
vulnerability databases; a CVE in NVD may not be in Snyk's database and vice versa.
The gap is typically 5-10% for popular packages; for obscure packages, it can be higher.
Run both OWASP DC and Snyk for complete coverage on high-security applications.

---

**[STAFF] Q12 (Behavioral): How do you build a supply chain security program for an organization that has none?**

A supply chain security program has three maturity levels. Start at level 1, build to 3.

Level 1 - Visibility (month 1-3):
Goal: know what you are running.
Actions: deploy OWASP Dependency Check in detection mode (non-blocking) for all
repositories; generate SBOM for all production artifacts; deploy Dependency Track
with all SBOMs indexed.
Metric: "what percentage of production services have an indexed SBOM?" Start: 0%.
Target at 90 days: 100%.

Level 2 - Gating (month 3-6):
Goal: prevent new critical CVEs from reaching production.
Actions: enable blocking mode for CVSS >= 9.0 in CI; require suppression documentation
for any bypass; set up Dependabot for automated dependency update PRs.
Metric: "how many critical CVEs are open in production > 7 days?" Target: 0 at any
given time.

Level 3 - Continuous improvement (month 6+):
Goal: proactive risk reduction; supply chain attack prevention.
Actions: artifact signing with cosign; private registry for all dependencies (no
internet pull at build time); dependency governance process (approved list + review
for new additions); quarterly dependency health review.
Metric: "mean time to identify blast radius after CVE announcement" - target: < 1 hour.

Communication to leadership: frame as risk management. The cost of a single supply
chain incident (like Log4Shell remediation: 200 engineers × 2 days = 400 engineer-days
of emergency response) exceeds the cost of the program by an order of magnitude.
The business case is insurance: low probability, catastrophic impact, low prevention cost.

*What separates good from great:* Starting with level 1 before level 2. Many organizations
try to gate CI before they have visibility, discover 500 blocking CVEs, and declare
the effort failed. Visibility first - understand the landscape before gating. The first
90 days are about measurement, not enforcement.
