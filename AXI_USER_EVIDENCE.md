# Bounded AXI USER evidence — 2026-09-24

Pinned Caliptra RTL v2.1.2 is `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
Its `src/soc_ifc/tb/soc_ifc_axi_sha_acc_dis_tb.sv` passes variable USER values
to `axi_read_single` and `axi_write_single`. The latter supplies a separate
`write_user`, but `axi_if.axi_write_single` hardcodes `use_write_user(0)`, so
that upstream argument does not reach WUSER. The previous QD adapter tied
ARUSER/AWUSER/WUSER low, so QD's
12-transfer subordinate pilot could not represent these accesses. The upstream
interface tasks in `src/axi/rtl/axi_if.sv` and component USER assignments in
`axi_sub_rd.sv`/`axi_sub_wr.sv` are the reference for this bounded mapping.

The new `write_one_user` takes separate AWUSER/WUSER and `read_one_user` takes
ARUSER. Existing task calls still use zero. The driver rejects X/Z USER
arguments before launch and checks all three USER payloads across READY stalls.
It does not interpret response USER, nonzero lock, bursts, or overlapping calls.

## Reproduce

Host: macOS arm64. Icarus/vvp 13.0 stable (`v13_0`), Verilator 5.050
(`2026-07-01 rev vUNKNOWN-built20260701`), Python 3.14.7. QD base
`532d33cc5293cb1a7df4980485855cab9a0740f8`. From QD-BFM:

```sh
./run.sh
python3 run_caliptra_subordinate.py /Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl /tmp/qd-axi-user-caliptra-pilot-positional
/tmp/qd-axi-user-caliptra-pilot-positional/obj-upstream-default/Vtb_caliptra_axi_sub +USER
/tmp/qd-axi-user-caliptra-pilot-positional/obj-upstream-default/Vtb_caliptra_axi_sub +USER +BAD_USER
```

The standalone suite exits 0: three accepted write/read pairs cover USER zero,
nonzero and all-ones on AW/W/AR, with at least two READY-low cycles per request
channel. Six X/Z argument cases and three stalled USER mutations exit nonzero
before PASS; the independent local target rejects a seeded wrong expected
AWUSER. Other existing tests remain passing. One local `./run.sh` measurement
was 1.07 s wall and 5,996,544 bytes peak RSS including compilation; no
reference-host throughput claim follows.

The real `axi_sub` default lane with `+USER` exits 0: six additional transfers,
18 total, 36 component hold cycles; its component monitor sees AWUSER/ARUSER,
and a separate request-pin monitor sees QD's WUSER. This does not demonstrate
nonzero WUSER behavior in the upstream SHA bench. `+USER +BAD_USER` exits 1 at
885 ns with component address/control mismatch and no PASS banner. The normal
runner retains its original 12 transfers, bad-data detection, three raw
interface width warnings and five `eventually` assertion build errors. It exits
2 (UNKNOWN), as before. Raw commands/logs/input hashes live in
`/tmp/qd-axi-user-caliptra-pilot-positional`; this is local evidence, not a release bundle.

The named upstream `soc_ifc_axi_sha_acc_dis_tb.vf` lint attempt uses:

```sh
CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
CALIPTRA_PRIM_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl/src/caliptra_prim_generic \
CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic \
verilator --lint-only --timing -Wno-fatal --top-module soc_ifc_axi_sha_acc_dis_tb \
  -f src/soc_ifc/config/soc_ifc_axi_sha_acc_dis_tb.vf
```

It exits 0 with 222 visible warnings, archived at
`/tmp/qd-axi-user-sha-lint.log`. `-Wno-fatal` is evidence collection only.
This was a lint-only run of the upstream bench, with no QD-BFM hookup and no
runtime SHA authorization result. The Caliptra checkout was clean afterwards.
This single host and one checkout do not establish repeatability. Full DV,
four-state behavior on real RTL, UVM interoperability, USER-dependent security
policy, and AXI protocol qualification remain UNKNOWN.

The pinned Linux CI runner now executes both USER modes at response delays 0
and 7. Its evidence validator requires 18/36 positive coverage, the expected
response stall counts, the wrong-USER failure without PASS, and the unchanged
warning/assertion diagnostic set. Eleven corruptions of copied evidence must
be rejected. The local delay-7 run and evidence checker passed, with overall
pilot status still UNKNOWN.
