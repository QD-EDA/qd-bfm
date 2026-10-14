# AXI unaligned FIXED and INCR evidence — 2026-10-09

Both guarded regressions passed from a clean QD-BFM checkout at
`72123e9f055630781e664fd6aa4960671afe3394` using clean, published Icarus
`main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. The Icarus source checkout
was clean and contained that commit in `origin/main`; a live remote check
returned the same `main` SHA. The source and executable hashes, tool version,
Slurm script, runner output, and resource logs are retained here.

The tests cover an unaligned four-byte INCR burst whose first beat uses only
byte lane 3 and whose next address is aligned, an unaligned two-beat FIXED
burst that retains its address and lane, and a one-byte write/read at the final
mapped SRAM byte. The master suite also retains the legal WRAP and aligned
narrow cases; the subordinate suite checks the write/read results and coverage
denominators. Address and lane progression follows Arm IHI0022H A3.4, the
[AMBA AXI and ACE Protocol Specification](https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/IHI0022H_amba_axi_protocol_spec.pdf).

Slurm job 76 requested 1 GiB and 1 CPU. `/usr/bin/time -v` measured 17,644 KiB
maximum RSS for `run_master.sh` and 17,588 KiB for `run_subordinate.sh`; each
runner completed in 0.28 seconds. Both exit statuses were zero.

This is directed evidence for the tested 32-bit configuration. It does not
qualify other data widths, four-state behavior, an independent simulator, or
the full Caliptra/UVMF integration.
