# Row 59 overlay gate (job 2685)

The testbench width overlay plus the `abr_libs/rtl` include path compiled and simulated successfully (both exits 0, 11.161 s, no timeout). The then-current runner classified the row **BLOCKED** because it did not recognize the testbench's `Ctrl test done` completion marker. The log contains the expected successful checks and rejection checks with no `ERROR:` lines. This is retained as the classifier-gap attempt; job 2686 is the fresh gate after correcting classification.

The overlay changes the three undefined `MLDSA_MEM_ADDR_WIDTH` references to the package-exported `ABR_MEM_ADDR_WIDTH`; it touches only the testbench and its filelist. Pinned inputs and compiler are the same as job 2683. Remote hashes for every captured file are in `raw/SHA256SUMS.remote.txt`; all verified before cleanup.
