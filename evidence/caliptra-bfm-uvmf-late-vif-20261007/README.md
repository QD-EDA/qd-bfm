# UVMF late BFM registration smoke — 2026-10-07

## Result

The active/passive toy-agent smoke initializes the environment and agent
configurations before publishing the canonical `UVMF_VIRTUAL_INTERFACES`
keys. The agent base resolves its typed driver/monitor BFMs during agent
build.

The isolated IEEE 1800-2017 run passed its positive case and mismatch control:

- Positive: one expected and one actual transaction matched; zero UVM errors
  or fatals.
- Negative control: one intentional `UVMF_SB_MISMATCH`; exactly one UVM error
  and zero fatals.
- Both cases reached the agent smoke `PASS` checkpoint.

IEEE 1800-2023 and registration after agent build remain unverified. The
generated ECC runtime was not exercised in this run.

## Reproduction

From the QD-EDA/qd-bfm repository root:

```sh
UVMF_IEEE_EDITION=2017 \
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
./dv/caliptra_bfm/uvmf_lite/tests/run_uvmf_agent.sh
```

The compiler reported a mixed-timescale warning and seven `eval_object_select`
null-fallback warnings in `uvmf_base_pkg.sv`; the smoke still reached its
positive and negative control checkpoints.

## Tool and source fingerprints

- QD-EDA/qd-bfm commit: `33e68dec9ea9268c9d28926e732de504f6e68991`
- Icarus source checkout: `ac4532fab037e91df2f903e67fb40f59baedccca`
- Merged Icarus `origin/main`: `fc9d8b86ca21b6c4852e09c605555f0c1631d544`
- `iverilog -V`: `13.0 (devel) (ac4532fa-dirty)`
- `vvp -V`: `13.0 (devel) (ac4532fa-dirty)`
- Accellera `uvm-core`: `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`

| Input | SHA-256 |
| --- | --- |
| `bin/iverilog` | `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114` |
| `bin/vvp` | `4bf80d6d22b44c22d518514c2f98f1f3fd485d77ba7c63bc97e68770d58b2867` |
| `lib/ivl/ivl` | `e532e050c126b0c1db8287ffdcd8afe22188e1585610b77f0ca625b5a1bc20c1` |
| `lib/ivl/ivlpp` | `edbeb86a150a12926e31a898902c087bab615cdf0c61af88eb961f0a5bac7771` |
| `lib/ivl/vvp.tgt` | `d00ca9e58ef269a7d112c7230816386dc195cae5a56c564ff084610db3190141` |
| `dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv` | `ab7ca7b16eb3e88f4f8cb35ff4356f5306b5fbacd3774b0cbf38e32f192285ea` |
| `dv/caliptra_bfm/uvmf_lite/tests/tb_uvmf_agent.sv` | `f8a8577c7ad64fa94c4323082879a04511696305566f011b27d1c205d0403b17` |
| `dv/caliptra_bfm/uvmf_lite/tests/run_uvmf_agent.sh` | `efa7e131492d694d36e4a0e0195070dffdd4550564b3fc081837b85789446f0d` |
