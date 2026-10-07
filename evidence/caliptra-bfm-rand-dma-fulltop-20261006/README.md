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
