M14 sigdecode_z width-alias gate — COMPILE_FAIL

Job 2348 completed on DAN-DESKTOP (1 CPU, 3 GiB). The run-local abr_params_pkg alias removed the zero-width MLDSA_MEM_ADDR_WIDTH compile blocker, but Icarus then reported two elaboration errors: sigdecode_z_test is declared with one argument while its two call sites each pass two. Simulation did not start. This is a testbench call mismatch, not a simulator defect. The failed gate's raw sources, filelist, compile log, resource/version reports, hashes, and result are preserved under raw/; the remote run tree was hash-verified before cleanup.

Pinned source and compiler SHAs are recorded in raw/tasks/adams-bridge-v2-0-3-sigdecode_z_tb/source-revisions.txt. No RTL, firmware, or pass criteria changed.

Remote run-tree bytes freed: 29960.
