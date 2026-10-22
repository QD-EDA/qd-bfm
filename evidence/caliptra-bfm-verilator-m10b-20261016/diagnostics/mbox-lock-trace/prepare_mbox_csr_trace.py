#!/usr/bin/env python3
"""Make a logging-only overlay for the pinned mailbox lock CSR."""

import hashlib
import sys
from pathlib import Path


PINNED_SHA256 = "453c4b3500fc19bf5d206413efc41db2caca9129405cbec248508ad6e71fcc4e"
TRACE = """
    integer m10b_mbox_trace_cycle;
    initial m10b_mbox_trace_cycle = 0;
    always @(posedge clk) begin
        m10b_mbox_trace_cycle = m10b_mbox_trace_cycle + 1;
        if (decoded_reg_strb.mbox_lock && !decoded_req_is_wr) begin
            $display("M10B_MBOX_LOCK_PRE cycle=%0d time=%0t req=%b ack=%b value=%b next=%b load=%b readback=%08x rd_data=%08x",
                     m10b_mbox_trace_cycle, $time, decoded_req, cpuif_rd_ack,
                     field_storage.mbox_lock.lock.value, field_combo.mbox_lock.lock.next,
                     field_combo.mbox_lock.lock.load_next, readback_data, cpuif_rd_data);
            $strobe("M10B_MBOX_LOCK_POST cycle=%0d time=%0t req=%b ack=%b value=%b next=%b load=%b readback=%08x rd_data=%08x",
                    m10b_mbox_trace_cycle, $time, decoded_req, cpuif_rd_ack,
                    field_storage.mbox_lock.lock.value, field_combo.mbox_lock.lock.next,
                    field_combo.mbox_lock.lock.load_next, readback_data, cpuif_rd_data);
        end
    end
"""


source, output = map(Path, sys.argv[1:3])
raw = source.read_bytes()
digest = hashlib.sha256(raw).hexdigest()
if digest != PINNED_SHA256:
    raise SystemExit(f"pinned mbox_csr.sv hash mismatch: {digest}")
text = raw.decode()
if text.count("endmodule") != 1:
    raise SystemExit("expected exactly one mbox_csr module terminator")
overlay = text.replace("endmodule", TRACE + "\nendmodule", 1)
if overlay.count("M10B_MBOX_LOCK_PRE") != 1 or overlay.count("endmodule") != 1:
    raise SystemExit("trace overlay self-check failed")
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(overlay)
print(f"pinned_sha256={digest}")
print(f"overlay_sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")
