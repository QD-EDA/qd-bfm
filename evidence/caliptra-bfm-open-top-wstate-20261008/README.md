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

## Sixth AES/DMA vector — 2026-10-08

The sixth vector passed in isolation with the checker enabled
(`--limit-aes-cases 1 --start-aes-case 5`). It exercised six-beat source
transfers and split the destination into four- and two-beat writes:

| Cycle | Channel | Address | Result |
| ---: | --- | --- | --- |
| 1,552–1,560 | AW, W, B | `0x123440000` | Six W beats; B completed |
| 3,141–3,153 | AR, R | `0x123440000` | Six read beats |
| 3,283–3,289 | AW, W, B | `0x123460000` | Four W beats; B completed |
| 3,350–3,354 | AW, W, B | `0x123460010` | Two W beats; B completed |
| 3,506–3,518 | AR, R | `0x123460000` | Six read beats |

Firmware reported PASS at `mcycle=4379`; the runner recorded one pass marker,
no fail markers, no error/fatal diagnostics, and no unexpected JTAG errors.
The run used a single-vector firmware copy, fast TRNG cadence, PQ-vector
suppression, and Icarus source `ac4532fab037e91df2f903e67fb40f59baedccca`
(`ac4532fa-dirty`). This remains diagnostic only; a clean published Icarus
replay and the full suite are open. See
[`sixth-aes-result.json`](sixth-aes-result.json) and
[`sixth-aes-axi-wstate.log`](sixth-aes-axi-wstate.log).

## Seventh AES/DMA vector — 2026-10-08

The seventh vector passed in isolation with the checker enabled
(`--limit-aes-cases 1 --start-aes-case 6`). It exercised seven-beat source
transfers and split the destination into four- and three-beat writes:

| Cycle | Channel | Address | Result |
| ---: | --- | --- | --- |
| 1,565–1,574 | AW, W, B | `0x123440000` | Seven W beats; B completed |
| 3,138–3,152 | AR, R | `0x123440000` | Seven read beats |
| 3,280–3,286 | AW, W, B | `0x123460000` | Four W beats; B completed |
| 3,349–3,354 | AW, W, B | `0x123460010` | Three W beats; B completed |
| 3,503–3,517 | AR, R | `0x123460000` | Seven read beats |

Firmware reported PASS at `mcycle=4430`; the runner recorded one pass marker,
no fail markers, no error/fatal diagnostics, and no unexpected JTAG errors.
The run used a single-vector firmware copy, fast TRNG cadence, PQ-vector
suppression, and Icarus source `ac4532fab037e91df2f903e67fb40f59baedccca`
(`ac4532fa-dirty`). This remains diagnostic only; a clean published Icarus
replay and the full suite are open. See
[`seventh-aes-result.json`](seventh-aes-result.json) and
[`seventh-aes-axi-wstate.log`](seventh-aes-axi-wstate.log).

## Eighth AES/DMA vector — 2026-10-08

The eighth vector passed in isolation with the checker enabled
(`--limit-aes-cases 1 --start-aes-case 7`). It exercised eight-beat source
transfers and two four-beat destination writes:

| Cycle | Channel | Address | Result |
| ---: | --- | --- | --- |
| 1,718–1,728 | AW, W, B | `0x123440000` | Eight W beats; B completed |
| 3,285–3,301 | AR, R | `0x123440000` | Eight read beats |
| 3,379–3,385 | AW, W, B | `0x123460000` | Four W beats; B completed |
| 3,451–3,457 | AW, W, B | `0x123460010` | Four W beats; B completed |
| 3,594–3,610 | AR, R | `0x123460000` | Eight read beats |

Firmware reported PASS at `mcycle=4566`; the runner recorded one pass marker,
no fail markers, no error/fatal diagnostics, and no unexpected JTAG errors.
The run used a single-vector firmware copy, fast TRNG cadence, PQ-vector
suppression, and Icarus source `ac4532fab037e91df2f903e67fb40f59baedccca`
(`ac4532fa-dirty`). This remains diagnostic only; a clean published Icarus
replay and the full suite are open. See
[`eighth-aes-result.json`](eighth-aes-result.json) and
[`eighth-aes-axi-wstate.log`](eighth-aes-axi-wstate.log).

## Ninth AES/DMA vector — 2026-10-08

The ninth vector passed in isolation with the checker enabled
(`--limit-aes-cases 1 --start-aes-case 8`). It exercised nine-beat source
transfers and split the destination into four-, four-, and one-beat writes:

| Cycle | Channel | Address | Result |
| ---: | --- | --- | --- |
| 1,730–1,741 | AW, W, B | `0x123440000` | Nine W beats; B completed |
| 3,309–3,327 | AR, R | `0x123440000` | Nine read beats |
| 3,403–3,409 | AW, W, B | `0x123460000` | Four W beats; B completed |
| 3,523–3,529 | AW, W, B | `0x123460010` | Four W beats; B completed |
| 3,588–3,591 | AW, W, B | `0x123460020` | One W beat; B completed |
| 3,730–3,748 | AR, R | `0x123460000` | Nine read beats |

Firmware reported PASS at `mcycle=4687`; the runner recorded one pass marker,
no fail markers, no error/fatal diagnostics, and no unexpected JTAG errors.
The run used a single-vector firmware copy, fast TRNG cadence, PQ-vector
suppression, and Icarus source `ac4532fab037e91df2f903e67fb40f59baedccca`
(`ac4532fa-dirty`). This remains diagnostic only; a clean published Icarus
replay and the full suite are open. See
[`ninth-aes-result.json`](ninth-aes-result.json) and
[`ninth-aes-axi-wstate.log`](ninth-aes-axi-wstate.log).

## Tenth AES/DMA vector — 2026-10-08

The tenth vector passed in isolation with the checker enabled
(`--limit-aes-cases 1 --start-aes-case 9`). It exercised ten-beat source
transfers and split the destination into four-, four-, and two-beat writes:

| Cycle | Channel | Address | Result |
| ---: | --- | --- | --- |
| 1,833–1,845 | AW, W, B | `0x123440000` | Ten W beats; B completed |
| 3,412–3,432 | AR, R | `0x123440000` | Ten read beats |
| 3,506–3,512 | AW, W, B | `0x123460000` | Four W beats; B completed |
| 3,626–3,632 | AW, W, B | `0x123460010` | Four W beats; B completed |
| 3,693–3,697 | AW, W, B | `0x123460020` | Two W beats; B completed |
| 3,833–3,853 | AR, R | `0x123460000` | Ten read beats |

Firmware reported PASS at `mcycle=4847`; the runner recorded one pass marker,
no fail markers, no error/fatal diagnostics, and no unexpected JTAG errors.
The run used a single-vector firmware copy, fast TRNG cadence, PQ-vector
suppression, and Icarus source `ac4532fab037e91df2f903e67fb40f59baedccca`
(`ac4532fa-dirty`). This remains diagnostic only; a clean published Icarus
replay and the full suite are open. See
[`tenth-aes-result.json`](tenth-aes-result.json) and
[`tenth-aes-axi-wstate.log`](tenth-aes-axi-wstate.log).
