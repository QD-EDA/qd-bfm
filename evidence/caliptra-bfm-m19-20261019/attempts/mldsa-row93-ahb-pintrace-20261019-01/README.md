# Corrected row 93 full-clock AHB pin trace

The first conditional trace attempt was not submitted because row 97 showed the address/select trigger matched no runtime cycles. This staged follow-up uses the corrected full-clock observer proven by the row 97 full-clock gate: it records pre/post AHB select, transfer, address, direction, ready, and read-data pins on every `hdl_top.clk` rising edge. It changes no RTL, firmware, expected values, or pass criteria.

The preceding current-c339 row93 run failed in 1,415.732 seconds with 16 scoreboard mismatches at 0xd8–0x114 (actual zero, expected nonzero), UVM_ERROR=16, UVM_FATAL=0. The complete archive is `../mldsa-result-pintrace-array-20261019-02/raw/job-3140_93.tar.gz`, SHA-256 `43b50e8661553e8d2caf6751f0e48f3c8044b64156865c6d000b3df24fb2ca10`.

Do not submit until row97 job 3151 proves the full-clock trace emits runtime lines. Then use this one-row row93 rerun to decide whether zero data is present at the raw AHB pins or introduced by monitor/scoreboard sampling.
