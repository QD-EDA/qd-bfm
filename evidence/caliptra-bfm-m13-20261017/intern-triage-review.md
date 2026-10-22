# M13 log triage review

The first combined intern request exceeded its 150,000-character input limit and cross-attributed lines between rows. Its output is retained as `intern-triage-unverified-20261017.txt` for audit only and is not used for classifications. I reran the longest relevant rows in smaller labeled batches and checked each claim against the Slurm logs.

| Environment | Verified current-main classification | Direct evidence |
|---|---|---|
| `adams-bridge-v2-0-3-cbd_sampler_tb` | FAIL | Ten queue-underflow reports; `*** 10 errors detected during testing.` and `* TESTCASE FAILED`. The c339 follow-up traced this to the generator/testbench 256-coefficient boundary. |
| `adams-bridge-v2-0-3-butterfly_top_tb` | BLOCKED/setup | Four required `kyber_*.txt`/`.hex` inputs cannot be opened; the log only says the NTT/INTT operations succeeded and finishes without a testcase pass marker. |
| `adams-bridge-v2-0-3-ntt_top_tb` | BLOCKED/setup | `ntt_unmasked_input.hex` cannot be opened; the test reaches `$finish` without a testcase pass marker. |
| `adams-bridge-v2-0-3-rej_bounded_tb` | BLOCKED/setup | Generator reports `python: not found`; `exp_results.txt` and `input_vectors.txt` are absent, and the run hits the max-cycle guard. This run does not establish functional failure. |
| `adams-bridge-v2-0-3-sigencode_z_tb` | BLOCKED/setup | Generator reports `No module named 'numpy'`; `input_z.hex` and `output_encoded_z.hex` are absent; no testcase marker is emitted. |
| `caliptra-v2-1-2-ecc_montgomerymultiplier_tb` | BLOCKED/setup | The required Montgomery vector file cannot be opened and the log says `Read 0 test vectors`; the subsequent pass marker is vacuous. |
| `caliptra-v2-1-2-entropy_src_tb` | PASS | The `00` count is a testbench counter bug: `tc_ctr` is initialized but never incremented, while `run_hw_if_test()` runs once and compares the response. Diagnostic-only job 2285 confirms 12 queued words before the loop, 12 expected comparisons, 0 remaining afterward, no mismatches, and `* TESTCASE PASSED`. |
| `adams-bridge-v2-0-3-power2round_tb` | BLOCKED/setup | Python is unavailable and all three coefficient vector files fail to open; the later `2048 test cases completed successfully` marker is not valid evidence without those inputs. |
| `caliptra-v2-1-2-soc_ifc_axi_sha_acc_dis_tb` | PASS | The log has undefined-dynamic-array warnings but also reports `SHA status read over AXI = 00000002` three times and emits `* TESTCASE PASSED`; source review confirms readback checks for lock, mode, data length, data-in, and execute. |
| `adams-bridge-v2-0-3-norm_check_tb` (width overlay) | PASS | The log reports successful Z and R0 bound checks, the intended rejection cases, and `Ctrl test done`. |
| `adams-bridge-v2-0-3-skdecode_tb` (width overlay) | PASS | The log reports all three unpack checks, `*** All test cases completed successfully.`, and `* TESTCASE PASSED`. The intern initially misread `invalid s1 is detected` as failure; source lines 435–440 show that this is the success branch, while absence of detection prints `Error:` and increments the error count. |
| `adams-bridge-v2-0-3-decompose_tb` (width and stale-port overlay) | PASS | The log reports `Decompose success` and `Decompose + usehint success`, with compile and simulation exit 0. |
| `adams-bridge-v2-0-3-ntt_masked_mult_reduction_tb` | PASS | The testbench defines `NUM_OF_TEST_VECTOR = 1000000`, prints a mismatch for every failed comparison, and calls `$stop` after that count. The current-main run reached interval `999999`, had zero `Mismatch at cycle` lines, and exited 0; the test has no explicit pass marker. |

