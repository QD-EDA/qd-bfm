# Exact-pin SystemVerilog display-width check

A five-line reproducer was compiled and run on DAN-DESKTOP with the M20 Icarus source pin `cae035642e056644274a01e98d4422ce286685b4` (Icarus 13.0 devel). The `iverilog` SHA-256 is `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`; the `vvp` SHA-256 is `979d745f46bf952c86b1f09255e2256a6eec2bbef15b5c11634c8b4c95013309`.

Command: `iverilog -g2012 -o /tmp/m20b-display-width.vvp /tmp/m20b-display-width.sv`, then `vvp /tmp/m20b-display-width.vvp`. The observed output is `00000003`.

IEEE 1800-2017 §21.2.1.3 specifies that displayed expression values are sized automatically; a field expands when the converted value is wider than the requested field, with no truncation. Thus `%02X` on a 32-bit value produces eight hex digits. Icarus matches the clause. Caliptra's command reader expects a one-byte opcode, so the underlying issue is its command-width assumption; the M20 overlay explicitly sizes the command expression and stays in place.

The requested `from-caliptra-dv` compatibility report is [issue #797](https://github.com/dsellerbrock/iverilog-uvm/issues/797). Full exact-pin transcript: `raw/exact-pin-run.log`.
