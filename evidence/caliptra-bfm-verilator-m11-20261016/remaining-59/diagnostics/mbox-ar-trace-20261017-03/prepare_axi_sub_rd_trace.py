#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path


path = Path(sys.argv[1])
source = path.read_text()
anchor = "    // Handshake rules\n"
trace = """    clocking m11_sub_ar_trace_cb @(posedge clk);
        input #1step m11_sub_arvalid = s_axi_if.arvalid;
        input #1step m11_sub_arready = s_axi_if.arready;
        input #1step m11_sub_araddr = s_axi_if.araddr;
        input #1step m11_sub_rst_n = rst_n;
    endclocking
    int unsigned m11_sub_ar_trace_cycle = 0;
    bit m11_sub_ar_trace_active = 0;
    bit m11_sub_ar_trace_after_handshake = 0;
    always @(posedge clk) begin
        m11_sub_ar_trace_cycle++;
        if (m11_sub_ar_trace_cb.m11_sub_araddr == AW'(32'h00020000))
            m11_sub_ar_trace_active = 1;
        if (m11_sub_ar_trace_active || m11_sub_ar_trace_after_handshake) begin
            $display("M11_AXI_SUB_AR_SAMPLE %m cycle=%0d time=%0t rst_n=%b addr=%08x valid=%b ready=%b",
                     m11_sub_ar_trace_cycle, $time,
                     m11_sub_ar_trace_cb.m11_sub_rst_n,
                     m11_sub_ar_trace_cb.m11_sub_araddr,
                     m11_sub_ar_trace_cb.m11_sub_arvalid,
                     m11_sub_ar_trace_cb.m11_sub_arready);
            $strobe("M11_AXI_SUB_AR_POST %m cycle=%0d time=%0t rst_n=%b addr=%08x valid=%b ready=%b",
                    m11_sub_ar_trace_cycle, $time, rst_n, s_axi_if.araddr,
                    s_axi_if.arvalid, s_axi_if.arready);
            if (m11_sub_ar_trace_after_handshake) begin
                m11_sub_ar_trace_after_handshake = 0;
                m11_sub_ar_trace_active = 0;
            end else if (m11_sub_ar_trace_cb.m11_sub_arvalid &&
                         m11_sub_ar_trace_cb.m11_sub_arready) begin
                m11_sub_ar_trace_active = 0;
                m11_sub_ar_trace_after_handshake = 1;
            end else if (!m11_sub_ar_trace_cb.m11_sub_arvalid) begin
                m11_sub_ar_trace_active = 0;
            end
        end
    end

"""
if source.count(anchor) != 1:
    raise SystemExit("expected exactly one handshake-rules anchor")
source = source.replace(anchor, trace + anchor, 1)
path.write_text(source)
print(f"trace_axi_sub_rd_sha256={hashlib.sha256(path.read_bytes()).hexdigest()}")
