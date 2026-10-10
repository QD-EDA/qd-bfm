# AXI outstanding read parameter matrix — 2026-10-09

The guarded `run_outstanding_depth_matrix.sh` passed all 27 combinations from
a clean QD-BFM checkout at `63283a712939e840f18c3d15bb1e22d1a8a8f457`, using
clean published Icarus `main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`.
The run verified the Icarus commit is an ancestor of `origin/main`; a live
remote check returned the same `main` SHA. Source commits, file hashes,
simulator hashes and version, Slurm script, output, and resource measurement
are retained here.

The matrix crosses `DATA_WIDTH` 32, 64, and 128; `ID_WIDTH` 1, 4, and 8; and
`MAX_OUTSTANDING` 1, 2, and 4. Each configuration launches five queued read
tasks, checks the configured capacity, and verifies returned data and USER
metadata. At depths 2 and 4, the responder returns responses out of order across
IDs while preserving order for repeated IDs.

Slurm job 89 requested 1 GiB and 1 CPU. All 27 compile/simulation cases ran
serially in 0.53 seconds with 17,616 KiB maximum RSS; exit status was zero.

This covers the read side of the representative width/ID/outstanding matrix.
The concurrent write matrix and full Caliptra/UVMF qualification remain open.

## Expanded read width cross-product — 2026-10-10

The guarded read matrix now passes 54 configurations: `DATA_WIDTH` 32, 64,
128, 256, 512, and 1024; `ID_WIDTH` 1, 4, and 8; and `MAX_OUTSTANDING` 1,
2, and 4. Each configuration launches five queued reads, checks capacity,
and verifies response data and USER routing. The responder reorders responses
across IDs while preserving order for repeated IDs.

An initial run passed on clean published Icarus
`127b887dfdc09283ab0187a2e618421dee3d5dcc`. The matrix was then repeated on
the newest locally available published `origin/main` revision,
`4b3f3424c440aca6af92153b6860a7253b925234`, and all 54 cases passed again.
The `iverilog` and `vvp` hashes match the clean-build record in the 2026-10-10
published-main evidence. QD runner source is commit
`13363373b49c2aaaf31621c21692f28df0ee9898`; the working tree also contained
unrelated local files, which were not runner inputs and were left untouched.

Reproduce with:

```sh
IVERILOG_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/vvp \
  dv/caliptra_bfm/axi/tests/run_outstanding_depth_matrix.sh
```

All 54 configurations passed under the memory guard. Runner, testbench,
manager, simulator, and raw output SHA-256 values:

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/axi/tests/run_outstanding_depth_matrix.sh` | `94d34573dcccc7efbd3ff37e8182ad06db0def59a943728c7be9e7c3ce0d6526` |
| `dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master_outstanding.sv` | `42aba854f065d85eb0fa82912620b9b7a2e4c3730d4b7b41251b6d0e847b2562` |
| `dv/caliptra_bfm/axi/axi4_caliptra_master.sv` | `1b21a6fd7731aea0c4c79089ee7b8fe37f3b1cb9d9d94d7e9843f6ad47d72e64` |
| `logs/outstanding-1024-published-20261010.log` (127b887) | `a40e9af8b39b2e051ac5d5158b780de919afb7c767d5a59ef965786cdc6705ee` |
| `logs/outstanding-1024-4b3f-published-20261010.log` | `8af67c35b6f6a2dec8546a093b9661b21e2a47de24e3ff40babeb6c07456e3ce` |
| Icarus `iverilog` | `00a0686a9f0d6962d3e9cd4790464321a608d77efe4db8e50fa02ec7f3f69385` |
| Icarus `vvp` | `f7b6f7cbb87d60f96914ad1213beab2a359e15cc3a2bcf176190cecb28fdc19a` |
