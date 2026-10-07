# Checker-enabled full-top DMA attempt — 2026-10-07

**Status: timeout before AES/DMA; not a qualification pass.** The current QD-EDA
runner compiled the full Caliptra top with `CALIPTRA_BFM_CHECKER` enabled and
started the first short AES/DMA firmware diagnostic. Reset, fuse setup and
BootGo completed, then the simulation stayed in ROM flow until the 900-second
limit. It emitted no AES/DMA testcase result or normal finish.

The JTAG DPI listener bound successfully. The memory guard recorded 58% minimum
free RAM against a 40% floor. This run does not establish a checker failure: it
ended before a DMA request, and AXI VPI tracing was disabled. A later
checker-enabled first-case diagnostic passes below; stock and full-suite
qualification remain open.

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

A second bounded attempt used Homebrew Icarus 13 with a temporary command
adapter translating `-g2017` to `-g2012` and dropping the unsupported
`-gcommercial-unsafe` option. Compilation stopped on unsupported Caliptra RTL
syntax (`caliptra_sram.sv`, `ahb_slv_sif.sv`, `pv_gen_hash.sv`, and other
files), before simulation. The guard observed 60% minimum free RAM against
the 40% floor. Its 1.5 MB compile output was hashed
(`2d4cbbfaedbbc5bf2be8b63709914c08911664767e32836f342b1b13b92c485f`) and
removed. This does not qualify stock Icarus 13 as a replacement for the
development compiler needed by the full-top flow.

## Current-runner first AES/DMA A/B — 2026-10-07

The checker-disabled build used runner commit `a6cd3d1`; the checker-enabled
replay used `6005e423`. Both commits contain identical runner-script content
(SHA-256 recorded in each result), the same Caliptra revision, diagnostic
settings and firmware image hashes. The checker-disabled image was launched
manually after the sandboxed runner attempt could not bind its JTAG socket; a
temporary `python` to `python3` alias supplied the testbench's generator path.
The checker-enabled case ran through the guarded runner. Each reached
`* TESTCASE PASSED` and normal `$finish` at `mcycle=3572` (`minstret=1426`);
each log had zero fail, error, or JTAG-error markers.

| Checker | Compile/simulation | Minimum free RAM | Result |
| --- | --- | ---: | --- |
| Disabled | 0 / 0 | 48% | Pass, one testcase marker |
| Enabled | 0 / 0 | 45% | Pass, one testcase marker |

The earlier checker-enabled ROM timeout was not reproduced. The checker was
enabled on the actual Caliptra top and emitted no error for this case. These
runs use a one-case firmware copy, fast TRNG, fast boot preload, skipped
MLDSA/MLKEM vector generation, and suppressed low-priority firmware prints.
AXI VPI tracing was off, so this is not transaction-trace evidence or stock
firmware qualification. Full-suite, random-DMA reset, and stock-configuration
coverage remain open.

The exact result JSON and compact log for each variant are preserved here:

- Checker disabled: [`result`](checker-disabled-first-aes-result.json),
  [`log`](checker-disabled-first-aes-sim.log).
- Checker enabled: [`result`](checker-enabled-first-aes-result.json),
  [`log`](checker-enabled-first-aes-sim.log).
