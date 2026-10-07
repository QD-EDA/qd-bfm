# Caliptra BFM Phase 0 source inventory — 2026-10-03

## Scope and provenance

This is a read-only source census of Caliptra v2.1.2 at
<code>49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e</code> and its Adams Bridge v2.0.3
submodule at <code>b77e3d899e828d626cfc2a0d26a6b5704cc121e0</code>. Both input checkouts
were clean during the scan. The generated, line-addressable manifest is
[caliptra_bfm_consumer_manifest_2026-10-03.json](caliptra_bfm_consumer_manifest_2026-10-03.json);
regenerate it with:

    python3 scripts/caliptra_bfm_consumer_manifest.py \
      --caliptra-root /path/to/caliptra-rtl \
      --adams-root /path/to/caliptra-rtl/submodules/adams-bridge \
      --unit-census-json /path/to/unit-census-results.json \
      --output docs/conformance/caliptra_bfm_consumer_manifest_2026-10-03.json

The standard-library-only generator is included in this QD-BFM checkout. It
records Git revisions and file hashes, and reads sources without modifying
either checkout. A 2026-10-06 replay regenerated the tracked manifest from the
pinned Caliptra/Adams Bridge roots and frozen unit census. Generator
SHA-256: `ee8af1ab8ae47b71ce25e36d1ff3fc21cd352d5a1d716a29e38f51f8c483f248`.

| Pinned tree | Test YAML under stimulus/tests | Generated UVMF test YAML | stimulus/testsuites files | Frozen census filelists |
| --- | ---: | ---: | ---: | ---: |
| Caliptra | 35 | 22 | 27 | 17 |
| Adams Bridge | 22 | 30 | 2 | 27 |
| Total | 57 | 52 | 29 | 44 |

The 44-filelist denominator is sourced entry-by-entry from the frozen Icarus
census. It includes Caliptra's caliptra_top_tb.vf and excludes Adams Bridge's
ntt_utb.vf; a filename glob would produce the wrong 16/28 split. Counts do not
mean the tests pass or that all filelists are usable on Icarus. A prior frozen report
records 293 test definitions and 33 regression lists. Those totals count a
different inventory and are not reconciled by the directory-level file
filters above; the manifest retains the individual test, suite, filelist, and
suite-path references so that discrepancy can be traced before using those
larger totals as a requirement denominator.

For each of the 44 filelists, the manifest records provider variables, raw
include roots and defines, other compile options, direct HDL-reference count,
visible package imports, DPI imports, conditional macros, and symbolic or
absent source references. Caliptra's 17 filelists contain 3,697 direct HDL
references and 398 include-root entries; Adams Bridge's 27 contain 1,420 HDL
references and 150 include-root entries. Neither set contains a `+define+`
directive. The Adams Bridge scan found five source paths absent from the
pinned checkout, repeated in five unit filelists: `abr_piso_4.sv`,
`mldsa_sampler_pkg.sv`, `mldsa_config_defines.svh`, `mldsa_params_pkg.sv`, and
`mldsa_reg_pkg.sv`. These are source-path findings, not proof that every
listed unit requires each file. Runtime plusargs are not captured by the
compile-only census; the manifest marks that gap instead of treating it as an
empty set. Package/DPI/macro matches are textual evidence, not compiler
resolution.

### Adams Bridge legacy ML-DSA filelist drift

Git history shows these are stale filelist paths, not files omitted from the
checkout by sparse cloning. In the pinned v2.0.3 tree, `abr_piso_4.sv` was
renamed to `abr_piso_multi.sv` at `7b0417e`; no RTL outside filelists
instantiates the old module. At `0a45a69`, the four ML-DSA source paths were
renamed into the ABR tree:

| Stale filelist path | Current path in v2.0.3 |
| --- | --- |
| `src/mldsa_sampler_top/rtl/mldsa_sampler_pkg.sv` | `src/abr_sampler_top/rtl/abr_sampler_pkg.sv` |
| `src/mldsa_top/rtl/mldsa_config_defines.svh` | `src/abr_top/rtl/abr_config_defines.svh` |
| `src/mldsa_top/rtl/mldsa_params_pkg.sv` | `src/abr_top/rtl/abr_params_pkg.sv` |
| `src/mldsa_top/rtl/mldsa_reg_pkg.sv` | `src/abr_top/rtl/abr_reg_pkg.sv` |

The five affected test filelists and their testbenches still refer to the old
paths and, for package imports/includes, old ML-DSA identifiers. Replacing only
the paths is therefore insufficient to make this lane compile against the
pinned release. Keep it classified as stale source setup until a narrowly
scoped, hash-guarded compatibility overlay is justified; do not count it as an
AHB BFM failure or claim Adams Bridge ML-DSA qualification.

The manifest carries the frozen compile-only outcome for each filelist: 20
pass, 6 fail, 17 setup, and 1 unsupported. Its source inventory hash and
census artifact hash are retained. This evidence is a prior classification,
not a fresh compile under the current BFM branch or a runtime qualification.

## Direct consumer findings

| Environment | Evidence from pinned sources | Replacement contract indicated |
| --- | --- | --- |
| Caliptra SoC-IFC | <code>soc_ifc_environment.yaml</code> names an active <code>dummy_avery_aaxi_agent</code>, creates a <code>qvip_ahb_lite_slave</code> subenvironment, and connects its <code>burst_transfer</code> stream to the predictor. The associated <code>avery_aaxi_interface.yaml</code> has only a one-bit <code>fixme_hshake</code> port. | A real Avery AXI pin-level producer is **not proven** by the dummy interface schema. The BFM has a lower-bound AAXI sequencer/driver, USER-aware RAL adapter, predictor exports, and all four observed manager analysis port names. Focused UVM smoke sends RAL read/write traffic through the AAXI-style driver and predicts from completed monitor records. A generated-path `aaxi_tb.env0.master[0]` hierarchy smoke checks `driver.cfg_info`, sequencer/completion ports, and write/read traffic through Caliptra's `axi_if` and open SRAM target. The generated SoC-IFC environment runtime now compiles the generated packages/top and actual `soc_ifc_top`, runs the generated power-on sequence, and passes a host AAXI write/read at `0x30048` with zero UVM errors/fatals ([runtime evidence](../../evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md)). This is a bounded reset/power-on and one AXI-pair qualification, using hash-guarded disposable Icarus compatibility overlays; full generated test-suite/coverage behavior is open. A separate static `hdl_top` compile covers seven generated interface/driver/monitor BFM sets, open AHB/AAXI sources, and the DMA target, with compile-only proxy declarations and reset/Avery/coverage stubs ([compile evidence](../../evidence/caliptra-bfm-soc-ifc-generated-hdl-20261004/README.md)). The fallback AAXI signal interface is driven by the open manager and sampled by the profile checker and pin monitor, which publishes complete records after B/final R. The bounded generated-environment runtime exercises `intf_uc` through the generated `ports` handoff to `master[0].driver` for one host AXI pair; Avery's exact partial-item lifecycle/event timing, complete register-predictor integration, and agent configuration remain open. For AHB, the native monitor publishes the observed keyed streams, and a clean-room <code>mvc_sequencer</code>/bounded MVC burst driver and grouped monitor plus scalar RAL adapter exercise the directed manager. A generated-name QVIP configuration/environment shim exposes the observed setup and analysis-port API. A clean-room `hdl_qvip_ahb_lite_slave` replacement preserves generated module/internal wire names and registers local record/command interfaces; generated-style active/passive smoke passes with synthetic target traffic in Icarus 2012/2017/2023. Actual SoC-IFC smoke has standalone and UVM-enabled modes. Both write/read `CPTRA_MBOX_VALID_AXI_USER[0]` through <code>soc_ifc_top.s_axi_if</code> at host address <code>0x30048</code>; UVM mode drives through generated-name <code>aaxi_monitor_wrapper</code>/<code>aaxi_uvm_testbench</code> and checks completed pin records. Both then use the open AHB manager to program actual DMA registers and verify its AXI read/write copy plus status read through the open SRAM/FIFO target; a second run injects target <code>SLVERR</code> and verifies SoC-IFC status reaches <code>DMA_ERROR</code>. The UVM-enabled DMA run passes in IEEE 2012 with zero UVM warnings/errors/fatals. A hash-guarded overlay also replaces generated <code>hdl_top</code>'s zero-tied DMA manager response with the typed open target; overlay generation and typed 256-beat <code>axi_if</code> smoke pass. Full MVC semantics, proprietary sidebands, policy, and coverage behavior remain open. |
| Caliptra top | The top UVMF environment nests SoC-IFC; the top bench marks its nested QVIP AHB instance <code>PASSIVE</code>. SoC-IFC and top filelists include Avery AXI and <code>Axi4PC.sv</code>. | Top-level AHB use is observation of DUT traffic, not an active response memory. The current Caliptra AXI profile checker is useful but is not the ARM Axi4PC assertion set. |
| Caliptra PCRVault | <code>pv_environment.yaml</code> configures the QVIP AHB-Lite slave subenvironment; generated code connects <code>ap["burst_transfer"]</code> to the predictor and maps the QVIP sequencer through a register adapter/predictor. | The open monitor publishes the consumer-observed transaction fields. The native keyed wrapper, lower-bound <code>mvc_sequencer</code>, bounded MVC burst driver/monitor, scalar RAL adapter, and generated-name config/environment shim exist. The focused synthetic-target UVM smoke verifies four-beat read/write, first-beat abort, and partial one-success/one-error burst responses through all three keyed streams, and the generated-name active/passive smoke also passes four-beat traffic. The pinned generated PV hdl_top/hvl_top and pv_rand_wr_rd_test run against actual PV RTL through this replacement in IEEE 2017 with zero UVM errors/fatals and 768 warnings under the documented Icarus overlays. Full burst-predictor semantics, licensed QVIP lifecycle, and top-level qualification remain open. |
| Caliptra KeyVault | <code>kv_environment.yaml</code>, its generated environment/configuration, and scoreboard/predictor YAML use the same QVIP AHB-Lite subenvironment and <code>ahb_master_burst_transfer</code> type. | The open monitor publishes the consumer-observed transaction fields. The native keyed wrapper, lower-bound <code>mvc_sequencer</code>, bounded MVC burst driver/monitor, scalar RAL adapter, and generated-name config/environment shim exist. The synthetic-target UVM smoke verifies the bounded burst queue path; full generated KeyVault predictor behavior for multi-beat items remains open. The pinned generated KV <code>hdl_top</code>, reset/read/write interfaces, actual KV RTL, and replacement AHB shell elaborate under 2017/2023. The generated <code>hvl_top</code> and <code>kv_rand_wr_rd_test</code> pass under IEEE 2017 and 2023 with zero UVM errors/fatals after a hash-guarded Icarus overlay yields one delta after read capture; the 2023 replay preserves 68,229 UVM warnings. A pin/model trace shows the read monitor publishing before the write monitor's one-clock-delayed predictor update; the delta shim resolves that event-order race without advancing simulation time. This qualifies the block test with the local overlay, not licensed full UVMF/QVIP or the full Caliptra top. |
| Adams Bridge ML-DSA top | <code>src/abr_top/uvmf/mldsa_environment.yaml</code> declares <code>qvip_ahb_lite_slave</code> and routes <code>burst_transfer</code> to its predictor. It also declares <code>trans_ap</code> with the comment <code>Assuming a placeholder key</code>. The checked-in generated <code>mldsa_environment.svh</code> omits that placeholder and connects <code>burst_transfer</code> to the predictor and <code>burst_transfer_sb</code> to the scoreboard; no generated source references <code>trans_ap</code>. The predictor/scoreboard cast the parameterized item type and use <code>RnW</code>, <code>address</code>, <code>data[0][31:0]</code>, <code>resp[0]</code> (diagnostic), and <code>convert2string()</code>. | The AHB wire agent and generated-name config/environment shim expose the observed keys and item fields, along with the lower-bound <code>mvc_sequencer</code>, bounded MVC burst driver/monitor, and scalar RAL adapter. The placeholder does not require a synthetic output. Exact QVIP parameter specialization remains unverified, and the pinned Adams generated top has not been compiled or run with the replacement. No Avery AXI or Axi4PC references were found in this pinned tree's source scan. |
| ECC, HMAC, SHA-512 block filelists | Their UVMF .vf files include the common QVIP AHB wrapper/package filelist. A direct generated <code>qvip_ahb_lite_slave_subenv</code> instantiation was not found in the corresponding environment sources. | Treat this as a compile-time package dependency, not proof that each block consumes the QVIP agent at runtime. The manifest preserves these package references without inflating the active-consumer list. For ECC, generated packages, interfaces, environment, sequence/test classes, and agent proxies now compile/run in focused probes. Actual <code>hdl_top</code> plus ECC RTL compiles only after a temporary modport/timescale overlay. A hash-guarded monitor overlay passes the generated reset-only <code>hdl_top</code>/<code>hvl_top</code> runtime probe in IEEE 2017/2023 after 250 clocks, with exactly one expected/actual match and zero UVM errors/fatals. The Apache-licensed C vector generator builds natively against host Mbed TLS, and a generated keygen transaction completes under IEEE 2017 and 2023 at 717,997 clocks with predicted-vector matches and zero UVM errors/fatals; minimum free memory was 59% against the 50% guard floor. Bounded 1,000- and 10,000-clock traces confirm the AHB driver handshakes seed/nonce/IV/control writes and polls status with <code>HREADY</code>/<code>HREADYOUT</code> high. HMAC-DRBG completes by the 6,000-clock checkpoint and the point-multiplication program and Montgomery counters advance by 10,000 clocks, with all three KV clients ready. This rules out an AHB handshake stall and shows active ECC computation in the diagnostic window, and the 1,200,000-clock IEEE 2017 run now scores the generated keygen result. See <code>evidence/caliptra-bfm-generated-ecc-*</code>. |

### APB references

The manifest records APB5 source and filelist references, but inspection of
the pinned Caliptra v2.1.2 generated top, environment YAML, and PCRVault and
KeyVault predictor/scoreboard YAML shows the relevant APB instantiations and
connections commented out. The only <code>apb_slv_sif</code> hit is its module
definition, with no instantiation in the scanned source tree. APB is therefore
not part of the current active BFM requirement set; revisit if a maintained
Caliptra test configuration enables those paths.

The visible SoC-IFC <code>aaxi_master_tr</code> references include <code>addr</code>,
<code>kind</code>, <code>resp</code>, <code>data</code>, <code>beatQ</code>, <code>awuser</code>, <code>aruser</code>,
<code>is_write()</code>, <code>is_read()</code>, <code>copy()</code>, and <code>sprint()</code>. The scoreboard
additionally calls <code>compare(...)</code> and <code>convert2string()</code> and uses
transaction casts/queues. These are a lower bound: the Avery type and the base
register adapter/predictor implementation are not in the pinned Caliptra
sources, so inherited fields, methods, comparison ordering, and full
manager-monitor event timing are unverified.

The observed QVIP AHB transaction is
<code>ahb_master_burst_transfer #(NUM_MASTERS, MASTER_BITS, NUM_SLAVES,
ADDRESS_WIDTH, WDATA_WIDTH, RDATA_WIDTH)</code>. The output API is addressed by
the exact <code>"burst_transfer"</code> string key. The clean-room lower-bound
item implements only the visible direction/address/size/data/response fields
and copy/compare/string operations. The native monitor retains per-beat records
and groups contiguous accepted SEQ beats with matching direction and size into
bounded queue items, ending at an accepted IDLE/NONSEQ boundary or after 256
beats. Since Caliptra's reduced bus interface omits HBURST, the item boundary
is inferred from accepted address phases. The MVC driver now carries up to 256
beats through the manager. Focused Icarus 2012 synthetic-target smokes verify a
four-beat write/read, first-beat ERROR abort, preserved unissued read data, and
grouped active/passive generated-name streams. The clean-room configuration
and generated-name environment wrapper compile in the pinned generated
PCRVault, KeyVault, and SoC-IFC environments. The recorded PCRVault and KeyVault
block tests exercise scalar AHB RAL traffic against the actual block RTL. The
SoC-IFC runtime qualifies generated reset/power-on and AAXI traffic plus a
generated AHB mailbox-lock claim read and MBOX_DLEN write/readback through the
active manager. A separate generated AHB RAL lane sends a four-word mailbox
request through MBOX_CMD, MBOX_DLEN, MBOX_DATAIN, and MBOX_EXECUTE; the open SRAM
target verifies the words, including single-bit injection behavior. This
remains a narrow AHB sequence qualification. See the [PCRVault](../../evidence/caliptra-bfm-pv-generated-uvmf-20261004/README.md),
[KeyVault](../../evidence/caliptra-bfm-keyvault-generated-hdl-20261004/README.md),
and [SoC-IFC](../../evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md)
evidence. These probes do not qualify the licensed QVIP lifecycle or provide
its full class methods, burst policy, generated pin BFM, or coverage/sequence
implementation.

The visible Caliptra predictor field reads are <code>RnW</code>, <code>address</code>,
<code>size</code>, <code>data[0]</code>, and <code>resp[0]</code> in SoC-IFC, and
<code>RnW</code>, <code>address</code>, and <code>data[0]</code> in PCRVault/KeyVault.
The open projection covers these fields and the observed copy/compare/string
calls. It does not establish the official constructor, all array semantics,
QVIP's response sampling, or all scoreboard/API methods.

## License and reuse decisions

| Source | Finding | Decision |
| --- | --- | --- |
| Caliptra and Adams Bridge consumer code | Pinned repositories carry Apache-2.0 licensing. | Read for interface discovery; this work does not modify the pinned clones. |
| QD-EDA qd-bfm single-beat helper | Apache-2.0 source already copied with its notice and provenance under <code>dv/caliptra_bfm/axi/</code>. | Reuse only for its bounded, directed helper role; it is not the required transaction/monitor/UVM stack. |
| CHIPS Alliance axi-vip (historically associated with WD) | The clean, pinned ISC checkout is `16d0f444299014b2079c941925ea8b43d85a13f7`. Its interface lacks LOCK, defaults to a 32-byte bus/4-bit USER rather than Caliptra's 4-byte bus/32-bit USER, and stores address/ID as `int unsigned`. Reproduced Icarus-fork probes fail at the UVM static `set_server` call, then at an impure constraint helper and runtime-selected clocking drives in the isolated compile probe; details and file hashes are in the research note. | Keep as a licensed reference candidate, not a Caliptra drop-in. The local Icarus failures do not establish incompatibility with VCS or Questa. No source was copied. |
| User-linked muneeb-mbytes/UVMF mirror | Root lists UVM_Framework/, README.md, make_filelist.py, and yaml2uvmf.py. A recursive tree scan found license files only for bundled Python dependencies, not the framework. | No source copying or vendoring until the framework's license terms are established. |
| Official QVIP, Avery AXI VIP, ARM Axi4PC | Caliptra documents them as required external inputs; their implementation sources are absent from the pinned checkout and are licensed products. | Recreate only the observable consumer contract, clean-room. Do not claim source/API equivalence beyond observed use. |

The currently linked UVMF mirror claims to be an open-source framework in its
README, but the recursive repository tree exposes no framework license. The
visible licenses cover bundled Python dependencies only; that is not enough to
establish a redistribution grant. The public Caliptra README names the UVMF,
QVIP, Avery, and Axi4PC inputs explicitly. [UVMF mirror](https://github.com/muneeb-mbytes/UVMF),
[Caliptra verification prerequisites](https://github.com/chipsalliance/caliptra-rtl).

## Still open in Phase 0

- Reconcile the legacy 293-test / 33-regression counts against the frozen
  inventory and this enumerated source tree.
- Complete the 44-unit dependency map: resolve symbolic/provider paths and
  absent references, inspect nested filelists and test-level plusargs, and
  connect visible package/DPI use to the exact providers and runtime results.
- Complete a method/arity/override-point inventory of the consumed UVMF base
  API, plusargs, macros, and generated start-up order.
- Establish permissible UVMF redistribution/read terms or finish the
  clean-room minimum base-layer boundary.
- Resolve QVIP <code>burst_transfer</code> item lifecycle/configuration semantics and the
  Avery transaction producer lifecycle using an authorized implementation or
  additional vendor documentation.

Until those are resolved, Phase 0 is **partially complete**, the clean-room
protocol slices remain component-qualified only, and no official Caliptra or
Adams Bridge UVMF regression is claimed.
