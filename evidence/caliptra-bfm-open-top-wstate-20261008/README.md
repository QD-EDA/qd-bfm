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

## Second AES/DMA vector — 2026-10-08

The next firmware vector (`--limit-aes-cases 1 --start-aes-case 1`) also
passed with the checker enabled. Unlike the first vector, it transfers two
beats per DMA buffer. The trace shows:

| Cycle | Channel | Address | Result |
| ---: | --- | --- | --- |
| 1,378–1,382 | AW, W, B | `0x123440000` | Two accepted W beats; `WLAST=1` on beat two; B completed |
| 2,973–2,977 | AR, R | `0x123440000` | Two read beats; checker reported no framing error |
| 3,063–3,067 | AW, W, B | `0x123460000` | Two accepted W beats; `WLAST=1` on beat two; B completed |
| 3,212–3,216 | AR, R | `0x123460000` | Two read beats; checker reported no framing error |

The runner reported PASS, with one testcase pass marker, no fail markers,
unexpected diagnostics, or JTAG server errors. The sandbox bind denial was
recorded separately. The generated result and compact simulation log are
[`second-aes-result.json`](second-aes-result.json) and
[`second-aes-axi-wstate.log`](second-aes-axi-wstate.log).

This remains diagnostic evidence on the dirty, unpublished Icarus source SHA
above; it does not qualify the stock firmware or the full 12-vector suite.

## Third and fourth AES/DMA vectors — 2026-10-08

The following vectors passed in isolated runs with the checker enabled. Their
source and destination transactions use three and four beats respectively:

| Vector | Source AW/W/B | Source AR/R | Destination AW/W/B | Destination AR/R | Firmware finish |
| ---: | --- | --- | --- | --- | --- |
| 3 | 1,383–1,388; 3 W beats | 2,943–2,949; 3 R beats | 3,035–3,040; 3 W beats | 3,182–3,188; 3 R beats | PASS; `mcycle=3857` |
| 4 | 1,478–1,484; 4 W beats | 3,034–3,042; 4 R beats | 3,128–3,134; 4 W beats | 3,287–3,295; 4 R beats | PASS; `mcycle=4000` |

All writes were accepted without W-channel stalls and the checker reported no
framing errors. Each run emitted one testcase pass marker, no fail markers,
unexpected diagnostics, or JTAG server errors. The paired sandbox listener
denial was recorded separately. Per-run result JSON and logs are
[`third-aes-result.json`](third-aes-result.json),
[`third-aes-axi-wstate.log`](third-aes-axi-wstate.log),
[`fourth-aes-result.json`](fourth-aes-result.json), and
[`fourth-aes-axi-wstate.log`](fourth-aes-axi-wstate.log).

Together with the first two vectors above, this gives separate full-top
diagnostic passes for one-, two-, three-, and four-beat DMA buffers. The runs
use a diagnostic firmware copy, fast TRNG cadence, and PQ-vector suppression;
all remain diagnostic on the dirty, unpublished Icarus source SHA.

## Fifth AES/DMA vector — 2026-10-08

The fifth short-suite vector passed in isolation with the checker enabled
(`--limit-aes-cases 1 --start-aes-case 4`). It exercised five-beat source
transfers and split the destination into four- and one-beat writes:

| Cycle | Channel | Address | Result |
| ---: | --- | --- | --- |
| 1,492–1,499 | AW, W, B | `0x123440000` | Five W beats; B completed |
| 3,073–3,083 | AR, R | `0x123440000` | Five read beats |
| 3,215–3,221 | AW, W, B | `0x123460000` | Four W beats; B completed |
| 3,280–3,283 | AW, W, B | `0x123460010` | One W beat; B completed |
| 3,438–3,448 | AR, R | `0x123460000` | Five read beats |

Firmware reported PASS at `mcycle=4209`; the runner recorded one pass marker,
no fail markers, no error/fatal diagnostics, and no unexpected JTAG errors.
The exact bind-denied sandbox message was recorded separately. The run used a
single-vector firmware copy, fast TRNG cadence, PQ-vector suppression, and
Icarus source `ac4532fab037e91df2f903e67fb40f59baedccca` (`ac4532fa-dirty`).
This is diagnostic evidence, not qualification. The full suite and clean,
published Icarus replay remain open. See
[`fifth-aes-result.json`](fifth-aes-result.json) and
[`fifth-aes-axi-wstate.log`](fifth-aes-axi-wstate.log).
