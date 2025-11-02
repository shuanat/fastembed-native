---
name: Bug Report
about: Report a bug or unexpected behavior
title: "[BUG] "
labels: bug
assignees: ''

---

## Bug Description

**Brief description:**
A clear and concise description of what the bug is.

**Expected behavior:**
What you expected to happen.

**Actual behavior:**
What actually happened.

---

## Steps to Reproduce

1. Go to '...'
2. Run '....'
3. Call function '....'
4. See error

---

## Environment

**Platform:**

- OS: [e.g., Ubuntu 22.04, Windows 11, macOS 14]
- Architecture: [e.g., x86-64, ARM64]

**Language Binding:**

- Binding: [e.g., Node.js, Python, C#, Java]
- Version: [e.g., Node.js 18.17, Python 3.10]

**FastEmbed Version:**

- Version: [e.g., 1.0.0]
- Commit: [if building from source]

**Compiler/Tools:**

- Compiler: [e.g., GCC 11.4, MSVC 2022]
- NASM: [e.g., 2.15.05]

---

## Code Sample

```language
// Minimal reproducible code example
const client = new FastEmbedNativeClient(768);
const embedding = client.generateEmbedding("test");
// ... error occurs here
```

---

## Error Messages

```
Paste full error message, stack trace, or logs here
```

---

## Additional Context

Add any other context, screenshots, or relevant information.

---

## Workarounds

If you found a temporary workaround, please describe it here.
