# Build Checklist

- [ ] Install CMake 3.10+, C++17 compiler, Git, vcpkg
- [ ] Clone https://github.com/CorsixTH/CorsixTH and submodules
- [ ] Configure with `cmake -S . -B build -DCMAKE_PREFIX_PATH=/opt/SDL3` (or vcpkg preset)
- [ ] Build with `cmake --build build -j`
- [ ] Verify `build/CorsixTH/corsix-th` exists
- [ ] Run with `build/CorsixTH/run-corsixth-dev.sh` or `SDL_VIDEODRIVER=offscreen`

## Related Pages

- [[28-build/SUMMARY]]
- [[28-build/MAP]]
- [[28-build/SCAFFOLD]]
