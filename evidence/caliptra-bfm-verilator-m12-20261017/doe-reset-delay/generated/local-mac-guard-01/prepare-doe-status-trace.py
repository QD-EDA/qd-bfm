#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path


SOURCE_SHA256 = "6bd2ade137a90c0701aab28951ba6f8918724e0467c21756b0c308e6e9081c89"
ANCHOR = b"  DOE_clear_obf_status_valid: assert property ("
ERROR = b'else $display("SVA ERROR: DOE STATUS valid bit not set after clear obf secrets cmd");'
TRACE = b"""else begin
    $display("M12_DOE_FAILURE_SAMPLE time=%0t prev_cptra_rst_b=%b prev_doe_rst_b=%b prev_clear=%b prev_valid=%b prev_deobf=%b now_cptra_rst_b=%b now_doe_rst_b=%b now_clear=%b now_valid=%b now_deobf=%b",
             $time,
             $past(`CPTRA_TOP_PATH.cptra_rst_b), $past(`DOE_PATH.rst_b),
             $past(`CPTRA_TOP_PATH.clear_obf_secrets),
             $past(`DOE_REG_PATH.field_storage.DOE_STATUS.VALID.value),
             $past(`DOE_REG_PATH.field_storage.DOE_STATUS.DEOBF_SECRETS_CLEARED.value),
             `CPTRA_TOP_PATH.cptra_rst_b, `DOE_PATH.rst_b,
             `CPTRA_TOP_PATH.clear_obf_secrets,
             `DOE_REG_PATH.field_storage.DOE_STATUS.VALID.value,
             `DOE_REG_PATH.field_storage.DOE_STATUS.DEOBF_SECRETS_CLEARED.value);
    $display("SVA ERROR: DOE STATUS valid bit not set after clear obf secrets cmd");
end"""

rtl, checker_overlay = map(Path, sys.argv[1:])
source = rtl / "src/integration/asserts/caliptra_top_sva.sv"
source_bytes = source.read_bytes()
source_sha = hashlib.sha256(source_bytes).hexdigest()
if source_sha != SOURCE_SHA256:
    raise SystemExit(f"pinned Caliptra checker source hash mismatch: {source_sha}")
if source_bytes.count(ANCHOR) != 1:
    raise SystemExit("expected exactly one DOE reset-corner assertion")

overlay_bytes = checker_overlay.read_bytes()
if overlay_bytes.count(ANCHOR) != 1 or overlay_bytes.count(ERROR) != 1 or b"M12_DOE_FAILURE_SAMPLE" in overlay_bytes:
    raise SystemExit("expected one uninstrumented DOE assertion overlay")
traced = overlay_bytes.replace(ERROR, TRACE, 1)
if traced.replace(TRACE, ERROR, 1) != overlay_bytes:
    raise SystemExit("DOE failure trace changed bytes outside the assertion error action")
checker_overlay.write_bytes(traced)
print(f"checker_source_sha256={source_sha}")
print(f"doe_trace_overlay_sha256={hashlib.sha256(traced).hexdigest()}")
print("instrumentation=print prior-cycle antecedent and DOE status when the DOE assertion fails")
