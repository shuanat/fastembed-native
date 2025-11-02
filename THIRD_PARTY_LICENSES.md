# Third-Party Licenses

This document lists major third‑party components used by FastEmbed and links to their licenses. These components remain under their original licenses. Copies of their LICENSE/NOTICE files are preserved where required.

Note: This list is informational and may not be exhaustive of all transient dev/test dependencies (e.g., within `node_modules/`). For the authoritative text of each license, see the linked upstream repositories and bundled license files.

---

## ONNX Runtime

- Project: ONNX Runtime (Microsoft)
- License: MIT
- Upstream: <https://github.com/microsoft/onnxruntime>
- License File: `onnxruntime/LICENSE`
- Third-Party Notices: `onnxruntime/ThirdPartyNotices.txt`

## ONNX (Open Neural Network Exchange)

- Project: ONNX
- License: Apache-2.0
- Upstream: <https://github.com/onnx/onnx>
- License: <https://www.apache.org/licenses/LICENSE-2.0>

## pybind11

- Project: pybind11
- License: BSD-3-Clause
- Upstream: <https://github.com/pybind/pybind11>
- License: <https://github.com/pybind/pybind11/blob/master/LICENSE>

## node-addon-api

- Project: node-addon-api
- License: MIT
- Upstream: <https://github.com/nodejs/node-addon-api>
- License: <https://github.com/nodejs/node-addon-api/blob/main/LICENSE.md>

## node-gyp

- Project: node-gyp
- License: MIT
- Upstream: <https://github.com/nodejs/node-gyp>
- License: <https://github.com/nodejs/node-gyp/blob/master/LICENSE>

---

## Build-time tools (not distributed)

These tools are used for building only and are not distributed with FastEmbed binaries or packages; their licenses apply to the tools themselves:

- NASM — BSD-2-Clause — <https://www.nasm.us/license.html>
- GCC/Clang/MSVC — respective vendor licenses
- Maven / .NET SDK / Python setuptools — respective licenses

---

## Notes on Compliance

- Third‑party components remain under their original licenses even when used with FastEmbed.
- Where required by MIT/Apache‑2.0/BSD, LICENSE/NOTICE files are included in the corresponding directories or referenced above.
- If you redistribute binaries that bundle these components, ensure that you also provide the corresponding third‑party notices.

For questions or corrections to this list, please open a GitHub Issue.
