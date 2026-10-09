# Adams Bridge generated MLDSA AHB BFM smoke — 2026-10-09

The pinned Adams Bridge MLDSA UVMF environment compiled and ran a generated
RAL seed write plus version read against the actual `abr_top` through the
clean-room 32-bit AHB manager and monitor under IEEE 2017 and 2023. The RAL checks passed;
the passive AHB monitor recorded one write, one read, and zero error
transfers. UVM reported zero errors/fatals and one expected warning that QVIP
covergroups are not recreated. The MLDSA predictor scoreboard had zero
comparisons because this smoke does not issue a cryptographic operation.

**Status: diagnostic integration evidence, not qualification.** The Icarus
source checkout was dirty and unpublished at `ac4532fab037e91df2f903e67fb40f59baedccca`.
The clean-room AHB path is exercised, but this does not qualify the complete
generated environment or MLDSA cryptographic sequences.

## Reproduction

```sh
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
python3 dv/caliptra_bfm/uvm/tests/run_adams_mldsa_env_compile.py \
  --adamsbridge-root /Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl/submodules/adams-bridge \
  --actual-rtl-smoke --edition 2017
```

The same runner's `--actual-rtl-smoke --compile-only --edition 2017` also
passed. The 2023 runtime uses the same command with `--edition 2023`.
Caliptra RTL was `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams
Bridge was `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and the QD-BFM branch
base was `7ceb95f6c2683fcf49bede68163135bc60aff490`.

| Artifact | SHA-256 |
|---|---|
| `ahb-ral-smoke.log` | `b11447b3adb962a46c572a5056e97a014e5868321436f7f1e3df5748ed67fc58` |
| `ahb-ral-smoke-2023.log` | `9bff4e69079d8f7903ee2f972728746226fb7712518a6026ff38425b103d571e` |
| `run_adams_mldsa_env_compile.py` | `599d80fb043db83f8b1c0a7dd9b374519f609971ff4e096feafc66008500cb08` |
| `ahb_lite_caliptra_uvm_pkg.sv` | `74b15dace3c62cf5c1f3a0f7817e1f993d951c17d2c8f3cc3eda68f4023b16fd` |
| `caliptra_ahb_qvip_compat_pkg.sv` | `4592ce31da201f0e56d4c2629aafbe3638f5d2970713fc382c3a4a5bff05bd9b` |
| `ahb_lite_caliptra_master.sv` | `520933e2b42ba6f2e5e58e1c5be3f48088e50823045c9cdba2c4700e30d57061` |
| `iverilog` | `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114` |
| `vvp` | `4bf80d6d22b44c22d518514c2f98f1f3fd485d77ba7c63bc97e68770d58b2867` |

## Keygen follow-up

`--actual-keygen-smoke --edition 2017` compiled and entered the real MLDSA
keygen busy phase, but the guarded 600-second run timed out before its first
10,000-cycle progress update. The retained progress file ends at cycle 0 with
`busy=1`; no keygen result is claimed. The captured diagnostic output and
progress file hashes are `01b10cf4568fd04dc09a6af0c3a0bc8cb0b6403d97988e71a6b0d0dba04a6570`
and `23f30a07acd54514eed77ab4782bd238407d4910d3e6e8c280ee1ae8ad17226e`.

### Progress-sampling follow-up — 2026-10-09

The progress interval was reduced to 1,000 cycles. A separate 180-second
guarded run reached cycle 1,000 with `busy=1`, then exited at the guard before
keygen completion. The earlier cycle-0-only log was therefore too coarse to
show that the simulation had advanced. No keygen result is claimed. The
progress log SHA-256 is
`b22d5d7fa188567d289b41f7f8c0b45e15a0a428cb2bd7de201219de83595135`; the
runner source used for this probe is
`aa398f185df3931c405d266c1941ee1ed51b61828cc7df2549acc0521e317e73`.

### Controller-progress follow-up — 2026-10-09

An instrumented 180-second run reached `MLDSA_KG_S+12`, the bounded-rejection
sampler instruction for `S2[1]`. At cycle 1,000, the sampler was in WAIT with
five accepted coefficients, SHA3 in `StManualRun`, and the controller waiting
for the sampler. This confirms progress through actual keygen RTL after the
AHB seed and control writes; it did not complete the operation before the
guard timeout. This remains diagnostic because the Icarus source build is
dirty and unpublished (`ac4532fab037e91df2f903e67fb40f59baedccca`).

The trace log SHA-256 is
`ea0206127a22c88b082e8a83a7ae7a8fa2c608725b291c877ecd9873c6881a0f`; the
instrumented runner SHA-256 is
`09388292753e2615dde416f1344b5455b67d97f92e7a5007f5d647ecdd5036a8`.

### Keccak/controller follow-up — 2026-10-09

A second 180-second diagnostic sampled the controller and Keccak engine every
100 simulated cycles. The AHB command had set `busy=1`; controller PC advanced
from 2 to 19 by cycle 1,500, while the sampler and Keccak state changed. The
Keccak round counter advanced from 22 at cycle 400 to 4 at cycle 500, showing
that the round engine completed a permutation and restarted. The outer guard
ended the run at 180 seconds with `busy=1`, before keygen finished or key
readback was checked. This rules out a failed AHB launch or a frozen Keccak
round in the sampled interval; complete MLDSA keygen and scoreboard agreement
remain unverified.

This is diagnostic only: it used dirty, unpublished Icarus source HEAD
`ac4532fab037e91df2f903e67fb40f59baedccca` (`ac4532fa-dirty`). The Caliptra
checkout was clean at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and Adams
Bridge was pinned at `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. Re-run on a
clean, published Icarus SHA before making a qualification claim.

```sh
TMPDIR=/private/tmp/qd-adams-keygen-roundtrace-20261009 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=180 \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
python3 dv/caliptra_bfm/uvm/tests/run_adams_mldsa_env_compile.py \
  --adamsbridge-root /Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl/submodules/adams-bridge \
  --actual-keygen-smoke --edition 2017
```

| Diagnostic artifact | SHA-256 |
|---|---|
| `keygen-progress-keccak-180s.log` | `b148ddbdfd5666c59083b232509ef1f8ccc95c23b84ad1d8fb1d4b0eda343812` |
| `run_adams_mldsa_env_compile.py` | `ec5a3b2db1d94bc9ccbac015067f17bf666b054a80b393928239d79b3cf40ce6` |
| `iverilog` | `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114` |
| `vvp` | `4bf80d6d22b44c22d518514c2f98f1f3fd485d77ba7c63bc97e68770d58b2867` |

### Packed-member width follow-up — 2026-10-09

A standalone paired reproduction isolates the missing SKENCODE read request.
It mirrors `skencode.sv` lines 280–281: `rd_wr_en` is `RW_READ`, while the
named `addr` member is 15 bits and its expression includes the 32-bit
`num_mem_operands`. The checked-in
[`packed member-width reproduction`](packed_member_width_repro.sv) produces
`raw_en=0 raw_addr=1` and `sized_en=1 sized_addr=1` on the Icarus build below.
Verilator 5.050 produces `raw_en=1` for the same uncast assignment and warns
that the 32-bit pattern value is truncated to the 15-bit member. This
reproduces the field loss independently of Caliptra and localizes the observed
no-read behavior to Icarus's handling of this packed-struct assignment
pattern. No QD or pinned RTL workaround was applied. Actual keygen remains
incomplete; this is diagnostic evidence, not qualification.

Both compilers and runtimes were invoked through
`scripts/run_with_memory_pressure_guard.py`. The Icarus source was dirty and
unpublished at `ac4532fab037e91df2f903e67fb40f59baedccca`; its `iverilog` and
`vvp` binary SHA-256 values are recorded above. Verilator was
`5.050 2026-07-01 rev vUNKNOWN-built20260701`. The Caliptra and Adams Bridge
revisions remain `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and
`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, respectively. The reproduction
source SHA-256 is recorded with this follow-up's commit.

Reproduction source SHA-256: `d9a7586a19293ae11bbe9ce215cf8e5e6e4c85c9a0d1d226fdda32e2090d646e`.

### Keygen preflight follow-up — 2026-10-09

`run_adams_mldsa_env_compile.py --actual-keygen-smoke` now compiles and runs
this small reproduction before building the native helper or starting the
Caliptra simulation. On the current Icarus build it exits with the observed
`raw_en=0` result and explains that keygen was not started. The ordinary
version-read smoke and `--compile-only` path are unchanged.

Preflight runner SHA-256:
`8748d2a7beafd982175b2265fd2ce809add4c58746275df490fdfc59dbe6a2db`.

### Generated MLDSA compile-only follow-up — 2026-10-09

The `--actual-rtl-smoke --compile-only` path compiled the pinned generated
MLDSA testbench, clean-room 32-bit AHB provider, and actual `abr_top` RTL in
both IEEE 2017 and 2023 modes. The runner exited successfully in each mode;
`-tnull` was used and VVP was not started, so this confirms compile/elaboration
only, not AHB runtime behavior or keygen. The Adams Bridge checkout was clean
at `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.

This is diagnostic only: the installed Icarus build was dirty and unpublished
at `ac4532fab037e91df2f903e67fb40f59baedccca` (`ac4532fa-dirty`). No
qualification claim is made. Both invocations used the repository's guarded
runner and disposable generated-source overlays:

```sh
python3 dv/caliptra_bfm/uvm/tests/run_adams_mldsa_env_compile.py \
  --adamsbridge-root /Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl/submodules/adams-bridge \
  --iverilog '/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
  --vvp '/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  --edition 2017 --actual-rtl-smoke --compile-only
```

The 2023 run used the same command with `--edition 2023`.

| Input | SHA-256 |
|---|---|
| `run_adams_mldsa_env_compile.py` | `8748d2a7beafd982175b2265fd2ce809add4c58746275df490fdfc59dbe6a2db` |
| Icarus `iverilog` | `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114` |

### Generated MLDSA version-read runtime follow-up — 2026-10-09

The bounded `--actual-rtl-smoke` now passes against the pinned `abr_top` in
both IEEE 2017 and 2023 modes. The generated environment writes the seed RAL
register and reads the actual version register over the clean-room 32-bit AHB
agent. The monitor records one read and one write, no transfer errors, and six
wait cycles. Both runs report zero UVM errors and fatals; the single warning
states that the proprietary internal coverage groups are not recreated. The
scoreboard reports no mismatch. These are runtime smokes, not keygen runs.

This remains diagnostic only because Icarus was dirty and unpublished at
`ac4532fab037e91df2f903e67fb40f59baedccca` (`ac4532fa-dirty`). Adams Bridge
was clean at `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. Each command used the
guarded runner and disposable generated-source overlays:

```sh
python3 dv/caliptra_bfm/uvm/tests/run_adams_mldsa_env_compile.py \
  --adamsbridge-root /Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl/submodules/adams-bridge \
  --iverilog '/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
  --vvp '/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  --edition 2017 --actual-rtl-smoke
```

The 2023 run used the same command with `--edition 2023`.

| Artifact | SHA-256 |
|---|---|
| IEEE 2017 runtime log | `93e598b82bc19993388db6676019915064de7b5096dd8e07c7f8b15c0510416c` |
| IEEE 2023 runtime log | `1c0984f12864dedf708a96ed487eb2c71af381e5c97d78fa145acc56ecf82d7d` |
| `run_adams_mldsa_env_compile.py` | `8748d2a7beafd982175b2265fd2ce809add4c58746275df490fdfc59dbe6a2db` |
| Icarus `iverilog` | `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114` |
| Icarus `vvp` | `4bf80d6d22b44c22d518514c2f98f1f3fd485d77ba7c63bc97e68770d58b2867` |

### Published-Icarus generated MLDSA BFM check — 2026-10-09

The same generated-environment compile and actual-RTL version-read smoke now
pass using a clean source archive of published Icarus main
`127b887dfdc09283ab0187a2e618421dee3d5dcc` and UVM Core
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. The pinned Adams Bridge tree was
`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; the runner verifies this revision
and a clean tree. It creates source-hash-checked compatibility overlays only
in a temporary directory.

The generated MLDSA environment plus the `abr_top` actual-RTL harness compiled
under IEEE 2017 and 2023. The bounded version-read runtime also passed under
both editions: generated RAL wrote the seed and read the actual version over
the clean-room 32-bit AHB agent; the monitor observed one read and one write,
zero transfer errors and six wait cycles. Each run reported zero UVM errors
and fatals and the expected warning that internal QVIP covergroups are not
recreated. This version-register smoke does not run MLDSA keygen; its
scoreboard correctly reports zero matches because no MLDSA prediction was
generated. It is targeted integration evidence, not full Adams Bridge
qualification.

The installed binaries were built from the published source archive. Their
fingerprints and relevant source hashes are:

```text
Icarus source: 127b887dfdc09283ab0187a2e618421dee3d5dcc
a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602  iverilog
29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca  vvp
8748d2a7beafd982175b2265fd2ce809add4c58746275df490fdfc59dbe6a2db  dv/caliptra_bfm/uvm/tests/run_adams_mldsa_env_compile.py
afa63b20041ebef82ff585b449c06cfd208ddc95e8ba2bfd18396fc6ddd931c4  dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f
82729c2af1f1ea9f3c97b9ea42e93d57b75134ded36a1bb027be8bdf5dbbb311  dv/caliptra_bfm/uvm/ahb_lite_caliptra_uvm_pkg.sv
4592ce31da201f0e56d4c2629aafbe3638f5d2970713fc382c3a4a5bff05bd9b  dv/caliptra_bfm/uvm/caliptra_ahb_qvip_compat_pkg.sv
0208f6d8c0fc6e83fa7533cf76990c58f4ad5a062d7cd7a943aea967bb8e4a35  dv/caliptra_bfm/uvm/caliptra_ahb_mvc_compat_pkg.sv
```

Runtime commands (run sequentially):

```sh
python3 dv/caliptra_bfm/uvm/tests/run_adams_mldsa_env_compile.py \
  --adamsbridge-root /Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl/submodules/adams-bridge \
  --iverilog /private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
  --vvp /private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
  --edition 2017 --actual-rtl-smoke

# Repeat with --edition 2023.
```
