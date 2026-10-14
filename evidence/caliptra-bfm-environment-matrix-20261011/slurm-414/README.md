# Slurm array 414: Python setup repair results

This fresh array used the pinned c339 toolchain and a run-local Python 3.14.4 environment with NumPy 2.5.4. It fixes `python`/NumPy availability without changing the pinned Caliptra or Adams sources.

- `power2round_tb`: PASS; 2,048 vector cases completed, one pass marker, no errors.
- `rej_bounded_tb`: FAIL; generated vector files and executed, then reported 8 errors including repeated “Not enough valid samples in the queue” and `TESTCASE FAILED`.
- `sigencode_z_tb`: FAIL; generated inputs and ran, but 3,584 output comparisons produced `Got: xxxxx` against expected values. This confirms a functional failure but does not yet establish an Icarus defect; no issue was filed for it.

Raw compile/simulation/resource logs, generated-file hashes, source/tool provenance, and host details are preserved per task. All three Slurm tasks completed; no local duplicate was started.
