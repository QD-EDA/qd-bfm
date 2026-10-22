# Draft: LMS firmware rows fail while loading DCCM images

**Status:** Local review draft only; not posted. The focused run retains the failing image and identifies the out-of-range address/index values; which layer should convert them remains a maintainer question.

The focused Verilator 5.052 run with the official M10b overlay and assertions for `fw_test_lms32` (`8c392993b1af6e0c`) stops at time 0 before firmware execution with:

```text
%Error: dccm.hex:1: $readmem file address beyond bounds of array
```

The preserved `dccm.hex` is 5,177 bytes / 107 lines and starts with the address directive `@FFFFFFFFB0003FF0`. At time 0 the preloader reports DCCM base `0x50000000`, limit `0x5003ffff` (256 KiB), an array depth of 32,768 64-bit words (last legal index 32767), and `readmemh_end_index=262143`. Verilator reports the out-of-bounds error at `dccm.hex:1`. The directive and reported end index are outside the word-array index range; the evidence supports an address/index-unit mismatch, but does not establish whether the image generator or testbench loader should remap the address. See [the retained image and trace](../diagnostics/m11b-focused-traces-20261017-06/raw/job-2090/results/8c392993b1af6e0c/).

Array 1835 also recorded this failure for LMS rows, but their cleanup had removed the generated images. The focused `fw_test_lms32` c339 baseline is unverified. Please confirm the intended address format for LMS DCCM images and which layer owns conversion to the 64-bit preloader word index. No compatibility workaround was added.

M12 adds a build-time, Verilator-only DCCM image-load overlay: it normalizes LMS address directives into DCCM-relative offsets, stages bytes into a one-dimensional scratch array, then copies them into the existing 64-bit preloader. The original generated image and its payload are preserved and hashed. Full-timeout gate 2123 passed `fw_test_lms32` at mcycle 2,675,745 with `sim_scan.bad=0`; All 33 remaining rows passed in array 2146; the per-row results and hashes are in the checksum-verified [`array-2146` evidence archive](../../../caliptra-bfm-verilator-m12-20261017/lms-dccm/generated/array-2146/evidence.tar.gz). This local candidate does not modify RTL, firmware, or pass criteria; final per-row results are recorded in the M12 report when the array completes.
