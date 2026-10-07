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

## BSS-preload follow-up — 2026-10-07

The fast-boot helper now validates and preloads the exact zero-filled `.bss`
image before skipping both CRT0 loops. Its runner suite passes 28 tests,
including nonempty AES `.bss`, empty `rand_test_dma` `.bss`, and rejection of
nonzero BSS data. A checker-enabled full-top retry did not reach simulation:
the available development Icarus build stopped during top compilation with
208,896 repeated errors at the generated services overlay (expression kind 26
in a vector context). The memory guard observed 56% minimum free RAM against
the 40% floor. The 245 MB compile log was hashed
(`01f0dcacb067343bed23e816ecf15e55416e678c402be02cfd3f90b432b0e776`) and
removed. This retry provides no checker or DMA result.
