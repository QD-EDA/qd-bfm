#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path


path = Path(sys.argv[1])
source = path.read_text()
before = """        clocking axi_if_arready_cb @(posedge clk);
            input #1step arready;
        endclocking"""
after = """        clocking axi_if_arready_cb @(posedge clk);
            input #1step arvalid, arready, araddr, rst_n;
        endclocking
        int unsigned m11_ar_trace_cycle = 0;
        int unsigned m11_ar_trace_count = 0;
        bit m11_ar_trace_active = 0;
        always @(posedge clk) begin
            m11_ar_trace_cycle++;
            if (axi_if_arready_cb.araddr == 32'h30020000)
                m11_ar_trace_active = 1;
            if (m11_ar_trace_active) begin
                m11_ar_trace_count++;
                if (m11_ar_trace_count <= 12 ||
                    !axi_if_arready_cb.arvalid || axi_if_arready_cb.arready ||
                    (m11_ar_trace_count % 1000000) == 0) begin
                    $display("M11_MBOX_AR_SAMPLE cycle=%0d time=%0t rst_n=%b addr=%08x valid=%b ready=%b",
                             m11_ar_trace_cycle, $time, axi_if_arready_cb.rst_n,
                             axi_if_arready_cb.araddr, axi_if_arready_cb.arvalid,
                             axi_if_arready_cb.arready);
                    $strobe("M11_MBOX_AR_POST cycle=%0d time=%0t rst_n=%b addr=%08x valid=%b ready=%b",
                            m11_ar_trace_cycle, $time, rst_n, araddr, arvalid, arready);
                end
                if (!axi_if_arready_cb.arvalid || axi_if_arready_cb.arready)
                    m11_ar_trace_active = 0;
            end
        end"""
if source.count(before) != 1:
    raise SystemExit("expected one M11 AR clocking block")
source = source.replace(before, after, 1)

before = """                arvalid `AR_EQ__ 1;
                `WAIT_ARREADY;
            end while(!`SAMPLE_ARREADY);"""
after = """                arvalid `AR_EQ__ 1;
                `WAIT_ARREADY;
                if (addr == AW'(32'h30020000)) begin
                    $display("M11_MBOX_AR_TASK time=%0t addr=%08x sampled_valid=%b sampled_ready=%b live_valid=%b live_ready=%b",
                             $time, addr, axi_if_arready_cb.arvalid,
                             `SAMPLE_ARREADY, arvalid, arready);
                end
            end while(!`SAMPLE_ARREADY);"""
if source.count(before) != 1:
    raise SystemExit("expected one M11 AR task wait")
source = source.replace(before, after, 1)
path.write_text(source)
print(f"trace_axi_if_sha256={hashlib.sha256(path.read_bytes()).hexdigest()}")
