---
layout: default
title: "Security - L4 Penetration Testing"
parent: "Security"
nav_order: 10
permalink: /security/l4-penetration-testing/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Penetration Testing Methodology and Tools](#penetration-testing-methodology-and-tools) | high |

---

# Penetration Testing Methodology and Tools

---
id: SEC-021
title: "Penetration Testing Methodology and Tools"
category: Security
difficulty: "★★★"
interview_weight: high
asked_at: Senior+
seniority: senior
tags: [security, pentest, vulnerability-assessment, red-team, burp-suite]
status: draft
sd: true
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Penetration testing is authorized simulated attack to identify vulnerabilities before
> real attackers do. The methodology follows five phases: Reconnaissance, Scanning,
> Exploitation, Post-Exploitation, and Reporting. Key tools: Burp Suite (web app),
> nmap (network scanning), Metasploit (exploitation framework), gobuster/ffuf (directory
> brute force). A successful pentest produces a report with findings, severity ratings,
> and remediation steps.

**3 minutes (Senior):**
> Pentest phases: Reconnaisance (OSINT - find subdomains, tech stack, employee info);
> Scanning (nmap for open ports/services, Nikto/Nuclei for web vulns, Shodan for
> internet-exposed assets); Exploitation (Burp Suite for web app testing - intercept,
> modify, replay requests; SQLMap for SQL injection; Metasploit for service exploits);
> Post-Exploitation (privilege escalation, lateral movement, data exfiltration proof);
> Reporting (findings with CVSS scores, reproduction steps, evidence screenshots, remediation).
> Types: black-box (no info), gray-box (partial info), white-box (full code/arch access).
> Web app pentest focuses: authentication, authorization, input handling (injection, XSS),
> business logic flaws, API security, and cryptographic issues.

**Framework:** Scope → Phases → Tools → Evidence → Report

**Blank Mind Recovery:**

**(1) Restate:** "Pentest is authorized simulated attack. Five phases: recon, scan,
exploit, post-exploit, report. Tools: Burp Suite for web, nmap for network,
Metasploit for exploitation."

**(2) First principles:** "A defender needs to know what an attacker can find and do.
Penetration testing answers this by having someone attempt to attack the system with
the same techniques a real attacker would use."

**(3) Bridge:** "Pentest is like a fire drill for security - you simulate the emergency
to find gaps before a real fire. The report is the list of things that need to be fixed
in the fire safety plan."

---

### 📘 Concept Explanation

**What it is:**
Penetration testing is an authorized security engagement where a tester (or team)
simulates real-world attacks against a target system to identify exploitable
vulnerabilities. Unlike a vulnerability scan (automated), a pentest includes manual
exploitation and post-exploitation to prove impact.

**The problem it solves:**
Automated scanners find known CVEs but miss business logic flaws, chained
vulnerabilities, and novel attack vectors. A pentest provides human adversarial
thinking - the tester tries to prove impact, not just list vulnerabilities.

**Pentest phases:**

```
PENTEST METHODOLOGY (PTES-based):

1. RECONNAISSANCE (Passive + Active)
   Passive (no target interaction):
   - OSINT: Google dorks, Shodan, Censys
   - Subdomain enum: subfinder, amass, crt.sh
   - Technology fingerprint: BuiltWith, Wappalyzer
   - Employee info: LinkedIn, HaveIBeenPwned

   Active (target interaction):
   - DNS enumeration: dnsrecon, dig
   - nmap host discovery: nmap -sn 10.0.0.0/24

2. SCANNING AND ENUMERATION
   - Port/service scan: nmap -sV -sC target
   - Web app crawl: Burp Suite Spider / OWASP ZAP
   - Directory brute force:
     gobuster dir -u https://target.com -w wordlist
   - Vulnerability scan: Nuclei, Nikto
   - API endpoint discovery: ffuf, swagger scraping

3. EXPLOITATION
   - Web: Burp Suite (intercept, replay, intruder)
   - SQLi: SQLMap --dbs --tables --dump
   - Auth bypass: manual testing, custom scripts
   - Service exploits: Metasploit Framework
   - Password attacks: Hydra, hashcat (offline)

4. POST-EXPLOITATION (if in scope)
   - Privilege escalation: LinPEAS, WinPEAS
   - Lateral movement: BloodHound (AD), SSH agent
   - Data exfiltration proof (sample, not full dump)
   - Persistence demo (if in scope)

5. REPORTING
   - Executive summary (business risk)
   - Technical findings (CVSS score, steps to reproduce)
   - Evidence (screenshots, HTTP requests, tool output)
   - Remediation recommendations
   - Retesting offer
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the five PTES-aligned pentest phases with specific tools and activities at each phase. (2) KEY MECHANISM: each phase builds on the previous; reconnaissance identifies the attack surface, scanning finds entry points, exploitation proves impact, post-exploitation proves blast radius, reporting documents everything for remediation. (3) WHY IT MATTERS: a pentest without all five phases is incomplete; reconnaisance and post-exploitation are the phases most often skipped in rushed engagements, leaving the most valuable findings undiscovered. (4) WHAT BREAKS: starting exploitation before thorough reconnaissance misses the easy wins; most real attackers spend 70% of their time in reconnaissance. (5) TAKEAWAY: follow all five phases in order; the quality of findings is directly proportional to the quality of reconnaissance.

**Web application pentest focus areas:**

```
WEB APP PENTEST OWASP TOP 10 COVERAGE:

  AUTHENTICATION:
  - Test: credential stuffing, brute force,
    default credentials, MFA bypass
  - Tools: Burp Intruder, Hydra, custom scripts

  AUTHORIZATION (IDOR + broken access control):
  - Test: horizontal IDOR (user A accesses user B)
  - Test: vertical privilege escalation
  - Method: manipulate IDs in requests (Burp Repeater)

  INJECTION (SQL, NoSQL, Command):
  - Test: SQLMap, manual parameter testing
  - Evidence: extract data, boolean-based blind SQLi

  XSS (Reflected, Stored, DOM-based):
  - Test: inject payloads in all inputs
  - Evidence: cookie theft proof (not actual)

  CRYPTOGRAPHIC ISSUES:
  - Test: HTTP instead of HTTPS, weak ciphers
  - Tools: testssl.sh, nmap ssl-cert

  BUSINESS LOGIC:
  - Test: price manipulation, workflow skip
  - Evidence: negative prices, step bypass
```

> **Code walkthrough:** (1) WHAT IT SHOWS: web app pentest coverage map organized by OWASP Top 10 category with specific tests and tools. (2) KEY MECHANISM: each category requires both automated scanning (to catch known patterns) and manual testing (to catch logic flaws); automated tools find ~40% of issues; manual testing finds the rest. (3) WHY IT MATTERS: authorization testing (IDOR) is the most commonly missed category in web app pentests because automated scanners cannot understand what the business logic intends; manual testing with two accounts is required. (4) WHAT BREAKS: relying on automated scanners alone; a scanner will not find a price manipulation vulnerability where a negative quantity results in a credit. (5) TAKEAWAY: run automated scans for efficiency, but follow with manual testing for authentication, authorization, and business logic; these are the high-value, high-impact findings.

**The key insight:**
The best pentest finding is one the client did not expect. Automated tools find what
is already known. The unique value of a skilled tester is finding chained vulnerabilities
and business logic flaws that tools miss.

**When to use it:**
Pre-launch for new applications handling sensitive data. Annual for production
systems. After significant architectural changes. After a security incident (to find
related vulnerabilities). As a compliance requirement (PCI DSS, SOC 2 Type II).

---

### 💻 Code Example

```python
# Example: Testing for IDOR vulnerabilities
# (authorized testing only - demonstrate methodology)

import requests

# BAD: API that has IDOR vulnerability
# GET /api/orders/12345 returns order for ANY user
# Only orderId is checked, not ownership

# GOOD test: automated IDOR detection
def test_idor_orders(base_url, token_user1,
                      user1_order_id,
                      token_user2):
    """
    Tests if user 2 can access user 1's orders.
    Returns True if IDOR vulnerability found.
    """
    headers_user2 = {
        "Authorization": f"Bearer {token_user2}",
        "Content-Type": "application/json"
    }

    # Attempt to access user1's order as user2
    response = requests.get(
        f"{base_url}/api/orders/{user1_order_id}",
        headers=headers_user2
    )

    if response.status_code == 200:
        data = response.json()
        # Verify the response contains user1's data
        if data.get("userId") != get_user_id(
                token_user2):
            print(f"IDOR FOUND: user2 accessed "
                  f"user1's order {user1_order_id}")
            print(f"Response: {data}")
            return True  # vulnerability confirmed
    elif response.status_code == 403:
        print("IDOR not present: 403 returned")
        return False
    elif response.status_code == 404:
        # 404 could be IDOR mitigation
        # or the resource does not exist
        print("WARN: 404 - may be security by obscurity")
        return False

    return False
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a structured IDOR test that uses two authenticated accounts to verify whether user2 can access user1's resources - the correct methodology for testing horizontal access control. (2) KEY MECHANISM: the test authenticates as user2 and requests a resource owned by user1; a 200 response with user1's data confirms IDOR; a 403 confirms correct access control; a 404 is ambiguous (could be security through obscurity). (3) WHY IT MATTERS: IDOR is one of the most common and highest-impact web app vulnerabilities; it is missed by automated scanners because the scanner does not understand resource ownership; this test requires two accounts and enumeration of resource IDs. (4) WHAT BREAKS: testing with a single account; the scanner must test as user2 requesting user1's specific resource ID - two accounts are required. (5) TAKEAWAY: write automated IDOR tests that enumerate resource IDs across accounts; run them as part of API security testing; include in the pentest scope for every new API endpoint.

```bash
# nmap scanning examples (authorized systems only)
# Reconnaissance and service discovery

# Host discovery
nmap -sn 192.168.1.0/24

# Service version scan with default scripts
nmap -sV -sC -p 80,443,8080,8443 target.com

# Full port scan (slow, thorough)
nmap -sV -p- target.com

# Vulnerability scan
nmap --script vuln target.com

# SSL/TLS configuration check
nmap --script ssl-cert,ssl-enum-ciphers \
  -p 443 target.com
```

> **Code walkthrough:** (1) WHAT IT SHOWS: common nmap commands for the reconnaissance and scanning phases - host discovery, service enumeration, and SSL configuration checks. (2) KEY MECHANISM: nmap sends crafted packets and analyzes responses to identify open ports, running services, service versions, and known vulnerabilities; the `-sC` flag runs default NSE scripts that detect common misconfigurations. (3) WHY IT MATTERS: service version information reveals which CVEs apply; outdated service versions with public exploits are high-severity findings; TLS configuration weaknesses (SSLv3, weak ciphers) are PCI DSS and HIPAA findings. (4) WHAT BREAKS: scanning without authorization; all nmap commands above require explicit written permission for the target; unauthorized scanning is illegal in most jurisdictions. (5) TAKEAWAY: start every pentest with thorough service enumeration; the attack surface is not just what was presented to you in scope - enumerate to discover what the client missed.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Penetration testing simulates an attack to find vulnerabilities. The five phases
> are reconnaissance (find targets and info), scanning (find open ports and services),
> exploitation (prove the vulnerability is exploitable), post-exploitation (show what
> an attacker can do after compromising a system), and reporting (document findings
> with remediation steps). Key tools: Burp Suite for web apps, nmap for network
> scanning, SQLMap for SQL injection testing.

---

**Senior / Staff (5+ years):**
> My pentest methodology starts with scope definition and rules of engagement - what
> is in scope, what is out of scope, is destructive testing allowed, is social
> engineering in scope? Then reconnaissance: enumerate all subdomains, find exposed
> cloud storage, check GitHub for leaked credentials. Scanning: Nuclei for known
> CVEs, manual Burp Suite testing for OWASP Top 10. The findings I value most are
> not the CVSS 9.8 known CVE (that shows up in automated scans) but the chained
> vulnerabilities: SSRF + metadata service access + IAM privilege escalation that
> requires understanding the cloud environment. Reporting: I categorize by impact,
> not just CVSS; a CVSS 6.0 SQL injection in an admin-only endpoint is lower
> priority than a CVSS 7.0 IDOR affecting all users.

---

### ⚠️ Common Misconceptions

**Misconception 1: "A vulnerability scan and a penetration test are the same thing."**

A vulnerability scan is automated: a tool looks up version numbers against CVE
databases and runs signatures. It produces false positives and misses business logic
flaws, IDOR vulnerabilities, and chained attacks. A penetration test includes manual
exploitation to prove impact, post-exploitation to demonstrate blast radius, and
human adversarial thinking. Compliance requirements (PCI DSS) explicitly require
penetration testing, not just vulnerability scanning.

**Misconception 2: "If the pentest found nothing, we are secure."**

A clean pentest result means the tester found nothing within the scope, time, and
skill constraints of that specific engagement. It does not mean no vulnerabilities
exist. Zero-day vulnerabilities, vulnerabilities outside the pentest scope, and
vulnerabilities requiring different expertise are all outside the result. A clean
pentest result should increase confidence but not eliminate the security program.

**Misconception 3: "The pentest scope should be as broad as possible."**

Broad scope without adequate time and resources produces shallow testing. A focused
pentest of the authentication and authorization system finds more critical findings
than a surface-level scan of 200 endpoints in the same time. Define scope based on
risk: what is the highest-value target? What has the highest likelihood of vulnerability?

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Findings not remediated after pentest.**

Symptom: pentest report delivered; findings sit in a backlog for months; next pentest
finds the same issues.
Root cause: no process to track and require remediation of pentest findings.
Fix: pentest findings enter the engineering backlog with severity-based SLAs (critical:
7 days, high: 30 days, medium: 90 days); progress tracked in weekly security review;
retest validates fixes.

**Failure Mode 2: Pentest scope excludes the most critical systems.**

Symptom: pentest of marketing website while payment processing system is out of scope.
Root cause: scope defined by what is least disruptive, not what has highest risk.
Fix: scope based on risk profile; payment and authentication systems are always highest
priority; if critical systems cannot be in scope for production pentest, test in
a staging environment that mirrors production.

**Failure Mode 3: Social engineering component excluded.**

Symptom: technical systems tested but phishing and pretexting (calling employees
for passwords) excluded. Attackers use social engineering as primary entry.
Root cause: social engineering feels intrusive; management reluctant to test employees.
Fix: include phishing simulation as a minimum; report on employee click rates; use
results for security awareness training, not employee punishment.

---

### ⚖️ Comparison Table

| Test type | Automated | Manual | Business logic | Blast radius | Cost |
|---|---|---|---|---|---|
| **Vulnerability scan** | Yes | No | No | No | Low |
| **Web app pentest** | Partial | Yes | Yes | Limited | Medium |
| **Network pentest** | Partial | Yes | No | Yes | Medium |
| **Red team exercise** | Partial | Yes (full) | Yes | Full | High |
| **Purple team** | Partial | Yes (collab) | Yes | Full | High |
| **Bug bounty** | Crowd | Yes | Yes | Limited | Variable |

---

### 🏛️ System Design

**Security Testing in the SDLC**

```
  DEV           CI/CD PIPELINE        PRODUCTION
  +------+      +----------------+    +----------+
  | Code |----->| SAST (SonarQube)|   | Annual   |
  | Review      | Dependency Scan |   | Pentest  |
  | (manual     | Secret Scan    |   | PCI/SOC2 |
  |  security   | OWASP ZAP DAST |   +----------+
  |  checklist) | Docker scan    |
  +------+      +----------------+    +----------+
                        |             | Continuous|
                        |             | Monitoring|
                        v             | (SIEM)    |
                   Staging Env        +----------+
                   - Pre-prod pentest
                   - Load/perf test
                   - Red team (quarterly)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: security testing integrated across the SDLC - from code review in development through CI/CD pipeline scanning to periodic production penetration testing. (2) HOW TO READ IT: left to right shows the software delivery pipeline; each box shows what security activities occur at that stage. (3) KEY RELATIONSHIP: earlier-stage security testing (SAST, dependency scan) is cheaper to fix and more frequent; later-stage testing (pentest, red team) is more realistic but more expensive. (4) EDGE CASE: a critical vulnerability in production that was not caught by SAST indicates either a logic flaw (SAST cannot catch) or a gap in SAST rule coverage; use postmortem to add detection. (5) INSIGHT: a senior engineer designs the pipeline so that SAST/DAST failures block deployment; findings that would have required a pentest to find in production are now caught before deployment.

---

### 📊 Diagram

```
PENTEST ENGAGEMENT LIFECYCLE:

  SCOPING:
    Define targets + rules of engagement
    Written authorization (REQUIRED)
    Emergency contact + abort criteria
          |
          v
  RECON: Find attack surface
    Subdomains, tech stack, OSINT
          |
          v
  SCAN: Find entry points
    Ports, services, web endpoints
          |
          v
  EXPLOIT: Prove impact
    Burp Suite, SQLMap, custom scripts
          |
          v
  POST-EXPLOIT: Measure blast radius
    Privesc, lateral movement, data proof
          |
          v
  REPORT: Deliver findings
    Severity, repro, evidence, remediation
          |
          v
  RETEST: Verify fixes
    Confirm critical/high findings resolved
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the complete pentest engagement lifecycle from scoping to retest, emphasizing that written authorization is the mandatory first step. (2) KEY MECHANISM: each phase feeds the next; incomplete reconnaissance means exploitation misses attack surface; incomplete exploitation means post-exploitation cannot demonstrate true blast radius. (3) WHY IT MATTERS: the lifecycle enforces discipline; a pentest that skips scoping or retest is not professionally complete and does not serve the client's security goals. (4) WHAT BREAKS: a pentest that ends at exploitation without post-exploitation underestimates impact; proving "SQL injection exists" is not as impactful as proving "SQL injection provides full database read access including 2.5M user records". (5) TAKEAWAY: always complete all phases; retest is not optional - a finding without a verified fix is an open vulnerability; retesting confirms the remediation actually works.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Phases, types |
| Mechanism | 2 | Tools, methodology |
| Application | 2 | Web app, authorization |
| Scenario | 3 | Report prioritization, scope, incident |
| Trade-off | 2 | Types, automated vs manual |
| Behavioral | 1 | Pentest leadership |

---

**[MID] Q1 (Definition): What are the five phases of a penetration test?**

Reconnaissance: gather information about the target. Passive reconnaissance does not
interact with the target: OSINT, Google dorking, Shodan, subdomain enumeration,
technology stack fingerprinting, LinkedIn for employee names. Active reconnaissance
interacts with the target: DNS queries, port probing, web crawling.

Scanning and enumeration: identify specific services, versions, and potential
vulnerabilities on the target. Port scanning (nmap), service version detection,
web application crawling, directory brute forcing, API endpoint discovery, automated
vulnerability scanning (Nuclei, Nikto).

Exploitation: attempt to exploit identified vulnerabilities to prove they are
genuinely exploitable, not theoretical. Burp Suite for web app testing, SQLMap for
SQL injection, Metasploit for service exploits. Goal: demonstrate impact (data access,
code execution) with controlled evidence.

Post-exploitation: after gaining initial access, explore what an attacker could do:
privilege escalation (gaining admin/root access), lateral movement (accessing other
systems), data exfiltration proof (accessing sensitive records), persistence demo.
Always within rules of engagement; never actually exfiltrate real data.

Reporting: document all findings with CVSS severity scores, reproduction steps,
evidence (screenshots, HTTP requests), business impact description, and remediation
recommendations. Deliver executive summary (business risk language) and technical
details (engineer-level reproduction steps).

*What separates good from great:* The retest phase after reporting. A finding is
not resolved until the fix is verified. Critical and high findings should be retested
within the remediation SLA. Remediation reports without retest confirmation leave
open the question of whether the fix actually works.

---

**[MID] Q2 (Definition): What is the difference between black-box, gray-box, and white-box testing?**

Black-box testing: the tester has no information about the target system. They start
from the position of an external attacker with only the target's public-facing resources.
Advantage: most realistic simulation of an external attacker.
Disadvantage: significant time spent on reconnaissance; may miss vulnerabilities
that are only exploitable with internal knowledge.

Gray-box testing: the tester has partial information - typically: the application URL,
test credentials for different roles, and sometimes API documentation.
Advantage: more efficient than black-box; tester can focus on logic and authorization
rather than discovery.
Disadvantage: does not simulate a completely external attacker; some insider-threat
scenarios are not covered.

White-box testing: the tester has full information - source code, architecture
diagrams, infrastructure details, all credentials, and test environments.
Advantage: most thorough; can find vulnerabilities that would never be discovered
in black-box (e.g., hard-coded cryptographic constants, subtle logic flaws in code).
Disadvantage: does not simulate an external attacker; requires more tester expertise
to review code effectively; findings may not be externally exploitable.

Most common engagement: gray-box for web application pentests (provides test
credentials for authorization testing); white-box (code review + pentest) for
the highest assurance.

*What separates good from great:* Recognizing that white-box is not strictly better.
Black-box testing validates that an external attacker cannot find vulnerabilities
from public exposure alone - this is a different quality bar than white-box.
A mature security program includes both: white-box for internal quality; black-box
for external exposure validation.

---

**[SENIOR] Q3 (Mechanism): How do you test for authorization vulnerabilities (IDOR) in an API?**

Insecure Direct Object References require testing with two accounts of the same
privilege level (testing horizontal access control) and accounts of different
privilege levels (testing vertical access control).

Horizontal IDOR testing:
1. Log in as User A. Perform actions that create and retrieve resources
   (orders, documents, messages). Note all resource IDs used.
2. Log in as User B. Attempt to access User A's resources using the same IDs.
3. Expected: 403 Forbidden. Finding: 200 OK with User A's data.

Tools: Burp Suite Autorize plugin - the Autorize plugin intercepts all requests
and automatically replays them with a second account's cookies. Any request that
returns 200 with different credentials is flagged as a potential IDOR.

Vertical IDOR testing:
1. Log in as a regular user. Attempt to access admin endpoints.
2. Attempt to modify request parameters to invoke admin operations.
3. Expected: 403 Forbidden. Finding: any success.

Common IDOR patterns to test:
- Numeric sequential IDs: change `?id=123` to `?id=122`
- UUID-based IDs: test if the endpoint validates ownership (UUIDs provide obscurity,
  not authorization)
- Indirect references: `?file=invoice.pdf` - test for path traversal
  (`?file=../config.properties`)

*What separates good from great:* Testing all HTTP methods on each resource endpoint.
A resource that correctly restricts GET may allow PUT or DELETE for unauthorized users.
Use Burp Suite Intruder to test all HTTP methods on all endpoints with both accounts.

---

**[SENIOR] Q4 (Application): Walk through a typical web application pentest for a REST API.**

Pre-engagement: receive written authorization, test credentials for each user role,
API documentation (or OpenAPI spec), base URL, and any out-of-scope paths.

Phase 1 - Reconnaissance: enumerate API endpoints from documentation; try to discover
undocumented endpoints via Burp Spider, ffuf, or wordlists; identify authentication
mechanism (JWT, session cookie, API key); note the tech stack from response headers.

Phase 2 - Authentication testing:
- Test for weak password policy (Burp Intruder)
- Test for account lockout (try 100 invalid passwords)
- Test for credential enumeration (different errors for valid vs invalid usernames)
- Test for JWT issues: algorithm confusion, weak secret, missing expiry validation

Phase 3 - Authorization testing:
- IDOR horizontal: access other users' resources
- IDOR vertical: regular user accesses admin endpoints
- Missing function level access control: find admin endpoints by brute-forcing paths

Phase 4 - Injection testing:
- SQLMap on all parameters
- Manual SSTI testing (Burp Repeater with template payloads)
- Command injection on parameters that might reach system calls

Phase 5 - Business logic:
- Test workflows out of order (skip payment step)
- Test for negative values (negative quantity, negative price)
- Test for mass assignment (send extra JSON fields that should not be settable)

Finding documentation: for each finding, record the HTTP request and response in
Burp Suite history; export as evidence; write reproduction steps from scratch
(not just "see Burp history").

*What separates good from great:* Mass assignment testing. Modern APIs that use
JSON often accept extra fields in the request body and map them to the object.
`PUT /api/users/123` with body `{"name": "Alice", "role": "admin"}` - does the
API update the role? This is missed by automated scanners and has led to several
high-profile privilege escalation findings.

---

**[SENIOR] Q5 (Mechanism): How do you use Burp Suite for a web application penetration test?**

Burp Suite is a proxy-based web app testing platform. Core workflow:

Proxy setup: configure browser to route through Burp at `127.0.0.1:8080`.
All HTTP/HTTPS traffic passes through Burp and is captured in Proxy > HTTP history.

Target scoping: set the target scope (Settings > Target > Scope) to the test domain
only. This prevents logging unrelated traffic and focuses tools on the target.

Crawling: Burp Spider (Pro) or manual browsing in the browser with Burp recording
captures all endpoints and forms. Review the Sitemap for discovered resources.

Scanning (Pro): Active scanner runs OWASP checks on all discovered endpoints.
Review findings: many are false positives; confirm each manually.

Manual testing workflow - Repeater:
Find a request in HTTP history. Send to Repeater (Ctrl+R). Modify parameters and
resend to see how the server responds. Test for injection, IDOR, parameter tampering.

Manual testing - Intruder:
For brute-force, fuzzing, or enumeration. Mark payload positions in a request.
Choose a payload list. Attack. Review responses for anomalies (size, status code).

Manual testing - Extender + plugins:
Autorize: IDOR detection (automatic second-account replay).
JWT Editor: JWT manipulation (algorithm confusion, expired tokens).
ActiveScan++: additional scanner rules.

Sequencer: analyze token randomness (session IDs, CSRF tokens). Weak entropy
is a vulnerability.

*What separates good from great:* The Burp Intruder for authorization bypass.
Set the Authorization header as a parameter with two values: valid token, no token.
Run against all endpoints. Any endpoint that returns 200 with no token = missing auth.
This finds forgotten, undocumented endpoints that are not in the API documentation.

---

**[SENIOR] Q6 (Scenario): A pentest report has 40 findings. How do you prioritize remediation?**

Prioritize by: (1) exploitability (how easy?), (2) impact (what happens if exploited?),
(3) exposure (who can reach it?), combined with the CVSS score.

Immediate action (within 24-48 hours):
- Active exploitation evidence: if the pentest report includes evidence of active
  exploitation (data extracted, shell obtained), treat as an incident response, not
  a remediation ticket.
- Critical (CVSS >= 9.0) + internet-exposed: SQL injection on a public endpoint,
  SSRF to metadata service, authentication bypass.

7-day remediation:
- Critical (CVSS >= 9.0) in general.
- High (CVSS 7.0-8.9) on internet-exposed endpoints.
- Authentication and authorization issues at any severity.

30-day remediation:
- High findings on internal systems.
- Medium (CVSS 4.0-6.9) on internet-exposed endpoints.

90-day remediation:
- Medium on internal systems.
- Low informational findings.

Additional factors that override CVSS: business logic flaws that have CVSS 6.0 but
allow fraudulent transactions (business impact >> technical score); IDOR on
user data (privacy/regulatory impact may mandate faster remediation than CVSS suggests);
authentication issues always treated as high priority regardless of CVSS.

Track progress in a security findings register with: CVE/finding ID, severity, owner,
due date, status (open/in-progress/resolved/retested). Review in weekly security meeting.

*What separates good from great:* Not using CVSS alone. CVSS measures technical severity;
it does not account for business context. A CVSS 6.0 finding that allows an attacker
to access the financial records of all customers is a business-critical issue. Complement
CVSS with "if exploited, what is the worst case business impact?" as a second dimension.

---

**[SENIOR] Q7 (Trade-off): When should you use a red team exercise vs a traditional penetration test?**

Traditional penetration test: defined scope, defined timeframe (2-4 weeks), structured
methodology (OWASP, PTES), all findings documented. Tests whether known vulnerabilities
exist. The blue team (defenders) typically knows the test is happening.

Red team exercise: adversarial, long-duration (3+ months), full kill chain simulation
(social engineering + physical + technical), objective-based (get to the crown jewel),
blue team does not know the test is happening.

Choose penetration test when:
- Compliance requirement (PCI DSS, SOC 2, ISO 27001) - specific requirements for scope
- New application before launch (specific surface needs assessment)
- Specific system needs security validation
- Budget is constrained (pentest is less expensive)
- Team is early in security maturity (pentest finds the low-hanging fruit first)

Choose red team when:
- Testing detection and response capabilities, not just prevention
- Testing the full kill chain (social engineering + technical)
- High security maturity (basic vulnerabilities already remediated)
- Testing realistic attacker scenarios against specific targets (crown jewels)
- Simulating an APT (Advanced Persistent Threat) specific to the industry

Misconception to avoid: "we had a red team exercise, so we do not need a pentest."
They test different things. Pentesting validates the absence of known vulnerabilities.
Red teaming validates the effectiveness of the security program as a whole.

*What separates good from great:* Purple teaming. Instead of blue team vs red team,
both work collaboratively. Red team executes attack techniques; blue team watches and
tunes detection rules in real time. More learning per hour; improves detection
capabilities faster than a pure red team exercise. Suitable for mature security programs.

---

**[SENIOR] Q8 (Mechanism): How do you test for SQL injection manually (without SQLMap)?**

Manual SQL injection testing is required when automated tools are noisy, out-of-scope,
or when demonstrating impact to a skeptical developer.

Step 1 - Identify candidate parameters: any parameter that correlates to database
retrieval. URL parameters, POST body fields, JSON fields, HTTP headers (User-Agent,
Referer, X-Forwarded-For can reach database queries).

Step 2 - Probe for error-based SQL injection:
- Input: `'` (single quote) - causes SQL syntax error in vulnerable queries
- Look for: database error message, abnormal response, 500 status
- Input: `''` (two quotes) - fixes the syntax; normal response confirms SQL interpretation

Step 3 - Boolean-based blind SQL injection:
- Input on condition known to be true: `' OR '1'='1` - should return all records or true
- Input on condition known to be false: `' AND '1'='2` - should return empty or false
- Compare responses: different responses confirm blind SQLi

Step 4 - Time-based blind SQL injection (MySQL):
- `'; SELECT SLEEP(5); --` - if response takes 5+ seconds, time-based SQLi confirmed
- Safe to use in pentests; no data is modified

Step 5 - Union-based extraction (once injection confirmed):
- Determine column count: `' ORDER BY 1,2,3,...-- ` until error
- Extract data: `' UNION SELECT username,password,NULL FROM users-- `

Evidence documentation: capture the HTTP request in Burp Repeater; capture the
modified request and the server response; note the parameter, the payload, and
the evidence of injection (error message, different response, time delay).

*What separates good from great:* Testing beyond URL parameters. HTTP headers that
reach database queries are frequently missed. `User-Agent: ' OR '1'='1` submitted
to any endpoint that logs user agents; if the application stores logs in a database,
SQL injection via headers is possible. Burp Scanner tests headers automatically; manual
testers should include `X-Forwarded-For`, `Referer`, and custom headers.

---

**[SENIOR] Q9 (Scenario): You find a critical SQL injection vulnerability during a pentest. How do you handle it?**

A critical finding mid-engagement requires immediate escalation beyond the normal
report delivery process.

Immediate notification: contact the pentest point-of-contact immediately via phone
or secure channel (not email if the mail system might be compromised). Report the
finding with enough detail to triage but not more - do not send the full exploitation
chain unsolicited.

Confirm scope: is post-exploitation with this finding in scope? Extracting even
a sample of records should have explicit written authorization. If post-exploitation
is not authorized, document the finding and stop at proof-of-concept.

Verify severity: confirm the injection is exploitable (not a theoretical parser issue).
Use a safe payload: boolean-based blind with a time delay (SLEEP) to confirm execution
without data modification. Document: which endpoint, which parameter, which database
user the query runs as.

Provide remediation guidance immediately: do not wait for the final report.
The finding severity justifies immediate guidance:
1. Use parameterized queries / prepared statements
2. Reduce database user privileges (principle of least privilege)
3. Enable WAF SQL injection rules as temporary mitigation

Continue the engagement: do not stop the pentest. Other findings may be equally
or more severe. The critical finding is escalated; the engagement continues.

*What separates good from great:* The privilege context. "SQL injection exists" is
a finding. "SQL injection exists and the database user has db_owner privilege,
allowing xp_cmdshell execution and OS command execution on the database server"
is a critical incident. Always check the database user's privileges as part of
SQL injection proof-of-concept.

---

**[SENIOR] Q10 (Trade-off): How do you decide the scope and timing for a production penetration test?**

Scope decisions:

What to include: any system handling sensitive data (PII, financial, health);
authentication and authorization systems; payment processing; external APIs; recently
changed systems (most likely to have regressions); systems handling the most traffic.

What to consider excluding: systems with no external exposure and no sensitive data;
systems that cannot tolerate any testing (certain embedded systems, life-critical
infrastructure); systems already retested recently with no findings.

Timing:
Production testing risk: pentest activities can cause unintended outages (resource
exhaustion from scanning, DoS-like behavior from Intruder). Test during business
off-hours (weekend night) for critical systems if any testing could cause disruption.

Staging vs production: if staging is an accurate mirror of production (same code,
same data schema, similar config), test in staging first. Production testing provides
the most accurate results but has the highest risk.

Continuous pentesting: bug bounty programs provide ongoing adversarial testing
between point-in-time engagements. Complement annual pentests with a bug bounty
program for critical assets.

Rules of engagement: document what tools and techniques are allowed. Automated
scanning allowed? Social engineering in scope? Physical security? Destructive testing
(dropping tables, deleting files) is always out of scope. The rules of engagement
are a contract; they protect both tester and organization.

*What separates good from great:* The scope negotiation mindset. Organizations tend
to scope out the highest-risk systems ("we cannot have anyone poking at payment
processing"). Push back: "the highest-risk system being outside scope means it is
also outside your security assurance. Let us test it in staging first." Frame as
risk management: the risk of an untested system is higher than the risk of a tested
one.

---

**[SENIOR] Q11 (Scenario): After a pentest, the dev team disputes several findings as "not exploitable in practice." How do you respond?**

Disputing findings is legitimate and healthy. The goal is accurate risk assessment,
not a high finding count.

Evaluate the argument: what specifically is the developer claiming is not exploitable?
Is the claim: requires physical access (legitimate reduction in risk), requires prior
authentication (valid context, reduces likelihood but not severity), or "it would
never be done" (opinion, not technical evidence)?

Valid disputes:
- Finding requires a specific combination of conditions that the production environment
  prevents (e.g., the vulnerable code path is only reached from an internal network
  that is firewall-restricted). Reduce severity accordingly.
- The vulnerability class is mitigated by a compensating control not in scope
  (the SQL injection endpoint is behind a WAF rule that blocks all SQL keywords).
  Document the compensating control; reduce severity but keep the finding.

Invalid disputes:
- "Attackers would not know to look for this": security by obscurity is not a mitigation.
- "We have never been hacked": past success is not a security control.
- "It would require too much effort for an attacker": quantify "too much effort"
  with specific technical constraints.

Process: findings disputed by the development team should be reviewed jointly with
a security architect. If there is genuine disagreement on severity, escalate to CISO.
Document the resolution: finding accepted as-is, severity reduced with rationale,
or finding closed as not exploitable with technical justification.

*What separates good from great:* Treating disputes as opportunities for accuracy.
A false positive wastes remediation effort. A legitimate false positive dispute,
validated and documented, improves the report quality and builds trust with the
engineering team. The goal is accurate risk communication, not a high finding count.

---

**[STAFF] Q12 (Behavioral): You are building a penetration testing program from scratch for a 500-person company with no current pentest program. What do you do in the first 90 days?**

Day 1-30 - Assessment and foundation:
Inventory all systems: identify all applications, APIs, and infrastructure. Classify
by risk (handles PII, financial data, internet-exposed vs internal).
Identify compliance requirements: PCI DSS, SOC 2, HIPAA all have explicit pentest
requirements with scope and frequency; use compliance requirements to get budget approval.

Day 30-60 - First engagement:
Select highest-risk target: the internet-facing application handling the most sensitive
data. Issue RFP or select a pentest firm (ensure they have relevant expertise for the
tech stack). Define scope, rules of engagement, and deliverables.
Internal capability: begin Burp Suite training for one developer on each team to
enable lightweight OWASP testing before external pentests.

Day 60-90 - Program structure:
Publish findings SLA: define response times by severity (critical: 7 days, high: 30,
medium: 90).
Create findings register: track all findings from the first engagement through
remediation and retest.
Schedule recurring engagements: annual pentest for all systems; bi-annual for
highest-risk systems.

Bug bounty consideration: if engineering capacity for remediation is sufficient
and code is mature, initiate a private bug bounty program to provide continuous
adversarial testing between point-in-time engagements.

Metrics to track: mean time to remediation by severity; findings count by category
(authentication, authorization, injection) - patterns identify systemic issues;
retest pass rate - high pass rate indicates effective remediation; repeat findings
across engagements indicate systemic quality issues.

*What separates good from great:* The internal champion model. Send a developer from
each team to basic web app security training (OWASP WebGoat, PortSwigger Web Security
Academy - free). They become the team's security touchpoint for code reviews,
not a pentest substitute, but an early warning system. Security issues caught in
code review are 100x cheaper to fix than findings from a production pentest.
