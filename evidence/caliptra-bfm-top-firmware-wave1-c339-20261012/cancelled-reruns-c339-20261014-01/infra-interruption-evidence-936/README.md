# Array 936 interrupted by DAN-DESKTOP host restart

Job 936 started at 00:12 MDT on 2026-10-14. All four simulators wrote 16 heartbeats through `wall_s=4500`; final mcycles were 34,321 (task 1, source row 37), 34,174 (task 2, source row 39), 34,274 (task 3, source row 43), and 34,266 (task 4, source row 44). Their simulator logs all stopped at 01:27:54–55 MDT. Each task has an empty `resource.log` and `runner.log`, no `status.txt`, no `result.json`, and no testcase PASS/FAIL marker.

At 07:31 MDT, DAN-DESKTOP had been up 3 minutes, jobs 936_1–4 and 799_37/38 were absent from `squeue`, no Icarus/VVP processes remained, and `sacct` reported accounting storage disabled. The jobs therefore lost their host before the runner could record completion. This is **INFRA-INTERRUPTED**, not PASS, FAIL, TIMEOUT, or a test hang. The log evidence does not show repeated heartbeat mcycles; the common stop across all four rows with a host restart does not justify filing a simulator reproducer.

The four partial output trees occupied 1,502,851,877 bytes. The selected run metadata, partial simulator/build logs, and Slurm wrapper outputs are under `runs/` and `logs/`; every file matches its `REMOTE-SHA256SUMS-task936_N.txt` manifest. The remote output trees remain pending cleanup after this evidence is committed. The next fresh array attempt will have its own run directory and ledger.
