# EL2 stale memory-port overlay rerun

`el2-veer-remove-stale-dft-ports.patch` removes the four zero-tied memory DFT
packet pins absent from pinned `rvtop`. The patch is applied only to an
isolated Caliptra source archive; the pinned checkout remains unchanged.

Job 570 was a setup failure: GNU patch stripped the CRs from the CRLF patch.
Job 572 verified CRLF-safe application and exposed the other three stale pins.
Job 574 used a fresh source archive and the expanded patch. It removed all four
stale pins, then stopped at two unconnected wrapper memory-export interfaces
and 22 c339 errors resolving static members through interface continuous
assignments. Those same 22 errors appear in the pinned-only local compile; the
memory interfaces are not instantiated by the testbench, and simulation did
not run. This row remains BLOCKED with a specific upstream testbench and c339
elaboration cause, not a PASS.

Job 574 used one CPU, 3 GiB, a 6,900-second process timeout, and a two-hour
Slurm limit. The compiler exited 24 after 1.67 seconds at 262,892 KiB peak RSS.
Provenance, tool versions, hashes, compiler output, and scheduler output are in
[`run-574/`](run-574/README.md). Remote run root:
`/home/dsell/slurm-runs/caliptra-bfm/a2/m4-env-overlay-c339-20261011-03`.
