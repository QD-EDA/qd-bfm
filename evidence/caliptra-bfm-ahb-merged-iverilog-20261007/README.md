# Caliptra ECC AHB BFM on merged Icarus — 2026-10-07

## Result

The native Caliptra AHB manager, checker, and passive monitor passed against
the pinned `ecc_top` RTL in IEEE 2012, 2017, and 2023 modes using the binaries
built after the Icarus-UVM `origin/main` merge. Each run wrote `1` to the ECC
interrupt-enable register at `0x804`, read it back, and checked exactly two
completed AHB transfers with no checker or monitor protocol errors. All three
runs printed the pass marker and finished normally; logs are preserved beside
this report.

The RAM guard used a 40% free-memory floor. Minimum observed free memory was
54% for IEEE 2012 and 2017, and 53% for IEEE 2023. No compiler/runtime warning
was emitted in these focused runs.

This is actual ECC block-level AHB BFM evidence. It does not qualify all AHB
addresses, reset-abort behavior, a generated UVMF environment, or the full
Caliptra top.

## Reproduction

From the QD-BFM repository root:

```sh
for edition in 2012 2017 2023; do
  env CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
    CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
    CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
    SV_EDITION="$edition" \
    IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
    VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
    dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ecc_ahb_bfm.sh
done
```

Caliptra v2.1.2 is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
The simulator binaries report Icarus Verilog 13.0 (devel), source merge
`ac4532fab037e91df2f903e67fb40f59baedccca`, merging `origin/main`
`197f9baece79e66d25524906fb7b54c9faa8f4e2`. The exact binary, RTL, harness,
and BFM source hashes are recorded in [`result.json`](result.json).
