# Caliptra top AAXI row 0 gate (corrected source snapshot)

One-row gate before rows 1–4. Uses the open-AAXI compatibility package/filelist overlay and generated environment's open-AHB overlay. Limit: 600 s, 1 CPU, 4 GiB. Snapshot includes all support filelists and the AAXI overlay helper. Pass criteria unchanged. Pinned Icarus source: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`.

An earlier staging attempt (job 2936) stopped before compile because its source snapshot omitted `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f`; raw archive `../top-aaxi-row0-gate-20261019-26/raw/job-2936-infrastructure.tar.gz` (SHA-256 `cf736fdbe09dc9f0e55c69b246697296e44f572ba2e68c218dd282acc9b93212`).

The corrected-source retry, job 2940, reached Icarus and was blocked by the deliberate syntax guard in `src/integration/tb/Axi4PC.sv:17`. The top environment filelist contains this stub, but the pinned top environment sources do not reference it; the filelist overlay now drops it as an unused testbench dependency. Raw archive `raw/job-2940.tar.gz`; SHA-256 `d1f09899c7266628c457818359eab77c497836966d29d1e86f21d07f7f69c2a7`. This is an intermediate gate result; row 0 will be classified from a fresh run with the updated overlay.
