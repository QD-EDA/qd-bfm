# Verilator top-level build with the Icarus checker overlay

Slurm job 1311 on DAN-DESKTOP built `caliptra_top_tb` with Verilator 5.052
(`ea338be98e1e838d3518809ce8899f85a009963c`) and the QD-BFM wrapper. The build
used 4 CPUs and a 3 GiB memory limit; it finished in 96.67 seconds, exited 0,
and peaked at 2,359,796 KiB RSS. The linked model is 707,542,264 bytes with
SHA-256 `b6ee29ade1b17547c4b31692ed9a0b48e22031c4551604fd9dc250a81e01ae79`.

This rebuild replaces the earlier diagnostic model's upstream SVA checker
with the same pinned diagnostic overlay used by the Icarus runner: it removes
nine `$display` statements while preserving checker predicates and failure
returns. The generated filelist records the base and overlay hashes, the
top-testbench overlay hash, checker overlay hash, and 16 QD sources in
`filelist-manifest.txt`. QD-BFM source commit: `d0d728d7a4aea66ce1962a418d6403d017b72157`;
Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`;
Adams Bridge: `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.

The build retained two warnings: upstream `MISINDENT` in
`caliptra_top_tb_services.sv:1111` and `CASEINCOMPLETE` in the QD AXI checker at
`axi4_caliptra_checker.sv:217`. They were nonfatal under `--Wno-fatal`; the
generated model linked successfully. The full build log and resource report
are retained here. Ask-intern's log summary was checked against the final
link command, model hash, and exit status in the source log.

The model remains in the protected-for-this-run tree
`/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-top-20261015-06/model`
while the firmware comparisons use it. It will be removed after all result
logs and hashes have been recorded.
