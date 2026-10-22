# First-fuse-write diagnostic, job 1812

Host: `DAN-DESKTOP`. This was the single selected row `smoke_test_ahb_mux` (`cadf43c78de6a454`), built with assertions enabled. Slurm allocated 1 CPU and 3 GiB; the wrapper applied a 600-second outer cap. The job completed in 5.162 seconds, with 55,420 KiB maximum RSS.

Outcome: **PASS**. `sim_exit=0`; `sim.log` contains `* TESTCASE PASSED` and `Finished : minstret = 582, mcycle = 3973`. The c339 baseline for this row is also `PASS`, `mcycle=3973`; its wall time is unavailable in the input matrix, so no speedup is claimed.

Model SHA-256: `998ce756bf9e819f473ed79acc559e036e5e69824b33cf3f03da3b770aa30228`. The traced AW/W/B overlay SHA-256 is `4c54c0366614692d8bfaaa46f07f6015e431fb579b1aecbd0aea18b620e91da1`.

The first fuse-bank write is AW address `0x30200`. The edge-sample trace captures AW valid/ready, then W valid/ready, and BVALID/BREADY together at realtime 3.95; the trace logs `M10B_AW_W_B_TRACE_B_HANDSHAKE`. The firmware then continues to a PASS result. Realtime advances in 0.10 ns steps in this corrected run. The earlier failing rows localized the defect to Verilator scheduling of the BFM's post-edge ready/valid sampling; this passing trace confirms the fix clears the first write. By itself, the corrected trace does not prove whether the original hang was a zero-delay loop. The overlay now drives write channels nonblocking and samples AWREADY, WREADY, and BVALID with `#1step` clocking inputs at the edge.

The archive preserves `result.json`, `sim.log`, `firmware.log`, resource reports, per-file checksums, and the Slurm output. Archive SHA-256: `3e0a5f50de8d32e52e049f72766e411e69684073fc56073ebd7aeeb5d31232a2`.
