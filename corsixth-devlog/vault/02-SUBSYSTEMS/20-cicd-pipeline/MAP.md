# CI/CD File:Line Index — CorsixTH

Complete mapping of every workflow step to source file and line number.

---

## `.github/workflows/Linux.yml` (183 lines)

| Line | Step/Section | Description |
|------|--------------|-------------|
| 1-2 | `---`<br>`name: Linux and Tests` | Workflow header |
| 4-7 | `permissions:` | `contents: read`, `pull-requests: read` |
| 8-21 | `on:` | Triggers: push (ignore gh-pages), PR, workflow_dispatch (animview, pr) |
| 22 | `jobs:` | Job definitions start |
| 23-133 | `Linux-apt-get:` | Main apt-get job (matrix) |
| 24-36 | `strategy:`<br>`matrix:`<br>`include:` | Matrix: LuaJIT (line 28-30), Lua 5.1 (line 31-35) |
| 36 | `runs-on: ubuntu-26.04` | Runner |
| 37 | `name: Linux apt-get ${{matrix.lua}}...` | Dynamic job name |
| 38-44 | `steps:`<br>`actions/checkout@v6`<br>`Checkout selected PR` | Checkout + optional PR checkout |
| 45-53 | `Install CorsixTH and lua test requirements` | apt-get install, luarocks (luacheck, busted) |
| 54-61 | `Install docs and static analysis requirements` | Conditional: lpeg, doxygen, yamllint, codespell, cmakelint, luafilesystem |
| 62-68 | `Install CMake 3.16` | Conditional: downloads & installs CMake 3.16.9 |
| 69-72 | `Create CorsixTH makefiles with ${{matrix.lua}}` | cmake configure with matrix.cmakejit |
| 73-76 | `Build CorsixTH with ${{matrix.lua}}` | cmake build + install |
| 77-85 | `Run lua tests` | Conditional (static_analysis): luac, luacheck, busted |
| 86-113 | `Run simple code tests` | Conditional: whitespace, BOM, lua classes, tabs, LevelEdit, codespell, cmakelint, yamllint, shellcheck, windows config |
| 114-117 | `Generate documentation` | Conditional (docs): cmake --target doc |
| 118-132 | `Upload documentation` | Conditional (master + CorsixTH/CorsixTH + docs): deploy to gh-pages |
| 134-183 | `Linux-vcpkg:` | vcpkg job (Lua 5.5) |
| 135-138 | `runs-on: ubuntu-22.04`<br>`env: VCPKG_BINARY_SOURCES` | Runner + binary cache config |
| 139-145 | `steps:`<br>`checkout`<br>`Checkout selected PR` | Checkout + PR |
| 146-153 | `Install build dependencies` | LLVM 20, X11 libs, clang-format-20, clang-tidy-20 |
| 154-159 | `Restore vcpkg cache` | actions/cache@v5 keyed to vcpkg.json + vcpkg-configuration.json |
| 160-161 | `Get CMake and Ninja` | lukka/get-cmake@v4.3.3 |
| 162-164 | `Setup vcpkg` | lukka/run-vcpkg@v11 |
| 165-174 | `Build CorsixTH, run tests` | lukka/run-cmake@v10 with linux-dev-vcpkg preset |
| 175-182 | `Run clang code tests` | clang-format-20 (checks diff), run-clang-tidy-20 |

---

## `.github/workflows/Windows.yml` (119 lines)

| Line | Step/Section | Description |
|------|--------------|-------------|
| 1-2 | `---`<br>`name: Windows` | Workflow header |
| 4-7 | `permissions:` | `contents: read`, `pull-requests: read` |
| 8-29 | `on:` | Triggers: push (ignore gh-pages), PR, workflow_dispatch (preset, animview, pr) |
| 30 | `jobs:` | |
| 31-119 | `Windows:` | Single job with matrix via preset input |
| 32-39 | `runs-on: windows-2022`<br>`env:` | Runner + PRESET, ANIMVIEW, NAME, VCPKG_ROOT, VCPKG_DEFAULT_BINARY_CACHE |
| 40-42 | `defaults: run: shell: bash` | Default shell |
| 43-51 | `steps:`<br>`Checkout`<br>`Checkout selected PR` | Checkout + PR |
| 52-60 | `Extract vcpkg baseline` | PowerShell: reads vcpkg-configuration.json baseline |
| 61-68 | `Checkout vcpkg` | actions/checkout@v6 from microsoft/vcpkg at baseline |
| 69-74 | `Bootstrap vcpkg` | cmd: bootstrap-vcpkg.bat -disableMetrics |
| 75-81 | `Setup binary cache` | actions/cache@v5 for vcpkg binary cache |
| 82-86 | `Ensure directories exist` | mkdir vcpkg cache + artifact |
| 87-91 | `Run CMake configure` | cmd: cmake --preset with VCPKG_INSTALL_OPTIONS |
| 92-96 | `Run CMake build` | cmd: cmake --build --preset --verbose |
| 97-101 | `Run CTest` | cmd: ctest --preset |
| 102-107 | `Run CMake install` | Conditional (!= win-dev): cmake --install to artifact |
| 108-112 | `List the artifact files` | Conditional: ls -R artifact |
| 113-119 | `Upload build` | Conditional: upload-artifact@v6 (artifact or artifact/CorsixTH) |

---

## `.github/workflows/WindowsInstaller.yml` (48 lines)

| Line | Step/Section | Description |
|------|--------------|-------------|
| 1-2 | `---`<br>`name: Windows installer` | Workflow header |
| 4-6 | `permissions: contents: read` | |
| 7-18 | `on: workflow_dispatch:` | Manual trigger with x86/x64 run IDs |
| 19 | `jobs:` | |
| 20-48 | `WindowsInstaller:` | |
| 21-22 | `runs-on: ubuntu-24.04`<br>`name: Make and test Windows installer` | Linux runner (NSIS on Linux) |
| 23-24 | `steps:`<br>`actions/checkout@v6` | |
| 25-26 | `Install NSIS` | apt-get install nsis |
| 27-32 | `Download x86 artifact` | actions/download-artifact@v8 from x86 run |
| 33-38 | `Download x64 artifact` | actions/download-artifact@v8 from x64 run |
| 39-43 | `Create installer` | cd WindowsInstaller; makensis -V4 -WX Win32Script.nsi; sha256sum |
| 44-48 | `Upload installer` | upload-artifact@v7: CorsixTHInstaller.exe |

---

## `.github/workflows/update-website.yml` (21 lines)

| Line | Step/Section | Description |
|------|--------------|-------------|
| 1 | `name: Update website` | |
| 3 | `permissions: {}` | No permissions needed |
| 5-11 | `on: release:` | Triggers: created, deleted, released, unpublished |
| 12 | `jobs:` | |
| 13-21 | `dispatch:` | |
| 14-16 | `runs-on: ubuntu-latest` | |
| 17-21 | `peter-evans/repository-dispatch@v2` | Dispatches 'release' event to CorsixTH/corsixth.github.io |

---

## `appveyor.yml` (38 lines)

| Line | Step/Section | Description |
|------|--------------|-------------|
| 1 | `version: '{build}'` | Build version format |
| 2 | `image: Visual Studio 2022` | Build image |
| 3-4 | `pull_requests: do_not_increment_build_number: true` | PR handling |
| 5-9 | `environment:` | VCPKG_ROOT, VCPKG_DEFAULT_BINARY_CACHE, LUA_PATH, LUA_CPATH |
| 10-11 | `init: mkdir %VCPKG_DEFAULT_BINARY_CACHE%` | Create cache dir |
| 12-13 | `cache: C:\vcpkg-bin-cache -> vcpkg_configuration.json` | Cache config |
| 14 | `configuration: Release` | Build config |
| 15-19 | `install:` | cd vcpkg, git pull, bootstrap-vcpkg.bat |
| 20 | (blank) | |
| 21-22 | `before_build: cmake --preset win-x64-rel -B .` | Configure |
| 23-25 | `build: project: CorsixTH_Top_Level.sln, verbosity: minimal` | MSBuild |
| 26-28 | `test_script: ctest --extra-verbose --build-config Release --output-on-failure` | Tests |
| 29 | (blank) | |
| 30-35 | `after_build:` | Copy Lua, Bitmap, Levels, Campaigns, CorsixTH.lua to Release/ |
| 36-38 | `artifacts: CorsixTH/Release/ -> CorsixTH` | Artifact upload |

---

## `CMakePresets.json` (248 lines)

### Configure Presets (lines 3-145)

| Line | Preset | Key Details |
|------|--------|-------------|
| 4-17 | `linux-dev` | Ninja, Debug, USE_SOURCE_DATADIRS, ENABLE_UNIT_TESTS, ENABLE_SANITIZERS, BUILD_ANIMVIEW, BUILD_TOOLS, CMAKE_EXPORT_COMPILE_COMMANDS |
| 18-32 | `linux-dev-vcpkg` | Ninja, Debug, **CMAKE_TOOLCHAIN_FILE=vcpkg**, same as linux-dev |
| 33-46 | `linux-tracy` | Ninja, RelWithDebInfo, vcpkg toolchain, WITH_TRACY=ON |
| 47-58 | `win-dev` | VS 17 2022, Debug, vcpkg toolchain, BUILD_ANIMVIEW, BUILD_TOOLS |
| 59-71 | `win-x64-rel` | VS 17 2022, x64, RelWithDebInfo, vcpkg toolchain, **VCPKG_TARGET_TRIPLET=x64-windows-release**, FETCH_SOUNDFONT, FETCH_UNICODE_FONT |
| 72-84 | `win-x86-rel` | VS 17 2022, Win32, RelWithDebInfo, vcpkg toolchain, **VCPKG_TARGET_TRIPLET=x86-windows**, FETCH_SOUNDFONT, FETCH_UNICODE_FONT |
| 85-102 | `macos-arm64-dev` | Ninja, Debug, arm64-osx triplet, clang, sanitizers, BUILD_ANIMVIEW, BUILD_TOOLS |
| 103-114 | `macos-arm64-rel` | Unix Makefiles, RelWithDebInfo, arm64-osx-release triplet |
| 115-132 | `macos-x64-dev` | Ninja, Debug, x64-osx triplet, clang, sanitizers |
| 133-144 | `macos-x64-rel` | Unix Makefiles, RelWithDebInfo, x64-osx-release triplet |

### Build Presets (lines 146-182)

| Line | Preset | Configure Preset | Configuration |
|------|--------|-----------------|---------------|
| 147-151 | `linux-dev` | linux-dev | Debug |
| 152-156 | `linux-dev-vcpkg` | linux-dev-vcpkg | Debug |
| 157-161 | `win-dev` | win-dev | Debug |
| 162-166 | `win-x64-rel` | win-x64-rel | RelWithDebInfo |
| 167-171 | `win-x86-rel` | win-x86-rel | RelWithDebInfo |
| 172-176 | `macos-arm64-rel` | macos-arm64-rel | RelWithDebInfo |
| 177-181 | `macos-x64-rel` | macos-x64-rel | RelWithDebInfo |

### Test Presets (lines 183-247)

| Line | Preset | Configure Preset | Configuration | Output |
|------|--------|-----------------|---------------|--------|
| 184-192 | `linux-dev` | linux-dev | Debug | verbosity: extra, outputOnFailure: true |
| 193-201 | `linux-dev-vcpkg` | linux-dev-vcpkg | Debug | same |
| 202-210 | `win-dev` | win-dev | Debug | same |
| 211-219 | `win-x64-rel` | win-x64-rel | RelWithDebInfo | same |
| 220-228 | `win-x86-rel` | win-x86-rel | RelWithDebInfo | same |
| 229-237 | `macos-arm64-rel` | macos-arm64-rel | RelWithDebInfo | same |
| 238-246 | `macos-x64-rel` | macos-x64-rel | RelWithDebInfo | same |

---

## `vcpkg.json` (90 lines)

| Line | Section | Details |
|------|---------|---------|
| 1 | `{` | |
| 2-33 | `"dependencies":` | lua (tools), sdl3, luafilesystem, lpeg, libpng, zlib, fluidsynth (sndfile), sdl3-mixer (8 features), freetype |
| 34-89 | `"features":` | animview (wxwidgets), updatecheck (curl+ssl), movies (ffmpeg), midi (rtmidi), catch2, tracy (cli-tools) |

---

## `vcpkg-configuration.json` (20 lines)

| Line | Section | Details |
|------|---------|---------|
| 1 | `{` | |
| 2-6 | `"default-registry":` | git, baseline: `bee87c32fcf25e81b0d9c312144475b5e34181a8`, microsoft/vcpkg |
| 7-19 | `"registries":` | [0] microsoft CE catalog (artifact), [1] CorsixTH/vcpkg-registry (git, baseline: `ddc4effddd5f69d77c2eae918d7f8ba55fc8ab37`, packages: ffmpeg, ffmpeg-bin2c) |

---

## `.luacheckrc` (144 lines)

| Line | Section | Details |
|------|---------|---------|
| 1-19 | License header | MIT |
| 21 | `self = false` | Don't check self |
| 22-90 | `globals = {` | 100+ global names: CorsixTH internals, game classes, UI, actions, math, test helpers |
| 92-93 | `files["CorsixTH/Luatest"] = {std = "+busted"}` | Test files use busted std |
| 95 | `codes = true` | Show warning codes |
| 96 | `max_line_length = false` | No line length limit |
| 97 | `unused_args = false` | Allow unused args |
| 99-100 | `exclude_files = {` | Bitmap, api_version.lua, LDocGen |
| 102-113 | `add_ignore()` helper | Function to add ignores per file |
| 115-130 | Language file ignores | Ignore W111, W112, W113, W314 for all 30 language files |
| 132-144 | Specific function ignores | Save game compat stubs in app.lua, bottom_panel.lua, options.lua, machine.lua, patient.lua, staff.lua, vip_go_to_next_room.lua, operating_theatre.lua |

---

## `scripts/check_whitespace.py` (145 lines)

| Line | Function | Description |
|------|----------|-------------|
| 1-15 | Module docstring | Usage, checks TAB, trailing space |
| 17-33 | Constants | BAD_WHITESPACE regex, MESSAGES dict |
| 35-58 | `check_for_bad_whitespace(path)` | Returns error message or None |
| 60-142 | `main()` | CLI parsing (-h, -e), walks dirs, checks .py/.lua/.h/.cpp/.cc/.c |
| 144-145 | `if __name__ == '__main__': main()` | Entry point |

**CI invocation**: Line 90 in Linux.yml: `python3 scripts/check_whitespace.py -e scanner.cpp -e parser.cpp -e build`

---

## `scripts/check_language_files_not_BOM.py` (52 lines)

| Line | Function | Description |
|------|----------|-------------|
| 1-9 | Module docstring | Checks for UTF-8 BOM in .lua files |
| 11-23 | `is_BOM_encoded_file(path)` | Reads first 4 bytes, checks for codecs.BOM_UTF8 |
| 25-50 | Main | Walks dir, checks .lua files, prints offending files, exits 1 if found |

**CI invocation**: Line 92 in Linux.yml: `python3 scripts/check_language_files_not_BOM.py`

---

## `scripts/check_lua_classes.py` (42 lines)

| Line | Section | Description |
|------|---------|-------------|
| 1-6 | Imports | os, re, sys |
| 8-11 | Regex | `^class "(.+)".*\n\n(?!---@type \1\nlocal \1 = _G\["\1\"])` |
| 12-17 | Setup | script_dir = CorsixTH/Lua, ignored = languages/ |
| 18-29 | Walk & check | For each .lua (not in languages), apply regex, print failures |
| 30-41 | Output | Summary + required pattern if failures |

**CI invocation**: Line 94 in Linux.yml: `python3 scripts/check_lua_classes.py`

---

## `scripts/generate_windows_config.lua` (57 lines)

| Line | Section | Description |
|------|---------|-------------|
| 1-24 | License header | MIT |
| 25-37 | Helpers | `do_not_wrap`, `serialize()`, `loadstring_envcall()`, `path()` |
| 38-51 | Config generation | Loads config_finder, gets defaults, sets placeholder values |
| 52-56 | Write template | Saves to WindowsInstaller/config_template.txt |

**CI invocation**: Line 111-113 in Linux.yml: `eval "$(luarocks --lua-version 5.1 path)"` + `lua5.1 scripts/generate_windows_config.lua` + `git diff --exit-code`

---

## Cross-Reference: CI Steps → Source Files

| CI Step | Workflow | Line | Source File | Source Lines |
|---------|----------|------|-------------|--------------|
| luacheck | Linux.yml | 82-83 | `.luacheckrc` | 1-144 |
| busted | Linux.yml | 84-85 | `CorsixTH/Luatest/` | (test files) |
| whitespace | Linux.yml | 89-90 | `scripts/check_whitespace.py` | 1-145 |
| BOM check | Linux.yml | 91-92 | `scripts/check_language_files_not_BOM.py` | 1-52 |
| lua classes | Linux.yml | 93-94 | `scripts/check_lua_classes.py` | 1-42 |
| tabs in Lua | Linux.yml | 95-96 | (grep) | - |
| LevelEdit | Linux.yml | 97-98 | `LevelEdit/build.xml` | (Ant) |
| codespell | Linux.yml | 99-102 | (codespell) | - |
| cmakelint | Linux.yml | 103-106 | (cmakelint) | - |
| yamllint | Linux.yml | 107-108 | (yamllint) | - |
| shellcheck | Linux.yml | 109-110 | `scripts/macos_luarocks` | (shell) |
| windows config | Linux.yml | 111-113 | `scripts/generate_windows_config.lua` | 1-57 |
| clang-format | Linux.yml | 177-182 | `.clang-format` | (config) |
| clang-tidy | Linux.yml | 182 | `.clang-tidy` | (config) |
| vcpkg baseline | Windows.yml | 53-60 | `vcpkg-configuration.json` | 2-6 |
| vcpkg deps | All | - | `vcpkg.json` | 1-90 |
| CMake presets | All | - | `CMakePresets.json` | 1-248 |

---

## Quick Navigation Commands

```bash
# View specific workflow section
sed -n '77,85p' .github/workflows/Linux.yml    # lua tests
sed -n '86,113p' .github/workflows/Linux.yml   # code tests
sed -n '175,183p' .github/workflows/Linux.yml  # clang tests

# View CMake preset
jq '.configurePresets[] | select(.name=="linux-dev-vcpkg")' CMakePresets.json
jq '.configurePresets[] | select(.name=="win-x64-rel")' CMakePresets.json

# View vcpkg baseline
jq '.["default-registry"].baseline' vcpkg-configuration.json

# View luacheck globals
grep -A 70 '^globals = {' .luacheckrc
```
