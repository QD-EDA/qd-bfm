# QD-BFM

`qd_axi4_single_master.sv` is a small AXI4 manager BFM for bounded, directed, single-beat reads and writes. It targets the inbound SoC AXI subordinate interface in Caliptra RTL v2.1.2: `caliptra_top.sv` ports `s_axi_w_if` and `s_axi_r_if` (`axi_if.w_sub` / `axi_if.r_sub`), declared in `caliptra-rtl/src/axi/rtl/axi_if.sv`. That interface's widths come from integration parameters; the BFM defaults are `AW=32`, `DW=32`, `IW=8`, `TIMEOUT=16`.

It is a directed-test helper, not UVMF/QVIP/Avery verification, Caliptra DV qualification, or AXI protocol signoff. It does not implement bursts, multiple outstanding transactions, user/lock signaling, coverage, or a Caliptra adapter. The local test uses an independent tiny memory target and does not compile or modify Caliptra.

## Requirements and quick start

Install Icarus Verilog (`iverilog` and `vvp`), then run:

```sh
./run.sh
```

The script compiles the BFM and local testbench, then runs the passing write/read, request-stall, error-response, and address-timeout cases. It also injects a bad read response ID and missing `RLAST`, requires each run to fail, and rejects any pass banner from those negative runs. Success prints `PASS` and exits `0`; a compile, simulation, or expectation failure exits nonzero.

## Using the BFM

Instantiate the module and connect its request/response pins to the manager side of the target interface (for Caliptra's inbound interface, to `s_axi_*_if`). Drive `clk` and active-low `rst_n`; tie unused interface user/lock fields low and ignore response user fields. Call `write_one(addr, data, strb, id, ok, resp)` or `read_one(addr, id, ok, data, resp)` from a testbench process. The address must be aligned to `DW/8` bytes and reset must be released. `ok` is true only for a successful response; `resp` carries the two-bit AXI response. `TIMEOUT` bounds each wait in clock cycles.

Requests remain asserted through ready stalls, with payload-stability checks. Response ID mismatch or a read without `RLAST` calls `$fatal`; AXI error responses return `ok=0`. On request-channel timeout, VALID remains asserted to preserve AXI handshake rules: reset both BFM and target before another transfer. Response timeout returns `ok=0` and deasserts response ready.

Licensed under Apache-2.0; see [LICENSE](LICENSE).

See [the staged qualification roadmap](ROADMAP.md) for named pilots, unsupported
cases, independent oracles, performance targets and release gates.
