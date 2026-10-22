# Entropy source zero-count marker check

The pinned-only log prints `*** All 00 test cases completed successfully.` The
testbench initializes `tc_ctr` to zero and never increments it, but it does
call `run_hw_if_test()` once, which compares the 128-bit response with four
32-bit words accumulated from the physical RNG stream. A run-local diagnostic
adds queue-size displays around that existing comparison loop; it does not
change stimulus, timing, or comparisons.

Job 2285 used current Icarus main with a 600-second cap. It reported
`vector_count_before=12 expected_words=12` and `vector_count_after=0`, with
compile and simulation exit 0, one testcase pass marker, and no mismatches.
The diagnostic-only overlay, source diff, logs, hashes, versions, and resource
records are in [`entropy-src-check-2285.tgz`](entropy-src-check-2285.tgz); its
archive SHA-256 is recorded in the adjacent `.sha256` file.
