# Caliptra ECC AHB UVM on published Icarus main

Date: 2026-10-09

The existing ECC AHB UVM runner passed on a clean source archive of the newest
published Icarus main revision available in the local origin/main ref. Both
IEEE 1800-2017 and 2023 runs completed the same four transfers through the
native UVM agent against Caliptra ECC RTL.

| Edition | Result | Transfers | UVM warnings/errors/fatals |
| --- | --- | ---: | --- |
| 2017 | PASS | 4 | 0 / 0 / 0 |
| 2023 | PASS | 4 | 0 / 0 / 0 |

## Reproduction

Run each edition with:

CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl
IVERILOG_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/iverilog
VVP_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/vvp
SV_EDITION=2017 or 2023
sh dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ecc_ahb_uvm_bfm.sh

The run used Caliptra commit 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e and
Accellera UVM 2020.3.1. Coverage reported two reads, two writes, four 4-byte
accesses, and zero protocol errors.

## Simulator provenance

The simulator source was a clean archive of published origin/main commit
4b3f3424c440aca6af92153b6860a7253b925234, merged on 2026-10-09 at 09:25 UTC.
Its UVM Core submodule revision was 78c06547a2a0a29b3dc9dcafae62b75b2ff61544.
The source archive was built and installed in a temporary directory without
changing the Icarus working checkout or any branch.

This is the latest published main revision available in the local cache. A
fresh remote lookup failed because this machine could not resolve github.com,
so the current remote head could not be confirmed.

## SHA-256 inputs

| Input | SHA-256 |
| --- | --- |
| Icarus iverilog binary | 00a0686a9f0d6962d3e9cd4790464321a608d77efe4db8e50fa02ec7f3f69385 |
| Icarus vvp binary | f7b6f7cbb87d60f96914ad1213beab2a359e15cc3a2bcf176190cecb28fdc19a |
| ECC UVM runner | a988d54e388ae9fc9b5c5fbafa16d7d1da7f9474ce2f38cda94bf81a0d61c617 |
| Testbench | 6ca5e1706d48edc046b5eb2b3fbb18881e053624cda16c5d56c1f6ae920fd812 |
| BFM UVM filelist | afa63b20041ebef82ff585b449c06cfd208ddc95e8ba2bfd18396fc6ddd931c4 |
| Caliptra ECC filelist | a1b22f20543ebdc0b732981c96554bd287e98d11236fa5d1860c8819aae95ef2 |

This qualifies only the listed ECC unit-level AHB/UVM smoke on these builds; it
does not qualify full UVMF environments or full-top Caliptra firmware.

## Current-state rerun: monitor-driven RAL prediction (2026-10-10)

The test now connects the actual ECC AHB monitor's burst stream to the
clean-room `ahb_reg_predictor` and explicitly disables RAL auto-prediction. A
direct UVM sequence writes and reads `1` at CSR `0x804`; the test checks the
mirror becomes `1`. It then uses RAL frontdoor traffic to write and read `0`
and checks the monitor predictor changes the mirror to `0`. All four
transactions are observed against the pinned `ecc_top` RTL.

The run passed in IEEE 2012, 2017, and 2023 on clean published Icarus source
`4b3f3424c440aca6af92153b6860a7253b925234`. Every run reported two reads,
two writes, four checked transfers, and zero UVM warnings/errors/fatals. The
local Slurm host timed out over SSH, so this focused run used the existing
local Icarus install under the runner's memory guard.

Logs:

- [IEEE 2012](logs/predictor-ral-2012.log)
- [IEEE 2017](logs/predictor-ral-2017.log)
- [IEEE 2023](logs/predictor-ral-2023.log)

QD test source is pinned by commit `2ce14f978f21c095a3c2a7c04dd52fe1fdfb5d88`;
the updated testbench SHA-256 is
`74eab23a5e882a12f5ebce57f6b92992bfd422beeb279accdee422f76812d319`. Caliptra
remained clean at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. The executable
hashes are the same as in the simulator provenance table above.

## Predictor-disconnect mutation control (2026-10-10)

The runner now repeats the simulation with `+AHB_NO_RAL_PREDICTOR`, which
deliberately skips the monitor-to-predictor connection. The normal run passes;
the mutation run is accepted only when it reports exactly one
`ECC_AHB_RAL_PREDICT` UVM fatal and zero UVM errors. Both checks pass for IEEE
2012, 2017, and 2023 on the same clean published Icarus revision. The memory
guard measured a 0.38 GiB peak process group during these runs.

Logs: [2012](logs/predictor-ral-mutation-2012.log),
[2017](logs/predictor-ral-mutation-2017.log),
[2023](logs/predictor-ral-mutation-2023.log).

Current testbench SHA-256: `aabf24f1138087e807433bee8def065adf58799696aa3b9fd966b97a22d7a03e`.
Current runner SHA-256: `f35dfa99b519700c1e250c1aa2ca77b27d1ad68048cd8867ab4ad4820cbe3102`.
