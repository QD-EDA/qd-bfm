> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra generated-name AHB compatibility smoke evidence

Date: 2026-10-04

## Scope

This evidence covers the clean-room `qvip_ahb_lite_slave` configuration and
UVM environment API plus a clean-room `hdl_qvip_ahb_lite_slave` shell. The
smoke instantiates the replacement in active and passive modes, creates the
QVIP-named environment, stores `AHB_READ` and `AHB_WRITE` in the `ahb_rnw_e`
type, performs AHB write/read traffic against a synthetic memory target, and
checks the predictor, scoreboard, coverage, and passive monitor streams. It
verifies the locally implemented generated-name surface;
the initial smoke did not compile or run the pinned generated Caliptra/Adams
HDL top or UVMF environment. A later package-compile check is recorded below.

The smoke reports one intentional `AHB_QVIP_CVG` warning in each generated-
style run: proprietary internal QVIP covergroups are not recreated. Icarus
also reports existing mixed-timescale and UVMF-lite `eval_object_select`
compile warnings. Runtime summaries report zero UVM errors and fatals.

## Commands and results

Compiler/runtime: `/private/tmp/bfm-work-install/bin/iverilog` and
`/private/tmp/bfm-work-install/bin/vvp`, Icarus 13.0 development build from
`246c58e4` (dirty local compiler tree).

Pinned Caliptra RTL: commit
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

From the `BFM WORK` checkout, each of these exited 0 and printed
`PASS: generated-name AHB QVIP configuration, environment, sequencer, and analysis streams`:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp SV_EDITION=2012 \
  dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh

IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp SV_EDITION=2017 \
  dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh

IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp SV_EDITION=2023 \
  dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh
```

The AHB QVIP smoke was rerun after adding the enum check. All three editions
exited 0 with zero UVM errors/fatals; each retains the expected single
`AHB_QVIP_CVG` warning. The rerun outputs are in
`ahb_qvip_compat_2012_after_rnw_enum.log`,
`ahb_qvip_compat_2017_after_rnw_enum.log`, and
`ahb_qvip_compat_2023_after_rnw_enum.log`.

The existing AHB keyed-stream regression also exited 0 and printed
`PASS: keyed AHB compatibility streams completed wait-state read/write and propagated ERROR`:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  dv/caliptra_bfm/uvm/tests/run_ahb_lite_uvm_agent.sh
```

Earlier outputs are retained in `ahb_qvip_compat_2012.log`,
`ahb_qvip_compat_2017.log`, `ahb_qvip_compat_2023.log`, and
`ahb_lite_uvm_agent.log`.

## Source hashes

SHA-256 at evidence capture:

```text
00a8177347b55f69842ddaa34d3dc281bc14b3b0cbba1ed142f32a7b9716c01b  dv/caliptra_bfm/uvm/caliptra_ahb_mvc_compat_pkg.sv
53a0661f6e0d76349ab93ebe2806f93e45da9ac111a881333e0326b3b601d50e  dv/caliptra_bfm/uvm/ahb_lite_caliptra_qvip_hdl.sv
7ceae4cba0f1da6b300bc9cd89fae940bb295456e539bf4b00992928561b144d  dv/caliptra_bfm/uvm/caliptra_ahb_qvip_compat_pkg.sv
b928bf29277747371fda9e499575be3808f1edc7b93c566b27c290ea7add236b  dv/caliptra_bfm/uvm/ahb_lite_caliptra_uvm_pkg.sv
9f9459dc3eaf8afc6de74d1d0eeb3666baa52ee353d8a845ba4fbb214601ae69  dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f
419481d6876a1504fd9ba9dc625e92cdb558ef0906230d465dcf3be50ac81765  dv/caliptra_bfm/uvm/tests/tb_ahb_qvip_compat_env.sv
ae65bc9c1a947d232b4bcd37d75e903a099651017c595b99afbc3851e8d93b42  dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh
7495994665229148b8735448f538f0e481b8cbd22cc1df3109226d207f43684e  dv/caliptra_bfm/uvm/tests/run_ahb_lite_uvm_agent.sh
```

## Bounded MVC burst follow-up (2026-10-05)

The AHB MVC path now accepts up to 256 data beats, drives NONSEQ/SEQ phases,
returns per-beat responses, and groups contiguous monitored SEQ transfers into
one queue item. The agent smoke writes and reads four beats, aborts on a first-
beat ERROR, and exercises an end-of-memory write burst with one successful
beat, one ERROR beat, and two unissued beats. It checks partial response queues
and preservation of unissued data. The generated-name smoke checks four-beat
items on all active keyed streams and the passive stream.

Both guarded commands exited 0 with a 70% free-memory floor and minimum
observed free memory of 74%:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  dv/caliptra_bfm/uvm/tests/run_ahb_lite_uvm_agent.sh

IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh
```

The agent smoke reports zero UVM warnings/errors/fatals. The generated-name
smoke reports zero UVM errors/fatals and the expected single `AHB_QVIP_CVG`
warning because licensed internal QVIP covergroups are not recreated. Icarus
also emits the existing mixed-timescale and UVMF-lite `eval_object_select`
compile warnings. The standalone AHB manager regression passes its INCR burst,
wait-state, and ERROR checks under the same guard.

The agent smoke was extended with a partial burst at the end of the bounded
memory window: one write beat completes, the next returns ERROR, and two later
beats remain unissued. The latest guarded rerun exited 0 with zero UVM
warnings/errors/fatals and 75% minimum free memory. It verified a two-entry
monitor queue with `OKAY` then `ERROR`, while preserving the original four-beat
write queue in the driver item.

SHA-256 for the follow-up source set:

```text
520933e2b42ba6f2e5e58e1c5be3f48088e50823045c9cdba2c4700e30d57061  dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_master.sv
e97eecb2f695ae9af551722318eb46dae5ae9ec11181109ca159178dd36bbf08  dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_monitor.sv
65e0dc8e99d9d08ea20e2e4a74214111d550a3fdca7b347cd09f9a5e503b9336  dv/caliptra_bfm/uvm/ahb_lite_caliptra_master_cmd_if.sv
3ed7ab5c13e591a07ee121297a26a68d6932fd406cc9fbfe34648c3f0c146df5  dv/caliptra_bfm/uvm/ahb_lite_caliptra_pin_monitor_adapter.sv
93e44ec9c61dbdd60b5ec92db8c9314cd3344209a21673f87acb016ab26c49cd  dv/caliptra_bfm/uvm/ahb_lite_caliptra_record_if.sv
784d91e6e6c33985272f4c8a10de46da74f9b3770c2ff24dc5da239b09d0ab2c  dv/caliptra_bfm/uvm/ahb_lite_caliptra_uvm_master_proxy.sv
d0ea58340867aad8e1662e660d700d6bbe3320caaa2ee2cb98e6acd505dbbe73  dv/caliptra_bfm/uvm/ahb_lite_caliptra_uvm_pkg.sv
f1c8eb54a5bfc8ae939122abe7c251f4024ab35fef2f832d3a9a1115423b89ba  dv/caliptra_bfm/uvm/tests/tb_ahb_lite_caliptra_uvm_agent.sv
bf204a8dc230e0354c70564be0c27dac054341bc428afdebbf585c89bbee1e96  dv/caliptra_bfm/uvm/tests/tb_ahb_qvip_compat_env.sv
```

## Adams Bridge 32-bit profile follow-up (2026-10-06)

The generated-name smoke now accepts `AHB_PROFILE=32` and instantiates its
synthetic target at the selected AHB width. Guarded 32-bit and default 64-bit
runs both exited 0 with the expected `AHB_QVIP_CVG` warning, zero UVM errors,
and zero fatals. The 32-bit run checks word-sized four-beat writes and reads
through the UVM MVC driver and analysis streams. Both runs used Icarus 13.0
development build `9bd5082b8` with UVM support; the memory guard observed 70%
minimum free memory against its 60% floor.

```sh
AHB_PROFILE=32 dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh
AHB_PROFILE=64 dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh
```

SHA-256 for the updated profile smoke:

```text
23fdf5b5aca936e33a5b6f2283d4678b4a45e602294838ebab21127ea9a2aa16  dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh
edc96b1e2271bca273ad7b4a2dc41c8e9d9007a377ba369cde63eba304b8a1e0  dv/caliptra_bfm/uvm/tests/tb_ahb_qvip_compat_env.sv
```

## Generated Adams Bridge MLDSA environment compile and RTL smoke (2026-10-06)

`tests/run_adams_mldsa_env_compile.py` compiles the pinned generated MLDSA
configuration, predictor, scoreboard, environment, and RAL package against the
clean-room provider at Adams Bridge commit
`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. It makes Icarus-specific source
adjustments only in a disposable overlay. The package-only guarded run exited
0 with one existing covergroup-stub warning and 72% minimum free memory
against the 60% floor.

With `--actual-rtl-smoke`, the runner also compiles the generated `hdl_top` and
pinned `abr_top` RTL, starts the real generated environment, writes one seed
`MLDSA_SEED[0]` at `0x58` and reads `MLDSA_VERSION[0]` at `0x8` through the
generated RAL frontdoor. Both transfers returned `UVM_IS_OK`; the read returned
`0x302e322e`, matching `MLDSA_CORE_VERSION[31:0]`. UVM reported zero errors,
fatals, or scoreboard mismatches. The generated predictor and scoreboard skip
version-register comparisons, so this proves the generated RAL read/write
paths and a clean scoreboard run; it does not qualify MLDSA signing/KATs, error
cases, or full generated-top DV.
The guarded runtime exited 0 with one expected QVIP covergroup warning and
73% minimum free memory against the 60% floor.

The disposable runtime overlay sets the ten generated RAL maps to little
endian, binds predictor/scoreboard transaction declarations to the clean-room
generated-item alias, and constructs the predictor's parameterized output item
directly. These Icarus compatibility edits leave the pinned Adams Bridge
checkout unchanged.

The runner also includes `--actual-keygen-smoke`: it builds the pinned native
MLDSA helper in its disposable directory, writes a full 32-byte seed through
RAL, observes actual `abr_top.busy_o` with a 500,000-cycle watchdog, checks
READY/VALID, and reads one word each from the public and private key memories.
This path is **not qualified yet**. A 600-second RTL attempt produced the
predictor's keygen files but timed out while polling status through AHB; minimum
free memory was 63%. The revised busy-signal harness passes `--compile-only`
against the actual-RTL file list at 67% minimum free memory. Its VVP runtime
timed out at the 600-second default with 69% minimum free memory. A direct
guarded rerun of that compiled VVP started the generated test, issued the
seed/CTRL operations, and logged the predictor keygen launch at 465,000 ns.
The unchanged 60% guard then stopped it at 59% free memory before key
readback; no keygen scoreboard result is claimed. The earlier
`--actual-rtl-smoke` run remains the passing generated RAL seed/version probe;
the updated shared runner has not been rerun in that mode.
The next keygen runtime attempt will flush a compact busy-signal trace to
`keygen_progress.log` every 10,000 observed cycles; this progress logging
compiles but has not yet been runtime-verified.

```sh
python3 dv/caliptra_bfm/uvm/tests/run_adams_mldsa_env_compile.py \
  --adamsbridge-root "$ADAMSBRIDGE_ROOT" --iverilog "$IVERILOG_BIN"
python3 dv/caliptra_bfm/uvm/tests/run_adams_mldsa_env_compile.py \
  --adamsbridge-root "$ADAMSBRIDGE_ROOT" --iverilog "$IVERILOG_BIN" \
  --vvp "$VVP_BIN" --actual-rtl-smoke
python3 dv/caliptra_bfm/uvm/tests/run_adams_mldsa_env_compile.py \
  --adamsbridge-root "$ADAMSBRIDGE_ROOT" --iverilog "$IVERILOG_BIN" \
  --vvp "$VVP_BIN" --actual-keygen-smoke
python3 dv/caliptra_bfm/uvm/tests/run_adams_mldsa_env_compile.py \
  --adamsbridge-root "$ADAMSBRIDGE_ROOT" --iverilog "$IVERILOG_BIN" \
  --actual-keygen-smoke --compile-only
```

The run used Icarus 13.0 development build `9bd5082b8` with UVM support.
SHA-256 for the runner:

```text
9f2517ae91c0db06d4b19907ec3ee94e12198c3eadd706154f17d20f959c96ba  dv/caliptra_bfm/uvm/tests/run_adams_mldsa_env_compile.py
```
