# AXI manager WRAP and narrow-transfer regression — 2026-10-09

The guarded `dv/caliptra_bfm/axi/tests/run_master.sh` regression passed on QD
commit `c44e132dd91ca23c3791ce7a5bb6b9f7a257e66b` with clean published Icarus
`main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`.

The simulator source checkout was clean, `origin/main` contained the build
commit, and a live `git ls-remote` check returned the same `main` SHA. The
captured version and executable hashes are in `iverilog-version.txt` and
`simulator-sha256.txt`.

The added manager case verifies write/read address wrap for all legal WRAP
lengths (2, 4, 8, and 16 beats), including per-beat data, USER, and OKAY
responses. It also sends a two-beat, two-byte INCR write at byte address
`0x42`, checks the lane strobes and readback, and confirms neighboring bytes
remain intact. Three-beat WRAP and a misaligned two-byte transfer are rejected
before the manager asserts request VALID.

The same run also passed the existing USER/LOCK, stalls, errors, reset abort,
W-before-AW, concurrent read/write, out-of-order read/write response, and
fail-stop checks. Its requested resources were 1 GiB and 1 CPU; `/usr/bin/time`
reported 17,576 KiB maximum RSS and 0.28 seconds elapsed.

`job.sbatch`, `source-commits.txt`, runner output, and the resource record are
retained here. This is manager-level protocol regression evidence for the
aligned Caliptra profile; unaligned requests and full AXI production
qualification remain outside this result.
