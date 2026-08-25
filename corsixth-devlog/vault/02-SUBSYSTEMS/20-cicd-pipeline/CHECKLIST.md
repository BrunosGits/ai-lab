# Pre-PR CI Success Checklist

Complete every item before pushing. ⬜ = Not done, ✅ = Done

---

## 📋 Code Quality (Must Pass Locally)

### Lua Code
- [ ] **luacheck passes**: `luacheck --quiet --codes --ranges CorsixTH`
  - No W111/W112/W113 (undefined globals) — add to `.luacheckrc` if intentional
  - No W211 (unused locals) — prefix with `_` or remove
- [ ] **busted tests pass**: `busted --verbose --directory=CorsixTH/Luatest`
  - All existing tests pass
  - New tests added for new functionality
- [ ] **Syntax valid**: `find CorsixTH -name '*.lua' -print0 | xargs -0 -I{} luac5.1 -p {}`
- [ ] **Class declarations correct**: `python3 scripts/check_lua_classes.py`
  - Pattern: `class "Name" (Parent)` → blank line → `---@type Name` → `local Name = _G["Name"]`
- [ ] **No tabs in Lua**: `! grep -IrnP '\t' CorsixTH/Lua`
- [ ] **No BOM in Lua files**: `python3 scripts/check_language_files_not_BOM.py`

### Whitespace & Encoding
- [ ] **No tabs/trailing spaces**: `python3 scripts/check_whitespace.py -e scanner.cpp -e parser.cpp -e build`
  - Run `find . -name "*.lua" -exec sed -i 's/\t/  /g' {} +` to fix tabs
  - Run `find . -name "*.lua" -exec sed -i 's/[[:space:]]*$//' {} +` to fix trailing spaces

### C++ Code
- [ ] **clang-format clean**: `clang-format-20 -i CorsixTH/Src/*.cpp CorsixTH/Src/*.h AnimView/*.cpp AnimView/*.h libs/rnc/*.cpp libs/rnc/*.h CorsixTH/SrcUnshared/main.cpp && git diff --quiet`
  - Run clang-format, check `git diff`, commit if changes
- [ ] **clang-tidy clean**: `run-clang-tidy-20 -p build/dev-vcpkg` (requires vcpkg build)
  - Address warnings or add `// NOLINT(comment)` with justification

### Build System
- [ ] **cmakelint passes**: `cmakelint --filter=-linelength [all CMakeLists.txt]`
  - Lowercase commands, consistent spacing
- [ ] **CMake configure succeeds** for target preset:
  - Linux: `cmake --preset linux-dev-vcpkg`
  - Windows: `cmake --preset win-x64-rel`

---

## 🧪 Testing

### Unit Tests
- [ ] **Lua tests pass** (busted)
- [ ] **C++ tests pass** (CTest):
  - Linux: `ctest --preset linux-dev-vcpkg --output-on-failure`
  - Windows: `ctest --preset win-x64-rel --output-on-failure`

### Build Verification
- [ ] **Linux builds**: LuaJIT, Lua 5.1, Lua 5.5 (vcpkg)
- [ ] **Windows builds**: win-x64-rel, win-x86-rel
- [ ] **Install step works**: `cmake --install build/<preset> --prefix ./artifact`

---

## 📝 Documentation & Config

### Documentation
- [ ] **Docs build**: `cmake --build build/ --target doc` (no warnings/errors)
- [ ] **API docs updated** for new public functions/classes
- [ ] **README/CHANGELOG updated** if user-facing changes

### Configuration
- [ ] **Windows config current**: `eval "$(luarocks --lua-version 5.1 path)" && lua5.1 scripts/generate_windows_config.lua && git diff --exit-code`
  - If `git diff` shows changes, commit them
- [ ] **vcpkg.json updated** if new dependencies added
- [ ] **vcpkg-configuration.json baseline updated** if vcpkg updated

---

## 🔧 Workflow Files

### YAML Syntax
- [ ] **yamllint passes**: `yamllint --config-data "rules: {line-length: disable}" .github/workflows/*.yml`
- [ ] **No hardcoded secrets** — use `${{ secrets.NAME }}`
- [ ] **Permissions minimal**: `contents: read`, `pull-requests: read` (no write unless needed)

### Matrix/Strategy
- [ ] **New configurations tested** locally before adding to matrix
- [ ] **fail-fast: false** for independent matrix jobs
- [ ] **Runner labels current** (ubuntu-26.04, windows-2022, etc.)

---

## 🔐 Security & Secrets

- [ ] **No tokens/passwords in code** — use GitHub Secrets
- [ ] **WEBSITE_REPO_TOKEN** configured for website dispatch (maintainers only)
- [ ] **Dependabot alerts addressed** for vcpkg/github-actions dependencies

---

## 📦 Dependencies

### vcpkg
- [ ] **vcpkg.json** — all deps declared with correct features
- [ ] **vcpkg-configuration.json** — baseline matches tested vcpkg commit
- [ ] **Custom registry** (CorsixTH/vcpkg-registry) updated for forked packages

### LuaRocks
- [ ] **New Lua deps** added to CI install steps (Linux.yml lines 51-53, 58-61)
- [ ] **Version pins** where needed for reproducibility

---

## 🏷️ Release Preparation (If Applicable)

- [ ] **Version bumped** in CMakeLists.txt / relevant files
- [ ] **Changelog updated** with release notes
- [ ] **Windows installer tested** via WindowsInstaller.yml workflow_dispatch
- [ ] **Release tag format**: `vX.Y.Z` (semver)
- [ ] **GitHub Release created** (triggers website update workflow)

---

## 🚀 Pre-Push Commands (Run All)

```bash
# 1. Full local validation
./validate_before_push.sh

# 2. Quick smoke test builds
cmake --preset linux-dev-vcpkg && cmake --build --preset linux-dev-vcpkg
cmake --preset win-x64-rel && cmake --build --preset win-x64-rel --config RelWithDebInfo

# 3. Run tests
ctest --preset linux-dev-vcpkg --output-on-failure
ctest --preset win-x64-rel --output-on-failure

# 4. Check for uncommitted changes
git status

# 5. Push
git push origin feature-branch
```

---

## 🆘 If CI Still Fails

### Debug Steps
1. **Check Actions tab** → failed workflow → failed step → expand logs
2. **Compare local vs CI**: Runner OS, tool versions, environment
3. **Re-run with SSH** (GitHub Actions): Add `uses: mxschmitt/action-tmate@v3` to failed job
4. **Check common issues** in `CI_DEBUG_GUIDE.md` Section 9

### Common Quick Fixes
| Failure | Fix |
|---------|-----|
| luacheck globals | Add to `.luacheckrc` globals table |
| Whitespace tabs | `sed -i 's/\t/  /g' file.lua` |
| BOM encoding | `iconv -f UTF-8 -t UTF-8 file.lua > file.lua.new && mv file.lua.new file.lua` |
| Class declaration | Follow pattern in `CI_DEBUG_GUIDE.md` §3.3 |
| clang-format | Run locally, commit formatted files |
| vcpkg baseline | Update `vcpkg-configuration.json` baseline |
| CMake 4.x Lua 5.1 | Use CMake 3.16 (see guide) |

---

## ✅ Final Sign-Off

- [ ] All checklist items ✅
- [ ] `validate_before_push.sh` exits 0
- [ ] CI passes on draft PR (or push to feature branch)
- [ ] Code review approved
- [ ] Merge to master

---

**Remember**: CI is a safety net, not a development workflow. Run checks locally first!


## Related Pages

- [[20-cicd-pipeline/SUMMARY]]
- [[20-cicd-pipeline/MAP]]
- [[20-cicd-pipeline/SCAFFOLD]]
