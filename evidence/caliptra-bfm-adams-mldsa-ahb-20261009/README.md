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
