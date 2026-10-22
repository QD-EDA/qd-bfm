# M21 Part A Icarus issue triage

Current-main probes use Icarus source `cc25756d187314742d347267c2a513b3e640a7fb`, `iverilog` SHA-256 `87bb417df23d260bcfde3fb372b4a80eaad69e4fd2eea1ffb8b0eff10f7af08e`, and `vvp` SHA-256 `dfc193c466a70a0917a16ab4198a111de616657d6004de79456db2a4b603b437`.

| Issue | Action | M20 rows / cause |
|---|---|---|
| [#834](https://github.com/dsellerbrock/iverilog-uvm/issues/834) | New issue, `from-caliptra-dv` + `bug`; includes <=20-line reproducer, 64-bit control, expected/observed, and IEEE 1800-2017 §19.5.1. | 0–4, 43–45: explicit 256-bit coverpoint range bin cannot be represented. |
| [#12](https://github.com/dsellerbrock/iverilog-uvm/issues/12) | Commented with a distinct `inside` Boolean as `dist` subject case; diagnostic cites IEEE 1800-2017 §11.8.2. | 0–4, 43–45. |
| [#670](https://github.com/dsellerbrock/iverilog-uvm/issues/670) | Commented with current-main confirmation, paired control, no applicable IEEE clause (`$psprintf` is non-standard), and <=20-line reproducer. | 0–4, 43–48. |
| [#671](https://github.com/dsellerbrock/iverilog-uvm/issues/671) | Commented with current-main confirmation, control, IEEE 1800-2017 §7.6, and a tested 16-line reproducer. | 46–48. |
| [#663](https://github.com/dsellerbrock/iverilog-uvm/issues/663) | Commented that the current-main reduced reproducer now passes. | 46–48; inherited type-parameter member lookup. |
| [#664](https://github.com/dsellerbrock/iverilog-uvm/issues/664) | Commented that the current-main reduced reproducer now passes. | 46–48; omitted method parentheses in concatenation. |
| [#672](https://github.com/dsellerbrock/iverilog-uvm/issues/672) | Commented that the current-main reduced reproducer now passes. | 46–48; nested property path through parameterized base. |
| [#667](https://github.com/dsellerbrock/iverilog-uvm/issues/667) | Commented that wide automatic bins now compile and run on current main; M20 later blockers are unrelated. | Prior wide automatic-bin cause was cleared before the M20b baseline. |

The ECC, PV, and SoC-IFC input-modport write diagnostics are testbench binding defects under IEEE 1800-2017 §25.5, demonstrated by `interface_modport_actual.sv`; they are being handled with copied-top A2 overlays, not reported as Icarus bugs. M20 rows 12, 13, and 51 have no recorded progressing heartbeat/mcycle or isolated simulator root cause, so they are not filed or included in A3.
