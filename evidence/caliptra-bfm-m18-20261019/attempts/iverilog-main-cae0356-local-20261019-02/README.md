# Icarus main build — local macOS recovery

This recovery built the clean source snapshot for upstream `main` at `cae035642e056644274a01e98d4422ce286685b4` (source archive SHA-256 `396d4ddd8dc3a0f9285d67e3c23c15673b30d665c0956cffb10c8b51a2ee82e8`). The build used Homebrew Bison 3.8.2 and Z3 5.1.0. The generated Makefile already links `-lz3`, but omits Homebrew's Z3 library search path; the reproducible script passes Homebrew's Z3 include and library flags to `make` without changing tracked compiler source.

The first local try stopped at `vvp_dpi.cc:15` because the configured SDK include path did not resolve `ffi.h`; its log and resource record are retained. The second try got past `ffi.h` after configuring libffi flags, then stopped at `vvp_z3.cc:35` for `z3.h`. Adding the Z3 include path exposed the final link search-path issue (`ld: library 'z3' not found`). The final retry added the Homebrew Z3 library path and completed install plus UVM smoke. These are build-environment corrections only; no Icarus source was edited.

The successful command used `localrun 1800`, `make -j1`, and `make install`; the complete command is in `build-local.sh` and raw output is in `raw/retry-link.log`. The UVM smoke printed `No-rand test PASSED!` with zero warnings/errors/fatals. The compiler reports Icarus 13.0 (devel). Build host, dependency versions, binary hashes, and dynamic-library paths are in `raw/build-info.txt`. Local Mac binary hashes are distinct from the canonical Linux hashes recorded in the parent report.

`raw/retry-z3.log` records the intermediate missing-link-path failure, and `raw/retry-link.exit` records success (`0`). SHA-256 sidecars cover the raw logs and build metadata.
