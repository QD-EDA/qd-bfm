# Environment matrix overlays

Apply a listed patch only to a disposable source archive before compilation:
`apply.sh STAGED_SOURCE_ROOT PATCH.patch`. The helper rejects Git checkouts and
checks that the patch applies before changing the staged copy. Each file fixes
one documented compatibility issue; no test vector or expected value is
fabricated. The pkdecode address cast is a QD-side workaround for known c339
issue #539 and does not modify the pinned checkout.

| Patch | One-line justification | Environment row(s) | Evidence |
|---|---|---|---|
| `csrng-package-order.patch` | Compile the pinned RAM package before its first importer. | `caliptra-v2-1-2-csrng_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-csrng-fix/` |
| `csrng-generated-reg-include.patch` | Add the pinned generated register-header directory to the CSRNG include path. | `caliptra-v2-1-2-csrng_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-csrng-fix/` |
| `adams-legacy-width-alias.patch` | Map the stale MLDSA width name to the equivalent pinned Adams Bridge width. | Adams `decompose`, `norm_check`, `pkdecode`, `sigdecode_h`, and `skdecode` rows | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-mldsa-width/` |
| `adams-decompose-drop-stale-port.patch` | Remove the testbench connection to the deleted, unobserved `w1_encode_done` output. | Adams `decompose_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-mldsa-width/` |
| `adams-pkdecode-remove-stale-parameter.patch` | Remove the testbench override for the deleted `MEM_ADDR_WIDTH` parameter. | Adams `pkdecode_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-539-confirmation/` |
| `adams-pkdecode-c339-539-address-cast.patch` | Cast both packed write addresses to their declared member width to avoid known c339 issue #539. | Adams `pkdecode_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-539-confirmation/` |
| `adams-pkdecode-source-base.patch` | Keep the second input vector at address zero because the pinned DUT has no source-base input and reads from zero. | Adams `pkdecode_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-539-confirmation/run-04-pkdecode-src0/` |
| `adams-sigdecode-z-update-call-arity.patch` | Match the test calls to the pinned one-argument task declaration. | Adams `sigdecode_z_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-mldsa-width/` |
| `adams-skencode-drop-stale-port.patch` | Connect the testbench's existing error check to the current DUT error flag. | Adams `skencode_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-mldsa-width/` |
| `adams-compress-filelist-package.patch` | Add the existing `ntt_defines_pkg` dependency before `compress_defines_pkg`. | Adams `compress_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-compress-fix/` |
| `el2-veer-remove-stale-dft-ports.patch` | Drop the four obsolete zero-tied memory DFT packet ports absent from pinned `rvtop`. | Caliptra `el2_veer_wrapper_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/m4-el2-overlay/README.md` (rerun reached pinned c339 elaboration limits). |
| `soc-ifc-assignment-patterns.patch` | Add the required apostrophes to associative-array initializers and struct assignment patterns. | Caliptra `soc_ifc_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-soc-ifc-fix/` (job 474 applied the equivalent cumulative patch; compile reached c339 limits). |
| `soc-ifc-function-return-types.patch` | Declare the existing `lock_fuses` and `unlock_fuses` functions with their required `void` return types. | Caliptra `soc_ifc_tb` | `evidence/caliptra-bfm-environment-matrix-20261011/slurm-soc-ifc-fix/` (job 474 applied the equivalent cumulative patch; compile reached c339 limits). |

For a row with multiple fixes, apply each patch in this order: `csrng_tb` uses
the two CSRNG patches in table order; `decompose_tb` uses the Adams width alias
then the stale-port patch; `pkdecode_tb` uses the width alias, stale-parameter
removal, c339 address cast, and source-base correction; `soc_ifc_tb` uses the
assignment-pattern patch then the function-return-type patch.

## Causes not suitable for a compatibility patch

- Caliptra `caliptra_top_ss_mode_tb` and `caliptra_top_trng_tb`: `axi_if.rst_mgr()` is compiled for the shared interface type and writes fields that those tops continuously drive; removing it globally would break the separate BFM reset-manager instance, while splitting the interface changes its type contract. The c339 compile also reaches the `caliptra_top_tb.sv:138` clock-generator diagnostic tracked by #545; it remains unconfirmed pending a corrected reducer from the actual Caliptra source. Evidence: `evidence/caliptra-bfm-environment-matrix-20261011/slurm-vip-adapter/`.
- Adams tests referencing absent `mldsa_config_defines.svh`: the pinned source archive contains no definition or authoritative replacement, so synthesizing the missing configuration macros would invent upstream configuration. Rows: `abr_sha3_tb`, `abr_top_tb`, `exp_mask_tb`, `mldsa_rej_sampler_tb`, `mlkem_rej_sampler_tb`, `sample_in_ball_tb`.
- Adams `compress_tb`: after its filelist package omission is fixed, its testbench still expects the removed direct-memory write interface while pinned `compress_top` exposes an API read/write bus; adapting the test requires rewriting stimulus and checks, not a semantics-preserving port overlay.
- Caliptra `el2_veer_wrapper_tb`: after removing four stale memory DFT pin connections, its testbench still leaves the wrapper memory-export interfaces uninstantiated; the same compile also hits 22 c339 errors resolving static members through interface continuous assignments, already present in the pinned-only compile. Supplying memory interface models changes the testbench behavior; the simulator elaboration limitation cannot be fixed in this QD overlay. Evidence: `evidence/caliptra-bfm-environment-matrix-20261011/m4-el2-overlay/README.md`.
- Caliptra `doe_cbc_tb` and Adams `ntt_top_tb`: the pinned inputs are respectively absent and undersized (64 words for a 16,384-word request); there is no pinned expected data from which an overlay can reconstruct valid vectors.
- Caliptra `soc_ifc_tb`: after the two syntax patches above, compilation reaches unsupported random-constraint translation and `$ivl_clocking_sample`, followed by c339 exit 139; completing that repair requires Icarus changes, which are out of scope.
- Adams `ntt_top_masking_tb`: the testbench calls a missing task and connects a removed port as well as using indefinite-width concatenation operands; replacing the test behavior is a port, not a narrow compatibility patch.
- Adams `butterfly_top_tb`, `sigdecode_z_tb`, `sigencode_z_tb`, and `skencode_tb`: the remaining blockers reproduce c339 issues #538/#539 and are simulator defects, not upstream defects to mask in the source.

## Existing c339 PASS accounting

The environment matrix currently records 19 PASS rows: 15 pinned-only and 4
with-overlay. The with-overlay PASS rows are `caliptra-v2-1-2-csrng_tb`,
`adams-bridge-v2-0-3-decompose_tb`, `adams-bridge-v2-0-3-norm_check_tb`, and
`adams-bridge-v2-0-3-pkdecode_tb`; their run-local patch evidence is linked in
the matrix CSV. The pkdecode pass also used a run-local mismatch counter and
pass marker around its existing comparisons; it added no expected data. The
other 15 PASS rows use pinned filelists and sources. Overlay attempts that did
not pass are not included in either PASS count.
