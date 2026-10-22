M14 sigdecode_z diagnostic gate — SUPERSEDED, NOT COUNTED

Job 2351 completed on DAN-DESKTOP (1 CPU, 3 GiB); compile and simulation both exited 0. The protected Python 3.14.4 + NumPy 2.5.4 environment generated nonempty input_z.hex and output_decoded_z.hex. Both invocations printed “Test completed”; there were zero output-mismatch messages and no runtime ERROR lines. This result used the package-level width alias as an overlay, which M14 excludes under the no-RTL-overlay guardrail. It is preserved for diagnosis but not counted. A fresh testbench-only width correction is being gated separately.

The package-level alias was the only non-pinned input in this diagnostic run. No firmware or pass criteria changed.

Pins, Python/NumPy versions, filelist and overlay hashes, tool hashes, vectors, logs, and resources are preserved under raw/. The remote run tree was hash-verified before cleanup.

Remote run-tree bytes freed: 3662568.
