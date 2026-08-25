# CorsixTH CI/CD Pipeline Deep Research

## Executive Summary

CorsixTH employs a sophisticated multi-platform CI/CD pipeline spanning GitHub Actions (Linux, Windows, Windows Installer, Website Updates) and AppVeyor (legacy Windows). The pipeline validates code across **3 Lua runtimes** (LuaJIT, Lua 5.1, Lua 5.5), **3 Windows architectures** (x64, x86, dev), **4 Linux configurations** (apt-get, vcpkg, tracy, sanitizers), and **macOS** (arm64/x64, dev/rel). Static analysis includes **9 linters** and **2 C++ analysis tools**. Documentation auto-deploys to gh-pages on master pushes.

---

## 1. Linux Workflow (`.github/workflows/Linux.yml`)

### 1.1 Trigger Configuration
```yaml
on:
  push:
    branches-ignore: ['gh-pages']  # Skip docs-only branch
  pull_request:
  workflow_dispatch:
    inputs:
      animview: boolean    # Build AnimView tool
      pr: number          # Build specific PR
```

### 1.2 Job Matrix: `Linux-apt-get`

| Matrix Entry | Lua Runtime | Key Packages | Special Flags |
|-------------|-------------|--------------|---------------|
| 1 | **LuaJIT** | `libluajit-5.1-dev` | `-DWITH_LUAJIT=ON`, `WITH_MOVIES=OFF`, `WITH_MIDI_DEVICE=OFF` |
| 2 | **Lua 5.1** | `libavcodec-dev`, `libavformat-dev`, `libavutil-dev`, `libswresample-dev`, `libswscale-dev`, `librtmidi-dev` | `cmake=1`, `static_analysis=1`, `docs=1` |

**Runner**: `ubuntu-26.04` (Resolute Raccoon)

### 1.3 Job Matrix: `Linux-vcpkg`

Single configuration: **Lua 5.5** via vcpkg on `ubuntu-22.04`
- Uses `configurePreset: 'linux-dev-vcpkg'`
- Runs `clang-format-20` and `run-clang-tidy-20`
- Caches vcpkg binary packages

### 1.4 Static Analysis Steps (Lua 5.1 matrix only)

| Step | Tool | Command | Purpose |
|------|------|---------|---------|
| 1 | `luac5.1` | `find CorsixTH -name '*.lua' -print0 \| xargs -0 -I{} luac5.1 -p {}` | Syntax validation |
| 2 | **luacheck** | `luacheck --quiet --codes --ranges CorsixTH` | Lua linting (config: `.luacheckrc`) |
| 3 | **busted** | `busted --verbose --directory=CorsixTH/Luatest` | Unit tests |
| 4 | **whitespace** | `python3 scripts/check_whitespace.py -e scanner.cpp -e parser.cpp -e build` | Tabs/trailing spaces |
| 5 | **BOM check** | `python3 scripts/check_language_files_not_BOM.py` | UTF-8 without BOM |
| 6 | **lua classes** | `python3 scripts/check_lua_classes.py` | Class declaration pattern |
| 7 | **tabs in Lua** | `! grep -IrnP '\t' CorsixTH/Lua` | Enforce spaces |
| 8 | **LevelEdit** | `ant -buildfile LevelEdit/build.xml dist` | Java build validation |
| 9 | **codespell** | `codespell --skip="languages,corsix-th.6,*.dat" -L sav,unexpect,persistance,defin,uint,inout,currenty,blong,falsy,manuel` | Spell check (non-blocking) |
| 10 | **cmakelint** | `cmakelint --filter=-linelength [CMakeLists.txt files]` | CMake style |
| 11 | **yamllint** | `yamllint --config-data "rules: {line-length: disable}" .github/workflows/*.yml` | YAML syntax |
| 12 | **shellcheck** | `shellcheck --shell sh scripts/macos_luarocks` | Shell script lint |

### 1.5 Documentation Deployment
```yaml
- name: Generate documentation
  if: matrix.docs
  run: cmake --build build/ --target doc

- name: Upload documentation
  if: github.ref == 'refs/heads/master' && github.repository == 'CorsixTH/CorsixTH' && matrix.docs
  run: |
    git config user.email "documentationbot@corsixth.com"
    git config user.name "Docs Bot"
    git fetch origin gh-pages
    git checkout --force gh-pages
    rsync --recursive build/doc/ .
    git add animview/ corsixth_engine/ corsixth_lua/ index.html leveledit/
    if ! git diff --cached --exit-code; then
      git commit --message "Documentation from $(git rev-parse --short master) [no CI]"
      git push origin gh-pages
    fi
```
**Triggers**: Only on `master` branch pushes to `CorsixTH/CorsixTH` repo (not forks)

---

## 2. Windows Workflow (`.github/workflows/Windows.yml`)

### 2.1 Trigger Configuration
```yaml
on:
  push:
    branches-ignore: ['gh-pages']
  pull_request:
  workflow_dispatch:
    inputs:
      preset:
        type: choice
        options: ['win-dev', 'win-x64-rel', 'win-x86-rel']
        default: 'win-x64-rel'
      animview: boolean
      pr: number
```

### 2.2 CMake Presets Used

| Preset | Architecture | Generator | Triplet | Config |
|--------|-------------|-----------|---------|--------|
| `win-dev` | x64 | VS 17 2022 | (default) | Debug |
| `win-x64-rel` | x64 | VS 17 2022 | `x64-windows-release` | RelWithDebInfo |
| `win-x86-rel` | Win32 | VS 17 2022 | `x86-windows` | RelWithDebInfo |

### 2.3 vcpkg Bootstrap Process
```yaml
- name: Extract vcpkg baseline
  id: vcpkg-baseline
  shell: pwsh
  run: |
    $config = Get-Content vcpkg-configuration.json | ConvertFrom-Json
    $baseline = $config.'default-registry'.baseline
    echo "baseline=$baseline" >> $env:GITHUB_OUTPUT

- name: Checkout vcpkg
  uses: actions/checkout@v6
  with:
    repository: 'microsoft/vcpkg'
    ref: ${{ steps.vcpkg-baseline.outputs.baseline }}
    fetch-depth: 0
    path: vcpkg

- name: Bootstrap vcpkg
  shell: cmd
  run: |
    cd "%VCPKG_ROOT%"
    bootstrap-vcpkg.bat -disableMetrics
```

### 2.4 Build Steps
```yaml
- name: Run CMake configure
  shell: cmd
  run: |
    cmake --preset "%PRESET%" -DVCPKG_INSTALL_OPTIONS="--x-abi-tools-use-exact-versions" -DBUILD_ANIMVIEW=%ANIMVIEW%

- name: Run CMake build
  shell: cmd
  run: |
    cmake --build --preset "%PRESET%" --verbose

- name: Run CTest
  shell: cmd
  run: |
    ctest --preset "%PRESET%"

- name: Run CMake install
  if: inputs.PRESET != 'win-dev'
  shell: cmd
  run: |
    cmake --install build/%PRESET% --prefix ./artifact --config RelWithDebInfo
```

### 2.5 Artifact Upload
```yaml
- name: Upload build
  if: inputs.PRESET != 'win-dev'
  uses: actions/upload-artifact@v6
  with:
    path: ${{ inputs.animview && 'artifact' || 'artifact/CorsixTH' }}
    name: ${{env.NAME}}
```

---

## 3. Windows Installer Workflow (`.github/workflows/WindowsInstaller.yml`)

### 3.1 Purpose
Creates NSIS installer by combining x86 and x64 build artifacts from previous Windows workflow runs.

### 3.2 Trigger
```yaml
on:
  workflow_dispatch:
    inputs:
      x86:
        description: 'x86 run ID (url part)'
        required: true
        type: number
      x64:
        description: 'x64 run ID (url part)'
        required: true
        type: number
```

### 3.3 Process
```yaml
- name: Download x86 artifact
  uses: actions/download-artifact@v8
  with:
    run-id: ${{inputs.x86}}
    path: WindowsInstaller/x86
    github-token: ${{github.token}}

- name: Download x64 artifact
  uses: actions/download-artifact@v8
  with:
    run-id: ${{inputs.x64}}
    path: WindowsInstaller/x64
    github-token: ${{github.token}}

- name: Create installer
  run: |
    cd WindowsInstaller
    makensis -V4 -WX -- Win32Script.nsi
    sha256sum CorsixTHInstaller.exe >> $GITHUB_STEP_SUMMARY

- name: Upload installer
  uses: actions/upload-artifact@v7
  with:
    path: 'WindowsInstaller/CorsixTHInstaller.exe'
    archive: false
```

**Runner**: `ubuntu-24.04` (Linux) — NSIS runs on Linux via Wine/NSIS package

---

## 4. Website Update Workflow (`.github/workflows/update-website.yml`)

### 4.1 Trigger
```yaml
on:
  release:
    types: [created, deleted, released, unpublished]
```

### 4.2 Action
```yaml
jobs:
  dispatch:
    runs-on: ubuntu-latest
    steps:
      - uses: peter-evans/repository-dispatch@v2
        with:
          repository: CorsixTH/corsixth.github.io
          token: ${{ secrets.WEBSITE_REPO_TOKEN }}
          event-type: release
```
Dispatches a `release` event to the website repo for automatic site regeneration.

---

## 5. AppVeyor Configuration (`appveyor.yml`)

### 5.1 Legacy Windows CI
```yaml
version: '{build}'
image: Visual Studio 2022
pull_requests:
  do_not_increment_build_number: true
environment:
  VCPKG_ROOT: C:\Tools\vcpkg
  VCPKG_DEFAULT_BINARY_CACHE: C:\vcpkg-bin-cache
  LUA_PATH: "%APPVEYOR_BUILD_FOLDER%/vcpkg_installed/x64-windows-release/share/lua?.lua;;"
  LUA_CPATH: "%APPVEYOR_BUILD_FOLDER%/vcpkg_installed/x64-windows-release/bin/?/core.dll;%APPVEYOR_BUILD_FOLDER%/vcpkg_installed/x64-windows-release/bin/?.dll;;"
init:
  - mkdir %VCPKG_DEFAULT_BINARY_CACHE%
cache:
  - C:\vcpkg-bin-cache -> vcpkg_configuration.json
configuration: Release
install:
  - cd %VCPKG_ROOT%
  - git pull --quiet
  - .\bootstrap-vcpkg.bat
  - cd %APPVEYOR_BUILD_FOLDER%
before_build:
  - cmd: cmake --preset win-x64-rel -B .
build:
  project: CorsixTH_Top_Level.sln
  verbosity: minimal
test_script:
  - cmd: ctest --extra-verbose --build-config Release --output-on-failure
after_build:
  - cp -R %APPVEYOR_BUILD_FOLDER%/CorsixTH/Lua %APPVEYOR_BUILD_FOLDER%/CorsixTH/Release/Lua
  - cp -R %APPVEYOR_BUILD_FOLDER%/CorsixTH/Bitmap %APPVEYOR_BUILD_FOLDER%/CorsixTH/Release/Bitmap
  - cp -R %APPVEYOR_BUILD_FOLDER%/CorsixTH/Levels %APPVEYOR_BUILD_FOLDER%/CorsixTH/Release/Levels
  - cp -R %APPVEYOR_BUILD_FOLDER%/CorsixTH/Campaigns %APPVEYOR_BUILD_FOLDER%/CorsixTH/Release/Campaigns
  - cp %APPVEYOR_BUILD_FOLDER%/CorsixTH/CorsixTH.lua %APPVEYOR_BUILD_FOLDER%/CorsixTH/Release/
artifacts:
  - path: CorsixTH/Release/
    name: CorsixTH
```

**Key Differences from GitHub Actions Windows**:
- Uses `CorsixTH_Top_Level.sln` directly (VS solution)
- Manual vcpkg bootstrap in `install` phase
- Copies Lua/assets post-build for artifact
- Caches `vcpkg-bin-cache` keyed to `vcpkg_configuration.json`
- Only tests `win-x64-rel` preset

---

## 6. CMake Presets (`CMakePresets.json`)

### 6.1 Configure Presets (12 total)

| Preset | Platform | Generator | Build Type | Key Variables |
|--------|----------|-----------|------------|---------------|
| `linux-dev` | Linux | Ninja | Debug | `USE_SOURCE_DATADIRS=ON`, `ENABLE_UNIT_TESTS=ON`, `ENABLE_SANITIZERS=ON`, `BUILD_ANIMVIEW=ON`, `BUILD_TOOLS=ON` |
| `linux-dev-vcpkg` | Linux | Ninja | Debug | `CMAKE_TOOLCHAIN_FILE=$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake`, same as above |
| `linux-tracy` | Linux | Ninja | RelWithDebInfo | `WITH_TRACY=ON`, vcpkg toolchain |
| `win-dev` | Windows | VS 17 2022 | Debug | vcpkg toolchain, `BUILD_ANIMVIEW=ON`, `BUILD_TOOLS=ON` |
| `win-x64-rel` | Windows | VS 17 2022 (x64) | RelWithDebInfo | `VCPKG_TARGET_TRIPLET=x64-windows-release`, `FETCH_SOUNDFONT=ON`, `FETCH_UNICODE_FONT=ON` |
| `win-x86-rel` | Windows | VS 17 2022 (Win32) | RelWithDebInfo | `VCPKG_TARGET_TRIPLET=x86-windows`, same fetch options |
| `macos-arm64-dev` | macOS | Ninja | Debug | `VCPKG_TARGET_TRIPLET=arm64-osx`, clang, sanitizers |
| `macos-arm64-rel` | macOS | Unix Makefiles | RelWithDebInfo | `VCPKG_TARGET_TRIPLET=arm64-osx-release` |
| `macos-x64-dev` | macOS | Ninja | Debug | `VCPKG_TARGET_TRIPLET=x64-osx`, clang, sanitizers |
| `macos-x64-rel` | macOS | Unix Makefiles | RelWithDebInfo | `VCPKG_TARGET_TRIPLET=x64-osx-release` |

### 6.2 Build Presets (7)
Each maps 1:1 to configure preset with matching configuration (Debug/RelWithDebInfo).

### 6.3 Test Presets (8)
Each specifies `output.verbosity: extra` and `output.outputOnFailure: true`.

### 6.4 vcpkg Integration
All presets (except `linux-dev` and `linux-tracy`) use:
```json
"CMAKE_TOOLCHAIN_FILE": "$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
```

The `linux-dev-vcpkg` preset is used by GitHub Actions Linux-vcpkg job.
The `win-x64-rel` and `win-x86-rel` presets are used by GitHub Actions Windows workflow.
The `win-dev` preset is available for local development.

---

## 7. vcpkg Integration Details

### 7.1 `vcpkg.json` — Dependencies
```json
{
  "dependencies": [
    { "name": "lua", "features": ["tools"] },
    "sdl3",
    "luafilesystem",
    "lpeg",
    "libpng",
    "zlib",
    { "name": "fluidsynth", "features": ["sndfile"] },
    { "name": "sdl3-mixer", "features": ["libxmp", "fluidsynth", "libflac", "mpg123", "opusfile", "libvorbis", "wavpack"] },
    "freetype"
  ],
  "features": {
    "animview": { "dependencies": ["wxwidgets"] },
    "updatecheck": { "dependencies": [{ "name": "curl", "default-features": false, "features": ["ssl"] }] },
    "movies": { "dependencies": [{ "name": "ffmpeg", "default-features": false, "features": ["avcodec", "avformat", "swresample", "swscale"] }] },
    "midi": { "dependencies": ["rtmidi"] },
    "catch2": { "dependencies": ["catch2"] },
    "tracy": { "dependencies": [{ "name": "tracy", "features": ["cli-tools"] }] }
  }
}
```

### 7.2 `vcpkg-configuration.json` — Registries & Baseline
```json
{
  "default-registry": {
    "kind": "git",
    "baseline": "bee87c32fcf25e81b0d9c312144475b5e34181a8",
    "repository": "https://github.com/microsoft/vcpkg"
  },
  "registries": [
    {
      "kind": "artifact",
      "location": "https://github.com/microsoft/vcpkg-ce-catalog/archive/refs/heads/main.zip",
      "name": "microsoft"
    },
    {
      "kind": "git",
      "repository": "https://github.com/CorsixTH/vcpkg-registry",
      "baseline": "ddc4effddd5f69d77c2eae918d7f8ba55fc8ab37",
      "packages": ["ffmpeg", "ffmpeg-bin2c"]
    }
  ]
}
```

**Key Points**:
- Pinned baseline ensures reproducible builds
- Custom CorsixTH registry provides `ffmpeg` and `ffmpeg-bin2c` packages
- Binary caching in GitHub Actions keyed to hash of both JSON files

---

## 8. Code Examples for Common CI Failures

### 8.1 luacheck Failure
```bash
# Local reproduction
luarocks install luacheck
luacheck --quiet --codes --ranges CorsixTH

# Common fix: Check .luacheckrc globals list
# Add missing globals to .luacheckrc globals table
```

### 8.2 Whitespace Failure
```bash
# Local reproduction
python3 scripts/check_whitespace.py -e scanner.cpp -e parser.cpp -e build

# Fix: Remove tabs/trailing spaces
# Use editor config or: sed -i 's/\t/  /g' file.lua
```

### 8.3 BOM Encoding Failure
```bash
# Local reproduction
python3 scripts/check_language_files_not_BOM.py

# Fix: Convert to UTF-8 without BOM
# iconv -f UTF-8 -t UTF-8 file.lua > file.lua.new && mv file.lua.new file.lua
```

### 8.4 Lua Class Declaration Failure
```bash
# Local reproduction
python3 scripts/check_lua_classes.py

# Required pattern:
class "ClassName" (ParentClass)

---@type ClassName
local ClassName = _G["ClassName"]
```

### 8.5 cmakelint Failure
```bash
# Local reproduction
pip3 install cmakelint==1.4
cmakelint --filter=-linelength CMakeLists.txt CorsixTH/CMakeLists.txt ...

# Common issues: line length, command case, spacing
```

### 8.6 clang-format Failure
```bash
# Local reproduction
clang-format-20 -i CorsixTH/Src/*.cpp CorsixTH/Src/*.h AnimView/*.cpp AnimView/*.h libs/rnc/*.cpp libs/rnc/*.h CorsixTH/SrcUnshared/main.cpp
git diff

# Fix: Apply formatting or adjust .clang-format
```

### 8.7 clang-tidy Failure
```bash
# Local reproduction (requires compile_commands.json)
cmake --preset linux-dev-vcpkg
run-clang-tidy-20 -p build/dev-vcpkg

# Fix: Address warnings or add NOLINT comments
```

### 8.8 CTest Failure (Windows)
```bash
# Local reproduction
cmake --preset win-x64-rel
cmake --build --preset win-x64-rel --config RelWithDebInfo
ctest --preset win-x64-rel --output-on-failure

# Debug: Run specific test
ctest -R test_name --output-on-failure
```

### 8.9 vcpkg Baseline Mismatch
```bash
# Error: vcpkg baseline in vcpkg-configuration.json doesn't match checked-out vcpkg
# Fix: Update baseline in vcpkg-configuration.json to match current vcpkg commit
# Or run: git -C vcpkg log -1 --format=%H
```

### 8.10 Codespell False Positives
```bash
# Add to skip list in Linux.yml codespell command:
-L sav,unexpect,persistance,defin,uint,inout,currenty,blong,falsy,manuel,yourword
```

---

## 9. Pipeline Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Events                            │
│  push (non-gh-pages) │ PR │ workflow_dispatch │ release        │
└──────────────────────────┬──────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│  Linux.yml    │  │  Windows.yml  │  │Update-website │
│               │  │               │  │    .yml       │
│ Linux-apt-get │  │  Windows      │  │               │
│  ┌─────────┐  │  │  ┌─────────┐  │  │ Dispatch to   │
│  │ LuaJIT  │  │  │  │win-dev  │  │  │ corsixth.     │
│  │ Lua 5.1 │  │  │  │x64-rel  │  │  │ github.io     │
│  └─────────┘  │  │  │x86-rel  │  │  │ on release    │
│ Linux-vcpkg  │  │  └─────────┘  │  └───────────────┘
│  (Lua 5.5)   │  │               │
└───────────────┘  └───────────────┘
        │                  │
        ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    WindowsInstaller.yml                         │
│  workflow_dispatch(x86_run_id, x64_run_id)                     │
│  Download artifacts → NSIS → Upload CorsixTHInstaller.exe      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        AppVeyor (Legacy)                        │
│  VS 2022 │ vcpkg bootstrap │ win-x64-rel │ CTest │ Artifacts  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. Summary of Key Files

| File | Purpose |
|------|---------|
| `.github/workflows/Linux.yml` | Main CI: 3 Lua runtimes, 12 linters, docs deploy |
| `.github/workflows/Windows.yml` | Windows builds: 3 presets, vcpkg bootstrap, artifacts |
| `.github/workflows/WindowsInstaller.yml` | NSIS installer from Windows artifacts |
| `.github/workflows/update-website.yml` | Release → website repo dispatch |
| `appveyor.yml` | Legacy Windows CI (VS solution) |
| `CMakePresets.json` | 12 configure, 7 build, 8 test presets |
| `vcpkg.json` | Dependency manifest with 9 features |
| `vcpkg-configuration.json` | Pinned baseline + custom registry |
| `.luacheckrc` | Lua lint config (144 lines, extensive globals) |
| `scripts/check_*.py` | Custom whitespace, BOM, class validators |


## Related Pages

- [[20-cicd-pipeline/CHECKLIST]]
- [[20-cicd-pipeline/MAP]]
- [[20-cicd-pipeline/SCAFFOLD]]
