# SoC-IFC row 43 overlay gate, retry 3

Fresh one-row gate for soc_ifc_trng_test with the revised overlay. Retry 2 ended before the simulation harness because the staged source archive had been unpacked into the run root instead of its required source/ subdirectory; its local log, metadata, and resource report are preserved under raw/ and do not represent a test result.

The revised overlay redirects the two generated mailbox invalid-access sequence selectors through local strings, preserving case labels and behavior. Pinned sources and c339 compiler are unchanged. Resources: 1 CPU / 2 GiB; 1,800-second runner timeout; 2,100-second Slurm limit.

Terminal result: BLOCKED during compile at `randomize_seqs` in `soc_ifc_env_mbox_rand_multi_agent_sequence.svh:213`. Archive `raw/job-3237_43.tar.gz` SHA-256: `a39e15ec45abc5a5d753b62c8dc4779869fdbaf2cf1899cf828cf42118842f27`. The first overlay added a return type only to the `create_seqs` definition. The next overlay also adds explicit `void` returns to both `create_seqs` and `randomize_seqs` declarations and definitions. This gate did not reach simulation.
