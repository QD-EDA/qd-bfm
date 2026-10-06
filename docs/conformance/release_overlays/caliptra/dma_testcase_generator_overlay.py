#!/usr/bin/env python3
"""Make Caliptra's DMA testcase generator's testbench callbacks explicit."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


SOURCE = "src/integration/tb/dma_testcase_generator.sv"
SOURCE_SHA256 = "940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447"
TOP = "tb_caliptra_dma_testcase_generator_bfm"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--caliptra-root", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--dut-replay", action="store_true")
    parser.add_argument("--top", default=TOP)
    args = parser.parse_args()

    root = args.caliptra_root.resolve()
    source_path = root / SOURCE
    original = source_path.read_bytes()
    if sha256(original) != SOURCE_SHA256:
        raise SystemExit(f"Refusing unreviewed Caliptra DMA generator: {sha256(original)}")
    text = original.decode()
    for call, replacement, count in (
        ("slam_dccm_ram(", f"{args.top}.slam_dccm_ram(", 7),
        ("riscv_ecc32(", f"{args.top}.riscv_ecc32(", 7),
        ('$fatal("', '$fatal(1, "', 1),
    ):
        actual = text.count(call)
        if actual != count:
            raise SystemExit(f"Expected {count} instances of {call!r}, found {actual}")
        text = text.replace(call, replacement)

    if args.dut_replay:
        randomize_branch = '''        if (!dma_gen.randomize()) begin
          $error("Randomization failed for dma_transfer_generator %d", i);
        end
        else begin'''
        if text.count(randomize_branch) != 1:
            raise SystemExit("Expected one dma_gen.randomize() branch to qualify for DUT replay")
        text = text.replace(
            randomize_branch,
            """        int unsigned replay_size;
        bit large_fifo_case;
        bit randomize_success;
        if ($test$plusargs("CALIPTRA_BFM_DUT_REPLAY")) begin
          large_fifo_case = (i == 0);
          if (large_fifo_case)
            replay_size = 65536;
          else begin
            case ((i - 1) % 8)
              0: replay_size = 1;
              1: replay_size = 4;
              2: replay_size = 5;
              3: replay_size = 16;
              4: replay_size = 64;
              5: replay_size = 65;
              6: replay_size = 255;
              default: replay_size = 256;
            endcase
          end
          dma_gen.srandom(32'h4341_0000 + i);
          randomize_success = dma_gen.randomize() with {
            dma_xfer_type inside {AHB2AXI, MBOX2AXI, AXI2AXI, AXI2MBOX, AXI2AHB};
            (large_fifo_case) -> dma_xfer_type == AXI2AXI;
            (large_fifo_case) -> src_is_fifo;
            (!large_fifo_case) -> !src_is_fifo;
            !dst_is_fifo;
            (large_fifo_case) -> use_rd_fixed;
            (!large_fifo_case) -> !use_rd_fixed;
            !use_wr_fixed;
            !inject_rst;
            !test_block_size;
            block_size == 0;
            xfer_size == replay_size;
            (large_fifo_case) -> src_offset == 0;
            (large_fifo_case) -> dst_offset == 0;
            (!large_fifo_case && dma_xfer_type == MBOX2AXI) -> src_offset inside {[32'h0000_1000:32'h0000_1efc]};
            (!large_fifo_case && dma_xfer_type != MBOX2AXI) -> src_offset inside {[32'h0000_1000:32'h0000_1ffc]};
            (!large_fifo_case && dma_xfer_type == AXI2MBOX) -> dst_offset inside {[32'h0000_1000:32'h0000_1efc]};
            (!large_fifo_case && dma_xfer_type != AXI2MBOX) -> dst_offset inside {[32'h0000_4000:32'h0000_4ffc]};
          };
        end else begin
          randomize_success = dma_gen.randomize();
        end
        if (!randomize_success) begin
          $error("Randomization failed for dma_transfer_generator %d", i);
        end else begin""",
        )

    transformed = text.encode()
    output = args.output.resolve()
    if output == source_path or root in output.parents:
        raise SystemExit("overlay output must remain outside the pinned Caliptra sources")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(transformed)

    if args.manifest:
        manifest = args.manifest.resolve()
        manifest.parent.mkdir(parents=True, exist_ok=True)
        manifest.write_text(
            json.dumps(
                {
                    "purpose": "Run Caliptra's DMA testcase generator with an explicit DCCM callback in the Icarus harness.",
                    "changes": [
                        "Qualify slam_dccm_ram and riscv_ecc32 against the harness top.",
                        "Add the Icarus-required numeric $fatal finish code.",
                        *(
                            ["Use deterministic per-case seeds to cover five named DMA routes at eight short transfer sizes (1, 4, 5, 16, 64, 65, 255, and 256 words), plus a maximum 65,536-word fixed-read FIFO-to-SRAM stream; preserve Caliptra's randomized delay flag."]
                            if args.dut_replay
                            else []
                        ),
                    ],
                    "source": str(source_path),
                    "top": args.top,
                    "source_sha256": SOURCE_SHA256,
                    "overlay": str(output),
                    "overlay_sha256": sha256(transformed),
                },
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
