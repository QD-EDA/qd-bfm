# Trailing empty `$psprintf` argument: simulator differential

Pinned Icarus 13.0 source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` rejects the reduced `psprintf_empty_arg.sv` with “The function `$psprintf` has been called with missing/empty parameters.” The control, differing only by removal of the trailing comma and empty argument, compiles and runs under the same Icarus build. Verilator 5.032 compiles and runs both forms; it emits a `NONSTD` warning because `$psprintf` is non-standard.

The source shape also appears in pinned Caliptra KeyVault `kv_rst_configuration.svh` (Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, file SHA256 `9d1682590cb85410b67cefe0df3f66f6ca31304f03a1458d283df99411c3a2a6`). Its `uvm_info` at source lines 142–144 contains `$psprintf(..., agent_path, interface_name, )`; the full Icarus log reports the diagnostic at line 149.

The issue is filed internally for A3 to classify as [#670](https://github.com/dsellerbrock/iverilog-uvm/issues/670), labeled `from-caliptra-dv`. This reduced test does not prove a full Caliptra environment pass; KeyVault row 6 remains blocked by other generated-code diagnostics. Nothing in RTL, firmware, or pass criteria changed.

Job 2784 (one CPU, 1 GiB, five-minute Slurm cap) tested pinned Icarus plus Verilator lint. Job 2785 repeated both forms with Verilator runtime. These tiny diagnostic runs did not record per-process RSS; Verilator reports 153 MB allocator use in its runtime summary. The two remote capture hashes were verified after copying to this directory:

- `run-2784.tar.gz`: `e068c28883e6329d6872f35fa3fda46ee9278dda6ed07d80dcd60640b49438f9`
- `run-2785.tar.gz`: `4b3fe9bfabe9943c773a5252ba3152c173933824dee4af8e638424071cd55d12`

The issue text is saved as [`issue-draft.md`](issue-draft.md), and all raw sources and captures are listed in `SHA256SUMS.txt`. The captures contain logs and build results; generated executables and Verilator object directories are excluded. Both completed remote run trees and temporary tar staging were removed after verification, freeing 1,017,382 bytes (about 0.00095 GiB).
