#!/usr/bin/env python3
"""Create exact-source Icarus overlays for the pinned PCRVault UVMF bench."""

from __future__ import annotations

import hashlib
import sys
from pathlib import Path


EXPECTED = {
    "verification_ip/interface_packages/pv_rst_pkg/src/pv_rst_configuration.svh":
        "d7d2e044e81dc6f098c365d3e7795155b8af8179224b0c60126620b3cfa8f901",
    "verification_ip/interface_packages/pv_rst_pkg/src/pv_rst_driver_bfm.sv":
        "42decdf0ba5de29334ce6cf51bab413576415327d0fbd642e7c2de49389d1948",
    "verification_ip/interface_packages/pv_rst_pkg/src/pv_rst_monitor_bfm.sv":
        "b7cf81eb9208fcb6113b8959e4ad9e06e6604623a90e801a98da69233858a388",
    "project_benches/pv/tb/testbench/hdl_top.sv":
        "086b332911af73233f0d1b699dbeee875707cc8fa75578ec93bb246d285bfda0",
    "verification_ip/environment_packages/pv_env_pkg/src/pv_env_configuration.svh":
        "996eb7a048d61b98385413f41da87d4457b9c749e0628c86906b2b32c21effd4",
    "verification_ip/environment_packages/pv_env_pkg/src/pv_ahb_reg_predictor.svh":
        "5bd7bbcd13a8c9918723c886fc60f8a07e1231fa005d2e664d4d8b5c77e5a935",
    "verification_ip/interface_packages/pv_read_pkg/src/pv_read_driver_bfm.sv":
        "f7d45238eb3a55a292ae6b5202ffbf2a4f6925b82e4c675f124d72b2225aadfd",
    "verification_ip/interface_packages/pv_read_pkg/src/pv_read_monitor_bfm.sv":
        "e9c607ac5e2907bf1ca0d1b417493c0ffb1360e10fd9b9ea18395d6e7bc1341a",
}


def read_pinned(source_root: Path, relative: str) -> str:
    path = source_root / relative
    data = path.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    expected = EXPECTED[relative]
    if digest != expected:
        raise SystemExit(
            f"refusing stale PCRVault source {path}: expected SHA-256 {expected}, got {digest}"
        )
    return data.decode("utf-8")


def replace_once(text: str, old: str, new: str, source: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"expected exactly one overlay anchor in {source}; found {count}")
    return text.replace(old, new, 1)


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit(
            f"usage: {Path(sys.argv[0]).name} <pcrvault-uvmf-template-output> <overlay-dir>"
        )
    source_root, overlay_root = map(Path, sys.argv[1:])

    for relative, old, new in (
        (
            "verification_ip/interface_packages/pv_rst_pkg/src/pv_rst_configuration.svh",
            "agent_path, interface_name, )",
            "agent_path, interface_name)",
        ),
        (
            "verification_ip/interface_packages/pv_rst_pkg/src/pv_rst_driver_bfm.sv",
            'The BFM at \'%m\' has the following parameters: ", )',
            'The BFM at \'%m\' has the following parameters: ")',
        ),
        (
            "verification_ip/interface_packages/pv_rst_pkg/src/pv_rst_monitor_bfm.sv",
            'The BFM at \'%m\' has the following parameters: ", )',
            'The BFM at \'%m\' has the following parameters: ")',
        ),
    ):
        text = read_pinned(source_root, relative)
        text = replace_once(text, old, new, relative)
        target = overlay_root / "src" / Path(relative).name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)

    relative = "project_benches/pv/tb/testbench/hdl_top.sv"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        "pv_write_driver_bfm  pv_sha512_write_agent_drv_bfm(pv_sha512_write_agent_bus.initiator_port);",
        "pv_write_driver_bfm  pv_sha512_write_agent_drv_bfm(pv_sha512_write_agent_bus);",
        relative,
    )
    text = replace_once(
        text,
        "pv_read_driver_bfm  pv_sha512_block_read_agent_drv_bfm(pv_sha512_block_read_agent_bus.initiator_port);",
        "pv_read_driver_bfm  pv_sha512_block_read_agent_drv_bfm(pv_sha512_block_read_agent_bus);",
        relative,
    )
    target = overlay_root / "hdl_top.sv"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)

    relative = "verification_ip/environment_packages/pv_env_pkg/src/pv_env_configuration.svh"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        "qvip_ahb_lite_slave_subenv_interface_names     = interface_names[0:0];",
        "qvip_ahb_lite_slave_subenv_interface_names[0]  = interface_names[0];",
        relative,
    )
    text = replace_once(
        text,
        "qvip_ahb_lite_slave_subenv_interface_activity  = interface_activity[0:0];",
        "qvip_ahb_lite_slave_subenv_interface_activity[0] = interface_activity[0];",
        relative,
    )
    target = overlay_root / "src" / Path(relative).name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)

    relative = "verification_ip/interface_packages/pv_read_pkg/src/pv_read_driver_bfm.sv"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        """    pv_read_responder_struct.read_entry = pv_read_i[8:4];
    pv_read_responder_struct.read_offset = pv_read_i[3:0];
    responder_struct = pv_read_responder_struct;""",
        """    pv_read_responder_struct.read_entry = pv_read_i[8:4];
    pv_read_responder_struct.read_offset = pv_read_i[3:0];
    pv_read_responder_struct.error = pv_rd_resp_i[33];
    pv_read_responder_struct.last = pv_rd_resp_i[32];
    pv_read_responder_struct.read_data = pv_rd_resp_i[31:0];
    responder_struct = pv_read_responder_struct;""",
        relative,
    )
    target = overlay_root / "src" / Path(relative).name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)

    relative = "verification_ip/interface_packages/pv_read_pkg/src/pv_read_monitor_bfm.sv"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        """  function bit any_signal_changed();
    return |(pv_read_i[8:4]   ^ read_entry_o)   ||
           |(pv_read_i[3:0]   ^ read_offset_o)  ||
           |(pv_rd_resp_i[33] ^ error_o)        ||
           |(pv_rd_resp_i[32] ^ last_o)         ||
           |(pv_rd_resp_i[31:0] ^ read_data_o);
  endfunction""",
        """  function bit request_changed();
    return |(pv_read_i[8:4] ^ read_entry_o) ||
           |(pv_read_i[3:0] ^ read_offset_o);
  endfunction""",
        relative,
    )
    text = replace_once(
        text,
        "while (!any_signal_changed()) @(posedge clk_i);",
        "while (!request_changed()) @(negedge clk_i);",
        relative,
    )
    target = overlay_root / "src" / Path(relative).name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)

    relative = "verification_ip/environment_packages/pv_env_pkg/src/pv_ahb_reg_predictor.svh"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        "        T ahb_txn;",
        "        ahb_master_burst_transfer #(ahb_lite_slave_0_params::AHB_NUM_MASTERS, "
        "ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS, "
        "ahb_lite_slave_0_params::AHB_NUM_SLAVES, "
        "ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH, "
        "ahb_lite_slave_0_params::AHB_WDATA_WIDTH, "
        "ahb_lite_slave_0_params::AHB_RDATA_WIDTH) ahb_txn;",
        relative,
    )
    target = overlay_root / "src" / Path(relative).name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
