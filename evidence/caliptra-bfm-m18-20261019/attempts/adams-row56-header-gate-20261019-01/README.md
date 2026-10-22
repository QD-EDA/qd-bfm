# M18 Adams Bridge row 56 header-overlay pre-fix attempt — BLOCKED

Job 3018 applied the ML-DSA config-header/filelist overlay but stopped before simulation because the pinned filelist referenced nonexistent `src/abr_libs/rtl/abr_piso_4.sv` (compile exit 1). Remote source inspection found only `abr_piso.sv` and `abr_piso_multi.sv`, and no `abr_piso_4` module use. The exact stale entry is removed by the follow-up overlay gate in `adams-row56-header-gate-20261019-02`.

The raw archive SHA-256 `9e50f06dd385fe10f607c08047349b9306fba057752b612f1e0be65663b4a2fc` matches the remote sidecar.
