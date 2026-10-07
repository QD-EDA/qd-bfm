> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated SoC-IFC host-package compile probe — 2026-10-04

This probe attempted to compile the pinned generated `soc_ifc_reg_model_top_pkg`
and `soc_ifc_env_pkg` with the seven generated SoC-IFC interface packages, the
open BFM/UVM compatibility packages, and disposable, hash-guarded Caliptra
source overlays. The pinned Caliptra checkout remained unchanged.

The retained [`run_soc_ifc_env_compile.py`](run_soc_ifc_env_compile.py) runner
automatically applies the macOS memory guard before rebuilding overlays or
starting Icarus. At capture time, the guard capped the process group at 6 GiB
and preserved 6 GiB system-available memory; the current defaults are 4 GB and
6 GB. Set `CALIPTRA_BFM_MAX_PROCESS_BYTES` or
`CALIPTRA_BFM_MIN_AVAILABLE_BYTES` to adjust those limits. The bound is 90
seconds for the host-package compile and 300 seconds for the larger
generated-package/runtime modes. The guard fails closed when macOS memory or
process telemetry is unavailable. Run
it from the `BFM WORK` root with
`IVERILOG_BIN=/path/to/iverilog python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py`.
Wrap any other large build or compile explicitly with
`python3 scripts/run_with_memory_pressure_guard.py --timeout-seconds 300 -- <command>`;
the SoC-IFC runner above wraps itself automatically.

## Latest whole host-package compile

The retained guarded runner now exits 0 while compiling the generated
`soc_ifc_env_pkg` and register-model package with the generated interface
packages, open BFM/UVM compatibility packages, and hash-guarded disposable
overlays. After the AAXI driver began requiring and consuming the generated
`ports` VIF, this package set recompiled with 364 warnings and no hard errors or
unsupported-syntax (`sorry`) diagnostics. The RAM guard started at 81% free and
observed a minimum of 80%; that retained run used a 70% floor. The latest log is
`soc-ifc-env-compile-after-ports-vif.log` (raw artifact omitted from this checkpoint);
its guard telemetry is in
`memory-guard-ports-vif-package.log` (raw artifact omitted from this checkpoint).

This is package compile/elaboration evidence only. It uses Icarus-specific
source adaptations in temporary copies and compile-progress stubs; it does not
establish UVM sequence execution, meaningful generated coverage, full
UVMF-agent behavior, or end-to-end Caliptra DV qualification. The previous
timeout and unreproducible one-off diagnostic logs below remain as history.

## Generated project-bench package compile

The retained runner can also compile the generated `soc_ifc_parameters_pkg`,
`soc_ifc_sequences_pkg`, and `soc_ifc_tests_pkg` packages:

```sh
IVERILOG_BIN=/path/to/iverilog \
  python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py \
    --include-project-bench-packages
```

This captured run used a 6 GiB process-group cap, 6 GiB system reserve, and a
five-minute timeout unless the byte-limit environment variables override them.
It compiles the generated project-bench packages with the host
packages, excluding only the generated command-line test and sequence because
they call `factory.create_object_by_name`, unavailable in this UVM
implementation. [`soc_ifc_generated_cmdline_test_overlay.py`](../../docs/conformance/release_overlays/caliptra/soc_ifc_generated_cmdline_test_overlay.py)
checks both pinned source hashes and writes the disposable replacements;
[`project-bench-overlay-manifest-20261005.json`](project-bench-overlay-manifest-20261005.json)
records the source and output hashes. `QUESTA_MVC` and the unused QVIP memory
message handler are compile-only clean-room import shims. This remains
compile-only evidence; a full generated-environment runtime has not yet been
qualified.

The initial attempt found `ahb_rnw_e` missing from the clean-room AHB MVC/QVIP
surface. That type is now declared in
[`caliptra_ahb_mvc_compat_pkg.sv`](../../dv/caliptra_bfm/uvm/caliptra_ahb_mvc_compat_pkg.sv),
and the generated-name AHB QVIP compatibility smoke passes. The original
whole-filelist compiles were stopped after 180 seconds and 120 seconds. Their
logs ended with filter-limit notices and generated covergroup-stub
`set_inst_name` warnings. Those runs did not return normally and were not
passing compiles.

A separate compile-only probe imports `mgc_ahb_v2_0_pkg::ahb_rnw_e` and
assigns both `AHB_READ` and `AHB_WRITE`; it exits 0.

The 60-second control-package timeout was traced to generated
`soc_ifc_ctrl_transaction_coverage.svh`. Its `generic_input_val` coverpoint has
eight `[0:$]` bins with `with` predicates. The compiler counted candidate
values in `uint64_t`; the full `[0:UINT64_MAX]` span wrapped the count to zero,
skipped the existing 4,096-value guard, and entered an effectively unbounded
enumeration loop.

`elaborate.cc` now checks each span before adding it, and rejects a non-`inside`
`with` filter above the 4,096-value limit with a compile error. This prevents
both the hang and a successful compile that silently drops those bins; it does
not implement arbitrary full-domain `with` coverage. The generated control
package now exits with eight explicit coverage errors in 2.59 seconds. The
permanent `sv_covergroup_with_full_range_limit` regression reproduces the
construct, while `sv_covergroup_with_range_limit` checks that exactly 4,096
candidates remain supported. Both tests run in IEEE 2017 and 2023; the focused
legacy and JSON runners each pass 10/10 tests.

The open BFM-only filelist with an empty selected top still compiles in about
1.5 seconds. One invocation of the larger generated host-package filelist
exited with compiler diagnostics in 1.97 seconds. Its output included
unresolved generated types and macro-visibility errors followed by parse
cascades. The copied package tree, assembled filelist, and diagnostic log were
temporary and were not retained, so those diagnostics have not been
root-caused and this is not a reproducible compile result. A later retained
runner compiled the generated host-package set with hash-guarded overlays; the
generated UVMF runtime and behavior remain unqualified.

An exact source overlay now makes the eight generated `generic_input_val`
bins usable in a bounded Icarus package compile. Each predicate
`$countones(item[byte] > 0)` is equivalent for this 2-state 64-bit field to
the union of eight wildcard masks, each fixing one bit in that byte to 1 and
leaving the other bits as don't-cares. The hash-guarded overlay changes only
the disposable generated coverage file; it leaves the pinned Caliptra source
unchanged. A standalone 64-bit coverage smoke samples all 255 nonzero byte
values in each of the eight positions, checks that isolated-byte samples do
not hit other byte bins, and checks that a two-byte sample hits only its two
corresponding byte bins (along with the zero bin sampled first).

The generated `soc_ifc_ctrl_pkg` reducer compiles with this overlay in about
2.8 seconds. The compile still emits generated covergroup-stub and clean-room
UVMF compile-progress warnings; it proves package elaboration only. The
standalone coverage smoke exits 0 in both the exhaustive per-byte and
two-byte-overlap runs. This overlay does not add generic full-domain `with`
support or qualify the generated coverage class inside UVMF.

A broader source-hash-guarded helper now applies the same exact-mask approach
to the generated 64-bit status byte predicates, the two 32-bit generic-wire
coverpoints, and the mailbox/SHA-512 aligned-length bins. For aligned lengths,
the helper decomposes `[1:32'h8000]` into disjoint wildcard masks while keeping
the original alignment condition. It is an additional disposable-source
overlay; the full generated host-package/UVMF compile is still unqualified.
See [`soc_ifc_host_coverage_wildcard_overlay.py`](../../docs/conformance/release_overlays/caliptra/soc_ifc_host_coverage_wildcard_overlay.py).
The retained pattern verifier checks the pinned input and transformed hashes,
3,320 byte-mask memberships, and 131,088 aligned-range memberships. It is a
bounded Python check of mask generation, not covergroup runtime evidence. Run
it from the `BFM WORK` root with:

```sh
python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/verify-host-coverage-patterns.py
```

A reduced register-model filelist now compiles the pinned generated
`soc_ifc_reg_model_top_pkg` after a hash-guarded overlay adds explicit
`new(string name)` forwarding constructors to 47 factory-registered RAL
classes across 39 generated files. The run exits 0 in about 2.8 seconds with
48 warnings and no hard or unsupported-syntax diagnostics. It uses the
generated RAL package, Caliptra register packages, and open BFM UVM
compatibility packages; generated interface-agent package copies are excluded.
This is package compilation only. It does not run UVM or qualify the complete
generated SoC-IFC environment. The captured filelist names temporary absolute
paths and is retained for audit, not as a portable replay. The
[`constructor overlay manifest`](reg-model-constructor-overlay-manifest.json)
records the pinned register-tree hash, every transformed output hash, and the
compile log/filelist hashes. The pinned Caliptra checkout remains unchanged.

## Captured output

- `compile-no-errors-before-timeout.log` (raw artifact omitted from this checkpoint):
  full host-package filelist, no selected synthetic top.
- `compile-synthetic-top-before-timeout.log` (raw artifact omitted from this checkpoint):
  same filelist with a trivial selected top.
- `compile-single-generated-package-before-timeout.log` (raw artifact omitted from this checkpoint):
  original selected-top probe with the generated control interface package,
  manually stopped after 60 seconds.
- `compile-single-generated-package-after-range-guard.log` (raw artifact omitted from this checkpoint):
  same bounded package probe after the candidate-count fix; it exits with eight
  explicit errors rather than hanging.
- [`ctrl-core-coverage.f.in`](ctrl-core-coverage.f.in) and
  [`replay-control-package.py`](replay-control-package.py): reconstruct the
  bounded control-package reducer from the pinned Caliptra checkout and the
  hash-guarded overlay builder. The replay runner exits 0 only when it sees the
  expected eight controlled coverage errors; the compiler itself exits 8.
- `compile-single-generated-package-replay.log` (raw artifact omitted from this checkpoint):
  output from that retained replay command.
- [`nonzero-byte-wildcard-smoke.sv`](nonzero-byte-wildcard-smoke.sv) and
  [`verify-control-package-wildcard-overlay.py`](verify-control-package-wildcard-overlay.py):
  exercise every nonzero byte value in each 64-bit byte position and a
  multi-byte overlap, then compile the generated control-package reducer
  through the exact overlay.
- `compile-control-package-wildcard-overlay.log` (raw artifact omitted from this checkpoint):
  output from that successful bounded replay. It includes the covergroup-stub
  warnings described above; it is not a generated UVMF runtime.
- `compile-reg-model-constructor-overlay.log` (raw artifact omitted from this checkpoint)
  and [`reg-model-constructor-overlay.captured.f`](reg-model-constructor-overlay.captured.f):
  the reduced RAL package compile's captured output and absolute-path filelist.
- [`reg-model-constructor-overlay-manifest.json`](reg-model-constructor-overlay-manifest.json):
  pinned source-tree and transformed-file hashes plus exact scope and limits.
- [`exact nonzero-byte coverage overlay`](../../docs/conformance/release_overlays/caliptra/soc_ifc_ctrl_nonzero_byte_coverage_overlay.py):
  hash-guarded rewrite for the generated byte predicates.
- [`results.json`](results.json): bounded run outcomes and known limitations.

From the `BFM WORK` root, replay it with:

```sh
IVERILOG_BIN=/path/to/iverilog \
  python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/replay-control-package.py
```

Run the exact wildcard overlay and coverage smoke with the branch's Icarus
fork using:

```sh
IVERILOG_BIN=/path/to/iverilog VVP_BIN=/path/to/vvp \
  python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/verify-control-package-wildcard-overlay.py
```

The runner defaults `CALIPTRA_ROOT` to the sibling `../caliptra-rtl` checkout
and refuses any source revision other than the recorded Caliptra commit.

The generated coverage source hash matches the pinned Caliptra v2.1.2 file.
The compiler source/binary hashes and exact focused runner commands are in
[`results.json`](results.json). The checkout was dirty before this narrow fix;
its existing BFM and Caliptra work remains preserved.
The compiler reducer, control-package filelist template, replay runner, package
shim, and focused test lists are retained. The replay reconstructs the bounded
single-package probe independently. The copied full-package tree, overlays,
and assembled `.f` filelists for the larger host-package probe remain under
`/private/tmp/caliptra-soc-ifc-hostpkg-8hdd96u0` and are not retained, so that
earlier larger probe is not independently replayable from this evidence
directory. The latest guarded compile is replayable through the retained
runner, but it does not qualify the generated UVMF environment.
