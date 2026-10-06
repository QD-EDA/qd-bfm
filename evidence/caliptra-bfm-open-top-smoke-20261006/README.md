> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

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

The remaining top-level step is a firmware DMA scenario that supplies
`+CPTRA_RAND_TEST_DMA` and exercises the open AXI target through the actual
Caliptra top. It needs a JTAG-capable runner environment to satisfy the current
L0 result gate.

## DMA firmware follow-up

Three bounded top runs were attempted with the open AXI target. Each reached
`CLP: ROM Flow in progress...` but stopped at its wall-clock guard before any
test pass/fail, simulator error/fatal, or JTAG error marker:

| Firmware case | Physical RNG cadence | Guard | Minimum free memory | Result |
| --- | ---: | ---: | ---: | --- |
| `smoke_test_dma` | 500 cycles | 1,800 s | 77% | Timeout (exit 124) |
| `smoke_test_dma_aes_gcm_short_1_dword` | 500 cycles | 600 s | 77% | Timeout (exit 124) |
| `smoke_test_dma_aes_gcm_short_1_dword` | 50 cycles, diagnostic override | 1,800 s | 72% | Timeout (exit 124) |

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

These runs are timeout diagnostics, not a firmware DMA pass. The full-top DMA
runtime remains unqualified; faster RNG cadence alone did not reach a later
visible checkpoint within 30 minutes.

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
