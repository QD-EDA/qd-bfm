# Adams Bridge rows 58, 61, 65 — supported cycle-limit rerun

The previous runs reached the benches' default 200,000-cycle limit before a testcase verdict. Both benches explicitly support the `+MAX_CYCLES=<value>` plusarg (`sample_in_ball_tb.sv:38–44`, `abr_sha3_tb.sv:53–60`). This rerun passes `+MAX_CYCLES=10000000` through the existing M15 manifest for rows 58, 61, and 65; RTL, testbench sources, stimulus, expected values, assertions, and pass criteria stay unchanged.

The source snapshot SHA-256 is `0237a23e43cba95e136fc20410faf997784cf163f449840dddddc7b3241efaab`. Each task requests one CPU / 4 GiB and a 3,600-second runner cap, with at most two array tasks running. The pinned inputs are Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus `cae035642e056644274a01e98d4422ce286685b4` with the M20 binary hashes recorded in the run script.

No row classification changes until each terminal result, testcase marker, and archive sidecar is verified.

Submitted as array 3288 with dependency `afterany:3286`, so these three long-cap tasks wait for the current row-4 gate. The array throttle is two tasks; no scheduler polling is being performed. Submission and input hashes are in `submission.txt`.
