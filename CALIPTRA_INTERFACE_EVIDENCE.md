# Caliptra interface pilot: UNKNOWN

Base QD-BFM: `dfcb8d9640d00e22802c4a03eb67c4af14e5121a`.
Caliptra v2.1.2: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, clean checkout.
Simulator: Homebrew Verilator 5.050, `2026-07-01 rev vUNKNOWN-built20260701`.
Host: macOS arm64, Darwin 27.0.0, Mac17,3, 24 GiB RAM.

## What was checked

The adapter compiles the actual `src/axi/rtl/axi_pkg.sv` and `axi_if.sv` without
copies, source edits, SYNTHESIS/XCELIUM defines, warning suppression or replacement
interfaces. The named inbound path is `caliptra_top.s_axi_w_if/s_axi_r_if` through
`soc_ifc_top` into `axi_sub` (see `src/soc_ifc/rtl/soc_ifc_top.sv:361`).
This run uses the real interface with a local independent target, not that RTL.

| Configuration | Behavioral evidence | Pilot gate |
| --- | --- | --- |
| AW32/DW32/IW8/UW32 | 4 writes + 4 reads pass | UNKNOWN: 3 upstream warnings |
| AW32/DW64/IW1/UW32 | 4 writes + 4 reads pass | UNKNOWN: 3 upstream warnings |
| Adapter IW8 / interface IW1 | width mismatch rejected before transactions | expected invalid input |

The pin-level target checks addresses, lengths, sizes, burst type, IDs, data,
strobes, LAST and tied-zero request sidebands. It deliberately stalls AW/W/AR
and returns all four response encodings; only OKAY yields `ok=1`. IDs include
zero and the configured maximum. Strobes include full, low-byte, zero and
high-byte. Nonzero response user fields demonstrate they do not enter the
current task API; no semantics for those fields are verified. BAD_RID separately
fails both valid width configurations and emits no PASS. A wrong-revision input
is rejected by the script before compiling. Existing `./run.sh` still passes
on Icarus/vvp 13.0, including four-state and reset checks.

## Commands and diagnostics

```sh
./run.sh
./run_caliptra_interface.sh /path/to/caliptra-rtl /tmp/qd-caliptra-interface
```

The pilot is expected to exit **2**, not 0, with this pinned tool/source pair.
It stores exact compiler argv, ordered input SHA-256 hashes, tool version,
complete build output and positive/negative simulation logs in the output
directory. It requires a clean checkout at the full SHA before use.

Verilator reports WIDTHTRUNC at `axi_if.sv:230` and `:334` (32-bit `$clog2`
defaults assigned to 3-bit task inputs), and WIDTHEXPAND at `:370` (loop index
compared with 8-bit length). These occur in the upstream built-in tasks even
when the adapter does not call them. A minimal interface-only probe reproduced
the same three diagnostics. No waiver has been approved.

`-Wno-fatal` lets compilation continue to collect behavioral evidence, but does
not suppress a diagnostic or make the pilot pass: the runner prints and saves
all compiler output, then returns UNKNOWN if **any** compiler warning occurs on
a valid configuration. The deliberately invalid width case has its own expected
failure check. Build/test failures return 1. Default CI runs only `./run.sh`;
green CI therefore does not establish a clean interface pilot.

One fresh three-configuration run took 11.24 s wall time, including C++ builds;
`/usr/bin/time -l` reported 270,991,360 bytes maximum resident set size. Each
valid simulation ended at 540 ns. These are local observations, not the roadmap
Linux performance gate or a five-run benchmark.

## Actual subordinate compile probe

The upstream `src/axi/config/axi_sub.vf` alone lacks the primitive assertion
include path. Adding `+incdir+${CALIPTRA_ROOT}/src/caliptra_prim/rtl` resolves it.
With the adapter connected to `axi_sub` in a compile-only harness, this command
still exits 1 on the same three interface warnings:

```sh
CALIPTRA_ROOT=/path/to/caliptra-rtl verilator --lint-only --timing --assert \
  --top-module axi_sub_probe --timescale 1ns/1ps \
  +incdir+/path/to/caliptra-rtl/src/caliptra_prim/rtl \
  -f /path/to/caliptra-rtl/src/axi/config/axi_sub.vf \
  qd_axi4_single_master.sv qd_caliptra_axi_single_master.sv axi_sub_probe.sv
```

The compile-only harness is in the local evidence bundle; no subordinate
simulation result is claimed. Crucially, `caliptra_prim_assert.sv:111` selects
`caliptra_prim_assert_dummy_macros.svh` under VERILATOR. `--assert` cannot restore
macros removed by preprocessing. Thus the upstream protocol assertions are
**unavailable in this configuration**, not passing. No dummy was added by QD-BFM.

## Limits and next step

The local evidence directory `../evidence/bfm-caliptra-interface/` contains raw
logs, probes, tool/input hashes and a manifest; it is not published release
evidence. The pilot has not earned qualification. Actual `axi_sub` transactions,
top-level register/firmware smoke, independently active protocol assertions,
four-state interface simulation, reset-through-interface coverage, nonzero-user
access policy, bursts and UVM remain open. User/lock zero is a restricted adapter
policy, not proof that all real Caliptra accesses allow that policy. Review real
register permissions before choosing the next top-level smoke sequence.
