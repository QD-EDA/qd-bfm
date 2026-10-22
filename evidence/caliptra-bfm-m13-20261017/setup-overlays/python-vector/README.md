# Python-generated vector reruns

The one-row `power2round_tb` gate passed with the protected Python 3.14.4 +
NumPy 2.5.4 environment. This array uses that same immutable environment to
rerun the two rows whose M13 pinned-only simulations did not have generated
inputs: `rej_bounded_tb` (missing Python and its two files) and `sigencode_z_tb`
(missing NumPy and its input/output files).

These are fresh overlay results on the exact M13 current-main Icarus SHA and
pinned firmware sources. Each row gets 1 CPU, 3 GiB, and a 600-second compile
and simulation cap. The array throttle is 2. A row qualifies as PASS only when
the required nonempty vectors exist, simulation exits zero, exactly one pass
marker is present, and no failure marker is reported. Job 2267 completed both
rows; the verified raw archive is
[`python-vector-overlay-2267.tgz`](python-vector-overlay-2267.tgz), SHA-256
`45beed64243a46830c22bd4a6b9cec3afeeb21889a67de53e02e66d9ff2344fa`.

- `rej_bounded_tb`: **FAIL**. Vectors were present and compile/simulation
  exited zero, but the test reported 10 cases with 8 “Not enough valid samples
  in the queue” notices and `*** 08 errors detected during testing.` The
  [adjudication](review.md) records the generator-boundary cause from the c339
  follow-up.
- `sigencode_z_tb`: **FAIL**. The log has 3,072 output mismatches, all `Got:
  xxxxx`, split into two 1,536-row calls over indices 256–1791. The archived
  `result.txt` says `BLOCKED_SETUP` because that runner revision did not treat
  `Error: Output mismatch` as a failure marker; direct log review establishes
  the failure. The local runner pattern now includes that marker. The
  [adjudication](review.md) explains the one-polynomial versus seven-polynomial
  testbench/RTL-use mismatch.
