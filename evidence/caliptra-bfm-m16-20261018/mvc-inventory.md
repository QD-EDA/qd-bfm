# M16 generated-UVMF MVC inventory

Scope: the 50 generated-UVMF rows recorded **BLOCKED** in `evidence/caliptra-bfm-m15-20261017/m15-results.tsv`, using Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. The one already-passing generated HMAC row is outside this 50-row blocked set.

## Components and exact row groups

| Environment | Rows | Active MVC/QVIP use | AXI use |
|---|---:|---|---|
| `uvmf-caliptra_top` | 5 (0–4) | AHB-Lite QVIP slave | Avery AAXI host/agent |
| `uvmf-kv` | 5 (6–10) | AHB-Lite QVIP slave | — |
| `uvmf-mldsa` | 30 (77–89, 91–107) | AHB-Lite QVIP slave; optional `qvip_memory_message_handler` handle declaration | — |
| `uvmf-pv` | 3 (46–48) | AHB-Lite QVIP slave | — |
| `uvmf-soc_ifc` | 3 (43–45) | AHB-Lite QVIP slave | Avery AAXI host/agent |
| `uvmf-ecc` | 2 (54–55) | No active MVC/QVIP component or API reference found; only the generated filelist's MVC boilerplate | — |
| `uvmf-sha512` | 2 (16–17) | No active MVC/QVIP component or API reference found; only the generated filelist's MVC boilerplate | — |
| **Total** | **50** | **46 AHB rows; 4 with no active MVC use** | **8 AAXI rows, all within the AHB set** |

No active APB component or API is used by these rows. Caliptra-top and SoC-IFC retain commented APB imports/config fragments; the active generated test packages do not import or instantiate an APB agent.

## AHB MVC/QVIP API surface

The same AHB slave component is used by the 46 rows in Caliptra-top, KV, MLDSA, PV, and SoC-IFC. The generated packages import `mvc_pkg`, `mgc_ahb_v2_0_pkg`, `qvip_ahb_lite_slave_params_pkg`, and `qvip_ahb_lite_slave_pkg`; test packages also wildcard-import the empty `QUESTA_MVC` namespace. The active symbols exercised by those environments are:

- `mvc_sequence_item_base` and `mvc_sequencer` from `mvc_pkg`.
- `ahb_master_burst_transfer` and its base type, AHB read/write/size and OKAY/ERROR constants from `mgc_ahb_v2_0_pkg`.
- `ahb_lite_slave_0_params` width/agent parameters from `qvip_ahb_lite_slave_params_pkg`.
- `qvip_ahb_lite_slave_env_configuration`, `qvip_ahb_lite_slave_environment`, the generated `ahb_lite_slave_0` agent, and its `ap["burst_transfer"]` analysis connection from `qvip_ahb_lite_slave_pkg`.
- `reg2ahb_adapter`, `ahb_reg_predictor`, `set_monitor_item`, and the generated AHB configuration's `convert2string` method.
- The HDL wrapper `hdl_qvip_ahb_lite_slave`, instantiated by generated `hdl_top.sv`; the generated hierarchy exposes the AHB address, data, select, write, ready, transfer, size, response, and read-data pins.
- MLDSA additionally imports `qvip_utils_pkg`; source search found only an optional `qvip_memory_message_handler` handle declaration, with no construction/use in the generated environment.

The QD-BFM drop-ins are in `dv/caliptra_bfm/uvm/caliptra_ahb_mvc_compat_pkg.sv`, `dv/caliptra_bfm/uvm/caliptra_ahb_qvip_compat_pkg.sv`, and `dv/caliptra_bfm/uvm/ahb_lite_caliptra_qvip_hdl.sv`, all listed by `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f`.

## AAXI API surface

Only the 5 Caliptra-top and 3 SoC-IFC rows use AAXI. Their active generated packages import `aaxi_pkg`, `aaxi_pkg_xactor`, `aaxi_pkg_test`, `aaxi_pll`, and `aaxi_uvm_pkg`; generated environments instantiate `aaxi_uvm_testbench`, bind `aaxi_uvm_container`/`aaxi_intf` through `uvm_config_db`, and use the generated host/driver interface. The QD-BFM compatibility sources are `dv/caliptra_bfm/uvm/aaxi_generated_namespace_compat.sv` and `dv/caliptra_bfm/uvm/caliptra_aaxi_compat_pkg.sv`.

This inventory was queried from the code graph first, then checked against the pinned generated package, sequence, and HDL-top source references and the 50-row M15 result table. The row-45 filelist gate is preserved under `attempts/gate-2669-socifc-ahb/`; it is blocked before simulation by missing vendor Avery sources and the optional proprietary AXI checker. Prior generated AHB mailbox runtime PASS evidence is documented in `evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md` and its curated runner.
