# AXI outstanding write parameter matrix — 2026-10-09

The guarded `run_write_outstanding_depth_matrix.sh` passed all 27 combinations
from a clean QD-BFM checkout at `368d64a8a9e3c42a5bf20c7ee3e6ee0f02304b18`,
using clean published Icarus `main`
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. The run verified the Icarus
commit is an ancestor of `origin/main`; a live remote check returned the same
`main` SHA. Source commits, file hashes, simulator hashes and version, Slurm
script, output, and resource measurement are retained here.

The matrix crosses `DATA_WIDTH` 32, 64, and 128; `ID_WIDTH` 1, 4, and 8; and
`MAX_OUTSTANDING` 1, 2, and 4. Each configuration launches five concurrent
single-beat writes, checks manager capacity and AW/W payloads, holds W payload
stable through delayed WREADY, and routes BRESP/BUSER to the right caller. At
depths 2 and 4, the responder returns out of order across IDs while preserving
order for repeated IDs; caller 3 receives the expected SLVERR.

Slurm job 91 requested 1 GiB and 1 CPU. All 27 compile/simulation cases ran
serially in 0.53 seconds with 17,608 KiB maximum RSS; exit status was zero.

This is representative concurrent read/write parameter coverage, not the full
Caliptra/UVMF qualification matrix.

## Expanded write width cross-product — 2026-10-10

The guarded write matrix now passes 54 configurations: `DATA_WIDTH` 32, 64,
128, 256, 512, and 1024; `ID_WIDTH` 1, 4, and 8; and `MAX_OUTSTANDING` 1,
2, and 4. Each configuration launches five concurrent single-beat writes,
checks manager capacity and AW/W payloads, holds W payload stable through
delayed WREADY, and checks BID/BUSER routing, including the expected SLVERR.
Responses reorder across IDs while repeated IDs retain order.

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
  dv/caliptra_bfm/axi/tests/run_write_outstanding_depth_matrix.sh
```

All 54 configurations passed under the memory guard. Runner, testbench,
manager, simulator, and raw output SHA-256 values:

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/axi/tests/run_write_outstanding_depth_matrix.sh` | `b96697c6fbf2927390ab107d452028aa774e390b425c6c936a894e66e9974cee` |
| `dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master_write_outstanding.sv` | `4e6b2dae30de0581e9af5b3b04f9a7669225f742ff7e30fea8b9c3d32071d70c` |
| `dv/caliptra_bfm/axi/axi4_caliptra_master.sv` | `1b21a6fd7731aea0c4c79089ee7b8fe37f3b1cb9d9d94d7e9843f6ad47d72e64` |
| `logs/write-outstanding-1024-published-20261010.log` (127b887) | `e2c0bb1f57a0a1c3c44c97c6f843240561723e281e93a439a38bb2bd6a7edfc7` |
| `logs/write-outstanding-1024-4b3f-published-20261010.log` | `0485dca5a2a5893974f31185f6ed00e7c3195c18929db23c44687ae2d5ec6613` |
| Icarus `iverilog` | `00a0686a9f0d6962d3e9cd4790464321a608d77efe4db8e50fa02ec7f3f69385` |
| Icarus `vvp` | `f7b6f7cbb87d60f96914ad1213beab2a359e15cc3a2bcf176190cecb28fdc19a` |
