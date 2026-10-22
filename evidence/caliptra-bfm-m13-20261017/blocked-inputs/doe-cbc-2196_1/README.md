# DOE CBC row blocked by missing vector

Array task `2196_1` ran for 1:17:59 without a terminal testcase result. The
staged runtime does not contain `CBCVarTxt256_clean.txt`, while the pinned
testbench opens that vector from a hard-coded path in `/home/t-stevenlian` and
does not check whether `$fopen` succeeded. The run therefore had no valid
input for its KAT loop. I canceled this task before its 6,900-second timeout;
it is recorded as `BLOCKED_SETUP`, not a firmware FAIL or TIMEOUT.

The pre-cancel state, raw logs, compile/provenance files, and source/tool
hashes are preserved here. Archive SHA-256:
`e582c625d11e062c96f56695322e5ab121c7d01cab11f3647b3db8095748e575`.
