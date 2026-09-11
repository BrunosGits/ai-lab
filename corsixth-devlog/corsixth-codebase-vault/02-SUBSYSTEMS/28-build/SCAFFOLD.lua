--[[ Build Scaffold
Usage: Copy this scaffold to test a new build configuration.

This file is a template, not executed. Replace with your build test.
]]

-- Example: Test build with SDL3 from source
-- cmake -S /opt/SDL3 -B /opt/SDL3/build -DCMAKE_INSTALL_PREFIX=/opt/SDL3
-- cmake --build /opt/SDL3/build -j
-- cmake --install /opt/SDL3/build
-- cmake -S . -B build -DCMAKE_PREFIX_PATH=/opt/SDL3
-- cmake --build build -j
