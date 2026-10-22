# MBOX trace build attempt 1779

The job stopped before Verilator compilation. The filelist helper retains the pinned `${CALIPTRA_ROOT}/src/axi/rtl/axi_if.sv` entry; the first script incorrectly expected a generated overlay path there, so its exact-match guard exited before changing the filelist. This was a diagnostic-script error, not a simulator or firmware result. The complete submitted log, generated filelist and manifest are retained here, and all three match their remote SHA-256 values in `REMOTE-SHA256SUMS`. The retry uses a fresh run directory and replaces the actual pinned entry.
