M14 skencode width-alias gate — BLOCKED_COMPILE

Job 2352 completed on DAN-DESKTOP (1 CPU, 3 GiB). The alias overlay removed the missing MLDSA_MEM_ADDR_WIDTH blocker, but compile then failed because the pinned skencode_tb connects a skencode_error port that is absent from the current skencode DUT. Simulation did not start. This is a testbench/DUT interface mismatch, not a simulator issue. The exact compile output, source package overlay, filelist, script, versions/hashes, and result are preserved under raw/; the remote tree was hash-verified before cleanup.

No RTL, firmware, or pass criteria changed. Whether the stale error port can be adapted without removing the negative error check remains under review; this row is not counted as a PASS.

Remote run-tree bytes freed: 36658.
