# CI Debug Guide — Run Checks Locally

This guide shows how to reproduce every CI check locally, common failure modes, and fixes.

---

## Prerequisites

### Ubuntu/Debian
```bash
# Base dependencies
sudo apt-get update
sudo apt-get install -y \
  cmake ninja-build \
  liblua5.1-dev lua5.1 luarocks \
  libsdl3-dev libfreetype-dev libcurl4-openssl-dev \
  libavcodec-dev libavformat-dev libavutil-dev \
  libswresample-dev libswscale-dev librtmidi-dev \
  libluajit-5.1-dev \
  doxygen yamllint \
  clang-format-20 clang-tidy-20 \
  ant openjdk-11-jdk  # For LevelEdit

# Python tools
sudo pip3 install -I codespell==2.2 cmakelint==1.4

# Lua rocks
sudo luarocks install luacheck
sudo luarocks install busted
sudo luarocks install luafilesystem
sudo luarocks install lpeg
```

### macOS (Homebrew)
```bash
brew install cmake ninja lua luajit luarocks sdl3 freetype curl ffmpeg rtmidi
brew install doxygen yamllint llvm@20 ant openjdk@11
pip3 install codespell==2.2 cmakelint==1.4
luarocks install luacheck busted luafilesystem lpeg
```

### Windows (Manual)
```cmd
# Install: Visual Studio 2022, vcpkg, NSIS, CMake, Ninja, Python, Lua 5.1, LuaRocks
# See: https://github.com/microsoft/vcpkg
```

---

## 1. Linux apt-get Build (LuaJIT & Lua 5.1)

### 1.1 LuaJIT Build
```bash
# Configure
cmake . -G"Unix Makefiles" -Bbuild \
  -DWITH_LUAJIT=ON \
  -DLUA_LIBRARY=/usr/lib/x86_64-linux-gnu/libluajit-5.1.so \
  -DWITH_MOVIES=OFF \
  -DWITH_MIDI_DEVICE=OFF \
  -DFETCH_SDL_MIXER=ON

# Build
cmake --build build/ -- VERBOSE=1
sudo cmake --build build/ -- install
```

### 1.2 Lua 5.1 Build (with Static Analysis)
```bash
# Install CMake 3.16 (oldest supported)
curl -L https://github.com/Kitware/CMake/releases/download/v3.16.9/cmake-3.16.9-Linux-x86_64.sh -o cmake.sh
sudo bash cmake.sh --prefix=/usr/local/ --exclude-subdir --skip-license

# Configure
cmake . -G"Unix Makefiles" -Bbuild -DFETCH_SDL_MIXER=ON

# Build
cmake --build build/ -- VERBOSE=1
sudo cmake --build build/ -- install
```

---

## 2. Static Analysis — Lua Checks

### 2.1 Syntax Validation (luac)
```bash
# Run
find CorsixTH -name '*.lua' -print0 | xargs -0 -I{} luac5.1 -p {}

# Common failures:
# - Syntax errors in Lua files
# - Mismatched parentheses/braces
# Fix: Check line numbers in error output
```

### 2.2 luacheck (Lua Linting)
```bash
# Install
luarocks install luacheck

# Run (uses .luacheckrc)
luacheck --quiet --codes --ranges CorsixTH

# Common failures:
# W111: Setting non-standard global variable
#   Fix: Add to .luacheckrc globals table
# W113: Accessing undefined variable
#   Fix: Check spelling, add to globals if intentional
# W211: Unused local variable
#   Fix: Prefix with _ or remove

# Debug: Show all warnings
luacheck --codes --ranges CorsixTH
```

### 2.3 busted (Unit Tests)
```bash
# Install
luarocks install busted

# Run
busted --verbose --directory=CorsixTH/Luatest

# Common failures:
# - Assertion failures in test files
# - Missing test dependencies
# Debug: Run single test file
busted --verbose CorsixTH/Luatest/specific_test.lua
```

---

## 3. Static Analysis — Code Style Checks

### 3.1 Whitespace Check
```bash
# Run
python3 scripts/check_whitespace.py -e scanner.cpp -e parser.cpp -e build

# Checks for:
# - TAB characters (anywhere)
# - Trailing spaces (space before CR/NL/EOF)

# Common failures:
# File "CorsixTH/Lua/file.lua" has at least one tab character
# File "CorsixTH/Lua/file.lua" has trailing whitespace

# Fix: Auto-remove
# Tabs → spaces:
find CorsixTH -name "*.lua" -exec sed -i 's/\t/  /g' {} +
# Trailing spaces:
find CorsixTH -name "*.lua" -exec sed -i 's/[[:space:]]*$//' {} +
```

### 3.2 BOM Encoding Check
```bash
# Run
python3 scripts/check_language_files_not_BOM.py

# Checks: Lua files must be UTF-8 WITHOUT BOM

# Common failures:
# Found files with UTF-8 with BOM encoding:
# brazilian_portuguese.lua

# Fix: Convert
for f in CorsixTH/Lua/languages/*.lua; do
  iconv -f UTF-8 -t UTF-8 "$f" > "$f.new" && mv "$f.new" "$f"
done
```

### 3.3 Lua Class Declaration Check
```bash
# Run
python3 scripts/check_lua_classes.py

# Required pattern (first non-comment lines):
class "ClassName" (ParentClass)

---@type ClassName
local ClassName = _G["ClassName"]

# Common failures:
# Invalid/Improper Class Declarations Found:
# *CorsixTH/Lua/entities/room.lua:RoomClass

# Fix: Ensure class declaration matches pattern exactly
# - Class name in quotes
# - Parent in parentheses (or nothing)
# - Blank line
# - ---@type annotation
# - local assignment from _G
```

### 3.4 Tabs in Lua Directory
```bash
# Run
! grep -IrnP '\t' CorsixTH/Lua

# Should return exit code 0 (no tabs found)
# Exit code 1 = tabs found (FAIL)

# Fix: Same as whitespace check
find CorsixTH/Lua -name "*.lua" -exec sed -i 's/\t/  /g' {} +
```

---

## 4. Static Analysis — Build System Checks

### 4.1 LevelEdit (Ant Build)
```bash
# Run
ant -buildfile LevelEdit/build.xml dist

# Requirements: JDK 11+, Ant
# Common failures:
# - Missing Java dependencies
# - Build.xml syntax errors
# Debug: ant -buildfile LevelEdit/build.xml -verbose
```

### 4.2 codespell (Spell Check)
```bash
# Install
pip3 install codespell==2.2

# Run (non-blocking in CI)
codespell --enable-colors --quiet-level 2 --skip="languages,corsix-th.6,*.dat" \
  -L sav,unexpect,persistance,defin,uint,inout,currenty,blong,falsy,manuel \
  AnimView CorsixTH CorsixTH/Lua/languages/english.lua LevelEdit libs || true

# Common failures:
# Spelling errors in comments/strings
# Fix: Add to -L list or correct spelling
# Debug: Run without || true to see errors
```

### 4.3 cmakelint (CMake Style)
```bash
# Install
pip3 install cmakelint==1.4

# Run
cmakelint --filter=-linelength \
  AnimView/CMakeLists.txt CMakeLists.txt CorsixTH/CMakeLists.txt \
  CorsixTH/CppTest/CMakeLists.txt CorsixTH/Src/CMakeLists.txt \
  CorsixTH/SrcUnshared/CMakeLists.txt libs/CMakeLists.txt libs/rnc/CMakeLists.txt \
  CMake/GenerateDoc.cmake

# Common failures:
# - Line too long (filtered out with -linelength)
# - Command case (prefer lower_case)
# - Spacing around parentheses
# Fix: Follow CMake style guide
```

### 4.4 yamllint (Workflow YAML)
```bash
# Install
sudo apt-get install yamllint  # or pip3 install yamllint

# Run
yamllint --config-data "rules: {line-length: disable}" .github/workflows/*.yml

# Common failures:
# - Indentation errors
# - Missing document start (---)
# - Trailing spaces
```

### 4.5 shellcheck (Shell Scripts)
```bash
# Install
sudo apt-get install shellcheck

# Run
shellcheck --shell sh scripts/macos_luarocks

# Common failures:
# - SC2086: Double quote to prevent globbing
# - SC2164: Use 'cd ... || exit'
# - SC2034: Unused variable
```

---

## 5. vcpkg Build (Linux-vcpkg Job)

### 5.1 Setup vcpkg
```bash
# Clone vcpkg at pinned baseline
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
git checkout bee87c32fcf25e81b0d9c312144475b5e34181a8
./bootstrap-vcpkg.sh -disableMetrics
export VCPKG_ROOT=$(pwd)
```

### 5.2 Install Dependencies
```bash
# Install LLVM 20 for clang-format/tidy
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh 20
sudo apt-get install libltdl-dev libx11-dev libxcursor-dev \
  libxft-dev libxext-dev libxtst-dev libxrandr-dev nasm \
  clang-format-20 clang-tidy-20 autoconf-archive
```

### 5.3 Build with CMake Preset
```bash
# Configure
cmake --preset linux-dev-vcpkg -DBUILD_ANIMVIEW=ON

# Build
cmake --build --preset linux-dev-vcpkg --verbose

# Test
ctest --preset linux-dev-vcpkg --output-on-failure
```

### 5.4 clang-format Check
```bash
# Run (modifies files in place!)
clang-format-20 -i CorsixTH/Src/*.cpp CorsixTH/Src/*.h \
  AnimView/*.cpp AnimView/*.h \
  libs/rnc/*.cpp libs/rnc/*.h \
  CorsixTH/SrcUnshared/main.cpp

# Check diff
git diff

# If changes shown → CI FAILS
# Fix: Commit formatted files or run clang-format before push
```

### 5.5 clang-tidy Check
```bash
# Run (requires compile_commands.json from build)
run-clang-tidy-20 -p build/dev-vcpkg

# Common checks:
# - modernize-use-nullptr
# - readability-identifier-naming
# - performance-unnecessary-value-param
# Fix: Address warnings or add // NOLINT(comment)
```

---

## 6. Windows Build (GitHub Actions)

### 6.1 Local Windows Build (vcpkg + CMake Presets)
```cmd
# Setup vcpkg
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
git checkout bee87c32fcf25e81b0d9c312144475b5e34181a8
bootstrap-vcpkg.bat -disableMetrics
set VCPKG_ROOT=%CD%

# Configure (win-x64-rel)
cmake --preset win-x64-rel -DVCPKG_INSTALL_OPTIONS="--x-abi-tools-use-exact-versions"

# Build
cmake --build --preset win-x64-rel --verbose --config RelWithDebInfo

# Test
ctest --preset win-x64-rel --output-on-failure

# Install
cmake --install build/win-x64-rel --prefix ./artifact --config RelWithDebInfo
```

### 6.2 Debug CTest Failures
```cmd
# List tests
ctest --preset win-x64-rel -N

# Run specific test with output
ctest --preset win-x64-rel -R "test_name" --output-on-failure --verbose

# Debug with Visual Studio
# Open CorsixTH_Top_Level.sln, set startup project, debug
```

---

## 7. Windows Installer (NSIS)

### 7.1 Local Build (Linux/macOS with Wine)
```bash
# Install NSIS
sudo apt-get install nsis  # Ubuntu
brew install nsis          # macOS

# Download x86 and x64 artifacts from CI
# Place in WindowsInstaller/x86 and WindowsInstaller/x64

# Build installer
cd WindowsInstaller
makensis -V4 -WX -- Win32Script.nsi
sha256sum CorsixTHInstaller.exe
```

### 7.2 Common NSIS Failures
```
- File not found: Check artifact paths in Win32Script.nsi
- Access denied: Run with proper permissions
- Compression errors: Check disk space
```

---

## 8. Documentation Build & Deploy

### 8.1 Local Doc Build
```bash
# Requires: doxygen, lua, lpeg, luafilesystem, LDocGen
cmake --build build/ --target doc

# Output in build/doc/
# Deploy: rsync to gh-pages branch (CI only)
```

---

## 9. Common Failure Patterns & Fixes

### 9.1 vcpkg Baseline Mismatch
**Error**: `vcpkg baseline in configuration doesn't match`
```bash
# Get current vcpkg commit
cd vcpkg && git log -1 --format=%H

# Update vcpkg-configuration.json baseline field
# Commit both files together
```

### 9.2 CMake Version Too New (Lua 5.1)
**Error**: CMake 4.x doesn't support Lua 5.1 find module
```bash
# Use CMake 3.16 (as CI does)
curl -L https://github.com/Kitware/CMake/releases/download/v3.16.9/cmake-3.16.9-Linux-x86_64.sh -o cmake.sh
sudo bash cmake.sh --prefix=/usr/local/ --exclude-subdir --skip-license
```

### 9.3 LuaRocks Path Issues
**Error**: `luarocks: command not found` or modules not found
```bash
# Ensure luarocks path is set
eval "$(luarocks --lua-version 5.1 path)"
export LUA_PATH="$LUA_PATH;;"
export LUA_CPATH="$LUA_CPATH;;"
```

### 9.4 Git Diff Exit Code (Config Check)
**Error**: `git diff --exit-code` fails in CI
```bash
# Regenerate windows config
eval "$(luarocks --lua-version 5.1 path)"
lua5.1 scripts/generate_windows_config.lua

# Check what changed
git diff WindowsInstaller/config_template.txt

# Commit if intentional, or fix generator
```

### 9.5 Codespell False Positives
**Error**: Legitimate words flagged
```bash
# Add to skip list in Linux.yml:
-L word1,word2,yourword

# Or ignore file:
--skip="path/to/file.lua"
```

### 9.6 Clang-Format Version Mismatch
**Error**: Local clang-format differs from CI (v20)
```bash
# Check version
clang-format --version

# Install v20 specifically
# Ubuntu: sudo apt-get install clang-format-20
# macOS: brew install llvm@20 && export PATH="/opt/homebrew/opt/llvm@20/bin:$PATH"
```

---

## 10. Pre-Push Validation Script

Create `validate_before_push.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== Running pre-push validation ==="

# 1. Whitespace
echo "1/10: Whitespace check..."
python3 scripts/check_whitespace.py -e scanner.cpp -e parser.cpp -e build

# 2. BOM
echo "2/10: BOM check..."
python3 scripts/check_language_files_not_BOM.py

# 3. Lua classes
echo "3/10: Lua class declarations..."
python3 scripts/check_lua_classes.py

# 4. Tabs in Lua
echo "4/10: Tabs in Lua..."
! grep -IrnP '\t' CorsixTH/Lua

# 5. luacheck
echo "5/10: luacheck..."
luacheck --quiet --codes --ranges CorsixTH

# 6. busted
echo "6/10: busted tests..."
busted --verbose --directory=CorsixTH/Luatest

# 7. cmakelint
echo "7/10: cmakelint..."
cmakelint --filter=-linelength \
  AnimView/CMakeLists.txt CMakeLists.txt CorsixTH/CMakeLists.txt \
  CorsixTH/CppTest/CMakeLists.txt CorsixTH/Src/CMakeLists.txt \
  CorsixTH/SrcUnshared/CMakeLists.txt libs/CMakeLists.txt libs/rnc/CMakeLists.txt \
  CMake/GenerateDoc.cmake

# 8. yamllint
echo "8/10: yamllint..."
yamllint --config-data "rules: {line-length: disable}" .github/workflows/*.yml

# 9. shellcheck
echo "9/10: shellcheck..."
shellcheck --shell sh scripts/macos_luarocks

# 10. Generate windows config
echo "10/10: Windows config..."
eval "$(luarocks --lua-version 5.1 path)"
lua5.1 scripts/generate_windows_config.lua
git diff --exit-code

echo "=== All checks passed! ==="
```

Make executable: `chmod +x validate_before_push.sh`

---

## 11. CI Log Analysis Tips

### 11.1 GitHub Actions Log Structure
```
Job: Linux-apt-get (Lua 5.1)
  Step: Install CorsixTH and lua test requirements
  Step: Install docs and static analysis requirements
  Step: Install CMake 3.16
  Step: Create CorsixTH makefiles with Lua 5.1
  Step: Build CorsixTH with Lua 5.1
  Step: Run lua tests          ← luacheck, busted
  Step: Run simple code tests  ← whitespace, BOM, classes, codespell, cmakelint, yamllint, shellcheck, config
  Step: Generate documentation
  Step: Upload documentation
```

### 11.2 Finding Failures
- Click failed step → expand `Run ...` section
- Look for `Error:` or non-zero exit codes
- Check `Annotations` tab for inline error markers

### 11.3 Re-running Failed Jobs
- Go to Actions tab → select run → "Re-run failed jobs"
- Or push empty commit: `git commit --allow-empty -m "ci: retry" && git push`

---

## 12. Environment Variable Reference

| Variable | Used In | Purpose |
|----------|---------|---------|
| `VCPKG_ROOT` | All vcpkg builds | Path to vcpkg installation |
| `VCPKG_DEFAULT_BINARY_CACHE` | Windows CI | Binary cache directory |
| `LUA_PATH` / `LUA_CPATH` | AppVeyor, tests | Lua module search paths |
| `PRESET` | Windows.yml | Selected CMake preset |
| `ANIMVIEW` | Windows.yml | ON/OFF for AnimView build |
| `GH_TOKEN` | All workflows | GitHub API token for PR checkout |

---

## 13. Useful Aliases for Development

Add to `.bashrc` / `.zshrc`:
```bash
# CorsixTH CI helpers
alias corsix-luacheck='luacheck --quiet --codes --ranges CorsixTH'
alias corsix-busted='busted --verbose --directory=CorsixTH/Luatest'
alias corsix-whitespace='python3 scripts/check_whitespace.py -e scanner.cpp -e parser.cpp -e build'
alias corsix-bom='python3 scripts/check_language_files_not_BOM.py'
alias corsix-classes='python3 scripts/check_lua_classes.py'
alias corsix-cmakelint='cmakelint --filter=-linelength AnimView/CMakeLists.txt CMakeLists.txt CorsixTH/CMakeLists.txt CorsixTH/CppTest/CMakeLists.txt CorsixTH/Src/CMakeLists.txt CorsixTH/SrcUnshared/CMakeLists.txt libs/CMakeLists.txt libs/rnc/CMakeLists.txt CMake/GenerateDoc.cmake'
alias corsix-yamllint='yamllint --config-data "rules: {line-length: disable}" .github/workflows/*.yml'
alias corsix-shellcheck='shellcheck --shell sh scripts/macos_luarocks'
alias corsix-config='eval "$(luarocks --lua-version 5.1 path)" && lua5.1 scripts/generate_windows_config.lua && git diff --exit-code'

# Full validation
alias corsix-validate='corsix-whitespace && corsix-bom && corsix-classes && ! grep -IrnP '"'"'\t'"'"' CorsixTH/Lua && corsix-luacheck && corsix-busted && corsix-cmakelint && corsix-yamllint && corsix-shellcheck && corsix-config'
```
