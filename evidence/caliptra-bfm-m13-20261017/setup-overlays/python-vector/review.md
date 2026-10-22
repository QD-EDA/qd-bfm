# Overlay result adjudication

The 2267 archive preserves the raw job output. Its runner's failure-marker
pattern did not include the testbench's `Error: Output mismatch` lines, so the
generated `result.txt` incorrectly calls `sigencode_z_tb` `BLOCKED_SETUP`.
Directly counting the archived complete log gives 3,072 mismatches, all with
`Got: xxxxx`; the row is **FAIL**. The runner pattern is corrected locally for
future rows. No simulator or source result was changed.

The 3,072 mismatches split evenly across the testbench's two `sigencode_z_test`
calls: 1,536 mismatches per call, from index 256 through 1791. In the pinned
testbench, `NUM_OF_COEFF = MLDSA_N * MLDSA_L` is 1,792, but each top-level call
processes one MLDSA_N polynomial: `sigencode_z_top` sets `THE_LAST_ADDR` to
`MLDSA_N/4 - 1` (63), with four coefficient lanes per memory address. The
testbench invokes the top twice and compares all 1,792 coefficients each time.
It therefore expects seven polynomial blocks from each one-block invocation.
This is a testbench/RTL-use mismatch, not a current-main simulator defect.

The minimal packed-struct reproducer for the already closed issue #539 was run
on current main 9b5fad2. It passed: `bad=4002 bad_en=01`, matching the explicit
width control. See
[`../../simulator-defects/issue539-current-main/`](../../simulator-defects/issue539-current-main/).
The c339 baseline's all-X result and the current-main partial output are
consistent with #539 being fixed on current main; no duplicate issue was filed.

`rej_bounded_tb` is a functional **FAIL** with generated inputs: the complete
log contains `*** 08 errors detected during testing.` and `* TESTCASE FAILED`,
after eight queue-underflow reports. The c339 follow-up traced the same failure
to the generator streaming the remainder of a full 136-byte SHAKE block after
the expected 256 coefficients. It is not a simulator defect.

`power2round_tb` is a valid **PASS** with the setup overlay: its generator wrote
all three required nonempty vectors, the log reports 2,048 completed cases, and
the simulation emits exactly one pass marker with no failure marker.

Intern's triage drafts are kept separately; the classifications above were
checked against the logs, generated files, pinned testbench, and current-main
reproducer result.
