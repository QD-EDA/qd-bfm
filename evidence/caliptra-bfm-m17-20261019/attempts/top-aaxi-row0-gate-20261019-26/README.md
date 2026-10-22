# Caliptra top AAXI row 0 gate

Single-row gate before rows 1–4. Uses the existing open-AAXI compatibility package/filelist overlay plus the generated environment's open-AHB overlay. Limit: 600 s, 1 CPU, 4 GiB. Pass criteria unchanged; pinned Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`.

**Infrastructure failure only:** job 2936 stopped before compile because the source snapshot omitted `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f`. No test result was produced and row 0 remains pending. Raw archive `raw/job-2936-infrastructure.tar.gz`; SHA-256 `cf736fdbe09dc9f0e55c69b246697296e44f572ba2e68c218dd282acc9b93212`. The intern diagnosis was verified against `runner.log` and `result.json`.
