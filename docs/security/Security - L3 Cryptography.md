---
layout: default
title: "Security - L3 Cryptography"
parent: "Security"
nav_order: 6
permalink: /security/l3-cryptography/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Cryptography: Hashing, Symmetric, and Asymmetric Encryption](#cryptography-hashing-symmetric-and-asymmetric-encryption) | critical |
| 2 | [Secrets Management: Vault, KMS, and Rotation](#secrets-management-vault-kms-and-rotation) | high |

---

# Cryptography: Hashing, Symmetric, and Asymmetric Encryption

---
id: SEC-014
title: "Cryptography: Hashing, Symmetric, and Asymmetric Encryption"
category: Security
difficulty: ★★☆
interview_weight: critical
asked_at: All
seniority: mid
tags: #security, #cryptography, #hashing, #encryption, #asymmetric
status: draft
sd: false
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Hashing is a one-way function: SHA-256 produces a fixed fingerprint; you cannot
> reverse it. Symmetric encryption (AES-256-GCM) uses one key to encrypt and decrypt -
> fast, good for data at rest. Asymmetric encryption (RSA/ECDSA) uses a public key
> to encrypt or verify, and a private key to decrypt or sign - slower, used for key
> exchange and signatures. Each solves a different problem.

**3 minutes (Senior):**
> Hashing verifies integrity: SHA-256 a file and the hash changes if one byte is
> altered. For passwords: use bcrypt, scrypt, or Argon2 (slow-by-design) NOT SHA-256
> (fast hashing allows 10 billion guesses per second on a GPU). Symmetric encryption
> (AES-256-GCM) encrypts data; GCM mode provides authenticated encryption - decryption
> fails if the ciphertext is tampered with. Key distribution is the hard part. Asymmetric
> encryption solves key distribution: share the public key freely, keep the private key
> secret. RSA-OAEP for key transport; ECDSA for digital signatures (smaller keys than
> RSA for equivalent security). In practice: TLS uses asymmetric crypto during handshake
> to establish a session key, then symmetric crypto for the data. Diffie-Hellman key
> exchange lets two parties derive a shared secret without transmitting it.

**Framework:** Hash (integrity/passwords) → Symmetric (bulk encryption) → Asymmetric (key exchange/signatures) → Hybrid (TLS model)

**Blank Mind Recovery:**

**(1) Restate:** "Cryptography transforms data to provide confidentiality, integrity,
and authentication. Three primitive types serve different purposes."

**(2) First principles:** "Hashing = fingerprint (one-way). Symmetric = lockbox with
one key. Asymmetric = lockbox with a padlock (public) and a key (private)."

**(3) Bridge:** "Hashing is like a document's ISBN - unique, not reversible.
Symmetric is like a house key. Asymmetric is like a mailbox - anyone can put mail in
(public key), only you retrieve it (private key)."

---

### 📘 Concept Explanation

**What it is:**
Cryptographic primitives transform data to provide security properties. Hashing:
deterministic one-way function producing a fixed-size digest. Symmetric encryption:
reversible transformation using one shared key. Asymmetric encryption: reversible
using a keypair where one key encrypts and the other decrypts.

**The problem it solves:**
Security requires confidentiality (only authorized parties read data), integrity
(data has not been modified), and authentication (the sender is who they claim).
Cryptographic primitives provide these properties mathematically.

**How it works:**

```
HASHING:
  Input: "password123"
  SHA-256: 5e884898da...  (64 hex chars, fixed size)
  SHA-256("password124"): a3f3b83a1c... (completely different)
  CANNOT reverse: given hash, cannot recover input

  Password storage (BAD → GOOD):
  BAD:  SHA-256(password) -> GPU cracks at 10B/sec
  GOOD: Argon2id(password, salt, cost) -> 1ms/attempt

  Use cases: checksums, HMAC, password hashing,
             Merkle trees, certificate fingerprints
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the critical difference between fast hashes (SHA-256, MD5) and slow password hashes (Argon2id, bcrypt). (2) KEY MECHANISM: SHA-256 is designed for speed; a GPU can test 10 billion passwords per second against a stolen SHA-256 hash; Argon2id is parameterized to require configurable memory and CPU time per hash, making bulk cracking economically infeasible. (3) WHY IT MATTERS: password database breaches are inevitable; the hashing algorithm determines whether stolen hashes translate to cracked accounts within hours or decades. (4) WHAT BREAKS: using SHA-256 for passwords; bcrypt truncates at 72 bytes (long passwords not fully hashed); Argon2id is the current recommendation. (5) TAKEAWAY: SHA-256 = integrity and fingerprinting; Argon2id/bcrypt/scrypt = password storage; never swap them.

```
SYMMETRIC ENCRYPTION (AES-256-GCM):
  Key: 256-bit random key (32 bytes)
  IV/Nonce: random, 12 bytes, UNIQUE per encryption
  Encrypt: AES-GCM(key, iv, plaintext) -> ciphertext + auth_tag
  Decrypt: AES-GCM(key, iv, ciphertext, auth_tag)
           -> plaintext OR authentication failure
  Auth tag: proves ciphertext not tampered (AEAD)

  Key insight: GCM mode = encryption + integrity in one pass
  Warning: reusing same IV with same key = catastrophic
```

> **Code walkthrough:** (1) WHAT IT SHOWS: AES-256-GCM as an AEAD cipher - it simultaneously encrypts and authenticates, so any tampering with the ciphertext causes decryption to fail with an authentication error. (2) KEY MECHANISM: AES-GCM uses a 12-byte nonce; the nonce must be unique for every encryption operation with the same key; reuse allows an attacker to derive the keystream and decrypt or forge messages. (3) WHY IT MATTERS: AEAD eliminates the separate MAC-then-encrypt pattern that caused padding oracle attacks in TLS 1.0/1.1; one primitive handles both security properties. (4) WHAT BREAKS: IV/nonce reuse is catastrophic; generate a random 12-byte nonce per encryption, store it alongside the ciphertext (it is not secret). (5) TAKEAWAY: AES-256-GCM is the standard symmetric choice; use ChaCha20-Poly1305 for environments without hardware AES acceleration.

```
ASYMMETRIC ENCRYPTION (RSA/ECDSA):
  Key generation:
    Private key: kept secret by owner
    Public key:  shared with anyone

  RSA-OAEP (key transport):
    Encrypt:  RSA-OAEP(public_key, plaintext) -> ciphertext
    Decrypt:  RSA-OAEP(private_key, ciphertext) -> plaintext
    Use case: wrapping symmetric keys for transport

  ECDSA/EdDSA (digital signatures):
    Sign:     ECDSA(private_key, message) -> signature
    Verify:   ECDSA(public_key, message, signature) -> bool
    Use case: JWT (RS256), TLS certificates, code signing
    
  RSA-2048 security ~ ECDSA-224 security
  ECDSA-256 (P-256) standard for most TLS certificates
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the two main asymmetric operations - encryption/decryption (RSA-OAEP) for key transport and sign/verify (ECDSA) for authenticity. (2) KEY MECHANISM: RSA uses the mathematical difficulty of factoring the product of two large primes; ECDSA uses the discrete logarithm problem on elliptic curves; both are asymmetric - one key is computationally derived from the other but the reverse is infeasible. (3) WHY IT MATTERS: asymmetric crypto solves the key distribution problem - you can publish your public key without compromising security; this enables TLS, PGP, and JWT. (4) WHAT BREAKS: RSA below 2048 bits is deprecated (NIST); RSA-PKCS1v1.5 padding is vulnerable to Bleichenbacher attacks; always use RSA-OAEP for encryption. (5) TAKEAWAY: use ECDSA P-256 or Ed25519 for signatures (smaller, faster than RSA); use RSA-OAEP-2048 for key wrapping when RSA is required.

**The key insight:**
TLS uses all three: asymmetric crypto during handshake (certificate signature verification,
key exchange), symmetric crypto for the data channel, and hashing for HMAC message
authentication. This is the hybrid model - asymmetric solves key distribution,
symmetric solves bulk throughput.

**When to use it:**
Hashing: file integrity, password storage, HMAC.
Symmetric: data at rest encryption, bulk data.
Asymmetric: key exchange, digital signatures, certificate validation.

**When NOT to use it:**
Never roll your own cryptography. Never use MD5 or SHA-1 for security purposes.
Never use ECB mode (patterns visible in ciphertext). Never use RSA-PKCS1v1.5 padding.

**Alternatives:**
- ChaCha20-Poly1305: symmetric AEAD without hardware AES requirement
- Ed25519: modern EdDSA; faster and more robust than ECDSA
- Curve25519 (X25519): DH key exchange; used in TLS 1.3 and Signal

---

### 💻 Code Example

```java
// BAD: Fast hash for passwords - GPU-crackable
public String hashPasswordBad(String password) {
    // SHA-256 runs at ~10 billion/sec on GPU
    // Stolen hash cracked in seconds
    return DigestUtils.sha256Hex(password);
}

// GOOD: Slow adaptive hash with Argon2id
@Bean
public PasswordEncoder passwordEncoder() {
    return Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8();
    // memory=9MB, iterations=1, parallelism=1
    // ~1ms per attempt even on GPU
}

// Usage:
encoder.encode("userPassword")       // store result
encoder.matches("input", stored)     // verify
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the password hashing failure mode (SHA-256) and the correct approach (Argon2id via Spring Security). (2) KEY MECHANISM: Argon2id requires configurable memory and CPU work; the cost parameters mean one hash attempt takes ~1ms even on specialized hardware; SHA-256 takes nanoseconds. (3) WHY IT MATTERS: in a breach of 10 million accounts with SHA-256 hashes, a GPU cluster cracks weak passwords in hours; with Argon2id the same attack takes centuries. (4) WHAT BREAKS: bcrypt truncates passwords at 72 bytes - a password longer than 72 bytes provides no additional security; Argon2id has no such limit. (5) TAKEAWAY: use Argon2id (preferred), bcrypt, or scrypt for passwords; SHA-256 is for file integrity checks, never passwords.

```java
// AES-256-GCM: Authenticated Encryption
import javax.crypto.*;
import javax.crypto.spec.*;

public class AesGcmCipher {
    private static final int KEY_LEN = 256;
    private static final int TAG_LEN = 128;
    private static final int IV_LEN  = 12;

    public byte[] encrypt(
            SecretKey key, byte[] plaintext)
            throws Exception {
        // ALWAYS generate a random IV per encryption
        byte[] iv = new byte[IV_LEN];
        new SecureRandom().nextBytes(iv);

        Cipher c = Cipher.getInstance("AES/GCM/NoPadding");
        c.init(Cipher.ENCRYPT_MODE, key,
            new GCMParameterSpec(TAG_LEN, iv));
        byte[] cipher = c.doFinal(plaintext);

        // Prepend IV: [iv(12)] [ciphertext + auth_tag]
        byte[] result = new byte[IV_LEN + cipher.length];
        System.arraycopy(iv, 0, result, 0, IV_LEN);
        System.arraycopy(cipher, 0, result, IV_LEN,
            cipher.length);
        return result;
    }

    public byte[] decrypt(
            SecretKey key, byte[] data)
            throws Exception {
        // Extract IV from first 12 bytes
        byte[] iv = Arrays.copyOf(data, IV_LEN);
        byte[] cipherWithTag = Arrays.copyOfRange(
            data, IV_LEN, data.length);

        Cipher c = Cipher.getInstance("AES/GCM/NoPadding");
        c.init(Cipher.DECRYPT_MODE, key,
            new GCMParameterSpec(TAG_LEN, iv));
        // Throws AEADBadTagException if tampered
        return c.doFinal(cipherWithTag);
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: complete AES-256-GCM encrypt/decrypt with correct IV generation, storage, and authenticated decryption failure handling. (2) KEY MECHANISM: the IV is prepended to the ciphertext so it is available during decryption without a separate lookup; the 128-bit GCM auth tag (appended by Java to the ciphertext) causes `AEADBadTagException` if any byte of the ciphertext is modified. (3) WHY IT MATTERS: prepending the IV is the standard storage convention; the IV is not secret - it only must be unique; the auth tag catches both accidental corruption and deliberate tampering. (4) WHAT BREAKS: generating a new key for every encryption instead of reusing a stored key; generating the same IV twice with the same key (IV reuse); using ECB mode (patterns visible). (5) TAKEAWAY: generate a random IV per encryption; prepend it to ciphertext; let GCM auth tag detect any tampering; generate the encryption key once and store it securely.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Hashing is one-way: SHA-256 produces a fixed fingerprint you cannot reverse. Symmetric
> encryption (AES) uses one key; asymmetric (RSA) uses a keypair. For passwords: use
> bcrypt or Argon2, not SHA-256. For data encryption: AES-256-GCM provides both
> confidentiality and integrity in one operation.

---

**Senior / Staff (5+ years):**
> The critical choice is mode of operation for symmetric: GCM provides AEAD
> (authenticated encryption with associated data) - no separate HMAC needed.
> CBC requires manual HMAC and has padding oracle vulnerability history (POODLE).
> For asymmetric: ECDSA P-256 or Ed25519 for signatures (JWT RS256 vs ES256);
> Ed25519 has better security properties and faster signing. The TLS 1.3 model is
> the production reference: ECDH (X25519) for forward-secret key exchange, then
> AES-256-GCM or ChaCha20-Poly1305 for the session. At the staff level: key management
> is harder than algorithm choice. A correct algorithm with a hard-coded key is
> catastrophically insecure.

---

### ⚠️ Common Misconceptions

**Misconception 1: SHA-256 is secure for password storage.**

SHA-256 is a fast general-purpose hash designed for speed. It runs at billions of
iterations per second on modern GPUs. Storing passwords with SHA-256 means a breach
allows an attacker to recover all passwords with weak entropy in hours. Use bcrypt,
scrypt, or Argon2id - designed to be slow and memory-intensive.

**Misconception 2: Encryption provides integrity.**

AES in CBC mode (or ECB) provides only confidentiality. An attacker can flip bits in
the ciphertext and the decryption succeeds but produces garbage plaintext - the
application may accept corrupted data. AES-GCM or separate HMAC provides integrity.

**Misconception 3: RSA encryption is used for bulk data.**

RSA is orders of magnitude slower than symmetric encryption and has a size limit
(RSA-2048 can encrypt ~245 bytes). RSA is used for key transport: encrypt a random
symmetric key with RSA, then use that symmetric key for the actual data (hybrid scheme).

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Nonce/IV reuse in AES-GCM.**

Symptom: ciphertext XOR reveals plaintext; authenticated data can be forged.
Diagnosis: check if nonce is reused (static nonce, counter overflow, seeded RNG).
Fix: always generate a random nonce with `SecureRandom`; for high-volume encryption,
use a deterministic nonce with a counter in a monotonically increasing format.

**Failure Mode 2: Using MD5 or SHA-1 for security purposes.**

Symptom: DAST or compliance scan flags MD5/SHA-1 usage; certificate signature is SHA-1.
Diagnosis: `grep -r 'MD5\|SHA1\|SHA-1' src/`.
Fix: SHA-256 minimum for non-password hashing; TLS certificates must use SHA-256
or better; Java `MessageDigest.getInstance("MD5")` must be replaced.

**Failure Mode 3: Hard-coded encryption keys.**

Symptom: static analysis or code review finds key material in source.
Diagnosis: `git log -p --all | grep -E '[0-9a-f]{32,}'` for likely key strings.
Fix: keys in Vault or KMS; load at startup via environment variables or secrets
injection; rotate immediately if exposed.

---

### ⚖️ Comparison Table

| Aspect | Hashing | Symmetric (AES-GCM) | Asymmetric (ECDSA) |
|---|---|---|---|
| **Reversible** | No | Yes (with key) | Yes (with private key) |
| **Key count** | None | 1 shared key | 2 (public + private) |
| **Speed** | Fast (SHA) / Slow (Argon2) | Fast | Slow |
| **Use case** | Integrity, passwords | Bulk encryption | Signatures, key exchange |
| **Key distribution** | N/A | Hard (secure channel) | Easy (public key) |
| **Standard** | SHA-256, Argon2id | AES-256-GCM | ECDSA P-256, Ed25519 |

---

### 🏛️ System Design

*(Omit: ★★☆ intermediate. Full cryptography architecture covered in L4/L5 entries.)*

---

### 📊 Diagram

*(Omit: ASCII diagrams in Concept Explanation illustrate the three primitive models.)*

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Primitive types, use cases |
| Mechanism | 3 | GCM, key exchange, hybrid |
| Debugging | 2 | Weak hash, key reuse |
| Trade-off | 2 | Algorithm selection |

---

**[MID] Q1 (Definition): What is the difference between hashing, encryption, and encoding?**

These three are frequently confused and each serves a distinct purpose.

Hashing (one-way): a deterministic function that maps arbitrary input to a fixed-size
output. SHA-256("hello") = `2cf24d...`. Cannot be reversed. Same input always produces
same output. Used for integrity (file checksums), authentication (HMAC), and password
verification (bcrypt compares hashes without storing or recovering the password).

Encryption (two-way, with key): a reversible transformation using a key. AES-256-GCM
encrypts data and can decrypt it with the same key. Protects confidentiality of data
in transit or at rest. Meaningless without the key.

Encoding (format conversion): transforms data representation without security purpose.
Base64 encodes binary data as printable ASCII. URL encoding `%20` represents a space.
No key, no security - completely reversible by anyone. Used for data compatibility, not security.

Common confusion: JWT "looks encrypted" because Base64url encoding produces an
unrecognizable string. But Base64url decoded in 2 seconds reveals the payload in plain text.

*What separates good from great:* Immediately correcting JWT confidentiality misconceptions.
Many developers store sensitive data in JWT claims assuming the encoding protects it.
The payload is fully readable by anyone with the token; use JWE (JSON Web Encryption) for confidential claims.

---

**[MID] Q2 (Definition): Which hash algorithm should you use for passwords vs file integrity?**

These require fundamentally different algorithms because the threat models differ.

File integrity: use SHA-256 (or SHA-3 for modern systems). Speed is desirable; you
are computing checksums over files and comparing deterministically. MD5 and SHA-1 are
cryptographically broken for collision resistance - an attacker can create a different
file with the same hash. SHA-256 remains collision-resistant.

Password storage: NEVER use SHA-256, MD5, or any general-purpose hash. These run
at 10+ billion guesses per second on modern GPUs. Use slow-by-design algorithms:
- Argon2id (current recommendation): memory-hard, configurable time and memory cost
- bcrypt: time-tested, 72-byte truncation limit
- scrypt: memory-hard, precursor to Argon2

OWASP recommendation: Argon2id with memory=19MB, iterations=2, parallelism=1.
This produces ~1ms per hash, making a 10-billion-guess/second attack take 10 million
seconds (115+ days) per password.

*What separates good from great:* Knowing bcrypt's 72-byte truncation. Long passphrases
are increasingly common; bcrypt silently ignores characters beyond 72 bytes. For modern
systems: Argon2id with no truncation limit is the correct choice.

---

**[SENIOR] Q3 (Mechanism): Explain authenticated encryption and why GCM mode matters.**

Authenticated encryption (AE) provides both confidentiality and integrity from a single
operation. AES without authentication (ECB, CBC) provides only confidentiality - an
attacker can flip bits in the ciphertext, which decrypts to corrupted but accepted data.

AES-GCM (Galois/Counter Mode) is an AEAD cipher:
- Counter Mode (CTR): encrypts using a keystream XOR'd with plaintext
- Galois authentication: computes a 128-bit authentication tag over ciphertext
  and optional "associated data" (headers, metadata that must not be tampered)

Decryption verifies the authentication tag FIRST. If any ciphertext byte changed,
the tag verification fails and decryption returns an error - the application never
sees corrupted plaintext.

Historical context: TLS 1.0/1.1 used CBC with a separate HMAC. This led to padding
oracle attacks (POODLE, BEAST) where crafted ciphertext manipulation revealed plaintext.
TLS 1.3 mandates AEAD (AES-GCM or ChaCha20-Poly1305) only.

*What separates good from great:* Understanding the "associated data" (AD) in AEAD.
You can authenticate unencrypted metadata alongside the ciphertext - the AD is not
encrypted but tampering with it fails authentication. Example: encrypt the document
body but put the user ID in AD; the auth tag covers both; swapping a document's owner
ID tampers with the auth tag and decryption fails.

---

**[SENIOR] Q4 (Mechanism): How does Diffie-Hellman key exchange work and why is it used in TLS?**

Diffie-Hellman (DH) allows two parties to establish a shared secret over an untrusted
channel without transmitting the secret. Neither party sends the secret; both derive it
independently.

Simplified: Alice and Bob agree on a public prime `p` and generator `g`. Alice picks
secret `a`, sends `g^a mod p` (public). Bob picks secret `b`, sends `g^b mod p` (public).
Alice computes `(g^b mod p)^a mod p`. Bob computes `(g^a mod p)^b mod p`. Both arrive
at `g^(ab) mod p` - identical shared secret. An eavesdropper sees only `g^a mod p` and
`g^b mod p`; computing `ab` from these is the discrete logarithm problem - computationally infeasible.

ECDH (Elliptic Curve DH): same principle on elliptic curves. Smaller key sizes for
equivalent security. X25519 (Curve25519-based) is the standard in TLS 1.3.

In TLS: DH provides forward secrecy. The session key is derived from an ephemeral DH
exchange. Even if the server's private key is compromised later, past session keys
cannot be derived (they were never stored). This is why "ECDHE" in cipher suites means
ephemeral ECDH.

*What separates good from great:* The forward secrecy point. Static RSA key exchange
(pre-TLS 1.3) allowed a passive adversary to record all encrypted traffic and decrypt
it retroactively if they later obtained the private key. TLS 1.3 mandates ephemeral
key exchange (ECDHE), eliminating retroactive decryption.

---

**[SENIOR] Q5 (Mechanism): Explain the hybrid encryption model used in TLS.**

Asymmetric encryption is slow (RSA-2048 encrypt: ~1ms) and limited to small data (< 245 bytes for RSA-2048). Symmetric encryption is fast (AES: GB/sec on hardware) but requires secure key distribution. TLS combines both in a hybrid scheme.

TLS 1.3 handshake:
1. Client sends supported cipher suites and ECDH public key share.
2. Server sends its certificate (public key), selects cipher suite, and sends ECDH share.
3. Both sides perform ECDH (X25519) to derive the same shared secret.
4. From the shared secret, both derive symmetric keys for the session (AES-256-GCM or ChaCha20-Poly1305).
5. Server proves identity by signing the handshake hash with its certificate private key.
6. Data channel uses symmetric encryption with derived session keys.

The certificate's RSA or ECDSA keypair authenticates the server; it does NOT encrypt
session data. The session key comes from ECDH. This provides forward secrecy: each
connection uses a fresh ECDH exchange; the certificate private key is never involved
in deriving session keys.

*What separates good from great:* The TLS 1.2 vs 1.3 difference. TLS 1.2 allowed
RSA key exchange (encrypt the pre-master secret with the server's public key) - no
forward secrecy, and the full handshake requires 2 round trips. TLS 1.3 removed RSA
key exchange entirely and reduced the handshake to 1 round trip.

---

**[SENIOR] Q6 (Debugging): Your application uses AES encryption but a security audit flags
that ciphertexts look correlated for similar plaintexts. What went wrong?**

ECB mode (Electronic Codebook) encryption. ECB encrypts each block (16 bytes) independently
with the same key. Identical 16-byte plaintext blocks produce identical ciphertext blocks.
This leaks structural patterns: the famous "ECB penguin" - encrypting a bitmap with ECB
reveals the outline of the penguin because large uniform regions produce repeated ciphertext blocks.

Fix:
1. Switch to AES-256-GCM (authenticates too - added bonus).
2. Or AES-256-CBC with a random IV (no auth; add HMAC separately).
3. Never `Cipher.getInstance("AES")` - Java defaults to ECB when no mode is specified.
4. Always: `Cipher.getInstance("AES/GCM/NoPadding")`.

Diagnosis: `Cipher.getInstance("AES")` in source. If ciphertexts for similar data have
matching prefixes, ECB is the cause.

*What separates good from great:* Java's default cipher mode behavior. `Cipher.getInstance("AES")` silently uses ECB in Oracle JDK. This is a well-known Java trap. Always specify the full transformation string: algorithm/mode/padding.

---

**[SENIOR] Q7 (Trade-off): RSA vs ECDSA for digital signatures - when do you choose each?**

RSA signatures: RSA-2048 or RSA-4096. Widely supported; RSA-2048 is approximately
3KB key for similar security to ECDSA-256. Slower signing and verification. Larger
key and signature sizes. Still dominant in many certificate authorities and legacy systems.

ECDSA P-256 (secp256r1): 256-bit key provides security comparable to RSA-3072.
Smaller key size means faster operations and smaller TLS handshakes. Standard in TLS
certificates (Let's Encrypt default). Some concern about NIST curve parameter origin.

Ed25519 (EdDSA on Curve25519): modern Edwards curve. No timing side-channels by
design (unlike ECDSA which leaks the private key if the nonce is predictable). Faster
than ECDSA. Smaller signatures. Not yet universal in PKI but supported in TLS 1.3,
SSH, and modern JWT libraries.

When RSA: legacy system compatibility; CA requirements; RSA-PSS is the modern padding scheme for RSA signatures.
When ECDSA P-256: standard TLS certificates; JWT (ES256); general asymmetric signatures.
When Ed25519: SSH keys; modern protocols; highest security requirement with maximum performance.

*What separates good from great:* The ECDSA nonce reuse catastrophe. ECDSA requires
a unique random nonce per signature. If the nonce is ever reused, the private key is
recoverable from two signatures. This is how the Sony PlayStation 3 private key was
extracted. Ed25519's deterministic nonce eliminates this vulnerability class entirely.

---

**[SENIOR] Q8 (Trade-off): When is it appropriate to use asymmetric vs symmetric encryption for data at rest?**

Symmetric (AES-256-GCM) is the standard for data at rest: fast, auditable, no size
constraint. The only challenge is key management. Use in: database field encryption,
S3 object encryption, disk encryption.

Asymmetric encryption for data at rest is appropriate only for one specific scenario:
multiple independent parties need to encrypt data that only the recipient can decrypt,
without sharing a symmetric key out-of-band.

Example: secure mailbox or file store where senders encrypt data with the recipient's
public key and only the recipient (private key holder) decrypts. PGP file encryption.

In practice: asymmetric crypto wraps a symmetric key (envelope encryption):
1. Generate random AES-256 key.
2. Encrypt data with AES-256 key.
3. Encrypt AES-256 key with recipient's public key.
4. Store: encrypted key + encrypted data.

This is the envelope encryption model used by AWS KMS: data key generated locally,
used for bulk encryption, then wrapped by the CMK.

*What separates good from great:* Envelope encryption is the production pattern for
any system where data is accessed by multiple parties or where key rotation is needed.
Rotate the master key by re-wrapping the data key; no need to re-encrypt the data.

---

**[STAFF] Q9 (Deep Dive): A developer commits an AES-256 key to git. What is your incident response?**

Immediate containment (minutes): rotate the key. Generate a new key and deploy it.
Deactivate the compromised key in the key management system. This stops ongoing
exposure.

Scope assessment: what data was encrypted with the compromised key? Check key usage
logs in KMS or application logs. When was the key first committed? Use `git log --all`
to find first introduction. Who had access to the repository? This determines who
may have seen the key.

Data impact: for each record encrypted with the compromised key, the attacker with
the key could decrypt retroactively if they captured the ciphertext. Assessment: was
the data in a database accessible from networks the attacker could reach? Was it
exported or logged?

Remediation: re-encrypt all affected data with the new key. For large datasets,
this may require a migration script. Log every re-encrypted record for audit trail.

Prevention: secrets scanning in CI (GitGuardian, GitHub secret scanning, gitleaks).
Pre-commit hooks that reject commits containing entropy patterns. Store keys in Vault
or AWS Secrets Manager; load via environment variables at runtime; never commit to source.

*What separates good from great:* Distinguishing between potential exposure (key
committed but no evidence of access) and confirmed breach (evidence of unauthorized
decryption). The incident response differs; potential exposure may be reportable if
regulated data is involved; confirmed breach typically triggers notification requirements.

---

---

# Secrets Management: Vault, KMS, and Rotation

---
id: SEC-015
title: "Secrets Management: Vault, KMS, and Rotation"
category: Security
difficulty: ★★☆
interview_weight: high
asked_at: Senior+
seniority: senior
tags: #security, #vault, #kms, #secrets, #rotation
status: draft
sd: false
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Secrets management means storing, accessing, and rotating sensitive credentials
> (API keys, database passwords, encryption keys) without them appearing in source
> code or configuration files. Tools: HashiCorp Vault (self-hosted, full-featured),
> AWS KMS (managed key management), cloud secret managers (AWS Secrets Manager,
> GCP Secret Manager). The key practices: inject secrets at runtime (not at build
> time), rotate frequently, audit all access.

**3 minutes (Senior):**
> Secrets in source code, CI logs, or environment variables in Dockerfiles cause
> breaches. The correct model: secrets live in Vault or a cloud secret manager;
> applications authenticate to Vault using short-lived tokens or IAM roles; secrets
> are fetched at startup (or via sidecar); a lease means the secret expires and forces
> renewal. KMS is a different layer: you never see the raw key. KMS encrypts/decrypts
> using a CMK that never leaves the HSM; the service calls KMS with data and gets
> back ciphertext (encrypt) or plaintext (decrypt). Rotation: a secret expires,
> a new one is generated and registered with the dependent service before the old
> one is revoked. Dynamic secrets are the gold standard: Vault generates a unique
> database credential per application instance, revokes it when the lease expires.

**Framework:** DISCOVERY (find secrets in code) → EXTRACTION (move to Vault/KMS) → INJECTION (runtime access) → ROTATION (automated) → AUDIT (who accessed what)

**Blank Mind Recovery:**

**(1) Restate:** "Secrets must be managed externally from application code and
configuration files, with access controlled, audited, and time-limited."

**(2) First principles:** "A secret hard-coded in source is visible to anyone with
repository access. The question is: how do you give the application a secret
without embedding it anywhere that is not secured?"

**(3) Bridge:** "Vault is like a bank vault for secrets: the application authenticates
(like showing ID), gets access to its safety deposit box (its secrets), and the bank
logs every access. KMS is like a notary that performs cryptographic operations
without showing you the key."

---

### 📘 Concept Explanation

**What it is:**
Secrets management is the practice of securely storing, distributing, rotating, and
auditing credentials and sensitive configuration. A secret is any value that grants
access or proves identity: passwords, API keys, certificates, encryption keys.

**The problem it solves:**
Without secrets management, credentials end up in source code, CI/CD configs,
Kubernetes manifests, application logs, and Docker images - all high-risk exposure
surfaces. Once committed, a secret propagates to every developer's clone, every CI
environment, and every container layer.

**How it works:**

```
VAULT WORKFLOW:
  1. App authenticates to Vault:
     - Kubernetes: pod SA token -> Vault Kubernetes auth
     - AWS: IAM role -> Vault AWS auth
     - Short-lived Vault token (TTL: 1 hour) returned
  
  2. App reads secrets:
     vault read secret/myapp/db-password
     -> creds valid for lease_duration (24 hours)
  
  3. Dynamic secrets (gold standard):
     vault read database/creds/myapp-role
     -> generates unique DB user/password for THIS instance
     -> lease: 1 hour, renewed by running app
     -> on shutdown/expiry: Vault revokes the DB user
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Vault workflow from authentication to secret retrieval, using short-lived tokens and optional dynamic secret generation. (2) KEY MECHANISM: dynamic secrets are single-use per application instance; Vault calls the database to create a temporary user; when the lease expires or the app is shut down, Vault calls the database to revoke that user; no shared password exists. (3) WHY IT MATTERS: dynamic secrets eliminate shared credentials entirely; a breach of one application instance's credentials affects only that instance and expires automatically. (4) WHAT BREAKS: applications that cannot handle credential refresh mid-runtime; connection pooling with baked-in credentials does not react to rotation; use Vault Agent sidecar for transparent renewal. (5) TAKEAWAY: dynamic secrets are the highest security posture; static secrets in Vault are still vastly better than hard-coded credentials.

```
KMS ENVELOPE ENCRYPTION:
  ENCRYPT flow:
    1. App generates data key (AES-256, in memory)
    2. App encrypts data with data key
    3. App calls KMS.Encrypt(CMK_ID, data_key)
       -> KMS returns encrypted_data_key (blob)
    4. Store: { encrypted_data_key, encrypted_data }
    5. Discard plaintext data_key from memory

  DECRYPT flow:
    1. Load { encrypted_data_key, encrypted_data }
    2. Call KMS.Decrypt(encrypted_data_key)
       -> KMS returns plaintext data_key (IAM auth)
    3. Decrypt data with plaintext data_key
    4. Discard plaintext data_key from memory

  CMK never leaves KMS hardware security module (HSM)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: envelope encryption separating the data encryption key (DEK) from the master key (CMK), where the CMK never leaves the KMS hardware. (2) KEY MECHANISM: the app encrypts data locally with the DEK for performance; the CMK in KMS wraps (encrypts) the DEK; to decrypt data you must call KMS to unwrap the DEK; IAM policies control who can call KMS.Decrypt. (3) WHY IT MATTERS: key rotation is decoupled from data re-encryption; to rotate the CMK, re-wrap the DEK with the new CMK; the encrypted data does not change. (4) WHAT BREAKS: calling KMS to encrypt every data item individually at high throughput creates latency and cost; the DEK should be reused for a batch, cached in memory (never on disk). (5) TAKEAWAY: generate one DEK per batch/session; wrap it with KMS once; store the wrapped DEK alongside the data; rotate the CMK by re-wrapping DEKs on a schedule.

**The key insight:**
Vault manages secret access control and rotation. KMS manages cryptographic key
operations without key exposure. They solve different problems and are commonly used
together: Vault stores database credentials; KMS wraps the encryption keys for data stored in those databases.

**When to use it:**
Every production application with credentials. Vault for multi-cloud or on-premise.
AWS Secrets Manager for pure AWS workloads. KMS when data-at-rest encryption is needed.

**When NOT to use it:**
Secrets in `.env` files committed to Git (even with gitignore). Secrets in Kubernetes
ConfigMaps (not encrypted). Secrets in environment variables in Docker image layers.

**Alternatives:**
- AWS Secrets Manager: managed Vault alternative for AWS
- GCP Secret Manager: Google equivalent
- Azure Key Vault: Microsoft equivalent
- Kubernetes Secrets (with RBAC + etcd encryption at rest): basic, sufficient for simple cases

---

### 💻 Code Example

```java
// BAD: Hard-coded credentials - immediate security failure
@Configuration
public class BadDataSourceConfig {
    @Bean
    public DataSource dataSource() {
        HikariConfig cfg = new HikariConfig();
        cfg.setJdbcUrl("jdbc:postgresql://db:5432/app");
        cfg.setUsername("app_user");
        // BAD: hard-coded; visible in logs, code reviews, git
        cfg.setPassword("P@ssw0rd123!");
        return new HikariDataSource(cfg);
    }
}

// GOOD: Credentials from Vault via Spring Vault
@Configuration
public class GoodDataSourceConfig {
    // Spring Vault injects secret at startup via bootstrap.yml:
    // spring.cloud.vault.uri=https://vault:8200
    // spring.cloud.vault.authentication=kubernetes
    @Value("${db.password}")  // resolved from Vault
    private String dbPassword;

    @Bean
    public DataSource dataSource() {
        HikariConfig cfg = new HikariConfig();
        cfg.setJdbcUrl("jdbc:postgresql://db:5432/app");
        cfg.setUsername("app_user");
        cfg.setPassword(dbPassword);  // from Vault at startup
        return new HikariDataSource(cfg);
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the contrast between hard-coded credentials and Vault-injected credentials via Spring Vault's property source integration. (2) KEY MECHANISM: Spring Vault's `BootstrapPropertySource` authenticates to Vault at application startup using Kubernetes service account tokens, fetches secrets from the configured path, and makes them available as standard Spring properties - the application code does not change. (3) WHY IT MATTERS: the hard-coded password appears in every git clone, every log that dumps configuration, every container image; the Vault approach means the password never appears in source control or container layers. (4) WHAT BREAKS: Vault is unavailable at startup - the application fails to start (fail closed); add a Vault health check to the readiness probe. (5) TAKEAWAY: Spring Vault integrates with the Spring property system transparently; use `spring.cloud.vault` for startup injection; use VaultTemplate for runtime secret access.

```java
// AWS KMS: Envelope encryption for sensitive data
@Service
public class EncryptedStorage {
    private final KmsClient kms;
    private final String cmkArn; // from environment variable
    // In-memory DEK cache (encrypt/decrypt without KMS per call)
    private final LoadingCache<String, byte[]> dekCache;

    public EncryptedRecord encrypt(
            String tenantId, byte[] plaintext)
            throws Exception {
        // 1. Get or generate DEK for this tenant
        byte[] dek = dekCache.get(tenantId);
        byte[] wrappedDek = wrapDek(tenantId, dek);

        // 2. Encrypt data locally with DEK
        byte[] ciphertext = AesGcm.encrypt(dek, plaintext);

        return new EncryptedRecord(wrappedDek, ciphertext);
    }

    public byte[] decrypt(
            String tenantId, EncryptedRecord record)
            throws Exception {
        // 1. Unwrap DEK via KMS (IAM-authenticated)
        byte[] dek = unwrapDek(tenantId, record.wrappedDek());

        // 2. Decrypt data locally
        return AesGcm.decrypt(dek, record.ciphertext());
    }

    private byte[] wrapDek(String tenantId, byte[] dek) {
        EncryptRequest req = EncryptRequest.builder()
            .keyId(cmkArn)
            .plaintext(SdkBytes.fromByteArray(dek))
            // Encryption context: tenant ID is in auth tag
            .encryptionContext(Map.of("tenantId", tenantId))
            .build();
        return kms.encrypt(req).ciphertextBlob().asByteArray();
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: tenant-scoped envelope encryption using KMS for key wrapping and AES-GCM for data encryption, with a DEK cache to avoid per-record KMS calls. (2) KEY MECHANISM: the encryption context (`tenantId`) is passed to KMS and is included in the auth tag of the wrapped DEK; a call to KMS.Decrypt with the wrong tenant ID fails because the encryption context is mismatched. (3) WHY IT MATTERS: the encryption context creates tenant isolation at the KMS level; even if the wrong wrapped DEK is loaded for a tenant, decryption fails. (4) WHAT BREAKS: caching the DEK in memory without TTL means key rotation does not take effect until restart; use Caffeine cache with a TTL (e.g., 1 hour) to pick up rotated keys. (5) TAKEAWAY: encryption context in KMS is a powerful authorization mechanism - bind the decryption permission to the operation's context so cross-tenant key usage fails at the KMS layer.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Secrets should never be in source code. Use environment variables loaded from a
> secret manager (AWS Secrets Manager, Vault). Secrets are injected at runtime, not
> baked into the container image. Rotate credentials regularly; log all secret access
> for audit.

---

**Senior / Staff (5+ years):**
> The architecture question is whether to use static secrets (credential stored in
> Vault, rotated periodically) or dynamic secrets (Vault generates a unique credential
> per instance, revokes on expiry). Dynamic secrets are the gold standard but require
> applications that can handle credential expiry without restart. KMS is orthogonal:
> Vault manages access to secrets; KMS performs cryptographic operations without
> exposing keys. At the staff level: secret sprawl is the production problem - hundreds
> of services, each with dozens of secrets, many with unknown ownership and last-rotation
> date. The solution is a secrets inventory with ownership, TTL, and rotation schedule
> tracked as code in a registry.

---

### ⚠️ Common Misconceptions

**Misconception 1: Environment variables are safe for secrets.**

Environment variables are not secure: they appear in `/proc/{pid}/environ`, are visible
to all processes run by the same user, appear in crash dumps, and are exposed in
`docker inspect`, `kubectl describe pod`. They are better than hard-coded values but
not a secrets management solution. Use Vault or a cloud secret manager; inject via
file system mounts or the Vault Agent sidecar.

**Misconception 2: gitignore prevents secrets from leaking.**

Once a secret is committed (even briefly), it is in the git object store and visible
via `git log -p --all`. An `rm` followed by a commit does not remove it from history.
Full remediation: `git filter-repo` to rewrite history, then consider the secret
compromised for any collaborators who already cloned. Prevention: pre-commit hooks
with secrets scanning.

**Misconception 3: Vault's AppRole authentication is just basic auth.**

AppRole is a two-factor authentication mechanism: a role-ID (not secret, like a username)
and a secret-ID (one-time-use, short-lived). The secret-ID is injected by a CI system
or orchestrator at deployment time. This is fundamentally different from static
passwords: secret-IDs are single-use, expire, and are never stored in application config.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Secret committed to git.**

Symptom: code review finds hard-coded password; security scanner alerts.
Diagnosis: `git log -p --all -- file.txt | grep -i password`.
Fix: rotate the secret immediately (compromised); remove from history with
`git filter-repo --path file.txt --invert-paths`; add pre-commit hook.

**Failure Mode 2: Secret rotation breaks production.**

Symptom: after rotation, applications get authentication failures; 503s spike.
Diagnosis: applications cached the old credential and have not fetched the new one.
Fix: gradual rotation - deploy new secret to Vault; applications should refetch on
auth failure (retry once with fresh credential); add a grace period where both old
and new credentials are valid simultaneously.

**Failure Mode 3: Vault token expires during application runtime.**

Symptom: application starts correctly but fails 24 hours later with 403 from Vault.
Diagnosis: check Vault token TTL; check if application renews the token.
Fix: use Vault Agent sidecar which handles token renewal transparently; or implement
token renewal in the application before TTL expiry.

---

### ⚖️ Comparison Table

| Aspect | HashiCorp Vault | AWS Secrets Manager | Kubernetes Secrets |
|---|---|---|---|
| **Dynamic secrets** | Yes (full support) | No | No |
| **Key operations** | Via Transit engine | Via KMS (separate) | No |
| **Managed** | Self-hosted (or HCP) | Fully managed | Cluster-local |
| **Cost** | Open source (fees for ent) | $0.40/secret/month | Free |
| **Rotation** | Full automation | Native rotation | Manual |
| **Audit log** | Built-in | CloudTrail | Manual |
| **Best for** | Multi-cloud, on-prem | Pure AWS workloads | Simple k8s use cases |

---

### 🏛️ System Design

*(Omit: ★★☆ intermediate. Full secrets architecture at scale covered in L4/L5 entries.)*

---

### 📊 Diagram

*(Omit: ASCII diagrams in Concept Explanation illustrate Vault and KMS workflows.)*

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Secret types, storage options |
| Mechanism | 2 | Vault dynamic secrets, KMS envelope |
| Debugging | 2 | Leaked secret, rotation failure |
| Trade-off | 2 | Platform choice, static vs dynamic |
| Scenario | 1 | Breach response |

---

**[MID] Q1 (Definition): What is a secret and where should secrets NOT live?**

A secret is any value that grants access or proves identity and must be protected from
unauthorized disclosure. Categories: database passwords, API keys (Stripe, Twilio),
encryption/signing keys, OAuth client secrets, certificates and private keys, service
account credentials.

Where secrets must NOT be:
- Source code (any file, any language, any branch)
- CI/CD pipeline configuration (env vars in GitHub Actions, GitLab CI, Jenkins)
- Container images (Dockerfile ENV, docker build args visible in layer history)
- Application logs (common failure: logging configuration files with passwords)
- Kubernetes ConfigMaps (stored unencrypted in etcd)
- Cloud metadata endpoints (EC2 user data in plaintext)
- Browser console, client-side JavaScript

Where secrets should be: a dedicated secret management system (Vault, AWS Secrets
Manager, GCP Secret Manager, Azure Key Vault). Accessed at runtime via authenticated
API calls; never stored in the application's file system.

*What separates good from great:* The "committed temporarily" trap. A developer adds a password for a quick test, then removes it in the next commit. The password is now permanently in git history, visible to anyone with repo access. The incident response is the same as a live secret: rotate, investigate.

---

**[SENIOR] Q2 (Mechanism): Explain Vault's dynamic database secrets engine.**

Vault's database secrets engine creates unique, time-limited credentials per request,
rather than distributing a shared password.

Configuration: Vault connects to the database with a privileged account (the "root
credential"). An administrator defines a "role" specifying the SQL to run when
generating credentials:
{% raw %}
```sql
CREATE USER "{{name}}" WITH ENCRYPTED PASSWORD '{{password}}'
VALID UNTIL '{{expiration}}';
GRANT SELECT, INSERT ON users TO "{{name}}";
```
{% endraw %}

> **Code walkthrough:** (1) WHAT IT SHOWS: Vault's database secrets engine SQL template using `{{name}}`, `{{password}}`, and `{{expiration}}` placeholders that Vault substitutes when generating a credential. (2) KEY MECHANISM: Vault executes this SQL against the database for each credential request, creating a real database user with a unique name and time-bound validity; the `VALID UNTIL` clause enforces expiry at the database layer independent of Vault. (3) WHY IT MATTERS: even if Vault's revocation fails (network partition, bug), the database enforces credential expiry via `VALID UNTIL`; defense in depth at the database layer. (4) WHAT BREAKS: not granting minimal privileges - the GRANT should be scoped to exactly what the service needs; a compromised instance's credential should not allow it to access other services' data. (5) TAKEAWAY: dynamic SQL template + VALID UNTIL + minimal GRANT = the three elements of a secure Vault database role.

When an application reads `vault read database/creds/myapp-role`:
1. Vault calls the database to CREATE a new user with a random name and password.
2. Returns the credentials with a lease (e.g., 1 hour).
3. The application connects to the database with these credentials.
4. When the lease expires (or Vault is told the app shut down), Vault calls the database to DROP the user.

Result: no shared credentials; each application instance has unique credentials;
credentials expire automatically; a compromised credential affects only one instance
and expires on schedule.

*What separates good from great:* Application-side credential rotation handling.
When the lease expires, the application must obtain new credentials and reconnect
the pool. HikariCP does not do this automatically. Options: Vault Agent Sidecar (renews and writes to file, triggers app reload), Spring Vault (can refresh on expiry), or a wrapper that catches authentication errors and refetches.

---

**[SENIOR] Q3 (Trade-off): When do you choose Vault vs AWS Secrets Manager?**

Choose AWS Secrets Manager when:
- Pure AWS workload; no on-premise or multi-cloud
- Managed service (no Vault cluster to operate)
- AWS native rotation (Secrets Manager has built-in Lambda rotation for RDS, ElastiCache)
- Cost is acceptable ($0.40/secret/month + API cost)

Choose HashiCorp Vault when:
- Multi-cloud or hybrid: single secrets platform across AWS, GCP, Azure, on-premise
- Dynamic secrets: Vault has mature database, cloud, PKI, and SSH secrets engines
- Transit (encryption-as-a-service): Vault's Transit engine provides KMS-like operations
  for applications without needing raw key access
- On-premise HSM integration
- Custom auth backends (LDAP, GitHub, custom plugins)

In practice: large enterprises often use both. AWS workloads use Secrets Manager
for operational simplicity; Vault for the central PKI and multi-cloud secrets.

*What separates good from great:* The Transit secrets engine. Vault Transit lets
applications encrypt/decrypt data without ever seeing the encryption key - the application
sends data to Vault and gets back ciphertext. This is equivalent to KMS but works
across cloud providers and on-premise, and the encryption policy lives in Vault's ACL.

---

**[SENIOR] Q4 (Debugging): You find a database password in a 6-month-old git commit. Walk through the response.**

Phase 1 - Immediate containment (within the hour):
Rotate the database password NOW. Generate a new password, update the database, deploy
new secret to Vault/Secrets Manager, roll out the application to pick up the new credential.
Do not wait for the investigation to complete; contain the exposure first.

Phase 2 - Scope assessment:
Who had repository access? All contributors, all CI systems, all forks. When was
it committed? Check git log with dates. Was the database externally reachable?
Check security groups/firewall rules. What permissions did the credential have?
Check database role.

Phase 3 - Evidence of access:
Review database audit logs for the period from the commit date to rotation.
Look for: unusual source IPs, bulk SELECT queries, access outside business hours,
queries against unusual tables. If the database does not have audit logging: this is
a gap - you cannot rule out access.

Phase 4 - Remediation and reporting:
Remove from git history: `git filter-repo --path file.py --invert-paths`.
Require all collaborators to reclone (filtered history is not fully compatible
with existing clones).
If regulated data (PCI, GDPR, HIPAA) was in the database: likely notification
requirement regardless of evidence; consult legal.

Phase 5 - Prevention:
Pre-commit hook with gitleaks. CI secret scanning (GitHub Advanced Security, GitGuardian).
Quarterly secrets audit (no credentials should appear in any source, config, or CI env).

*What separates good from great:* The distinction between "no evidence of unauthorized
access" and "confirmed no breach." Without comprehensive database audit logs from day
of commit, you cannot confirm the latter. The absence of evidence is not evidence of
absence. This affects the incident classification and notification decision.

---

**[SENIOR] Q5 (Mechanism): How do you implement zero-downtime secret rotation?**

The challenge: the application must transition from the old secret to the new one
without any authentication failure during the changeover.

Two-phase rotation pattern:

Phase 1 - Deploy new secret alongside old:
Generate new secret. Register both old AND new in the system (e.g., both database
passwords are valid for the service account). Update Vault to store the new secret.
Applications still use the old credential; the new one is ready.

Phase 2 - Application picks up new secret:
Rolling restart of application instances. Each instance fetches the new credential
from Vault on startup. Old instances use old credential; new instances use new.
Both work during the rollout. After all instances are on the new version:
revoke the old credential from the database.

For credential-based systems (database passwords): `ALTER USER SET PASSWORD` in
postgres/mysql supports transitional period with both passwords.

Vault's credential rotation: the `vault write database/config/rotate-root` command
rotates the root credential without manual password generation.

*What separates good from great:* Connection pool behavior. HikariCP will attempt to
reconnect using cached credentials. After rotation, pools eventually exhaust their
connections and recreate them with fresh credentials. During this window, some requests
fail. To avoid: application must detect auth failure and explicitly close/reopen the
pool with fresh credentials (Vault Agent can help by writing new credentials and
signaling the application).

---

**[MID] Q6 (Definition): What is the difference between a secret lease and secret rotation?**

A lease (Vault concept): a time-limited grant of access to a secret. When a dynamic
secret is issued, the lease defines how long the credential is valid. The application
must renew the lease before expiry or obtain a new credential. Leases are Vault-specific.

Secret rotation: the act of replacing an existing secret with a new one. The old
secret is deactivated; the new one is registered with the target system. Rotation can
be scheduled (every 90 days), triggered (on suspicion of compromise), or continuous
(dynamic secrets rotate on every request).

Key difference: leases are about time-limiting access to a credential. Rotation is
about replacing the credential itself. Dynamic secrets combine both: each credential
has a short lease, so rotation is implicit on every lease expiry.

Real-world interaction: a static database password in Vault may have a lease of 24
hours (the application fetches it at startup and holds it). The rotation schedule
is 90 days. Both the lease and the rotation schedule must be managed; the app must
be able to pick up a rotated password without manual restart.

*What separates good from great:* The rotation notification problem. When a static
secret in Vault is rotated, how does the running application know? Options: (1) short
lease forces re-fetch on each startup; (2) Vault Agent watches for changes and
writes new value to a file; (3) application polls Vault periodically; (4) a rotation
event triggers a rolling restart. Each has operational trade-offs.

---

**[STAFF] Q7 (Deep Dive): Design a secrets management system for 200 microservices.**

Scale problem: 200 services, each with ~10 secrets = 2,000 secrets. Challenges:
secret sprawl, unknown ownership, stale rotation, audit gaps.

Architecture:

Centralized platform: HashiCorp Vault Enterprise or AWS Secrets Manager. Decision
based on cloud strategy.

Service identity: each service authenticates to Vault via its Kubernetes service
account token (Vault Kubernetes auth). Each SA token is scoped to the specific
secrets the service needs (least privilege).

Secrets registry (code): secrets.yaml in each service's repo:
```yaml
service: payment-api
secrets:
  - path: secret/payment/db-password
    lease: 24h
    rotation: 90d
    owner: platform-team
  - path: secret/payment/stripe-key
    lease: 1h
    rotation: 30d
    owner: payments-team
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a secrets registry YAML schema that declares each secret's Vault path, lease, rotation schedule, and owner as code in the service repository. (2) KEY MECHANISM: this registry is the single source of truth for secret ownership; automation reads it to schedule rotations and page the correct owner on failures; a secrets audit scans Vault against all registered secrets to find unregistered (orphan) secrets. (3) WHY IT MATTERS: without a registry, secrets accumulate in Vault with no owner, no rotation schedule, and no decommissioning process; the registry enforces policy as code. (4) WHAT BREAKS: the registry being optional - teams skip it for "quick" secrets; enforce via CI: PR without updated secrets.yaml for a new secret fails the pipeline check. (5) TAKEAWAY: manage secrets as code alongside the service; the secrets registry is the contract between the service and the platform team.

Rotation automation: each secret has a rotation schedule and an owner. An automation
system generates new credentials, updates the target system (database, Stripe), and
updates Vault. Owner is paged if rotation fails.

Audit and compliance: Vault audit log -> centralized log store (Splunk, OpenSearch).
Dashboards: "last rotation date" per secret, "services accessing a secret", "token
renewal failures". Secrets without a recent rotation are flagged.

*What separates good from great:* The "secret orphan" problem. Services are deprecated
but their secrets are not rotated or decommissioned. Six months later, the secret for a
decommissioned service is found in Vault with no owner and no last-rotation date. The
secrets registry enforced as code (PR required to add, active owner verification quarterly)
prevents secret orphans from accumulating.

---

**[SENIOR] Q8 (Debugging): An application is failing with 403 errors from Vault. How do you diagnose?**

A 403 from Vault means authentication succeeded but authorization failed - the token
does not have permission to read the requested path. This is distinct from a 401
(authentication failure) or a 503 (Vault unavailable).

Diagnosis steps:

Step 1 - Identify the token: what Vault token is the application using? Kubernetes
auth tokens are named after the service account. Check `vault token lookup <token>`
to see its policies.

Step 2 - Check policies: `vault policy read <policy-name>`. Does the policy include
a `path "secret/myapp/*" { capabilities = ["read"] }` entry for the exact path
being requested? Vault path ACLs are prefix-matched; a policy for
`secret/myapp/*` does not grant access to `secret/myapp` (no trailing slash).

Step 3 - Check the path: is the secret at the exact path the application is
requesting? Vault paths are case-sensitive. `secret/MyApp` != `secret/myapp`.

Step 4 - Check token renewal: has the token expired? Kubernetes tokens are renewed
automatically by Vault Agent; standalone tokens may have expired.

Fix: update the Vault policy to include the required path with `read` capability;
redeploy the Vault Agent configuration if the policy was correct but the token had wrong policies.

*What separates good from great:* Using `vault audit list` to enable/check the audit
device. The Vault audit log shows every request with the full path and the result.
A 403 in the audit log confirms the denial with the exact path, making diagnosis immediate.

---

**[SENIOR] Q9 (Scenario): How do you handle the Vault bootstrap problem - the first secret needed to access Vault?**

The bootstrap problem: to access Vault, the application needs credentials. But those
credentials must be stored somewhere. If they are stored in Vault, you have a circular dependency.

The solution is Vault's auth methods that use external trust authorities:

Kubernetes auth: the Kubernetes API server signs service account tokens. Vault
trusts the Kubernetes API as an authority. The pod presents its mounted service
account token; Vault calls the Kubernetes API to verify the pod's identity; no secret
bootstrap required. The service account token is automatically mounted by Kubernetes.

AWS auth: the EC2 instance or Lambda function has an IAM role attached at the
infrastructure level (not a secret). Vault trusts AWS IAM as an authority.
The application calls the AWS metadata service to get a signed identity document;
Vault verifies with AWS; no secret bootstrap required.

AppRole (reduced bootstrap): a role-ID (non-secret, like a username) is baked into
the image. A secret-ID (one-time-use, short-lived) is injected by the CI/CD system
at deployment time. The secret-ID never lives in a config file - the CI system
generates it and passes it to the pod as a secret; it is consumed once and discarded.

The pattern: use platform-provided identity (Kubernetes SA, IAM role, cloud metadata)
as the root of trust for Vault authentication. No secret needs to be bootstrapped
because the platform's identity system is the bootstrap.

*What separates good from great:* The wrapped secret-ID pattern in AppRole. Vault
can issue a "response-wrapped" secret-ID: the CI system gets a one-time token
that contains the secret-ID, can only be unwrapped once, expires in seconds,
and the unwrap is audited. This eliminates CI secret-ID exposure windows entirely.
