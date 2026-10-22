# Local M20-pinned Icarus build

- Source: `dsellerbrock/iverilog-uvm` commit `cae035642e056644274a01e98d4422ce286685b4`; submodules were initialized at the commits listed in `raw/metadata.txt`.
- Host/build tools: MacBook Air, macOS 27.0, Apple clang 21.0.3, Bison 3.8.2, Flex 2.6.4, gperf 3.0.3. `make -j3`; peak RSS stayed below 1.4 GiB in the full build attempt.
- Build attempts 1 and 2 stopped at compiler setup: missing Homebrew include path for `z3.h`, then missing Homebrew library search path for `-lz3`. `ask-intern` triage was manually checked against the logs. Attempt 3 completed `make install`; the wrapper then failed only while writing the install manifest under the wrong working directory. The installed binaries were independently executed and hashed; `retry-link.sh` now writes that manifest through an absolute evidence path.
- Installed compiler: Icarus 13.0 (devel) `(cae03564)`, local binary SHA-256 `0f6c688825ca70480510526384fc56365c5eb7ba3b4f5d1c5834489451eec2ea`.
- Matching runtime: VVP 13.0 (devel) `(cae03564)`, binary SHA-256 `b5dd81144624fbd2ad81ceb406d04d7e4bce2250d43541e419ce898303a6129d`.
- This is a local build from the exact pinned source commit; its platform-specific binary hash differs from the DAN-DESKTOP binary hash. The M20-pinned DAN-DESKTOP Icarus binary (`6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`) was used in the remote minimal reproducer transcript.
- `raw/local-c339-verilator-reproducer.log` confirms the local build from the M20 source pin reproduces the command-width discrepancy and the explicitly sized expression on both simulators.
