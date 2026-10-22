# M15 pilot array 2366

- 56 rows, array concurrency 6, one CPU and 3 GiB per row, two-hour Slurm cap, one-hour runner timeout.
- Runner code is commit `0aea6ebe`; Caliptra and Adams Bridge pins and per-filelist hashes are recorded in each result JSON. Icarus source pin and binary hash are recorded per row.
- Outcomes: 2 PASS, 54 BLOCKED. `row-11 hmac_normal_test` and `row-39 soc_ifc_axi_sha_acc_dis_tb` passed.
- 21 SoC-IFC component rows were blocked at the malformed associative-array initializer in `src/soc_ifc/tb/soc_ifc_tb_pkg.sv:116`; a minimal comparison reproducer is in `diagnostics/`. Both Icarus 13 and Verilator 5.032 reject the bare-brace initializer and accept the standard apostrophe assignment pattern, so this is a testbench syntax compatibility issue, not an Icarus defect.
- 33 generated-UVMF rows were blocked before elaboration at `/src/uvm_pkg.sv: No such file or directory`. Their pinned `.vf` files refer to `UVM_HOME`, `UVMF_HOME`, `QUESTA_MVC_HOME`, and (for SoC-IFC) Avery source roots; the runner did not supply these roots in this attempt.
- All 56 result JSONs, exact commands, resource records, compile/run logs, and Slurm task logs are preserved. The row table is `results.tsv`. Build images and copied runtime source trees were excluded from evidence.
