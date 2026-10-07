# Full-top random DMA bring-up

The full-top `rand_test_dma` run reached live AXI traffic but **did not finish**;
it is not firmware or BFM qualification. The pinned Caliptra top compiled and
firmware built with xPack RISC-V GCC 13.4.0 for arm64. Simulation ran for the
900-second guard limit and was stopped before a testcase pass/fail marker or
warm-reset recovery was observed.

- Caliptra RTL commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- Case/profile: `rand_test_dma`, stock `caliptra_top_tb.vf`
- Diagnostic options: fast TRNG cadence, verified `.data` preload, quiet
  firmware, AXI VPI trace; this is not a stock-image qualification run
- Full-top compile and firmware build: passed
- Successful firmware build log: `firmware-success.log`
- Simulation: guard timeout after 900 seconds at 68% current free memory
  (66% minimum observed; 60% floor)
- Trace endpoint: 9,040 cycles; 13 AW, 208 W, 13 B, 8 AR, and 128 R handshakes;
  no fatal was observed
- Not reached: testcase completion marker and warm-reset/resume evidence
- Trace SHA-256: `4e1ea6f8794d991334ff80fc46204263f5e02a93212a329a621e4a48ede0fc10`
- Trace: `sim-partial.log`
- Raw output directory: `/private/tmp/qd-bfm-fulltop-rand-dma-quiet-arm64-20261006`

The earlier attempt compiled the top but failed before simulation because its
RISC-V GCC 13.2 x86_64 binary required the unavailable Intel Homebrew library
`/usr/local/opt/isl/lib/libisl.23.dylib`. Its original logs remain below.

- Earlier full-top compile: passed; see `compile.log`
- Earlier firmware build: failed before producing images; see `firmware.log`
- Earlier run memory guard: 73% minimum free, with a 60% floor
- Earlier raw output directory: `/private/tmp/qd-bfm-rand-test-dma-20261006-retry3`

## One-case AES follow-up

A separate `smoke_test_dma_aes_gcm_short_1_dword` run used only the first AES
case, fast TRNG, verified `.data` preload, quiet firmware, and AXI tracing.
JTAG DPI bound successfully. The run reached one AXI write address, data beat,
and response at cycles 3149, 3150, and 3152. The memory guard then stopped the
run at cycle 3584 after free memory fell to 59% against the 60% floor (58% on
the post-run sample). No testcase completion marker was reached, so this is
partial integration evidence only.

- Raw trace SHA-256: `58bf76083a22373f1802655b1fcfd279ca72177a501bde89e5e9eb0841dbb737`
- Trace: `sim-one-aes-partial.log`
- Raw output directory: `/private/tmp/qd-bfm-top-short-aes-first-quiet-escalated-20261006`

## Bounded forced-reset random DMA follow-up

A diagnostic run limited `rand_test_dma` to one generated transfer and forced
`inject_rst` on that first transfer. The testbench generated exactly one case
and logged the reset assertion and deassertion; the CPU trace continued after
reset with no fatal observed. The memory guard stopped simulation at cycle
4,812 when free memory reached 59% against the 60% floor. No AXI handshakes or
testcase completion marker were reached, so this is reset-path progress only,
not a passing DMA test.

- Caliptra RTL commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- Profile: `rand_test_dma`, one iteration, forced first reset, fast TRNG,
  verified `.data` preload, quiet firmware, AXI VPI trace
- Memory guard: 66% free before run; 59% minimum observed; 60% floor
- Endpoint: 4,812 cycles, 1,754 retired instructions, zero AR/AW/W/B/R
  handshakes, `fatal=0`
- Simulation log SHA-256:
  `15463252dea25fa6af5c4f427052058e8a6073991711f73bad237b802d4495dd`
- Trace: `sim-forced-first-reset-partial.log`
- Raw output directory: `/private/tmp/qd-bfm-rand-dma-first-reset-20261007`

## Fixed reset-delay follow-up

A follow-up exercised the deterministic `--rand-dma-reset-delay-cycles 512`
overlay with one generated transfer. Top compilation and firmware build passed.
Simulation reached real AXI writes, then the 900-second guard timeout stopped
it before the testbench asserted warm reset. This does not qualify reset
recovery.

- Caliptra RTL commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- Profile: `rand_test_dma`, one iteration, forced first reset, fixed 512-cycle
  delay, fast TRNG, verified `.data` preload, quiet firmware, AXI VPI trace
- Services overlay SHA-256: `fcdd6675d1dd24aab9bd30b51f25352e44e1eeffcb1bcadcdf461e34b5a15675`
- Memory guard: 73% free before run; 64% minimum observed; 60% floor
- Endpoint: 10,800 cycles, 11 AW, 176 W, 11 B, zero AR/R, `reset_n=1`,
  `fatal=0`
- Simulation log SHA-256:
  `cd66e92cebd0454e76e9447fea346814d0b05c257b22355e8d404b4661e4f671`
- Trace: `sim-fixed-reset-delay-partial.log`
- The temporary simulator build tree was removed after preserving this log.

## No-trace comparison

The same one-transfer, fixed-512-cycle diagnostic was rerun without
`--trace-axi` to avoid trace-VPI overhead. The simulator log showed the
generated transfer with `inject_rst=1` and entry into Caliptra ROM flow. The
60% memory guard stopped the run when free memory reached 59%; no warm-reset
assertion, resume, or testcase completion marker was observed. This run adds
no reset-recovery qualification.

`inject_rst=1` in the generated DCCM record is only planned test data. The
pinned `rand_test_dma.c` sends stdout-control `0xEE` immediately before it
executes the selected DMA helper; `caliptra_top_tb_services.sv` starts the
delayed warm reset only after observing that write. The run log has no warm
reset event, but the original VPI trace did not record the `0xEE` write or the
service's pending-delay state, so it cannot distinguish a missing firmware
request from a delayed-reset scheduling problem. The earlier random-delay run
did log a reset pulse; the difference remains unresolved.

- Memory guard: 69% free before run; 59% minimum observed; 60% floor
- No result JSON was emitted because the guard stopped the runner
- The temporary simulator build tree was removed after inspection

The AXI trace VPI now also records `0xEE` mailbox writes, delayed-reset state,
and reset edges. It compiles with the local `iverilog-vpi`. The instrumented
full-top rerun stopped during vector preparation: preflight was 60% free and
the guard stopped it at 59%, before top compilation. Hierarchical binding and
runtime output remain unverified.

- Trace VPI SHA-256:
  `ff50cdb88665dc3fd227e7a6369dc05ecb29700cb5a0f3cfd7d9584c0736d851`

A disposable synthetic hierarchy smoke then loaded the VPI module and verified
the expected hierarchy names, `0xEE` request marker, and both reset-edge
callbacks. The smoke is now reproducible with
[`run_trace_vpi_smoke.sh`](../caliptra-bfm-open-top-smoke-20261006/run_trace_vpi_smoke.sh)
and [`trace_vpi_smoke.sv`](../caliptra-bfm-open-top-smoke-20261006/trace_vpi_smoke.sv).
It requires trace/reset bind markers, the firmware `0xEE` request, reset assert
and deassert edges in order, and one AXI AW handshake after reset. A guarded
run passed with 49% minimum free memory against a 45% floor. This validates the
tracer's synthetic hierarchy and event ordering; binding and reset behavior in
the actual Caliptra full-top remain unverified.

Re-run the fixture from the repository root with the normal Icarus tools on
`PATH` (or set `IVERILOG_BIN`, `VVP_BIN`, and `IVERILOG_VPI_BIN`):

```sh
python3 scripts/run_with_memory_pressure_guard.py \
  --max-process-bytes 6442450944 --min-available-bytes 6442450944 \
  --timeout-seconds 60 \
  --log /tmp/caliptra-trace-vpi.log -- \
  evidence/caliptra-bfm-open-top-smoke-20261006/run_trace_vpi_smoke.sh
```

## Actual-top forced-reset follow-up (2026-10-07)

The enhanced VPI bound to the real Caliptra top and observed the configured
512-cycle reset delay: reset asserted at cycle 2,896 and deasserted at 2,906.
The CPU resumed and the DMA produced 12 AXI write responses; a 13th write was
in progress when the runner reached its 1,800-second timeout. There were no AXI
reads, testcase pass marker, or fatal. This confirms actual-top reset signaling
and post-reset write traffic, but not full DMA recovery or testcase completion.

- Caliptra RTL commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- Profile: one `rand_test_dma` iteration, forced reset, 512-cycle delay, fast
  TRNG, verified `.data` preload, quiet firmware, checker enabled, AXI/reset VPI
- Memory guard: 40% floor; 48% minimum observed; timeout at 1,800 seconds
- Endpoint: cycle 11,200; 13 AW, 197 W, 12 B, zero AR/R; `reset_n=1`, `fatal=0`
- Trace: [sanitized simulation trace](../caliptra-bfm-rand-dma-reset-actual-top-20261007/sim-trace-sanitized.log); [structured result](../caliptra-bfm-rand-dma-reset-actual-top-20261007/result.json)
- The raw simulation log is not checked in because it includes generated seed and secret-key output; the committed trace keeps only test configuration, reset, AXI, and cycle-counter records.
- This run began before the Icarus `origin/main` merge to `BFM WORK`; it does not verify the merged simulator revision.
- After the run, `BFM WORK` merged `origin/main` at `197f9ba` (merge commit `ac4532f`) and built/installed successfully with GNU Bison 3.8.2. The guarded build had a 40% floor and 55% minimum free memory. The regression suite was not run; the binaries report `ac4532fa-dirty`.

## Reset-delay interpretation update (2026-10-07)

The 512-cycle trace places reset assertion at cycle 2,896 after the `0xEE`
request marker at cycle 2,382. No accepted AW precedes that reset; the first
observed AW is post-reset at cycle 5,785. The 512-cycle result therefore does
not demonstrate reset during an accepted DMA write. The 3,870-cycle candidate
targets cycle 6,254, between the baseline trace's AW at 6,036 and B at 6,398.
That candidate has not been run and is not reset-in-flight evidence.
