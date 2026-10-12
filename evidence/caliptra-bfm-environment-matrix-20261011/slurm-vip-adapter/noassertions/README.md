# Compile without assertions

Job 548 recompiled the `caliptra_top_ss_mode_tb` filelist from an immutable copy of the same Caliptra/Adams Bridge/QD-BFM sources as job 464. Icarus c339 (`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`) used `-g2017 -gno-assertions`; the one-CPU compile ran with a 3 GiB memory request and a 1,500-second timeout.

Compile exited 1 with 47 diagnostics: 46 mixed-driver reports across 23 signal names on the SRAM and FIFO AXI interfaces, plus the clock-generator intra-assignment-delay error. Removing assertions did not change either error class. No simulation ran. Host, source revisions, tool hashes/versions, compile resource data, and the full log are preserved here. The standalone reducer using the original `-g2017 -gassertions` flags passes, so the mixed-driver finding remains specific to the full source and is not attributed to a generic force/release failure.
