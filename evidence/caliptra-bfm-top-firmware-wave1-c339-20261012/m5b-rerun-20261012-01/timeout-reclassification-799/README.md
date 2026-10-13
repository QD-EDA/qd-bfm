# Job 799 timeout reclassification

The submitted wrapper labeled Slurm tasks 1–11 `INFRA_ERROR` because VVP was
terminated with exit 137. For every task, the measured elapsed time equals its
configured per-test timeout exactly, so the terminal outcome is `TIMEOUT`.
Each task requested 3 GiB and peaked at about 1.85 GiB RSS; the logs do not
indicate memory pressure. The full heartbeat sequences contain no repeated
mcycle values at adjacent 300-second samples, so none meets the 30-minute
flat-mcycle hang criterion.

`results.tsv` records the corrected outcome and final mcycle. The raw
`status.txt` and `resource.log` are retained for every row. Row 7 also includes
its provenance, tool versions, Slurm output, and build/simulation logs. The
wrapper's original status is unchanged.

Task 7's resource report records `2:07:08` (7,628 seconds), exactly matching
its configured timeout. Its last heartbeat is `wall_s=7500 mcycle=51400`; the
full sequence advances at every 300-second sample, and no testcase PASS/FAIL
marker or result JSON exists. It is a timeout, not a hang.

Task 8's resource report records `2:12:36` (7,956 seconds), exactly matching
its configured timeout. Its last heartbeat is `wall_s=7800 mcycle=54368`; the
full sequence advances at every 300-second sample, and no testcase PASS/FAIL
marker or result JSON exists. It is a timeout, not a hang.

Task 9's resource report records `2:27:56` (8,876 seconds), exactly matching
its configured timeout. Its last heartbeat is `wall_s=8700 mcycle=59294`; the
full sequence advances at every 300-second sample, and no testcase PASS/FAIL
marker or result JSON exists. It is a timeout, not a hang.

Task 10 (`smoke_test_hek_flow`) records `2:37:47` (9,467 seconds), exactly
matching its configured timeout. Its last heartbeat is `wall_s=9300 mcycle=63131`;
the 30 anchored heartbeat records and two additional simulator-prefixed
heartbeat lines all advance mcycle. No testcase PASS/FAIL marker or result JSON
exists, so it is a timeout, not a hang.

Task 11 (`smoke_test_dma_aes_gcm_non_gcm_en_dec`) records `2:48:11` (10,091
seconds), exactly matching its configured timeout. Its last heartbeat is
`wall_s=9900 mcycle=67671`; all 31 anchored heartbeats and the later
simulator-prefixed records advance mcycle. No testcase PASS/FAIL marker or
result JSON exists, so this is a timeout, not a hang. The wrapper status and
raw resource report are preserved under `runs/15-ea3af7f88b5170c5-11/`.

Task 12 (`c_intr_handler`) records `3:00:13` (10,813 seconds), exactly
matching its configured timeout. Its last heartbeat is
`wall_s=10500 mcycle=73262`; all 35 anchored heartbeats and the later
simulator-prefixed record advance mcycle. No testcase PASS/FAIL marker or
result JSON exists, so this is a timeout, not a hang. The wrapper status and
raw resource report are preserved under `runs/17-32a51e049923c576-12/`.

Task 13 (`smoke_test_mbox_byte_read`) records 10,846 seconds, exactly its
configured per-test cap. The wrapper left `INFRA_ERROR` in `status.txt`, but
`resource.log` confirms the exact cap and runner exit 137, so the corrected
outcome is TIMEOUT. Its last heartbeat is `wall_s=10800 mcycle=74961`; all
36 anchored heartbeats have distinct adjacent mcycle values, with no PASS/FAIL
marker or result JSON. The copied raw status, resource, simulator, and
provenance artifacts are under `runs/19-40a2264a41561d60-13/`; their remote
SHA-256 values are in `REMOTE-SHA256SUMS-task13.txt`.

Task 14 (`smoke_test_dma_aes_gcm_collision_test`) ran for 11,010 seconds,
exactly its configured cap; runner exit 137 and the wrapper's INFRA_ERROR are
therefore corrected to TIMEOUT. `resource.log` reports maximum RSS 1,852,448
KiB. The last heartbeat in the full simulator log is
`wall_s=10800 mcycle=75743`, with no testcase terminal marker or result JSON.
The wrapper status's `last_heartbeat` field is older at wall 10,200; the
simulator log contains the later sample. Its copied evidence is under
`runs/20-0627acabfee6876c-14/`, with original remote hashes in
`REMOTE-SHA256SUMS-task14.txt`.

Task 15 (`smoke_test_dma_aes_gcm_short_dword`) records 11,240 seconds,
exactly its configured cap. Its wrapper outcome `INFRA_ERROR` is corrected to
TIMEOUT from elapsed time and runner exit 137. The last heartbeat was
`wall_s=11100 mcycle=78702`; no testcase PASS/FAIL marker or result JSON exists.
The full log has no repeated adjacent mcycle sample. Maximum RSS was 1,852,384
KiB. Raw evidence and the copied task output are in
`runs/21-c95f8624d4cb7fe0-15/`, with hashes in `REMOTE-SHA256SUMS-task15.txt`.

Task 16 (`smoke_test_kv_securitystate`) records 11,240 seconds, exactly its
configured cap; runner exit 137 and wrapper outcome `INFRA_ERROR` are corrected
to TIMEOUT. Its final simulator-log heartbeat is `wall_s=11100 mcycle=19222`,
with no repeated adjacent mcycle sample, result JSON, or testcase PASS/FAIL
marker. Maximum RSS was 1,852,360 KiB. The wrapper status and full log are in
`runs/22-871bf14a358781fb-16/`, with original hashes in
`REMOTE-SHA256SUMS-task16.txt`.

Task 17 (`smoke_test_datavault_lock`) records 11,601 seconds, exactly its
configured cap; runner exit 137 and wrapper outcome `INFRA_ERROR` are corrected
to TIMEOUT. The wrapper status ends at wall 7,500/mcycle 53,013, but the full
simulator log contains later heartbeats through `wall_s=11400 mcycle=81461`.
The full log has no repeated adjacent mcycle values, result JSON, or testcase
terminal marker. Maximum RSS was 1,852,436 KiB. The raw status, resource,
simulator, and provenance files are in `runs/23-40ec556410264b2f-17/`, with
their remote hashes in `REMOTE-SHA256SUMS-task17.txt`.

Task 18 (`smoke_test_datavault_mini`) records 12,257 seconds, exactly its
configured cap; runner exit 137 and wrapper outcome `INFRA_ERROR` are corrected
to TIMEOUT. The wrapper reports 29 heartbeats; the full simulator log contains
41 samples through `wall_s=12000 mcycle=85975`. All samples advance, so there is
no 30-minute flat interval. No result JSON or testcase terminal marker is
present. Maximum RSS was 1,852,408 KiB. The raw status, resource, simulator,
firmware, console, and provenance files are in
`runs/24-483ee327507dab77-18/`, with their remote hashes in
`REMOTE-SHA256SUMS-task18.txt`.

Task 19 (`smoke_test_aes_gcm`) records 13,210 seconds, exactly its configured
cap; runner exit 137 and wrapper outcome `INFRA_ERROR` are corrected to
TIMEOUT. The wrapper reports 39 heartbeats; the full simulator log contains 44
samples through `wall_s=12900 mcycle=91549`. All samples advance, so there is
no 30-minute flat interval. No result JSON or testcase terminal marker is
present. Maximum RSS was 1,852,480 KiB. The raw status, resource, simulator,
firmware, console, and provenance files are in
`runs/25-6bccff716e6bcab5-19/`, with their remote hashes in
`REMOTE-SHA256SUMS-task19.txt`.

Task 20 (`smoke_test_dma_aes_gcm_short_1_dword`) records 13,341 seconds,
exactly its configured cap; runner exit 137 and wrapper outcome `INFRA_ERROR`
are corrected to TIMEOUT. The wrapper reports 36 heartbeats; the full log has
45 samples through `wall_s=13200 mcycle=93689`, all advancing. It includes an
internal `Test 1 PASSED` line but no row-level `* TESTCASE PASSED` marker or
result JSON. The runner only records a row PASS after a normal simulator exit
and its testcase-marker checks; this capped run is TIMEOUT. Maximum RSS was
1,852,436 KiB. Raw status, resource, simulator, firmware, console, and
provenance files are in `runs/26-ca84d5f757b500b2-20/`, with remote hashes in
`REMOTE-SHA256SUMS-task20.txt`.

Task 21 (`jtag_tap_mbox`) records 15,212 seconds, exactly its configured
per-test timeout; runner exit 137 and wrapper outcome `INFRA_ERROR` are corrected
to TIMEOUT. The full simulator log contains 50 heartbeats through
`wall_s=15000 mcycle=108152`, with no adjacent repeated mcycle sample. No
testcase PASS/FAIL marker or result JSON exists. Maximum RSS was 1,852,512 KiB.
The copied status, resource, simulator, firmware, console, and provenance files
are in `runs/29-3439695c6637d6f2-21/`, with remote hashes in
`REMOTE-SHA256SUMS-task21.txt`.

Task 22 (`iccm_lock`) records 15,639 seconds, exactly its configured
per-test timeout; the resource report also records 4:20:39 and runner exit 137.
The wrapper's `INFRA_ERROR` is corrected to TIMEOUT. Its status reports 47
heartbeats; the full simulator log has 53 samples through
`wall_s=15600 mcycle=33461`, all advancing. No testcase PASS/FAIL marker or
result JSON exists. Maximum RSS was 1,852,468 KiB. The copied status, resource,
simulator, firmware, console, and provenance files are in
`runs/30-35735b41cd07eed7-22/`, with remote hashes in
`REMOTE-SHA256SUMS-task22.txt`.

Task 23 (`smoke_test_ecc_keygen`) records 16,033 seconds, exactly its
configured per-test timeout; resource wall time is 4:27:13 and runner exit is
137. The wrapper's `INFRA_ERROR` is corrected to TIMEOUT. Status and full log
both report 54 heartbeats through `wall_s=15900 mcycle=115112`; all adjacent
mcycle values advance. No testcase PASS/FAIL marker or result JSON exists.
Maximum RSS was 1,852,344 KiB. Its copied run logs and provenance are under
`runs/32-2f1b875490838662-23/`, with remote hashes in
`REMOTE-SHA256SUMS-task23.txt`.

Task 24 (`smoke_test_ecc_sign`) records 16,033 seconds, exactly its
configured per-test cap; resource wall time is 4:27:13 and runner exit is 137.
The wrapper's `INFRA_ERROR` is corrected to TIMEOUT. Status and full log contain
54 heartbeats through `wall_s=15900 mcycle=115159`, all advancing. No testcase
PASS/FAIL marker or result JSON exists. Maximum RSS was 1,852,444 KiB. Its copied
run logs and provenance are under `runs/33-ba452156bdfcaf3a-24/`, with remote
hashes in `REMOTE-SHA256SUMS-task24.txt`.
