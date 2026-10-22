#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path


SOURCE_SHA256 = "e03bd7a7654eb9c31bd532861b94d59c876810aa9798f9f67f7df2a5a3f5495c"

source, output = map(Path, sys.argv[1:])
original = source.read_text()
if hashlib.sha256(source.read_bytes()).hexdigest() != SOURCE_SHA256:
    raise SystemExit(f"pinned axi_if.sv hash mismatch: {source}")

macros_before = """    `ifdef VERILATOR
        `define EQ__ =
        `define TIME_ALGN #100ps
    `else
        `define EQ__ <=
        `define TIME_ALGN
    `endif"""
macros_after = """    `ifdef VERILATOR
        `define EQ__ =
        // Sample ARREADY in the same edge region as the subordinate assertion.
        `define AR_EQ__ <=
        `define WAIT_ARREADY @(posedge clk)
        `define SAMPLE_ARREADY axi_if_arready_cb.arready
        clocking axi_if_arready_cb @(posedge clk);
            input #1step arready;
        endclocking
        // SVA samples before the edge; keep AW drives out of its sampling region.
        `define AW_EQ__ <=
        `define TIME_ALGN #100ps
        // Wait on the clock itself; Verilator's clocking-block event spun at the first write.
        `define WAIT_AWREADY @(posedge clk)
        `define SAMPLE_AWREADY axi_if_awready_cb.awready
        clocking axi_if_awready_cb @(posedge clk);
            input #1step awready;
        endclocking
        // Keep W valid/data stable through the assertion sample at the clock edge.
        `define W_EQ__ <=
        `define WAIT_WREADY @(posedge clk)
        `define SAMPLE_WREADY axi_if_wready_cb.wready
        clocking axi_if_wready_cb @(posedge clk);
            input #1step wready;
        endclocking
        // Keep BREADY asserted until BVALID is seen in the assertion sample region.
        `define B_EQ__ <=
        `define WAIT_BVALID @(posedge clk)
        `define SAMPLE_BVALID axi_if_bvalid_cb.bvalid
        clocking axi_if_bvalid_cb @(posedge clk);
            input #1step bvalid;
        endclocking
    `else
        `define EQ__ <=
        `define AR_EQ__ <=
        `define AW_EQ__ <=
        `define W_EQ__ <=
        `define TIME_ALGN
        `define WAIT_ARREADY @(posedge clk)
        `define SAMPLE_ARREADY arready
        `define WAIT_AWREADY @(posedge clk)
        `define SAMPLE_AWREADY awready
        `define WAIT_WREADY @(posedge clk)
        `define SAMPLE_WREADY wready
        `define B_EQ__ <=
        `define WAIT_BVALID @(posedge clk)
        `define SAMPLE_BVALID bvalid
    `endif"""
if original.count(macros_before) != 1:
    raise SystemExit("expected the exact pinned VERILATOR task macro block once")
overlay = original.replace(macros_before, macros_after, 1)

aw_wait_before = """                awvalid `EQ__ 1;
                @(posedge clk);
            end while(!awready);"""
aw_wait_after = """                awvalid `EQ__ 1;
                `WAIT_AWREADY;
            end while(!`SAMPLE_AWREADY);"""
if overlay.count(aw_wait_before) != 1:
    raise SystemExit("expected the exact axi_write AW wait once")
overlay = overlay.replace(aw_wait_before, aw_wait_after, 1)

aw_block_before = """                `TIME_ALGN
                awaddr  `EQ__ addr;
                awburst `EQ__ burst;
                awsize  `EQ__ size;
                awlen   `EQ__ len;
                awuser  `EQ__ user;
                awid    `EQ__ id;
                awlock  `EQ__ lock;
                awvalid `EQ__ 1;
                `WAIT_AWREADY;
            end while(!`SAMPLE_AWREADY);
            `TIME_ALGN
            awaddr  `EQ__ '0;
            awburst `EQ__ AXI_BURST_FIXED;
            awsize  `EQ__ '0;
            awlen   `EQ__ '0;
            awuser  `EQ__ '0;
            awid    `EQ__ '0;
            awlock  `EQ__ '0;
            awvalid `EQ__ '0;"""
aw_block_after = aw_block_before.replace("`EQ__", "`AW_EQ__")
if overlay.count(aw_block_before) != 1:
    raise SystemExit("expected the exact axi_write AW drive and cleanup block once")
overlay = overlay.replace(aw_block_before, aw_block_after, 1)

w_block_before = """            wvalid `EQ__ 1;
            wlast  `EQ__ last;
            wdata  `EQ__ data;
            wstrb  `EQ__ strb;
            wuser  `EQ__ user;
            do
                @(posedge clk);
            while (!wready);
            `TIME_ALGN
            wvalid `EQ__ '0;
            wlast  `EQ__ '0;
            wdata  `EQ__ '0;
            wstrb  `EQ__ '0;
            wuser  `EQ__ '0;"""
w_wait_before = """            do
                @(posedge clk);
            while (!wready);"""
if w_block_before.count(w_wait_before) != 1:
    raise SystemExit("expected one W-ready edge wait in the exact send_write_beat block")
w_block_after = w_block_before.replace("`EQ__", "`W_EQ__").replace(
    w_wait_before,
    """            do
                `WAIT_WREADY;
            while (!`SAMPLE_WREADY);""",
)
if overlay.count(w_block_before) != 1:
    raise SystemExit("expected the exact send_write_beat W drive and wait block once")
overlay = overlay.replace(w_block_before, w_block_after, 1)

b_block_before = """            `TIME_ALGN
            bready `EQ__ 1;
            do
                @(posedge clk);
            while(!bvalid);
            resp `EQ__ axi_resp_e'(bresp);
            user `EQ__ buser;
            `TIME_ALGN
            bready `EQ__ 0;"""
b_wait_before = """            do
                @(posedge clk);
            while(!bvalid);"""
if b_block_before.count(b_wait_before) != 1:
    raise SystemExit("expected one B-valid edge wait in the exact get_write_resp block")
b_block_after = b_block_before.replace("bready `EQ__", "bready `B_EQ__").replace(
    b_wait_before,
    """            do
                `WAIT_BVALID;
            while(!`SAMPLE_BVALID);""",
)
if overlay.count(b_block_before) != 1:
    raise SystemExit("expected the exact get_write_resp B drive and wait block once")
overlay = overlay.replace(b_block_before, b_block_after, 1)

ar_block_before = """                `TIME_ALGN
                araddr  `EQ__ addr;
                arburst `EQ__ burst;
                arsize  `EQ__ size;
                arlen   `EQ__ len;
                aruser  `EQ__ user;
                arid    `EQ__ id;
                arlock  `EQ__ lock;
                arvalid `EQ__ 1;
                @(posedge clk);
            end while(!arready);
            `TIME_ALGN
            araddr  `EQ__ '0;
            arburst `EQ__ AXI_BURST_FIXED;
            arsize  `EQ__ '0;
            arlen   `EQ__ '0;
            aruser  `EQ__ '0;
            arid    `EQ__ '0;
            arlock  `EQ__ '0;
            arvalid `EQ__ '0;"""
ar_block_after = """                `TIME_ALGN
                araddr  `AR_EQ__ addr;
                arburst `AR_EQ__ burst;
                arsize  `AR_EQ__ size;
                arlen   `AR_EQ__ len;
                aruser  `AR_EQ__ user;
                arid    `AR_EQ__ id;
                arlock  `AR_EQ__ lock;
                arvalid `AR_EQ__ 1;
                `WAIT_ARREADY;
            end while(!`SAMPLE_ARREADY);
            `TIME_ALGN
            araddr  `AR_EQ__ '0;
            arburst `AR_EQ__ AXI_BURST_FIXED;
            arsize  `AR_EQ__ '0;
            arlen   `AR_EQ__ '0;
            aruser  `AR_EQ__ '0;
            arid    `AR_EQ__ '0;
            arlock  `AR_EQ__ '0;
            arvalid `AR_EQ__ '0;"""
if overlay.count(ar_block_before) != 1:
    raise SystemExit("expected the exact axi_read AR drive, wait, and cleanup block once")
overlay = overlay.replace(ar_block_before, ar_block_after, 1)

undef_before = """    `undef EQ__
    `undef TIME_ALGN"""
undef_after = """    `undef WAIT_AWREADY
    `undef SAMPLE_AWREADY
    `undef WAIT_ARREADY
    `undef SAMPLE_ARREADY
    `undef WAIT_WREADY
    `undef SAMPLE_WREADY
    `undef WAIT_BVALID
    `undef SAMPLE_BVALID
    `undef AW_EQ__
    `undef AR_EQ__
    `undef W_EQ__
    `undef B_EQ__
    `undef EQ__
    `undef TIME_ALGN"""
if overlay.count(undef_before) != 1:
    raise SystemExit("expected the task macro cleanup once")
overlay = overlay.replace(undef_before, undef_after, 1)

output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(overlay)
print(f"source_sha256={SOURCE_SHA256}")
print(f"overlay_sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")
print("change=AR, AW, W and B channels use NBA drives and posedge clocking-block samples; Icarus unchanged")
