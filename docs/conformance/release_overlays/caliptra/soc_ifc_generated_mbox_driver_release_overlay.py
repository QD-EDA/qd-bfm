#!/usr/bin/env python3
"""Release the generated mailbox driver response pin for the open SRAM model."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path


SOURCE_RELATIVE = Path(
    "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/"
    "interface_packages/mbox_sram_pkg/src/mbox_sram_driver_bfm.sv"
)
SOURCE_SHA256 = "8e8e3973fe64221557c3df6fd32af9892e5d1443a5c662a3285d265db5eb6948"
PSPRINTF_OVERLAY_SHA256 = "fc27eb2fe5a18b7a56794d775badf097d5d4480afb2851718a6877efbfaffbad"
DRIVEN_RESPONSE = """    if (mbox_sram_responder_struct.is_read) begin
        mbox_sram_resp_o.rdata.data <= mbox_sram_responder_struct.data;
        mbox_sram_resp_o.rdata.ecc  <= mbox_sram_responder_struct.data_ecc;
    end
    @(posedge clk_i);"""
RELEASED_RESPONSE = """    // The open mailbox subordinate is the sole response-data driver.
    mbox_sram_resp_o <= 'bz;
    @(posedge clk_i);"""
PROXY_ANCHOR = "  mbox_sram_pkg::mbox_sram_driver   proxy;\n"
LIVE_ECC_SYNC = """  // Keep the open SRAM target synchronized with sequence-time ECC settings.
  always @(negedge clk_i) begin
    if (proxy != null)
      inject_ecc_error = proxy.configuration.inject_ecc_error;
  end
"""


def main() -> None:
    repo_root = Path(__file__).resolve().parents[4]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--caliptra-root",
        type=Path,
        default=repo_root.parent / "caliptra-rtl",
        help="pinned Caliptra checkout (default: sibling caliptra-rtl)",
    )
    parser.add_argument(
        "--input",
        type=Path,
        help="already hash-guarded disposable source after the generated $psprintf overlay",
    )
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    source_path = args.caliptra_root / SOURCE_RELATIVE
    pinned_source = source_path.read_bytes()
    pinned_sha256 = hashlib.sha256(pinned_source).hexdigest()
    if pinned_sha256 != SOURCE_SHA256:
        raise SystemExit(
            f"Refusing unreviewed mailbox BFM: SHA-256 {pinned_sha256} != {SOURCE_SHA256}"
        )
    source_bytes = args.input.read_bytes() if args.input else pinned_source
    actual_sha256 = hashlib.sha256(source_bytes).hexdigest()
    allowed_input_hash = PSPRINTF_OVERLAY_SHA256 if args.input else SOURCE_SHA256
    if actual_sha256 != allowed_input_hash:
        raise SystemExit(
            f"Refusing unexpected disposable mailbox source: SHA-256 {actual_sha256} "
            f"!= {allowed_input_hash}"
        )
    source = source_bytes.decode()
    if source.count(DRIVEN_RESPONSE) != 1:
        raise SystemExit("Refusing mailbox BFM with an unexpected response-drive task")
    if source.count(PROXY_ANCHOR) != 1:
        raise SystemExit("Refusing mailbox BFM with an unexpected proxy declaration")

    overlay = source.replace(DRIVEN_RESPONSE, RELEASED_RESPONSE, 1)
    overlay = overlay.replace(PROXY_ANCHOR, PROXY_ANCHOR + LIVE_ECC_SYNC, 1)
    output = args.output.resolve()
    if output == source_path.resolve():
        raise SystemExit("Overlay output must not overwrite the pinned Caliptra source")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(overlay)
    print(f"PASS: generated mailbox driver release overlay in {output}")
    print(
        f"PASS: source SHA-256 {actual_sha256}; "
        f"overlay SHA-256 {hashlib.sha256(overlay.encode()).hexdigest()}"
    )


if __name__ == "__main__":
    main()
