# Build System in CorsixTH

## Overview

This document covers how to compile CorsixTH from source, based on the wiki's How To Compile guide. The build uses CMake and vcpkg for dependencies.

## 1. Prerequisites

### Applications

| Application | Status | Notes |
|-------------|--------|-------|
| CMake | Required | 3.10 or later |
| C++ compiler | Required | Must support C++17 (Visual Studio, g++, Xcode) |
| Git client | Recommended | For vcpkg |
| vcpkg | Recommended | For CMake presets |

### Libraries (if not using vcpkg)

Development libraries are installed automatically via vcpkg when running cmake. Without vcpkg, manual installation is needed for each library.

## 2. Getting the Source

Clone the repository and update submodules. The source is at `https://github.com/CorsixTH/CorsixTH`.

## 3. Compiling

Use CMake to configure and build. With vcpkg, dependencies are handled automatically. Example:

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH=/opt/SDL3
cmake --build build -j
```

For the VPS setup, SDL3 3.4.14 + SDL3_mixer 3.2.4 are built from source into `/opt/SDL3`, and the game is configured with `-DCMAKE_PREFIX_PATH=/opt/SDL3`.

## 4. Build Output

The build produces `CorsixTH/corsix-th` and `libCorsixTH_lib.a` in `build/CorsixTH/`, plus `run-corsixth-dev.sh` for development runs.

## Related Pages

- [[28-build/MAP]]
- [[28-build/CHECKLIST]]
- [[28-build/SCAFFOLD]]
