# Adams Bridge abr_sha3 stale-port one-row gate

Row 61 gates a testbench-only compatibility overlay that removes the obsolete `.done_i` connection from the pinned `abr_sha3_tb`; the current DUT has no such port and the signal has no other readers. The helper refuses a source SHA mismatch. No RTL, stimulus, expected value, or pass criteria changes.

Icarus pin `cae035642e056644274a01e98d4422ce286685b4`; 1 CPU, 1 GiB (row58 measured 26,804 KiB peak RSS), 600-second timeout. Source snapshot SHA-256: `6f002baf8784326f77919af14b7bbc7c22b13d47d8a2508e094209fef6b14aec`. INVALID SELECTION: job 3064 inherited row selector 58 from the gate template, as confirmed by the archived result.json. Row 58 was not reused as matrix evidence; its official M18 result remains in the earlier row58 gate. Invalid archive SHA-256: `544857b7fde2601135f9a79490a92f63ab47aa3a8bba01a048853bebc035a905` (verified against the adjacent sidecar).
