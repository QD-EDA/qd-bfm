# Caliptra top first AES/DMA W-channel trace — 2026-10-08

**Status: diagnostic integration result; not qualification.** The first short
AES/DMA firmware case passed in the full Caliptra top with the open AXI target
and `CALIPTRA_BFM_CHECKER` enabled. The test emitted one pass marker, no fail
marker or simulator/checker error, and finished normally. The output runner
initially classified the run as failed because it counted the expected
`Unable to create TCP server on port 0` message after the sandbox's exact JTAG
socket permission denial. Re-scanning the same unchanged simulation log with
the corrected classifier gives `passed=1`, `jtag_errors=0`, and
`jtag_bind_denials=1`. The runner's original output was left unchanged.

The AXI trace shows the first payload write completed without a stall:

| Cycle | Channel | Address | Result |
| ---: | --- | --- | --- |
| 1,348–1,351 | AW, W, B | `0x123440000` | W accepted next cycle; `WLAST=1`; B returned three cycles after AW |
| 2,907–2,909 | AR, R | `0x123440000` | Read response returned two cycles after AR |
| 2,995–2,998 | AW, W, B | `0x123460000` | W accepted next cycle; `WLAST=1`; B returned three cycles after AW |
| 3,146–3,148 | AR, R | `0x123460000` | Read response returned two cycles after AR |

The prior 600-second retry ended before its readback because it stopped the
simulation early; this run establishes that the target accepted the writes and
returned both reads. The result is specific to the one-case diagnostic image,
fast TRNG cadence, and PQ-vector suppression.

## Provenance

- Icarus source: `ac4532fab037e91df2f903e67fb40f59baedccca`, dirty and unpublished;
  this is diagnostic evidence only.
- Simulation exit: 0; testcase pass markers: 1; fail markers: 0; bad diagnostics: 0.
- Firmware finish: `minstret=1429`, `mcycle=3663`; AXI trace ended at cycle 3,802.
- Checker: enabled.
- Simulation log SHA-256: `4e3dc79f3423ab0aa5d6e6c6ddd25c7b17cfe53dbf3eb472b2e11de9317271e2`.
- Trace VPI source SHA-256: `27295f3f2d6172fc925f950b862dc8f6d82f518f344f118a2a9e63b2b953bd20`.
- Trace VPI plugin SHA-256: `1a7c0a663ccb25e40ad76cef9d501c8b9b1d049d727ae2d4e3faded2da662dfb`.

The compact simulation log and exact VPI source are kept beside this note.
