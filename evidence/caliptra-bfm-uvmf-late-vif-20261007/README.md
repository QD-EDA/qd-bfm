# UVMF late BFM registration and generated ECC smoke — 2026-10-07

## Result

The toy-agent smoke registers typed BFMs from a later build-phase component,
after both agents complete build. Driver and monitor bases now resolve and
assign their handles in `connect_phase`, then call the generated
`configure()` hook before installing the proxy.

The agent smoke passed in IEEE 1800-2017 and 1800-2023:

- Positive case: one expected/actual transaction matched; zero UVM errors or
  fatals.
- Negative control: exactly one intentional `UVMF_SB_MISMATCH`; one UVM error
  and zero fatals.
- Driver response cloning returned value 42; mutating the response clone did
  not change the request.

The generated ECC reset/IRQ probe passed in IEEE 1800-2017 and 1800-2023. In
both editions the reset scoreboard matched, the generated AHB driver wrote
and read back `ECC_IRQ_EN`, and UVM reported zero errors and fatals.

## Reproduction

From the QD-EDA/qd-bfm repository root, run the agent cases:

```sh
for edition in 2017 2023; do
  UVMF_IEEE_EDITION="$edition" \
  IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
  VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  ./dv/caliptra_bfm/uvmf_lite/tests/run_uvmf_agent.sh || exit
done
```

Run both generated ECC editions with the pinned clean Caliptra checkout:

```sh
ECC_IEEE_EDITION=both \
CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
./dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_reset_monitor.sh
```

## Tool and source fingerprints

- QD-EDA/qd-bfm source commit: `675f8012152b0e0c88c615b6f412466d6dc546fe`
- Caliptra source checkout: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
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
| `dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv` | `b933ec5380706ddebe168d9f839a5aa5a6596a951cfaa053d53471a19c272b17` |
| `dv/caliptra_bfm/uvmf_lite/tests/tb_uvmf_agent.sv` | `721d4b8c197a8ec7562c25cb1cb0a2e28aa0cde63b74880d3c61061790f0110b` |
| `dv/caliptra_bfm/uvmf_lite/tests/run_uvmf_agent.sh` | `efa7e131492d694d36e4a0e0195070dffdd4550564b3fc081837b85789446f0d` |
