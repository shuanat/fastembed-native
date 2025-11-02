# FastEmbed Shared Native Library

This directory contains the core C and Assembly implementation shared by all language bindings.

## Building

```bash
make all          # Build all components
make fastembed.a  # Build static library only
make clean        # Clean build artifacts
```

## Contents

### src/

C and Assembly source code:

- `embedding_lib.asm`: SIMD-optimized vector operations
- `embedding_lib_c.c`: C wrappers for Assembly
- `embedding_generator.asm`: Hash-based embedding generator
- `embedding_gen_cli.c`: CLI tool
- `vector_ops_cli.c`: Vector operations CLI
- `onnx_embedding_cli.c`: ONNX Runtime CLI
- `onnx_embedding_loader.c`: ONNX integration

### include/

Public header files:

- `fastembed.h`: Main API
- `embedding_lib_c.h`: C function declarations
- `fastembed_config.h`: Configuration

## API

See main [README](../../README.md) for API documentation.

## Performance

- SIMD-optimized (SSE4, AVX2)
- Assembly-level performance
- Zero-copy operations where possible
