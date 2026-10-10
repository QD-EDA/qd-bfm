# AHB QVIP ERROR-tail predictor diagnostic (2026-10-10)

This diagnostic checks the AHB RAL predictor change in QD-EDA/qd-bfm commit
`bbde596890889453230b479f530f6c584eee42bf`. Its synthetic burst has responses
`OKAY, ERROR, OKAY`: the successful prefix updates the mirror, while the error
beat and every later beat leave their prior mirror values intact.

## Result

The guarded `run_ahb_qvip_compat_env.sh` runner passed with both 64-bit and
32-bit AHB profiles. Each run reported `UVM_ERROR : 0` and `UVM_FATAL : 0`;
the single `AHB_QVIP_CVG` warning is expected because internal QVIP covergroups
are not recreated. The memory guard reported maximum process groups of 0.36
GiB (64-bit) and 0.35 GiB (32-bit).

Logs:

- [64-bit profile](logs/ahb-profile-64.log)
- [32-bit profile](logs/ahb-profile-32.log)

## Reproduction and provenance

From the repository root, run:

```sh
IVERILOG_BIN="/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog" \
VVP_BIN="/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp" \
AHB_PROFILE=64 sh dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh

IVERILOG_BIN="/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog" \
VVP_BIN="/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp" \
AHB_PROFILE=32 sh dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh
```

The binaries were read-only inputs from the local `BFM WORK` checkout. Their
version is Icarus Verilog `13.0 (devel) (ac4532fa-dirty)`. SHA-256:

- `iverilog`: `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114`
- `vvp`: `4bf80d6d22b44c22d518514c2f98f1f3fd485d77ba7c63bc97e68770d58b2867`

This is diagnostic evidence only. The simulator revision is dirty and
unpublished, so these results do not qualify the change against a published
Icarus revision.

## Clean published simulator rerun (2026-10-10)

The same guarded runner and QD predictor/test sources from commit `bbde596`
also pass on the clean published Icarus `main` build
`4b3f3424c440aca6af92153b6860a7253b925234`. Both 32-bit and 64-bit AHB
profiles reach the ERROR-tail assertion, report zero UVM errors/fatals, and
show a maximum guarded process group of 0.36 GiB. The one
`AHB_QVIP_CVG` warning is expected. The QD worktree was at `4deb718` with no
changes to the runner or tested source files.

- [Published-main 32-bit log](logs/clean-published-4b3f342-profile-32.log)
- [Published-main 64-bit log](logs/clean-published-4b3f342-profile-64.log)

The executable SHA-256 values match the clean published-main provenance in
[`generated ECC published evidence`](../caliptra-bfm-generated-ecc-published-20261009/README.md):

- `iverilog`: `00a0686a9f0d6962d3e9cd4790464321a608d77efe4db8e50fa02ec7f3f69385`
- `vvp`: `f7b6f7cbb87d60f96914ad1213beab2a359e15cc3a2bcf176190cecb28fdc19a`

This verifies the targeted predictor regression on a clean published
simulator. It does not close generated Caliptra UVMF or full-profile
qualification.
