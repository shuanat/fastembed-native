# Security Policy

## Supported Versions

We actively support the following versions of FastEmbed with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

---

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in FastEmbed, please report it responsibly.

### How to Report

**DO NOT** create a public GitHub issue for security vulnerabilities.

Instead, please report security issues privately:

1. **GitHub Security Advisory (Private):**
   - Open the repository on GitHub
   - Go to the "Security" tab → "Report a vulnerability"
   - Fill out the private report form with full technical details and reproduction steps

If the "Report a vulnerability" option is unavailable in your view, create a new Issue titled "[SECURITY] Private report request" without sensitive details — we will follow up privately and convert it to a confidential workflow.

### What to Include

Please provide as much information as possible:

- **Type of vulnerability** (e.g., buffer overflow, injection, memory corruption)
- **Affected component** (e.g., Assembly code, C wrapper, specific binding)
- **Affected version(s)**
- **Steps to reproduce** the vulnerability
- **Proof of concept** or exploit code (if available)
- **Impact assessment** (what can an attacker do?)
- **Suggested fix** (if you have one)

### What to Expect

- **Acknowledgment:** Within 48 hours
- **Initial assessment:** Within 1 week
- **Status updates:** Every 2 weeks until resolved
- **Fix timeline:** Depends on severity:
  - **Critical:** 1-7 days
  - **High:** 1-2 weeks
  - **Medium:** 2-4 weeks
  - **Low:** Next regular release

### Disclosure Policy

- We follow **coordinated disclosure**
- We will work with you to understand and fix the issue
- We will credit you in the security advisory (unless you prefer to remain anonymous)
- We will publicly disclose the vulnerability only after a fix is released

---

## Security Best Practices

### For Users

1. **Use latest version:** Always use the latest stable release
2. **Validate inputs:** Sanitize user-provided text before generating embeddings
3. **Limit dimensions:** Use reasonable embedding dimensions (e.g., 256-2048)
4. **Memory limits:** Monitor memory usage in production
5. **Dependency updates:** Keep language binding dependencies up-to-date

### For Developers

1. **Memory safety:** Check all array bounds and pointer arithmetic
2. **ABI compliance:** Follow System V ABI strictly (callee-saved registers, stack alignment)
3. **Input validation:** Validate all C API inputs (null checks, dimension checks)
4. **Error handling:** Never ignore return values or error codes
5. **Fuzzing:** Run fuzz tests on new code (see `tests/fuzz/`)
6. **Code review:** All assembly changes require thorough review

---

## Known Security Considerations

### Assembly Code (bindings/shared/src/embedding_lib.asm)

- **Buffer overflows:** All vector operations assume correct dimension parameters
- **Stack alignment:** Misaligned stack can cause crashes or exploitable conditions
- **Register preservation:** Incorrect ABI compliance can corrupt caller state

**Mitigation:**

- Always call via C wrappers (which validate inputs)
- Use language binding safety features (type checks, bounds checks)
- Run tests on multiple platforms

### Hash-Based Embeddings

- **Not cryptographically secure:** Hash function is fast but not designed for security
- **Collision resistance:** Possible for adversarial inputs to generate similar embeddings

**Mitigation:**

- Do not use for security-sensitive applications (use ONNX models instead)
- Treat embeddings as public information (do not rely on secrecy)

### FFI/JNI/P/Invoke Boundaries

- **Type mismatches:** Incorrect type conversions can cause memory corruption
- **Memory leaks:** Unreleased memory across language boundaries

**Mitigation:**

- Use language binding wrappers (FastEmbedNativeClient, FastEmbedNative, etc.)
- Run memory leak detectors (Valgrind, AddressSanitizer)

---

## Security Updates

Security updates will be released as:

1. **Patch releases** (e.g., 1.0.1) for minor fixes
2. **GitHub Security Advisories** for public disclosure
3. **CHANGELOG.md** entries with CVE references (if assigned)

Subscribe to:

- **GitHub Releases:** <https://github.com/yourusername/fastembed/releases>
- **Security Advisories:** <https://github.com/yourusername/fastembed/security/advisories>

---

## Security Testing

We encourage security research! If you want to test FastEmbed for vulnerabilities:

1. **Fuzzing:** Use AFL, LibFuzzer, or Honggfuzz on C API
2. **Static analysis:** Run Clang Static Analyzer, Coverity, or SonarQube
3. **Memory safety:** Use AddressSanitizer (ASan), MemorySanitizer (MSan)
4. **Dynamic analysis:** Use Valgrind for memory leak detection

Please report any findings responsibly (see "Reporting a Vulnerability" above).

---

## Hall of Fame

We thank the following security researchers for responsibly disclosing vulnerabilities:

<!-- List will be updated as vulnerabilities are reported and fixed -->
- (None yet - be the first!)

---

## Contact

For non-security issues, use [GitHub Issues](https://github.com/yourusername/fastembed/issues).

For security issues, please use GitHub Security Advisories (see "Reporting a Vulnerability" above).

---

**Last updated:** November 1, 2024
