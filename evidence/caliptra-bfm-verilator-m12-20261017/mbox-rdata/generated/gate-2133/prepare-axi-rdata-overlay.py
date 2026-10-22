#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path


BASE_SHA256 = "d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1"

source, output = map(Path, sys.argv[1:])
source_bytes = source.read_bytes()
if hashlib.sha256(source_bytes).hexdigest() != BASE_SHA256:
    raise SystemExit("pinned M10b AXI overlay hash mismatch")
text = source_bytes.decode()

verilator_before = """        `define SAMPLE_BVALID axi_if_bvalid_cb.bvalid
        clocking axi_if_bvalid_cb @(posedge clk);
            input #1step bvalid;
        endclocking"""
verilator_after = """        `define SAMPLE_BVALID axi_if_bvalid_cb.bvalid
        `define WAIT_RVALID @(posedge clk)
        `define SAMPLE_RVALID axi_if_read_cb.rvalid
        `define SAMPLE_RDATA axi_if_read_cb.rdata
        `define SAMPLE_RUSER axi_if_read_cb.ruser
        `define SAMPLE_RRESP axi_if_read_cb.rresp
        clocking axi_if_bvalid_cb @(posedge clk);
            input #1step bvalid;
        endclocking
        // Capture the accepted beat before same-edge RTL updates.
        clocking axi_if_read_cb @(posedge clk);
            input #1step rvalid, rdata, ruser, rresp;
        endclocking"""
if text.count(verilator_before) != 1:
    raise SystemExit("expected one pinned Verilator BVALID clocking block")
text = text.replace(verilator_before, verilator_after, 1)

icarus_before = """        `define SAMPLE_BVALID bvalid
    `endif"""
icarus_after = """        `define SAMPLE_BVALID bvalid
        `define WAIT_RVALID @(posedge clk)
        `define SAMPLE_RVALID rvalid
        `define SAMPLE_RDATA rdata
        `define SAMPLE_RUSER ruser
        `define SAMPLE_RRESP rresp
    `endif"""
if text.count(icarus_before) != 1:
    raise SystemExit("expected one pinned non-Verilator BVALID macro block")
text = text.replace(icarus_before, icarus_after, 1)

read_before = """            do
                @(posedge clk);
            while (!rvalid);
            data   `EQ__ rdata;
            user   `EQ__ ruser;
            resp   `EQ__ axi_resp_e'(rresp);"""
read_after = """            do
                `WAIT_RVALID;
            while (!`SAMPLE_RVALID);
            data   `EQ__ `SAMPLE_RDATA;
            user   `EQ__ `SAMPLE_RUSER;
            resp   `EQ__ axi_resp_e'(`SAMPLE_RRESP);"""
if text.count(read_before) != 1:
    raise SystemExit("expected one pinned get_read_beat response sample")
text = text.replace(read_before, read_after, 1)

undef_before = """    `undef WAIT_BVALID
    `undef SAMPLE_BVALID
    `undef AW_EQ__"""
undef_after = """    `undef WAIT_BVALID
    `undef SAMPLE_BVALID
    `undef WAIT_RVALID
    `undef SAMPLE_RVALID
    `undef SAMPLE_RDATA
    `undef SAMPLE_RUSER
    `undef SAMPLE_RRESP
    `undef AW_EQ__"""
if text.count(undef_before) != 1:
    raise SystemExit("expected one pinned AXI macro cleanup block")
text = text.replace(undef_before, undef_after, 1)

if text.count("clocking axi_if_read_cb @(posedge clk);") != 1:
    raise SystemExit("read clocking block self-check failed")
if text.count("while (!`SAMPLE_RVALID);") != 1:
    raise SystemExit("read valid loop self-check failed")
if text.count("data   `EQ__ `SAMPLE_RDATA;") != 1:
    raise SystemExit("read data sampling self-check failed")

output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(text)
print(f"base_overlay_sha256={BASE_SHA256}")
print(f"rdata_overlay_sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")
print("change=Verilator samples accepted R-channel values with #1step; Icarus macros retain live edge sampling")
