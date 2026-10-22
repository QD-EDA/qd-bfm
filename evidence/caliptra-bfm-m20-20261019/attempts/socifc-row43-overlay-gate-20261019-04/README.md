# SoC-IFC row 43 overlay gate, retry 4

Fresh one-row gate after terminal BLOCKED compile evidence from jobs 3233 and 3237. This retry supplied explicit `void` returns for `create_seqs` and `randomize_seqs` in the generated multi-agent sequence, in addition to the earlier selector and coverage compatibility changes.

Pinned source/compiler unchanged. Resources: 1 CPU / 2 GiB; runner timeout 1,800 seconds; Slurm limit 2,100 seconds.

Terminal result: BLOCKED during compile before simulation, now at the same missing-return-type pattern in `soc_ifc_env_mbox_rst_sequence.svh:87` (`function soc_ifc_env_mbox_rst_sequence::create_seqs()`). Archive `raw/job-3239_43.tar.gz` SHA-256: `4615bde16c41f1536491b7e9404b70efa6bfec8afd971b73c123097cc7b0a300`. The source tree contains this pattern across the generated sequence package, so the next overlay applies the explicit-`void` compatibility fix to all `create_seqs`, `randomize_seqs`, and `create_and_randomize_seqs` declarations and definitions. No return statements or consumed return values were found for those methods. Host/tool hashes and the 129 MiB peak-RSS report are in `raw/job-3239_43.job-meta.txt` and `raw/job-3239_43.runner.resource`.
