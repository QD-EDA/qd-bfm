> Checkpoint copy: concise reports, the compact AXI trace, and its VPI source are preserved here; large simulation logs and generated binaries stay out of this feature branch.

# Open Caliptra AXI complex top smoke — 2026-10-06

**Status: diagnostic integration evidence, not a qualification pass.** The
full pinned `caliptra_top_tb` compiles with the open `caliptra_top_tb_axi_complex`
replacement. `smoke_test_veer` then reaches its pass marker and normal finish:
1,033 retired instructions, 7,355 cycles, and 1,034 trace records. The firmware
and DCCM image hashes match the frozen L0 runner inputs. No SVA, simulation
error, or fatal markers were emitted.

The run has two JTAG DPI socket bind errors because this sandbox denies socket
creation, including with the existing port-0 overlay. The L0 runner treats
those errors as a failure, so this is not counted as a qualified L0 pass. The
test also issues no DMA traffic; the AXI target behavior remains covered by
the separate block-level DMA/DUT evidence.

## Open profile-checker checkpoint — 2026-10-07

The full-top runner now defines `CALIPTRA_BFM_CHECKER`, connecting the native
Caliptra-profile protocol checker to the replacement's DMA AXI pins. The
full-top traces above predate this change and do not qualify DMA traffic with
the checker enabled. The guarded `axi/tests/run_caliptra_axi_complex_bfm.sh`
regression passed with its checker enabled: AXI error injection, SRAM/FIFO
traffic, FIFO controls, recovery availability, and randomized stalls passed;
minimum free RAM was 56% against a 40% floor. A checker-enabled first-AES
replay timed out in ROM flow before DMA; see the
[2026-10-07 result](../caliptra-bfm-fulltop-checker-dma-20261007/README.md).
A later current-runner first AES/DMA diagnostic passed with the checker both
on and off; see the paired results in that report. This covers only the
diagnostic one-case firmware configuration. Stock/full-suite qualification
remains open. The current full-top source profile separately
elaborated under IEEE 2017 with the checker enabled (`iverilog -tnull`): 17
compiler warnings, zero errors, and 58% minimum
free RAM against the same 40% floor. This is compile evidence only; it did not
run Caliptra firmware.

The integration uncovered and fixed an open-BFM control bug: Caliptra
initializes `dma_gen_block_size` only when `+CPTRA_RAND_TEST_DMA` is supplied.
The replacement now enables its generated recovery sequence only with that
same plusarg. Without it, an X block-size array is ignored as intended. The
focused test first failed on the X array, then passed after the fix.

The compile used `driver/iverilog` with `-g2017 -gassertions
-gcommercial-unsafe`, the open AXI complex module, and a temporary
Icarus-compatible SRAM-export copy. Runtime used hash-guarded temporary
reset, checker, numeric-`$fatal`, and JTAG-port overlays; no pinned Caliptra
file was changed. Guard results stayed above the 60% free-memory floor:
79% minimum during compile and 77% during simulation. The simulation had a
900-second bound and finished before it.

Files:

- [`result.json`](result.json) — commands’ qualification limits, hashes, and
  guard/finish metrics.
- `strict-diagnostic-compile.log` (raw artifact omitted from this checkpoint)
- `sim-diagnostic.log` (raw artifact omitted from this checkpoint)

At that point, the remaining top-level step was a firmware DMA scenario that
supplies `+CPTRA_RAND_TEST_DMA` and exercises the open AXI target through the
actual Caliptra top. The later diagnostic DMA result below supersedes that
status; stock L0 qualification is still open.

## DMA firmware follow-up

Six bounded top runs with the open AXI target timed out before a firmware
test result. They reached `CLP: ROM Flow in progress...`; historical run
details are:

| Firmware case | Physical RNG cadence | Guard | Minimum free memory | Result |
| --- | ---: | ---: | ---: | --- |
| `smoke_test_dma` | 500 cycles | 1,800 s | 77% | Timeout (exit 124) |
| `smoke_test_dma_aes_gcm_short_1_dword` | 500 cycles | 600 s | 77% | Timeout (exit 124) |
| `smoke_test_dma_aes_gcm_short_1_dword` | 50 cycles, diagnostic override | 1,800 s | 72% | Timeout (exit 124) |
| `smoke_test_dma_aes_gcm_short_1_dword` (all 12 cases) | 50 cycles, fast boot preload; PQ generators active | 900 s | 75% | ROM-flow timeout (exit 124) |
| `smoke_test_dma_aes_gcm_short_1_dword` (all 12 cases) | 50 cycles, fast boot preload; PQ generators skipped | 1,800 s | 70% | ROM-flow timeout (exit 124) |
| `smoke_test_dma_aes_gcm_short_1_dword` (all 12 cases) | 50 cycles, fast boot preload; PQ generators skipped; quiet firmware | 1,800 s | 68% | ROM-flow timeout (exit 124) |

All three simulation logs have SHA-256
`0dca66c812631aa21ebbe07094e7d0db9d55ebbba309c7bb12b28268ea44ef99`.
The raw logs remain in the local diagnostic output, not in this branch. After
checkpointing the code, nine redundant compiled images were removed to reclaim
space; the latest full-DMA and fast-RNG images remain. A 1,000-cycle VPI probe
on the fast-RNG image observed 265 CPU
instruction commits by simulated time 9,995,000 ps; the CPU is advancing after
BootGo, but this short probe does not establish when the full firmware reaches
the DMA request. The probe log SHA-256 is
`72f34229b158613162a6f1934de90566789537a3e5b9d2bae6067e7173af8f76`.

The fourth and fifth run hashes and markers are recorded in
[`full-aes-all-cases-pre-pq-skip-timeout.json`](full-aes-all-cases-pre-pq-skip-timeout.json)
and [`full-aes-all-cases-pqskip-timeout.json`](full-aes-all-cases-pqskip-timeout.json).
Their large simulator images and raw logs were removed after hashing. Both kept
the full 12-case firmware. Skipping unrelated MLDSA/MLKEM testbench vectors
reduced the simulator log from 49,658 to 4,512 bytes, but the run still reached
ROM flow only within 1,800 seconds. Neither run had AXI instrumentation, so
neither establishes DMA traffic or an AXI response failure. The sixth run also
used `--quiet-firmware` and timed out in ROM flow; its result and simulator-log
hash are in
[`full-aes-all-cases-pqskip-quiet-timeout.json`](full-aes-all-cases-pqskip-quiet-timeout.json).
The all-case runtime remains unqualified; the separate first-case transaction
pass below establishes only that diagnostic case.

## Fast CRT0 startup diagnostic

The opt-in `--fast-boot-data-preload` path verified the short AES firmware's
linker/disassembly layout, copied its 16,868 `.data` bytes from LMA `0xfd58`
to DCCM VMA `0x50020000`, and replaced only the verified startup branch at
`0x46` with a jump to the existing BSS-clear setup at `0x5a`. A 180-second
`+CLP_BUS_LOGS` probe reached the BSS loop and then the firmware banner-output
routine (340 retired instructions). It ended at the time guard with no testcase
pass/fail marker or simulation finish. The minimum free-memory reading was 77%;
two JTAG socket bind errors remain sandbox-related. This demonstrates startup
progress with the diagnostic image, not a DMA completion or stock-firmware
qualification. Hashes and the exact preload/branch metadata are in
[`fast-boot-probe.json`](fast-boot-probe.json).

## First AES/DMA case diagnostic

The runner's opt-in `--first-aes-case-diagnostic` builds a temporary firmware
copy that runs only the first 1-dword AES/DMA case, preloads `.data`, suppresses
low-priority firmware prints, and gates the unrelated MLDSA/MLKEM testbench
vector generators behind a plusarg. The pinned Caliptra tree and default
firmware flow are unchanged. The full-top image compiled successfully and its
JTAG server bound an ephemeral port. A guarded 300-second run completed reset
and fuse setup and reached `CLP: ROM Flow in progress`, but did not reach the
AES test banner or emit a DMA request. AHB traces grew to 5,047 lines; no
testcase result or normal finish appeared. Free memory stayed at 76% against a
60% floor. This remains diagnostic, not top-level DMA qualification. Exact
hashes and guard metrics are in
[`first-aes-case-diagnostic.json`](first-aes-case-diagnostic.json).


## Full-top first AES/DMA transaction trace — later run

A later 900-second guarded replay of the same first-case diagnostic completed
with `TESTCASE PASSED` and normal `$finish` at cycle 5,230 (1,857 retired
instructions). The open AXI target completed the actual Caliptra DMA path:

| Cycle | Handshake | Address |
| ---: | --- | --- |
| 2,905–2,908 | AW, W, B | `0x123440000` (payload write) |
| 4,359–4,361 | AR, R | `0x123440000` (payload read) |
| 4,447–4,450 | AW, W, B | `0x123460000` (AES destination write) |
| 4,594–4,596 | AR, R | `0x123460000` (readback) |

Write data handshook one cycle after AW; B followed AW by three cycles, and R
followed AR by two cycles. The memory guard's 60% free-memory floor was respected, with
75% minimum observed and exit 0. This extends the earlier timeout observations
above; those records remain as historical runs.

This is full-top integration evidence for the diagnostic first AES/DMA case.
It still uses `--fast-trng`, a one-case firmware copy, and PQ-vector suppression,
so it is not a stock-firmware qualification or general AXI signoff. Exact
run/image/source hashes and markers are in
[`first-aes-axi-trace.json`](first-aes-axi-trace.json); the compact log and VPI
trace source are [`first-aes-axi-trace.log`](first-aes-axi-trace.log) and
[`sim-axi-trace-vpi.c`](sim-axi-trace-vpi.c).


A subsequent 600-second retry with the runner's `--trace-axi` option ended at
cycle 4463 before a testcase marker. It saw one write handshake but no read,
then hit its time bound. The exact log/plugin hashes are in
[`short-aes-one-case-axi-trace-timeout.json`](short-aes-one-case-axi-trace-timeout.json).
This shorter attempt does not replace the 900-second passing first-case run
above.

Tracer follow-up (2026-10-07): `sim-axi-trace-vpi.c` now emits compact
`CALIPTRA_AXI WSTATE` records when WVALID changes and when WREADY or WLAST
changes while WVALID is active. This lets a later full-top replay distinguish
source-side gaps from target backpressure around an incomplete burst. Saved
logs and result hashes above predate this tracer change and are unchanged.

## W-state smoke repair and replay — 2026-10-09

The W-state tracer's new `wlast` VPI binding exposed a missing signal in its
small smoke fixture. The fixture now declares and drives `wlast`, and its
regression checks an accepted single-beat W transfer plus the `WSTATE` record.
The guarded smoke passes.

A replay of the retained first-AES compiled image with the updated tracer
completed with `* TESTCASE PASSED` and normal `$finish` at cycle 3,802. The
trace shows the open AXI target accepting each single-beat write without
backpressure:

| Cycle | Handshake | Result |
| ---: | --- | --- |
| 1,348–1,351 | AW, W, B to `0x123440000` | `WVALID=WREADY=WLAST=1`; B completed |
| 2,907–2,909 | AR, R from `0x123440000` | Read response completed |
| 2,995–2,998 | AW, W, B to `0x123460000` | `WVALID=WREADY=WLAST=1`; B completed |
| 3,146–3,148 | AR, R from `0x123460000` | Destination readback completed |

This trace localizes the interval between the first write response and the
next read to firmware progress before it issues AR; the target was idle during
that interval. It does not support an AXI target stall as the cause of the
earlier short retry timeout.

Diagnostic only: this reused the existing compiled image and dirty,
unpublished Icarus build `ac4532fa-dirty`; it is not qualification evidence.
The guarded replay exited 0, with a 0.81 GiB maximum process-group footprint
and 7.84 GiB minimum available memory. The retained trace log is
[`first-aes-wstate-retrace-20261009.log`](first-aes-wstate-retrace-20261009.log)
with SHA-256
`f5f001186e6f7b0a69878de8df8de77ac95f9ca6aa45a7056f86aff17c8c364b`;
the VPI source SHA-256 is
`27295f3f2d6172fc925f950b862dc8f6d82f518f344f118a2a9e63b2b953bd20`.

## Published-main AXI target replay — 2026-10-09

A live remote-head query returned published Icarus `main`
`0d8815febc260928e62d5c2ce82b14afd2e38dc3`. The guarded
`dv/caliptra_bfm/axi/tests/run_caliptra_axi_complex_bfm.sh` regression passed
with the existing build of that clean published revision and the profile
checker enabled. It checked the one-shot SLVERR range, SRAM/FIFO traffic,
FIFO controls, recovery availability, randomized stalls, and 208-dword burst
readback, then finished normally at `16580000` ps.

This is the AXI complex target's standalone top-testbench smoke, not a full
Caliptra RTL firmware run. The actual full-top first AES/DMA result above
remains a separate diagnostic result.

Command from the QD repository root:

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/vvp \
sh dv/caliptra_bfm/axi/tests/run_caliptra_axi_complex_bfm.sh
```
