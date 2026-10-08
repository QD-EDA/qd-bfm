> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated Caliptra ECC HDL-top and runtime — 2026-10-05

## Result

The pinned generated ECC `hdl_top.sv` does not elaborate unchanged under this
Icarus build. The generated `ECC_in_driver_bfm` writes `hrdata` and
`hreadyout` through `ECC_in_if.initiator_port`, where both are declared as
inputs. Icarus reports those two direction errors under IEEE 2017 and 2023.

A temporary copy of `hdl_top.sv` that removes the three modport selectors on
its monitor and input-driver connections and adds an explicit `1ns/1ps`
timescale elaborates with the actual `ecc_top` RTL, generated ECC
packages/interfaces, environment, sequence/test packages, and the UVMF-lite
base. The timescale is needed for the generated `#5ns` clock delay to advance
under this Icarus invocation. The repeatable probe passes under both IEEE
editions with 35 compile-progress warnings from coverage stubs. The pinned
Caliptra checkout is never modified.

## Scope and limits

The generated top now reaches UVM runtime with the local timescale overlay and
the UVMF-lite base no longer requires a driver BFM for the passive output
agent. The checked-in `ecc_secp384r1.exe` is an x86-64 Linux ELF, but its
Apache-licensed C source builds natively with a host Mbed TLS development
package. The key-generation probe compiles that source into a disposable
directory, runs the generated reset followed by one keygen request, and keeps
the generated vectors and key dump out of the repository. The full 500,000-
clock run did not publish a keygen predictor event; its log is
`keygen_runtime_2017.log` (raw artifact omitted from this checkpoint). The replay source overlay
now ties the generated bench's otherwise-unconnected `cptra_pwrgood` input
high to model a powered ECC block; the retained 500,000-clock log predates
that edit. Source inspection shows this signal only feeds the ECC hard-reset
register input; it is not a keygen datapath gate. A bounded 1,000-clock
follow-up trace accepts the seed, nonce, IV, and control writes, then completes
437 status reads with AHB `HREADY` and `HREADYOUT` high. At the cutoff, the ECC
core reports `busy=1`, `dsa_busy=1`, and `keygen_process=1`; all three KV client
ready signals are high. That rules out an AHB handshake stall during this
window and confirms the keygen command reached the core. A second trace through
10,000 clocks sees HMAC-DRBG complete and the point-multiplication engine
advance: between checkpoints its program counter changes from `0x047` to
`0x070`, and its Montgomery counter decrements from 575 to 572. AHB remains
ready throughout. The protected Montgomery loop count is 576; projecting the
100,000-clock trace's `mont_cntr=497` suggests about 0.6 million additional
clocks for the remaining iterations at that observed pace. This linear estimate
does not include completion phases and is not a result. That early trace did
not yet reach result sampling; the later 512-clock run below scores a complete
keygen transaction under IEEE 2017. Reproduce the 1,000-clock bounded classification with
[`diagnose_keygen_bus.sh`](diagnose_keygen_bus.sh). The earlier runtime attempt
without a native generator is in `runtime_blocker.log` (raw artifact omitted from this checkpoint).

The captured keygen runs used a hash-guarded driver overlay that waited 64
clocks between not-ready status reads. The current replay overlay waits 512
clocks, keeping the same ready-bit condition while reducing status-bus traffic
by up to eight times. With the 512-clock cadence, generated keygen transactions
under IEEE 2017 and 2023 both match their predicted vectors at 717,997 clocks,
with zero UVM errors or fatals. The trace shows `mont_cntr` falling from 498
at 100,000 clocks to 1 at 700,000 clocks; AHB remains ready throughout. The
memory guard's lowest free-memory observation across the two runs was 59%,
above the 50% floor. The passing logs are
`IEEE 2017` (raw artifact omitted from this checkpoint) and
`IEEE 2023` (raw artifact omitted from this checkpoint). A traced
2,500,000-clock run at the earlier cadence reached 100,000 clocks with
`mont_cntr=497` and 155,889 clocks before interruption. It did not
produce a scored result. At 100,000 clocks, AHB was ready and had completed
1,553 transfers, including 1,515 status polls. The partial run is retained in
`keygen_generated_slowpoll_2m5_trace100k_2017.log` (raw artifact omitted from this checkpoint).
A quiet 1,200,000-clock retry started at 53% free memory and was stopped by
the guard when free memory reached 49%, below its 50% floor. That run has no
keygen result and is recorded as a guard stop, not a DUT failure, in
`keygen_full_slowpoll_1m2_2017.log` (raw artifact omitted from this checkpoint).
The reset-only probe first found
that the input monitor republished while the initialization flag was held high
(25 expected records versus one actual record in 50 clocks). Extending the
probe to 250 clocks also exposed a second output record from the reset marker.
A hash-guarded overlay makes the input monitor wait for a fresh low-to-high
completion and makes the output monitor ignore the reset marker before
consuming real operation completions. The actual generated bench now yields
exactly one expected and one actual reset record, with no scoreboard mismatch
and zero UVM errors/fatals under IEEE 2017 and 2023. The overlay changes only
disposable copies; Caliptra's pinned generated source remains untouched. The
original failure log is
`reset_monitor_blocker.log` (raw artifact omitted from this checkpoint), and the passing logs
are `reset_monitor_overlay_2017.log` (raw artifact omitted from this checkpoint) and
`reset_monitor_overlay_2023.log` (raw artifact omitted from this checkpoint).

The runtime probe now continues after that scoreboard check and calls the
generated input driver's `write_single_word` and `read_single_word` tasks at
the ECC interrupt-enable register (`0x804`). The readback is `0x00000001`
from the actual `ecc_top`. This runs through the generated `test_top`, its
active input-agent configuration, and the generated BFM virtual interface
under IEEE 2017 and 2023; each run reports zero UVM errors and fatals. The
probe scores the reset event and checks the CSR readback directly. It does not
qualify a cryptographic operation or its output scoreboard. Current logs are
`generated_ecc_ahb_probe_2017.log` (raw artifact omitted from this checkpoint) and
`generated_ecc_ahb_probe_2023.log` (raw artifact omitted from this checkpoint).

An earlier full keygen attempt ended at its 500,000-clock watchdog. Reproduce
both passing editions with a host C compiler and Mbed TLS
`mbedtls`/`mbedcrypto` pkg-config modules:

```sh
ECC_KEYGEN_WATCHDOG_CLOCKS=1200000 \
ECC_KEYGEN_TRACE_INTERVAL=100000 \
ECC_KEYGEN_LOG_PREFIX=keygen_poll512_1m2_30m_trace100k_rerun \
ECC_KEYGEN_MIN_FREE_PERCENT=50 \
ECC_KEYGEN_TIMEOUT_SECONDS=1800 \
ECC_KEYGEN_TOP_SOURCE=evidence/caliptra-bfm-generated-ecc-hdl-20261004/top_keygen_diagnostic_probe.sv \
CC=/usr/bin/clang \
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  evidence/caliptra-bfm-generated-ecc-hdl-20261004/verify_keygen_runtime.sh
```

The runner defaults to 500,000 simulated clocks and can take several minutes on
this host. Its `ECC_KEYGEN_WATCHDOG_CLOCKS`, `ECC_KEYGEN_LOG_PREFIX`, and
`ECC_KEYGEN_TOP_SOURCE` environment overrides support bounded diagnostic runs
without overwriting the full-run log. `ECC_KEYGEN_TIMEOUT_SECONDS` adjusts the
guarded wall-time limit (default 1,200 seconds), and
`ECC_KEYGEN_TRACE_INTERVAL` selects sparse checkpoints in the diagnostic top.
The runner defaults to IEEE 2017 and 2023; set `ECC_KEYGEN_EDITION=2017` or
`2023` to run one edition.
The memory floor defaults to 50% free and is configurable with
`ECC_KEYGEN_MIN_FREE_PERCENT`.
It writes temporary vectors and the native generator under `/private/tmp` and
removes them at exit.

The 10,000-clock internal-progress trace uses the same runner and intentionally
ends at its watchdog. It is recorded in
`keygen_progress_10k_2017.log` (raw artifact omitted from this checkpoint). Reproduce it
with:

```sh
ECC_KEYGEN_WATCHDOG_CLOCKS=10000 \
ECC_KEYGEN_LOG_PREFIX=keygen_progress_10k \
ECC_KEYGEN_TOP_SOURCE=evidence/caliptra-bfm-generated-ecc-hdl-20261004/top_keygen_diagnostic_probe.sv \
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  evidence/caliptra-bfm-generated-ecc-hdl-20261004/verify_keygen_runtime.sh
```

The runner's nonzero watchdog exit is expected for this diagnostic; the saved
log records the intermediate AHB and ECC state checkpoints.

The reset-only overlay does not qualify ECC result sampling, full generated
sequences, or UVMF/QVIP compatibility. The separate native AHB UVM
CSR readback against actual ECC RTL is recorded in
[`ECC AHB UVM smoke`](../caliptra-bfm-ecc-ahb-uvm-20261004/README.md). The
generated agent proxy identity runtime check is recorded in
[`ECC generated runtime probe`](../caliptra-bfm-generated-ecc-runtime-20261004/README.md).

## Reproduce

From the qd-bfm repository root:

```sh
CALIPTRA_ROOT=/path/to/caliptra-rtl \
IVERILOG_BIN=/path/to/iverilog \
  dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_hdl_top.sh
```

The runner checks the pinned Caliptra revision, clean checkout, and generated
`hdl_top.sv` hash. It confirms the stock two-error failure, then compiles a
disposable overlay under both IEEE editions. Compiler output and binaries
are removed on exit.

To reproduce the generated reset-monitor and ECC AHB readback runtime from the qd-bfm repository root:

```sh
CALIPTRA_ROOT=/path/to/caliptra-rtl \
IVERILOG_BIN=/path/to/iverilog \
VVP_BIN=/path/to/vvp \
ECC_RESET_MONITOR_LOG_DIR=/path/to/retained/logs \
  dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_reset_monitor.sh
```

The runner validates source revisions and hashes, applies hash-guarded monitor changes only to temporary copies, then requires one matched reset transaction and an ECC_IRQ_EN readback in both IEEE editions. Set ECC_RESET_MONITOR_LOG_DIR to retain run logs; build files and overlays are removed on exit.

Observed output:

```text
PASS: actual ECC RTL and generated UVMF hdl_top elaborate with three modport selectors removed and a 1ns/1ps timescale under IEEE 2017 (35 compile-progress warnings).
REPRODUCED: unmodified hdl_top has exactly two initiator_port direction errors under IEEE 2017.
PASS: actual ECC RTL and generated UVMF hdl_top elaborate with three modport selectors removed and a 1ns/1ps timescale under IEEE 2023 (35 compile-progress warnings).
REPRODUCED: unmodified hdl_top has exactly two initiator_port direction errors under IEEE 2023.
PASS: generated reset scoreboard and ECC IRQ_EN AHB readback matched under IEEE 2017; UVM_ERROR=0; UVM_FATAL=0.
```

## Inputs and hashes

| Input | SHA-256 |
| --- | --- |
| Caliptra generated `hdl_top.sv` | `23e3f134c7403c4604f6067096809c8a154881b1fbc1f37502dd7b29d7833827` |
| Caliptra `src/ecc/config/ecc_top.vf` | `a1b22f20543ebdc0b732981c96554bd287e98d11236fa5d1860c8819aae95ef2` |
| Caliptra `src/ecc/rtl/ecc_top.sv` | `5b727a2f05dace84b262b61a0c5b303b32268b08bf57d0463fbf7589c0241a1c` |
| Caliptra `src/ecc/tb/ecc_secp384r1.c` | `9dc6f094f04498c8a1b9d261847e76b61c892b5241e845874fc240739ea22c5d` |
| Caliptra `ECC_in_monitor_bfm.sv` | `4bdd8631566d578514affb2c7e34ab4706fe45f3f53352bfda26d447297cfaf2` |
| Caliptra `ECC_out_monitor_bfm.sv` | `360f641ca3f51f1a3c26fb7c47217d7cf80f72a1cb1405e3633540a453e78393` |
| Caliptra `ECC_in_driver_bfm.sv` | `ac6594e2ff7bac5a30c2b3def59067099e3e9749e559b23251b99c52e8ecf9dc` |
| `dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv` | `ba86f1323cfc88298665154a4176f7d094c8f12af1971089ece859adcefc98bc` |
| `dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv` | `56f9768145c5e7c9477dfa3d019e6a0fbd2b58e9d1948520a3e096004bfa7e6d` |
| `dv/caliptra_bfm/uvmf_lite/tests/tb_uvmf_agent.sv` | `ebc0bccdc5384d92048c09716b2ddec3272b756a7d17d3132ea9c24b145186f3` |
| `dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_hdl_top.sh` | `36632fa945c40a6649b962ca9b952eafa03dd3f62e034fb19622eb8819041a71` |
| `dv/caliptra_bfm/uvmf_lite/tests/tb_generated_ecc_hdl_top.sv` | `2c6f13a3fdcfb7dfea59a100cccce0d683c20fdb40dff5e4aa2236d168e267a4` |
| `runtime_blocker.log` | `15782f5324fbb32405c345e928a5e8e07c4b7b4b5a61848f29d1a2179f341fac` |
| `reset_monitor_blocker.log` | `d01f7deab69315a182c68e55774333ba1f52b638a1b99a56bc9ae7a7abe0b14f` |
| `apply_monitor_overlay.py` used for captured runs (64-clock poll interval) | `f47b91a6648c24286acd16bd85e6e10fc60371bec1c3803535f51eb3157e29fc` |
| `dv/caliptra_bfm/uvmf_lite/tests/generated_ecc_monitor_overlay.py` (512-clock poll interval) | `3bc2a45314bbcf2cebe0bbeec612bfa78436782bd96229aa67ff2e962cf20885` |
| `dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_reset_monitor.sh` | `c35a451405550aa5a1329e0be37ecc3f38b10b2a17241254e0f6f70b3b4780b7` |
| `dv/caliptra_bfm/uvmf_lite/tests/tb_generated_ecc_reset_probe_pkg.sv` | `0fe0097116672c200b092df891d2e77ce45d9392e50d2e5c7589deb9c634be20` |
| `dv/caliptra_bfm/uvmf_lite/tests/tb_generated_ecc_full_probe.sv` | `b5ffee36e14275339589d85998bffaa1d9465b966ba246e49259d0a9a6c98ecc` |
| `reset_monitor_overlay_2017.log` / `_2023.log` | `fef64b931a192492cc86cfd4e869554e0a3ac1c16025c7ec4603193c9067ea78` |
| `generated_ecc_ahb_probe_2017.log` / `_2023.log` | `36695ddecaeb49ccaa9691bf8ce5ca6ce9e17991409cc7ad5ab4afcd25c16f47` |
| `verify_keygen_runtime.sh` (single-edition selector) | `4728efc608e53fd6710887ac87b0959f6580ee76aed4279d62965f445e73723f` |
| `keygen_full_slowpoll_1m2_2017.log` | `e4ecbe7a4deae051dbece4157aceb6ac563eb8144c97917c9a62b42ba1789b99` |
| `keygen_probe_pkg.sv` | `19c0da1c5f35478e55d73cd708aee5b676e0f0afba6a884d883422a6fa46d5f3` |
| `keygen_runtime_2017.log` | `3175a5ac544d34a6c4115eca4ef48a999e6d8c395da6648993805a46d8b880ac` |
| `diagnose_keygen_bus.sh` | `3d726d84878a39eb178af7189875f57454dd4b9a910a69e5f4db173a793ea88a` |
| `top_keygen_diagnostic_probe.sv` | `409d0b8fc114bb5d4078bcc864ccb0024b82b21c2097d816478c84a27585d447` |
| `keygen_diagnostic_2017.log` | `bd9ba25efaf4fb189d774667973932af234e8f447dd466128778c907daecd859` |
| `keygen_progress_10k_2017.log` | `89c5219f1f21d0b438cf3a55e9ac0254da13121d1351842cb8a3681d9fe67386` |
| `keygen_generated_slowpoll_2m5_trace100k_2017.log` | `ace9b41eafd915ebc8945b4a9e65828230e9a708b5194dc579e0fce16f8ba826` |
| `keygen_poll512_1m2_30m_trace100k_rerun_2017.log` | `231555f37e3391ee5f22ba699e0fb070e64cc5051e07222e945098a4932e25b0` |
| `keygen_poll512_1m2_30m_trace100k_rerun_2023.log` | `0761baf6204c770b7b18c42762cde62124a1b76c0cb080f92004e21b74df86b8` |
| `keygen_poll512_1m2_interrupted_trace100k_2017.log` | `62b9a8aae054b995c5438b82facd097dff674662b0fd37b65404a7f54aee9133` |
| Icarus Verilog 13.0 devel binary | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |

## Current-state diagnostic — 2026-10-08

The generated ECC `key_sign` probe completed under IEEE 2017. It reported
`PASS: generated ECC key-sign transaction matched`, with `UVM_ERROR=0` and
`UVM_FATAL=0`. This is diagnostic evidence only: it used local Icarus source
commit `ac4532fab037e91df2f903e67fb40f59baedccca`, which was dirty and
unpublished. It does not qualify key signing. Re-run on a clean, published
Icarus revision before making a qualification claim.

The Caliptra checkout was clean at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
The runner used its hash-guarded temporary monitor overlays and disposable
build directory. Reproduce from the QD-EDA/qd-bfm repository root with:

```sh
env CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  ECC_IEEE_EDITION=2017 \
  ECC_RUNTIME_PROBE=key_sign \
  ECC_RESET_MONITOR_LOG_DIR=/private/tmp/caliptra-bfm-ecc-key-sign-v13_0-20261008/logs \
  IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
  VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  sh dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_reset_monitor.sh
```

| Diagnostic artifact | SHA-256 |
| --- | --- |
| Detailed `key_sign_overlay_2017.log` | `32edc9ab8c8afeb7378b409b39b503598118db451a628e2a6cebbd26c77dad1f` |
| Captured runner output | `26457b59be14e2888b77f0ebf3228c074f8fe9ae564f1ded5622e3cd8a5ec275` |
| Icarus compiler binary | `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114` |
| VVP runtime binary | `4bf80d6d22b44c22d518514c2f98f1f3fd485d77ba7c63bc97e68770d58b2867` |
| Reset-monitor runner | `4d0db7367428907a43e07bc139f2cafc8ddb74847cd62607ba064b9ad272888e` |
| Probe package | `0c1b0b09c935e8294158acb797f6f830c6139a385974ae09da90a6b8d6bc8e66` |
| Sparse progress probe | `732bd1e09e9d9ff816d5800d442790027564c0504e42a7f7408cc0477297f6aa` |

### Key-verification runner follow-up — 2026-10-08

The corrected runner also completed the generated IEEE 2017 key-verification
transaction: expected=2, observed=2, matched=2, mismatched=0, pending=0,
`UVM_ERROR=0`, and `UVM_FATAL=0` at 961,144 simulated clocks. This is
diagnostic-only because it used the same dirty, unpublished Icarus commit above;
clean published-Icarus qualification remains open. It used the runner's
hash-guarded monitor and input-driver overlays.

```sh
env CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  ECC_IEEE_EDITION=2017 \
  ECC_RUNTIME_PROBE=key_verify \
  ECC_RESET_MONITOR_LOG_DIR=/private/tmp/caliptra-bfm-ecc-key-verify-v13_0-20261008/logs \
  IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
  VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  sh dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_reset_monitor.sh
```

| Diagnostic artifact | SHA-256 |
| --- | --- |
| Detailed `key_verify_overlay_2017.log` | `77b3020f694ab31ebd3cdbdab7b82f4c4fa544df010c0dc3526cdacd6ac6644d` |
| `generated_ecc_monitor_overlay.py` | `6070550509aabf541b3da7947f976e265a27eaefdf84c8079edf9b41d6a9a6f6` |

### ECDH runner follow-up — 2026-10-08

The corrected runner completed the generated IEEE 2017 ECDH shared-key
transaction: expected=2, observed=2, matched=2, mismatched=0, pending=0,
`UVM_ERROR=0`, and `UVM_FATAL=0` at 716,432 simulated clocks. This remains
diagnostic-only because it used the same dirty, unpublished Icarus commit above;
clean published-Icarus qualification remains open.

```sh
env CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  ECC_IEEE_EDITION=2017 \
  ECC_RUNTIME_PROBE=ecdh \
  ECC_RESET_MONITOR_LOG_DIR=/private/tmp/caliptra-bfm-ecc-ecdh-v13_0-20261008/logs \
  IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
  VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  sh dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_reset_monitor.sh
```

| Diagnostic artifact | SHA-256 |
| --- | --- |
| Detailed `ecdh_overlay_2017.log` | `82738669814ca646dd15d1fbf051f771fcbe434596137856d9f767da7b900096` |
| `generated_ecc_monitor_overlay.py` | `6070550509aabf541b3da7947f976e265a27eaefdf84c8079edf9b41d6a9a6f6` |
