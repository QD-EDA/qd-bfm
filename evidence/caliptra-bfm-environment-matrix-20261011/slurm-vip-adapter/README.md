# Caliptra AXI adapter matrix validation

Array 464 is the first run of the two missing-VIP matrix rows using the QD AXI checker through the compatibility adapter. The pinned Caliptra source declares `caliptra_top_tb` as the real simulator top for both filelists; the build-target names remain in the row IDs only. See `top-audit.txt`.

The run uses Icarus c339 (`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`), Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and QD-BFM adapter/checker from commit `3c41c09eca43ed31506013ca70973b99388421aa`. It appends the checker module source to each copied filelist and points `CALIPTRA_AXI4PC_DIR` at the committed `Axi4PC.sv` adapter.

Job 464 used one CPU, 3 GiB, and two hours per task; array throttle was two, and each test had a 6,900-second timeout. The immutable remote run directory is `/home/dsell/slurm-runs/caliptra-bfm/a2/vip-adapter-c339-20261011-01`.

Both compile steps exited 1 with 46 Icarus mixed-driver errors in `caliptra_top_tb_axi_complex.sv`, where continuously assigned AXI interface variables are procedurally forced/released by the delay-injection macro. Each compile also reports `always process does not have any delay` for the clock generator's `#5ns` intra-assignment delay. The original `Axi4PC.sv` syntax failure is gone, but neither simulation ran. The matrix rows remain BLOCKED on these specific simulator/testbench compile incompatibilities. The evidence includes full compile logs, timing/resource records, original and modified filelist hashes, tool hashes/versions, and source revisions.
