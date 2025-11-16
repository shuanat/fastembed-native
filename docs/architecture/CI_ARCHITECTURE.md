# CI/CD Architecture - Variant 4 (Parallel Architecture)

## Overview

This document describes the implementation of Variant 4 (Parallel Architecture) for FastEmbed CI/CD workflow.

## Architecture

Each platform works independently in a chain: `build → test → benchmark`

```
build-linux → test-linux → benchmark-linux (independent chain)
build-windows → test-windows → benchmark-windows (independent chain)
build-macos → test-macos → benchmark-macos (independent chain)
benchmark-aggregate (after all benchmarks)
```

## Key Principles

1. **Platform Independence**: Each platform chain is independent
   - `test-linux` starts immediately after `build-linux` completes
   - `test-windows` starts immediately after `build-windows` completes
   - `test-macos` starts immediately after `build-macos` completes
   - No waiting for other platforms

2. **Benchmark Separation**: Benchmarks run as a separate layer
   - Uses artifacts from build jobs
   - Runs on already built libraries
   - Separate from tests
   - Aggregates results across platforms

3. **Test Coverage**: All tests run on each platform
   - Linux: C core tests, Node.js, Python, C#, Java
   - Windows: C core tests, Node.js, Python, C#, Java
   - macOS: C core tests, Node.js, Python, C#, Java

## Job Structure

### Build Jobs

- **build-linux**: Builds shared library on Linux, uploads artifact
- **build-windows**: Builds shared library on Windows, uploads artifact
- **build-macos**: Builds shared library on macOS, uploads artifact

### Test Jobs

- **test-linux**: Runs all tests on Linux (C, Node.js, Python, C#, Java)
  - Uses artifact from `build-linux`
  - Depends on: `build-linux`
  
- **test-windows**: Runs all tests on Windows (C, Node.js, Python, C#, Java)
  - Uses artifact from `build-windows`
  - Depends on: `build-windows`
  
- **test-macos**: Runs all tests on macOS (C, Node.js, Python, C#, Java)
  - Uses artifact from `build-macos`
  - Depends on: `build-macos`

### Benchmark Jobs

- **benchmark-linux**: Runs benchmarks on Linux (C, Node.js, Python)
  - Uses artifact from `build-linux`
  - Depends on: `test-linux`
  
- **benchmark-windows**: Runs benchmarks on Windows (C, Node.js, Python)
  - Uses artifact from `build-windows`
  - Depends on: `test-windows`
  
- **benchmark-macos**: Runs benchmarks on macOS (C, Node.js, Python)
  - Uses artifact from `build-macos`
  - Depends on: `test-macos`

### Aggregate Job

- **benchmark-aggregate**: Aggregates benchmark results from all platforms
  - Depends on: `benchmark-linux`, `benchmark-windows`, `benchmark-macos`

## Benefits

1. **Faster Execution**: No waiting between layers for different platforms
2. **Maximum Parallelism**: Each platform chain runs independently
3. **Clear Separation**: Tests and benchmarks are clearly separated
4. **Efficient Artifact Usage**: Artifacts are used optimally
5. **Platform Independence**: Each platform can be debugged independently

## Migration Notes

- Remove benchmark steps from test jobs
- Create separate benchmark jobs for each platform
- Update dependencies to follow platform chains
- Update artifact names to be platform-specific
