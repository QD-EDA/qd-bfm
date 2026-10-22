# ML-DSA native command-width reproducer

## Finding

The pinned Adams Bridge `mldsa_predictor.svh` writes native-reference commands using `$fwrite(fd, "%02X\n", op_code-1)`. The two driving sequences for rows 93 and 97 also write unsized decimal literals `1` and `2` for signing and verification. On the M20-pinned Icarus build (source commit `cae035642e056644274a01e98d4422ce286685b4`), Icarus formats these as eight hex digits; the C reader consumes the first byte pair and dispatches the sign/verify input as key generation (`00`). A stopped row 93 attempt directly shows `signing_input_for_test.hex` beginning `00000001`, the helper output beginning `00` with keygen PK/SK shape, and the sequence reading that output into `SIG` before writing it to DUT registers. The existing row 93/97 archives independently show the same keygen-shaped native output.

The root-cause layer for M20 is Icarus display-format semantics: IEEE 1800-2017 §21.2.1.3 makes field width a minimum, so a 32-bit argument to `%02X` expands to eight digits. The output is standards-conforming; the concrete mismatch is Caliptra treating that formatted 32-bit value as a one-byte opcode. This is not an ML-DSA crypto/RTL failure or an Icarus conformance defect. See the exact-pin reproducer and compatibility issue #797. The per-run M16 compatibility overlay sizes all three predictor expressions to `op_code-3'd1` and the affected sequence literals to `3'd1`/`3'd2`; it does not change RTL, firmware, data, or checks.

## Cross-simulator check

`command_width.sv` writes the three legacy predictor expressions followed by their sized forms, then the unsized `1`/`2` sequence commands and their sized forms. `read_command.c` uses the same line-by-line/first-byte read behavior as the pinned native C helper and asserts the decoded command sequence. `run.sh` builds and checks both simulators.

| Host/tool | Legacy lines | Sized lines | Decoded commands |
|---|---|---|---|
| DAN-DESKTOP, Icarus 13.0 (`cae03564`), binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330` | `00000000`, `00000001`, `00000002` | `00`, `01`, `02` | `00 00 00 00 01 02` |
| DAN-DESKTOP, Verilator 5.032 | `00`, `01`, `02` | `00`, `01`, `02` | `00 01 02 00 01 02` |
| Mac, Icarus 14.0 devel, binary SHA-256 `8de905f21f15a875807196b7bd7a29dfc6f5250aa90696e40850370da1677ffd` | `00000000`, `00000001`, `00000002` | `00`, `01`, `02` | `00 00 00 00 01 02` |
| Mac, Icarus 13.0 devel built from the M20 source pin `cae035642e056644274a01e98d4422ce286685b4`, binary SHA-256 `0f6c688825ca70480510526384fc56365c5eb7ba3b4f5d1c5834489451eec2ea` | `00000000`, `00000001`, `00000002` | `00`, `01`, `02` | `00 00 00 00 01 02` |
| Mac, Verilator 5.051 devel | `00`, `01`, `02` | `00`, `01`, `02` | `00 01 02 00 01 02` |

This table records the first six predictor-command lines; the four sequence-command lines are checked below.

The Verilator formatter behavior is described in its [official format-task documentation](https://github.com/verilator/verilator/blob/master/docs/guide/extensions.rst#L419-L425). The explicit-width change makes the intended command byte independent of that difference.

The four added sequence-command lines were separately checked using the same C reader. Under the exact-source local M20-pinned Icarus build, unsized literal `1`/`2` decode as `00 00`, while `3'd1`/`3'd2` decode as `01 02`. Mac Verilator 5.051 decodes both forms as `01 02`. The full 10-command check passed on both; `sequence-command-results.log` SHA-256 is `184241cc86e4f13b820e8bdb63ef88fd9a1e3f9ba1ddf80b8b482943fa311271`.

The locally built M20-pinned Icarus run and Mac Verilator run are captured in `../../toolchain-c339-local-20261020/raw/local-c339-verilator-reproducer.log` (SHA-256 `3c35e8dac3b656c856b7a96ca6cf0899b89d8ed0d6df8db9960b7f57905c98d6`).

## Files

- `command_width.sv`: minimal simulator input.
- `read_command.c`: minimal native-reference parser check.
- `run.sh`: local Icarus/Verilator self-check.
- `c339-verilator-results.txt`: exact pinned-host run transcript and versions.
- `check_overlay.py`: applies both sequence overlays to the pinned Adams Bridge source and verifies changed command tokens and hashes.
- `overlay-check.log`: overlay self-check log SHA-256 `7744c16f26189d3f2f102b1225e562941c70c9a32d9390384e669e8a823063b9`.
- `runner-tests-after-sequence-fix.log`: 83 passing runner tests; SHA-256 `07b2230bb2c53d2f560daaee52fa1578ec04c595ca2a1367a51927ac839c3345`.
