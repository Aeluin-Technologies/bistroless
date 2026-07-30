# Bistroless Images

Optimized, multi-architecture base container images tailored for Bazel OCI
builds. These images bundle runtime dependencies into minimal Distroless
baselines to streamline containerization without requiring runtime package
downloads.

## Available Images

| Image Name | Base Image | Included Dependencies |
| --- | --- | --- |
| `bristroless-python` | `distroless/python3-debian13` | `dagster`, `dagster-webserver` |

## Features

* **Pre-bundled Dependencies:** Includes framework binaries to eliminate
downloading dependencies during build or execution phases.
* **Minimal Attack Surface:** Built on top of Google Distroless images to
ensure a minimal, secure production footprint without shells, etc.
* **Multi-Arch Support:** Cross-compiled natively for both x86_64 (`amd64`)
and ARM64 (`arm64/v8`).

## Usage with Bazel

Reference the image in your `MODULE.bazel`:

```starlark
oci.pull(
    name = "bristroless_python",
    image = "ghcr.io/aeluin-technologies/bristroless-python",
    platforms = [
        "linux/amd64",
        "linux/arm64/v8",
    ],
    tag = "latest",
)
```
