# Checker-enabled full-top DMA attempt — 2026-10-07

**Status: timeout before AES/DMA; not a qualification pass.** The current QD-EDA
runner compiled the full Caliptra top with `CALIPTRA_BFM_CHECKER` enabled and
started the first short AES/DMA firmware diagnostic. Reset, fuse setup and
BootGo completed, then the simulation stayed in ROM flow until the 900-second
limit. It emitted no AES/DMA testcase result or normal finish.

The JTAG DPI listener bound successfully. The memory guard recorded 58% minimum
free RAM against a 40% floor. This run does not establish a checker failure: it
ended before a DMA request, and AXI VPI tracing was disabled. The full-top DMA
path with the checker enabled remains unqualified.

`result.json` records source, image, profile, checker-overlay and log hashes.
The 309 MB simulator image and raw log were kept outside the repository and
removed after hashing.
