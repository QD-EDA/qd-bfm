M14 compress_tb current-main-plus-overlays result — PASS

Job 2347 completed on DAN-DESKTOP (1 CPU, 3 GiB). Compile exit 0, simulation exit 0, one testcase PASS marker and no failure markers. The new testbench latched the DUT's compress_done event and all scoreboards passed: mode 0 wrote 32 packed words, mode 1 wrote 160, mode 2 wrote 352. This is one added current-main-plus-overlays PASS. The pinned-only row remains blocked by the missing ntt_defines package and obsolete testbench interface; neither pinned RTL nor firmware was changed.

Pins: Caliptra RTL 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e; Adams Bridge b77e3d899e828d626cfc2a0d26a6b5704cc121e0; Icarus source 9b5fad2afb4104caa816b257d5bccc40f01b8c66. Exact overlay/filelist/script, source revisions, tool versions and hashes, result, logs, and resource reports are preserved under raw/. The copied run tree was hash-verified before cleanup.

Remote run-tree bytes freed: 151133.
