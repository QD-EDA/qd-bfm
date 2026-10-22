# M18 AAXI / SoC-IFC rows 1–4, 43–45 — BLOCKED (array job 3035)

All seven corrected stages compiled against the refreshed Icarus pin and open AAXI/AHB overlays, then stopped before simulation at the same pinned RTL construct: fixed-array wildcard bins in `soc_ifc_reg_covergroups.svh:2055`. The compiler output has subsequent syntax diagnostics (including the generated callback at `soc_ifc_reg_cbs_mbox_csr_mbox_lock_lock.svh:138`); the runner has no `sim.log` for these rows. The intern’s triage matched row 1’s log, and direct inspection confirms the same first diagnostic across all seven `result.json` files.

The one-row row 0 current-main gate hits the same `soc_ifc_reg_covergroups.svh:2055` blocker. These results close the requested eight-row refresh with current-main evidence; they do not indicate an AAXI BFM failure.

Host/toolchain: DAN-DESKTOP, Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Icarus source `cae035642e056644274a01e98d4422ce286685b4`, binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`. The array used a 4-task throttle, one CPU and 4 GiB per task; compile times were under 1.3 seconds.

Each raw archive has a verified SHA-256 sidecar:

- row 1: `604cff6a0bf69d2616c8e379bfe5e78e168fff6f809e502f1f83d68637b087c3`
- row 2: `4a3dba023791fc376297d563e6456aa073b678f191e465b0d3000b7a85f1bfde`
- row 3: `87674447d33b5ee7cb554e70e9d78373ca1ec7c7fc88077d97f955526b96e070`
- row 4: `795185ca9e7d43bcb2661890880d23a9824fb83b083885ae61d4887c63962468`
- row 43: `32ed052a803f32cafbd1984b7614b31e28f89af156ecf9d25eaaa6a8d70e889f`
- row 44: `da199f7352e1deebc93015955b93792ea0e390651fa92916f38763f5c7e957f4`
- row 45: `244d761e393eaaf66e8cc6d906551d5d8e3f957145a3a319b87b5fdcae98a45b`
