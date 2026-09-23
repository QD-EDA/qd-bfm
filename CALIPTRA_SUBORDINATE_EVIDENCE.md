# Caliptra AXI subordinate: first behavioral evidence

This adds a real-RTL target pilot after the interface-only pilot. The production
BFM and adapter are unchanged. The new testbench instantiates upstream axi_sub,
which includes its real read, write, address and arbitration logic, and connects
a QD-owned component model to its internal component interface.

## Configuration and commands

Caliptra v2.1.2 `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, clean before/after.
Native filelist: `src/axi/config/axi_sub.vf`; additional include directory
`src/caliptra_prim/rtl` resolves its assertion include. Parameters: AW=32, DW=32,
UW=32, IW=8, EX_EN=0, C_LAT=0. Manager user/lock remain zero. This is the standalone
subordinate used in the Caliptra integration path, not a complete soc_ifc instance.

```sh
./run.sh
python3 run_caliptra_subordinate.py "$CALIPTRA_ROOT" /tmp/qd-axi-sub-evidence
# Expected overall exit 2 on the observed version.
```

Observed tools: Verilator `5.050 2026-07-01 rev vUNKNOWN-built20260701`, Icarus/vvp
13.0 stable (`v13_0`) for the unchanged standalone suite, Python 3.14.7, macOS arm64.
The runner writes exact argv, engine statuses and wall time in commands.json,
raw stdout/stderr per invocation, version output, and input hashes. Its header
inventory is conservative and is not a proven preprocessing closure. Each
invocation has a 120-second timeout; a timeout is a failed/incomplete run.

## Results and oracles

| Lane | Build | Simulation | Overall consequence |
|---|---|---|---|
| `CLP_ASSERT_ON`, `--assert` | Fails on five unsupported `eventually` properties | Unavailable | UNKNOWN retained |
| Upstream default macros, `--assert` | Builds with three upstream width warnings | 12 transfers, 24 held cycles; injected read-data error detected | Observational evidence only; UNKNOWN retained |

The unsupported properties are in axi_sub_rd.sv lines 400–401 and axi_sub_wr.sv
lines 397–399. The default lane has CLP_ASSERT_ON absent, as in the previous
interface pilot; it is a different configuration, not an assertion-enabled pass.
Additionally caliptra_prim_assert.sv selects dummy concurrent macros under
VERILATOR. Those checks are unavailable, not passed. QD's immediate scoreboard
and existing active BFM checks execute. The runner does not edit or suppress any
upstream property to get a build.

The existing three width warnings remain at axi_if.sv lines 230, 334 and 370.
`-Wno-fatal` permits evidence collection; every warning remains archived and
prevents overall success. A new build error is not silently ignored: its raw log
and nonzero status remain in the assertion lane, and overall output is UNKNOWN.

Six write/read pairs cover full strobes, low-byte, zero-strobe, high-byte, an
error address, and middle bytes after a quiescent reset. IDs include 0, 1, 128 and
255. The component holds each transfer for two cycles. An independently updated
stimulus-side byte scoreboard is compared with returned data; the component-side
monitor checks address, direction, ID, user, size, last, write data and strobes.
There must be exactly 12 accepted component transfers and 24 held cycles.
The error address returns SLVERR and has no modeled write side effect. The final
read checks retained bytes, including across quiescent reset.

`+BAD_DATA` flips one bit only in the QD component read response. The scoreboard
fails at 140 ns with `read data scoreboard mismatch`, nonzero exit and no PASS
banner. Positive execution finishes at 730 ns. No application RTL/DV is mutated.
This fault validates the comparison, not an exhaustive corruption detector.

Initial runner measurements: assertion compile failure 0.042 s, default build
2.983 s, positive simulation process 0.136 s and negative process 0.004 s. These
are single-run wall times including process startup, not a performance guarantee;
peak RSS and scaling were not measured. Raw local artifacts live under
`../evidence/bfm-caliptra-subordinate/`, not a published qualified release.

## Still unknown

Full AXI4 bursts, multiple outstanding/concurrent transactions, response
backpressure variation, exclusive/user semantics, nonzero component latency,
in-flight reset against this target, four-state behavior in this two-state
simulator, full Caliptra DV and UVM compatibility remain outside this pilot.
The separate Icarus four-state suite covers the standalone BFM only. No licensed
VIP or independent AXI protocol checker was used here. This is progress toward
replacing a missing proprietary dependency, not equivalence to that dependency.
Default CI still runs the standalone suite and does not run this optional pilot.

A fresh QD-BFM checkout reran the standalone suite, independently rebuilt both
pilot configurations, and reproduced their statuses and the data-fault detection.
The application checkout remained the same clean pinned input. This is a second
tool workspace, not a second host or independent application checkout.
