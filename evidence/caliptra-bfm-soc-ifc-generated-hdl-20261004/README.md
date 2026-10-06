> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated SoC-IFC BFM HDL-top compile — 2026-10-04

The pinned Caliptra SoC-IFC generated `hdl_top` now elaborates against the open
BFM filelist and the real `soc_ifc_top` RTL. The generated top uses the
hash-guarded open DMA-target overlay from
[`caliptra-bfm-soc-ifc-axi-target-20261004`](../caliptra-bfm-soc-ifc-axi-target-20261004/README.md).

## Reproduce

From the `BFM WORK` clone, run:

```sh
IVERILOG_BIN=/path/to/iverilog \
  ./evidence/caliptra-bfm-soc-ifc-generated-hdl-20261004/run.sh
```

The runner automatically checks macOS system free memory before starting and
stops the compile if free memory drops below 70%. It also has a five-minute
runtime limit.

`CALIPTRA_ROOT` may select another pinned Caliptra v2.1.2 checkout without
spaces in its path; Icarus filelists do not support whitespace in paths here.
The runner copies the seven generated protocol packages under a fresh temporary
directory, applies the guarded `$psprintf` and responder-modport overlays
there, expands the Caliptra `.vf` variables for Icarus, and runs:

```sh
iverilog -uvm -g2012 -DXCELIUM -s hdl_top -tnull \
  -f <expanded-soc_ifc_top.vf> \
  -f dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f \
  -f <generated-hdl-top-filelist>
```

The generated-filelist compatibility inputs are deliberately narrow:

- [`hdl_proxy_packages.sv`](hdl_proxy_packages.sv) declares only the class
  handles, monitor callback, and mailbox ECC fields that the generated HDL
  BFMs reference. It does not replace generated UVMF transaction or agent
  classes.
- [`hdl_stubs.sv`](hdl_stubs.sv) supplies a minimal reset generator and empty
  coverage-bind module for static elaboration.
- `avery_defines.svh` is an empty include shim for the licensed Avery macro
  header. The open AAXI interface/container compatibility sources come from
  the local BFM filelist.

The generated `soc_ifc_env_pkg` and the seven full generated host UVMF packages
are not compiled in this lane. The proxy classes are compile-only; this result
does not establish a generated UVMF runtime, Avery/QVIP behavior, or
transaction-level coverage. The real `soc_ifc_top`, generated interfaces and
driver/monitor BFM modules, open AHB/AAXI compatibility modules, and open DMA
target are all present in the elaborated `hdl_top` hierarchy. The separate
[SoC-IFC runtime evidence](../caliptra-bfm-soc-ifc-dma-runtime-20261004/README.md)
exercises actual DUT transactions.

## Result

- Icarus: 13.0 development build, `246c58e4-dirty`
- Caliptra RTL: v2.1.2, commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- Result: exit 0, `hdl_top` elaborated with no hard errors
- Warnings: one timescale-mixing notice and one coercion of `security_state`
  to `inout` at the generated DUT instance; preserved in `compile.log` (raw artifact omitted from this checkpoint)
- The pinned Caliptra checkout remained clean

The previous strict compile identified 31 writes through generated responder
modports declared as inputs. Those signals are dynamically sampled and driven
by the generated BFMs; the disposable overlay changes only those responder
signals to `inout` and leaves `clk` and `dummy` as inputs. The mailbox SRAM
request and response are also dual-role and use `inout`.

## Overlay guards

- [`soc_ifc_generated_empty_psprintf_overlay.py`](../../docs/conformance/release_overlays/caliptra/soc_ifc_generated_empty_psprintf_overlay.py)
  copies the seven pinned packages and removes 21 trailing empty actuals from
  generated diagnostic `$psprintf` calls.
- [`soc_ifc_generated_responder_modport_overlay.py`](../../docs/conformance/release_overlays/caliptra/soc_ifc_generated_responder_modport_overlay.py)
  hash-checks four interface files and changes 32 responder signal directions
  in disposable copies.
- [`prepare_overlay.py`](../caliptra-bfm-soc-ifc-axi-target-20261004/prepare_overlay.py)
  hash-checks the generated `hdl_top` before replacing the DMA AXI tie-offs
  with the open subordinate.

None of these helpers writes to the pinned Caliptra checkout.
