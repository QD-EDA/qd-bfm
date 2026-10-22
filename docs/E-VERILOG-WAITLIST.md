# E-Verilog waitlist

Cases below could not complete in the default Verilator 5.052 flow. Icarus
status shows whether the open-source reference lane also has a gap.

| Case | Why not Verilator | Icarus status |
| --- | --- | --- |
| `smoke_test_sha3_interrupts` (M11 row 144; M23 `1b067d21081b705c`) | Firmware build failed before simulation (runner exit 1 after 0.781 s). The compact fetched bundle did not retain the underlying compiler diagnostic; capture it before the next Verilator retry. | M21: PASS, 6,731 s. |

M23 had no Verilator TIMEOUTs. `smoke_test_doe_scan` completed with FAIL and is
reported in the [M23 results](../evidence/caliptra-bfm-m23-20261022/README.md);
it is not listed as a timeout here.
