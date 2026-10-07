#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Apply narrow, hash-guarded monitor fixes to disposable Caliptra copies."""

import hashlib
import sys
from pathlib import Path


EXPECTED = {
    "ECC_in_monitor_bfm.sv": "4bdd8631566d578514affb2c7e34ab4706fe45f3f53352bfda26d447297cfaf2",
    "ECC_out_monitor_bfm.sv": "360f641ca3f51f1a3c26fb7c47217d7cf80f72a1cb1405e3633540a453e78393",
    "ECC_in_driver_bfm.sv": "ac6594e2ff7bac5a30c2b3def59067099e3e9749e559b23251b99c52e8ecf9dc",
}


def patch_input(source: str) -> str:
    start_marker = "    else begin\n\t    transaction_flag = 0;\n"
    end_marker = "\t    end //tx flag = 0\n    end"
    if source.count(start_marker) != 1:
        raise ValueError("input monitor branch marker must occur exactly once")
    start = source.index(start_marker)
    end = source.index(end_marker, start) + len(end_marker)
    replacement = """    else begin
      transaction_flag = 0;
      // The generated driver holds its initialization flag high. Consume a
      // completion only after observing a fresh low-to-high event.
      while (transaction_flag_out_monitor_i !== 1'b0) @(posedge clk_i);
      while (transaction_flag_out_monitor_i !== 1'b1) @(posedge clk_i);
      transaction_flag = 1;
      ECC_in_monitor_struct.test = ecc_in_test_transactions'(test_i);
      ECC_in_monitor_struct.op = ecc_in_op_transactions'(op_i);
      @(posedge clk_i);
    end"""
    return source[:start] + replacement + source[end:]


def patch_output(source: str) -> str:
    old = """      while (transaction_flag_out_monitor_i ==0) @(posedge clk_i);
      if (transaction_flag_out_monitor_i == 1 ) begin"""
    new = """      // ecc_reset_test (0) signals initialization, not a result record.
      while (test_i === 3'b000) @(posedge clk_i);
      // Require a fresh assertion for each real operation completion.
      while (transaction_flag_out_monitor_i !== 1'b0) @(posedge clk_i);
      while (transaction_flag_out_monitor_i !== 1'b1) @(posedge clk_i);
      if (transaction_flag_out_monitor_i == 1 ) begin"""
    if source.count(old) != 1:
        raise ValueError("output monitor flag wait must occur exactly once")
    return source.replace(old, new, 1)


def patch_input_driver(source: str) -> str:
    old = """    task wait_ready;
      begin
        read_single_word(ADDR_STATUS);
        while (hrdata_i == 0)
          begin
            read_single_word(ADDR_STATUS);
          end
      end
    endtask // wait_ready"""
    new = """    task wait_ready;
      begin
        read_single_word(ADDR_STATUS);
        while (hrdata_i == 0)
          begin
            // Status polling cadence does not affect the running ECC core.
            repeat (512) @(posedge clk_i);
            read_single_word(ADDR_STATUS);
          end
      end
    endtask // wait_ready"""
    if source.count(old) != 1:
        raise ValueError("input driver wait_ready task must occur exactly once")
    return source.replace(old, new, 1)


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} CALIPTRA_ROOT OUTPUT_DIR", file=sys.stderr)
        return 2
    caliptra_root, output_dir = map(Path, sys.argv[1:])
    source_root = (
        caliptra_root
        / "src/ecc/uvmf_ecc/uvmf_template_output/verification_ip/interface_packages"
    )
    output_dir.mkdir(parents=True, exist_ok=True)

    for package, transform in (
        ("ECC_in_pkg", patch_input),
        ("ECC_out_pkg", patch_output),
    ):
        name = f"{package.split('_pkg')[0]}_monitor_bfm.sv"
        source_path = source_root / package / "src" / name
        source_bytes = source_path.read_bytes()
        actual = hashlib.sha256(source_bytes).hexdigest()
        if actual != EXPECTED[name]:
            raise ValueError(f"unexpected pinned source hash for {name}: {actual}")
        patched = transform(source_bytes.decode())
        target_path = output_dir / name
        target_path.write_text(patched)
        print(f"OVERLAY: {name} {actual} -> {target_path}")

    name = "ECC_in_driver_bfm.sv"
    source_path = source_root / "ECC_in_pkg" / "src" / name
    source_bytes = source_path.read_bytes()
    actual = hashlib.sha256(source_bytes).hexdigest()
    if actual != EXPECTED[name]:
        raise ValueError(f"unexpected pinned source hash for {name}: {actual}")
    target_path = output_dir / name
    target_path.write_text(patch_input_driver(source_bytes.decode()))
    print(f"OVERLAY: {name} {actual} -> {target_path}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as error:
        print(f"monitor overlay failed: {error}", file=sys.stderr)
        raise SystemExit(1)
