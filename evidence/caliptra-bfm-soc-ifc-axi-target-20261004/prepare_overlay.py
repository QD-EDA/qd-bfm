#!/usr/bin/env python3
"""Generate a disposable SoC-IFC hdl_top with the open Caliptra DMA target."""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path


SOURCE_SHA256 = "a875a33b09abe09b9bed9220c8de0494917891da68442c943915c1e942fe7f84"
SOURCE_RELATIVE = Path(
    "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/project_benches/"
    "soc_ifc/tb/testbench/hdl_top.sv"
)
START = "    // TODO\n    always_comb begin\n        // AXI AR"
END = "    end\n\n\n  soc_ifc_cov_bind i_soc_ifc_cov_bind();"

OPEN_TARGET = """    // Open, deterministic SRAM/FIFO target for the Caliptra DMA AXI manager.
    axi4_caliptra_dma_if_subordinate #(
        .ADDR_WIDTH(`CALIPTRA_AXI_DMA_ADDR_WIDTH),
        .DATA_WIDTH(CPTRA_AXI_DMA_DATA_WIDTH),
        .ID_WIDTH(CPTRA_AXI_DMA_ID_WIDTH),
        .USER_WIDTH(CPTRA_AXI_DMA_USER_WIDTH),
        .SRAM_BASE_ADDR(48'h0001_2344_0000),
        .SRAM_BYTES(262144),
        .FIFO_BASE_ADDR(48'h0000_fa57_0000),
        .FIFO_CAPACITY_BYTES(65536),
        .DECODE_LOW_BITS(18),
        .DMA_BLOCK_COUNT(100)
    ) caliptra_open_dma_target (
        .ACLK(clk),
        .ARESETn(soc_ifc_ctrl_agent_bus.cptra_rst_b),
        .m_axi_w_if(m_axi_if.w_sub),
        .m_axi_r_if(m_axi_if.r_sub),
        .fifo_clear(1'b0),
        .auto_fifo_push(1'b0),
        .auto_fifo_pop(1'b0),
        .use_dma_gen_sequence(1'b0),
        .dma_gen_done(1'b0),
        .dma_gen_block_size_bytes(1200'b0),
        .en_recovery_emulation(1'b0),
        .recovery_threshold_words(32'b0),
        .recovery_block_words(32'b0),
        .inject_error(1'b0),
        .stall_sram_aw(1'b0),
        .stall_sram_w(1'b0),
        .stall_sram_b(1'b0),
        .stall_sram_ar(1'b0),
        .stall_sram_r(1'b0),
        .stall_fifo_aw(1'b0),
        .stall_fifo_w(1'b0),
        .stall_fifo_b(1'b0),
        .stall_fifo_ar(1'b0),
        .stall_fifo_r(1'b0),
        .fifo_level(),
        .fifo_push_event(),
        .fifo_pop_event(),
        .recovery_data_avail()
    );"""


def main() -> None:
    repo_root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--caliptra-root",
        type=Path,
        default=repo_root.parent / "caliptra-rtl",
        help="pinned Caliptra checkout (default: sibling caliptra-rtl)",
    )
    parser.add_argument("--output", required=True, type=Path, help="overlay output path")
    parser.add_argument(
        "--open-mbox-target",
        action="store_true",
        help="connect the open mailbox SRAM model in the disposable hdl_top",
    )
    args = parser.parse_args()

    source_path = args.caliptra_root / SOURCE_RELATIVE
    source = source_path.read_text()
    actual_sha256 = hashlib.sha256(source.encode()).hexdigest()
    if actual_sha256 != SOURCE_SHA256:
        raise SystemExit(
            f"Refusing unreviewed hdl_top: SHA-256 {actual_sha256} != {SOURCE_SHA256}"
        )
    if source.count(START) != 1 or source.count(END) != 1:
        raise SystemExit("Refusing hdl_top with an unexpected AXI tie-off block")

    start = source.index(START)
    end = source.index(END, start) + len("    end")
    replaced = source[start:end]
    tied_channels = (
        "arready", "rdata", "rresp", "rid", "rlast", "rvalid", "awready",
        "wready", "bresp", "bid", "bvalid",
    )
    tieoff_count = sum(
        len(re.findall(rf"m_axi_if\.{name}\s*=\s*'0\b", replaced))
        for name in tied_channels
    )
    if tieoff_count != len(tied_channels):
        raise SystemExit("Refusing to replace an unexpected set of AXI tie-offs")

    overlay = source[:start] + OPEN_TARGET + source[end:]
    dummy_tieoff = ".dummy(1'b1)"
    dummy_connection = ".dummy(dummy)"
    if overlay.count(dummy_tieoff) != 7:
        raise SystemExit("Refusing hdl_top with an unexpected set of BFM dummy-reset tie-offs")
    overlay = overlay.replace(dummy_tieoff, dummy_connection)
    if overlay.count(dummy_connection) != 7:
        raise SystemExit("Generated hdl_top does not connect the default reset pulse to all BFMs")
    if args.open_mbox_target:
        mbox_driver_instance = (
            "  mbox_sram_driver_bfm  mbox_sram_agent_drv_bfm("
            "mbox_sram_agent_bus.responder_port);\n"
        )
        if overlay.count(mbox_driver_instance) != 1:
            raise SystemExit("Refusing hdl_top with an unexpected mailbox SRAM driver instance")
        if "caliptra_open_mbox_sram" in overlay:
            raise SystemExit("Refusing hdl_top that already contains the open mailbox target")
        overlay = overlay.replace(
            mbox_driver_instance,
            "  wire caliptra_open_mbox_access_error;\n"
            + mbox_driver_instance
            + "  caliptra_mbox_sram_subordinate #(\n"
            + "    .ENABLE_ECC_INJECTION(1'b1)\n"
            + "  ) caliptra_open_mbox_sram (\n"
            + "    .clk_i(clk),\n"
            + "    .rst_b(soc_ifc_ctrl_agent_bus.cptra_rst_b),\n"
            + "    .req(mbox_sram_agent_bus.mbox_sram_req),\n"
            + "    .resp(mbox_sram_agent_bus.mbox_sram_resp),\n"
            + "    .write_xor_mask('0),\n"
            + "    .inject_ecc_error(mbox_sram_agent_drv_bfm.inject_ecc_error),\n"
            + "    .access_error(caliptra_open_mbox_access_error)\n"
            + "  );\n",
            1,
        )
        overlay = overlay.replace(
            "    .access_error(caliptra_open_mbox_access_error)\n"
            + "  );\n",
            "    .access_error(caliptra_open_mbox_access_error)\n"
            + "  );\n"
            + "  always @(posedge clk) begin\n"
            + "    if (soc_ifc_ctrl_agent_bus.cptra_rst_b === 1'b1 &&\n"
            + "        caliptra_open_mbox_access_error === 1'b1)\n"
            + "      $fatal(1, \"Open Caliptra mailbox SRAM target rejected an invalid request\");\n"
            + "  end\n",
            1,
        )
    if re.search(r"m_axi_if\.(arready|bvalid)\s*=\s*'0\b", overlay):
        raise SystemExit("Generated overlay still contains an AXI manager tie-off")
    if overlay.count("caliptra_open_dma_target") != 1:
        raise SystemExit("Generated overlay does not contain exactly one open target")
    if args.open_mbox_target and overlay.count("caliptra_open_mbox_sram") != 1:
        raise SystemExit("Generated overlay does not contain exactly one open mailbox target")
    if args.open_mbox_target and (
        overlay.count("caliptra_open_mbox_access_error") != 3
        or overlay.count("Open Caliptra mailbox SRAM target rejected an invalid request") != 1
    ):
        raise SystemExit("Generated overlay does not guard the mailbox target access-error pulse")

    output = args.output.resolve()
    if output == source_path.resolve():
        raise SystemExit("Overlay output must not overwrite the pinned Caliptra source")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(overlay)
    print(f"PASS: generated the guarded SoC-IFC open-target overlay in {output}")
    if args.open_mbox_target:
        print("PASS: connected mailbox SRAM to the open target with fatal access-error checking")
    print(f"PASS: source SHA-256 {actual_sha256}; overlay SHA-256 {hashlib.sha256(overlay.encode()).hexdigest()}")


if __name__ == "__main__":
    main()
