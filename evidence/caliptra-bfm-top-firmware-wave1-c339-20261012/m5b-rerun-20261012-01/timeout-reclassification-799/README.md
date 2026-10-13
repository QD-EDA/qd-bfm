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
